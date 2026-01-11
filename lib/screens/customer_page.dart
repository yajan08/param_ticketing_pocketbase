import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../models/ticket_model.dart';
import '../services/customer_service.dart';
import '../services/machine_service.dart';
import '../services/ticket_service.dart';
import '../utils/my_textfield.dart';
import 'ticket_detail_screen.dart';
import '../pb.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  String _searchQuery = "";
  List<Customer> _allCustomers = [];
  bool _isLoading = true;

  final Color colorBackground = const Color(0xFFF6EAD4);
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorSecondary = const Color(0xFFA2A595);
  final Color colorTextDark = const Color(0xFF3F4238);

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final customers = await CustomerService.getCustomers();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePhoneAction(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Clipboard.setData(ClipboardData(text: phone));
    }
  }

  void _showEditCustomerDialog(Customer customer) {
    final nameCtrl = TextEditingController(text: customer.name);
    final primaryPhoneCtrl = TextEditingController(text: customer.primaryPhone);
    final secondaryPhoneCtrl = TextEditingController(text: customer.secondaryPhone);
    final companyCtrl = TextEditingController(text: customer.company);
    final noteCtrl = TextEditingController(text: customer.note);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Edit Customer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextField(hintText: "Full Name", obscureText: false, controller: nameCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Primary Phone", obscureText: false, controller: primaryPhoneCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Secondary Phone", obscureText: false, controller: secondaryPhoneCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Company", obscureText: false, controller: companyCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Internal Note", obscureText: false, controller: noteCtrl, maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: TextStyle(color: colorSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
            onPressed: () async {
              await pb.collection('customers').update(customer.id, body: {
                'name': nameCtrl.text.trim(),
                'primary_phone': primaryPhoneCtrl.text.trim(),
                'secondary_phone': secondaryPhoneCtrl.text.trim(),
                'company': companyCtrl.text.trim(),
                'note': noteCtrl.text.trim(),
              });

              if (!mounted) return;
              _fetchCustomers(); 

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allCustomers.where((c) {
      final query = _searchQuery.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      String searchContent = [
        c.name,
        c.company,
        c.primaryPhone,
        c.secondaryPhone,
        c.note,
      ].join(' ').toLowerCase().replaceAll(RegExp(r'\s+'), '');
      return searchContent.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text("C U S T O M E R S", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorTextDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search name, company, phone, or note...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: colorPrimary))
              : filtered.isEmpty 
                ? _buildEmptyState(Icons.person_off_rounded, "No customers found")
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildCustomerCard(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    String phoneDisplay = customer.primaryPhone;
    if (customer.secondaryPhone.isNotEmpty) {
      phoneDisplay += " / ${customer.secondaryPhone}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colorPrimary.withAlpha(30),
          child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "?", 
              style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold)),
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(color: colorTextDark, fontSize: 14, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: customer.name),
              if (customer.company.isNotEmpty)
                TextSpan(
                  text: " (${customer.company})",
                  style: TextStyle(color: colorSecondary, fontWeight: FontWeight.normal, fontSize: 12),
                ),
            ],
          ),
        ),
        subtitle: Text(phoneDisplay, style: TextStyle(color: colorSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: colorPrimary, size: 20),
              onPressed: () => _showEditCustomerDialog(customer),
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green, size: 20),
              onPressed: () => _handlePhoneAction(customer.primaryPhone),
            ),
            Icon(Icons.arrow_forward_ios, color: colorSecondary.withAlpha(100), size: 14),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerMachineListPage(customer: customer))),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: colorSecondary.withAlpha(100)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: colorSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class CustomerMachineListPage extends StatefulWidget {
  final Customer customer;
  const CustomerMachineListPage({super.key, required this.customer});

  @override
  State<CustomerMachineListPage> createState() => _CustomerMachineListPageState();
}

class _CustomerMachineListPageState extends State<CustomerMachineListPage> {
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorBackground = const Color(0xFFF6EAD4);

  void _showEditMachineDialog(Machine machine) {
    final nameCtrl = TextEditingController(text: machine.name);
    final noteCtrl = TextEditingController(text: machine.note);
    String selectedType = machine.type.toLowerCase(); // Track type in dialog state

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: colorBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Edit Machine", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Added Machine Type Toggle
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
              MyTextField(hintText: "Machine Note", obscureText: false, controller: noteCtrl, maxLines: 2),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colorPrimary),
              onPressed: () async {
                await pb.collection('machines').update(machine.id, body: {
                  'name': nameCtrl.text.trim(),
                  'type': selectedType, // Update type in PocketBase
                  'note': noteCtrl.text.trim(),
                });

                if (!mounted) return;
                setState(() {}); 

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text("${widget.customer.name}'s Machines", 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: const Color(0xFF3F4238),
      ),
      body: FutureBuilder<List<Machine>>(
        future: MachineService.getMachines(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: colorPrimary));
          
          final machines = snapshot.data?.where((m) => m.ownerIds.contains(widget.customer.id)).toList() ?? [];

          if (machines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.precision_manufacturing_outlined, size: 60, color: colorPrimary.withAlpha(50)),
                  const SizedBox(height: 16),
                  const Text("No machines assigned", style: TextStyle(color: Color(0xFFA2A595), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: machines.length,
            itemBuilder: (context, index) {
              final m = machines[index];
              final String typePrefix = m.type.toLowerCase() == 'weight' ? 'W' : 'P';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8)],
                ),
                child: ListTile(
                  title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("ID: $typePrefix-${m.machineUid}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_note, color: colorPrimary),
                        onPressed: () => _showEditMachineDialog(m),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFA2A595)),
                    ],
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MachineHistoryPage(machine: m))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MachineHistoryPage extends StatelessWidget {
  final Machine machine;
  const MachineHistoryPage({super.key, required this.machine});

  @override
  Widget build(BuildContext context) {
    const Color colorBackground = Color(0xFFF6EAD4);
    const Color colorPrimary = Color(0xFF6B705C);

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text("History: ${machine.name}", 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, foregroundColor: const Color(0xFF3F4238),
      ),
      body: FutureBuilder<List<Ticket>>(
        future: TicketService.getTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final tickets = snapshot.data?.where((t) => t.machineId == machine.id).toList() ?? [];

          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 60, color: colorPrimary.withAlpha(50)),
                  const SizedBox(height: 16),
                  const Text("No service history", style: TextStyle(color: Color(0xFFA2A595), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              Color statusColor = ticket.status.toLowerCase() == 'open' 
                  ? const Color(0xFFE67E22) 
                  : (ticket.status.toLowerCase() == 'done' ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D));

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4)]
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text("#${ticket.ticketUid}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11))),
                  ),
                  title: Text(ticket.problem, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('dd MMM yyyy').format(ticket.created), style: const TextStyle(fontSize: 11)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailScreen(ticket: ticket))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}