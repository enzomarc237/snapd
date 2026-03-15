// Represents the result of executing a shell command.
class CommandResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;

  const CommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
  });

  bool get isSuccess => exitCode == 0;

  @override
  String toString() =>
      'CommandResult(exitCode: $exitCode, stdout: $stdout, stderr: $stderr)';
}
