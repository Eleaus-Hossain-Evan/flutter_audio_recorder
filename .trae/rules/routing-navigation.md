---
description: GoRouter navigation patterns, deep linking, and route guards. Load when configuring routes, implementing navigation (context.go/push/pop), setting up auth redirects, creating ShellRoute/StatefulShellRoute for bottom navigation, handling path/query parameters, or integrating GoRouter with Riverpod.
---

# Routing & Navigation (GoRouter)

## Project Standard

This project uses GoRouter with Riverpod integration via `@Riverpod` annotation.

## Basic Router Setup

```dart
@Riverpod(dependencies: [currentActivity])
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
```

## Route Configuration

### Simple Routes

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsScreen(),
)
```

### Route with Path Parameters

```dart
GoRoute(
  path: '/user/:id',
  builder: (context, state) {
    final userId = state.pathParameters['id']!;
    return UserScreen(userId: userId);
  },
)
```

### Query Parameters

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    return SearchScreen(query: query);
  },
)
// Navigate: context.go('/search?q=flutter')
```

### Nested Routes

```dart
GoRoute(
  path: '/products',
  builder: (context, state) => const ProductsScreen(),
  routes: [
    GoRoute(
      path: ':id', // Full path: /products/:id
      builder: (context, state) => ProductDetailScreen(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
)
```

## Shell Routes for Persistent Navigation

### ShellRoute (Basic)

Single navigator for all child routes. **Does NOT preserve state** when switching tabs.

```dart
ShellRoute(
  builder: (context, state, child) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const AppBottomNav(),
    );
  },
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const HomeTab()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileTab()),
  ],
)
```

### StatefulShellRoute (Recommended for Bottom Navigation)

Separate navigator per branch with **state preservation**. Use `indexedStack` for bottom navigation.

```dart
// Navigator keys for explicit control
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

GoRouter(
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
              routes: [
                // Nested route - stays within Home tab
                GoRoute(
                  path: 'details/:id',
                  builder: (context, state) => DetailsPage(
                    id: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Tab 1: Profile
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
)
```

### Shell Widget with StatefulNavigationShell

```dart
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // Displays current branch content
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            // Reset to initial location if tapping active tab
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

### StatefulNavigationShell Properties

| Property/Method                          | Description                     |
| ---------------------------------------- | ------------------------------- |
| `currentIndex`                           | Currently active branch index   |
| `goBranch(index)`                        | Navigate to specific branch     |
| `goBranch(index, initialLocation: true)` | Reset to branch's initial route |

### Full-Screen Routes from Within Shell

Use `parentNavigatorKey` to display routes outside the shell (no bottom nav):

```dart
StatefulShellRoute.indexedStack(
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
      ],
    ),
  ],
),
// Full-screen route (outside shell)
GoRoute(
  path: '/fullscreen-modal',
  parentNavigatorKey: _rootNavigatorKey, // ← Covers entire screen
  builder: (context, state) => const FullScreenPage(),
),
```

### Preloading Branch Data

```dart
StatefulShellBranch(
  preload: true, // Preload when shell initializes
  routes: [...],
),
```

### ShellRoute vs StatefulShellRoute

| Feature             | ShellRoute    | StatefulShellRoute            |
| ------------------- | ------------- | ----------------------------- |
| State Preservation  | ❌ No         | ✅ Yes                        |
| Separate Navigators | ❌ No         | ✅ Yes                        |
| Memory Usage        | Lower         | Higher (keeps branches alive) |
| Use Case            | Simple shells | Bottom navigation             |

## Navigation Methods

```dart
// Navigate and clear stack
context.go('/home');

// Push onto stack (can pop back)
context.push('/details');

// Replace current route
context.replace('/new-page');

// Pop current route
context.pop();

// With extra data
context.go('/details', extra: myObject);
```

## Authentication Redirects

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = ref.read(authStateProvider).isLoggedIn;
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoggingIn) {
      return '/login?redirect=${state.matchedLocation}';
    }
    if (isLoggedIn && isLoggingIn) {
      final redirect = state.uri.queryParameters['redirect'];
      return redirect ?? '/home';
    }
    return null; // No redirect
  },
  routes: [...],
)
```

## Refresh on Auth State Change

```dart
@Riverpod(dependencies: [authState])
GoRouter router(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.notifier).stream,
    ),
    redirect: (context, state) {
      // ... redirect logic based on authState
    },
    routes: [...],
  );
}
```

## Named Routes (Optional)

```dart
GoRoute(
  name: 'product',
  path: '/products/:id',
  builder: (context, state) => ProductScreen(
    id: state.pathParameters['id']!,
  ),
)

// Navigate by name
context.goNamed('product', pathParameters: {'id': '123'});
```

## Error Handling

```dart
GoRouter(
  errorBuilder: (context, state) => ErrorScreen(
    error: state.error,
  ),
  routes: [...],
)
```

## Using with MaterialApp

```dart
MaterialApp.router(
  routerConfig: ref.watch(routerProvider),
)
```

## Simple Navigator (Non-Deep-Linkable)

For temporary views like dialogs:

```dart
// Push
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const TempScreen()),
);

// Pop
Navigator.pop(context);

// Pop with result
Navigator.pop(context, result);
```
