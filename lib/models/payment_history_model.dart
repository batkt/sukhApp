import 'package:flutter/foundation.dart';

class PaymentHistory {
  final String paymentId;
  final String invoiceNo;
  final double paymentAmount;
  final String paymentStatus;
  final String paymentStatusText;
  final DateTime paymentStatusDate;
  final List<Bill> bills;

  final String? qpayPaymentId;
  final bool? isPaid;
  final String? trxNo;
  final bool isStuck;
  final String? walletStatus;

  PaymentHistory({
    required this.paymentId,
    required this.invoiceNo,
    required this.paymentAmount,
    required this.paymentStatus,
    required this.paymentStatusText,
    required this.paymentStatusDate,
    required this.bills,
    this.qpayPaymentId,
    this.isPaid,
    this.trxNo,
    this.isStuck = false,
    this.walletStatus,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    // API uses 'amount' OR 'paymentAmount' OR 'totalAmount'
    final rawAmount =
        json['paymentAmount'] ??
        json['amount'] ??
        json['totalAmount'] ??
        json['trxAmount'] ??
        json['paidAmount'] ??
        json['dun'] ??
        0;
    // API uses 'paymentStatusDate' OR 'trxDate' OR 'createdAt'
    final rawDate =
        json['paymentStatusDate'] ??
        json['trxDate'] ??
        json['createdAt'] ??
        json['updatedAt'] ??
        DateTime.now().toIso8601String();
    // Build bills from 'bills' or 'lines'
    final rawBills = (json['bills'] as List?) ?? (json['lines'] as List?) ?? [];
    final rawStatus =
        json['paymentStatus']?.toString() ??
        json['walletStatus']?.toString() ??
        json['status']?.toString() ??
        'UNKNOWN';

    return PaymentHistory(
      paymentId:
          json['paymentId']?.toString() ??
          json['walletPaymentId']?.toString() ??
          json['qpayPaymentId']?.toString() ??
          json['id']?.toString() ??
          '',
      invoiceNo: json['invoiceNo']?.toString() ?? json['invoiceNo']?.toString() ?? '',
      paymentAmount: (rawAmount as num).toDouble(),
      paymentStatus: rawStatus.toUpperCase(),
      paymentStatusText:
          json['paymentStatusText']?.toString() ??
          json['walletStatusText']?.toString() ??
          rawStatus,
      paymentStatusDate: DateTime.tryParse(rawDate.toString()) ?? DateTime.now(),
      bills: rawBills.map((bill) => Bill.fromJson(Map<String, dynamic>.from(bill))).toList(),
      qpayPaymentId: json['qpayPaymentId']?.toString(),
      isPaid: json['isPaid'],
      trxNo: json['trxNo']?.toString(),
      isStuck: json['isStuck'] ?? false,
      walletStatus: json['walletStatus']?.toString(),
    );
  }

  PaymentHistory copyWith({
    String? paymentId,
    String? invoiceNo,
    double? paymentAmount,
    String? paymentStatus,
    String? paymentStatusText,
    DateTime? paymentStatusDate,
    List<Bill>? bills,
  }) {
    return PaymentHistory(
      paymentId: paymentId ?? this.paymentId,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentStatusText: paymentStatusText ?? this.paymentStatusText,
      paymentStatusDate: paymentStatusDate ?? this.paymentStatusDate,
      bills: bills ?? this.bills,
      isStuck: this.isStuck,
      walletStatus: this.walletStatus,
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
  final double billLateFee;

  Bill({
    required this.billerName,
    required this.billType,
    required this.billNo,
    required this.hasVat,
    required this.billTotalAmount,
    required this.billPeriod,
    required this.billLateFee,
  });

  Bill copyWith({
    String? billerName,
    String? billType,
    String? billNo,
    bool? hasVat,
    double? billTotalAmount,
    String? billPeriod,
    double? billLateFee,
  }) {
    return Bill(
      billerName: billerName ?? this.billerName,
      billType: billType ?? this.billType,
      billNo: billNo ?? this.billNo,
      hasVat: hasVat ?? this.hasVat,
      billTotalAmount: billTotalAmount ?? this.billTotalAmount,
      billPeriod: billPeriod ?? this.billPeriod,
      billLateFee: billLateFee ?? this.billLateFee,
    );
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    final bName = json['billerName']?.toString() ?? 'Биллер';
    
    // Try to translate billtypeGeneral if present
    String? generalType;
    if (json['billtypeGeneral'] != null) {
      final gen = json['billtypeGeneral'].toString().toUpperCase();
      if (gen == 'HEATING') generalType = 'Дулааны төлбөр';
      else if (gen == 'ELECTRICITY') generalType = 'Цахилгааны төлбөр';
      else if (gen == 'WATER') generalType = 'Усны төлбөр';
      else if (gen == 'TRASH') generalType = 'Хогны төлбөр';
      else if (gen == 'PROPERTY') generalType = 'СӨХ-ийн төлбөр';
    }

    String? bType = json['billType']?.toString() ?? 
                  json['billtype']?.toString() ?? 
                  generalType ??
                  json['billName']?.toString() ?? 
                  json['type']?.toString() ??
                  json['description']?.toString() ??
                  json['tailbar']?.toString() ??
                  json['name']?.toString();
                  
    return Bill(
      billerName: bName,
      billType: (bType != null && bType.isNotEmpty && bType != 'Төлбөр') ? bType : bName,
      billNo: json['billNo']?.toString() ?? '',
      hasVat: json['hasVat'] == true,
      billTotalAmount: ((json['billTotalAmount'] ?? json['billAmount'] ?? 0) as num).toDouble(),
      billPeriod: json['billPeriod']?.toString() ?? '',
      billLateFee: ((json['billLateFee'] ?? 0) as num).toDouble(),
    );
  }
}
