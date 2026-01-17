import 'package:flutter/services.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http; // Added for network image fetching
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../services/ticket_service.dart'; // Added for getImageUrl logic

class PdfService {
  static Future<Uint8List> generateTicketPdf({
    required Ticket ticket,
    required Customer customer,
    required Machine machine,
    List<Map<String, String>>? checklistData,
    String? selectedPhotoName, // Added optional selected photo name
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // 1. Load Image Assets
    final ByteData watermarkBytes = await rootBundle.load('assets/paramLogoOnly.jpeg');
    final pw.MemoryImage watermarkImage = pw.MemoryImage(watermarkBytes.buffer.asUint8List());

    // --- NEW: Load Selected Customer Photo from PocketBase if exists ---
    pw.MemoryImage? customerPhoto;
    if (selectedPhotoName != null) {
      try {
        final String url = TicketService.getImageUrl('tickets', ticket.id, selectedPhotoName);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          customerPhoto = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // Silently fail if image can't be fetched to avoid breaking PDF 
      }
    }

    // 2. Logic to separate Work Done from the Staff Email
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
              // --- WATERMARK LAYER ---
              pw.Positioned.fill(
                child: pw.Opacity(
                  opacity: 0.05,
                  child: pw.Center(
                    child: pw.Image(watermarkImage, width: 400, fit: pw.BoxFit.contain),
                  ),
                ),
              ),
              // --- CONTENT LAYER ---
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. COMPANY HEADER WITH LOGO
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "PARAM SALES",
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text("7, Ramanand Complex, Near Janseva Bank,", style: const pw.TextStyle(fontSize: 8)),
                          pw.Text("Pune-Solapur Road, Hadapsar, Pune - 411028", style: const pw.TextStyle(fontSize: 8)),
                          pw.Text("Contact: +91 9822845121", style: const pw.TextStyle(fontSize: 8)),
                          pw.Text("Email: paramsalespune@gmail.com", style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.blueGrey50,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                            ),
                            child: pw.Text("SERVICE REPORT", 
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text("Ticket No: #${ticket.ticketUid}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text("Date: ${dateFormat.format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1, color: PdfColors.blue900),
                  pw.SizedBox(height: 15),

                  // 2. CLIENT & MACHINE DETAILS
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("CUSTOMER DETAILS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900)),
                            pw.SizedBox(height: 4),
                            pw.Text('Name: ${customer.name}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Company: ${customer.company}', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("Phone: ${customer.primaryPhone}", style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("MACHINE INFO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900)),
                            pw.SizedBox(height: 4),
                            pw.Text("Model: ${machine.name}", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("ID: ${machine.machineUid}", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("Service Opened: ${dateFormat.format(ticket.created)}", style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 25),

                  // 3. MAIN SERVICE TABLE
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                    cellHeight: 30,
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    
                    columnWidths: ticket.cost > 0 
                      ? {
                          0: const pw.FlexColumnWidth(2), 
                          1: const pw.FlexColumnWidth(3), 
                          2: const pw.FlexColumnWidth(1.2), 
                        }
                      : {
                          0: const pw.FlexColumnWidth(2), 
                          1: const pw.FlexColumnWidth(3), 
                        },

                    headers: [
                      'Issue Reported', 
                      'Work Done', 
                      if (ticket.cost > 0) 'Amount'
                    ],

                    data: [
                      [
                        ticket.problem,
                        "$workDisplay\n\nAttended by: $staffEmail",
                        if (ticket.cost > 0) "Rs. ${ticket.cost.toStringAsFixed(2)}",
                      ],
                    ],
                  ),

                  // --- UPDATED CHECKLIST TABLE SECTION ---
                  if (checklistData != null && checklistData.isNotEmpty) ...[
                    pw.SizedBox(height: 20),
                    pw.Text("SERVICE CHECKLIST / INSPECTION DETAILS:", 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900)),
                    pw.SizedBox(height: 6),
                    pw.TableHelper.fromTextArray(
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
                      cellHeight: 20,
                      cellStyle: const pw.TextStyle(fontSize: 8),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(0.8), // Check column
                        1: const pw.FlexColumnWidth(2),   // Item column
                        2: const pw.FlexColumnWidth(3),   // Remark column
                      },
                      headers: ['Done', 'Component/Task', 'Remarks / Details'],
                      data: checklistData.map((item) {
                      // Check if remark is null or just an empty string
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
                    pw.Text("Notes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    if (ticket.note.isNotEmpty) ...[
                     pw.Text(ticket.note, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    ],

                  pw.Spacer(), // Pushes signatures to the bottom

                  // 4. SIGNATURE SECTION
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end, // Align to bottom
                    children: [
                      pw.Column(
                        children: [
                          // Display selected photo above signature line
                          if (customerPhoto != null)
                            pw.Container(
                              height: 60,
                              width: 100,
                              margin: const pw.EdgeInsets.only(bottom: 5),
                              child: pw.Image(customerPhoto, fit: pw.BoxFit.contain),
                            )
                          else
                            pw.SizedBox(height: 65), // Maintain spacing
                          
                          pw.Container(width: 160, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                          pw.SizedBox(height: 5),
                          pw.Text("Customer Signature", style: const pw.TextStyle(fontSize: 9)), 
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.SizedBox(height: 65), // Align with left side
                          pw.Container(width: 160, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                          pw.SizedBox(height: 5),
                          pw.Text("Authorized Signatory", style: const pw.TextStyle(fontSize: 9)),
                          pw.Text("For PARAM SALES", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 40),

                  // 5. FOOTER
                  pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text("Thanking you & assuring you our best support & services at all times.",
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                        pw.SizedBox(height: 4),
                        pw.Text("Param Sales.",
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
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