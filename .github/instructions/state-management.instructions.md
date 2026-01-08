---
description: "Riverpod state management patterns and best practices. Load when creating providers (@riverpod), implementing AsyncNotifier/Notifier, using ref.watch/ref.read, managing app state, implementing provider dependencies, or working with ConsumerWidget/HookConsumerWidget."
---

# State Management (Riverpod)

## Project Standard: Riverpod + Code Generation

Use `@riverpod` annotation for providers. Run `dart run build_runner build --delete-conflicting-outputs` after changes.

## Provider Types

### Simple Provider

```dart
@riverpod
IAuthRepo authRepo(Ref ref) {
  return AuthRepoImpl(
    ref.watch(dioClientProvider),
    ref.watch(localStorageProvider),
  );
}
```

### Async Provider (FutureProvider)

```dart
@riverpod
Future<User> currentUser(Ref ref) async {
  final repo = ref.watch(authRepoProvider);
  return repo.getCurrentUser();
}
```

### Stateful Provider (Notifier)

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}
```

### AsyncNotifier for Complex State

```dart
@riverpod
class AuthState extends _$AuthState {
  @override
  Future<User?> build() async {
    return ref.watch(authRepoProvider).getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(authRepoProvider).login(email, password)
    );
  }

  Future<void> logout() async {
    await ref.read(authRepoProvider).logout();
    state = const AsyncData(null);
  }
}
```

## Provider Dependencies

```dart
@Riverpod(dependencies: [currentActivity])
GoRouter router(Ref ref) {
  final activity = ref.watch(currentActivityProvider);
  // ...
}
```

## Keep Alive for Persistent State

```dart
@Riverpod(keepAlive: true)
Future<Map<String, String>> allPara(Ref ref) async {
  // This provider won't be disposed when not listened to
  return loadParaData();
}
```

## Consuming Providers

### In Widgets (ConsumerWidget)

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return user.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }
}
```

### With Hooks (HookConsumerWidget)

```dart
class MyPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final authState = ref.watch(authStateProvider);

    return // ...
  }
}
```

## ref.watch vs ref.read

```dart
// ✅ watch: Rebuilds when provider changes (in build)
final user = ref.watch(userProvider);

// ✅ read: One-time read (in callbacks/methods)
onPressed: () {
  ref.read(counterProvider.notifier).increment();
}
```

## Provider Overrides (Testing/DI)

```dart
ProviderScope(
  overrides: [
    authRepoProvider.overrideWithValue(FakeAuthRepo()),
  ],
  child: MyApp(),
)
```

## Built-in Flutter State (When Appropriate)

For simple, ephemeral state not needing global access:

### ValueNotifier

```dart
final counter = ValueNotifier<int>(0);

ValueListenableBuilder<int>(
  valueListenable: counter,
  builder: (context, value, child) => Text('Count: $value'),
)
```

### StreamBuilder

```dart
StreamBuilder<User>(
  stream: userStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) return UserWidget(snapshot.data!);
    if (snapshot.hasError) return ErrorWidget(snapshot.error!);
    return const CircularProgressIndicator();
  },
)
```

## Data Flow Pattern

1. **UI** → watches providers
2. **Providers** → depend on repositories
3. **Repositories** → abstract data sources
4. **Data Sources** → API, database, storage
