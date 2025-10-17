import 'package:flutter/material.dart';
import '../widget/app_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color.fromARGB(255, 238, 7, 7).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: const AppLogo(radius: 60, iconSize: 60),
                ),
                const SizedBox(height: 24),
                Text(
                  '"Cleanliness is next to Godliness. Be the change you wish to see."',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.normal, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '✨ Achieve the "Cleaner of the Area" credit! Report and help clean a location to get exclusive Swachh-Coins! 🪙',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'From Dump to Dazzling ✨',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Community effort can transform neglected dump yards into vibrant, clean spaces for everyone to enjoy. A small step can lead to a giant leap for our environment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildBeforeAfterCard(context, 'Before', 'assets/before_clean.jpg'),
                    _buildBeforeAfterCard(context, 'After', 'assets/after_clean.jpg'),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'An initiative running under the Swachh Bharat Mission.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeAfterCard(BuildContext context, String title, String imagePath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 250.0 : 150.0;

    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          elevation: 6,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Image.asset(
            imagePath,
            height: cardWidth,
            width: cardWidth,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(height: cardWidth, width: cardWidth, color: Colors.grey[800], child: const Icon(Icons.broken_image, size: 50));
            },
          ),
        ),
      ],
    );
  }
}
