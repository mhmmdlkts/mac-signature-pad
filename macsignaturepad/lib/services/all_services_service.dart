import 'package:macsignaturepad/models/analysis_details.dart';
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
    'Gewerbliche- und BU-Risiken': [
      ServiceDetails(code: 'bau-cyber', name: 'Gewerberisiken & Cyberversicherung'),
      ServiceDetails(code: 'bau-betri', name: 'Betriebsunterbrechung'),
      ServiceDetails(code: 'bau-vermö', name: 'Vermögungsaufbau'),
      ServiceDetails(code: 'bau-enkel', name: 'Vorsorge für Kinder und Enkel'),
      ServiceDetails(code: 'bau-begra', name: 'Begräbniskostenvorsorge'),
    ],
  };

  static List<AnalysisDetails> getNewMapAnalysisDetails() => [
    AnalysisDetails(
      code: 'analy-sie',
      name: 'Sind Sie',
      options: {
        'ArbeiterIn': false,
        'Angestellte/r': false,
        'Beamtin/er': false,
        'Hausfrau/mann': false,
        'PensionistIn': false,
        'LandwirtIn': false,
        'in Karent': false,
        'Lehrling': false,
        'SchülerIn/StudentIn': false,
        'UnternehmerIn': false,
        'arbeitssuchend': false,
        'sonstiges': false,
      }
    ),
    AnalysisDetails(
      code: 'analy-derzeit',
      name: 'Wie leben Sie derzeit',
      options: {
        'als Single': false,
        'in einer Partnerschaft': false,
        'in einer Wohngemeinschaft': false,
        'sonstiges': false,
        'keine Angabe': false
      }
    ),
    AnalysisDetails(
      code: 'analy-unter',
      name: 'Sind Sie unterhaltspflichtig',
      options: {
        'ja': false,
        'nein': false,
        'keine Angabe': false
      }
    ),
    AnalysisDetails(
      code: 'analy-bestehen',
      name: 'Bestehen aktuell finanzielle Verpflichtungen',
      options: {
        'Kredit': false,
        'Leasing': false,
        'keine': false,
        'sonstiges': false,
        'keine Angabe': false,
      }
    ),
    AnalysisDetails(
      code: 'analy-netto',
      name: 'Wie hoch ist ca. Ihr monatliches netto Haushaltseinkommen',
      options: {
        '< EUR 1000': false,
        '>= EUR 1000 bis <= EUR 2000': false,
        '> EUR 2000 bis <= EUR 3000': false,
        '> EUR 3000': false,
        'keine Angabe': false
      }
    ),
    AnalysisDetails(
      code: 'analy-wohnsi',
      name: 'Wie ist Ihre derzeitige Wohnsituation',
      options: {
        'Haus': false,
        'Wohnung': false,
        'Sonstiges': false
      }
    ),
    AnalysisDetails(
      code: 'analy-immo',
      name: 'Befinden sich Immobilien in Ihrem Eigentum',
      options: {
        'ja': false,
        'nein': false,
        'keine Angabe': false
      }
    ),
    AnalysisDetails(
      code: 'analy-vertra',
      name: 'Schließen Sie Verträge ab bei welchen es zu rechtlichen Auseinandersetzungen kommen könnte',
      options: {
        'ja': false,
        'nein': false
      }
    ),
    AnalysisDetails(
      code: 'analy-involvi',
      name: 'Sehen Sie die Möglichkeit in einen Rechtsstreit involviert zu werden',
      options: {
        'ja': false,
        'nein': false
      }
    ),
    AnalysisDetails(
      code: 'analy-leben',
      name: 'Sehen Sie die Möglichkeit, dass für Sie aus den Gefahren des täglichen Lebens eine Haftung entsteht',
      options: {
        'ja': false,
        'nein': false
      }
    ),
    AnalysisDetails(
      code: 'analy-fahrze',
      name: 'Welche Fahrzeuge nützen oder besitzen Sie',
      options: {
        'PKW & LKW < 1,5t': false,
        'LKW < 1,5t': false,
        'Motorrad': false,
        'E-Bike': false,
        'Fahrrad': false,
        'sonstiges': false,
        'keines': false,
      }
    ),
    AnalysisDetails(
      code: 'analy-angewi',
      name: 'Sind Sie auf Ihr Fahrzeug angewiesen',
      options: {
        'ja': false,
        'nein': false,
        'keines vorhanden': false
      }
    ),
    AnalysisDetails(
      code: 'analy-sport',
      name: 'Betreiben Sie Sport',
      options: {
        'nie': false,
        'gelegentlich': false,
        'regelmäßig': false,
        'extrem': false
      }
    ),
    AnalysisDetails(
      code: 'analy-unfall',
      name: 'Sehen Sie für sich die Gefahr einen Unfall zu erleiden',
      options: {
        'ja': false,
        'nein': false
      }
    ),
    AnalysisDetails(
      code: 'analy-schwer',
      name: 'Fühlen Sie sich ausreichend vor den finanziellen Folgen von schweren Unfällen abgesichert',
      options: {
        'ja': false,
        'nein': false
      }
    ),
  ];
}