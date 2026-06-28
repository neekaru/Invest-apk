import 'package:flutter/material.dart';

IconData iconFromCodePoint(int codePoint) {
  // ignore: non_const_argument_for_const_parameter
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}
