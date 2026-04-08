import 'package:commut4/ridesinfo.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenderSelectionPage extends StatefulWidget {
  const GenderSelectionPage({super.key});

  @override
  State<GenderSelectionPage> createState() => _GenderSelectionPageState();
}

class _GenderSelectionPageState extends State<GenderSelectionPage> {
  String? _selected;
  bool _saving = false;

  final List<_GenderOption> _options = const [
    _GenderOption(label: 'Male',              icon: Icons.male_rounded),
    _GenderOption(label: 'Female',            icon: Icons.female_rounded),
    _GenderOption(label: 'Prefer not to say', icon: Icons.person_outline_rounded),
  ];

  Future<void> _save() async {
    if (_selected == null) return;

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'gender': _selected});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RidesPage()),
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2563eb),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),

              // Header
              const Text(
                'One last thing.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'How do you identify? This helps us\nbuild safer ride groups.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 1),

              // Options
              ..._options.map((option) => _buildTile(option)),

              const Spacer(flex: 2),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selected == null || _saving) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563eb),
                    disabledBackgroundColor: Colors.white30,
                    disabledForegroundColor: Colors.white60,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF2563eb),
                          ),
                        )
                      : const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(_GenderOption option) {
    final bool isSelected = _selected == option.label;

    return GestureDetector(
      onTap: () => setState(() => _selected = option.label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected ? const Color(0xFF2563eb) : Colors.white,
              size: 26,
            ),
            const SizedBox(width: 16),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF2563eb) : Colors.white,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2563eb),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _GenderOption {
  final String label;
  final IconData icon;
  const _GenderOption({required this.label, required this.icon});
}