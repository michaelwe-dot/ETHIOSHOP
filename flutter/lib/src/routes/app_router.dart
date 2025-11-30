import 'package:flutter/material.dart';

import '../screens/splash_lottie_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/listings_screen.dart';
import '../screens/listing_detail_screen.dart';
import '../screens/post_listing_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/chat_thread_screen.dart';
import '../screens/search_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const LottieSplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/market':
        return MaterialPageRoute(builder: (_) => const ListingsScreen());
      case '/listing':
        final id = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => ListingDetailScreen(listingId: id ?? ''));
      case '/post_listing':
        return MaterialPageRoute(builder: (_) => const PostListingScreen());
      case '/messages':
        return MaterialPageRoute(builder: (_) => ChatListScreen());
      case '/thread':
        final threadId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => ChatThreadScreen(threadId: threadId));
      case '/search':
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      default:
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Unknown route'))));
    }
  }
}
