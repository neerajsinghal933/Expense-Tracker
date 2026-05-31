import 'parsed_transaction.dart';

/// Synchronous ParserService for Phase 1 unit tests.
class ParserService {
  static final ParserService _instance = ParserService._internal();
  factory ParserService() => _instance;
  ParserService._internal();

  static final _amountReg = RegExp(
    r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );
  static final _creditReg = RegExp(
    r'\bcredit(?:ed)?\b|\bcredited\b|\bdeposited\b|\breceived\b|\bcr\b|\bcredit alert\b',
    caseSensitive: false,
  );
  static final _debitReg = RegExp(
    r'\bdebited\b|\bspent\b|\bwithdrawn\b|\bpaid\b|\bsent\b',
    caseSensitive: false,
  );
  static final _refundReg = RegExp(r'\brefund\b', caseSensitive: false);
  static final _upiReg = RegExp(r'\b(?:upi|vpa)\b', caseSensitive: false);
  static final _salaryReg = RegExp(
    r'\bsalary\b|\bpayroll\b|\bctc\b|\bwages\b|\bcompensation\b|\bemployer\b|\bprivate ltd\b|\btechnology private ltd\b',
    caseSensitive: false,
  );
  static final _transferReg = RegExp(
    r'\b(?:imps|neft|rtgs|transfer)\b',
    caseSensitive: false,
  );
  static final _emiReg = RegExp(r'\bemi\b', caseSensitive: false);
  static final _atmReg = RegExp(
    r'\batm\b.*\bwithdraw',
    caseSensitive: false,
  );
  static final _failedReg = RegExp(r'\bfailed\b', caseSensitive: false);
  static final _vpaReg = RegExp(r'([a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+)');

  Future<ParsedTransaction> parseSms({
    required String smsId,
    required String sender,
    required String body,
    required int timestampMs,
  }) async {
    double amount = 0.0;
    String? merchant;
    String? paymentMethod;
    String type = 'unknown';
    double confidence = 0.0;

    final amountMatch = _amountReg.firstMatch(body);
    if (amountMatch != null) {
      final raw = amountMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(raw) ?? 0.0;
      confidence += 0.4;
    }

    if (_failedReg.hasMatch(body)) {
      type = 'failed';
      confidence += 0.5;
    } else if (_refundReg.hasMatch(body)) {
      type = 'refund';
      confidence += 0.5;
    } else if (_emiReg.hasMatch(body)) {
      type = 'emi';
      confidence += 0.45;
    } else if (_atmReg.hasMatch(body)) {
      type = 'atm_withdrawal';
      confidence += 0.45;
    } else if (_salaryReg.hasMatch(body)) {
      type = 'credit';
      confidence += 0.35;
    } else if (_creditReg.hasMatch(body)) {
      type = 'credit';
      confidence += 0.2;
    }

    if (_debitReg.hasMatch(body) && type == 'unknown') {
      type = 'debit';
      confidence += 0.4;
    }

    if (_transferReg.hasMatch(body)) {
      paymentMethod ??= _detectTransferMethod(body);
      if (type == 'unknown') {
        type = _creditReg.hasMatch(body) ? 'credit' : 'debit';
      }
      confidence += 0.15;
    }

    if (type == 'credit' && _salaryReg.hasMatch(body)) {
      confidence += 0.15;
    }

    if (_upiReg.hasMatch(body)) {
      paymentMethod = 'UPI';
      confidence += 0.15;
    }

    final merchantPatterns = [
      RegExp(r'\b(?:at|to|for)\s+([A-Za-z0-9 &\-\.,]{3,60})',
          caseSensitive: false),
      RegExp(r'merchant[:\s]+([A-Za-z0-9 &\-\.,]{3,60})', caseSensitive: false),
      RegExp(r'via\s+([A-Za-z0-9 &\-\.,]{3,60})', caseSensitive: false),
      RegExp(r'info[:\s]+([A-Za-z0-9 &\-\.,]{3,60})', caseSensitive: false),
    ];
    for (final pat in merchantPatterns) {
      final mm = pat.firstMatch(body);
      if (mm != null) {
        merchant = _cleanMerchant(mm.group(1));
        confidence += 0.2;
        break;
      }
    }

    final vpaMatch = _vpaReg.firstMatch(body);
    if (vpaMatch != null) {
      paymentMethod ??= 'UPI';
      merchant ??= vpaMatch.group(1);
      confidence += 0.1;
    }

    confidence = confidence.clamp(0.0, 1.0);

    return ParsedTransaction(
      id: smsId,
      rawText: body,
      amount: amount,
      currency: 'INR',
      type: _parseType(type),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      merchantName: merchant,
      paymentMethod: paymentMethod,
      reference: null,
      balance: null,
      confidence: confidence,
      parsedBy: 'sync',
    );
  }

  String? _detectTransferMethod(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('imps')) return 'IMPS';
    if (lower.contains('neft')) return 'NEFT';
    if (lower.contains('rtgs')) return 'RTGS';
    return 'Transfer';
  }

  String? _cleanMerchant(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    if (s.endsWith(' on')) s = s.substring(0, s.length - 3).trim();
    if (s.endsWith('.')) s = s.substring(0, s.length - 1).trim();
    return s.isEmpty ? null : s;
  }

  TransactionType _parseType(String s) {
    switch (s) {
      case 'debit':
        return TransactionType.debit;
      case 'credit':
        return TransactionType.credit;
      case 'refund':
        return TransactionType.refund;
      case 'emi':
        return TransactionType.emi;
      case 'atm_withdrawal':
        return TransactionType.atm_withdrawal;
      case 'failed':
        return TransactionType.failed;
      default:
        return TransactionType.unknown;
    }
  }
}
