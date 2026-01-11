import 'package:flutter/material.dart';
import '../pb.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../utils/my_textfield.dart';

class CustomerSelectionScreen extends StatefulWidget {
  const CustomerSelectionScreen({super.key});

  @override
  State<CustomerSelectionScreen> createState() => _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
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
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await CustomerService.getCustomers();
      if (!mounted) return;
      setState(() {
        _allCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Normalize the user query: lowercase and remove ALL whitespace
    String normalizedQuery = _searchQuery.toLowerCase().replaceAll(RegExp(r'\s+'), "");

    List<Customer> filtered = _allCustomers.where((c) {
      // 2. Normalize all data fields for comparison
      String nName = c.name.toLowerCase().replaceAll(RegExp(r'\s+'), "");
      String nCompany = c.company.toLowerCase().replaceAll(RegExp(r'\s+'), "");
      String nPhone = c.primaryPhone.replaceAll(RegExp(r'\s+'), "");
      String nSecPhone = c.secondaryPhone.replaceAll(RegExp(r'\s+'), "");
      String nNote = c.note.toLowerCase().replaceAll(RegExp(r'\s+'), "");

      // 3. Compare normalized query against normalized fields
      return normalizedQuery.isEmpty || 
              nName.contains(normalizedQuery) || 
              nCompany.contains(normalizedQuery) || 
              nPhone.contains(normalizedQuery) || 
              nSecPhone.contains(normalizedQuery) ||
              nNote.contains(normalizedQuery);
    }).toList();

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        backgroundColor: colorBackground,
        elevation: 0,
        title: Text("Select Customer", style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: colorPrimary),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search Name, Company, Phone or Note...",
                hintStyle: TextStyle(color: colorSecondary, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: colorPrimary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: colorPrimary))
              : ListView.builder(
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildAddTile();
                    
                    final customer = filtered[index - 1];
                    return _buildCustomerTile(customer);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorPrimary.withAlpha(26), // 0.1 * 255 approx 26
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _showCreateDialog(),
        leading: CircleAvatar(backgroundColor: colorPrimary, child: const Icon(Icons.person_add, color: Colors.white)),
        title: Text(_searchQuery.isEmpty ? "Register New Customer" : "Add \"$_searchQuery\"", 
          style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold)),
        subtitle: const Text("Create a new profile if not found"),
      ),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5, offset: const Offset(0, 2))], // 0.05 * 255 approx 13
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorSecondary.withAlpha(51), child: Icon(Icons.person, color: colorPrimary)), // 0.2 * 255 approx 51
        title: RichText(
          text: TextSpan(
            style: TextStyle(color: colorTextDark, fontSize: 16, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: customer.name),
              if (customer.company.isNotEmpty)
                TextSpan(
                  text: " (${customer.company})",
                  style: TextStyle(color: colorPrimary, fontWeight: FontWeight.normal, fontSize: 13),
                ),
            ],
          ),
        ),
        subtitle: Text(customer.secondaryPhone.isEmpty 
            ? customer.primaryPhone 
            : "${customer.primaryPhone} / ${customer.secondaryPhone}"),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: colorPrimary),
          onPressed: () => _showEditCustomerDialog(customer),
        ),
        onTap: () => Navigator.pop(context, customer),
      ),
    );
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
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await pb.collection('customers').update(customer.id, body: {
                  'name': nameCtrl.text.trim(),
                  'primary_phone': primaryPhoneCtrl.text.trim(),
                  'secondary_phone': secondaryPhoneCtrl.text.trim(),
                  'company': companyCtrl.text.trim(),
                  'note': noteCtrl.text.trim(),
                });

                if (!mounted) return;
                _loadCustomers(); // Refresh the list

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController(text: double.tryParse(_searchQuery) == null ? _searchQuery : "");
    final companyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: double.tryParse(_searchQuery) != null ? _searchQuery : "");
    final secPhoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorBackground,
        title: Text("New Customer Profile", style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextField(hintText: "Full Name *", obscureText: false, controller: nameCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Company Name", obscureText: false, controller: companyCtrl),
              const SizedBox(height: 10),
              MyTextField(hintText: "Primary Phone *", obscureText: false, controller: phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              MyTextField(hintText: "Secondary Phone", obscureText: false, controller: secPhoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              MyTextField(hintText: "Notes (Address, etc.)", obscureText: false, controller: noteCtrl, maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: colorSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Primary Phone are required")));
                }
                return;
              }

              final data = {
                'name': nameCtrl.text.trim(),
                'company': companyCtrl.text.trim(),
                'primary_phone': phoneCtrl.text.trim(),
                'secondary_phone': secPhoneCtrl.text.trim(),
                'note': noteCtrl.text.trim(),
              };

              try {
                await CustomerService.addCustomer(data);
                
                // Re-fetch record to get the server-generated ID
                final records = await pb.collection('customers').getList(
                  filter: 'primary_phone = "${phoneCtrl.text.trim()}"',
                );

                if (!context.mounted) return;

                if (records.items.isNotEmpty) {
                  final newCust = Customer.fromRecord(records.items.first);
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, newCust); // Pass to Add Ticket Screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Save Customer"),
          )
        ],
      ),
    );
  }
}