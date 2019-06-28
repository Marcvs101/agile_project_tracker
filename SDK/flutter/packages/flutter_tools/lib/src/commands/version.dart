// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';

class VersionCommand extends FlutterCommand {
  VersionCommand() : super() {
    argParser.addFlag('force',
      abbr: 'f',
      help: 'Force switch to older Flutter versions that do not include a version command',
    );
  }

  @override
  final String name = 'version';

  @override
  final String description = 'List or switch flutter versions.';

  // The first version of Flutter which includes the flutter version command. Switching to older
  // versions will require the user to manually upgrade.
  Version minSupportedVersion = Version.parse('1.2.1');

  Future<List<String>> getTags() async {
    final RunResult runResult = await runCheckedAsync(
      <String>['git', 'tag', '-l', 'v*', '--sort=-creatordate'],
      workingDirectory: Cache.flutterRoot,
    );
    return runResult.toString().split('\n');
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> tags = await getTags();
    if (argResults.rest.isEmpty) {
      tags.forEach(printStatus);
      return const FlutterCommandResult(ExitStatus.success);
    }
    final String version = argResults.rest[0].replaceFirst('v', '');
    if (!tags.contains('v$version')) {
      printError('There is no version: $version');
    }

    // check min supported version
    final Version targetVersion = Version.parse(version);
    bool withForce = false;
    if (targetVersion < minSupportedVersion) {
      if (!argResults['force']) {
        printError(
          'Version command is not supported in $targetVersion and it is supported since version $minSupportedVersion'
          'which means if you switch to version $minSupportedVersion then you can not use version command.'
          'If you really want to switch to version $targetVersion, please use `--force` flag: `flutter version --force $targetVersion`.'
        );
        return const FlutterCommandResult(ExitStatus.success);
      }
      withForce = true;
    }

    try {
      await runCheckedAsync(
        <String>['git', 'checkout', 'v$version'],
        workingDirectory: Cache.flutterRoot,
      );
    } catch (e) {
      throwToolExit('Unable to checkout version branch for version $version.');
    }

    final FlutterVersion flutterVersion = FlutterVersion();

    printStatus('Switching Flutter to version ${flutterVersion.frameworkVersion}${withForce ? ' with force' : ''}');

    // Check for and download any engine and pkg/ updates.
    // We run the 'flutter' shell script re-entrantly here
    // so that it will download the updated Dart and so forth
    // if necessary.
    printStatus('');
    printStatus('Downloading engine...');
    int code = await runCommandAndStreamOutput(<String>[
      fs.path.join('bin', 'flutter'),
      '--no-color',
      'precache',
    ], workingDirectory: Cache.flutterRoot, allowReentrantFlutter: true);

    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    printStatus('');
    printStatus(flutterVersion.toString());

    final String projectRoot = findProjectRoot();
    if (projectRoot != null) {
      printStatus('');
      await pubGet(
        context: PubContext.pubUpgrade,
        directory: projectRoot,
        upgrade: true,
        checkLastModified: false,
      );
    }

    // Run a doctor check in case system requirements have changed.
    printStatus('');
    printStatus('Running flutter doctor...');
    code = await runCommandAndStreamOutput(
      <String>[
        fs.path.join('bin', 'flutter'),
        'doctor',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );

    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    return const FlutterCommandResult(ExitStatus.success);
  }
}
