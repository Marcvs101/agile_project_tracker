// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:completion/completion.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../runner/flutter_command.dart';

class ShellCompletionCommand extends FlutterCommand {
  ShellCompletionCommand() {
    argParser.addFlag(
      'overwrite',
      defaultsTo: false,
      negatable: true,
      help: 'Causes the given shell completion setup script to be overwritten if it already exists.',
    );
  }

  @override
  final String name = 'bash-completion';

  @override
  final String description = 'Output command line shell completion setup scripts.\n\n'
      'This command prints the flutter command line completion setup script for Bash and Zsh. To '
      'use it, specify an output file and follow the instructions in the generated output file to '
      'install it in your shell environment. Once it is sourced, your shell will be able to '
      'complete flutter commands and options.';

  @override
  final List<String> aliases = <String>['zsh-completion'];

  @override
  bool get shouldUpdateCache => false;

  /// Return null to disable analytics recording of the `bash-completion` command.
  @override
  Future<String> get usagePath async => null;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.rest.length > 1) {
      throwToolExit('Too many arguments given to bash-completion command.', exitCode: 1);
    }

    if (argResults.rest.isEmpty || argResults.rest.first == '-') {
      stdout.write(generateCompletionScript(<String>['flutter']));
      return null;
    }

    final File outputFile = fs.file(argResults.rest.first);
    if (outputFile.existsSync() && !argResults['overwrite']) {
      throwToolExit(
        'Output file ${outputFile.path} already exists, will not overwrite. '
            'Use --overwrite to force overwriting existing output file.',
        exitCode: 1,
      );
    }
    try {
      outputFile.writeAsStringSync(generateCompletionScript(<String>['flutter']));
    } on FileSystemException catch (error) {
      throwToolExit('Unable to write shell completion setup script.\n$error', exitCode: 1);
    }

    return null;
  }
}
