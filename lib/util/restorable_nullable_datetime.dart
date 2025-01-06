import 'package:flutter/material.dart';

class RestorableNullableDateTime extends RestorableValue<DateTime?> {
  RestorableNullableDateTime(DateTime? value) : _defaultValue = value;

  final DateTime? _defaultValue;

  @override
  DateTime? createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(DateTime? oldValue) {
    if (oldValue == null || oldValue.millisecondsSinceEpoch != value?.millisecondsSinceEpoch) {
      notifyListeners();
    }
  }

  @override
  DateTime? fromPrimitives(Object? data) {
    if (data == null) {
      return _defaultValue;
    }
    if (data is int) {
      return DateTime.fromMillisecondsSinceEpoch(data);
    }
    return _defaultValue;
  }

  @override
  Object? toPrimitives() {
    return value?.millisecondsSinceEpoch;
  }
}