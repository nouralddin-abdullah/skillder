import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../../models/dummy_user.dart';
import '../../widgets/swipe/swipe_card.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CardSwiper(
        controller: _swiperController,
        cardsCount: dummyUsers.length,
        numberOfCardsDisplayed:
            dummyUsers.length < 3 ? dummyUsers.length : 3,
        backCardOffset: const Offset(0, -12),
        padding: EdgeInsets.zero,
        isLoop: true,
        threshold: 100,
        allowedSwipeDirection: const AllowedSwipeDirection.all(),
        onSwipe: (previousIndex, currentIndex, direction) {
          if (direction == CardSwiperDirection.bottom) return false;
          final user = dummyUsers[previousIndex];
          if (direction == CardSwiperDirection.right) {
            print('Liked ${user.firstName}');
          } else if (direction == CardSwiperDirection.left) {
            print('Passed ${user.firstName}');
          } else if (direction == CardSwiperDirection.top) {
            print('Super-pitched ${user.firstName}');
          }
          return true;
        },
        cardBuilder:
            (context, index, percentThresholdX, percentThresholdY) {
          return SwipeCard(
            user: dummyUsers[index],
            percentX: percentThresholdX,
            percentY: percentThresholdY,
            onPass: () =>
                _swiperController.swipe(CardSwiperDirection.left),
            onSuperPitch: () =>
                _swiperController.swipe(CardSwiperDirection.top),
            onLike: () =>
                _swiperController.swipe(CardSwiperDirection.right),
          );
        },
      ),
    );
  }
}
