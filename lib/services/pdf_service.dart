import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart'; 
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';

class PdfService {
  static Future<Uint8List> generateTicketPdf({
    required Ticket ticket,
    required Customer customer,
    required Machine machine,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Logic to separate Work Done from the Staff Email
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
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. COMPANY LETTERHEAD
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("PARAM SALES",
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900)),
                      pw.SizedBox(height: 5),
                      pw.Text("7, Ramanand Complex, Near Janseva Bank,"),
                      pw.Text("Pune-Solapur Road, Hadapsar, Pune - 411028"),
                      pw.Text("Contact: +91 9689997979"),
                      pw.Text("Email: paramsalespune@gmail.com"),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                        ),
                        child: pw.Text("SERVICE INVOICE",
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text("Ticket No: #${ticket.ticketUid}",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Status: ${ticket.status.toUpperCase()}"),
                      // This shows the actual date the PDF was created
                      pw.Text("Bill Date: ${dateFormat.format(DateTime.now())}"),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 25),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 20),

              // 2. CLIENT & MACHINE DETAILS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("BILL TO / CUSTOMER:",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 5),
                        // Explicitly added Name: and Company: labels
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: "Name: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.TextSpan(text: customer.name),
                            ],
                          ),
                        ),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: "Company: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.TextSpan(text: customer.company),
                            ],
                          ),
                        ),
                        pw.Text("Phone: ${customer.primaryPhone}"),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("MACHINE & SERVICE INFO:",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 5),
                        pw.Text("Model: ${machine.name}"),
                        pw.Text("Machine ID: ${machine.machineUid}"),
                        pw.Text("Type: ${machine.type}"),
                        pw.Text("Service Opened: ${dateFormat.format(ticket.created)}"),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // 3. MAIN SERVICE TABLE
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellHeight: 35,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), 
                  1: const pw.FlexColumnWidth(3), 
                  2: const pw.FlexColumnWidth(1.2), 
                },
                headers: ['Issue Reported', 'Service Action / Work Done', 'Amount'],
                data: [
                  [
                    ticket.problem,
                    "$workDisplay\n\nAttended by: $staffEmail",
                    "Rs. ${ticket.cost.toStringAsFixed(2)}"
                  ],
                ],
              ),

              // 4. SUMMARY SECTION
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Notes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Text(ticket.note.isEmpty ? "No additional notes." : ticket.note,
                            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Subtotal:"),
                              pw.Text("Rs. ${ticket.cost.toStringAsFixed(2)}"),
                            ],
                          ),
                          pw.Divider(),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Total:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text("Rs. ${ticket.cost.toStringAsFixed(2)}",
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 60),

              // 5. SIGNATURE SECTION
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1))),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text("Customer Signature & Stamp", style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1))),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text("Authorized Signatory", style: const pw.TextStyle(fontSize: 9)),
                      pw.Text("For PARAM SALES", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // 6. FOOTER
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("This is a computer-generated service record. Valid without physical signature.",
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.SizedBox(height: 5),
                    pw.Text("Param Sales - Quality Service, Trusted Support",
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.blue900)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}
