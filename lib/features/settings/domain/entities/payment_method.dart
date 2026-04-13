import 'package:equatable/equatable.dart';

/// Represents a payment method for the agency.
class PaymentMethod extends Equatable {
  final int id;
  final String name;
  final String paymentType; // e.g., 'Transferencia'
  final String accountType; // e.g., 'Ahorros'
  final String accountNumber;
  final String accountHolder; // A nombre de quien está la cuenta
  final bool isActive;
  final DateTime? createdAt;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.paymentType,
    required this.accountType,
    required this.accountNumber,
    this.accountHolder = '',
    this.isActive = true,
    this.createdAt,
  });

  PaymentMethod copyWith({
    int? id,
    String? name,
    String? paymentType,
    String? accountType,
    String? accountNumber,
    String? accountHolder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      paymentType: paymentType ?? this.paymentType,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    paymentType,
    accountType,
    accountNumber,
    accountHolder,
    isActive,
    createdAt,
  ];
}
