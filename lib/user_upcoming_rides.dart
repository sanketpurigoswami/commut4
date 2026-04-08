import 'dart:async';

import 'package:commut4/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

SupabaseClient get _supabase => Supabase.instance.client;

class UserUpcomingRidesPage extends StatefulWidget {
  const UserUpcomingRidesPage({super.key});

  @override
  State<UserUpcomingRidesPage> createState() => _UserUpcomingRidesPageState();
}

class _UserUpcomingRidesPageState extends State<UserUpcomingRidesPage> {
  // each entry = joined ride_requests + rides data for this user (i will input more details later in v2)
  List<Map<String, dynamic>> _upcomingRides = [];
  StreamSubscription? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeToUpcomingRides();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToUpcomingRides() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // stream ride_requests for this user, then join rides data client side (i will input more details later in v2)
    _subscription = _supabase
        .from('ride_requests')
        .stream(primaryKey: ['id'])
        .eq('uid', uid)
        .listen((List<Map<String, dynamic>> requests) async {
          if (requests.isEmpty) {
            setState(() {
              _upcomingRides = [];
              _isLoading = false;
            });
            return;
          }

          // fetch full ride details for each ride_id
          final rideIds = requests.map((r) => r['ride_id']).toList();
          final rides = await _supabase
              .from('rides')
              .select()
              .inFilter('ride_id', rideIds);

          // build lookup map ride_id → ride row
          final Map<String, Map<String, dynamic>> ridesMap = {
            for (final r in rides) r['ride_id'] as String: r,
          };

          // merge request + ride data into one object per entry
          final merged = requests.map((req) {
            final ride = ridesMap[req['ride_id']] ?? {};
            return {
              'ride_id':      req['ride_id'],
              'time':         ride['time'] ?? '—',
              'from_place':   ride['from_place'] ?? '—',
              'to_place':     ride['to_place'] ?? '—',
              
              'group_number': req['group_number'] ?? 1,
              'status':       req['status'] ?? 'pending',
              'requested_at': req['requested_at'] ?? '',
              'request_count': ride['request_count'] ?? 0,
            };
          }).toList();

          // sort by time (earliest first)
          merged.sort((a, b) =>
              (a['requested_at'] as String).compareTo(b['requested_at'] as String));

          setState(() {
            _upcomingRides = merged;
            _isLoading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563eb),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Upcoming Rides',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _upcomingRides.isEmpty
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_upcomingRides.length} ride${_upcomingRides.length == 1 ? '' : 's'} booked',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             
                              Row(
                                children: const [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF2563eb),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Route',
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
                                      'Group',
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
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _upcomingRides.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final ride = _upcomingRides[index];
                                    return InkWell(
                                      onTap: () => _showRideDetail(ride),
                                      child: Container(
                                        color: const Color(0xFF00C97A)
                                            .withOpacity(0.08),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        child: Row(
                                          children: [
                                            // Time
                                            Expanded(
                                              flex: 2,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.access_time,
                                                      size: 15,
                                                      color: Colors.grey[500]),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    ride['time'],
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF1a1a1a),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Route
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                '${ride['from_place']} → ${ride['to_place']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            /* 
                                            !!!!!
                                            
                                            group number badge (respected viewers, this is super 
                                            important for the logic to work correctly in the later stage of the app )
                                            
                                            !!!!!
                                            
                                            */
                                            Expanded(
                                              flex: 1,
                                              child: Center(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                            0xFF00C97A)
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    'G${ride['group_number']}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF00A862),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 64, color: Colors.white.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No upcoming rides',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your booked rides will appear here.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showRideDetail(Map<String, dynamic> ride) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    // fetch all members in this user's group from ride_requests
    final groupMembers = await _supabase
        .from('ride_requests')
        .select('uid, requested_at')
        .eq('ride_id', ride['ride_id'])
        .eq('group_number', ride['group_number'])
        .order('requested_at', ascending: true);

    // fetch name, year, branch from Firestore: users/{uid}
    final Map<String, Map<String, dynamic>> usersMap = {};
    for (final m in groupMembers) {
      final uid = m['uid'] as String;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        usersMap[uid] = doc.data() ?? {};
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563eb),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _detailRow(Icons.access_time,   'Time',         ride['time']),
                    const SizedBox(height: 14),
                    _detailRow(Icons.my_location,   'From',         ride['from_place']),
                    const SizedBox(height: 14),
                    _detailRow(Icons.location_on,   'To',           ride['to_place']),
                   
                    const SizedBox(height: 14),
                    _detailRow(Icons.group,         'Your Group',   'Group ${ride['group_number']}'),
                    const SizedBox(height: 14),
                    _detailRow(Icons.people_outline,'People in Your Group', '${groupMembers.length} / 3'),
                    const SizedBox(height: 14),
                    _detailRow(Icons.check_circle_outline, 'Status', groupMembers.length >= 3 ? 'CONFIRMED' : (ride['status'] as String).toUpperCase()),

                    // Group members — always shown below status
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Group Members',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563eb),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (groupMembers.length < 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Waiting for ${3 - groupMembers.length} more',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // One card per group member
                    ...groupMembers.asMap().entries.map((entry) {
                      final index  = entry.key;
                      final member = entry.value;
                      final isMe    = member['uid'] == currentUid;
                      final uid     = member['uid'] as String;
                      final info    = usersMap[uid];
                      final fullName = info?['googleDisplayName'] as String? ?? '';
                      final firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'Unknown';
                      final year    = info?['year']?.toString() ?? '—';
                      final branch  = info?['branch'] as String? ?? '—';
                      final label   = isMe ? 'You ($firstName)' : firstName;
                      final sub     = '$branch • Year $year';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF00C97A).withOpacity(0.08)
                              : const Color(0xFF2563eb).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMe
                                ? const Color(0xFF00C97A).withOpacity(0.3)
                                : const Color(0xFF2563eb).withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF00C97A).withOpacity(0.15)
                                    : const Color(0xFF2563eb).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: isMe
                                    ? const Color(0xFF00A862)
                                    : const Color(0xFF2563eb),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isMe
                                          ? const Color(0xFF00A862)
                                          : const Color(0xFF1a1a1a),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sub,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe)
                              const Icon(Icons.star, size: 14, color: Color(0xFF00A862)),
                          ],
                        ),
                      );
                    }).toList(),

                    // Empty slots if group not full yet
                    ...List.generate(3 - groupMembers.length, (i) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person_outline,
                                  color: Colors.grey[400], size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Waiting...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Open Group Chat button
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {return ChatPage(
                                rideId: ride['ride_id'],
                                groupNumber: ride['group_number'],
                              );}
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text(
                          'Open Group Chat',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563eb),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel Ride button
                    const SizedBox(height: 0),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Ride'),
                              content: const Text('Are you sure you want to cancel this ride request?'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Yes, Cancel'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          final rideId = ride['ride_id'] as String;

                          // Delete user's row from ride_requests
                          await _supabase
                              .from('ride_requests')
                              .delete()
                              .eq('ride_id', rideId)
                              .eq('uid', uid!);

                          // Decrement request_count in rides
                          final currentCount = (ride['request_count'] as int?) ?? 1;
                          if (currentCount <= 1) {
                            // Last person — delete the ride row entirely
                            await _supabase
                                .from('rides')
                                .delete()
                                .eq('ride_id', rideId);
                          } else {
                            await _supabase
                                .from('rides')
                                .update({'request_count': currentCount - 1})
                                .eq('ride_id', rideId);
                          }

                          if (mounted) {
                            Navigator.pop(context); // close modal
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ride cancelled successfully.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text(
                          'Cancel Ride',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2563eb), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1a1a1a),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}