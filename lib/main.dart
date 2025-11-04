import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trash Classification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: const TrashClassificationScreen(),
    );
  }
}

class TrashClassificationScreen extends StatefulWidget {
  const TrashClassificationScreen({Key? key}) : super(key: key);

  @override
  State<TrashClassificationScreen> createState() => _TrashClassificationScreenState();
}

class _TrashClassificationScreenState extends State<TrashClassificationScreen> {
  int bateraiCount = 0;
  int kertasCount = 0;
  int plastikCount = 0;
  
  String currentTrashType = 'Plastik';
  IconData currentIcon = Icons.eco;
  Color currentIconColor = Colors.teal;

  final List<Map<String, dynamic>> trashTypes = [
    {
      'name': 'Plastik',
      'icon': Icons.eco,
      'color': Colors.teal,
    },
    {
      'name': 'Baterai',
      'icon': Icons.battery_charging_full,
      'color': Colors.orange,
    },
    {
      'name': 'Kertas',
      'icon': Icons.article,
      'color': Colors.brown,
    },
  ];

  void classifyTrash() {
    setState(() {
      // Randomly select a trash type
      final random = Random();
      final selectedTrash = trashTypes[random.nextInt(trashTypes.length)];
      
      currentTrashType = selectedTrash['name'];
      currentIcon = selectedTrash['icon'];
      currentIconColor = selectedTrash['color'];
      
      // Increment the appropriate counter
      switch (currentTrashType) {
        case 'Plastik':
          plastikCount++;
          break;
        case 'Baterai':
          bateraiCount++;
          break;
        case 'Kertas':
          kertasCount++;
          break;
      }
    });

    // Show a snackbar with the result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terdeteksi: $currentTrashType'),
        duration: const Duration(seconds: 2),
        backgroundColor: currentIconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.recycling,
                    color: Colors.teal,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TRASH CLASSIFICATION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Plant/Trash Image
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Container(
                        key: ValueKey<String>(currentTrashType),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            currentIcon,
                            size: 120,
                            color: currentIconColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Text
                    const Text(
                      'Jenis sampah',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        currentTrashType,
                        key: ValueKey<String>(currentTrashType),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start Button
                    ElevatedButton(
                      onPressed: classifyTrash,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A67E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    const Text(
                      'History jenis sampah',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Cards
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      bateraiCount.toString(),
                      'Baterai',
                      const Color(0xFFB8E6D5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      kertasCount.toString(),
                      'Kertas',
                      const Color(0xFFE8F5B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              count,
              key: ValueKey<String>(count),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}