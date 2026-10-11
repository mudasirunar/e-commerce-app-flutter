import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/widgets/home/category_story_bubble.dart';
import 'package:ecommerceapp/widgets/home/circular_product_item.dart';
import 'package:ecommerceapp/widgets/home/promo_carousel_banner.dart';

void main() {
  group('HomeScreen Redesign Components', () {
    testWidgets('PromoCarouselBanner renders slide items and indicator pills', (tester) async {
      PromoSlideItem? tappedSlide;

      const slides = [
        PromoSlideItem(
          title: 'Spring Flash Sale',
          subtitle: '30% Off Home & Kitchen',
          badgeText: 'FLASH SALE',
          ctaText: 'Shop Now',
          imageUrl: '',
          gradientColors: [Colors.deepOrange, Colors.orange],
        ),
        PromoSlideItem(
          title: 'Smart Tech Gear',
          subtitle: 'High precision wearables',
          badgeText: 'NEW',
          ctaText: 'Explore Tech',
          imageUrl: '',
          gradientColors: [Colors.blueGrey, Colors.black],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PromoCarouselBanner(
              slides: slides,
              onSlideTap: (s) => tappedSlide = s,
            ),
          ),
        ),
      );

      // Verify first slide content
      expect(find.text('Spring Flash Sale'), findsOneWidget);
      expect(find.text('FLASH SALE'), findsOneWidget);
      expect(find.text('Shop Now'), findsOneWidget);

      // Tap slide CTA
      await tester.tap(find.text('Shop Now'));
      await tester.pump();

      expect(tappedSlide, isNotNull);
      expect(tappedSlide!.title, equals('Spring Flash Sale'));
    });

    testWidgets('CategoryStoryBubble renders circular avatar and label with tap callback', (tester) async {
      bool tapped = false;

      const category = Category(
        categoryId: 'electronics',
        name: 'Electronics',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryStoryBubble(
              category: category,
              iconFallback: Icons.devices_rounded,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Electronics'), findsOneWidget);
      expect(find.byIcon(Icons.devices_rounded), findsOneWidget);

      await tester.tap(find.text('Electronics'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('CircularProductItem renders circular product with rating and price pill', (tester) async {
      bool tapped = false;

      const product = Product(
        productId: 'prod_1',
        name: 'Artisanal Ceramic Cup',
        categoryId: 'home-kitchen',
        imageUrl: '',
        priceMinor: 250000, // PKR 2,500
        stockQuantity: 10,
        rating: 4.9,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularProductItem(
              product: product,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Artisanal Ceramic Cup'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Rs 2,500.00'), findsOneWidget);

      await tester.tap(find.text('Artisanal Ceramic Cup'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
