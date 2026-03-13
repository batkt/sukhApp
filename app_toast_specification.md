# AppToast: Component Specification

The [AppToast](file:///c:/Users/user/Desktop/fsmapp/lib/widgets/app_toast.dart#4-23) is a high-performance, non-blocking notification system that renders above the application's main navigation stack using the Flutter [Overlay](file:///c:/Users/user/Desktop/fsmapp/lib/widgets/app_toast.dart#93-116).

## 1. Visual Design & Positioning

### Static Properties
- **Position:** Anchored exactly `10px` below the status bar (`mq.padding.top + 10`).
- **Margins:** `20px` horizontal padding from the screen edges (Left/Right).
- **Background:** Uses `c.cardBackground` with a subtle `c.border` (60% opacity).
- **Shadow:** 15-point blur with an 8-pixel downward offset (`Offset(0, 8)`), colored at 8% opacity black.
- **Corner Radius:** `16px` (Semi-rounded).

### Dynamic Content
The toast supports three distinct content modes:
1.  **Icon Mode:** Renders a custom leading icon (e.g., Error, Checkmark).
2.  **Determinate Progress:** Displays a circular spinner and a bottom `LinearProgressIndicator` with a percentage label.
3.  **Basic Message:** Minimal text-only notification.

---

## 2. Animation Physics

The toast features a synchronized entrance animation to feel fluid and reactive:
-   **Slide:** Transitions from an initial offset of `Offset(0, -0.5)` to its final position using `Curves.easeOutCubic`.
-   **Fade:** A simple linear alpha ramp from `0.0` to `1.0`.
-   **Duration:** `300ms` for the entrance.

---

## 3. Technical Implementation Details

### Overlay Management
Unlike standard `SnackBars`, [AppToast](file:///c:/Users/user/Desktop/fsmapp/lib/widgets/app_toast.dart#4-23) uses a singleton [_AppToastManager](file:///c:/Users/user/Desktop/fsmapp/lib/widgets/app_toast.dart#24-78) and raw `OverlayEntry`. This allows it to:
- Persist across screen transitions.
- Be manually updated in-place (e.g., when updating a progress bar percentage).
- Avoid interfering with the `ScaffoldMessenger` or `bottomNavigationBar`.

### Usage Logic
```dart
AppToast.show(
  context,
  'Амжилттай!',
  icon: Icons.check_circle_rounded,
  color: context.colors.success,
  duration: Duration(seconds: 4),
);
```

### Layout Logic (Simplified)
```dart
Positioned(
  top: topPadding,
  child: SlideTransition(
    position: _slideAnimation,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [...],
      ),
      child: Row(...) // Icon + Message + (Optional) Progress
    ),
  ),
);
```

---

> [!TIP]
> The toast automatically calculations its top position based on the device's "safe area" (Notch/Status Bar), ensuring it never obscures system icons or gets cut off by hardware cutouts.
