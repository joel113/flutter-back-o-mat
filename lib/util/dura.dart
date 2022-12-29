class Dura {
  static String stringify(Duration value) {
    if(value.inHours > 1) {
      return "${value.inHours} Stunden";
    }
    if(value.inHours == 1) {
      return "${value.inHours} Stunde";
    }
    if(value.inMinutes > 1) {
      return "${value.inHours} Minuten";
    }
    else {
      return "${value.inMinutes} Minute";
    }
  }
  static String stringifyNoUnit(Duration value) {
    if(value.inHours > 0) {
      return "${value.inHours}";
    }
    else {
      return "${value.inMinutes}";
    }
  }
}