class ProfileModel {
  final String id;
  final String fullName;
  final String username;
  final String preferredCurrency;
  final double? monthlyIncome;
  final String? avatarPath;

  ProfileModel(
      {required this.id,
      required this.fullName,
      required this.username,
      required this.preferredCurrency,
      this.monthlyIncome,
      this.avatarPath});
}
