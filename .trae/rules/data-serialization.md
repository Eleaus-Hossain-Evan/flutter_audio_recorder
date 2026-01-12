---
description: Data handling, JSON serialization, and repository patterns. Load when creating model classes with Dart Data Class Generator (fromMap/toMap, copyWith, Equatable), implementing repository pattern (interface in domain, implementation in infrastructure), making API calls with DioService.run(), or handling JSON parsing.
---

# Data Handling & Serialization

## Repository Pattern

### 1. Define Interface in Domain

```dart
// lib/features/auth/domain/i_auth_repo.dart
abstract class IAuthRepo {
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
}
```

### 2. Implement in Infrastructure

```dart
// lib/features/auth/infrastructure/auth_repo.dart
class AuthRepoImpl implements IAuthRepo {
  AuthRepoImpl(this._dio, this._storage);

  final Dio _dio;
  final ILocalStorageService _storage;

  @override
  Future<User> login(String email, String password) async {
    final response = await DioService.run(
      request: () => _dio.post(ApiEndpoint.login, data: {
        'email': email,
        'password': password,
      }),
      parse: (data) => User.fromJson(data),
    );
    return response;
  }
}
```

### 3. Expose via Provider

```dart
// lib/features/auth/application/auth_provider.dart
@riverpod
IAuthRepo authRepo(Ref ref) => AuthRepoImpl(
  ref.watch(dioClientProvider),
  ref.watch(localStorageProvider),
);
```

## JSON Serialization

### Model with Dart Data Class Generator (Project Standard)

This project uses the **Dart Data Class Generator** VSCode extension instead of `json_serializable`. It generates: constructor, `copyWith`, `fromJson`/`toJson`, `fromMap`/`toMap`, `toString`, and `props` (via Equatable).

```dart
import 'dart:convert';

import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final List<int> completedItems;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.completedItems,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    List<int>? completedItems,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      completedItems: completedItems ?? this.completedItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'completedItems': completedItems,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      completedItems: List<int>.from(map['completedItems'] ?? const []),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';

  @override
  List<Object?> get props => [id, name, email, avatarUrl, completedItems];
}
```

### Nested Models

```dart
class GroupModel extends Equatable {
  final String groupId;
  final List<UserModel> users;
  final StatsModel stats;

  // ... constructor, copyWith ...

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'users': users.map((x) => x.toMap()).toList(),
      'stats': stats.toMap(),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map['groupId'] ?? '',
      users: List<UserModel>.from(
        map['users']?.map((x) => UserModel.fromMap(x)) ?? const [],
      ),
      stats: StatsModel.fromMap(map['stats']),
    );
  }

  // ... rest of methods
}
```

### Type Handling in fromMap

```dart
// Integers with null safety
totalCount: map['totalCount']?.toInt() ?? 0,

// DateTime
createdAt: DateTime.parse(map['createdAt']),

// Lists
items: List<String>.from(map['items'] ?? const []),

// Nested objects
user: UserModel.fromMap(map['user']),

// Nullable nested objects
user: map['user'] != null ? UserModel.fromMap(map['user']) : null,


// List of nested objects
comments: List<CommentModel>.from(
  map['comments']?.map((x) => CommentModel.fromMap(x)) ?? const [],
),
```

## API Calls (DioService Pattern)

### Standard API Call

```dart
final response = await DioService.run(
  request: () => _dio.get(ApiEndpoint.users),
  parse: (data) => (data as List)
      .map((e) => User.fromJson(e))
      .toList(),
);
```

### With Error Handling

```dart
try {
  final user = await DioService.run(
    request: () => _dio.post(ApiEndpoint.login, data: credentials),
    parse: (data) => User.fromJson(data),
  );
  return user;
} on DioException catch (e) {
  throw AuthException.fromDioError(e);
}
```

## Data Structures

### State Classes with Equatable

For state classes, use the same pattern:

```dart
class AuthState extends Equatable {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  String toString() => 'AuthState(isLoading: $isLoading, user: $user, error: $error)';

  @override
  List<Object?> get props => [isLoading, user, error];
}
```

### Empty/Initial State Factory

```dart
factory UserModel.empty() {
  return const UserModel(
    id: '',
    name: '',
    email: '',
    completedItems: [],
  );
}
```

## Code Generation

This project uses **Dart Data Class Generator** extension, not `build_runner` for models.

To generate model boilerplate:

1. Define class fields
2. Use VSCode command palette: "Dart Data Class Generator: Generate"
3. Or use keyboard shortcut

For Riverpod providers (still uses build_runner):

```bash
dart run build_runner build --delete-conflicting-outputs
```

⚠️ Never edit `*.g.dart` or `*.freezed.dart` files (for Riverpod/Freezed).
