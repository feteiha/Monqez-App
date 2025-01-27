import 'package:monqez_app/Screens/InstructionsScreens/ImageController.dart';
import 'Pair.dart';

class Injury {
  Pair _title;
  List<Pair> _instructions;

  Injury(ImageController image, String caption) {
    _title = new Pair(image, caption);
    _instructions = [];
  }

  void addStep (ImageController image, String caption) {
    _instructions.add(Pair(image, caption));
  }

  Pair getTitle () {
    return _title;
  }

  void setInstructions(List<Pair> instructions) {
    _instructions = instructions;
  }

  List<Pair> getInstructions() {
    return _instructions;
  }

  Map<String, dynamic> getJson() {
    List<Map> instructionsMap = [];
    for (Pair p in _instructions) {
      instructionsMap.add(p.getJson());
    }
    Map<String, dynamic> injuryMap = {
      "Title": _title.getCaption(),
      "Thumbnail": _title.getImage().base_64,
      "instructions": instructionsMap
    };
    return injuryMap;
  }
}