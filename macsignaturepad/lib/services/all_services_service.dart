import 'package:macsignaturepad/models/service_details.dart';

class AllServicesService {
  static Map<String, List<ServiceDetails>> getNewMap() => {
    'Für mich und meine Familie': [
      ServiceDetails(code: 'fam-ableb', name: 'Ablebensvorsoge'),
      ServiceDetails(code: 'fam-alter', name: 'Alters-/Pensionsvorsoge'),
      ServiceDetails(code: 'fam-krang', name: 'Krankenvorsorge'),
      ServiceDetails(code: 'fam-unfal', name: 'Unfallvorsorge'),
      ServiceDetails(code: 'fam-beruf', name: 'Berufsunfähigkeitsvorsoge'),
      ServiceDetails(code: 'fam-recht', name: 'Rechtsschutz'),
      ServiceDetails(code: 'fam-priva', name: 'Privathaftpflicht'),
      ServiceDetails(code: 'fam-behaf', name: 'Berufshaftung'),
      ServiceDetails(code: 'fam-veran', name: 'Veranlagung'),
      ServiceDetails(code: 'fam-fenan', name: 'Finanzierung'),
    ],
    'Für meine Kraftfahrzeug': [
      ServiceDetails(code: 'kfz-haftp', name: 'KFZ- Haftpflicht'),
      ServiceDetails(code: 'kfz-vollk', name: 'KFZ- Vollkasko'),
      ServiceDetails(code: 'kfz-teilk', name: 'KFZ- Teilkasko'),
      ServiceDetails(code: 'kfz-wildw', name: 'KFZ- Wild &Wetter Kasko'),
      ServiceDetails(code: 'kfz-insas', name: 'KFZ- Insassenunfall'),
      ServiceDetails(code: 'kfz-recht', name: 'KFZ- Rechtschutz'),
    ],
    'Für mein Haus / meine Wohnung / mein Eigentum / mein Grundstück': [
      ServiceDetails(code: 'woh-wohng', name: 'Wohngebäude'),
      ServiceDetails(code: 'woh-haush', name: 'Haushalt / Inventar'),
      ServiceDetails(code: 'woh-grobe', name: 'Grober Fahrlässigkeit'),
      ServiceDetails(code: 'woh-werts', name: 'Wertsachen / wie Schmuck Petze, etc'),
      ServiceDetails(code: 'woh-tierh', name: 'Tierhalterhaftplicht'),
      ServiceDetails(code: 'woh-unbeb', name: 'Unbebaute Grundstücke'),
      ServiceDetails(code: 'woh-schlu', name: 'Schlüsselverlust'),
      ServiceDetails(code: 'woh-sonst', name: 'Sonstiges / Betrieb'),
    ],
  };
}