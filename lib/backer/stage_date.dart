import 'package:flutter/material.dart';

class StageDate extends StatelessWidget {
  const StageDate(this.dateTime, {Key? key}) : super(key: key);

  final DateTime? dateTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.lightBlue[100],
              borderRadius: BorderRadius.circular(20)),
          child: const Text(
            "Fr. 30. Dez. 08:02",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 24),
          ),
        )
      ],
    );
  }

}