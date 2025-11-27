import 'dart:io';

abstract class ReceiptState {}

class ReceiptInitial extends ReceiptState {}

class ReceiptGenerating extends ReceiptState {}

class ReceiptGenerated extends ReceiptState {
  final File pdfFile;
  final String filePath;

  ReceiptGenerated({required this.pdfFile, required this.filePath});
}

class ReceiptPrinting extends ReceiptState {}

class ReceiptPrinted extends ReceiptState {
  final String message;

  ReceiptPrinted({required this.message});
}

class ReceiptSharing extends ReceiptState {}

class ReceiptShared extends ReceiptState {
  final String message;

  ReceiptShared({required this.message});
}

class ReceiptError extends ReceiptState {
  final String message;

  ReceiptError({required this.message});
}
