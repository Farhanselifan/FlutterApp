import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:developer' as developer;

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
  State<TrashClassificationScreen> createState() =>
      _TrashClassificationScreenState();
}

class _TrashClassificationScreenState extends State<TrashClassificationScreen> {
  MqttServerClient? client;
  String connectionStatus = '🔌 Not Connected';
  bool isConnecting = false;
  String detectedType = 'Menunggu data...';

  int bateraiCount = 0;
  int kertasCount = 0;
  int plastikCount = 0;

  String currentTrashType = 'Menunggu data...';
  IconData currentIcon = Icons.hourglass_empty;
  Color currentIconColor = Colors.grey;

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

  // ===================== MQTT SETUP =====================
  Future<void> connectToMQTT() async {
    if (isConnecting) return; // prevent double tap
    
    setState(() {
      isConnecting = true;
      connectionStatus = '⏳ Connecting...';
    });

    try {
      client = MqttServerClient('test.mosquitto.org', '');
      client!.port = 1883;
      client!.logging(on: false);
      client!.keepAlivePeriod = 20;
      client!.autoReconnect = true;

      client!.onConnected = () {
        setState(() {
          connectionStatus = '✅ Connected to MQTT';
          isConnecting = false;
        });
        print('✅ MQTT Connected');
      };

      client!.onDisconnected = () {
        setState(() {
          connectionStatus = '❌ Disconnected';
          isConnecting = false;
        });
        print('❌ MQTT Disconnected');
      };

      client!.onSubscribed = (String topic) {
        print('📡 Subscribed to: $topic');
      };

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(
              'flutter_client_${DateTime.now().millisecondsSinceEpoch}')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      client!.connectionMessage = connMessage;

      await client!.connect();

      if (client!.connectionStatus?.state == MqttConnectionState.connected) {
        setState(() {
          connectionStatus = '✅ Connected to MQTT';
          isConnecting = false;
        });

        // Subscribe to topic
        client!.subscribe('smartbin/detection', MqttQos.atMostOnce);

        // Listen for messages
        client!.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
          final recMess = c![0].payload as MqttPublishMessage;
          final message =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          setState(() {
            detectedType = message;
            updateFromIoT(message);
          });

          print('📩 Message received: $message');
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Terhubung ke MQTT broker'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Connection failed');
      }
    } catch (e) {
      setState(() {
        connectionStatus = '⚠️ Connection failed';
        isConnecting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal terhubung: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      client?.disconnect();
      print('❌ MQTT Connection error: $e');
    }
  }

  // Update UI when MQTT message received
  void updateFromIoT(String message) {
    final trash = trashTypes.firstWhere(
      (t) => t['name'].toLowerCase() == message.trim().toLowerCase(),
      orElse: () => {
        'name': 'Tidak dikenali',
        'icon': Icons.help_outline,
        'color': Colors.grey,
      },
    );

    setState(() {
      currentTrashType = trash['name'];
      currentIcon = trash['icon'];
      currentIconColor = trash['color'];

      String normalizedMessage = message.trim().toLowerCase();
      
      if (normalizedMessage == 'baterai') {
        bateraiCount++;
      } else if (normalizedMessage == 'kertas') {
        kertasCount++;
      } else if (normalizedMessage == 'plastik') {
        plastikCount++;
      }
    });

    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terdeteksi: ${trash['name']}'),
          duration: const Duration(seconds: 2),
          backgroundColor: trash['color'],
        ),
      );
    }
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.recycling, color: Colors.teal, size: 32),
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
                  ElevatedButton(
                    onPressed: isConnecting ? null : connectToMQTT,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnecting 
                          ? Colors.grey 
                          : (connectionStatus.contains('Connected') 
                              ? Colors.green 
                              : Colors.blueAccent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isConnecting ? 'Connecting...' : 'Connect',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // CONNECTION STATUS
            Text(
              connectionStatus,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // MAIN CONTENT
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
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
                    const Text(
                      'Jenis sampah',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
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
                  ],
                ),
              ),
            ),

            // STATISTICS
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      bateraiCount.toString(),
                      'Baterai',
                      const Color(0xFFB8E6D5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      kertasCount.toString(),
                      'Kertas',
                      const Color(0xFFE8F5B8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      plastikCount.toString(),
                      'Plastik',
                      const Color(0xFFE0F7FA),
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

  Widget _buildStatCard(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
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
              key: ValueKey<String>(count + label),
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
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}