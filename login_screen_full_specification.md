# Login Screen: Design & Positioning Specification (High Detail)

This document provides the exact positioning, sizing, and styling data used to render the **Zev** login screen. It follows the precise logic implemented in the [_BgPainter](file:///c:/Users/user/Desktop/fsmapp/lib/screens/login_screen.dart#779-845) and [_buildBranding](file:///c:/Users/user/Desktop/fsmapp/lib/screens/login_screen.dart#409-462) components.

## 1. Background Geometry ([_BgPainter](file:///c:/Users/user/Desktop/fsmapp/lib/screens/login_screen.dart#779-845))

The background uses procedural rendering to ensure perfect scaling across all device sizes. All coordinates are relative to the screen dimensions (`size.width`, `size.height`).

### A. Linear Gradient
- **Axis:** `Alignment.topCenter` to `Alignment.bottomCenter`.
- **Colors & Stops:**
  - `0.0`: `brandGreen` (#059669)
  - `0.35`: `brandGreen` (85% Opacity)
  - `0.45`: `loginBackground` (#F5F9FC)
  - `1.0`: `loginBackground`

### B. Decorative Circles (White, 5% Opacity)
| Element | Center Offset (X, Y) | Radius |
| :--- | :--- | :--- |
| **Top Right Circle** | `85% Width`, `8% Height` | `35% Width` |
| **Mid Left Circle** | `10% Width`, `22% Height` | `25% Width` |
| **Mid Right Circle** | `70% Width`, `30% Height` | `15% Width` |

### C. Wave Separator Path
- **Base Level (`waveY`):** `38% Height`.
- **Curve 1 (Bottom Left):** Starts at [(0, waveY)](file:///c:/Users/user/Desktop/fsmapp/lib/main.dart#32-58), quadratic bezier via [(25% Width, waveY + 30)](file:///c:/Users/user/Desktop/fsmapp/lib/main.dart#32-58) to [(50% Width, waveY - 10)](file:///c:/Users/user/Desktop/fsmapp/lib/main.dart#32-58).
- **Curve 2 (Bottom Right):** Quadratic bezier via [(75% Width, waveY - 50)](file:///c:/Users/user/Desktop/fsmapp/lib/main.dart#32-58) to [(size.width, waveY + 10)](file:///c:/Users/user/Desktop/fsmapp/lib/main.dart#32-58).
- **Fill:** Rectangular fill from the wave path to the bottom of the screen using `loginBackground`.

---

## 2. Branding Section Positioning

The branding section is centered vertically and uses a tiered scaling system based on the screen class.

### Logo Container
- **Shape:** Perfect Circle.
- **Styling:** `white` (15% opacity).
- **Shadow:** `spreadRadius: 5`, `blurRadius: 40`, `color: brandGreen.withOpacity(0.3)`.
- **Logo Size (`zev_logo.png`):**
  - **Landscape/Compact:** `48px` height.
  - **Portrait (Short Screen):** `56px` height.
  - **Standard Portrait:** `64px` height.

### Typography Spacing
- **Title Gap:** `10px` below logo.
- **Subtitle Gap:** `6px` below title.
- **Title Size:** `24px` (Portrait), `22px` (Short), `18px` (Compact).
- **Subtitle Size:** `13px` (Portrait), `12px` (Short/Compact).

---

## 3. Auth Form Card Constraints

### Sizing & Shadows
- **Max Width:** `480px` (Tablet), `380px` (Mobile).
- **Internal Padding:** `20px` (Standard), `16px` (Short Screen).
- **Border:** `0.5` opacity `border` color.
- **Shadow:**
  - `offset: Offset(0, 10)`
  - `blurRadius: 30`
  - `color: Colors.black.withOpacity(0.08)`

### Input Field Visuals
- **Corner Radius:** `10px` for all states.
- **Focus Border:** `2px` width, color `brandGreen`.
- **Internal Spacing:** `14px` vertical, `16px` horizontal padding.

---

## 4. Layout Fractions (Landscape Mode)

In Side-by-Side mode, the screen is split into a flex-grid:
- **Left Column (Flex 4):** Branding content, centered.
- **Right Column (Flex 5):** Interaction card, centered with `24px` padding.

---

> [!IMPORTANT]
> The background wave and circles are drawn *beneath* the `SafeArea` content to ensure brand visibility while maintaining a high-depth visual effect.
