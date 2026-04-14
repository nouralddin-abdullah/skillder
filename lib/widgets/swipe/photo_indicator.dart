import 'package:flutter/material.dart';

class PhotoIndicator extends StatelessWidget {
  final int count;
  final int current;

  const PhotoIndicator({
    super.key,
    required this.count,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.only(right: index < count - 1 ? 3 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: index == current
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          );
        }),
      ),
    );
  }
}
