class ItemDuration {
  ItemDuration({required this.lowerValue, required this.upperValue});

  final Duration lowerValue;
  final Duration upperValue;

  ItemDuration.fromJson(Map<String, dynamic> json)
      : lowerValue = deserializeDuration(json['unit'], json['lower value']),
        upperValue = deserializeDuration(json['unit'], json['upper value']);

  static Duration deserializeDuration(String unit, int value) {
    if(unit == "hours") {
      return Duration(hours: value);
    }
    else {
      return Duration(minutes: value);
    }
  }
}
