import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../services/machine_service.dart';
import '../utils/my_textfield.dart';

class MachineSelectionScreen extends StatefulWidget {
  final Customer customer;
  const MachineSelectionScreen({super.key, required this.customer});

  @override
  State<MachineSelectionScreen> createState() => _MachineSelectionScreenState();
}

class _MachineSelectionScreenState extends State<MachineSelectionScreen> {
  String _searchQuery = "";
  List<Machine> _allMachines = [];
  bool _isLoading = true;

  final Color colorBackground = const Color(0xFFF6EAD4);
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorSecondary = const Color(0xFFA2A595);
  final Color colorTextDark = const Color(0xFF3F4238);

  @override
  void initState() {
    super.initState();
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    try {
      final machines = await MachineService.getMachines();
      if (!mounted) return;
      setState(() {
        _allMachines = machines;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show machines linked to this specific customer
    List<Machine> ownedMachines =
        _allMachines.where((m) => m.ownerIds.contains(widget.customer.id)).toList();

    String normalizedQuery = _searchQuery.toLowerCase().replaceAll(RegExp(r'\s+'), "");

    List<Machine> filtered = ownedMachines.where((m) {
      String nName = m.name.toLowerCase().replaceAll(RegExp(r'\s+'), "");
      String prefix = m.type.toLowerCase() == 'weight' ? 'W' : 'P';
      String fullId = "$prefix-${m.machineUid}";
      String nNote = m.note.toLowerCase().replaceAll(RegExp(r'\s+'), "");
      return normalizedQuery.isEmpty ||
          nName.contains(normalizedQuery) ||
          fullId.toLowerCase().contains(normalizedQuery) ||
          nNote.contains(normalizedQuery);
    }).toList();

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        elevation: 0,
        title: Text("Select Machine",
            style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: colorPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search customer's machines...",
                prefixIcon: Icon(Icons.search, color: colorPrimary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          _buildActionRow(),
          const Divider(height: 30),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorPrimary))
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final machine = filtered[index];
                          String idPrefix = machine.type.toLowerCase() == 'weight' ? 'W' : 'P';

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorPrimary.withAlpha(26)),
                            ),
                            child: ListTile(
                              onTap: () => Navigator.pop(context, machine),
                              leading: CircleAvatar(
                                backgroundColor: colorPrimary.withAlpha(26),
                                child: Text(idPrefix,
                                    style: TextStyle(
                                        color: colorPrimary, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(machine.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle:
                                  Text("ID: $idPrefix-${machine.machineUid} • ${machine.type}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.blueGrey),
                                onPressed: () => _showEditMachineDialog(machine),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showEditMachineDialog(Machine machine) {
    final nameCtrl = TextEditingController(text: machine.name);
    final noteCtrl = TextEditingController(text: machine.note);
    String selectedType = machine.type.toLowerCase();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorBackground,
          title: const Text("Edit Machine"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Weight"),
                      selected: selectedType == "weight",
                      onSelected: (val) => setDialogState(() => selectedType = "weight"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Packing"),
                      selected: selectedType == "packing",
                      onSelected: (val) => setDialogState(() => selectedType = "packing"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              MyTextField(hintText: "Machine Name", obscureText: false, controller: nameCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Permanent Note", obscureText: false, controller: noteCtrl),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await MachineService.updateMachine(machine.id, {
                  'name': nameCtrl.text,
                  'type': selectedType,
                  'note': noteCtrl.text,
                });
                
                if (!mounted) return;
                _loadMachines();
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }

  void _showCreateMachineDialog() {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedType = "weight";

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorBackground,
          title: const Text("Register Machine"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Weight"),
                      selected: selectedType == "weight",
                      onSelected: (val) => setDialogState(() => selectedType = "weight"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text("Packing"),
                      selected: selectedType == "packing",
                      onSelected: (val) => setDialogState(() => selectedType = "packing"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              MyTextField(hintText: "Machine Name", obscureText: false, controller: nameCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Permanent Note", obscureText: false, controller: noteCtrl),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                
                await MachineService.createMachine(
                  name: nameCtrl.text,
                  type: selectedType,
                  customerIds: [widget.customer.id],
                  note: noteCtrl.text,
                );
                
                final machines = await MachineService.getMachines();
                
                if (!mounted) return;
                
                final newMachine = machines.firstWhere((m) => m.ownerIds.contains(widget.customer.id));
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                
                if (context.mounted) {
                  Navigator.pop(context, newMachine);
                }
              },
              child: const Text("Register & Select"),
            )
          ],
        ),
      ),
    );
  }

  void _showLinkIdDialog() {
    final idCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Link via Machine ID"),
        content: MyTextField(hintText: "Enter ID (e.g., W-5 or P-12)", obscureText: false, controller: idCtrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              String input = idCtrl.text.trim().toUpperCase();
              try {
                final machine = _allMachines.firstWhere((m) {
                  String prefix = m.type.toLowerCase() == 'weight' ? 'W' : 'P';
                  return "$prefix-${m.machineUid}" == input;
                });
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                _showLinkConfirmDialog(machine);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text("Machine not found")));
                }
              }
            },
            child: const Text("Find"),
          )
        ],
      ),
    );
  }

  void _showLinkConfirmDialog(Machine machine) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Owner?"),
        content: Text("Link ${machine.name} to ${widget.customer.name}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              List<String> owners = List.from(machine.ownerIds)..add(widget.customer.id);
              await MachineService.updateMachine(machine.id, {'owner': owners});
              
              if (!mounted) return;
              
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              
              if (context.mounted) {
                Navigator.pop(context, machine);
              }
            },
            child: const Text("Link & Select"),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.precision_manufacturing_outlined,
              size: 64, color: colorSecondary.withAlpha(128)),
          const SizedBox(height: 16),
          const Text("No machines linked to this customer."),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
              child: _smallActionButton(
                  icon: Icons.add_box, label: "New Machine", onTap: _showCreateMachineDialog)),
          const SizedBox(width: 12),
          Expanded(
              child: _smallActionButton(
                  icon: Icons.link, label: "Link ID", onTap: _showLinkIdDialog)),
        ],
      ),
    );
  }

  Widget _smallActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration:
            BoxDecoration(color: colorPrimary, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }
}