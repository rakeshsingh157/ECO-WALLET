---
name: Merchant Vernacular
colors:
  surface: '#f6faf9'
  surface-dim: '#d7dbda'
  surface-bright: '#f6faf9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f4f3'
  surface-container: '#ebefee'
  surface-container-high: '#e5e9e8'
  surface-container-highest: '#dfe3e2'
  on-surface: '#181c1c'
  on-surface-variant: '#3e4949'
  inverse-surface: '#2c3131'
  inverse-on-surface: '#edf2f1'
  outline: '#6e7979'
  outline-variant: '#bdc9c8'
  surface-tint: '#006a6a'
  primary: '#006565'
  on-primary: '#ffffff'
  primary-container: '#008080'
  on-primary-container: '#e3fffe'
  inverse-primary: '#76d6d5'
  secondary: '#a04100'
  on-secondary: '#ffffff'
  secondary-container: '#fd7729'
  on-secondary-container: '#5e2300'
  tertiary: '#8b4823'
  on-tertiary: '#ffffff'
  tertiary-container: '#a96039'
  on-tertiary-container: '#fff9f7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#93f2f2'
  primary-fixed-dim: '#76d6d5'
  on-primary-fixed: '#002020'
  on-primary-fixed-variant: '#004f4f'
  secondary-fixed: '#ffdbcc'
  secondary-fixed-dim: '#ffb693'
  on-secondary-fixed: '#351000'
  on-secondary-fixed-variant: '#7a3000'
  tertiary-fixed: '#ffdbcb'
  tertiary-fixed-dim: '#ffb692'
  on-tertiary-fixed: '#341100'
  on-tertiary-fixed-variant: '#733512'
  background: '#f6faf9'
  on-background: '#181c1c'
  surface-variant: '#dfe3e2'
typography:
  display-lg:
    fontFamily: Quicksand
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Quicksand
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Quicksand
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Quicksand
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Quicksand
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Quicksand
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-md:
    fontFamily: Quicksand
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  label-md:
    fontFamily: Quicksand
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  caption:
    fontFamily: Quicksand
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 48px
---

## Brand & Style
The design system is built for the modern Indian shopkeeper, blending traditional warmth with contemporary digital efficiency. The brand personality is "The Reliable Helper"—approachable, industrious, and premium without being intimidating.

The design style is **Tactile Modernism**. It prioritizes high legibility and physical metaphors (like paper receipts and ledger cards) while maintaining a clean, clutter-free aesthetic. It avoids the coldness of typical enterprise SaaS by using organic shapes, warm neutrals, and a bespoke mascot family. The emotional goal is to make inventory and financial management feel less like a chore and more like a natural extension of the shop's daily rhythm.

## Colors
The palette is rooted in a warm, off-white base (#FAF9F6) that reduces eye strain during long hours of shop management. 

- **Primary (Teal):** Used for main actions, navigation states, and brand presence. It feels modern and trustworthy.
- **Secondary (Saffron/Terracotta):** Used for alerts, urgent notifications, and highlighting key financial metrics to ensure they stand out against the teal.
- **Neutrals:** Deep charcoal (#2D2D2D) provides high-contrast legibility for transaction details, while soft greys are reserved for secondary labels and dividers.
- **Status Colors:** Low-saturation "Sage" and "Terracotta" are used for success and error states respectively, maintaining the "Warm & Playful" tone without becoming visually aggressive.

## Typography
This design system uses **Quicksand** exclusively to maintain a soft, humanistic feel across the entire interface. The rounded terminals of the typeface complement the "Playful" brand pillar.

- **Scale:** Large display sizes are used for high-level shop health (Total Sales, Stock Count). 
- **Weights:** Use Bold (700) for headers to ensure clear hierarchy. Medium (500) is the standard for body text to ensure the light font weight of Quicksand remains legible on all screen types.
- **Accessibility:** All body text must maintain a minimum contrast ratio of 4.5:1 against the warm background.

## Layout & Spacing
The layout follows a **4px baseline grid** to maintain strict alignment while allowing for flexible, generous whitespace.

- **Mobile First:** Given the target audience, the layout is optimized for single-handed use on mobile devices. Primary actions (Add Sale, Scan Barcode) are placed in a "bottom-action zone."
- **Grid:** On mobile, use a 4-column fluid grid with 16px margins. On desktop, use a 12-column fixed-center grid (max-width 1200px).
- **Rhythm:** Use "md" (16px) for internal card padding and "lg" (24px) for spacing between distinct logical sections.

## Elevation & Depth
This design system avoids heavy shadows and floating effects. Depth is conveyed through **Tonal Layering** and **Subtle Tactility**.

- **Level 0 (Base):** The off-white background (#FAF9F6).
- **Level 1 (Cards):** Pure white (#FFFFFF) surfaces with a 1px solid border (#EAE8E0) and a very soft, diffused shadow (0px 4px 12px rgba(0,0,0,0.03)).
- **Level 2 (Modals/Popovers):** Higher contrast border and a slightly deeper shadow to indicate focus. 
- **Interactive States:** Buttons use a "press-in" effect where the shadow disappears and the element shifts 1px down, mimicking a physical button.

## Shapes
The shape language is varied to create a distinct visual hierarchy:

- **Buttons:** 8px (Small/Medium) corner radius to feel precise and actionable.
- **Cards & Containers:** 16px corner radius for a soft, friendly framing of information.
- **Inputs:** 8px corner radius to match buttons.
- **Search Bars & Chips:** Fully pill-shaped (100px) to distinguish them from actionable buttons.
- **Mascots:** Character art should use thick, 2pt clean outlines with rounded caps/joins.

## Components

### Buttons
- **Primary:** Solid Teal background with White text. 8px radius.
- **Secondary:** Transparent background, Teal 1.5px border.
- **Action Float:** A large, circular button with a "plus" icon for the most frequent tasks (e.g., "New Sale").

### Cards
- Always use White backgrounds on the Off-White page base.
- Internal padding is 16px.
- Use the 16px corner radius. Include a 1px #EAE8E0 border to define the edge against the warm background.

### Input Fields
- Use "Floating Labels" to save vertical space.
- Background should be slightly darker than the page (#F3F2EE) when inactive, turning White with a Teal border on focus.

### Mascot Integration
- **Empty States:** A "Box" mascot looking sad for "No Inventory" or a "Calculator" mascot with a magnifying glass for "No Results Found."
- **Onboarding:** The "Shopkeeper" character should guide users through the first setup steps with speech bubbles using `body-md` typography.

### Lists & Ledger Lines
- List items should have a 1px bottom border (#F3F2EE).
- Use Sage Green for positive cash flow (+ ₹) and Terracotta for negative cash flow (- ₹).