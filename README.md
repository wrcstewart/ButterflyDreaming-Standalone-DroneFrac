# DroneFrac — a granular drone steered by an L-system

One media module from [ButterflyDreaming](https://butterflydreaming.org),
running on its own. Open `index.html` — there is no build step, no bundler and
no server.

**[butterflydreaming.org](https://butterflydreaming.org)** · CC0

---

## What it does

A sustained sample never stops sounding. It is chopped into **grains** — short
fragments, a fifth of a second or so — and an L-system walk steers them.

    the walk's height          ->  the grains' PITCH
    the length of its runs     ->  the grains' SIZE

Those are two independent destinations, and that is the whole reason this module
exists. Its sibling `bd_M_Fractal` walks the same kind of turtle but funnels
everything through an ABC score, where duration and pitch arrive welded
together. Here there is no notation in between to collapse them.

A second channel reads the **same walk at an offset**, two octaves up — so at
any moment you are hearing two places in the same walk at once. That is a chord
the grammar builds out of itself, not a canon.

---

## Granular synthesis, briefly

Play a tape slowly and it drops in pitch: speed and pitch are the same physical
thing. Granular breaks that. Chop the sound into fragments and play a stream of
them, and two decisions separate:

- **where** each grain is taken from — how fast you travel through the sound
- **how fast the grain itself plays** — the pitch

So you can stand still inside a sound and change its pitch, or wander through it
without changing pitch at all.

**Grain size is not a quality setting** — it changes what kind of thing you hear:

| grain size | grain rate | what you hear |
|---|---|---|
| 0.5–1.0 s | 1–2 /sec | recognisable slices of the original |
| 0.1–0.3 s | 3–10 /sec | texture — the source implied, not stated |
| 0.03–0.05 s | 20–30 /sec | shimmer, a fluttering edge |
| **0.02 s** | **50 /sec** | **the grain rate itself becomes a pitch** |

That last row is the striking one: at 50 grains a second the repetition rate is
audible as a tone, manufactured purely by the chopping and not present in the
sample.

**Overlap** is the crossfade between successive grains. Low, and you hear the
cuts — gritty and rhythmic. High, and they smear into a cloud. It is the most
character-defining control here.

---

## What makes a sample work

Granular repeats and overlaps material constantly, so a transient comes round
on every pass as a pulse you never asked for. The test is **steadiness**: window
the RMS and look at the spread. Under about 4 dB is good; over 10 and you are
granulating events rather than texture.

Every bundled sample is **CC0**, and `sources/SOURCES.md` records for each one
where it came from, what was done to it, and the measurements. Three are built
from organ notes in the [Versilian Community Sample Library](https://github.com/sgossner/VCSL);
three are built from [Freesound](https://freesound.org) pads. Both build scripts
ship, so every pad can be rebuilt from scratch — a derived work nobody can
rebuild is one whose licence cannot be checked.

**Two findings from making them, in case they save you time.**

**The registration matters more than the octave.** The organ pads were first
built on a "Full" mixture stop and dropping their nominal octave barely changed
what you heard — a mixture keeps most of its energy in partials well above its
nominal pitch. The 8′ rank has four times the low-end weight. Measured on one
note, share of energy at or below C2: Full 10.9%, 8′ **46.3%**, 4′ 2.9%.

**Loop length is a musical choice, not a technical one.** A short loop recurs
often, and each time the detuned voices stand in a slightly different relation —
theme and variation, which the ear follows. A loop longer than the piece is
heard once and never recurs: nothing to recognise, so nothing develops. The
seam-free 64-second loop is musically the *weakest* of the six.
**Steadiness measures suitability, not interest.**

---

## The output stage

Four controls sit after the effects, and they are `_p_` marked like everything
else — which means **they are written into the script and travel with it**:

    %%bd_p_volume   -40 .. +6 dB
    %%bd_p_bass     -12 .. +12 dB   (shelf below 250 Hz)
    %%bd_p_treble   -12 .. +12 dB   (shelf above 3 kHz)
    %%bd_p_balance   -1 .. +1       (left .. right)

That is the whole reason they exist. A drone is usually played *against*
something — speech, another module, a recording — and a balance you cannot
write down has to be found again every time. Saved in the script, a setting
that worked once can be returned to.

Signal order is `reverb → EQ → pan → volume → limiter → out`. EQ before the
limiter, so a boost is caught by the ceiling rather than clipping; volume after
the EQ, so the fader means what it says whatever the tone controls do; the
limiter last, always, because it is the only thing between grain summing and a
clipped output.

The spectrum display taps **after** the output stage, so what you see includes
the tone controls. Bake applies the same four, so a saved `.wav` is the thing
you balanced.

---

## Export

**.wav only**, via Bake then Save wav. There is no interchange format for a
granular patch — every tool uses its own, and [SDIF](https://en.wikipedia.org/wiki/SDIF)
describes analysed sound rather than a patch. MIDI is the wrong shape: it
carries notes, and this has none.

The **script** is the portable form, as everywhere else here — with one
condition peculiar to this module. A granular drone *is* its source file, so a
shared script reproduces nothing without the sample it names. That is why
`%%bd_sample` names a slug from `sources/manifest.json` rather than a filename,
and why the provenance record is not a courtesy but part of what makes a shared
script mean the same thing at both ends.

---

## For a developer: what a module has to do

A ButterflyDreaming media module is **an iframe that speaks four messages**.
That is the entire contract.

| direction | message | meaning |
|---|---|---|
| module → host | `BD_READY` | loaded; send me a script |
| host → module | `bd_script_update` `{ script }` | the text to render |
| module → host | `bd_av_state` `{ text, fromDrift }` | its live script, on **every** render |
| module → host | `bd_module_log` `{ level, line }` | its console, so a host can see inside the iframe |

There is a fifth, optional in both directions: `bd_ui_config`
`{ hideControls, hostChrome, hostScriptPanel }`, which lets a host say *I supply
the controls myself*, *I draw nothing around this iframe*, and *I show the
script with my own copy control, so hide yours*. Three independent assertions,
deliberately not one: `controls-hidden` used to carry two meanings at once and
had to be split, and a flag should assert one thing. Both default to BD's own
behaviour, so a module that ignores the message still works everywhere — but
this page sends `hostChrome: false`, because BD reserves layout for furniture
that only BD stamps in, and a standalone that kept the reserve would be giving
away picture for nothing.

Answer `bd_script_update`, announce `bd_av_state`, and **any** ButterflyDreaming
host can drive your module — this page, or BD itself, or a viewer on another
device. Nothing else is required.

`index.html` is a complete host in about 145 lines of plain JavaScript —
88 of code and 46 of comment — written to be read. Two details in it are worth stealing:

- **Attach the message listener before setting the iframe's `src`.** The module
  announces `BD_READY` the moment it loads, and a listener added afterwards
  misses it.
- **`fromDrift` marks a frame the module's own timer caused**, not a person. A
  host that writes every frame into a text box will fight anyone typing in it.
  This page tracks those frames in a variable so **Copy** is never stale, while
  the box itself only updates on a human change.

### Deliberately absent: deep links

Earlier standalones packed the whole script into a URL. That meant compression,
a wire table of abbreviated keys, and a length ceiling to measure against — a
great deal of apparatus standing between a reader and how a module actually
works. It is gone. Copy the script and paste it wherever you like.

---

## The script format

Lines beginning `%%bd_` are directives; everything else is prose. A block
directive opens with `[` and closes on a line that is exactly `%%bd_]`.

    %%bd_module bd_M_DroneFrac
    %%bd_p_sample vox_pad_dmin7
    %%bd_axiom X
    %%bd_rule X: FYFX+F+YFXFY-F-XFYFX
    %%bd_p_iterations 6
    %%bd_angle 90
    %%bd_p_grain_size 0.45

**`_p_` asks for a control.** `%%bd_p_grain_size` means "give this one a
stepper"; `%%bd_grain_size` means "use this value and offer no control" — which
is exactly what `%%bd_angle` above is doing. The mark is
presentation only — it never changes what a directive *means*, and a module
strips it before looking the value up.

Two rules a module must honour:

1. **The writer reconstructs the form it read.** A script carrying
   `%%bd_p_angle` must come back carrying `%%bd_p_angle`, or a value update
   would quietly change which controls appear.
2. **A script with no mark anywhere keeps every control.** Marking is opt-in, so
   nothing written before the convention existed changes behaviour.

---

## Keeping this copy honest

`music_module.html` and `sources/` are **vendored** — a copy of the module as it stands in
ButterflyDreaming's own repository. That is deliberate: a developer should be
able to open it, read it and break it without a server.

The cost of vendoring is drift, and it has bitten this project before — two
copies of an earlier module diverged and polish landed in only one of them. So
the copy is refreshed by one deliberate command rather than by hand:

    ./sync_from_bd.sh

It overwrites `music_module.html` AND the sample set from the BD working tree,
and records which commit they came from in `MODULE_SOURCE.txt`. **If you have changed the module
here, that command will discard your changes** — it is a copy-down, not a merge.

---

## Picking up development

`AGENTS.md` in this repository is the working guide: what may and may not be
edited here, how to prepare a change for ButterflyDreaming, the BDX/AVX/RX
harness, and a list of developments worth trying. Start there.

---

## Licence

CC0. Do what you like with it.
