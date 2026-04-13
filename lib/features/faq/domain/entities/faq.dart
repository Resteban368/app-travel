import 'package:equatable/equatable.dart';

class Faq extends Equatable {
  final int id;
  final String question;
  final String answer;
  final bool isActive;
  final DateTime? createdAt;

  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.isActive = true,
    this.createdAt,
  });

  Faq copyWith({
    int? id,
    String? question,
    String? answer,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Faq(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, question, answer, isActive, createdAt];
}
