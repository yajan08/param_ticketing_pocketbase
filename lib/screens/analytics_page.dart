import 'package:flutter/material.dart';
import 'package:param_ticketing/utils/my_textfield.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';
import 'package:pocketbase/pocketbase.dart';
import '../pb.dart'; // Ensure this points to your PocketBase instance

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Palette
  final Color colorBackground = const Color(0xFFF6EAD4);
  final Color colorPrimary = const Color(0xFF6B705C);
  final Color colorSecondary = const Color(0xFFA2A595);
  final Color colorTextDark = const Color(0xFF3F4238);

  // Analytics Variables
  final List<String> _predefinedIssues = const [
    'Battery', 'Wire', 'Display', 'PCB', 'FRC', 'LED', 'Switch', 'Transformer', 'Loadcell'
  ];
  
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final int _businessStartYear = 2024;
  final List<String> _months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  late Future<List<Ticket>> _ticketsFuture;

  // --- BAN SYSTEM STATE ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  List<RecordModel> _bannedUsers = [];
  bool _isBanning = false;

  List<int> get _dynamicYears {
    int currentYear = DateTime.now().year;
    return List.generate((currentYear - _businessStartYear) + 1, (index) => currentYear - index);
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
    _initBanSystem();
  }

  @override
  void dispose() {
    // Unsubscribe from real-time changes
    pb.collection('banned_users').unsubscribe('*');
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // --- BAN SYSTEM LOGIC ---

  void _initBanSystem() async {
    _fetchBannedUsers();
    
    // Real-time subscription as per PocketBase docs
    await pb.collection('banned_users').subscribe('*', (e) {
      if (mounted) {
        _fetchBannedUsers(); // Refresh list on create/update/delete
      }
    });
  }

  Future<void> _fetchBannedUsers() async {
    try {
      final records = await pb.collection('banned_users').getFullList(sort: '-created');
      if (mounted) setState(() => _bannedUsers = records);
    } catch (e) {
      debugPrint("Error fetching banned users: $e");
    }
  }

  Future<void> _submitBan() async {
    final email = _emailController.text.trim();
    final reason = _reasonController.text.trim();

    if (email.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter email and reason")));
      return;
    }

    setState(() => _isBanning = true);
    try {
      await pb.collection('banned_users').create(body: {
        'email': email,
        'reason': reason,
      });
      _emailController.clear();
      _reasonController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isBanning = false);
    }
  }

  Future<void> _unbanUser(String recordId) async {
    try {
      await pb.collection('banned_users').delete(recordId);
    } catch (e) {
      debugPrint("Unban error: $e");
    }
  }

  // --- EXISTING ANALYTICS LOGIC ---

  void _refreshData() {
    setState(() {
      _ticketsFuture = TicketService.getTickets();
    });
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Period", style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _dynamicYears.map((year) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text("$year"),
                      selected: _selectedYear == year,
                      onSelected: (val) => setModalState(() => _selectedYear = year),
                    ),
                  )).toList(),
                ),
              ),
              const Divider(height: 30),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: List.generate(12, (index) {
                  return ChoiceChip(
                    label: Text(_months[index]),
                    selected: _selectedMonth == index + 1,
                    onSelected: (val) {
                      setState(() => _selectedMonth = index + 1);
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: const Text("A N A L Y T I C S", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorTextDark,
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final tickets = snapshot.data ?? [];
          
          double lifetimeRevenue = 0;
          double filteredPeriodRevenue = 0;
          double prevPeriodRevenue = 0;
          Map<String, int> issueFrequency = { for (var item in _predefinedIssues) item : 0 };

          int prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
          int prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;

          for (var t in tickets) {
            lifetimeRevenue += t.cost;
            bool isInPeriod = t.created.month == _selectedMonth && t.created.year == _selectedYear;
            bool isPrevPeriod = t.created.month == prevMonth && t.created.year == prevYear;

            if (isInPeriod) filteredPeriodRevenue += t.cost;
            if (isPrevPeriod) prevPeriodRevenue += t.cost;

            for (var target in _predefinedIssues) {
              if (t.problem.toLowerCase().contains(target.toLowerCase())) {
                issueFrequency[target] = (issueFrequency[target] ?? 0) + 1;
              }
            }
          }

          double trendPercent = prevPeriodRevenue > 0 ? ((filteredPeriodRevenue - prevPeriodRevenue) / prevPeriodRevenue) * 100 : 0;
          var sortedIssues = issueFrequency.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("REVENUE OVERVIEW"),
                  Row(
                    children: [
                      _buildStatCard("Lifetime Rev.", "₹${lifetimeRevenue.toInt()}", Icons.account_balance_wallet, null),
                      const SizedBox(width: 12),
                      _buildStatCard("${_months[_selectedMonth - 1]} '$_selectedYear", "₹${filteredPeriodRevenue.toInt()}", Icons.calendar_month, _showPeriodPicker, trend: trendPercent),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _buildSectionTitle("COMPONENT FAILURE FREQUENCY"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(15), 
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5)]
                    ),
                    child: sortedIssues.isEmpty 
                      ? const Text("No predefined failures tracked yet.", style: TextStyle(fontSize: 12, color: Colors.grey)) 
                      : Column(
                          children: sortedIssues.map((e) {
                            double percent = tickets.isEmpty ? 0 : e.value / tickets.length;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e.key, style: TextStyle(color: colorTextDark, fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text("${e.value} Tickets", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      backgroundColor: colorBackground,
                                      color: colorPrimary,
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  ),

                  const SizedBox(height: 25),

                  // --- NEW BAN MANAGEMENT SECTION ---
                  _buildSectionTitle("USER RESTRICTIONS"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5)]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ban User",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 12),
                        
                        // Email Field using custom MyTextField
                        MyTextField(
                          controller: _emailController,
                          hintText: "User Email",
                          obscureText: false,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Reason Field using custom MyTextField
                        MyTextField(
                          controller: _reasonController,
                          hintText: "Reason",
                          obscureText: false,
                          keyboardType: TextInputType.text,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isBanning ? null : _submitBan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withAlpha(200),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isBanning
                                ? const SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text("ADD TO BAN LIST",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        
                        const Divider(height: 30),
                        const Text("Restricted Emails",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 10),
                        

                        if (_bannedUsers.isEmpty)
                          const Text("No users currently banned.",
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                              
                        ..._bannedUsers.map((record) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(record.getStringValue('email'),
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: Text(record.getStringValue('reason'),
                                  style: const TextStyle(fontSize: 11)),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.blue, size: 20),
                                onPressed: () => _unbanUser(record.id),
                              ),
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(title, style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, VoidCallback? onTap, {double? trend}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colorPrimary, borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white.withAlpha(128), size: 20),
                  if (trend != null && trend != 0) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: (trend > 0 ? Colors.greenAccent : Colors.redAccent).withAlpha(51), borderRadius: BorderRadius.circular(5)),
                      child: Text("${trend > 0 ? '+' : ''}${trend.toInt()}%", style: TextStyle(color: trend > 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              Text(title, style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import '../models/ticket_model.dart';
// import '../services/ticket_service.dart';

// class AnalyticsPage extends StatefulWidget {
//   const AnalyticsPage({super.key});

//   @override
//   State<AnalyticsPage> createState() => _AnalyticsPageState();
// }

// class _AnalyticsPageState extends State<AnalyticsPage> {
//   // Palette
//   final Color colorBackground = const Color(0xFFF6EAD4);
//   final Color colorPrimary = const Color(0xFF6B705C);
//   final Color colorSecondary = const Color(0xFFA2A595);
//   final Color colorTextDark = const Color(0xFF3F4238);

//   // Analytics Variables
//   final List<String> _predefinedIssues = const [
//     'Battery', 'Wire', 'Display', 'PCB', 'FRC', 'LED', 'Switch', 'Transformer', 'Loadcell'
//   ];
  
//   int _selectedMonth = DateTime.now().month;
//   int _selectedYear = DateTime.now().year;
//   final int _businessStartYear = 2024;
//   final List<String> _months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

//   late Future<List<Ticket>> _ticketsFuture;

//   List<int> get _dynamicYears {
//     int currentYear = DateTime.now().year;
//     return List.generate((currentYear - _businessStartYear) + 1, (index) => currentYear - index);
//   }

//   @override
//   void initState() {
//     super.initState();
//     _refreshData();
//   }

//   void _refreshData() {
//     setState(() {
//       _ticketsFuture = TicketService.getTickets();
//     });
//   }

//   void _showPeriodPicker() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: colorBackground,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text("Select Period", style: TextStyle(color: colorTextDark, fontWeight: FontWeight.bold, fontSize: 16)),
//               const SizedBox(height: 20),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: _dynamicYears.map((year) => Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4),
//                     child: ChoiceChip(
//                       label: Text("$year"),
//                       selected: _selectedYear == year,
//                       onSelected: (val) => setModalState(() => _selectedYear = year),
//                     ),
//                   )).toList(),
//                 ),
//               ),
//               const Divider(height: 30),
//               Wrap(
//                 spacing: 8, runSpacing: 8,
//                 children: List.generate(12, (index) {
//                   return ChoiceChip(
//                     label: Text(_months[index]),
//                     selected: _selectedMonth == index + 1,
//                     onSelected: (val) {
//                       setState(() => _selectedMonth = index + 1);
//                       Navigator.pop(context);
//                     },
//                   );
//                 }),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: colorBackground,
//       appBar: AppBar(
//         title: const Text("A N A L Y T I C S", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2)),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: colorTextDark,
//       ),
//       body: FutureBuilder<List<Ticket>>(
//         future: _ticketsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

//           final tickets = snapshot.data ?? [];
          
//           double lifetimeRevenue = 0;
//           double filteredPeriodRevenue = 0;
//           double prevPeriodRevenue = 0;
//           Map<String, int> issueFrequency = { for (var item in _predefinedIssues) item : 0 };

//           int prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
//           int prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;

//           for (var t in tickets) {
//             lifetimeRevenue += t.cost;
//             bool isInPeriod = t.created.month == _selectedMonth && t.created.year == _selectedYear;
//             bool isPrevPeriod = t.created.month == prevMonth && t.created.year == prevYear;

//             if (isInPeriod) filteredPeriodRevenue += t.cost;
//             if (isPrevPeriod) prevPeriodRevenue += t.cost;

//             for (var target in _predefinedIssues) {
//               if (t.problem.toLowerCase().contains(target.toLowerCase())) {
//                 issueFrequency[target] = (issueFrequency[target] ?? 0) + 1;
//               }
//             }
//           }

//           double trendPercent = prevPeriodRevenue > 0 ? ((filteredPeriodRevenue - prevPeriodRevenue) / prevPeriodRevenue) * 100 : 0;
//           var sortedIssues = issueFrequency.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));

//           return RefreshIndicator(
//             onRefresh: () async => _refreshData(),
//             child: SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSectionTitle("REVENUE OVERVIEW"),
//                   Row(
//                     children: [
//                       _buildStatCard("Lifetime Rev.", "₹${lifetimeRevenue.toInt()}", Icons.account_balance_wallet, null),
//                       const SizedBox(width: 12),
//                       _buildStatCard("${_months[_selectedMonth - 1]} '$_selectedYear", "₹${filteredPeriodRevenue.toInt()}", Icons.calendar_month, _showPeriodPicker, trend: trendPercent),
//                     ],
//                   ),

//                   const SizedBox(height: 25),
//                   // Replace your existing Container for COMPONENT FAILURE FREQUENCY with this:

//                     _buildSectionTitle("COMPONENT FAILURE FREQUENCY"),
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.white, 
//                         borderRadius: BorderRadius.circular(15), 
//                         boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 5)]
//                       ),
//                       child: sortedIssues.isEmpty 
//                         ? const Text("No predefined failures tracked yet.", style: TextStyle(fontSize: 12, color: Colors.grey)) 
//                         : Column(
//                             children: sortedIssues.map((e) {
//                               // Calculate percentage for a small visual bar
//                               double percent = tickets.isEmpty ? 0 : e.value / tickets.length;
                              
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 10.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Text(e.key, style: TextStyle(color: colorTextDark, fontWeight: FontWeight.w600, fontSize: 13)),
//                                         Text("${e.value} Tickets", style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 6),
//                                     // Visual progress bar
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(10),
//                                       child: LinearProgressIndicator(
//                                         value: percent,
//                                         backgroundColor: colorBackground,
//                                         color: colorPrimary,
//                                         minHeight: 6,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                     ),
//                   const SizedBox(height: 50),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10, left: 4),
//       child: Text(title, style: TextStyle(color: colorPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, VoidCallback? onTap, {double? trend}) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(color: colorPrimary, borderRadius: BorderRadius.circular(15)),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Icon(icon, color: Colors.white.withAlpha(128), size: 20),
//                   if (trend != null && trend != 0) 
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                       decoration: BoxDecoration(color: (trend > 0 ? Colors.greenAccent : Colors.redAccent).withAlpha(51), borderRadius: BorderRadius.circular(5)),
//                       child: Text("${trend > 0 ? '+' : ''}${trend.toInt()}%", style: TextStyle(color: trend > 0 ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               FittedBox(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
//               Text(title, style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 10)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }