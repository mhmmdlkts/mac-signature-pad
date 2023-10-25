import 'package:macsignaturepad/placeholders/protokoll_v1.dart';

import '../placeholders/vollmacht_v1.dart';

class PlaceholdersService {
  static Map<String, List<Map<String, dynamic>>> getPlaceholders(String file, String version) {
    if (file == 'protokoll') {
      if (version == 'v1') {
        return protokollV1;
      }
    } else if (file == 'vollmacht') {
      if (version == 'v1') {
        return vollmachtV1;
      }
    }
    return {};
  }
}