---
name: Asistly Modern M3
colors:
  surface: '#f7f9fe'
  surface-dim: '#d7dadf'
  surface-bright: '#f7f9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4f9'
  surface-container: '#ebeef3'
  surface-container-high: '#e5e8ed'
  surface-container-highest: '#dfe3e8'
  on-surface: '#181c20'
  on-surface-variant: '#444651'
  inverse-surface: '#2d3135'
  inverse-on-surface: '#eef1f6'
  outline: '#747683'
  outline-variant: '#c4c6d3'
  surface-tint: '#3b5aad'
  primary: '#00266f'
  on-primary: '#ffffff'
  primary-container: '#1a3d8f'
  on-primary-container: '#92acff'
  inverse-primary: '#b4c5ff'
  secondary: '#4a5d91'
  on-secondary: '#ffffff'
  secondary-container: '#afc2fe'
  on-secondary-container: '#3c4f82'
  tertiary: '#3a2a00'
  on-tertiary: '#ffffff'
  tertiary-container: '#553f00'
  on-tertiary-container: '#dba700'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#204193'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b3c5ff'
  on-secondary-fixed: '#001849'
  on-secondary-fixed-variant: '#324578'
  tertiary-fixed: '#ffdf9b'
  tertiary-fixed-dim: '#f6be21'
  on-tertiary-fixed: '#251a00'
  on-tertiary-fixed-variant: '#5a4300'
  background: '#f7f9fe'
  on-background: '#181c20'
  surface-variant: '#dfe3e8'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.005em
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  title-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  margin: 1rem
  margin-tablet: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an academic attendance management experience built upon modern Android Material 3 foundations. The visual personality balances institutional credibility with agile, student-first clarity. The interface projects efficiency, punctuality, and structure without feeling cold or bureaucratic.

### Target Audience & Tone
Engineered specifically for university professors, faculty coordinators, and students navigating fast-paced campus environments. The tone is organized, trustworthy, and proactive. Micro-interactions and layout structures minimize cognitive load during brief, high-frequency attendance windows (e.g., scanning QR codes, marking rolls, checking attendance percentages).

### Aesthetic Movement: Contemporary Material 3
Drawing strictly from Android Material 3 (Material You) ergonomics, the design utilizes tonal surface containers (`#F3F6FB`, `#E7EDF6`), generous touch targets, distinct corner curves, and soft ambient shadows. Deep authoritative blues anchor institutional identity, while calibrated yellow accents highlight immediate actions without overwhelming the screen. All microcopy, labels, and system messages are natively structured in Spanish (e.g., "Presente", "Ausente", "Registrar Asistencia", "Materia activa").

## Colors

The palette enforces a clear semantic hierarchy tailored for rapid scanning under varying ambient light conditions on campus.

### Palette Roles & Contrast Rules
- **Primary (`#1A3D8F`)**: Used for top app bars, primary icons, prominent active tabs, and headline anchors. Communicates institutional authority and stability.
- **Dark Blue (`#0F2557`)**: The deepest structural tone. Reserved for high-emphasis headlines, active card titles, and pressed state overlays. It also serves as the mandatory text/icon tone over accent yellow backgrounds.
- **Accent Yellow (`#FFC62B`)**: Strictly constrained to primary call-to-action buttons (e.g., "Registrar Asistencia"), high-priority floating action buttons (FAB), and the "Clase en curso" (active class) indicator. **Rule**: Text or iconography rendered over `#FFC62B` must always be `#0F2557` (never white) to ensure WCAG AAA legibility.
- **Background (`#FFFFFF`)**: Base canvas for full-screen sheets, dialogs, and elevated primary cards.
- **Surface (`#F3F6FB`)**: Standard mobile screen backdrop, providing soft visual separation from white elevated cards.
- **Surface Container High (`#E7EDF6`)**: Applied to inset cards, inactive track pills, search bars, and segmented tab tracks.
- **Text & Content**: Primary body content sits at `#0F172A` (off-black) for optimal crispness; secondary metadata, timestamps, and subtitles use `#64748B`.
- **System States**:
  - **Success (`#10B981`)**: Confirmed attendance ("Presente", "Verificado"), positive threshold rings (>80%).
  - **Absence / Error (`#D64545`)**: Unexcused absence ("Ausente"), critical attendance alerts (<75%).

## Typography

The typography system relies entirely on `Inter`, chosen for its technical precision, tall x-height, and superior legibility at small sizes on mobile displays.

### Hierarchy & Usage
- **Display & Headline Levels**: Reserved for statistical overview numbers (e.g., "94% Asistencia"), primary module views, and screen titles. Rendered in deep blue `#0F2557` to establish immediate structural authority.
- **Title Levels**: Used for course names (e.g., "Cálculo Integral", "Estructuras de Datos"), student full names in roster views, and modal sheet headers.
- **Body Levels**: Rendered in `#0F172A` for class notes, schedule details, and dialog copy. Secondary metadata (classroom codes, professor names, hours) defaults to `body-md` or `body-sm` in `#64748B`.
- **Label Levels**: Applied to status chips ("PRESENTE", "JUSTIFICADO"), tab bar items, uppercase metric identifiers, and CTA buttons.

## Layout & Spacing

The layout is built around a mobile-first, 4-column fluid grid system expanding to an 8-column layout on compact tablet devices.

### Margins and Ergonomics
- **Outer Canvas Margins**: 16px (`margin: 1rem`) on phone viewports; 24px (`margin-tablet: 1.5rem`) on horizontal or tablet surfaces.
- **Column Gutter**: 16px (`gutter: 1rem`) spacing ensures cards and multi-column action grids remain distinct without awkward density.
- **Touch Target Density**: All interactive components (FABs, check-in taps, status toggle chips) strictly observe Android's 48×48dp minimum touch target bounding box, even when visual badge footprints are smaller.
- **Bottom Clearance**: Screens with active bottom navigation include a baseline bottom content margin of 80px (`5rem`) to prevent floating buttons or fixed navigation bars from clipping card feeds.

## Elevation & Depth

Visual hierarchy conforms to Material 3 tonal elevation combined with soft, daylight-inspired ambient drop shadows. Surfaces elevate based on priority and user interaction layer.

### Elevation Hierarchy
1. **Level 0 (Surface Base)**: Hex `#F3F6FB`. Flat background for overall screen flow. No shadow.
2. **Level 1 (Default Cards & List Items)**: Hex `#FFFFFF`. Used for course cards, student attendance list tiles, and calendar blocks. Box shadow: `0px 2px 8px -2px rgba(15, 37, 87, 0.06), 0px 1px 3px rgba(15, 37, 87, 0.04)`.
3. **Level 2 (Active/Floating Elements)**: Hex `#FFFFFF` or Accent `#FFC62B`. Applied to sticky summary pills and the Floating Action Button. Box shadow: `0px 6px 16px -4px rgba(15, 37, 87, 0.12), 0px 2px 6px -1px rgba(15, 37, 87, 0.06)`.
4. **Level 3 (Modals & Bottom Sheets)**: Hex `#FFFFFF`. Modal sheets that slide over viewport context. Box shadow: `0px -8px 24px -6px rgba(15, 37, 87, 0.16)`.

## Shapes

The design system incorporates rounded, organic curves compliant with Android M3's rounded aesthetics, reducing sharp edges to create an approachable software environment.

### Geometric Rules
- **Course & Roster Cards**: 16px radius (`rounded-2xl` / 1rem base tier).
- **Bottom Sheets & Modal Dialogs**: 24px top radius (`rounded-3xl`) for sheet trays; 20px for dialog containers.
- **Chips, Badges, & Action Pills**: Fully pill-shaped (`9999px`) to distinguish categorical tags from rectangular data cards.
- **Form Inputs & Search Fields**: 12px corner radius (`rounded-lg`), blending structural stability with soft touchability.

## Components

### Buttons
- **Primary CTA ("Registrar Asistencia")**: Background `#FFC62B`, text `#0F2557` (Bold / `label-lg`), height 52dp, rounded-full or rounded-xl. Pressed state: subtle `#F5B813` with 10% dark blue ripple.
- **Secondary Action**: Background `#1A3D8F`, text `#FFFFFF`, height 48dp, rounded-xl. Pressed state: `#0F2557`.
- **Tonal / Outlined ("Justificar Falta")**: Background `#E7EDF6`, text `#1A3D8F`, height 44dp, 0px border.

### Floating Action Button (FAB)
- Material 3 extended FAB format: 56dp tall, corner radius 16dp (`rounded-2xl`).
- Accent Yellow variant (`#FFC62B` background with `#0F2557` icon and text label) positioned 16dp from the bottom-right edge above the bottom navigation bar.

### Status Chips & Badges
- **Presente**: Background `#ECFDF5` (`#10B981` at 10% tint), text `#059669`, with a 6dp green dot prefix.
- **Ausente**: Background `#FEF2F2` (`#D64545` at 10% tint), text `#DC2626`.
- **Clase en Curso**: Background `#FFC62B`, text `#0F2557`, pulsing 6dp blue indicator.
- **Tardanza / Justificado**: Background `#FFFBEB`, text `#D97706`.

### Cards (Course & Attendance)
- Background `#FFFFFF`, 16px padding, 16px corner radius, Level 1 ambient drop shadow.
- Left-side accent indicator bar (4dp width) colored `#1A3D8F` for standard schedules or `#FFC62B` for the actively running lecture.
- Secondary stats display attendance percentage with a high-contrast circular progress track (`#E7EDF6` unfilled, `#10B981` or `#1A3D8F` filled).

### Lists & Student Rows
- List item height 64dp. Background `#FFFFFF` separated by thin 1dp borders in `#F3F6FB`.
- Left: 40dp avatar circle with student initials in `#1A3D8F` on `#E7EDF6`.
- Center: Student name in `title-md` (`#0F172A`) and student ID / university code in `body-sm` (`#64748B`).
- Right: Single-tap toggle chip cycling states (Presente, Ausente, Justificado) with instant color feedback.

### Form Inputs & Search
- Container `#F3F6FB`, border 1dp solid `#E7EDF6`, corner radius 12dp.
- Text `#0F172A`, placeholder `#64748B`.
- Focused state: Border 2dp solid `#1A3D8F` with white background.
- Error state: Border 2dp solid `#D64545`, helper caption in `#D64545`.

### Bottom Navigation Bar
- Background `#FFFFFF` with top border 1dp `#E7EDF6`, height 64dp.
- 4 primary destinations: "Inicio", "Materias", "Historial", "Perfil".
- Active item indicator: Pill container `#E7EDF6` wrapping primary deep blue icon (`#1A3D8F`) with bold label in `#1A3D8F`. Inactive items rendered in `#64748B`.