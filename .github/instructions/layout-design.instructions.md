---
description: "Flutter layout patterns, responsive design, and overflow handling. Load when building layouts with Row/Column/Stack, handling overflow issues, implementing responsive designs with LayoutBuilder/MediaQuery, using flutter_screenutil (.w, .h, .sp), or working with Expanded/Flexible/Wrap widgets."
---

# Flutter Layout Best Practices

## Flexible Layouts (Row/Column)

### Expanded vs Flexible

```dart
Row(
  children: [
    // Fills remaining space
    Expanded(child: TextField()),

    // Shrinks to fit, won't grow
    Flexible(child: Text('Label')),

    // Fixed size
    IconButton(icon: const Icon(Icons.send), onPressed: () {}),
  ],
)
```

⚠️ Don't combine `Flexible` and `Expanded` in same `Row`/`Column`.

### Wrap for Overflow

```dart
// Moves items to next line when overflowing
Wrap(
  spacing: 8,
  runSpacing: 4,
  children: tags.map((t) => Chip(label: Text(t))).toList(),
)
```

## Scrollable Content

### SingleChildScrollView

For fixed-size content larger than viewport:

```dart
SingleChildScrollView(
  child: Column(children: fixedContent),
)
```

### ListView/GridView Builder

Always use `.builder` for long lists:

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ListTile(title: Text(items[index])),
)
```

## Responsive Design

### LayoutBuilder

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return WideLayout();
    }
    return NarrowLayout();
  },
)
```

### MediaQuery

```dart
final screenWidth = MediaQuery.of(context).size.width;
final padding = MediaQuery.of(context).padding;
```

### flutter_screenutil (Project Standard)

```dart
// Width, height, font size, radius
Container(
  width: 100.w,
  height: 50.h,
  child: Text('Hello', style: TextStyle(fontSize: 14.sp)),
)
```

## Stack & Layering

### Positioned

```dart
Stack(
  children: [
    BackgroundWidget(),
    Positioned(
      top: 10,
      right: 10,
      child: CloseButton(),
    ),
  ],
)
```

### Align

```dart
Stack(
  children: [
    BackgroundWidget(),
    Align(
      alignment: Alignment.bottomCenter,
      child: BottomBar(),
    ),
  ],
)
```

## OverlayPortal (Dropdowns/Tooltips)

```dart
class CustomDropdown extends StatefulWidget {
  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  final _controller = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (context) {
        return Positioned(
          top: 50,
          left: 10,
          child: Card(child: DropdownContent()),
        );
      },
      child: ElevatedButton(
        onPressed: _controller.toggle,
        child: const Text('Open'),
      ),
    );
  }
}
```

## Scaling & Fitting

### FittedBox

```dart
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text('Long text that might overflow'),
)
```

### AspectRatio

```dart
AspectRatio(
  aspectRatio: 16 / 9,
  child: Image.network(url, fit: BoxFit.cover),
)
```

## Common Overflow Solutions

| Problem          | Solution                                     |
| ---------------- | -------------------------------------------- |
| Text overflow    | `Text(..., overflow: TextOverflow.ellipsis)` |
| Row overflow     | Wrap in `Expanded` or use `Wrap`             |
| Column overflow  | Wrap in `SingleChildScrollView`              |
| Unbounded height | Use `Expanded` or `SizedBox`                 |
