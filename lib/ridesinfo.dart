import 'dart:async';

import 'package:commut4/account_info.dart';
import 'package:commut4/ad_banner.dart';
import 'package:commut4/privacy_policy.dart';
import 'package:commut4/user_upcoming_rides.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:commut4/settings.dart';

SupabaseClient get _supabase => Supabase.instance.client;




class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  String? selectedLocation;
  String? selectedDate;

 final List<String> from = [
  'NIT Jalandhar',
  'JRC station',
  'JUC station',
  'Pap chowk',
  'Bus stand',
  'Amritsar',
  'Rama Mandi',
  'Jalandhar Cantt',
  'Phagwara Gate',
  'Mai Hiran Gate',
  'Central Town',
];

final List<String> to = [
  'NIT Jalandhar',
  'JRC station',
  'JUC station',
  'Pap chowk',
  'Bus stand',
  'Amritsar',
  'Rama Mandi',
  'Jalandhar Cantt',
  'Phagwara Gate',
  'Mai Hiran Gate',
  'Central Town',
];

  // Live data from Supabase — replaces hardcoded rideData
  List<Map<String, dynamic>> rideData = [];
  List<Map<String, dynamic>> _allRows = []; // cache of all Supabase rows
  StreamSubscription<List<Map<String, dynamic>>>? _ridesSubscription;
  int? _selectedIndex; // tracks which row is highlighted

  @override
  void initState() {
    super.initState();
    _subscribeToRides();
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    super.dispose();
  }

  // Subscribe to rides table, re-called when dropdowns change
  // Fixed 20-min time slots from 6:00 AM to 10:00 PM (I found this to be correctly spaces so i kept them at 20 mins gap)
  static List<String> get _timeSlots {
    final slots = <String>[];
    for (int h = 6; h <= 22; h++) {
      for (int m = 0; m < 60; m += 20) {
        if (h == 22 && m > 0) break;
        final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        final period = h >= 12 ? 'PM' : 'AM';
        final min = m.toString().padLeft(2, '0');
        slots.add('$hour:$min $period');
      }
    }
    return slots;
  }

  // Single persistent stream — never restarted
  void _subscribeToRides() {
    _ridesSubscription?.cancel();
    _ridesSubscription = _supabase
        .from('rides')
        .stream(primaryKey: ['ride_id'])
        .listen((List<Map<String, dynamic>> rows) {
          _allRows = rows; // cache all rows
          _applyFilter(); // filter with current dropdown values
        });
  }

  // Re-filters cached rows instantly, called on dropdown change
  void _applyFilter() {
    final filtered = _allRows.where((row) {
      final matchFrom =
          selectedLocation == null || row['from_place'] == selectedLocation;
      final matchTo = selectedDate == null || row['to_place'] == selectedDate;
      return matchFrom && matchTo;
    }).toList();

    final Map<String, Map<String, dynamic>> byTime = {
      for (final row in filtered) (row['time'] ?? ''): row,
    };

    setState(() {
      rideData = _timeSlots.map((slot) {
        final row = byTime[slot];
        return <String, dynamic>{
          'when': slot,
          'people': row?['request_count'] ?? 0,

          'ride_id': row?['ride_id'] ?? '',
        };
      }).toList();
    });
  }

  void _showRideDetails(Map<String, dynamic> ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context), // Close when tapping outside
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {}, // Prevent taps on the sheet from closing it (fixed a ui problem that i faced)
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text(
                          'Ride Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563eb),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          Icons.access_time,
                          'Time',
                          ride['when'],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.people,
                          'Active Requests',
                          '${ride['people']}',
                        ),

                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            requestRide(ride['when']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563eb),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Request Ride',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2563eb), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1a1a1a),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> requestRide(String when) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }

    try {
      final String rideId =
          'ride_${when.replaceAll(' ', '_').replaceAll(':', '_')}_${(selectedLocation ?? 'x').replaceAll(' ', '_')}_${(selectedDate ?? 'x').replaceAll(' ', '_')}';

      // Check if this ride slot already exists in Supabase
      final existing = await _supabase
          .from('rides')
          .select()
          .eq('ride_id', rideId)
          .maybeSingle();

      if (existing == null) {
        // CREATE new ride row with request_count = 1
        await _supabase.from('rides').insert({
          'ride_id': rideId,
          'from_place': selectedLocation ?? 'Not specified',
          'to_place': selectedDate ?? 'Not specified',
          'time': when,

          'request_count': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        // First person is always group 1
        await _supabase.from('ride_requests').insert({
          'ride_id': rideId,
          'uid': userId,
          'group_number': 1,
          'status': 'pending',
          'requested_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Check if user already requested this ride
        final alreadyRequested = await _supabase
            .from('ride_requests')
            .select()
            .eq('ride_id', rideId)
            .eq('uid', userId)
            .maybeSingle();

        if (alreadyRequested != null) {
          throw Exception('You already requested this ride');
        }

        // Atomic increment, DB increments and returns the unique new count
        // preventing race conditions when multiple users request simultaneously 
        final int newCount =
            await _supabase.rpc(
                  'increment_ride_count',
                  params: {'p_ride_id': rideId},
                )
                as int;

        // newCount is this user's unique position — derive group from it
        final int groupNumber = ((newCount - 1) ~/ 3) + 1;

        // INSERT ride_request with atomically derived group number
        await _supabase.from('ride_requests').insert({
          'ride_id': rideId,
          'uid': userId,
          'group_number': groupNumber,
          'status': 'pending',
          'requested_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride requested successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error requesting ride: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563eb), // Blue
      bottomNavigationBar: const AdBanner(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(Icons.menu, color: Colors.white),
            );
          },
        ),
        title: const Text(
          'Available Rides',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF2563eb)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Icon(Icons.directions_car, size: 48, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Ride Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFF2563eb)),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return RidesPage();
                      },
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.event_available,
                  color: Color(0xFF2563eb),
                ),
                title: const Text('My Upcoming Rides'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return UserUpcomingRidesPage();
                      },
                    ),
                  );
                  // left for v2
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.account_circle,
                  color: Color(0xFF2563eb),
                ),
                title: const Text('Account Info'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return AccountInfoPage();
                      },
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF2563eb)),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SettingsPage()),
);;
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF2563eb)),
                title: const Text('My Past Rides'),
                onTap: () {
                  Navigator.pop(context);
                  // left for v2
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip,
                  color: Color(0xFF2563eb),
                ),
                title: const Text('Privacy Policy'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.help_outline,
                  color: Color(0xFF2563eb),
                ),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  // left for v2
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'From',
                    value: selectedLocation,
                    items: from,
                    icon: Icons.location_on_outlined,
                    onChanged: (value) {
                      setState(() {
                        selectedLocation = value;
                        _applyFilter();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'To',
                    value: selectedDate,
                    items: to,
                    icon: Icons.calendar_today_outlined,
                    onChanged: (value) {
                      setState(() {
                        selectedDate = value;
                        _applyFilter();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            
            const Text(
              'Available Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: (selectedLocation == null || selectedDate == null)
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Please select From and To in the list',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Table Header
                          Row(
                            children: const [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'When',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF2563eb),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Active Requests',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF2563eb),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),

                          // Table Rows
                          Expanded(
                            child: ListView.separated(
                              itemCount: rideData.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final ride = rideData[index];
                                return InkWell(
                                  onTap: () {
                                    setState(() => _selectedIndex = index);
                                    _showRideDetails(ride);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    color: _selectedIndex == index
                                        ? const Color(
                                            0xFF2563eb,
                                          ).withOpacity(0.08)
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                ride['when'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF1a1a1a),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF2563eb,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${ride['people'] ?? 0}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2563eb),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF2563eb), size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            hint: Text(
              'Select $label',
              style: TextStyle(color: Colors.grey[400]),
            ),
            isExpanded: true,
            items: items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}