import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Row(
                children: const [
                  Icon(Icons.privacy_tip, color: Color(0xFF2563eb), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563eb),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: April 2025',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Section 1 — Data we collect
              _buildSectionTitle(Icons.person_outline, 'Information We Collect'),
              const SizedBox(height: 12),
              const Text(
                'When you create an account on AutoShare, we collect the following personal information to enable ride-sharing within your college:',
                style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a), height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildInfoTile(Icons.badge_outlined,        'Full Name',          'Used to identify you to fellow riders.'),
              _buildInfoTile(Icons.school_outlined,       'Academic Year',      'Helps verify you are a current student.'),
              _buildInfoTile(Icons.email_outlined,        'Email Address',      'Used for authentication and account recovery.'),
              _buildInfoTile(Icons.phone_outlined,        'Phone Number',       'Shared with your ride group so members can coordinate.'),
              _buildInfoTile(Icons.account_circle_outlined,'Profile Details',   'Any additional info you choose to add to your account.'),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Section 2 — Messages / Chats
              _buildSectionTitle(Icons.chat_bubble_outline, 'Messages & Chats'),
              const SizedBox(height: 12),
              const Text(
                'In-app messages and group chats between riders are stored securely on Google\'s cloud infrastructure. This allows your conversations to persist across sessions and devices. Google\'s services are governed by their own privacy and security standards.',
                style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a), height: 1.5),
              ),
              const SizedBox(height: 12),
              _buildHighlightBox(
                Icons.cloud_outlined,
                'Chats are stored on a Google cloud service to keep your conversations accessible and secure.',
              ),
              const SizedBox(height: 12),
              _buildHighlightBox(
                Icons.security_outlined,
                'Google may check your account and email address against its other services to prevent abuse and spam. This information may be retained on Google\'s side as part of their standard security practices, independently of AutoShare.',
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Section 3 — Ride details NOT stored
              _buildSectionTitle(Icons.directions_car_outlined, 'Ride Details'),
              const SizedBox(height: 12),
              const Text(
                'Ride requests and slot information are maintained only for real-time coordination. Once a ride is completed or no longer active, its details are not retained by AutoShare.',
                style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a), height: 1.5),
              ),
              const SizedBox(height: 12),
              _buildHighlightBox(
                Icons.delete_sweep_outlined,
                'We do not permanently store your ride details. No ride history is kept on our servers.',
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Section 4 — How we use your data
              _buildSectionTitle(Icons.tune_outlined, 'How We Use Your Data'),
              const SizedBox(height: 12),
              _buildBulletPoint('To match you with other riders going the same way.'),
              _buildBulletPoint('To allow group members to contact each other.'),
              _buildBulletPoint('To authenticate your account and keep it secure.'),
              _buildBulletPoint('We do not sell or share your data with third parties for marketing.'),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),

              // Section 5 — Contact
              _buildSectionTitle(Icons.help_outline, 'Questions or Concerns?'),
              const SizedBox(height: 12),
              const Text(
                'If you have any questions about how your data is handled, please reach out to us through the Help & Support section in the menu.',
                style: TextStyle(fontSize: 14, color: Color(0xFF1a1a1a), height: 1.5),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563eb), size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563eb),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a1a1a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2563eb).withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2563eb).withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563eb)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1a1a1a),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF2563eb),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1a1a1a),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}