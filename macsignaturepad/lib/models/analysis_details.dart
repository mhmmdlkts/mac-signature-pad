import 'package:macsignaturepad/services/all_services_service.dart';

class AnalysisDetails {
  String code;
  String name;
  Map<String, bool> options;

  AnalysisDetails({
    required this.code,
    required this.name,
    this.options = const {}
  });

  factory AnalysisDetails.fromJson(Map<String, dynamic> json) {
    AnalysisDetails details = AllServicesService.getNewMapAnalysisDetails().firstWhere((element) => element.code == json['code']);
    List<String> selectedOptions = json['value'].split(', ');
    Map<String, bool> options = {};
    details.options.keys.forEach((element) {
      options[element] = selectedOptions.contains(element);
    });
    return AnalysisDetails(
      code: json['code'],
      name: json['name'],
      options: options
    );
  }

  toJson() => {
    'code': code,
    'name': name,
    'value': options.keys.where((element) => options[element]!).join(', ')
  };
}