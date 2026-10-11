/// A local task/result boundary; measurement and model DTOs live in their
/// dedicated contracts. Presentation heuristics are not evidence.
abstract interface class Agent<TTask, TReport> {
  String get agentId;
  Future<TReport> execute(TTask task);
}

