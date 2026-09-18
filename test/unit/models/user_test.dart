import 'package:flutter_test/flutter_test.dart';
import 'package:cine_track/models/user.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': 30001,
        'name': 'rhey',
        'username': '',
        'email': 'realyncipriano.030@gmail.com',
        'phone': null,
        'date_of_birth': '1997-04-30',
        'country': 'Philippines',
        'marketing_opt_in': false,
        'role': 'admin',
        'email_verified': true,
        'avatar_url': null,
      };

  test('User.fromJson parses bio when present', () {
    final user = User.fromJson({...baseJson(), 'bio': 'Hello world'});
    expect(user.bio, 'Hello world');
  });

  test('User.fromJson leaves bio null when absent', () {
    final user = User.fromJson(baseJson());
    expect(user.bio, isNull);
  });

  test('User.copyWith updates bio and preserves other fields', () {
    final user = User.fromJson(baseJson());
    final updated = user.copyWith(bio: 'New bio');
    expect(updated.bio, 'New bio');
    expect(updated.name, user.name);
    expect(updated.email, user.email);
    expect(updated.country, user.country);
  });

  test('User.copyWith without bio keeps existing bio', () {
    final user = User.fromJson({...baseJson(), 'bio': 'Keep me'});
    final updated = user.copyWith(name: 'rhey2');
    expect(updated.bio, 'Keep me');
    expect(updated.name, 'rhey2');
  });

  test('bio round-trip: fromJson -> copyWith -> fromJson shape', () {
    final user = User.fromJson({...baseJson(), 'bio': 'Round trip'});
    final updated = user.copyWith(bio: '${user.bio}!');
    expect(updated.bio, 'Round trip!');
  });
}
