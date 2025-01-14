import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:drift_dev/src/backends/plugin/services/requests.dart';

class MoorCompletingContributor implements CompletionContributor {
  const MoorCompletingContributor();

  @override
  Future<void> computeSuggestions(
      MoorCompletionRequest request, CompletionCollector collector) {
    if (request.isMoorAndParsed) {
      final autoComplete = request.parsedMoor.parseResult.autoCompleteEngine;
      if (autoComplete == null) return Future.value();

      final results = autoComplete.suggestCompletions(request.offset);

      // todo: Fix calculation in sqlparser. Then, set offset to results.anchor
      // and length to results.lengthBefore
      collector
        ..offset = request.offset // should be results.anchor
        ..length = 0; // should be results.lengthBefore

      for (final suggestion in results.suggestions) {
        collector.addSuggestion(CompletionSuggestion(
          CompletionSuggestionKind.KEYWORD,
          suggestion.relevance,
          suggestion.code,
          0,
          0,
          false,
          false,
        ));
      }
    }
    return Future.value();
  }
}
