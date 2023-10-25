import 'package:macsignaturepad/services/advisor_service.dart';
import 'package:macsignaturepad/services/customer_service.dart';

class InitService {
  static bool isInited = false;
  static bool isIniting = false;

  static Future init({required int id, required Function function, bool force = false}) async {
    if ((isIniting || isInited) && !force) {
      return;
    }
    isIniting = true;
    List<Future> toDo = [
      AdvisorService.initAdvisor(),
      CustomerService.initCustomers(id: id, function: function)
    ];
    await Future.wait(toDo);
    isInited = true;
    isIniting = false;
  }

  static cleanCache() {
    isInited = false;
    isIniting = false;
  }
}