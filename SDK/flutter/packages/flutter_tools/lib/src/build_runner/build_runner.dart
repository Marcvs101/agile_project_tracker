// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:build_daemon/data/build_status.dart';
import 'package:build_daemon/data/build_target.dart';
import 'package:build_runner_core/build_runner_core.dart' hide BuildStatus;
import 'package:build_daemon/data/server_log.dart';
import 'package:build_daemon/data/build_status.dart' as build;
import 'package:build_daemon/client.dart';
import 'package:yaml/yaml.dart';
import 'package:crypto/crypto.dart' show md5;

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process_manager.dart';
import '../codegen.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../project.dart';
import 'build_script_generator.dart';

/// The minimum version of build_runner we can support in the flutter tool.
const String kMinimumBuildRunnerVersion = '1.2.8';

/// A wrapper for a build_runner process which delegates to a generated
/// build script.
///
/// This is only enabled if [experimentalBuildEnabled] is true, and only for
/// external flutter users.
class BuildRunner extends CodeGenerator {
  const BuildRunner();

  @override
  Future<void> generateBuildScript(FlutterProject flutterProject) async {
    final Directory entrypointDirectory = fs.directory(fs.path.join(flutterProject.dartTool.path, 'build', 'entrypoint'));
    final Directory generatedDirectory = fs.directory(fs.path.join(flutterProject.dartTool.path, 'flutter_tool'));
    final File buildScript = entrypointDirectory.childFile('build.dart');
    final File buildSnapshot = entrypointDirectory.childFile('build.dart.snapshot');
    final File scriptIdFile = entrypointDirectory.childFile('id');
    final File syntheticPubspec = generatedDirectory.childFile('pubspec.yaml');

    // Check if contents of builders changed. If so, invalidate build script
    // and regnerate.
    final YamlMap builders = flutterProject.builders;
    final List<int> appliedBuilderDigest = _produceScriptId(builders);
    if (scriptIdFile.existsSync() && buildSnapshot.existsSync()) {
      final List<int> previousAppliedBuilderDigest = scriptIdFile.readAsBytesSync();
      bool digestsAreEqual = false;
      if (appliedBuilderDigest.length == previousAppliedBuilderDigest.length) {
        digestsAreEqual = true;
        for (int i = 0; i < appliedBuilderDigest.length; i++) {
          if (appliedBuilderDigest[i] != previousAppliedBuilderDigest[i]) {
            digestsAreEqual = false;
            break;
          }
        }
      }
      if (digestsAreEqual) {
        return;
      }
    }
    // Clean-up all existing artifacts.
    if (flutterProject.dartTool.existsSync()) {
      flutterProject.dartTool.deleteSync(recursive: true);
    }
    final Status status = logger.startProgress('generating build script...', timeout: null);
    try {
      generatedDirectory.createSync(recursive: true);
      entrypointDirectory.createSync(recursive: true);
      flutterProject.dartTool.childDirectory('build').childDirectory('generated').createSync(recursive: true);
      final StringBuffer stringBuffer = StringBuffer();

      stringBuffer.writeln('name: flutter_tool');
      stringBuffer.writeln('dependencies:');
      final YamlMap builders = flutterProject.builders;
      if (builders != null) {
        for (String name in builders.keys) {
          final Object node = builders[name];
          stringBuffer.writeln('  $name: $node');
        }
      }
      stringBuffer.writeln('  build_runner: ^$kMinimumBuildRunnerVersion');
      await syntheticPubspec.writeAsString(stringBuffer.toString());

      await pubGet(
        context: PubContext.pubGet,
        directory: generatedDirectory.path,
        upgrade: false,
        checkLastModified: false,
      );
      if (!scriptIdFile.existsSync()) {
        scriptIdFile.createSync(recursive: true);
      }
      scriptIdFile.writeAsBytesSync(appliedBuilderDigest);
      final PackageGraph packageGraph = PackageGraph.forPath(syntheticPubspec.parent.path);
      final BuildScriptGenerator buildScriptGenerator = const BuildScriptGeneratorFactory().create(flutterProject, packageGraph);
      await buildScriptGenerator.generateBuildScript();
      final ProcessResult result = await processManager.run(<String>[
        artifacts.getArtifactPath(Artifact.engineDartBinary),
        '--snapshot=${buildSnapshot.path}',
        '--snapshot-kind=app-jit',
        '--packages=${fs.path.join(generatedDirectory.path, '.packages')}',
        buildScript.path,
      ]);
      if (result.exitCode != 0) {
        throwToolExit('Error generating build_script snapshot: ${result.stderr}');
      }
    } finally {
      status.stop();
    }
  }

  @override
  Future<CodegenDaemon> daemon(
    FlutterProject flutterProject, {
    String mainPath,
    bool linkPlatformKernelIn = false,
    bool targetProductVm = false,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions = const <String> [],
  }) async {
    await generateBuildScript(flutterProject);
    final String engineDartBinaryPath = artifacts.getArtifactPath(Artifact.engineDartBinary);
    final File buildSnapshot = flutterProject
        .dartTool
        .childDirectory('build')
        .childDirectory('entrypoint')
        .childFile('build.dart.snapshot');
    final String scriptPackagesPath = flutterProject
        .dartTool
        .childDirectory('flutter_tool')
        .childFile('.packages')
        .path;
    final Status status = logger.startProgress('starting build daemon...', timeout: null);
    BuildDaemonClient buildDaemonClient;
    try {
      final List<String> command = <String>[
        engineDartBinaryPath,
        '--packages=$scriptPackagesPath',
        buildSnapshot.path,
        'daemon',
         '--skip-build-script-check',
         '--delete-conflicting-outputs'
      ];
      buildDaemonClient = await BuildDaemonClient.connect(flutterProject.directory.path, command, logHandler: (ServerLog log) => printTrace(log.toString()));
    } finally {
      status.stop();
    }
    buildDaemonClient.registerBuildTarget(DefaultBuildTarget((DefaultBuildTargetBuilder builder) {
      builder.target = flutterProject.manifest.appName;
    }));
    return _BuildRunnerCodegenDaemon(buildDaemonClient);
  }
}

class _BuildRunnerCodegenDaemon implements CodegenDaemon {
  _BuildRunnerCodegenDaemon(this.buildDaemonClient);

  final BuildDaemonClient buildDaemonClient;

  @override
  CodegenStatus get lastStatus => _lastStatus;
  CodegenStatus _lastStatus;

  @override
  Stream<CodegenStatus> get buildResults => buildDaemonClient.buildResults.map((build.BuildResults results) {
    if (results.results.first.status == BuildStatus.failed) {
      return _lastStatus = CodegenStatus.Failed;
    }
    if (results.results.first.status == BuildStatus.started) {
      return _lastStatus = CodegenStatus.Started;
    }
    if (results.results.first.status == BuildStatus.succeeded) {
      return _lastStatus = CodegenStatus.Succeeded;
    }
    _lastStatus = null;
    return null;
  });

  @override
  void startBuild() {
    buildDaemonClient.startBuild();
  }
}

// Sorts the builders by name and produces a hashcode of the resulting iterable.
List<int> _produceScriptId(YamlMap builders) {
  if (builders == null || builders.isEmpty) {
    return md5.convert(platform.version.codeUnits).bytes;
  }
  final List<String> orderedBuilders = builders.keys
    .cast<String>()
    .toList()..sort();
  return md5.convert(orderedBuilders
    .followedBy(<String>[platform.version])
    .join('').codeUnits).bytes;
}
