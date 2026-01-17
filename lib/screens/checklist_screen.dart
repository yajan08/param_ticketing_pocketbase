import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../services/ticket_service.dart';
import '../utils/pdf_helper.dart';
import '../utils/my_textfield.dart';

// Helper class to hold the state of each checklist row
class ChecklistItem {
  final String name;
  bool isChecked;
  final TextEditingController controller;

  ChecklistItem({
    required this.name,
    this.isChecked = false,
  }) : controller = TextEditingController();
}

class ChecklistScreen extends StatefulWidget {
  final Ticket ticket;
  final Customer customer;
  final Machine machine;

  const ChecklistScreen({
    super.key,
    required this.ticket,
    required this.customer,
    required this.machine,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // 1. Central Configuration Arrays
  final List<String> _weightItems = [
    'Battery', 'Display', 'Keyboard', 'Caliberation', 'Power Supply', 'Loadcell', 'Overall'
  ];

  final List<String> _packingItems = [
    'Small Patti', 'Big Patti', 'Coil', 'Heating', 
    'Packing', 'Buzzer', 'Regulator', 'General'
  ];

  late List<ChecklistItem> _items;

  // Track selected image name
  String? _selectedPhotoName;
  
  // NEW: Track generation state for the button buffer
  bool _isGenerating = false;

  final Color colorBackground = const Color(0xFFF6EAD4);
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorTextDark = const Color(0xFF3F4238);

  @override
  void initState() {
    super.initState();
    _initializeChecklist();
  }

  // 2. Logic to pick items based on Machine Type
  void _initializeChecklist() {
    String type = widget.machine.type.toLowerCase();
    
    List<String> selectedList = (type == 'packing') 
        ? _packingItems 
        : _weightItems;

    _items = selectedList.map((name) => ChecklistItem(name: name)).toList();
  }

  void _generateFinalPdf() async {
    // Prevent double taps
    if (_isGenerating) return;

    // --- MANDATORY PHOTO VALIDATION ---
    if (_selectedPhotoName == null && widget.ticket.photos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a photo for the PDF signature area."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // 3. Prepare data for PDF Service
      final List<Map<String, String>> selectedData = _items
          .map((item) => {
                "item": item.name,
                "remark": item.controller.text.trim(),
                "status": item.isChecked ? "YES" : "NO",
              })
          .toList();

      await PdfHelper.shareTicketPdf(
        ticket: widget.ticket,
        customer: widget.customer,
        machine: widget.machine,
        checklistData: selectedData,
        selectedPhotoName: _selectedPhotoName, 
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text("Service Checklist", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorBackground,
        foregroundColor: colorTextDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // --- CHECKLIST ITEMS SECTION ---
          ..._items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name, 
                        style: TextStyle(
                          color: colorTextDark, 
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        )
                      ),
                      value: item.isChecked,
                      activeColor: colorPrimary,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setState(() => item.isChecked = val!);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: MyTextField(
                        hintText: "Remarks (if any)",
                        obscureText: false,
                        controller: item.controller,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // --- PHOTO SELECTION SECTION (Inside the scroll view) ---
          if (widget.ticket.photos.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("SELECT PHOTO FOR PDF", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                const SizedBox(width: 5),
                const Text("*", style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.ticket.photos.length,
                itemBuilder: (context, index) {
                  String photoName = widget.ticket.photos[index];
                  bool isSelected = _selectedPhotoName == photoName;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPhotoName = isSelected ? null : photoName;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? colorPrimary : Colors.black12,
                          width: isSelected ? 3 : 1,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(TicketService.getImageUrl('tickets', widget.ticket.id, photoName)),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isSelected 
                          ? const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 35))
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30), // Extra space at bottom of scroll
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorBackground,
          border: Border(top: BorderSide(color: colorPrimary.withAlpha(10))),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isGenerating ? null : _generateFinalPdf,
          child: _isGenerating 
            ? const SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : const Text("GENERATE & SHARE PDF", 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)
              ),
        ),
      ),
    );
  }
}