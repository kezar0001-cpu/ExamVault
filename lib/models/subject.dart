import 'package:cloud_firestore/cloud_firestore.dart';

/// High‑level subject representing an exam category (e.g. Private Pilot, Instrument Rating).
class Subject {
  final String id;
  final String name;
  final String? description;

  const Subject({
    required this.id,
    required this.name,
    this.description,
  });

  factory Subject.fromMap(String id, Map<String, dynamic> data) {
    return Subject(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}