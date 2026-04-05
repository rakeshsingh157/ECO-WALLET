# Design System Document: The Kinetic Ether

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Ether"**

This design system moves away from the rigid, "boxed-in" nature of traditional fintech apps to embrace a philosophy of fluidity and depth. We are not building a ledger; we are building a premium digital environment where capital feels like light and energy. 

The system achieves a "High-End Editorial" feel by breaking the standard 12-column grid in favor of **intentional asymmetry** and **tonal layering**. We prioritize breathability over density, using expansive whitespace (or "darkspace") to signal luxury and speed. The interface should feel less like a software tool and more like a high-performance dashboard found in a luxury electric vehicle—authoritative, silent, and sophisticated.

---

## 2. Colors & Surface Philosophy
The palette is rooted in deep obsidian tones, punctuated by high-frequency neon accents that represent "live" data and transaction energy.

### The "No-Line" Rule
**Explicit Instruction:** 1px solid borders are strictly prohibited for sectioning or containment. Boundaries must be defined through:
1.  **Background Shifts:** Use `surface_container_low` against `surface` to define areas.
2.  **Tonal Transitions:** Use soft, multi-stop gradients instead of hard edges.
3.  **Negative Space:** Let the 8px grid create "gutters of light" between surfaces.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of semi-translucent materials.
- **Base Layer:** `surface` (#0b1326).
- **Secondary Sectioning:** `surface_container_low` for large content blocks.
- **Interactive Cards:** `surface_container_high` or `surface_container_highest` to pull elements toward the user.
- **Nested Depth:** An inner element (like a "Send" button inside a card) should not use a border; it should use a `surface_bright` background or a glassmorphic blur to sit "within" the parent container.

### Glass & Gradient Signature
To achieve a "futuristic" feel, all primary CTAs and high-level summaries (like total balance) should utilize:
- **Mesh Gradients:** Transitions from `primary_container` (#00f5ff) to `on_primary_container` (#006c71) at a 135-degree angle.
- **Glassmorphism:** Use `surface_variant` at 60% opacity with a `20px` backdrop-blur for floating navigation bars or modal overlays.

---

## 3. Typography
We employ a "Technical-Editorial" pairing. We use **Space Grotesk** for high-impact data and headlines to provide a futuristic, wide-set character, while **Inter** handles the heavy lifting for legibility and trust.

| Level | Token | Font | Size | Weight | Intent |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Space Grotesk | 3.5rem | 700 | Hero balances / Large impact numbers. |
| **Headline** | `headline-md` | Space Grotesk | 1.75rem | 500 | Section titles / Page headers. |
| **Title** | `title-md` | Inter | 1.125rem | 600 | Card titles / Navigation labels. |
| **Body** | `body-md` | Inter | 0.875rem | 400 | Standard descriptions / Transaction data. |
| **Label** | `label-sm` | Inter | 0.6875rem | 700 | Uppercase micro-copy / Status tags. |

**Hierarchy Note:** Use `on_surface_variant` (#b9caca) for secondary body text to create a subtle "recessed" effect, making primary headers in `primary` (#e9feff) pop with crystalline clarity.

---

## 4. Elevation & Depth
In "The Digital Ether," depth is a result of light physics, not drop-shadow presets.

*   **The Layering Principle:** Avoid shadows on flat cards. Instead, elevate a `surface_container_high` card against a `surface_dim` background.
*   **Ambient Shadows:** For "Floating" elements (e.g., a Quick-Action FAB), use:
    *   `X: 0, Y: 20, Blur: 40`
    *   Color: `surface_tint` (#00dce5) at **6% opacity**. This creates a neon "glow" rather than a dirty shadow.
*   **The Ghost Border Fallback:** When high-contrast separation is required (e.g., Input Fields), use the `outline_variant` token at **15% opacity**. It should be felt, not seen.
*   **Roundedness:** Stick to `lg` (2rem/32px) for main containers and `DEFAULT` (1rem/16px) for inner components. This "nested rounding" reinforces the premium, organic feel.

---

## 5. Components

### Buttons
*   **Primary:** Gradient fill (`primary_fixed` to `primary_fixed_dim`). No border. `xl` (3rem) roundedness for a pill shape.
*   **Secondary:** `surface_container_highest` background with `primary` text. 
*   **Tertiary:** Ghost style. No background. `label-md` uppercase text with 2px tracking.

### Input Fields
*   **Style:** `surface_container_lowest` background. No bottom line.
*   **Active State:** Soft glow using a 1px `primary_container` ghost border at 30% opacity.
*   **Typography:** Use `body-lg` for input text to ensure the experience feels "fast" and accessible.

### Cards & Lists (The "Anti-List")
*   **Forbid Dividers:** Do not use lines between transaction items. 
*   **The Spacing Shift:** Separate list items using 12px of vertical whitespace. 
*   **Interactivity:** On hover/touch, change the item background to `surface_bright` with a `sm` (0.5rem) corner radius.

### Financial Visualization (The "Pulse")
*   **Sparklines:** Use `primary` for growth and `error` for decline. Lines should be 3px thick with a `primary_container` soft outer glow to mimic neon tubing.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical padding (e.g., more top padding than bottom) to create an editorial, "un-templated" look.
*   **Do** use `primary_fixed_dim` for icons to give them a "lit" appearance.
*   **Do** embrace extreme whitespace. If a screen feels "empty," it’s likely working.
*   **Do** use `space-grotesk` specifically for currency and percentages.

### Don’t
*   **Don’t** use pure black (#000000). Always use the `surface` palette for depth.
*   **Don’t** use standard "Material Design" shadows. They are too heavy for this ecosystem.
*   **Don’t** use 100% opaque `outline` colors. It breaks the "Ether" illusion.
*   **Don’t** crowd the edges. Keep a minimum 24px (3x 8px grid) margin from the screen edge.

---

## 7. Interaction Note
Every transition should be a "Smooth Glide." Use **Cubic-Bezier (0.4, 0, 0.2, 1)** for all card expansions and page transitions. Elements should not just "appear"; they should emerge from the depth of the `surface` layers.