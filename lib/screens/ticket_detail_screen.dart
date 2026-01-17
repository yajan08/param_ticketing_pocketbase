import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:param_ticketing/screens/checklist_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../services/ticket_service.dart';
import '../services/customer_service.dart';
import '../services/machine_service.dart';
import '../utils/my_textfield.dart';
import '../pb.dart';
import '../utils/pdf_helper.dart'; // Import the helper

class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _costController = TextEditingController();
  final _workDoneController = TextEditingController();
  final _problemController = TextEditingController();
  final _noteController = TextEditingController(); // Added

  late String _currentStatus;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;

  void _handlePdfShare() async {
  // 2. Existing Validation Logic (Updated to use widget.ticket data from PocketBase)
  if (widget.ticket.status != 'closed') { // Check PB status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF can only be generated for CLOSED tickets.")),
    );
    return;
  }

  // Check PB fields instead of controllers to ensure data is saved on server first
  if (widget.ticket.workDone.trim().isEmpty || widget.ticket.problem.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please SAVE the ticket before generating PDF.")),
    );
    return;
  }
 
  // 1. Check if we should go to Checklist (for OUT tickets)
  if (widget.ticket.isOut) {
    final customer = await _customerFuture;
    final machine = await _machineFuture;

    if (!mounted) return;
    
    // Navigate to Checklist and pass required data
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChecklistScreen(
          ticket: widget.ticket,
          customer: customer!,
          machine: machine!,
        ),
      ),
    );
    return; // Exit here so PDF logic doesn't run
  }

  // 3. Existing PDF Generation Logic
  setState(() => _isGeneratingPdf = true);
  try {
    final customer = await _customerFuture;
    final machine = await _machineFuture;

    if (customer != null && machine != null) {
      await PdfHelper.shareTicketPdf(
        ticket: widget.ticket, // Uses the saved PocketBase model data
        customer: customer,
        machine: machine,
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
    }
  } finally {
    if (mounted) setState(() => _isGeneratingPdf = false);
  }
}

  late List<String> _existingPhotos;
  final List<File> _newPhotos = [];

  late Future<Customer?> _customerFuture;
  late Future<Machine?> _machineFuture;

  final Color colorBackground = const Color(0xFFF6EAD4);
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorSecondary = const Color(0xFFA2A595);
  final Color colorTextDark = const Color(0xFF3F4238);

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
    _costController.text = widget.ticket.warranty ? "0" : widget.ticket.cost.toStringAsFixed(0);
    _problemController.text = widget.ticket.problem;
    _noteController.text = widget.ticket.note; // Initialized note

    String rawWork = widget.ticket.workDone;
    _workDoneController.text = rawWork.contains("@@@") ? rawWork.split("@@@").first : rawWork;
    
    _existingPhotos = List.from(widget.ticket.photos);

    _customerFuture = CustomerService.getCustomers().then(
        (list) => list.firstWhere((c) => c.id == widget.ticket.customerId));
    _machineFuture = MachineService.getMachines().then(
        (list) => list.firstWhere((m) => m.id == widget.ticket.machineId));
  }

  void _handlePhoneAction(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    final bool canLaunch = await canLaunchUrl(url);
    
    if (!mounted) return;

    if (canLaunch) {
      await launchUrl(url);
    } else {
      Clipboard.setData(ClipboardData(text: phone));
    }
  }

  void _showEditMachineDialog(Machine machine) {
    final nameCtrl = TextEditingController(text: machine.name);
    final noteCtrl = TextEditingController(text: machine.note);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Edit Machine", style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyTextField(hintText: "Machine Name", obscureText: false, controller: nameCtrl),
            const SizedBox(height: 10),
            MyTextField(hintText: "Machine Note", obscureText: false, controller: noteCtrl, maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Cancel", style: TextStyle(color: colorSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
            onPressed: () async {
              try {
                await pb.collection('machines').update(machine.id, body: {
                  'name': nameCtrl.text.trim(),
                  'note': noteCtrl.text.trim(),
                });
                
                if (!mounted) return;

                setState(() {
                  _machineFuture = MachineService.getMachines().then((list) => list.firstWhere((m) => m.id == machine.id));
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 65, 
        maxWidth: 800,
      );

      if (!mounted) return;

      if (photo != null) {
        setState(() {
          _newPhotos.add(File(photo.path));
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Camera Error: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera timed out. Try again.")),
      );
    } catch (e) {
      debugPrint("Unexpected Error: $e");
    }
  }

  void _showFullScreenImage({File? file, String? remoteName}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: file != null 
                  ? Image.file(file) 
                  : Image.network(TicketService.getImageUrl('tickets', widget.ticket.id, remoteName!)),
              ),
            ),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  void _confirmDelete({int? index, bool isNew = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorBackground,
        title: const Text("Remove Photo?", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: colorTextDark))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                if (isNew) { _newPhotos.removeAt(index!); } 
                else { _existingPhotos.removeAt(index!); }
              });
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      List<http.MultipartFile> files = [];
      for (var f in _newPhotos) {
        files.add(await http.MultipartFile.fromPath('photos', f.path));
      }

      final currentUserEmail = pb.authStore.record?.getStringValue('email') ?? "Staff";
      final currentUserId = pb.authStore.record?.id;
      
      String workText = _workDoneController.text.trim();
      if (workText.isNotEmpty) workText = "$workText @@@ $currentUserEmail";

      Map<String, dynamic> body = {
        "status": _currentStatus,
        "problem": _problemController.text.trim(),
        "note": _noteController.text.trim(), // Included note in save body
        "cost": widget.ticket.warranty ? 0.0 : (double.tryParse(_costController.text) ?? 0.0),
        "work_done": workText,
        "photos": _existingPhotos, 
      };

      if (_currentStatus == 'done' && widget.ticket.status != 'done') {
        body["done_by"] = currentUserId;
        body["done_at"] = DateTime.now().toIso8601String();
      } else if (_currentStatus == 'closed' && widget.ticket.status != 'closed') {
        body["closed_by"] = currentUserId;
        body["closed_at"] = DateTime.now().toIso8601String();
      }

      await TicketService.updateTicket(widget.ticket.id, body, files: files);
      
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
       if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Text("Ticket #${widget.ticket.ticketUid}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (widget.ticket.isOut)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("On Site", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              if (widget.ticket.isOut == false)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("In House", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        backgroundColor: colorBackground, elevation: 0, foregroundColor: colorTextDark,
        actions: [
          // PDF Share Button
          if (_isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B705C))),
            )
          else
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _handlePdfShare,
              tooltip: "Share Bill",
            ),
        ],
      ),
      body: _isSaving 
      ? const Center(child: CircularProgressIndicator()) 
      : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Customer?>(
              future: _customerFuture,
              builder: (context, snapshot) => Card(
                elevation: 0, color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: colorBackground, child: Icon(Icons.person, color: colorPrimary)),
                  title: Text(snapshot.data?.name ?? "Loading...", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(snapshot.data?.primaryPhone ?? ""),
                  trailing: IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () => _handlePhoneAction(snapshot.data?.primaryPhone ?? "")),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Machine?>(
              future: _machineFuture,
              builder: (context, snapshot) {
                final machine = snapshot.data;
                final String machineIdString = machine != null 
                    ? "${machine.type.toLowerCase() == 'weight' ? 'W' : 'P'}-${machine.machineUid}"
                    : "...";

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(machine?.name ?? "...", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text("ID: $machineIdString", style: TextStyle(color: colorSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (widget.ticket.warranty)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text("WARRANTY", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 9)),
                        ),
                      IconButton(
                        onPressed: () => machine != null ? _showEditMachineDialog(machine) : null,
                        icon: Icon(Icons.edit_note, color: colorPrimary, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            MyTextField(hintText: "Problem", obscureText: false, controller: _problemController, maxLines: 2),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _currentStatus,
                      decoration: InputDecoration(fillColor: Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: ['open', 'done', 'closed'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (val) => setState(() => _currentStatus = val!),
                    ),
                  ],
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("COST (₹)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _costController,
                      enabled: !widget.ticket.warranty,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(fillColor: widget.ticket.warranty ? Colors.grey.shade200 : Colors.white, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 20),
            MyTextField(hintText: "Work Done", obscureText: false, controller: _workDoneController, maxLines: 3),
            if (widget.ticket.workDone.contains("@@@"))
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4), 
                child: Text("Last updated by: ${widget.ticket.workDone.split("@@@").last}", style: TextStyle(color: colorSecondary, fontSize: 10, fontStyle: FontStyle.italic))
              ),
            const SizedBox(height: 24),
            const Text("PHOTOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: colorSecondary.withAlpha(77))), 
                    child: const Icon(Icons.camera_alt_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingPhotos.length + _newPhotos.length,
                      itemBuilder: (context, index) {
                        bool isExisting = index < _existingPhotos.length;
                        int adjIdx = isExisting ? index : index - _existingPhotos.length;
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => isExisting 
                                ? _showFullScreenImage(remoteName: _existingPhotos[adjIdx])
                                : _showFullScreenImage(file: _newPhotos[adjIdx]),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: isExisting 
                                      ? NetworkImage(TicketService.getImageUrl('tickets', widget.ticket.id, _existingPhotos[adjIdx])) as ImageProvider
                                      : FileImage(_newPhotos[adjIdx]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16, top: 4,
                              child: GestureDetector(
                                onTap: () => _confirmDelete(index: adjIdx, isNew: !isExisting),
                                child: const CircleAvatar(radius: 10, backgroundColor: Colors.redAccent, child: Icon(Icons.close, size: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // --- INTERNAL NOTE SECTION ADDED HERE ---
            const Text("INTERNAL NOTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 8),
            MyTextField(hintText: "Add specific details...", obscureText: false, controller: _noteController, maxLines: 2),
            const SizedBox(height: 24),
            const Text("HISTORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildHistoryRow("Created", widget.ticket.openedBy, widget.ticket.created),
                  if (widget.ticket.doneAt != null) 
                    _buildHistoryRow("Done", widget.ticket.doneBy ?? "Staff", widget.ticket.doneAt),
                  if (widget.ticket.closedAt != null)
                    _buildHistoryRow("Closed", widget.ticket.closedBy ?? "Admin", widget.ticket.closedAt),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimary, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("UPDATE TICKET", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String label, String user, DateTime? time) {
    String formattedTime = time != null ? DateFormat('dd/MM/yy, hh:mm a').format(time) : "";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(child: Text(user, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
          Text(formattedTime, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}