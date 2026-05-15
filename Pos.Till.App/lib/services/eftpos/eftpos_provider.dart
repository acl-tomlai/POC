/// Result returned by an EFTPOS charge/refund.
class EftposResult {
  const EftposResult({
    required this.approved,
    this.authCode,
    this.cardLast4,
    this.terminalReceipt,
    this.declineReason,
  });

  const EftposResult.approved({
    required String this.authCode,
    this.cardLast4,
    this.terminalReceipt,
  })  : approved = true,
        declineReason = null;

  const EftposResult.declined(String reason)
      : approved = false,
        authCode = null,
        cardLast4 = null,
        terminalReceipt = null,
        declineReason = reason;

  final bool approved;
  final String? authCode;
  final String? cardLast4;
  final String? terminalReceipt;
  final String? declineReason;
}

/// Vendor-agnostic EFTPOS terminal interface. v1 ships only
/// [MockEftposProvider]; real terminal SDKs swap in here without touching
/// the payment screen.
abstract class EftposProvider {
  Future<EftposResult> charge({
    required double amount,
    required String orderRef,
  });

  /// Unused in v1 (refunds aren't a shipped feature) but kept on the
  /// interface so vendor implementations match the eventual surface.
  Future<EftposResult> refund({
    required double amount,
    required String authCode,
  });
}
