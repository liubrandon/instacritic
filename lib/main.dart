import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/setup_screen.dart';
import 'configure_web.dart';
import 'package:provider/provider.dart';
import 'instagram_repository.dart';
import 'instacritic.dart';
Future<void> main() async {
  configureApp();
  await initializeFlutterFire();
  runApp(MyApp());
}

Future<void> initializeFlutterFire() async {
  try {
    await Firebase.initializeApp();
  } catch(e) {
    print(e);
    print("Firebase initialization failed.");
  }
}

class MyApp extends StatelessWidget {
  final ICRouterDelegate _routerDelegate = ICRouterDelegate();
  final ICRouteInformationParser _routeInformationParser = ICRouteInformationParser();
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => InstagramRepository(),
        child: MaterialApp.router(
          title: 'Instacritic',
          routerDelegate: _routerDelegate,
          routeInformationParser: _routeInformationParser,
        ),
      );
  }
}

class ICRouteInformationParser extends RouteInformationParser<ICRoutePath> {
  @override
  Future<ICRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location);
    if(uri.pathSegments.length == 0)
      return ICRoutePath.home();
    
    // Handle /setup
    if (uri.pathSegments.length == 1) {
      if (uri.pathSegments[0] == 'setup') return ICRoutePath.setup();
      return ICRoutePath.unknown();
    }

    // Handle unknown routes
    return ICRoutePath.unknown();
  }

  @override
  RouteInformation restoreRouteInformation(ICRoutePath path) {
    if (path.isUnknown)
      return RouteInformation(location: '/404');
    if (path.isHomePage)
      return RouteInformation(location: '/');
    if (path.isSetupPage)
      return RouteInformation(location: '/setup');
    return null;
  }
}

class ICRouterDelegate extends RouterDelegate<ICRoutePath>
  with ChangeNotifier, PopNavigatorRouterDelegateMixin<ICRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;
  int _currPageId = 0;
  bool show404 = false;
  ICRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  ICRoutePath get currentConfiguration { 
    if(_currPageId == 0)
      return ICRoutePath.home();
    else if(_currPageId == 1)
      return ICRoutePath.setup();
    else if(show404)
      return ICRoutePath.unknown();
    // print('ISSUE: Should never get here in routing...');
    return ICRoutePath.home();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      // transitionDelegate: NoAnimationTransitionDelegate(),
      pages: [
        if(_currPageId == 0)
          MaterialPage(
            key: ValueKey('Instacritic'),
            child: Instacritic(),
          ),
        if(show404)
          MaterialPage(key: ValueKey('UnknownPage'), child: UnknownScreen()),
        if(_currPageId == 1)
          MaterialPage(
            key: ValueKey('Instacritic Setup'),
            child: SetupScreen(),
          ),
      ],
      onPopPage: (route, result) {
        if(!route.didPop(result)) return false;
        show404 = false;
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(ICRoutePath path) async {
    if(path.isUnknown) {
      show404 = true;
      return;
    }
    else if(path.isHomePage) {
      _currPageId = 0;
      return;
    }
    else if(path.isSetupPage) {
      _currPageId = 1;
    }
    show404 = false;
  }
}

class ICRoutePath {
  final int pageId;
  final bool isUnknown;
  ICRoutePath.home() : pageId = 0, isUnknown = false;
  ICRoutePath.setup() : pageId = 1, isUnknown = false;
  ICRoutePath.unknown() : pageId = null, isUnknown = true;

  bool get isHomePage => pageId == 0 && isUnknown == false;
  bool get isSetupPage => pageId == 1 && isUnknown == false;
}

class NoAnimationTransitionDelegate extends TransitionDelegate<void> {
  @override
  Iterable<RouteTransitionRecord> resolve({
    List<RouteTransitionRecord> newPageRouteHistory,
    Map<RouteTransitionRecord, RouteTransitionRecord>
        locationToExitingPageRoute,
    Map<RouteTransitionRecord, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    final results = <RouteTransitionRecord>[];

    for (final pageRoute in newPageRouteHistory) {
      if (pageRoute.isWaitingForEnteringDecision) {
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
    }

    for (final exitingPageRoute in locationToExitingPageRoute.values) {
      if (exitingPageRoute.isWaitingForExitingDecision) {
        exitingPageRoute.markForRemove();
        final pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
        if (pagelessRoutes != null) {
          for (final pagelessRoute in pagelessRoutes) {
            pagelessRoute.markForRemove();
          }
        }
      }

      results.add(exitingPageRoute);
    }
    return results;
  }
}

class UnknownScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.purple,),
      body: Center(
        child: Text('404!'),
      ),
    );
  }
}