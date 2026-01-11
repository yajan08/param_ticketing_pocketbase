import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:param_ticketing/screens/ticket_detail_screen.dart';
import 'package:pocketbase/pocketbase.dart';
import '../pb.dart';
import '../models/ticket_model.dart';
import '../models/customer_model.dart';
import '../models/machine_model.dart';
import '../services/ticket_service.dart';
import '../services/customer_service.dart';
import '../services/machine_service.dart';
import '../utils/my_drawer.dart';
import 'add_ticket_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Logic State
  String _searchQuery = "";
  String _selectedStatusFilter = "all";
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  bool _isBackgroundSyncing = false; 

  // Data State
  List<Ticket> _allTickets = [];
  Map<String, Customer> _customerMap = {};
  Map<String, Machine> _machineMap = {};
  
  // Real-time Subscription references
  UnsubscribeFunc? _unsubTickets; 
  UnsubscribeFunc? _unsubCustomers;
  UnsubscribeFunc? _unsubMachines;
  UnsubscribeFunc? _unsubBans;

  // Palette
  final Color colorBackground = const Color(0xFFF6EAD4);
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorSecondary = const Color(0xFFA2A595);
  final Color colorTextDark = const Color(0xFF3F4238);

  @override
  void initState() {
    super.initState();
    // 1. Initial Load
    _loadInitialData();
    // Wait 1 second before starting real-time subscriptions 
  // to give the main data request priority
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) _initRealtimeSubscriptions();
  });
  }

  @override
  void dispose() {
    // Crucial: Clean up WebSocket connections to prevent memory leaks
    _unsubTickets?.call();
    _unsubCustomers?.call();
    _unsubMachines?.call();
    _unsubBans?.call();
    super.dispose();
  }

  // --- home_screen.dart ---

void _initRealtimeSubscriptions() async {
  // Listen to Tickets
  _unsubTickets = await TicketService.subscribeToTickets((ticket, action) {
    if (!mounted) return;

    setState(() {
      if (action == 'create') {
        // Add new ticket to the top
        _allTickets.insert(0, ticket);
      } else if (action == 'update') {
        // Find and replace the specific ticket
        final index = _allTickets.indexWhere((t) => t.id == ticket.id);
        if (index != -1) _allTickets[index] = ticket;
      } else if (action == 'delete') {
        // Remove the ticket
        _allTickets.removeWhere((t) => t.id == ticket.id);
      }
    });
  });

  // Keep these as "full refreshes" because mapping logic is complex
  _unsubCustomers = await pb.collection('customers').subscribe('*', (e) {
    if (mounted) _loadInitialData(showLoading: false);
  });

  _unsubMachines = await pb.collection('machines').subscribe('*', (e) {
    if (mounted) _loadInitialData(showLoading: false);
  });

  // 1. Listen for Bans
  _unsubBans = await pb.collection('banned_users').subscribe('*', (e) {
    if (!mounted) return;

    final currentUserEmail = pb.authStore.record?.getStringValue('email');

    // 2. Check if the action is a new ban ('create')
    if (e.action == 'create' && currentUserEmail != null) {
      final bannedEmail = e.record?.getStringValue('email');

      if (bannedEmail?.toLowerCase() == currentUserEmail.toLowerCase()) {
        
        // 3. Use SchedulerBinding to prevent the "Not Responding" freeze
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          // Clear local session
          pb.authStore.clear();

          // Force redirect to login and clear navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', 
            (route) => false
          );

          // Alert the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account Restricted: You have been logged out."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        });
      }
    }
  });

}

  // --- DATA LOADING ---

  bool _isFetchingData = false; 
  Future<void> _loadInitialData({bool showLoading = true}) async {
  if (_isFetchingData) return; 
  if (!mounted) return;

  setState(() {
    if (showLoading) {
      _isLoading = true;
    } else {
      _isBackgroundSyncing = true;
    }
  });
  
  _isFetchingData = true;

  try {
    // Add a .timeout() to the entire parallel operation
    final results = await Future.wait([
      TicketService.getTickets(),
      CustomerService.getCustomers(),
      MachineService.getMachines(),
    ]).timeout(const Duration(seconds: 10)); // If network is slow, don't wait forever

    if (!mounted) return;

    setState(() {
      _allTickets = results[0] as List<Ticket>;
      _customerMap = {for (var item in results[1] as List<Customer>) item.id: item};
      _machineMap = {for (var item in results[2] as List<Machine>) item.id: item};
      _isLoading = false;
      _isBackgroundSyncing = false;
    });
    print("HOME: Data Loaded Successfully");
  } catch (e) {
    print("HOME LOAD ERROR: $e");
    if (mounted) {
      setState(() { 
        _isLoading = false; 
        _isBackgroundSyncing = false; 
      });
      // Show the user what went wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection Error: Check your internet")),
      );
    }
  } finally {
    _isFetchingData = false; 
  }
}

  // --- UI COMPONENTS ---

  void _showSimpleDatePicker() {
    final List<int> days = List.generate(31, (i) => i + 1);
    final List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final List<int> years = List.generate(6, (i) => 2024 + i);

    int sDay = _startDate?.day ?? DateTime.now().day;
    int sMonth = _startDate?.month ?? DateTime.now().month;
    int sYear = _startDate?.year ?? DateTime.now().year;
    int eDay = _endDate?.day ?? DateTime.now().day;
    int eMonth = _endDate?.month ?? DateTime.now().month;
    int eYear = _endDate?.year ?? DateTime.now().year;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Filter by Date Range", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              _buildDateRow("FROM", days, sDay, months, sMonth, years, sYear, (d, m, y) {
                setPickerState(() { sDay = d; sMonth = m; sYear = y; });
              }),
              const SizedBox(height: 15),
              _buildDateRow("TO", days, eDay, months, eMonth, years, eYear, (d, m, y) {
                setPickerState(() { eDay = d; eMonth = m; eYear = y; });
              }),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () { setState(() { _startDate = null; _endDate = null; }); Navigator.pop(context); }, child: const Text("Clear"))),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colorPrimary, foregroundColor: Colors.white),
                    onPressed: () {
                      setState(() {
                        _startDate = DateTime(sYear, sMonth, sDay);
                        _endDate = DateTime(eYear, eMonth, eDay);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Apply"),
                  )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, List<int> days, int d, List<String> months, int m, List<int> years, int y, Function(int, int, int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: colorPrimary, fontWeight: FontWeight.bold)),
        Row(
          children: [
            DropdownButton<int>(value: d, items: days.map((i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(), onChanged: (v) => onChanged(v!, m, y)),
            const SizedBox(width: 10),
            DropdownButton<String>(value: months[m-1], items: months.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => onChanged(d, months.indexOf(v!) + 1, y)),
            const SizedBox(width: 10),
            DropdownButton<int>(value: y, items: years.map((i) => DropdownMenuItem(value: i, child: Text(i.toString()))).toList(), onChanged: (v) => onChanged(d, m, v!)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanQuery = _searchQuery.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    List<Ticket> filtered = _allTickets.where((t) {
      if (_selectedStatusFilter != "all" && t.status.toLowerCase() != _selectedStatusFilter) return false;
      if (_startDate != null && _endDate != null) {
        if (t.created.isBefore(_startDate!) || t.created.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
      }
      if (cleanQuery.isEmpty) return true;
      
      final cust = _customerMap[t.customerId];
      final mach = _machineMap[t.machineId];

      String payload = [
        t.ticketUid, t.note, t.problem, t.cost.toStringAsFixed(0), t.workDone,
        t.openedBy, t.doneBy ?? '', t.closedBy ?? '',
        cust?.name ?? '', cust?.note ?? '', cust?.primaryPhone ?? '', cust?.secondaryPhone ?? '', cust?.company ?? '',
        mach?.machineUid ?? '', mach?.name ?? '', mach?.note ?? '', mach?.type ?? '',
      ].join(' ').toLowerCase().replaceAll(RegExp(r'\s+'), '');

      return payload.contains(cleanQuery);
    }).toList();

    filtered.sort((a, b) => b.created.compareTo(a.created));

    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text("DASHBOARD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Small sync indicator to let users know the app is updating live in background
          if (_isBackgroundSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B705C))),
            )
        ],
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search tickets...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("All", "all"),
                const SizedBox(width: 4),
                _buildFilterChip("Open", "open"),
                const SizedBox(width: 4),
                _buildFilterChip("Done", "done"),
                const SizedBox(width: 4),
                _buildFilterChip("Closed", "closed"),
                const Spacer(),
                ActionChip(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: _startDate == null ? colorPrimary : Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _startDate == null ? "Date" : DateFormat('dd/MM').format(_startDate!),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _startDate == null ? colorPrimary : Colors.white),
                      ),
                    ],
                  ),
                  onPressed: _showSimpleDatePicker,
                  backgroundColor: _startDate == null ? Colors.white : colorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: colorPrimary.withAlpha(40))),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: colorPrimary))
              : RefreshIndicator(
                  onRefresh: () => _loadInitialData(showLoading: false),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(), 
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.isEmpty ? 1 : filtered.length,
                    itemBuilder: (context, index) {
                      if (filtered.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
                          child: Center(child: Text("No tickets found", style: TextStyle(color: colorSecondary, fontWeight: FontWeight.bold))),
                        );
                      }
                      return _buildTicketCard(filtered[index]);
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTicketScreen()));
          // If a ticket was added, refresh list (though real-time subscription will also catch this)
          if (result == true && mounted) _loadInitialData(showLoading: false);
        },
        backgroundColor: colorPrimary,
        foregroundColor: Colors.white,
        label: const Text("NEW TICKET"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedStatusFilter == value;
    return ChoiceChip(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      selected: isSelected,
      onSelected: (v) => setState(() => _selectedStatusFilter = value),
      selectedColor: colorPrimary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : colorPrimary),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? colorPrimary : colorPrimary.withAlpha(40))),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final cust = _customerMap[ticket.customerId];
    final mach = _machineMap[ticket.machineId];
    final displayName = cust?.name ?? "Unknown Customer";
    final machineName = mach?.name ?? "Unknown Machine";
    final String machineIdDisplay = mach != null ? "${mach.type.toLowerCase() == 'weight' ? 'W' : 'P'}-${mach.machineUid}" : "";

    Color statusColor = ticket.status.toLowerCase() == 'open' ? const Color(0xFFE67E22) : (ticket.status.toLowerCase() == 'done' ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withAlpha(10)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(10)), 
          child: Center(child: Text("#${ticket.ticketUid}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)))
        ),
        title: Text(displayName, style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("[$machineIdDisplay] $machineName: ${ticket.problem}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colorSecondary, fontSize: 11))),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("₹${ticket.cost.toInt()}", style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)), 
              child: Text(ticket.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailScreen(ticket: ticket)));
          if (result == true && mounted) _loadInitialData(showLoading: false); 
        },
      ),
    );
  }
}