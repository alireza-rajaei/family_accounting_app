import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

bool isLoanPrincipalType(String type) =>
    type == 'پرداخت وام به کاربر' || type == tr('transactions.loan_principal');

bool isLoanInstallmentType(String type) =>
    type == 'پرداخت قسط وام' || type == tr('transactions.loan_installment');

bool isLoanRelatedType(String type) =>
    isLoanPrincipalType(type) || isLoanInstallmentType(type);

bool isDepositType(String type) =>
    type == 'واریز' || type == tr('transactions.deposit');

bool isWithdrawType(String type) =>
    type == 'برداشت' || type == tr('transactions.withdraw');

bool isWalletType(String type) => isDepositType(type) || isWithdrawType(type);

/// Green for money-in (deposit / installment), red for money-out (withdraw / loan).
PdfColor? pdfAmountColor(String type) {
  if (isDepositType(type) || isLoanInstallmentType(type)) {
    return PdfColors.green700;
  }
  if (isWithdrawType(type) || isLoanPrincipalType(type)) {
    return PdfColors.red700;
  }
  return null;
}

pw.Widget pdfCellText(
  String text, {
  PdfColor? color,
  bool underline = false,
  bool bold = false,
}) {
  final label = pw.Text(
    text,
    textAlign: pw.TextAlign.right,
    style: pw.TextStyle(
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    ),
  );

  // Draw a line under the value (not the cell grid). pdf has no IntrinsicWidth,
  // so approximate line width from character count.
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    child: pw.Align(
      alignment: pw.Alignment.centerRight,
      child: underline
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                label,
                pw.SizedBox(height: 1.5),
                pw.Container(
                  height: 1.2,
                  width: (text.length * 5.5).clamp(24.0, 120.0),
                  color: PdfColors.black,
                ),
              ],
            )
          : label,
    ),
  );
}
