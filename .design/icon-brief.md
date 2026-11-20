# Icon brief: Dužy

## The product in one line

Dužy is a minimalist offline strength-training tracker for iPhone: your program, your sets, your progress, and nothing else. No accounts, no subscriptions, no feed. The full context is in `design-brief.md`; the visual language is the chosen direction "Plates, large" (`system/Color`, `system/Type`).

## The name

- **Dužy** is Belarusian in the Latin alphabet (Łacinka): «дужы» means *strong, sturdy*.
- To an English reader it sounds like *doozy* — something outstanding. One word carries both: strength for a Belarusian, "a big one" for the world.
- The ž inside the word is the trace of the language; it belongs to the name, not to the icon.
- Plain-ASCII contexts (file names, URLs, search) use `duzy`; the home screen label and the App Store use **Dužy**.

## Why the current icon goes

Variant A "Small step" is a macro shot of the bar end with a small plate. At home-screen and Settings sizes the stick with a disc on the end reads as a toilet plunger. It also has no link to the name.

## Core idea

**A loaded barbell bending under its weight.**

- A heavy bar visibly whips: the ends dip under the plates. That bend is the whole story of the name — the bar bends because the weight is serious, and you are the one who is strong.
- The bar is seen whole, from the front, with one plate on each end, bent into a shallow V or arc. Seeing both ends and both plates is what keeps it from reading as a plunger.
- Plates in IWF colors from `system/Color` — red (25 kg) or blue (20 kg). One color on both ends reads cleaner than two.
- Background: the app's paper and ink, not a gradient. Light: `background` #F3F2EF with the bar in `ink` #151515. Dark: `background` #111214 with the bar in `ink` dark #F2F1EE.
- The bend should be clearly intentional and confident, not a sagging or broken bar. The plates carry the weight; the bar shows it.

## No letters

The icon has **no letters**. A lone Z (or Ž) on a square reads as the Russian military "Z" symbol, and Ž at the start of a word recalls the slogan "Žyve Belarus". A training tracker must carry neither association. This is also why the name moved from Žym to Dužy.

## Explorations

Show at most two alternatives next to the main direction, each with one line on why it is weaker. For example:

- a deeper or a gentler bend, or the bar cropped by the icon edges so only the bend and the inner plates show;
- the bent bar on a plate-colored background instead of paper or ink.

Stay on the bending bar. No new concepts beyond that.

## Requirements

- Reads at every size: 1024, the home screen, Settings and Spotlight (40 pt and below). At the smallest sizes the plates and the bend must still be visible; drop detail (collars, sleeve grooves) before it turns into noise.
- iOS 26 appearances: default, dark, tinted, and clear if Icon Composer offers it. The tinted version is a silhouette, so the mark must work in one color.
- Layered for Icon Composer (`.icon`): background, bar, plates as separate layers. Liquid Glass highlights and shadows come from the system; don't paint them in.
- Colors only from the design system tokens: palette, IWF plate colors, `record` yellow if needed as an accent.

## Don't

- Letters of any kind, especially Z or Ž (see "No letters").
- Anything from "Requirement #1" of `design-brief.md`: purple or sunset gradients, glow, glassmorphism painted into the art, 3D blobs, neon on black, aggressive italics.
- A stick with a cup or disc seen end-on — the plunger problem.
- Clip-art: dumbbells, a flexed biceps, flames, lightning bolts.

## Deliverables

Update the `screens/AppIcon` board on the canvas:

- the chosen icon at 1024 in default, dark and tinted;
- a small-size test: 180 / 120 / 87 / 58 / 40 px;
- a home-screen mockup next to system icons, light and dark, with the label "Dužy";
- the layer breakdown for Icon Composer;
- the alternatives, each with one line on why not.

After the icon is approved the app is renamed to Dužy (home-screen name, strings, backup file prefix, README); see `docs/roadmap.md`.
