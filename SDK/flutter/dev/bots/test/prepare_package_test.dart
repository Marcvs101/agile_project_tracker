// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' show FakePlatform;

import '../prepare_package.dart';
import 'common.dart';
import 'fake_process_manager.dart';

void main() {
  const String testRef = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef';
  test('Throws on missing executable', () async {
    // Uses a *real* process manager, since we want to know what happens if
    // it can't find an executable.
    final ProcessRunner processRunner = ProcessRunner(subprocessOutput: false);
    expect(
        expectAsync1((List<String> commandLine) async {
          return processRunner.runProcess(commandLine);
        })(<String>['this_executable_better_not_exist_2857632534321']),
        throwsA(isInstanceOf<PreparePackageException>()));
    try {
      await processRunner.runProcess(<String>['this_executable_better_not_exist_2857632534321']);
    } on PreparePackageException catch (e) {
      expect(
        e.message,
        contains('Invalid argument(s): Cannot find executable for this_executable_better_not_exist_2857632534321.'),
      );
    }
  });
  for (String platformName in <String>['macos', 'linux', 'windows']) {
    final FakePlatform platform = FakePlatform(
      operatingSystem: platformName,
      environment: <String, String>{
        'DEPOT_TOOLS': path.join('D:', 'depot_tools'),
      },
    );
    group('ProcessRunner for $platform', () {
      test('Returns stdout', () async {
        final FakeProcessManager fakeProcessManager = FakeProcessManager();
        fakeProcessManager.fakeResults = <String, List<ProcessResult>>{
          'echo test': <ProcessResult>[ProcessResult(0, 0, 'output', 'error')],
        };
        final ProcessRunner processRunner = ProcessRunner(
            subprocessOutput: false, platform: platform, processManager: fakeProcessManager);
        final String output = await processRunner.runProcess(<String>['echo', 'test']);
        expect(output, equals('output'));
      });
      test('Throws on process failure', () async {
        final FakeProcessManager fakeProcessManager = FakeProcessManager();
        fakeProcessManager.fakeResults = <String, List<ProcessResult>>{
          'echo test': <ProcessResult>[ProcessResult(0, -1, 'output', 'error')],
        };
        final ProcessRunner processRunner = ProcessRunner(
            subprocessOutput: false, platform: platform, processManager: fakeProcessManager);
        expect(
            expectAsync1((List<String> commandLine) async {
              return processRunner.runProcess(commandLine);
            })(<String>['echo', 'test']),
            throwsA(isInstanceOf<PreparePackageException>()));
      });
    });
    group('ArchiveCreator for $platformName', () {
      ArchiveCreator creator;
      Directory tempDir;
      Directory flutterDir;
      FakeProcessManager processManager;
      final List<List<String>> args = <List<String>>[];
      final List<Map<Symbol, dynamic>> namedArgs = <Map<Symbol, dynamic>>[];
      String flutter;

      Future<Uint8List> fakeHttpReader(Uri url, {Map<String, String> headers}) {
        return Future<Uint8List>.value(Uint8List(0));
      }

      setUp(() async {
        processManager = FakeProcessManager();
        args.clear();
        namedArgs.clear();
        tempDir = Directory.systemTemp.createTempSync('flutter_prepage_package_test.');
        flutterDir = Directory(path.join(tempDir.path, 'flutter'));
        flutterDir.createSync(recursive: true);
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.dev,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        flutter = path.join(creator.flutterRoot.absolute.path, 'bin', 'flutter');
      });

      tearDown(() async {
        tryToDelete(tempDir);
      });

      test('sets PUB_CACHE properly', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'git clone -b dev https://chromium.googlesource.com/external/github.com/flutter/flutter': null,
          'git reset --hard $testRef': null,
          'git remote set-url origin https://github.com/flutter/flutter.git': null,
          'git describe --tags --exact-match $testRef': <ProcessResult>[ProcessResult(0, 0, 'v1.2.3', '')],
        };
        if (platform.isWindows) {
          calls['7za x ${path.join(tempDir.path, 'mingit.zip')}'] = null;
        }
        calls.addAll(<String, List<ProcessResult>>{
          '$flutter doctor': null,
          '$flutter update-packages': null,
          '$flutter precache': null,
          '$flutter ide-config': null,
          '$flutter create --template=app ${createBase}app': null,
          '$flutter create --template=package ${createBase}package': null,
          '$flutter create --template=plugin ${createBase}plugin': null,
          'git clean -f -X **/.packages': null,
        });
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_v1.2.3-dev${platform.isLinux ? '.tar.xz' : '.zip'}');
        if (platform.isWindows) {
          calls['7za a -tzip -mx=9 $archiveName flutter'] = null;
        } else if (platform.isMacOS) {
          calls['zip -r -9 $archiveName flutter'] = null;
        } else if (platform.isLinux) {
          calls['tar cJf $archiveName flutter'] = null;
        }
        processManager.fakeResults = calls;
        await creator.initializeRepo();
        await creator.createArchive();
        expect(
          verify(processManager.start(
            captureAny,
            workingDirectory: captureAnyNamed('workingDirectory'),
            environment: captureAnyNamed('environment'),
          )).captured[2]['PUB_CACHE'],
          endsWith(path.join('flutter', '.pub-cache')),
        );
      });

      test('calls the right commands for archive output', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'git clone -b dev https://chromium.googlesource.com/external/github.com/flutter/flutter': null,
          'git reset --hard $testRef': null,
          'git remote set-url origin https://github.com/flutter/flutter.git': null,
          'git describe --tags --exact-match $testRef': <ProcessResult>[ProcessResult(0, 0, 'v1.2.3', '')],
        };
        if (platform.isWindows) {
          calls['7za x ${path.join(tempDir.path, 'mingit.zip')}'] = null;
        }
        calls.addAll(<String, List<ProcessResult>>{
          '$flutter doctor': null,
          '$flutter update-packages': null,
          '$flutter precache': null,
          '$flutter ide-config': null,
          '$flutter create --template=app ${createBase}app': null,
          '$flutter create --template=package ${createBase}package': null,
          '$flutter create --template=plugin ${createBase}plugin': null,
          'git clean -f -X **/.packages': null,
        });
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_v1.2.3-dev${platform.isLinux ? '.tar.xz' : '.zip'}');
        if (platform.isWindows) {
          calls['7za a -tzip -mx=9 $archiveName flutter'] = null;
        } else if (platform.isMacOS) {
          calls['zip -r -9 $archiveName flutter'] = null;
        } else if (platform.isLinux) {
          calls['tar cJf $archiveName flutter'] = null;
        }
        processManager.fakeResults = calls;
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.dev,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        await creator.initializeRepo();
        await creator.createArchive();
        processManager.verifyCalls(calls.keys.toList());
      });

      test('throws when a command errors out', () async {
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'git clone -b dev https://chromium.googlesource.com/external/github.com/flutter/flutter':
              <ProcessResult>[ProcessResult(0, 0, 'output1', '')],
          'git reset --hard $testRef': <ProcessResult>[ProcessResult(0, -1, 'output2', '')],
        };
        processManager.fakeResults = calls;
        expect(expectAsync0(creator.initializeRepo),
            throwsA(isInstanceOf<PreparePackageException>()));
      });

      test('non-strict mode calls the right commands', () async {
        final String createBase = path.join(tempDir.absolute.path, 'create_');
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          'git clone -b dev https://chromium.googlesource.com/external/github.com/flutter/flutter': null,
          'git reset --hard $testRef': null,
          'git remote set-url origin https://github.com/flutter/flutter.git': null,
          'git describe --tags --abbrev=0 $testRef': <ProcessResult>[ProcessResult(0, 0, 'v1.2.3', '')],
        };
        if (platform.isWindows) {
          calls['7za x ${path.join(tempDir.path, 'mingit.zip')}'] = null;
        }
        calls.addAll(<String, List<ProcessResult>>{
          '$flutter doctor': null,
          '$flutter update-packages': null,
          '$flutter precache': null,
          '$flutter ide-config': null,
          '$flutter create --template=app ${createBase}app': null,
          '$flutter create --template=package ${createBase}package': null,
          '$flutter create --template=plugin ${createBase}plugin': null,
          'git clean -f -X **/.packages': null,
        });
        final String archiveName = path.join(tempDir.absolute.path,
            'flutter_${platformName}_v1.2.3-dev${platform.isLinux ? '.tar.xz' : '.zip'}');
        if (platform.isWindows) {
          calls['7za a -tzip -mx=9 $archiveName flutter'] = null;
        } else if (platform.isMacOS) {
          calls['zip -r -9 $archiveName flutter'] = null;
        } else if (platform.isLinux) {
          calls['tar cJf $archiveName flutter'] = null;
        }
        processManager.fakeResults = calls;
        creator = ArchiveCreator(
          tempDir,
          tempDir,
          testRef,
          Branch.dev,
          strict: false,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
          httpReader: fakeHttpReader,
        );
        await creator.initializeRepo();
        await creator.createArchive();
        processManager.verifyCalls(calls.keys.toList());
      });
    });

    group('ArchivePublisher for $platformName', () {
      FakeProcessManager processManager;
      Directory tempDir;

      setUp(() async {
        processManager = FakeProcessManager();
        tempDir = Directory.systemTemp.createTempSync('flutter_prepage_package_test.');
      });

      tearDown(() async {
        tryToDelete(tempDir);
      });

      test('calls the right processes', () async {
        final String releasesName = 'releases_$platformName.json';
        final String archiveName = platform.isLinux ? 'archive.tar.xz' : 'archive.zip';
        final String archiveMime = platform.isLinux ? 'application/x-gtar' : 'application/zip';
        final String archivePath = path.join(tempDir.absolute.path, archiveName);
        final String gsArchivePath = 'gs://flutter_infra/releases/stable/$platformName/$archiveName';
        final String jsonPath = path.join(tempDir.absolute.path, releasesName);
        final String gsJsonPath = 'gs://flutter_infra/releases/$releasesName';
        final String releasesJson = '''{
  "base_url": "https://storage.googleapis.com/flutter_infra/releases",
  "current_release": {
    "beta": "3ea4d06340a97a1e9d7cae97567c64e0569dcaa2",
    "dev": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"
  },
  "releases": [
    {
      "hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0",
      "channel": "dev",
      "version": "v0.2.3",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "dev/$platformName/flutter_${platformName}_v0.2.3-dev.zip",
      "sha256": "4fe85a822093e81cb5a66c7fc263f68de39b5797b294191b6d75e7afcc86aff8"
    },
    {
      "hash": "b9bd51cc36b706215915711e580851901faebb40",
      "channel": "beta",
      "version": "v0.2.2",
      "release_date": "2018-03-16T18:48:13.375013Z",
      "archive": "dev/$platformName/flutter_${platformName}_v0.2.2-dev.zip",
      "sha256": "6073331168cdb37a4637a5dc073d6a7ef4e466321effa2c529fa27d2253a4d4b"
    },
    {
      "hash": "$testRef",
      "channel": "stable",
      "version": "v0.0.0",
      "release_date": "2018-03-20T01:47:02.851729Z",
      "archive": "stable/$platformName/flutter_${platformName}_v0.0.0-dev.zip",
      "sha256": "5dd34873b3a3e214a32fd30c2c319a0f46e608afb72f0d450b2d621a6d02aebd"
    }
  ]
}
''';
        File(jsonPath).writeAsStringSync(releasesJson);
        File(archivePath).writeAsStringSync('archive contents');
        final String gsutilCall = platform.isWindows
            ? 'python ${path.join("D:", "depot_tools", "gsutil.py")}'
            : 'gsutil.py';
        final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
          '$gsutilCall -- rm $gsArchivePath': null,
          '$gsutilCall -- -h Content-Type:$archiveMime cp $archivePath $gsArchivePath': null,
          '$gsutilCall -- cp $gsJsonPath $jsonPath': null,
          '$gsutilCall -- rm $gsJsonPath': null,
          '$gsutilCall -- -h Content-Type:application/json cp $jsonPath $gsJsonPath': null,
        };
        processManager.fakeResults = calls;
        final File outputFile = File(path.join(tempDir.absolute.path, archiveName));
        assert(tempDir.existsSync());
        final ArchivePublisher publisher = ArchivePublisher(
          tempDir,
          testRef,
          Branch.stable,
          'v1.2.3',
          outputFile,
          processManager: processManager,
          subprocessOutput: false,
          platform: platform,
        );
        assert(tempDir.existsSync());
        await publisher.publishArchive();
        processManager.verifyCalls(calls.keys.toList());
        final File releaseFile = File(jsonPath);
        expect(releaseFile.existsSync(), isTrue);
        final String contents = releaseFile.readAsStringSync();
        // Make sure new data is added.
        expect(contents, contains('"hash": "$testRef"'));
        expect(contents, contains('"channel": "stable"'));
        expect(contents, contains('"archive": "stable/$platformName/$archiveName"'));
        expect(contents, contains('"sha256": "f69f4865f861193a91d1c5544a894167a7137b788d10bac8edbf5d095f45cb4d"'));
        // Make sure existing entries are preserved.
        expect(contents, contains('"hash": "5a58b36e36b8d7aace89d3950e6deb307956a6a0"'));
        expect(contents, contains('"hash": "b9bd51cc36b706215915711e580851901faebb40"'));
        expect(contents, contains('"channel": "beta"'));
        expect(contents, contains('"channel": "dev"'));
        // Make sure old matching entries are removed.
        expect(contents, isNot(contains('v0.0.0')));
        final Map<String, dynamic> jsonData = json.decode(contents);
        final List<dynamic> releases = jsonData['releases'];
        expect(releases.length, equals(3));
        // Make sure the new entry is first (and hopefully it takes less than a
        // minute to go from publishArchive above to this line!).
        expect(
          DateTime.now().difference(DateTime.parse(releases[0]['release_date'])),
          lessThan(const Duration(minutes: 1)),
        );
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        expect(contents, equals(encoder.convert(jsonData)));
      });
    });
  }
}
