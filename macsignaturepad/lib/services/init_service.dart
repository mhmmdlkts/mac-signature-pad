import 'package:macsignaturepad/services/advisor_service.dart';

class InitService {
  static bool isInited = false;
  static bool isIniting = false;

  static String version = '0.99v';

  static Future init({required int id, required Function function, bool force = false}) async {
    if ((isIniting || isInited) && !force) {
      return;
    }
    isIniting = true;
    await AdvisorService.initAdvisor();
    // await CustomerService.initCustomers(id: id, function: function);
    isInited = true;
    isIniting = false;
  }

  static cleanCache() {
    isInited = false;
    isIniting = false;
  }
}