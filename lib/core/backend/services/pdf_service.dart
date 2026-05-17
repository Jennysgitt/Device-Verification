import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateSecurityReport({
    required List<Map<String, dynamic>> logs,
    required String adminName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy HH:mm').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('Security Incident report', dateStr, adminName),
          pw.SizedBox(height: 20),
          _buildSummaryTable(logs),
          pw.SizedBox(height: 20),
          _buildLogsTable(logs),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Security_Report_${now.millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader(String title, String date, String admin) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated: $date'),
            pw.Text('Operator: $admin'),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildSummaryTable(List<Map<String, dynamic>> logs) {
    final total = logs.length;
    final verified = logs.where((l) => l['status'] == 'verified').length;
    final suspicious = logs.where((l) => l['status'] == 'suspicious').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Scans', total.toString()),
          _buildStatItem('Verified', verified.toString()),
          _buildStatItem('Suspicious', suspicious.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildLogsTable(List<Map<String, dynamic>> logs) {
    return pw.TableHelper.fromTextArray(
      headers: ['Timestamp', 'Owner', 'Device', 'Type', 'Status'],
      data: logs.map((log) {
        final device = log['devices'] as Map?;
        final user = device?['users'] as Map?;
        final time = DateFormat('HH:mm:ss').format(DateTime.parse(log['created_at']));
        return [
          time,
          user?['full_name'] ?? 'System',
          '${device?['brand'] ?? ''} ${device?['model'] ?? ''}',
          log['entry_type']?.toString().toUpperCase() ?? 'SCAN',
          log['status']?.toString().toUpperCase() ?? 'INFO',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
    );
  }
}
