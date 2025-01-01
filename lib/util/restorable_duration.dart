import 'package:flutter/material.dart';

class RestorableDuration extends RestorableValue<Duration> {
  RestorableDuration(Duration value) : _defaultValue = value;

  final Duration _defaultValue;

  @override
  Duration createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(Duration? oldValue) {
    if (oldValue == null || oldValue.inMicroseconds != value.inMicroseconds) {
      notifyListeners();
    }
  }

  @override
  Duration fromPrimitives(Object? data) {
    if(data == null){
      return Duration.zero;
    }
    return Duration(milliseconds: data as int);
  }

  @override
  Object toPrimitives() {
    return value.inMilliseconds;
  }
}