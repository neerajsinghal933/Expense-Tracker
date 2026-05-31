import '../../data/repositories/merchant_rule_repository.dart';
import '../../domain/constants/category_constants.dart';
import '../../services/parser/merchant_utils.dart';
import '../../services/parser/parsed_transaction.dart';

class CategoryMatch {
  final String categoryId;
  final double confidence;
  final String source;

  const CategoryMatch({
    required this.categoryId,
    required this.confidence,
    required this.source,
  });
}

class CategorizationService {
  CategorizationService(this._merchantRules);

  final MerchantRuleRepository _merchantRules;

  static const _keywordRules = <String, String>{
    // Food and dining
    'rolls mania': CategoryIds.food,
    'rollsmania': CategoryIds.food,
    'rolls': CategoryIds.food,
    'swiggy': CategoryIds.food,
    'zomato': CategoryIds.food,
    'dominos': CategoryIds.food,
    'domino': CategoryIds.food,
    'pizza hut': CategoryIds.food,
    'kfc': CategoryIds.food,
    'mcdonald': CategoryIds.food,
    'burger king': CategoryIds.food,
    'subway': CategoryIds.food,
    'starbucks': CategoryIds.food,
    'cafe': CategoryIds.food,
    'coffee': CategoryIds.food,
    'tea': CategoryIds.food,
    'restaurant': CategoryIds.food,
    'dining': CategoryIds.food,
    'food': CategoryIds.food,
    'kitchen': CategoryIds.food,
    'bakery': CategoryIds.food,
    'biryani': CategoryIds.food,
    'dosa': CategoryIds.food,
    'canteen': CategoryIds.food,

    // Shopping, groceries, and retail
    'amazon': CategoryIds.shopping,
    'flipkart': CategoryIds.shopping,
    'myntra': CategoryIds.shopping,
    'ajio': CategoryIds.shopping,
    'nykaa': CategoryIds.shopping,
    'meesho': CategoryIds.shopping,
    'snapdeal': CategoryIds.shopping,
    'tatacliq': CategoryIds.shopping,
    'tata cliq': CategoryIds.shopping,
    'croma': CategoryIds.shopping,
    'reliance digital': CategoryIds.shopping,
    'dmart': CategoryIds.shopping,
    'd mart': CategoryIds.shopping,
    'bigbasket': CategoryIds.shopping,
    'big basket': CategoryIds.shopping,
    'blinkit': CategoryIds.shopping,
    'zepto': CategoryIds.shopping,
    'instamart': CategoryIds.shopping,
    'supermarket': CategoryIds.shopping,
    'grocery': CategoryIds.shopping,
    'mall': CategoryIds.shopping,
    'retail': CategoryIds.shopping,
    'store': CategoryIds.shopping,
    'shopping': CategoryIds.shopping,

    // Transport and fuel
    'uber': CategoryIds.transport,
    'ola': CategoryIds.transport,
    'rapido': CategoryIds.transport,
    'metro': CategoryIds.transport,
    'irctc': CategoryIds.transport,
    'railway': CategoryIds.transport,
    'petrol': CategoryIds.transport,
    'diesel': CategoryIds.transport,
    'fuel': CategoryIds.transport,
    'hpcl': CategoryIds.transport,
    'bpcl': CategoryIds.transport,
    'indianoil': CategoryIds.transport,
    'indian oil': CategoryIds.transport,
    'shell': CategoryIds.transport,

    // Bills and utilities
    'jio': CategoryIds.bills,
    'airtel': CategoryIds.bills,
    'vodafone': CategoryIds.bills,
    'vi ': CategoryIds.bills,
    'bsnl': CategoryIds.bills,
    'electricity': CategoryIds.bills,
    'water bill': CategoryIds.bills,
    'gas bill': CategoryIds.bills,
    'broadband': CategoryIds.bills,
    'wifi': CategoryIds.bills,

    // Entertainment
    'netflix': CategoryIds.entertainment,
    'prime video': CategoryIds.entertainment,
    'hotstar': CategoryIds.entertainment,
    'disney': CategoryIds.entertainment,
    'spotify': CategoryIds.entertainment,
    'bookmyshow': CategoryIds.entertainment,
    'book my show': CategoryIds.entertainment,
    'pvr': CategoryIds.entertainment,
    'inox': CategoryIds.entertainment,

    // Health
    'pharmacy': CategoryIds.health,
    'apollo pharmacy': CategoryIds.health,
    'medplus': CategoryIds.health,
    'pharmeasy': CategoryIds.health,
    '1mg': CategoryIds.health,
    'hospital': CategoryIds.health,
    'clinic': CategoryIds.health,
    'doctor': CategoryIds.health,
    'diagnostic': CategoryIds.health,

    // Investments, home, education, insurance, subscriptions
    'mutual fund': CategoryIds.investment,
    'sip': CategoryIds.investment,
    'zerodha': CategoryIds.investment,
    'groww': CategoryIds.investment,
    'upstox': CategoryIds.investment,
    'nps': CategoryIds.investment,
    'rent': CategoryIds.home,
    'maintenance': CategoryIds.home,
    'society': CategoryIds.home,
    'home': CategoryIds.home,
    'ikea': CategoryIds.home,
    'urban company': CategoryIds.home,
    'school': CategoryIds.education,
    'college': CategoryIds.education,
    'course': CategoryIds.education,
    'udemy': CategoryIds.education,
    'coursera': CategoryIds.education,
    'flight': CategoryIds.travel,
    'hotel': CategoryIds.travel,
    'makemytrip': CategoryIds.travel,
    'goibibo': CategoryIds.travel,
    'airbnb': CategoryIds.travel,
    'insurance': CategoryIds.insurance,
    'policy': CategoryIds.insurance,
    'lic': CategoryIds.insurance,
    'subscription': CategoryIds.subscriptions,
    'google one': CategoryIds.subscriptions,
    'icloud': CategoryIds.subscriptions,

    // Income, transfer, and loans
    'salary': CategoryIds.salary,
    'payroll': CategoryIds.salary,
    'wages': CategoryIds.salary,
    'employer': CategoryIds.salary,
    'private ltd': CategoryIds.salary,
    'technology private ltd': CategoryIds.salary,
    'bny mellon': CategoryIds.salary,
    'emi': CategoryIds.emi,
  };

  static String? suggestCategoryId({
    String? merchantName,
    required String rawText,
  }) {
    final haystack =
        '${normalizeMerchantName(rawText)} ${normalizeMerchantName(merchantName)}';

    for (final entry in _keywordRules.entries) {
      if (haystack.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  Future<CategoryMatch> categorize(ParsedTransaction parsed) async {
    final lowerRaw = parsed.rawText.toLowerCase();
    final salaryLikeCredit = parsed.type == TransactionType.credit &&
        (lowerRaw.contains('salary') ||
            lowerRaw.contains('payroll') ||
            lowerRaw.contains('wages') ||
            lowerRaw.contains('employer') ||
            lowerRaw.contains('private ltd') ||
            lowerRaw.contains('technology private ltd') ||
            lowerRaw.contains('bny mellon'));
    if (salaryLikeCredit) {
      return const CategoryMatch(
        categoryId: CategoryIds.salary,
        confidence: 0.9,
        source: 'type',
      );
    }

    final merchant = parsed.merchantName ?? '';
    final normalized = normalizeMerchantName(merchant);
    final haystack = '${normalizeMerchantName(parsed.rawText)} $normalized';

    final rules = await _merchantRules.getAllOrdered();
    for (final rule in rules) {
      final pattern = rule.pattern?.trim().toLowerCase() ?? '';
      if (pattern.isEmpty) continue;
      if (haystack.contains(pattern) && rule.categoryId != null) {
        return CategoryMatch(
          categoryId: rule.categoryId!,
          confidence: 0.92,
          source: rule.isUserDefined ? 'learned' : 'rule',
        );
      }
    }

    final keywordCategory = suggestCategoryId(
      merchantName: parsed.merchantName,
      rawText: parsed.rawText,
    );
    if (keywordCategory != null) {
      return CategoryMatch(
        categoryId: keywordCategory,
        confidence: 0.75,
        source: 'keyword',
      );
    }

    // If message looks like credit (salary/transfer) prefer income-related categories
    if (parsed.type == TransactionType.credit) {
      // Salary was handled earlier. For other credits, prefer 'transfer' or 'salary' if detected.
      if (lowerRaw.contains('transfer') ||
          lowerRaw.contains('neft') ||
          lowerRaw.contains('imps') ||
          lowerRaw.contains('rtgs')) {
        return const CategoryMatch(
          categoryId: CategoryIds.transfer,
          confidence: 0.6,
          source: 'type',
        );
      }
      // fallback to salary if no merchant info
      if ((parsed.merchantName ?? '').isEmpty) {
        return const CategoryMatch(
          categoryId: CategoryIds.salary,
          confidence: 0.5,
          source: 'type',
        );
      }
    }

    if (parsed.type == TransactionType.emi) {
      return const CategoryMatch(
        categoryId: CategoryIds.emi,
        confidence: 0.7,
        source: 'type',
      );
    }

    if (parsed.confidence < 0.35 || normalized.isEmpty) {
      return const CategoryMatch(
        categoryId: CategoryIds.uncategorized,
        confidence: 0.2,
        source: 'unknown',
      );
    }

    return const CategoryMatch(
      categoryId: CategoryIds.other,
      confidence: 0.45,
      source: 'fallback',
    );
  }
}
