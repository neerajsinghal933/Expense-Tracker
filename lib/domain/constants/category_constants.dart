class CategoryIds {
  static const uncategorized = 'cat_uncategorized';
  static const other = 'cat_other';
  static const food = 'cat_food';
  static const shopping = 'cat_shopping';
  static const transport = 'cat_transport';
  static const bills = 'cat_bills';
  static const entertainment = 'cat_entertainment';
  static const health = 'cat_health';
  static const investment = 'cat_investment';
  static const home = 'cat_home';
  static const education = 'cat_education';
  static const travel = 'cat_travel';
  static const insurance = 'cat_insurance';
  static const subscriptions = 'cat_subscriptions';
  static const salary = 'cat_salary';
  static const transfer = 'cat_transfer';
  static const emi = 'cat_emi';
}

class DefaultCategories {
  static const entries = [
    (CategoryIds.food, 'Food & Dining', 'FF6B6B'),
    (CategoryIds.shopping, 'Shopping', '4ECDC4'),
    (CategoryIds.transport, 'Transport', '45B7D1'),
    (CategoryIds.bills, 'Bills & Utilities', '96CEB4'),
    (CategoryIds.entertainment, 'Entertainment', 'FFEAA7'),
    (CategoryIds.health, 'Health', 'DDA0DD'),
    (CategoryIds.investment, 'Investment', '34D399'),
    (CategoryIds.home, 'Home', 'FBBF24'),
    (CategoryIds.education, 'Education', 'A78BFA'),
    (CategoryIds.travel, 'Travel', '38BDF8'),
    (CategoryIds.insurance, 'Insurance', 'FB7185'),
    (CategoryIds.subscriptions, 'Subscriptions', '818CF8'),
    (CategoryIds.salary, 'Salary & Income', '98D8C8'),
    (CategoryIds.transfer, 'Transfers', 'A8DADC'),
    (CategoryIds.emi, 'EMI & Loans', 'F4A261'),
    (CategoryIds.other, 'Other', 'AAB3C0'),
    (CategoryIds.uncategorized, 'Needs category', 'E63946'),
  ];
}
