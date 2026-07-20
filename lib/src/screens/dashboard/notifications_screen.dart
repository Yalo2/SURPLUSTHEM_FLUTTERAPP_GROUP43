import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Notifications'),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(fontSize: 18)),
                  Text(
                    'You will see updates here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: isRead ? Colors.grey : const Color(0xFF2E7D32),
                  ),
                  title: Text(data['title'] ?? 'Notification'),
                  subtitle: Text(data['body'] ?? ''),
                  trailing: Text(
                    _timeAgo(data['createdAt']),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return '${difference.inMinutes}m ago';
  }
}
