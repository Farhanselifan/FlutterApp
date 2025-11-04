import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient client;

  Future<void> connect({
    required String broker,
    required String topic,
    required Function(String) onMessage,
  }) async {
    client = MqttServerClient(broker, '');
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
      print('✅ Connected to MQTT broker');

      client.subscribe(topic, MqttQos.atMostOnce);

      client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
        final recMess = messages![0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        onMessage(payload);
      });
    } catch (e) {
      print('⚠️ MQTT connection error: $e');
      client.disconnect();
    }
  }

  void disconnect() {
    client.disconnect();
  }
}
