// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:vm_service_lib/vm_service_lib.dart';
import 'package:vm_service_lib/vm_service_lib_io.dart';

import '../src/common.dart';

// Set this to true for debugging to get verbose logs written to stdout.
// The logs include the following:
//   <=stdout= data that the flutter tool running in --verbose mode wrote to stdout.
//   <=stderr= data that the flutter tool running in --verbose mode wrote to stderr.
//   =stdin=> data that the test sent to the flutter tool over stdin.
//   =vm=> data that was sent over the VM service channel to the app running on the test device.
//   <=vm= data that was sent from the app on the test device over the VM service channel.
//   Messages regarding what the test is doing.
// If this is false, then only critical errors and logs when things appear to be
// taking a long time are printed to the console.
const bool _printDebugOutputToStdOut = false;

final DateTime startTime = DateTime.now();

const Duration defaultTimeout = Duration(seconds: 5);
const Duration appStartTimeout = Duration(seconds: 120);
const Duration quitTimeout = Duration(seconds: 10);

abstract class FlutterTestDriver {
  FlutterTestDriver(
    this._projectFolder, {
    String logPrefix,
  }) : _logPrefix = logPrefix != null ? '$logPrefix: ' : '';

  final Directory _projectFolder;
  final String _logPrefix;
  Process _process;
  int _processPid;
  final StreamController<String> _stdout = StreamController<String>.broadcast();
  final StreamController<String> _stderr = StreamController<String>.broadcast();
  final StreamController<String> _allMessages = StreamController<String>.broadcast();
  final StringBuffer _errorBuffer = StringBuffer();
  String _lastResponse;
  Uri _vmServiceWsUri;
  bool _hasExited = false;

  VmService _vmService;
  String get lastErrorInfo => _errorBuffer.toString();
  Stream<String> get stdout => _stdout.stream;
  int get vmServicePort => _vmServiceWsUri.port;
  bool get hasExited => _hasExited;

  String lastTime = '';
  void _debugPrint(String message, { String topic = '' }) {
    const int maxLength = 2500;
    final String truncatedMessage = message.length > maxLength ? message.substring(0, maxLength) + '...' : message;
    final String line = '${topic.padRight(10)} $truncatedMessage';
    _allMessages.add(line);
    final int timeInSeconds = DateTime.now().difference(startTime).inSeconds;
    String time = timeInSeconds.toString().padLeft(5) + 's ';
    if (time == lastTime) {
      time = ' ' * time.length;
    } else {
      lastTime = time;
    }
    if (_printDebugOutputToStdOut)
      print('$time$_logPrefix$line');
  }

  Future<void> _setupProcess(
    List<String> arguments, {
    String script,
    bool withDebugger = false,
    File pidFile,
  }) async {
    final String flutterBin = fs.path.join(getFlutterRoot(), 'bin', 'flutter');
    if (withDebugger)
      arguments.add('--start-paused');
    if (_printDebugOutputToStdOut)
      arguments.add('--verbose');
    if (pidFile != null) {
      arguments.addAll(<String>['--pid-file', pidFile.path]);
    }
    if (script != null) {
      arguments.add(script);
    }
    _debugPrint('Spawning flutter $arguments in ${_projectFolder.path}');

    const ProcessManager _processManager = LocalProcessManager();
    _process = await _processManager.start(
      <String>[flutterBin]
        .followedBy(arguments)
        .toList(),
      workingDirectory: _projectFolder.path,
      environment: <String, String>{'FLUTTER_TEST': 'true'},
    );

    // This class doesn't use the result of the future. It's made available
    // via a getter for external uses.
    unawaited(_process.exitCode.then((int code) {
      _debugPrint('Process exited ($code)');
      _hasExited = true;
    }));
    transformToLines(_process.stdout).listen((String line) => _stdout.add(line));
    transformToLines(_process.stderr).listen((String line) => _stderr.add(line));

    // Capture stderr to a buffer so we can show it all if any requests fail.
    _stderr.stream.listen(_errorBuffer.writeln);

    // This is just debug printing to aid running/debugging tests locally.
    _stdout.stream.listen((String message) => _debugPrint(message, topic: '<=stdout='));
    _stderr.stream.listen((String message) => _debugPrint(message, topic: '<=stderr='));
  }

  Future<void> connectToVmService({ bool pauseOnExceptions = false }) async {
    _vmService = await vmServiceConnectUri('$_vmServiceWsUri');
    _vmService.onSend.listen((String s) => _debugPrint(s, topic: '=vm=>'));
    _vmService.onReceive.listen((String s) => _debugPrint(s, topic: '<=vm='));
    _vmService.onIsolateEvent.listen((Event event) {
      if (event.kind == EventKind.kIsolateExit && event.isolate.id == _flutterIsolateId) {
        // Hot restarts cause all the isolates to exit, so we need to refresh
        // our idea of what the Flutter isolate ID is.
        _flutterIsolateId = null;
      }
    });

    await Future.wait(<Future<Success>>[
      _vmService.streamListen('Isolate'),
      _vmService.streamListen('Debug'),
    ]);

    await waitForPause();
    if (pauseOnExceptions) {
      await _vmService.setExceptionPauseMode(
        await _getFlutterIsolateId(),
        ExceptionPauseMode.kUnhandled,
      );
    }
  }

  Future<int> quit() => _killGracefully();

  Future<int> _killGracefully() async {
    if (_processPid == null)
      return -1;
    _debugPrint('Sending SIGTERM to $_processPid..');
    Process.killPid(_processPid);
    return _process.exitCode.timeout(quitTimeout, onTimeout: _killForcefully);
  }

  Future<int> _killForcefully() {
    _debugPrint('Sending SIGKILL to $_processPid..');
    Process.killPid(_processPid, ProcessSignal.SIGKILL);
    return _process.exitCode;
  }

  String _flutterIsolateId;
  Future<String> _getFlutterIsolateId() async {
    // Currently these tests only have a single isolate. If this
    // ceases to be the case, this code will need changing.
    if (_flutterIsolateId == null) {
      final VM vm = await _vmService.getVM();
      _flutterIsolateId = vm.isolates.first.id;
    }
    return _flutterIsolateId;
  }

  Future<Isolate> _getFlutterIsolate() async {
    final Isolate isolate = await _vmService.getIsolate(await _getFlutterIsolateId());
    return isolate;
  }

  /// Add a breakpoint and wait for it to trip the program execution.
  ///
  /// Only call this when you are absolutely sure that the program under test
  /// will hit the breakpoint _in the future_.
  ///
  /// In particular, do not call this if the program is currently racing to pass
  /// the line of code you are breaking on. Pretend that calling this will take
  /// an hour before setting the breakpoint. Would the code still eventually hit
  /// the breakpoint and stop?
  Future<void> breakAt(Uri uri, int line) async {
    await addBreakpoint(uri, line);
    await waitForPause();
  }

  Future<void> addBreakpoint(Uri uri, int line) async {
    _debugPrint('Sending breakpoint for: $uri:$line');
    await _vmService.addBreakpointWithScriptUri(
      await _getFlutterIsolateId(),
      uri.toString(),
      line,
    );
  }

  // This method isn't racy. If the isolate is already paused,
  // it will immediately return.
  Future<Isolate> waitForPause() async {
    return _timeoutWithMessages<Isolate>(
      () async {
        final String flutterIsolate = await _getFlutterIsolateId();
        final Completer<Event> pauseEvent = Completer<Event>();

        // Start listening for pause events.
        final StreamSubscription<Event> pauseSubscription = _vmService.onDebugEvent
          .where((Event event) {
            return event.isolate.id == flutterIsolate
                && event.kind.startsWith('Pause');
          })
          .listen((Event event) {
            if (!pauseEvent.isCompleted)
              pauseEvent.complete(event);
          });

        // But also check if the isolate was already paused (only after we've set
        // up the subscription) to avoid races. If it was paused, we don't need to wait
        // for the event.
        final Isolate isolate = await _vmService.getIsolate(flutterIsolate);
        if (isolate.pauseEvent.kind.startsWith('Pause')) {
          _debugPrint('Isolate was already paused (${isolate.pauseEvent.kind}).');
        } else {
          _debugPrint('Isolate is not already paused, waiting for event to arrive...');
          await pauseEvent.future;
        }

        // Cancel the subscription on either of the above.
        await pauseSubscription.cancel();

        return _getFlutterIsolate();
      },
      task: 'Waiting for isolate to pause',
    );
  }

  Future<Isolate> resume({ bool waitForNextPause = false }) => _resume(null, waitForNextPause);
  Future<Isolate> stepOver({ bool waitForNextPause = true }) => _resume(StepOption.kOver, waitForNextPause);
  Future<Isolate> stepOverAsync({ bool waitForNextPause = true }) => _resume(StepOption.kOverAsyncSuspension, waitForNextPause);
  Future<Isolate> stepInto({ bool waitForNextPause = true }) => _resume(StepOption.kInto, waitForNextPause);
  Future<Isolate> stepOut({ bool waitForNextPause = true }) => _resume(StepOption.kOut, waitForNextPause);

  Future<bool> isAtAsyncSuspension() async {
    final Isolate isolate = await _getFlutterIsolate();
    return isolate.pauseEvent.atAsyncSuspension == true;
  }

  Future<Isolate> stepOverOrOverAsyncSuspension({ bool waitForNextPause = true }) async {
    if (await isAtAsyncSuspension())
      return await stepOverAsync(waitForNextPause: waitForNextPause);
    return await stepOver(waitForNextPause: waitForNextPause);
  }

  Future<Isolate> _resume(String step, bool waitForNextPause) async {
    assert(waitForNextPause != null);
    await _timeoutWithMessages<dynamic>(
      () async => _vmService.resume(await _getFlutterIsolateId(), step: step),
      task: 'Resuming isolate (step=$step)',
    );
    return waitForNextPause ? waitForPause() : null;
  }

  Future<InstanceRef> evaluateInFrame(String expression) async {
    return _timeoutWithMessages<InstanceRef>(
      () async => await _vmService.evaluateInFrame(await _getFlutterIsolateId(), 0, expression),
      task: 'Evaluating expression ($expression)',
    );
  }

  Future<InstanceRef> evaluate(String targetId, String expression) async {
    return _timeoutWithMessages<InstanceRef>(
      () async => await _vmService.evaluate(await _getFlutterIsolateId(), targetId, expression),
      task: 'Evaluating expression ($expression for $targetId)',
    );
  }

  Future<Frame> getTopStackFrame() async {
    final String flutterIsolateId = await _getFlutterIsolateId();
    final Stack stack = await _vmService.getStack(flutterIsolateId);
    if (stack.frames.isEmpty) {
      throw Exception('Stack is empty');
    }
    return stack.frames.first;
  }

  Future<SourcePosition> getSourceLocation() async {
    final String flutterIsolateId = await _getFlutterIsolateId();
    final Frame frame = await getTopStackFrame();
    final Script script = await _vmService.getObject(flutterIsolateId, frame.location.script.id);
    return _lookupTokenPos(script.tokenPosTable, frame.location.tokenPos);
  }

  SourcePosition _lookupTokenPos(List<List<int>> table, int tokenPos) {
    for (List<int> row in table) {
      final int lineNumber = row[0];
      int index = 1;

      for (index = 1; index < row.length - 1; index += 2) {
        if (row[index] == tokenPos) {
          return SourcePosition(lineNumber, row[index + 1]);
        }
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> _waitFor({
    String event,
    int id,
    Duration timeout = defaultTimeout,
    bool ignoreAppStopEvent = false,
  }) async {
    assert(timeout != null);
    assert(event != null || id != null);
    assert(event == null || id == null);
    final String interestingOccurrence = event != null ? '$event event' : 'response to request $id';
    final Completer<Map<String, dynamic>> response = Completer<Map<String, dynamic>>();
    StreamSubscription<String> subscription;
    subscription = _stdout.stream.listen((String line) async {
      final dynamic json = parseFlutterResponse(line);
      _lastResponse = line;
      if (json == null)
        return;
      if ((event != null && json['event'] == event) ||
          (id    != null && json['id']    == id)) {
        await subscription.cancel();
        _debugPrint('OK ($interestingOccurrence)');
        response.complete(json);
      } else if (!ignoreAppStopEvent && json['event'] == 'app.stop') {
        await subscription.cancel();
        final StringBuffer error = StringBuffer();
        error.write('Received app.stop event while waiting for $interestingOccurrence\n\n');
        if (json['params'] != null && json['params']['error'] != null) {
          error.write('${json['params']['error']}\n\n');
        }
        if (json['params'] != null && json['params']['trace'] != null) {
          error.write('${json['params']['trace']}\n\n');
        }
        response.completeError(error.toString());
      }
    });

    return _timeoutWithMessages(
      () => response.future,
      timeout: timeout,
      task: 'Expecting $interestingOccurrence',
    ).whenComplete(subscription.cancel);
  }

  Future<T> _timeoutWithMessages<T>(
    Future<T> Function() callback, {
    @required String task,
    Duration timeout = defaultTimeout,
  }) {
    assert(task != null);
    assert(timeout != null);

    if (_printDebugOutputToStdOut) {
      _debugPrint('$task...');
      return callback()..timeout(timeout, onTimeout: () {
        _debugPrint('$task is taking longer than usual...');
      });
    }

    // We're not showing all output to the screen, so let's capture the output
    // that we would have printed if we were, and output it if we take longer
    // than the timeout or if we get an error.
    final StringBuffer messages = StringBuffer('$task\n');
    final DateTime start = DateTime.now();
    bool timeoutExpired = false;
    void logMessage(String logLine) {
      final int ms = DateTime.now().difference(start).inMilliseconds;
      final String formattedLine = '[+ ${ms.toString().padLeft(5)}] $logLine';
      messages.writeln(formattedLine);
    }
    final StreamSubscription<String> subscription = _allMessages.stream.listen(logMessage);

    final Future<T> future = callback();

    future.timeout(timeout ?? defaultTimeout, onTimeout: () {
      print(messages.toString());
      timeoutExpired = true;
      print('$task is taking longer than usual...');
    });

    return future.catchError((dynamic error) {
      if (!timeoutExpired) {
        timeoutExpired = true;
        print(messages.toString());
      }
      throw error;
    }).whenComplete(() => subscription.cancel());
  }
}

class FlutterRunTestDriver extends FlutterTestDriver {
  FlutterRunTestDriver(
    Directory projectFolder, {
    String logPrefix,
  }) : super(projectFolder, logPrefix: logPrefix);

  String _currentRunningAppId;

  Future<void> run({
    bool withDebugger = false,
    bool startPaused = false,
    bool pauseOnExceptions = false,
    File pidFile,
  }) async {
    await _setupProcess(
      <String>[
        'run',
	'--disable-service-auth-codes',
        '--machine',
        '-d',
        'flutter-tester',
      ],
      withDebugger: withDebugger,
      startPaused: startPaused,
      pauseOnExceptions: pauseOnExceptions,
      pidFile: pidFile,
    );
  }

  Future<void> attach(
    int port, {
    bool withDebugger = false,
    bool startPaused = false,
    bool pauseOnExceptions = false,
    File pidFile,
  }) async {
    await _setupProcess(
      <String>[
        'attach',
        '--machine',
        '-d',
        'flutter-tester',
        '--debug-port',
        '$port',
      ],
      withDebugger: withDebugger,
      startPaused: startPaused,
      pauseOnExceptions: pauseOnExceptions,
      pidFile: pidFile,
    );
  }

  @override
  Future<void> _setupProcess(
    List<String> args, {
    String script,
    bool withDebugger = false,
    bool startPaused = false,
    bool pauseOnExceptions = false,
    File pidFile,
  }) async {
    assert(!startPaused || withDebugger);
    await super._setupProcess(
      args,
      script: script,
      withDebugger: withDebugger,
      pidFile: pidFile,
    );

    // Stash the PID so that we can terminate the VM more reliably than using
    // _process.kill() (`flutter` is a shell script so _process itself is a
    // shell, not the flutter tool's Dart process).
    final Map<String, dynamic> connected = await _waitFor(event: 'daemon.connected');
    _processPid = connected['params']['pid'];

    // Set this up now, but we don't wait it yet. We want to make sure we don't
    // miss it while waiting for debugPort below.
    final Future<Map<String, dynamic>> started = _waitFor(event: 'app.started', timeout: appStartTimeout);

    if (withDebugger) {
      final Map<String, dynamic> debugPort = await _waitFor(event: 'app.debugPort', timeout: appStartTimeout);
      final String wsUriString = debugPort['params']['wsUri'];
      _vmServiceWsUri = Uri.parse(wsUriString);
      await connectToVmService(pauseOnExceptions: pauseOnExceptions);
      if (!startPaused)
        await resume(waitForNextPause: false);
    }

    // Now await the started event; if it had already happened the future will
    // have already completed.
    _currentRunningAppId = (await started)['params']['appId'];
  }

  Future<void> hotRestart({ bool pause = false }) => _restart(fullRestart: true, pause: pause);
  Future<void> hotReload() => _restart(fullRestart: false);

  Future<void> _restart({ bool fullRestart = false, bool pause = false }) async {
    if (_currentRunningAppId == null)
      throw Exception('App has not started yet');

    _debugPrint('Performing ${ pause ? "paused " : "" }${ fullRestart ? "hot restart" : "hot reload" }...');
    final dynamic hotReloadResponse = await _sendRequest(
      'app.restart',
      <String, dynamic>{'appId': _currentRunningAppId, 'fullRestart': fullRestart, 'pause': pause},
    );
    _debugPrint('${ fullRestart ? "Hot restart" : "Hot reload" } complete.');

    if (hotReloadResponse == null || hotReloadResponse['code'] != 0)
      _throwErrorResponse('Hot ${fullRestart ? 'restart' : 'reload'} request failed');
  }

  Future<int> detach() async {
    if (_process == null) {
      return 0;
    }
    if (_vmService != null) {
      _debugPrint('Closing VM service...');
      _vmService.dispose();
    }
    if (_currentRunningAppId != null) {
      _debugPrint('Detaching from app...');
      await Future.any<void>(<Future<void>>[
        _process.exitCode,
        _sendRequest(
          'app.detach',
          <String, dynamic>{'appId': _currentRunningAppId},
        ),
      ]).timeout(
        quitTimeout,
        onTimeout: () { _debugPrint('app.detach did not return within $quitTimeout'); },
      );
      _currentRunningAppId = null;
    }
    _debugPrint('Waiting for process to end...');
    return _process.exitCode.timeout(quitTimeout, onTimeout: _killGracefully);
  }

  Future<int> stop() async {
    if (_vmService != null) {
      _debugPrint('Closing VM service...');
      _vmService.dispose();
    }
    if (_currentRunningAppId != null) {
      _debugPrint('Stopping application...');
      await Future.any<void>(<Future<void>>[
        _process.exitCode,
        _sendRequest(
          'app.stop',
          <String, dynamic>{'appId': _currentRunningAppId},
        ),
      ]).timeout(
        quitTimeout,
        onTimeout: () { _debugPrint('app.stop did not return within $quitTimeout'); },
      );
      _currentRunningAppId = null;
    }
    if (_process != null) {
      _debugPrint('Waiting for process to end...');
      return _process.exitCode.timeout(quitTimeout, onTimeout: _killGracefully);
    }
    return 0;
  }

  int id = 1;
  Future<dynamic> _sendRequest(String method, dynamic params) async {
    final int requestId = id++;
    final Map<String, dynamic> request = <String, dynamic>{
      'id': requestId,
      'method': method,
      'params': params,
    };
    final String jsonEncoded = json.encode(<Map<String, dynamic>>[request]);
    _debugPrint(jsonEncoded, topic: '=stdin=>');

    // Set up the response future before we send the request to avoid any
    // races. If the method we're calling is app.stop then we tell _waitFor not
    // to throw if it sees an app.stop event before the response to this request.
    final Future<Map<String, dynamic>> responseFuture = _waitFor(
      id: requestId,
      ignoreAppStopEvent: method == 'app.stop',
    );
    _process.stdin.writeln(jsonEncoded);
    final Map<String, dynamic> response = await responseFuture;

    if (response['error'] != null || response['result'] == null)
      _throwErrorResponse('Unexpected error response');

    return response['result'];
  }

  void _throwErrorResponse(String message) {
    throw '$message\n\n$_lastResponse\n\n${_errorBuffer.toString()}'.trim();
  }
}

class FlutterTestTestDriver extends FlutterTestDriver {
  FlutterTestTestDriver(Directory _projectFolder, {String logPrefix})
    : super(_projectFolder, logPrefix: logPrefix);

  Future<void> test({
    String testFile = 'test/test.dart',
    bool withDebugger = false,
    bool pauseOnExceptions = false,
    File pidFile,
    Future<void> Function() beforeStart,
  }) async {
    await _setupProcess(<String>[
        'test',
	'--disable-service-auth-codes',
        '--machine',
        '-d',
        'flutter-tester',
    ], script: testFile, withDebugger: withDebugger, pauseOnExceptions: pauseOnExceptions, pidFile: pidFile, beforeStart: beforeStart);
  }

  @override
  Future<void> _setupProcess(
    List<String> args, {
    String script,
    bool withDebugger = false,
    bool pauseOnExceptions = false,
    File pidFile,
    Future<void> Function() beforeStart,
  }) async {
    await super._setupProcess(
      args,
      script: script,
      withDebugger: withDebugger,
      pidFile: pidFile,
    );

    // Stash the PID so that we can terminate the VM more reliably than using
    // _proc.kill() (because _proc is a shell, because `flutter` is a shell
    // script).
    final Map<String, dynamic> version = await _waitForJson();
    _processPid = version['pid'];

    if (withDebugger) {
      final Map<String, dynamic> startedProcess = await _waitFor(event: 'test.startedProcess', timeout: appStartTimeout);
      final String vmServiceHttpString = startedProcess['params']['observatoryUri'];
      _vmServiceWsUri = Uri.parse(vmServiceHttpString).replace(scheme: 'ws', path: '/ws');
      await connectToVmService(pauseOnExceptions: pauseOnExceptions);
      // Allow us to run code before we start, eg. to set up breakpoints.
      if (beforeStart != null) {
        await beforeStart();
      }
      await resume(waitForNextPause: false);
    }
  }

  Future<Map<String, dynamic>> _waitForJson({
    Duration timeout,
  }) async {
    return _timeoutWithMessages<Map<String, dynamic>>(
      () => _stdout.stream.map<Map<String, dynamic>>(_parseJsonResponse).first,
      timeout: timeout,
      task: 'Waiting for JSON',
    );
  }

  Map<String, dynamic> _parseJsonResponse(String line) {
    try {
      return json.decode(line);
    } catch (e) {
      // Not valid JSON, so likely some other output.
      return null;
    }
  }
}

Stream<String> transformToLines(Stream<List<int>> byteStream) {
  return byteStream.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
}

Map<String, dynamic> parseFlutterResponse(String line) {
  if (line.startsWith('[') && line.endsWith(']')) {
    try {
      final Map<String, dynamic> response = json.decode(line)[0];
      return response;
    } catch (e) {
      // Not valid JSON, so likely some other output that was surrounded by [brackets]
      return null;
    }
  }
  return null;
}

class SourcePosition {
  SourcePosition(this.line, this.column);

  final int line;
  final int column;
}
