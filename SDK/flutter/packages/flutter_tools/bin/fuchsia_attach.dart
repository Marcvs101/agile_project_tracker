// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';

import 'package:flutter_tools/runner.dart' as runner;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/attach.dart';
import 'package:flutter_tools/src/commands/doctor.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

final ArgParser parser = ArgParser()
  ..addOption('build-dir', help: 'The fuchsia build directory')
  ..addOption('dart-sdk', help: 'The prebuilt dart SDK')
  ..addOption('target', help: 'The GN target to attach to')
  ..addOption('entrypoint', defaultsTo: 'main.dart', help: 'The filename of the main method. Defaults to main.dart')
  ..addOption('device', help: 'The device id to attach to')
  ..addOption('dev-finder', help: 'The location of the dev_finder binary')
  ..addFlag('verbose', negatable: true);

// Track the original working directory so that the tool can find the
// flutter repo in third_party.
String originalWorkingDirectory;

Future<void> main(List<String> args) async {
  final ArgResults argResults = parser.parse(args);
  final bool verbose = argResults['verbose'];
  final String target = argResults['target'];
  final List<String> targetParts = _extractPathAndName(target);
  final String path = targetParts[0];
  final String name = targetParts[1];
  final File dartSdk = fs.file(argResults['dart-sdk']);
  final String buildDirectory = argResults['build-dir'];
  final File frontendServer = fs.file('$buildDirectory/host_x64/gen/third_party/flutter/frontend_server/frontend_server_tool.snapshot');
  final File sshConfig = fs.file('$buildDirectory/ssh-keys/ssh_config');
  final File devFinder = fs.file(argResults['dev-finder']);
  final File platformKernelDill = fs.file('$buildDirectory/flutter_runner_patched_sdk/platform_strong.dill');
  final File flutterPatchedSdk = fs.file('$buildDirectory/flutter_runner_patched_sdk');
  final String packages = '$buildDirectory/dartlang/gen/$path/${name}_dart_library.packages';
  final String outputDill = '$buildDirectory/${name}_tmp.dill';

  // TODO(jonahwilliams): running from fuchsia root hangs hot reload for some reason.
  // switch to the project root directory and run from there.
  originalWorkingDirectory = fs.currentDirectory.path;
  fs.currentDirectory = path;

  if (!devFinder.existsSync()) {
    print('Error: dev_finder not found at ${devFinder.path}.');
    return 1;
  }
  if (!frontendServer.existsSync()) {
    print(
      'Error: frontend_server not found at ${frontendServer.path}. This '
      'Usually means you ran fx set without specifying '
      '--args=flutter_profile=true.'
    );
    return 1;
  }

  // Check for a package with a lib directory.
  final String entrypoint = argResults['entrypoint'];
  String targetFile = 'lib/$entrypoint';
  if (!fs.file(targetFile).existsSync()) {
    // Otherwise assume the package is flat.
    targetFile = entrypoint;
  }
  final List<String> command = <String>[
    'attach',
    '--module',
    name,
    '--isolate-filter',
    name,
    '--target',
    targetFile,
    '--target-model',
    'flutter', // TODO(jonahwilliams): change to flutter_runner when dart SDK rolls
    '--output-dill',
    outputDill,
    '--packages',
    packages,
  ];
  final String deviceName = argResults['device'];
  if (deviceName != null && deviceName.isNotEmpty) {
    command.addAll(<String>['-d', deviceName]);
  }
  if (verbose) {
    command.add('--verbose');
  }
  Cache.disableLocking(); // ignore: invalid_use_of_visible_for_testing_member
  await runner.run(
    command,
    <FlutterCommand>[
      _FuchsiaAttachCommand(),
      _FuchsiaDoctorCommand(), // If attach fails the tool will attempt to run doctor.
    ],
    verbose: verbose,
    muteCommandLogging: false,
    verboseHelp: false,
    overrides: <Type, Generator>{
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig, devFinder: devFinder),
      Artifacts: () => OverrideArtifacts(
        parent: CachedArtifacts(),
        frontendServer: frontendServer,
        engineDartBinary: dartSdk,
        platformKernelDill: platformKernelDill,
        flutterPatchedSdk: flutterPatchedSdk,
      ),
    },
  );
}

List<String> _extractPathAndName(String gnTarget) {
  // Separate strings like //path/to/target:app into [path/to/target, app]
  final int lastColon = gnTarget.lastIndexOf(':');
  if (lastColon < 0) {
    throwToolExit('invalid path: $gnTarget');
  }
  final String name = gnTarget.substring(lastColon + 1);
  // Skip '//' and chop off after :
  if ((gnTarget.length < 3) || (gnTarget[0] != '/') || (gnTarget[1] != '/')) {
    throwToolExit('invalid path: $gnTarget');
  }
  final String path = gnTarget.substring(2, lastColon);
  return <String>[path, name];
}

class _FuchsiaDoctorCommand extends DoctorCommand {
  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.flutterRoot = '$originalWorkingDirectory/third_party/dart-pkg/git/flutter';
    return super.runCommand();
  }
}

class _FuchsiaAttachCommand extends AttachCommand {
  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.flutterRoot = '$originalWorkingDirectory/third_party/dart-pkg/git/flutter';
    return super.runCommand();
  }
}
