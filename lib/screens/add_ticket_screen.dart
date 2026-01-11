import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../services/ticket_service.dart';
import '../utils/my_button.dart';
import '../utils/my_textfield.dart';
import 'customer_selection_screen.dart';
import 'machine_selection_screen.dart';

class AddTicketScreen extends StatefulWidget {
  const AddTicketScreen({super.key});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  Customer? _selectedCustomer;
  Machine? _selectedMachine;
  bool _isLoading = false;
  bool _isWarranty = false;

  final List<File> _capturedImages = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final Color colorBackground = const Color(0xFFF6EAD4);
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorSecondary = const Color(0xFFA2A595);
  final Color colorTextDark = const Color(0xFF3F4238);

  // --- DYNAMIC ISSUE LISTS ---
  final List<String> _weightIssues = [
    'Battery', 'Wire', 'Display', 'PCB', 'FRC', 
    'LED', 'Switch', 'Transformer', 'Loadcell', 'Dead', 'other'
    ];

  final List<String> _packingIssues = [
    'Coil', 'Small Patti', 'Big Patti', 'Transformer', 'Relay', 'Wire', 'Dead', 'other'
  ];

  // Helper to get current list based on machine type
  List<String> get _currentPredefinedIssues {
    if (_selectedMachine == null) return [];
    return _selectedMachine!.type.toLowerCase() == 'weight' 
        ? _weightIssues 
        : _packingIssues;
  }

  // --- PHOTO CAPTURE ---
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 65,
      maxWidth: 800,
    );
    if (photo != null) {
      setState(() {
        _capturedImages.add(File(photo.path));
      });
    }
  }

  // --- FULL SCREEN PREVIEW ---
  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(imageFile, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DELETE CONFIRMATION ---
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Remove Photo?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this image?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: colorTextDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _capturedImages.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- SAVE LOGIC ---
  void _handleSaveTicket() async {
    setState(() => _isLoading = true);
    try {
      await TicketService.createTicket(
        customerId: _selectedCustomer!.id,
        machineId: _selectedMachine!.id,
        problem: _problemController.text.trim(),
        warranty: _isWarranty,
        images: _capturedImages,
      );

      if (mounted) {
        // Pass 'true' back to the previous screen
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _pickCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerSelectionScreen()),
    );
    if (result != null && result is Customer) {
      setState(() {
        _selectedCustomer = result;
        _selectedMachine = null;
        _problemController.clear(); // Clear issues when customer changes
      });
    }
  }

  void _navigateToMachineSelection() async {
    if (_selectedCustomer == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MachineSelectionScreen(customer: _selectedCustomer!),
      ),
    );
    if (result != null && result is Machine) {
      setState(() {
        _selectedMachine = result;
        _problemController.clear(); // Clear previous issues if machine type changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFormValid = _selectedCustomer != null && 
                       _selectedMachine != null && 
                       _problemController.text.trim().isNotEmpty;

    // Get current predefined list based on selected machine type
    final currentIssuesList = _currentPredefinedIssues;

    List<String> selectedOptions = _problemController.text
        .split(', ')
        .where((s) => currentIssuesList.contains(s))
        .toList();

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        elevation: 0,
        centerTitle: true,
        title: Text("NEW TICKET", 
          style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)),
        leading: IconButton(
          icon: Icon(Icons.close, color: colorTextDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          height: 90, 
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: colorBackground,
            border: Border(top: BorderSide(color: colorSecondary.withAlpha(51))),
          ),
          child: _isLoading 
            ? Center(child: CircularProgressIndicator(color: colorPrimary))
            : MyButton(
                buttonText: "FINALIZE TICKET",
                onTap: isFormValid ? _handleSaveTicket : null, 
              ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("CUSTOMER", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorSecondary.withAlpha(26))),
              title: Text(_selectedCustomer?.name ?? "Select Customer", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_selectedCustomer?.primaryPhone ?? "Required"),
              trailing: Icon(Icons.person_search, color: colorPrimary),
              onTap: _pickCustomer,
            ),

            const SizedBox(height: 25),

            Text("MACHINE", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 8),
            if (_selectedMachine == null)
              OutlinedButton.icon(
                onPressed: _selectedCustomer == null ? null : _navigateToMachineSelection,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Pick Machine"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  foregroundColor: colorPrimary,
                  side: BorderSide(color: colorPrimary.withAlpha(102)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colorSecondary.withAlpha(26))),
                title: Text(_selectedMachine!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("ID: ${_selectedMachine!.type.toLowerCase() == 'weight' ? 'W' : 'P'}-${_selectedMachine!.machineUid}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToMachineSelection,
              ),

            if (_selectedMachine != null) ...[
              const SizedBox(height: 25),
              Text("Reported problems", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 0,
                children: currentIssuesList.map((problem) {
                  bool isSelected = selectedOptions.contains(problem);
                  return FilterChip(
                    label: Text(problem, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : colorTextDark)),
                    selected: isSelected,
                    selectedColor: colorPrimary,
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedOptions.add(problem);
                        } else {
                          selectedOptions.remove(problem);
                        }
                        _problemController.text = selectedOptions.join(", ");
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              MyTextField(
                controller: _problemController,
                hintText: "Detailed problem",
                obscureText: false,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Under Warranty?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                value: _isWarranty,
                activeThumbColor: colorPrimary,
                onChanged: (val) => setState(() => _isWarranty = val),
              ),

              const SizedBox(height: 25),
              Text("PHOTOS", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorSecondary.withAlpha(77)),
                      ),
                      child: Icon(Icons.camera_alt_outlined, color: colorPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _capturedImages.length,
                        itemBuilder: (context, index) => Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showFullScreenImage(_capturedImages[index]),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colorSecondary.withAlpha(51)),
                                  image: DecorationImage(
                                    image: FileImage(_capturedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 16, top: 4,
                              child: GestureDetector(
                                onTap: () => _confirmDelete(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              MyTextField(
                controller: _notesController,
                hintText: "Notes",
                obscureText: false,
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }
}