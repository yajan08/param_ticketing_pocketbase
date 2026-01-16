import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
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
    'PCB', 'Earthing', 'Battery', 'Display', 'Loadcell', 
    'Calibration', 'Cleaning', 'Keyboard', 'Mains Chord', 'Levelling'
  ];

  final List<String> _packingItems = [
    'Small Patti', 'Big Patti', 'Coil', 'Heating', 
    'Packing', 'Beeper', 'Regulator'
  ];

  late List<ChecklistItem> _items;

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
    // 3. Prepare data for PDF Service
    final List<Map<String, String>> selectedData = _items
        .map((item) => {
              "item": item.name,
              "remark": item.controller.text.trim(),
              "status": item.isChecked ? "YES" : "NO", // <--- ADD THIS LINE
            })
        .toList();

    await PdfHelper.shareTicketPdf(
      ticket: widget.ticket,
      customer: widget.customer,
      machine: widget.machine,
      checklistData: selectedData, // We will add this parameter to PdfHelper next
    );
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
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
                // 1. Checkbox and Label (Left Side)
                Expanded(
                  flex: 2, // Controls the width ratio
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
                    controlAffinity: ListTileControlAffinity.leading, // Box on the left
                    onChanged: (val) {
                      setState(() => item.isChecked = val!);
                    },
                  ),
                ),
                
                const SizedBox(width: 10),

                // 2. Remarks TextField (Right Side)
                Expanded(
                  flex: 3, // Gives more space to the text input
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: MyTextField(
                      hintText: "Remarks",
                      obscureText: false,
                      controller: item.controller,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
          onPressed: _generateFinalPdf,
          child: const Text("GENERATE & SHARE PDF", 
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)
          ),
        ),
      ),
    );
  }
}