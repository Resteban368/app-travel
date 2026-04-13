import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final int id;
  final String name;
  final double? cost;
  final String description;
  final int idSede;
  final bool isActive;
  final DateTime? createdAt;

  const Service({
    required this.id,
    required this.name,
    this.cost,
    required this.description,
    required this.idSede,
    this.isActive = true,
    this.createdAt,
  });

  Service copyWith({
    int? id,
    String? name,
    double? cost,
    String? description,
    int? idSede,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      description: description ?? this.description,
      idSede: idSede ?? this.idSede,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    cost,
    description,
    idSede,
    isActive,
    createdAt,
  ];
}
