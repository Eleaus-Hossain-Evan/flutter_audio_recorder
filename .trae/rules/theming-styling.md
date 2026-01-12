---
description: Material theming, color schemes, typography, and styling patterns. Load when working with ThemeData, ColorScheme, TextTheme, custom theme extensions, AppColors, text style extensions (context.textTheme, .bold, .colorPrimary()), color utilities (.darken(), .onColor), or implementing light/dark theme support.
---

# Flutter Theming & Styling

## Project Extensions (Preferred Approach)

### Theme Context Extensions

Access theme properties cleanly via `BuildContext` extensions:

```dart
// lib/core/utils/extensions/theme_extension.dart
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get color => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}

// Usage - cleaner than Theme.of(context)
Text('Title', style: context.textTheme.titleLarge)
Container(color: context.color.primary)
```

### TextStyle Fluent Extensions

Chain style modifications for readable code:

```dart
// lib/core/utils/extensions/text_style_extension.dart
extension TextStyleHelpers on TextStyle {
  // Font weights
  TextStyle get black => copyWith(fontWeight: AppFontWeight.black);
  TextStyle get extraBold => copyWith(fontWeight: AppFontWeight.extraBold);
  TextStyle get bold => copyWith(fontWeight: AppFontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: AppFontWeight.semiBold);
  TextStyle get medium => copyWith(fontWeight: AppFontWeight.medium);
  TextStyle get regular => copyWith(fontWeight: AppFontWeight.regular);
  TextStyle get light => copyWith(fontWeight: AppFontWeight.light);

  // Font style
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  // Chainable setters
  TextStyle font(double value) => copyWith(fontSize: value);
  TextStyle colorSet(Color value) => copyWith(color: value);
  TextStyle letterSpace(double value) => copyWith(letterSpacing: value);
  TextStyle heightSet(double value) => copyWith(height: value);

  // Predefined color shortcuts
  TextStyle colorPrimary() => copyWith(color: AppColors.emerald700);
  TextStyle colorBlack() => copyWith(color: AppColors.black);
  TextStyle colorWhite() => copyWith(color: AppColors.white);
  TextStyle colorHint() => copyWith(color: AppColors.gray500);
}

// Usage - fluent chaining
Text(
  'Hello World',
  style: context.textTheme.bodyLarge!.semiBold.colorPrimary(),
)

Text(
  'Subtitle',
  style: context.textTheme.bodyMedium!.italic.colorHint().heightSet(1.5),
)
```

### AppFontWeight Constants

Semantic font weight naming:

```dart
// lib/core/utils/typography/app_font_weight.dart
abstract class AppFontWeight {
  static const FontWeight black = FontWeight.w900;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight thin = FontWeight.w100;
}
```

### Color Extensions

Useful color manipulation utilities:

```dart
extension ColorExtensions on Color {
  Color brighten([int amount = 10]) => // ... brighten by %
  Color lighten([int amount = 10]) => // ... lighten via HSL
  Color darken([int amount = 10]) => // ... darken via HSL
  Color get onColor => // black or white for contrast
  bool get isLight => // brightness check
  bool get isDark => // brightness check
  Color blend(Color input, [int amount = 10]) => // alpha blend
  String get hex => // #RRGGBB format
  MaterialColor toMaterialColor() => // convert to MaterialColor
}

// Usage
AppColors.emerald700.darken(20)
AppColors.primary.onColor // returns white (for dark background)
```

## Material 3 & ThemeData

### Color Scheme Generation

Generate harmonious palettes from a seed color:

```dart
final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
);

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ),
);
```

### App Setup with Theme Toggle

```dart
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ThemeMode.system, // or .light, .dark
  home: const MyHomePage(),
);
```

## Component Themes

Customize individual Material components within `ThemeData`:

```dart
ThemeData(
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  cardTheme: const CardTheme(
    elevation: 2,
    margin: EdgeInsets.all(8),
  ),
)
```

## Custom Theme Extensions

For custom design tokens not in standard `ThemeData`:

```dart
@immutable
class AppExtendedColors extends ThemeExtension<AppExtendedColors> {
  const AppExtendedColors({required this.success, required this.warning});

  final Color success;
  final Color warning;

  @override
  ThemeExtension<AppExtendedColors> copyWith({Color? success, Color? warning}) {
    return AppExtendedColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  ThemeExtension<AppExtendedColors> lerp(covariant ThemeExtension<AppExtendedColors>? other, double t) {
    if (other is! AppExtendedColors) return this;
    return AppExtendedColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

// Register in ThemeData
ThemeData(
  extensions: const [
    AppExtendedColors(success: Colors.green, warning: Colors.orange),
  ],
)

// Access in widgets
Theme.of(context).extension<AppExtendedColors>()!.success
```

## WidgetStateProperty for Interactive States

```dart
final buttonStyle = ButtonStyle(
  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
    if (states.contains(WidgetState.pressed)) return Colors.green;
    if (states.contains(WidgetState.disabled)) return Colors.grey;
    return Colors.blue;
  }),
);
```

## Typography Best Practices

- Use `context.textTheme` (via extension) for text styles
- Chain modifiers: `context.textTheme.bodyLarge!.bold.colorPrimary()`
- Limit to 1-2 font families
- Establish clear hierarchy: display → title → body → label

```dart
// ✅ Preferred: Extension-based access with chaining
Text('Title', style: context.textTheme.titleLarge!.semiBold)
Text('Body', style: context.textTheme.bodyMedium!.colorHint())

// ❌ Avoid: Verbose Theme.of(context) calls
Text('Title', style: Theme.of(context).textTheme.titleLarge)
```

### Line Height & Readability

- Line height: 1.4x to 1.6x font size
- Line length: 45-75 characters for body text
- Avoid ALL CAPS for long text

## Color Best Practices

### Contrast Ratios (WCAG 2.1)

- Normal text: **4.5:1** minimum
- Large text (18pt+): **3:1** minimum

### 60-30-10 Rule

- **60%** Primary/Neutral (dominant)
- **30%** Secondary
- **10%** Accent

## Assets & Images

```dart
// Local assets
Image.asset('assets/images/logo.png')

// Network with error handling
Image.network(
  url,
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return const CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
)
```

Declare assets in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```
