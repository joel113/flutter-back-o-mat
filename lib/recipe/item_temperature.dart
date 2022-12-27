
class ItemTemperature {
  ItemTemperature({required this.lowerValue, required this.upperValue});

  final int lowerValue;
  final int upperValue;

  ItemTemperature.fromJson(Map<String, dynamic> json)
      : lowerValue = json['lower value'],
        upperValue = json['upper value'];
}