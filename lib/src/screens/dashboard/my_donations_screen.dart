import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  int _currentTab = 0;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('My Items'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color:
                          _currentTab == 0
                              ? const Color(0xFF2E7D32)
                              : Colors.transparent,
                      child: Text(
                        'My Donations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _currentTab == 0 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color:
                          _currentTab == 1
                              ? const Color(0xFF2E7D32)
                              : Colors.transparent,
                      child: Text(
                        'My Claims',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _currentTab == 1 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _currentTab == 0
                    ? _buildMyDonationsList()
                    : _buildMyClaimsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDonationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('donations')
              .where('donorId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('You haven\'t posted any donations yet.'),
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final status = data['status'] ?? 'available';
            return DonationItemCard(
              title: data['title'] ?? 'Untitled',
              status: status == 'claimed' ? 'Claimed' : 'Available',
              statusColor: status == 'claimed' ? Colors.green : Colors.orange,
              date: _formatDate(data['createdAt']),
            );
          },
        );
      },
    );
  }

  Widget _buildMyClaimsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('claims')
              .where('recipientId', isEqualTo: uid)
              .orderBy('requestedAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('You haven\'t claimed any items yet.'),
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return DonationItemCard(
              title: 'Donation: ${data['donationId'] ?? ''}',
              status: data['status'] ?? 'pending',
              statusColor:
                  (data['status'] == 'confirmed')
                      ? Colors.green
                      : Colors.orange,
              date: _formatDate(data['requestedAt']),
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'Posted ${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return 'Posted ${diff.inHours} hour(s) ago';
    return 'Posted just now';
  }
}

class DonationItemCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final String date;

  const DonationItemCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.image),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Chip(
          label: Text(status),
          backgroundColor: statusColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
      ),
    );
  }
}
