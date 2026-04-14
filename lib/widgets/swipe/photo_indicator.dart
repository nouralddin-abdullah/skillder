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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: index < count - 1 ? 4 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: index == current
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
