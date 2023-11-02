import 'package:dio/dio.dart';
import 'package:macsignaturepad/secrets/secrets.dart';

class SMSService {
  static Future<void> sendMessage(String phone, String message) async {
    final dio = Dio();

    final String url = 'https://api.smsapi.com/sms.do';
    final String senderName = 'MAC AGENTUR';

    final response = await dio.get(
      url,
      queryParameters: {
        'from': senderName,
        'to': phone,
        'message': message,
        'format': 'json',
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $SMS_API_KEY',
        },
      ),
    );

    if (response.statusCode == 200) {
      // Erfolgreiche Anfrage
      print('SMS erfolgreich gesendet: ${response.data}');
    } else {
      // Fehler bei der Anfrage
      print('Fehler beim Senden der SMS: ${response.statusCode}');
    }
  }
}
