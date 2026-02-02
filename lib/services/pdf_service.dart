import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../services/ticket_service.dart';

class PdfService {
  static Future<Uint8List> generateTicketPdf({
    required Ticket ticket,
    required Customer customer,
    required Machine machine,
    List<Map<String, String>>? checklistData,
    String? selectedPhotoName,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Define custom theme color (#393186)
    final customColor = PdfColor.fromInt(0xFF393186);
    // Light custom color for the checklist header
    final lightCustomColor = PdfColor.fromInt(0xFFF1F0F7);

    // 1. Load Image Assets
    final ByteData watermarkBytes = await rootBundle.load('assets/paramLogoOnly.jpeg');
    final pw.MemoryImage watermarkImage = pw.MemoryImage(watermarkBytes.buffer.asUint8List());

    final ByteData headerBytes = await rootBundle.load('assets/paramRoost.jpg');
    final pw.MemoryImage headerImage = pw.MemoryImage(headerBytes.buffer.asUint8List());

    pw.MemoryImage? customerPhoto;
    if (selectedPhotoName != null) {
      try {
        final String url = TicketService.getImageUrl('tickets', ticket.id, selectedPhotoName);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          customerPhoto = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // Silently fail
      }
    }

    String workDisplay = ticket.workDone;
    String staffEmail = "N/A";
    if (ticket.workDone.contains("@@@")) {
      List<String> parts = ticket.workDone.split("@@@");
      workDisplay = parts[0].trim();
      staffEmail = parts[1].trim();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(35),
        build: (pw.Context context) {
          return pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Positioned.fill(
                child: pw.Opacity(
                  opacity: 0.04,
                  child: pw.Center(
                    child: pw.Image(watermarkImage, width: 450, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. HEADER
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Image(headerImage, width: 140, height: 50, fit: pw.BoxFit.contain),
                          pw.SizedBox(height: 8),
                          pw.Text("7, Ramanand Complex, Near Janseva Bank,",
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          pw.Text("Pune-Solapur Road, Hadapsar, Pune - 411028",
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          pw.Text("Contact: +91 9822845121",
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          pw.Text("Email: paramsalespune@gmail.com",
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: customColor,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                            ),
                            child: pw.Text("SERVICE REPORT",
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white)),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text("Ticket No: #${ticket.ticketUid}",
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text("Date: ${dateFormat.format(DateTime.now())}",
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 15),
                  pw.Divider(thickness: 1.5, color: customColor),
                  pw.SizedBox(height: 15),

                  // 2. CLIENT INFO BOX
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: lightCustomColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: customColor, width: 0.2),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("CUSTOMER DETAILS",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold, fontSize: 8, color: customColor)),
                              pw.SizedBox(height: 4),
                              pw.Text(customer.name,
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Company: ${customer.company}',
                                  style: const pw.TextStyle(fontSize: 9)),
                              pw.Text("Phone: ${customer.primaryPhone}",
                                  style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("MACHINE INFO",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold, fontSize: 8, color: customColor)),
                              pw.SizedBox(height: 4),
                              pw.Text("Model: ${machine.name}",
                                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                              pw.Text("ID: ${machine.machineUid}",
                                  style: const pw.TextStyle(fontSize: 9)),
                              pw.Text("Service Opened: ${dateFormat.format(ticket.created)}",
                                  style: const pw.TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 20),

                  // 3. SERVICE TABLE
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: customColor, fontSize: 10),
                    headerDecoration: pw.BoxDecoration(color: lightCustomColor),
                    cellHeight: 35,
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    columnWidths: ticket.cost > 0
                        ? {
                            0: const pw.FlexColumnWidth(2),
                            1: const pw.FlexColumnWidth(3),
                            2: const pw.FlexColumnWidth(1.2)
                          }
                        : {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(3)},
                    headers: ['Issue Reported', 'Work Done', if (ticket.cost > 0) 'Amount'],
                    data: [
                      [
                        ticket.problem,
                        "$workDisplay\n\nAttended by: $staffEmail",
                        if (ticket.cost > 0) "Rs. ${ticket.cost.toStringAsFixed(2)}",
                      ]
                    ],
                  ),

                  // 4. CHECKLIST TABLE
                  if (checklistData != null && checklistData.isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    pw.Text("SERVICE CHECKLIST / INSPECTION DETAILS",
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 9, color: customColor)),
                    pw.SizedBox(height: 6),
                    pw.TableHelper.fromTextArray(
                      headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, color: customColor, fontSize: 9),
                      headerDecoration: pw.BoxDecoration(color: lightCustomColor),
                      cellHeight: 22,
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(0.8),
                        1: const pw.FlexColumnWidth(2),
                        2: const pw.FlexColumnWidth(3),
                      },
                      headers: ['Done', 'Component/Task', 'Remarks / Details'],
                      data: checklistData.map((item) {
                        String remark = item['remark'] ?? '';
                        if (remark.trim().isEmpty) remark = "N/A";
                        return [
                          item['status'] == "YES" ? "[ Checked ]" : "[ X ]",
                          item['item'] ?? '',
                          remark,
                        ];
                      }).toList(),
                    ),
                  ],

                  pw.SizedBox(height: 15),
                  pw.Text("Notes:",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 9, color: customColor)),
                  if (ticket.note.isNotEmpty)
                    pw.Text(ticket.note,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),

                  pw.Spacer(),

                  // 5. SIGNATURE SECTION
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Customer Side
                      pw.SizedBox(
                        width: 160,
                        child: pw.Column(
                          children: [
                            if (customerPhoto != null)
                              pw.Container(
                                height: 80,
                                width: 110,
                                margin: const pw.EdgeInsets.only(bottom: 5),
                                child: pw.Image(customerPhoto, fit: pw.BoxFit.contain),
                              )
                            else
                              pw.SizedBox(height: 85),
                            pw.Container(
                                decoration: const pw.BoxDecoration(
                                    border: pw.Border(
                                        top: pw.BorderSide(width: 0.8, color: PdfColors.grey600)))),
                            pw.SizedBox(height: 5),
                            pw.Text("Customer Signature",
                                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      // Authorized Side
                      pw.SizedBox(
                        width: 160,
                        child: pw.Column(
                          children: [
                            pw.SizedBox(height: 85),
                            pw.Container(
                                decoration: const pw.BoxDecoration(
                                    border: pw.Border(
                                        top: pw.BorderSide(width: 0.8, color: PdfColors.grey600)))),
                            pw.SizedBox(height: 5),
                            pw.Text("Authorized Signatory",
                                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                            pw.Text("For PARAM SALES",
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: customColor)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 30),

                  // 6. FOOTER
                  pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text("Thanking you & assuring you our best support & services at all times.",
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text("Param Sales.",
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold, color: customColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}