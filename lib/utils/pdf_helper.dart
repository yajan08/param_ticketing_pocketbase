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
    // Added optional list to hold the checklist items and remarks
    List<Map<String, String>>? checklistData,
    // Added optional string for the selected photo name
    String? selectedPhotoName,
  }) async {
    // 1. Generate the bytes, passing the checklistData and selectedPhotoName to the service
    final pdfBytes = await PdfService.generateTicketPdf(
      ticket: ticket,
      customer: customer,
      machine: machine,
      checklistData: checklistData,
      selectedPhotoName: selectedPhotoName, // Pass the image name here
    );

    // 2. Use printing package to share
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Ticket_${ticket.ticketUid}.pdf',
    );
  }
}

// import 'package:printing/printing.dart';
// import '../services/pdf_service.dart';
// import '../models/ticket_model.dart';
// import '../models/customer_model.dart';
// import '../models/machine_model.dart';

// class PdfHelper {
//   static Future<void> shareTicketPdf({
//     required Ticket ticket,
//     required Customer customer,
//     required Machine machine,
//     // Added optional list to hold the checklist items and remarks
//     List<Map<String, String>>? checklistData, 
//   }) async {
//     // 1. Generate the bytes, passing the new checklistData to the service
//     final pdfBytes = await PdfService.generateTicketPdf(
//       ticket: ticket,
//       customer: customer,
//       machine: machine,
//       checklistData: checklistData, 
//     );

//     // 2. Use printing package to share
//     await Printing.sharePdf(
//       bytes: pdfBytes,
//       filename: 'Ticket_${ticket.ticketUid}.pdf',
//     );
//   }
// }