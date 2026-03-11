# Lovable prompt: Fix app crash after Construction & Envelope was added

**Use this when:** The app no longer loads any page after Lovable added the Construction & Envelope tab and `ConstructionEnvelopeSection` component. The goal is to **restore a working app first**; we can re-add Construction & Envelope more carefully later.

**Related:** [LOVABLE-PROMPT-RESTORE-CONSTRUCTION-ENVELOPE-TILE.md](LOVABLE-PROMPT-RESTORE-CONSTRUCTION-ENVELOPE-TILE.md) — original prompt. This doc is for **recovery** when that change broke the app.

---

## Prompt to paste into Lovable (revert and restore app)

```
The app is broken and does not load any page after adding the Construction & Envelope tab and ConstructionEnvelopeSection component. We need to restore the app to a working state immediately.

Please do the following:

1. **Revert PropertyDetail.tsx**
   - Remove the import of ConstructionEnvelopeSection.
   - Remove the "Construction & Envelope" tab trigger and its TabsContent.
   - Set the Tabs defaultValue back to "building-systems" (not "construction").
   - Restore the TabsList to only: Building Systems, End-Use Nodes, Meters, IoT (Sensors & Devices).

2. **Remove or fix ConstructionEnvelopeSection.tsx**
   - Either delete the file `src/components/property/ConstructionEnvelopeSection.tsx` entirely, or
   - If you keep it, ensure it is valid TSX: no literal backslash-n (\\n) in the source, no escaped quotes inside JSX, all brackets and braces balanced, and all imports (e.g. Building, Card, Button, etc.) present and correct. The file must export a default or named component that accepts at least `propertyId` and renders without throwing.

3. **Verify**
   - The app must load again: at least the landing or login and the property detail page with the Physical & Technical tab showing Building Systems, End-Use Nodes, Meters, IoT. No white screen and no console errors that prevent render.

Do not re-add the Construction & Envelope tab until the app is loading. We will add it again later with a minimal, safe implementation.
```

---

## If you prefer to fix the component instead of reverting

If you want to keep Construction & Envelope but fix the crash, paste this **instead** of the revert prompt:

```
The ConstructionEnvelopeSection component is causing the app to crash (app does not load any page). The component file may contain invalid syntax: e.g. literal backslash-n (\\n) instead of real newlines, or escaped quotes inside JSX that break parsing.

Please:

1. Open src/components/property/ConstructionEnvelopeSection.tsx and fix it so it is valid TypeScript/TSX:
   - No string literals that contain \\n or \\" as literal characters in the source code; use real newlines and real quotes.
   - All JSX properly closed; all imports (Building, Card, CardContent, Button, Badge, etc.) from the correct paths and used correctly.
   - The component should be a normal function component that takes propertyId and returns JSX, with useState for draft/edit state and localStorage for persistence. No IIFE or eval-style code.

2. Ensure PropertyDetail.tsx imports ConstructionEnvelopeSection correctly and that the TabsContent for "construction" renders <ConstructionEnvelopeSection propertyId={property.id} />.

3. If the app still crashes, remove the Construction & Envelope tab and the ConstructionEnvelopeSection import from PropertyDetail, set default tab back to "building-systems", and delete ConstructionEnvelopeSection.tsx so the app loads again.
```

---

## After the app loads again

- Confirm you can open a property and see the Physical & Technical tab with Building Systems (and other sub-tabs).
- To add Construction & Envelope again later, use a **minimal** prompt: e.g. a single new tab that renders a placeholder card (“Construction & Envelope – coming soon”) or a very small component with one or two fields, then iterate. Avoid pasting large blocks of pre-written code into Lovable in one go.
