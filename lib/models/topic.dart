import 'package:cloud_firestore/cloud_firestore.dart';

/// Topic nested under a subject.
class Topic {
  final String id;
  final String subjectId;
  final String name;
  final String? description;

  const Topic({
    required this.id,
    required this.subjectId,
    required this.name,
    this.description,
  });

  factory Topic.fromMap(String id, Map<String, dynamic> data) {
    return Topic(
      id: id,
      subjectId: (data['subjectId'] as DocumentReference).id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': FirebaseFirestore.instance.collection('subjects').doc(subjectId),
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}