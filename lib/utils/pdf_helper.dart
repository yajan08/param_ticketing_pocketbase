import 'package:printing/printing.dart';
import '../services/pdf_service.dart';
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';

class PdfHelper {
  static Future<void> shareTicketPdf({
    required Ticket ticket,
    required Customer customer,
    required Machine machine,
  }) async {
    // Generate the bytes
    final pdfBytes = await PdfService.generateTicketPdf(
      ticket: ticket,
      customer: customer,
      machine: machine,
    );

    // Use printing package to share
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Ticket_${ticket.ticketUid}.pdf',
    );
  }
}