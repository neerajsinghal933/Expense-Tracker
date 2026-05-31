import '../db/app_database.dart';

class ProfileRepository {
  final AppDatabase db;
  ProfileRepository(this.db);

  Future<void> saveProfile(ProfilesCompanion companion) async {
    await db.into(db.profiles).insertOnConflictUpdate(companion);
  }

  Future<UserProfile?> loadProfile() async {
    final row = await (db.select(db.profiles)).getSingleOrNull();
    if (row == null) return null;
    return UserProfile(
      id: row.id,
      fullName: row.fullName,
      username: row.username,
      preferredCurrency: row.preferredCurrency,
      monthlyIncome: row.monthlyIncome,
      avatarPath: row.avatarPath,
    );
  }
}

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String preferredCurrency;
  final double? monthlyIncome;
  final String? avatarPath;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.preferredCurrency,
    this.monthlyIncome,
    this.avatarPath,
  });
}
