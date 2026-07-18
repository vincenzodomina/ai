---
name: write-html-diagram
description: Use when the user wants a diagram delivered as a self-contained HTML file — architecture diagram, flow chart, pipeline, sequence, or user journey — or asks to repair visual mismatches (arrows not reaching boxes, misaligned lanes, broken labels) in an existing HTML diagram.
---

# Write HTML Diagram

Produce a single self-contained `.html` file where the diagram is the deliverable: boxes laid out with CSS grid, connectors drawn as SVG from *measured* geometry, verified by actually rendering the page. Applies to architecture diagrams, flow charts, pipelines, and user journeys alike — only the lane semantics change.

## Steps

1. **Ground the content.** Read the real sources first (docs folder, code, prior conversation). Never invent specifics (standard names, endpoints, field names); if something plausible can't be confirmed, either omit it or flag it to the user as unconfirmed. The diagram must survive review by someone who knows the system.

2. **Find the one claim.** Every good diagram argues a single thesis ("everything passes through the core store", "time flows left → right on the platform foundation"). Write it down; the layout must *encode* it — e.g. every arrow crossing the core, or a foundation band under the whole timeline. Detail that doesn't serve the claim becomes a small labeled hint or is cut.

3. **Sketch a token plan before coding.**
   - One semantic color per role/lane (e.g. external system, ingest/write path, core store, compute/read path) — used consistently for box borders, arrows, labels, and legend.
   - Boxes: flat 1px border in the role color + very light wash of the same hue. No accent bars, no heavy shadows.
   - Type: system sans for text, monospace for identifiers, codes, endpoints, field names. No CDN webfonts (CSP or offline use → silent fallback).
   - Chrome stays minimal: small mono eyebrow, one modest headline line, a legend. No hero, no sub-headline paragraph — the diagram is the page.

4. **Build the layout** using the mechanics reference below: named-line CSS grid for boxes, one JS-drawn SVG layer for every connector.

5. **Verify by rendering — mandatory.** Never ship on a read-through of the code.
   - Render headless (Playwright + bundled Chromium), full-page screenshot, and *look at it*.
   - If anything is off, don't guess from the fuzzy image: probe with `page.evaluate` + `getBoundingClientRect` to get exact positions/widths of the suspect elements, then fix the root cause.
   - Pass criteria: every arrow endpoint touches its box edge; labels are shrink-wrapped chips (not full-width); lanes align column-for-column; legend swatches match the real box styles; no horizontal body scroll (wide diagram scrolls inside its own `overflow-x: auto` container).
   - Re-render after every fix until clean.

## Layout mechanics (reference)

**Grid.** One CSS grid with *named column lines* shared by all lanes (top row of stages, bottom platform band re-declares the same template), so upper boxes and lower blocks align by construction. Use `row-gap` as vertical runway for connectors. `min-width` on the diagram + `overflow-x: auto` on its wrapper.

**Connectors — never hand-place them.** Fixed pixel offsets and CSS pseudo-element triangles drift the moment any box changes height. Instead:

- One absolutely-positioned SVG layer (`position: absolute; inset: 0; pointer-events: none`) over the diagram; arrowheads as `<marker>` defs per color.
- Declare connectors as **data** (source id, target id, direction, color, label text), render them in a loop — never as bespoke markup per arrow.
- Compute every path endpoint from `getBoundingClientRect()` of the actual boxes, relative to the diagram container. Arrow tips land exactly on box edges.
- Redraw on `resize`, `document.fonts.ready`, and a `ResizeObserver` on the diagram, so connectors always match the *settled* layout.
- Labels: separate absolutely-positioned HTML chips (`transform: translate(-50%,-50%)`, `white-space: nowrap`, surface background) placed at path midpoints, so they read cleanly over lines.

**Legend correctness.** Legend swatches must use *exactly* the border + background styles of the boxes they stand for, and state what arrow directions mean (e.g. `↓ write into store · ↑ read/poll`). A legend that doesn't match the diagram is a bug.

## Failure modes (each one shipped a broken diagram before this rule existed)

- **Class collision**: a color-modifier class (`.entity` on a label) sharing a name with a container class (`.entity` on the band) makes the label inherit the whole container ruleset — giant stray boxes, duplicated `::before` badges. Namespace containers distinctly (`.entity-core`) from modifiers; resolve JS targets by `id`, never by a reused class.
- **Measurement feedback loop**: the SVG layer inflates the diagram's own `scrollWidth`, corrupting the next draw. Hide the layer (`display: none`) during measurement, restore after.
- **Trusting the first paint**: measuring before fonts/reflow settle leaves arrows a few px off. The ResizeObserver + `fonts.ready` redraw is not optional.
- **Eyeball-only review of source**: alignment bugs are invisible in code and obvious in a screenshot. Render-verify is a step, not a nicety.
- **Prose creep**: headlines, ledes, and explanatory paragraphs accumulate until the diagram is below the fold. Cut to eyebrow + one headline + legend if really necessary, prefer plain diagrams to reduce noise; move explanation into small labels *on* the diagram.
- **Invented detail**: filling gaps with plausible-sounding specifics (e.g. a standards list the system doesn't implement). Ground or flag.

## Iteration

Diagrams evolve through user feedback ("add X as a small hint", "remove the accent style"). Because connectors are data + measured drawing, structural edits (new boxes, taller blocks, new lane rows) need no arrow rework — add the box, add one connector entry, re-render, verify. If an edit *does* require touching arrow coordinates by hand, the structure is wrong; fix the structure.
