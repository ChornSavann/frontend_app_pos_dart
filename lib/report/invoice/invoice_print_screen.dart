import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pos_inventory/models/reports/report_daily.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_inventory/msg/appSnackBar.dart';
import 'package:flutter/services.dart';

class InvoicePrintScreen extends StatelessWidget {
  final ReportDaily order;

  const InvoicePrintScreen({super.key, required this.order});

  Future<void> _printInvoice(BuildContext context) async {
    try {
      AppSnackBar.showSuccess(context, "🖨️ កំពុងរៀបចំទម្រង់ព្រីន...");

      final pdf = pw.Document();
      pw.Font khmerFont;
      try {
        khmerFont = await PdfGoogleFonts.kantumruyProRegular();
      } catch (e) {
        khmerFont = pw.Font.helvetica();
      }

      String formattedDate = order.createdAt;
      try {
        DateTime parsedDate = DateTime.parse(order.createdAt).toLocal();
        formattedDate =
            "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
      } catch (_) {
        formattedDate = order.createdAt.contains('T')
            ? order.createdAt.split('T').first
            : order.createdAt;
      }
      final cashierName = order.user?.name ?? 'Admin / Cashier';

      double subtotal = 0.0;
      for (var detail in order.details) {
        subtotal += detail.price * detail.quantity;
      }

      double discountAmount = order.discountAmount;
      double taxAmount = order.taxAmount;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(14),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 🌟 Store Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'KHMER STORE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          font: khmerFont,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Main Branch • Tel: 012 345 678',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                          font: khmerFont,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey900,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            font: khmerFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(color: PdfColors.grey800, thickness: 1.2),
                pw.SizedBox(height: 6),

                // 📋 Order Info Metadata
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Invoice No:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        font: khmerFont,
                      ),
                    ),
                    pw.Text(
                      order.orderNumber,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        font: khmerFont,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        font: khmerFont,
                      ),
                    ),
                    pw.Text(
                      formattedDate, // 🟢 ប្រើប្រាស់កាលបរិច្ឆេទដែលបាន Format រួច
                      style: pw.TextStyle(fontSize: 8, font: khmerFont),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Customer:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        font: khmerFont,
                      ),
                    ),
                    pw.Text(
                      order.customer?.name ?? 'Guest',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        font: khmerFont,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Cashier:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        font: khmerFont,
                      ),
                    ),
                    pw.Text(
                      cashierName,
                      style: pw.TextStyle(fontSize: 8, font: khmerFont),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Payment:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                        font: khmerFont,
                      ),
                    ),
                    pw.Text(
                      order.payment?.paymentMethod ?? 'Cash',
                      style: pw.TextStyle(fontSize: 8, font: khmerFont),
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey800, thickness: 1.2),
                pw.SizedBox(height: 6),

                // 🛒 Items Table Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 4,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Item Description',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            font: khmerFont,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            font: khmerFont,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Price',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            font: khmerFont,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            font: khmerFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // 📦 Items List Rows
                ...order.details.map((detail) {
                  final itemName = detail.product?.name ?? 'Item';
                  final itemTotal = detail.price * detail.quantity;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            itemName,
                            style: pw.TextStyle(fontSize: 8, font: khmerFont),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '${detail.quantity.toInt()}',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 8, font: khmerFont),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '\$${detail.price.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 8, font: khmerFont),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '\$${itemTotal.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              font: khmerFont,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.grey800, thickness: 1.2),
                pw.SizedBox(height: 6),

                // 📊 Financial Summary Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Subtotal:',
                      style: pw.TextStyle(fontSize: 8, font: khmerFont),
                    ),
                    pw.Text(
                      '\$${subtotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 8, font: khmerFont),
                    ),
                  ],
                ),
                if (discountAmount > 0) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Discount:',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.red700,
                          font: khmerFont,
                        ),
                      ),
                      pw.Text(
                        '-\$${discountAmount.toStringAsFixed(2)}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.red700,
                        ),
                      ),
                    ],
                  ),
                ],
                if (taxAmount > 0) ...[
                  pw.SizedBox(height: 3),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Order Tax:',
                        style: pw.TextStyle(fontSize: 8, font: khmerFont),
                      ),
                      pw.Text(
                        '\$${taxAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 8, font: khmerFont),
                      ),
                    ],
                  ),
                ],
                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.grey500, thickness: 0.8),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Grand Total:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: khmerFont,
                      ),
                    ),
                    pw.Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                        font: khmerFont,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey800, thickness: 1.2),
                pw.SizedBox(height: 12),

                // Footer Message
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'អរគុណសម្រាប់ការគាំទ្រហាងយើងខ្ញុំ!',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          font: khmerFont,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Thank you! Please come again.',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                          font: khmerFont,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint("Error printing invoice: $e");
      if (context.mounted) {
        AppSnackBar.showError(context, "❌ មានបញ្ហាក្នុងการព្រីន: $e");
      }
    }
  }

  Future<void> _shareInvoiceAsPDF(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeName = prefs.getString('store_name') ?? 'Khmer Store';
      final branchName = prefs.getString('branch_name') ?? 'Main Branch';

      final pdf = pw.Document();
      final cashierName = order.user?.name ?? 'Admin / Cashier';

      double subtotal = 0.0;
      for (var detail in order.details) {
        subtotal += detail.price * detail.quantity; // 🟢 Fixed multiplication
      }

      double discountAmount = order.discountAmount;
      double taxAmount = order.taxAmount;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Store Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          storeName,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          branchName,
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'No: ${order.orderNumber}',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'Status: ${order.status.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),

                // Customer, Cashier & Date Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO:',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey500,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          order.customer?.name ?? 'Guest Customer',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date: ${order.createdAt.contains('T') ? order.createdAt.split('T').first : order.createdAt}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          'Payment: ${order.payment?.paymentMethod ?? 'Cash'}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Cashier: $cashierName',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Items Table Header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  color: PdfColors.grey800,
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          'Item',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Rate',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Items List
                ...order.details.map((detail) {
                  final productName = detail.product?.name ?? 'Product';
                  final itemTotal = detail.price * detail.quantity;
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey200),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            productName,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            '${detail.quantity.toInt()}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '\$${detail.price.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '\$${itemTotal.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 25),

                // Total Summary with Subtotal, Discount, Tax & Grand Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.SizedBox(
                      width: 220,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Subtotal:',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.Text(
                                '\$${subtotal.toStringAsFixed(2)}',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Discount:',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.Text(
                                '-\$${discountAmount.toStringAsFixed(2)}',
                                style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.red700,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Order Tax:',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey700,
                                ),
                              ),
                              pw.Text(
                                '\$${taxAmount.toStringAsFixed(2)}',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          pw.Divider(color: PdfColors.grey300),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Grand Total:',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              pw.Text(
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                  color: PdfColors.teal800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/Invoice_${order.orderNumber}.pdf");
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📄 វិក្កយបត្រ (Invoice) លេខ #${order.orderNumber}',
        subject: 'Invoice ${order.orderNumber}',
      );
    } catch (e) {
      debugPrint("Error generating or sharing PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLower = order.status.toLowerCase();
    Color badgeBgColor;
    Color badgeTextColor;

    if (statusLower == 'completed' ||
        statusLower == 'success' ||
        statusLower == 'paid') {
      badgeBgColor = const Color(0xFF10B981).withOpacity(0.12);
      badgeTextColor = const Color(0xFF059669);
    } else if (statusLower == 'pending') {
      badgeBgColor = const Color(0xFFF59E0B).withOpacity(0.12);
      badgeTextColor = const Color(0xFFD97706);
    } else {
      badgeBgColor = const Color(0xFFEF4444).withOpacity(0.12);
      badgeTextColor = const Color(0xFFDC2626);
    }

    final formattedDate = order.createdAt.contains('T')
        ? order.createdAt.split('T').first
        : order.createdAt;

    final cashierName = order.user?.name ?? 'Admin / Cashier';

    double subtotal = 0.0;
    for (var detail in order.details) {
      subtotal += detail.price * detail.quantity; // 🟢 Fixed multiplication
    }

    double discountAmount = order.discountAmount;
    double taxAmount = order.taxAmount;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.12)),
        ),
        middle: const Text(
          'Invoice Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Color(0xFF0F172A),
            decoration: TextDecoration.none,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Color(0xFF0F172A)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🖨️ Print Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _printInvoice(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.printer_fill,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 🔗 Share PDF Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _shareInvoiceAsPDF(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.share,
                  color: Color(0xFF0F766E),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ Top Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            CupertinoIcons.cube_box_fill,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khmer Store',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                decoration: TextDecoration.none,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Main Branch',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'INVOICE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badgeTextColor,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 16),

                // Bill To, Cashier & Date Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BILL TO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.8,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.customer?.name ?? 'Guest Customer',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildDetailRow('Date:', formattedDate),
                            const SizedBox(height: 4),
                            _buildDetailRow(
                              'Pay:',
                              order.payment?.paymentMethod ?? 'Cash',
                            ),
                            const SizedBox(height: 4),
                            _buildDetailRow('Cashier:', cashierName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 25,
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Item & Description',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rate',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Amount',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Body
                order.details.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.details.length,
                        itemBuilder: (context, index) {
                          final detail = order.details[index];
                          final productName =
                              detail.product?.name ?? 'Product #${index + 1}';
                          final itemTotal = detail.price * detail.quantity;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 25,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    productName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F172A),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${detail.quantity.toInt()}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${detail.price.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '\$${itemTotal.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 20),

                // Summary Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 230,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                '\$${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Discount',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                '-\$${discountAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order Tax',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                '\$${taxAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Divider(height: 1, thickness: 0.8),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF059669),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}
