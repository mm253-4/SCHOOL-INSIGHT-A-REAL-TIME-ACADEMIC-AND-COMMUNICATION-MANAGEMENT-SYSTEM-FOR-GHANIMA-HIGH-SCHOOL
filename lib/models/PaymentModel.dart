class Payment {
  final int? id;
  final String studentId;
  final String schoolId;
  final double amount;
  final String paymentMethod;
  final String? transactionId;
  final String? mpesaReceiptNumber;
  final String paymentDate;
  final String? term;
  final String status; // 'pending', 'completed', 'failed'

  Payment({
    this.id,
    required this.studentId,
    required this.schoolId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    this.mpesaReceiptNumber,
    required this.paymentDate,
    this.term,
    required this.status,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int?,
      studentId: json['studentId'] as String,
      schoolId: json['schoolId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      transactionId: json['transactionId'] as String?,
      mpesaReceiptNumber: json['mpesaReceiptNumber'] as String?,
      paymentDate: json['paymentDate'] as String,
      term: json['term'] as String?,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'schoolId': schoolId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'paymentDate': paymentDate,
      'term': term,
      'status': status,
    };
  }
}

