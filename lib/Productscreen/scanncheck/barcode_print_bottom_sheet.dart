import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pos_inventory/models/Product.dart';

class BarcodePrintHelper {
  static void show(BuildContext context, Product product) {
    String selectedPaperType = 'ROLL';
    String selectedStickerSize = '40x25';
    int numberOfLabels = 1;
    int crossAxisCount = 3;

    bool showProductName = true;
    bool showPrice = true;
    bool showBarcodeText = true;
    bool showSku = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> generateAndPrintPdf() async {
              final pdf = pw.Document();
              final standardFont = pw.Font.helvetica();
              final standardBoldFont = pw.Font.helveticaBold();

              // 🌟 1. កំណត់ទទឹង និងកម្ពស់ Sticker ជា Point (1 mm ≈ 2.83465 points)
              double stickerWidth = 40 * 2.83465;
              double stickerHeight = 25 * 2.83465;

              if (selectedStickerSize == '40x25') {
                stickerWidth = 40 * 2.83465;
                stickerHeight = 25 * 2.83465;
              } else if (selectedStickerSize == '50x30') {
                stickerWidth = 50 * 2.83465;
                stickerHeight = 30 * 2.83465;
              } else if (selectedStickerSize == '80x100') {
                stickerWidth = 80 * 2.83465;
                stickerHeight = 100 * 2.83465;
              }

              // 🌟 2. កំណត់ PageFormat ឱ្យត្រូវទៅនឹងក្រដាស ROLL ឬ A4/A5
              PdfPageFormat pageFormat;
              if (selectedPaperType == 'ROLL') {
                // ក្រដាសມូរ (Roll) គណនាកម្ពស់តាមចំនួន Sticker និង Columns
                int rows = (numberOfLabels / crossAxisCount).ceil();
                double totalHeight = (rows * stickerHeight) + (rows * 10) + 40;
                double totalWidth = (crossAxisCount * stickerWidth) + (crossAxisCount * 10) + 30;
                pageFormat = PdfPageFormat(totalWidth, totalHeight);
              } else if (selectedPaperType == 'A5') {
                pageFormat = PdfPageFormat.a5;
              } else {
                pageFormat = PdfPageFormat.a4;
              }

              pdf.addPage(
                pw.Page(
                  pageFormat: pageFormat,
                  margin: const pw.EdgeInsets.all(12),
                  build: (pw.Context context) {
                    return pw.Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(numberOfLabels, (index) {
                        return pw.Container(
                          width: stickerWidth,
                          height: stickerHeight,
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey400,
                              width: 0.5,
                            ),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            mainAxisSize: pw.MainAxisSize.min,
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (showProductName) ...[
                                pw.Text(
                                  product.name,
                                  style: pw.TextStyle(
                                    font: standardBoldFont,
                                    fontSize: selectedStickerSize == '40x25' ? 7 : 9,
                                  ),
                                  maxLines: 1,
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 1),
                              ],
                              if (showSku) ...[
                                pw.Text(
                                  "SKU: ${product.sku}",
                                  style: pw.TextStyle(
                                    font: standardFont,
                                    fontSize: 6,
                                    color: PdfColors.grey700,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                                pw.SizedBox(height: 2),
                              ],
                              pw.Center(
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.code128(),
                                  data: product.barcode ?? product.sku,
                                  width: stickerWidth - 16,
                                  height: stickerHeight * 0.35,
                                  drawText: showBarcodeText,
                                ),
                              ),
                              if (showPrice) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  "\$${product.sellingPrice.toStringAsFixed(2)}",
                                  style: pw.TextStyle(
                                    font: standardBoldFont,
                                    fontSize: selectedStickerSize == '40x25' ? 8 : 10,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              );

              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdf.save(),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🏷️ Header Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4F46E5,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_rounded,
                                    color: Color(0xFF4F46E5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Print Barcode",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                      ],
                    ),
                  ),

                  // 📜 Scrollable Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📄 Paper Type Section
                          const Text(
                            "Paper Type",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildSelectionCard(
                                title: "ROLL",
                                icon: Icons.receipt_long_rounded,
                                isSelected: selectedPaperType == 'ROLL',
                                onTap: () => setStateModal(
                                      () => selectedPaperType = 'ROLL',
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSelectionCard(
                                title: "A4",
                                icon: Icons.description_rounded,
                                isSelected: selectedPaperType == 'A4',
                                onTap: () => setStateModal(
                                      () => selectedPaperType = 'A4',
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSelectionCard(
                                title: "A5",
                                icon: Icons.article_outlined,
                                isSelected: selectedPaperType == 'A5',
                                onTap: () => setStateModal(
                                      () => selectedPaperType = 'A5',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 📏 Sticker Size Section
                          const Text(
                            "Sticker Size",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildSizeCard(
                                size: "40×25",
                                label: "Small",
                                isSelected: selectedStickerSize == '40x25',
                                onTap: () => setStateModal(
                                      () => selectedStickerSize = '40x25',
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSizeCard(
                                size: "50×30",
                                label: "Medium",
                                isSelected: selectedStickerSize == '50x30',
                                onTap: () => setStateModal(
                                      () => selectedStickerSize = '50x30',
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildSizeCard(
                                size: "80×100",
                                label: "Large",
                                isSelected: selectedStickerSize == '80x100',
                                onTap: () => setStateModal(
                                      () => selectedStickerSize = '80x100',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 📐 Layout Columns
                          const Text(
                            "Layout Columns",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildColumnChoiceCard(
                                columns: 2,
                                isSelected: crossAxisCount == 2,
                                onTap: () =>
                                    setStateModal(() => crossAxisCount = 2),
                              ),
                              const SizedBox(width: 8),
                              _buildColumnChoiceCard(
                                columns: 3,
                                isSelected: crossAxisCount == 3,
                                onTap: () =>
                                    setStateModal(() => crossAxisCount = 3),
                              ),
                              const SizedBox(width: 8),
                              _buildColumnChoiceCard(
                                columns: 4,
                                isSelected: crossAxisCount == 4,
                                onTap: () =>
                                    setStateModal(() => crossAxisCount = 4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 🔢 Number Of Labels Input
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Number Of Labels",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                Container(
                                  width: 80,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: TextFormField(
                                      initialValue: numberOfLabels.toString(),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onChanged: (val) {
                                        setStateModal(() {
                                          numberOfLabels =
                                              int.tryParse(val) ?? 1;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            "Show / Hide Elements",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                _buildSwitchRow(
                                  "Product Name",
                                  showProductName,
                                      (val) => setStateModal(
                                        () => showProductName = val,
                                  ),
                                ),
                                const Divider(height: 1, thickness: 0.5),
                                _buildSwitchRow(
                                  "Price",
                                  showPrice,
                                      (val) => setStateModal(() => showPrice = val),
                                ),
                                const Divider(height: 1, thickness: 0.5),
                                _buildSwitchRow(
                                  "Barcode Text",
                                  showBarcodeText,
                                      (val) => setStateModal(
                                        () => showBarcodeText = val,
                                  ),
                                ),
                                const Divider(height: 1, thickness: 0.5),
                                _buildSwitchRow(
                                  "SKU",
                                  showSku,
                                      (val) => setStateModal(() => showSku = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Color(0xFF4F46E5),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFF4F46E5),
                              size: 18,
                            ),
                            label: const Text(
                              "Export PDF",
                              style: TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              generateAndPrintPdf();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.print_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "Print",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              generateAndPrintPdf();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildColumnChoiceCard({
    required int columns,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                : Colors.grey.shade50,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : Colors.grey.shade200,
              width: isSelected ? 1.8 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                "$columns",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Columns",
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // កូដសន្លឹកបៀប Card ជ្រើសរើស Paper Type
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                : Colors.grey.shade50,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : Colors.grey.shade200,
              width: isSelected ? 1.8 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSizeCard({
    required String size,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                : Colors.grey.shade50,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : Colors.grey.shade200,
              width: isSelected ? 1.8 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(
                size,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSwitchRow(
      String title,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF4F46E5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}