# Icon brief: Žym

## The product in one line

Žym is a minimalist offline strength-training tracker for iPhone: your program, your sets, your progress, and nothing else. No accounts, no subscriptions, no feed. The full context is in `design-brief.md`; the visual language is the chosen direction "Plates, large" (`system/Color`, `system/Type`).

## The name

- **Žym** is Belarusian in the Latin alphabet (Łacinka): «жым» means *press*, as in «žym ležačy», the bench press.
- To an English reader it sounds almost like *gym*. One syllable carries both: the gym for the world, the main lift for a Belarusian.
- The háček over the Z is the trace of the language. It must not get lost, shrink into a speck or turn into decoration.
- Plain-ASCII contexts (file names, URLs, search) use `zym`; the icon and the home screen label use **Žym**.

## Why the current icon goes

Variant A "Small step" is a macro shot of the bar end with a small plate. At home-screen and Settings sizes the stick with a disc on the end reads as a toilet plunger. It also has no link to the name.

## Core idea

**The háček is a loaded barbell bending under weight.**

- A heavy bar visibly whips: the ends dip under the plates. Drawn as a mark, that bend is a shallow V — exactly the háček over the Z.
- Above: a bar with one plate on each end, bent into a shallow V. Plates in IWF colors from `system/Color` — red (25 kg) or blue (20 kg); one color on both ends reads cleaner than two.
- Below: a large **Z**. Start from Sofia Sans Condensed SemiBold (the app's numeral and heading font); redrawing the letter for the icon is welcome if it holds the character.
- Together they read as the letter **Ž** first and as a barbell on a second look. The joke should be found, not explained.
- Background: the app's paper and ink, not a gradient. Light: `background` #F3F2EF with `ink` #151515 for the Z. Dark: `background` #111214 with the Z in `ink` dark #F2F1EE.

## Explorations

Show at most two alternatives next to the main direction, each with one line on why it is weaker. For example:

- the bent bar alone as a standalone mark, without the Z;
- the Z and the bar in a different balance (a heavier bar, a narrower Z, the bar overlapping the letter).

Stay on the name and the bar. No new concepts beyond that.

## Requirements

- Reads at every size: 1024, the home screen, Settings and Spotlight (40 pt and below). At the smallest sizes the plates and the V must still be visible; drop detail before it turns into noise.
- iOS 26 appearances: default, dark, tinted, and clear if Icon Composer offers it. The tinted version is a silhouette, so the mark must work in one color.
- Layered for Icon Composer (`.icon`): background, Z, bar, plates as separate layers. Liquid Glass highlights and shadows come from the system; don't paint them in.
- No text other than the Z.
- Colors only from the design system tokens: palette, IWF plate colors, `record` yellow if needed as an accent.

## Don't

- Anything from "Requirement #1" of `design-brief.md`: purple or sunset gradients, glow, glassmorphism painted into the art, 3D blobs, neon on black, aggressive italics.
- A stick with a cup or disc seen end-on — the plunger problem.
- Clip-art: dumbbells, a flexed biceps, flames, lightning bolts.
- A faceless Z monogram that could belong to a bank or a crypto wallet.

## Deliverables

Update the `screens/AppIcon` board on the canvas:

- the chosen icon at 1024 in default, dark and tinted;
- a small-size test: 180 / 120 / 87 / 58 / 40 px;
- a home-screen mockup next to system icons, light and dark;
- the layer breakdown for Icon Composer;
- the alternatives, each with one line on why not.

After the icon is approved the app is renamed to Žym (home-screen name, strings, backup file prefix, README); see `docs/roadmap.md`.
