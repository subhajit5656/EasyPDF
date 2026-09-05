/// Simple user profile model synced to Firestore/Realtime DB.
class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;

  AppUser({required this.uid, this.name, this.email, this.photoUrl});

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String,
    name: map['name'] as String?,
    email: map['email'] as String?,
    photoUrl: map['photoUrl'] as String?,
  );
}
