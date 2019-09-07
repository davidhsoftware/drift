import 'package:analyzer/src/context/context_root.dart'; // ignore: implementation_imports
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/plugin/folding_mixin.dart';
import 'package:analyzer_plugin/plugin/highlights_mixin.dart';
import 'package:analyzer_plugin/plugin/outline_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:moor_generator/src/backends/plugin/backend/file_tracker.dart';
import 'package:moor_generator/src/backends/plugin/services/folding.dart';
import 'package:moor_generator/src/backends/plugin/services/highlights.dart';
import 'package:moor_generator/src/backends/plugin/services/outline.dart';
import 'package:moor_generator/src/backends/plugin/services/requests.dart';

import 'backend/driver.dart';
import 'backend/logger.dart';

class MoorPlugin extends ServerPlugin
    with OutlineMixin, HighlightsMixin, FoldingMixin {
  MoorPlugin(ResourceProvider provider) : super(provider) {
    setupLogger(this);
  }

  @override
  final List<String> fileGlobsToAnalyze = const ['*.moor'];
  @override
  final String name = 'Moor plugin';
  @override
  // docs say that this should a version of _this_ plugin, but they lie. this
  // version will be used to determine compatibility with the analyzer
  final String version = '2.0.0-alpha.0';
  @override
  final String contactInfo =
      'Create an issue at https://github.com/simolus3/moor/';

  @override
  MoorDriver createAnalysisDriver(plugin.ContextRoot contextRoot) {
    // create an analysis driver we can use to resolve Dart files
    final analyzerRoot = ContextRoot(contextRoot.root, contextRoot.exclude,
        pathContext: resourceProvider.pathContext)
      ..optionsFilePath = contextRoot.optionsFile;

    final builder = ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = analysisDriverScheduler
      ..byteStore = byteStore
      ..performanceLog = performanceLog
      ..fileContentOverlay = fileContentOverlay;

    // todo we listen because we copied this from the angular plugin. figure out
    // why exactly this is necessary
    final dartDriver = builder.buildDriver(analyzerRoot)
      ..results.listen((_) {}) // Consume the stream, otherwise we leak.
      ..exceptions.listen((_) {}); // Consume the stream, otherwise we leak.;

    final tracker = FileTracker();
    return MoorDriver(tracker, analysisDriverScheduler, dartDriver,
        fileContentOverlay, resourceProvider);
  }

  @override
  void contentChanged(String path) {
    _moorDriverForPath(path)?.handleFileChanged(path);
  }

  MoorDriver _moorDriverForPath(String path) {
    final driver = super.driverForPath(path);

    if (driver is! MoorDriver) return null;
    return driver as MoorDriver;
  }

  Future<MoorRequest> _createMoorRequest(String path) async {
    final driver = _moorDriverForPath(path);
    final task = await driver.parseMoorFile(path);

    return MoorRequest(task, resourceProvider);
  }

  @override
  List<OutlineContributor> getOutlineContributors(String path) {
    return const [MoorOutlineContributor()];
  }

  @override
  Future<OutlineRequest> getOutlineRequest(String path) =>
      _createMoorRequest(path);

  @override
  List<HighlightsContributor> getHighlightsContributors(String path) {
    return const [MoorHighlightContributor()];
  }

  @override
  Future<HighlightsRequest> getHighlightsRequest(String path) =>
      _createMoorRequest(path);

  @override
  List<FoldingContributor> getFoldingContributors(String path) {
    return const [MoorFoldingContributor()];
  }

  @override
  Future<FoldingRequest> getFoldingRequest(String path) =>
      _createMoorRequest(path);
}
