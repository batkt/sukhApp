import 'package:flutter/foundation.dart';

class PaymentHistory {
  final String paymentId;
  final String invoiceNo;
  final double paymentAmount;
  final String paymentStatus;
  final String paymentStatusText;
  final DateTime paymentStatusDate;
  final List<Bill> bills;

  PaymentHistory({
    required this.paymentId,
    required this.invoiceNo,
    required this.paymentAmount,
    required this.paymentStatus,
    required this.paymentStatusText,
    required this.paymentStatusDate,
    required this.bills,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      paymentId: json['paymentId'],
      invoiceNo: json['invoiceNo'],
      paymentAmount: (json['paymentAmount'] as num).toDouble(),
      paymentStatus: json['paymentStatus'],
      paymentStatusText: json['paymentStatusText'],
      paymentStatusDate: DateTime.parse(json['paymentStatusDate']),
      bills: (json['bills'] as List).map((bill) => Bill.fromJson(bill)).toList(),
    );
  }
}

class Bill {
  final String billerName;
  final String billType;
  final String billNo;
  final bool hasVat;
  final double billTotalAmount;
  final String billPeriod;

  Bill({
    required this.billerName,
    required this.billType,
    required this.billNo,
    required this.hasVat,
    required this.billTotalAmount,
    required this.billPeriod,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      billerName: json['billerName'],
      billType: json['billtype'],
      billNo: json['billNo'],
      hasVat: json['hasVat'],
      billTotalAmount: (json['billTotalAmount'] as num).toDouble(),
      billPeriod: json['billPeriod'],
    );
  }
}
