import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/tattoo_waitlist_cta.dart';

/// Educational FAQ screen about QR codes on tattoos.
///
/// Loads 6 FAQ entries from `assets/data/tattoo_faq.json` and renders them
/// as [ExpansionTile] items in a dark-themed list. The waitlist CTA for tattoo
/// studio partners is displayed at the bottom.
///
/// Shown when the user taps "¿Por qué?" in [TattooProfileEnforcementWidget]
/// or navigates from the tattoo product detail page.
class TattooFaqScreen extends StatefulWidget {
  const TattooFaqScreen({super.key});

  @override
  State<TattooFaqScreen> createState() => _TattooFaqScreenState();
}

class _TattooFaqScreenState extends State<TattooFaqScreen> {
  late Future<List<Map<String, dynamic>>> _faqFuture;

  @override
  void initState() {
    super.initState();
    _faqFuture = _loadFaq();
  }

  Future<List<Map<String, dynamic>>> _loadFaq() async {
    final jsonString =
        await rootBundle.loadString('assets/data/tattoo_faq.json');
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          '¿Cómo funciona el QR en tatuajes?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _faqFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00FF88),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Error al cargar el FAQ',
                style: TextStyle(color: Colors.grey[400]),
              ),
            );
          }

          final faqs = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Header badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF00CC6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QR Tattoo-Safe',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'EC-H • Módulos grandes • Logo máx 15%',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // FAQ entries as expansion tiles
              ...faqs.asMap().entries.map(
                (entry) => _FaqTile(
                  index: entry.key,
                  question: entry.value['q'] as String,
                  answer: entry.value['a'] as String,
                ),
              ),

              const SizedBox(height: 24),

              // Waitlist CTA at the bottom
              const TattooWaitlistCta(),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final int index;
  final String question;
  final String answer;

  const _FaqTile({
    required this.index,
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Theme(
        // Override the default ExpansionTile divider color
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          iconColor: const Color(0xFF00FF88),
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(
              color: Color(0xFF3A3A3A),
              height: 16,
            ),
            Text(
              answer,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
