# AGENTS.md — picking up development here

*For an AI agent, or a person arriving cold. Named `AGENTS.md` because that is
the filename the common coding agents look for without being told.*

**Read §1 before editing anything.** It is the one rule in this file that will
cost you work if you skip it.

---

## 1. The module file is VENDORED. Do not edit it here.

`music_module.html` is a **copy**. The original lives in the ButterflyDreaming
working tree at `M_DroneFrac/music_module.html`, and the copy here is refreshed by:

    ./sync_from_bd.sh

That is a **copy-down, not a merge**. It overwrites `music_module.html` and
discards anything you changed in it. `MODULE_SOURCE.txt` records which BD commit
the current copy came from.

So the workflow for a module change is:

1. edit `M_DroneFrac/music_module.html` in the BD repo,
2. commit and push there,
3. `./sync_from_bd.sh` here,
4. commit the refreshed copy here.

**What you MAY edit freely here:** `index.html` (the host page), `README.md`,
this file, `sync_from_bd.sh`. Those are this repository's own.

This is not bureaucracy. Two copies of an earlier module diverged in exactly
this way and polish landed in only one of them; the project has paid for the
lesson twice.

---

## 2. What this repo is

    index.html          the host page — ~146 lines of plain JS (87 code, 47 comment)
    music_module.html   the module, vendored (see §1)
    sources/            six CC0 pads + manifest.json + SOURCES.md — part of
                        the MODULE, not of the page (see §8)
    make_sample_pads.py builds the three Freesound pads
    make_organ_pads.sh  builds the three VCSL organ pads
    make_manifest.py    regenerates sources/manifest.json from the directory
    README.md           what the module does and how the figure is made
    sync_from_bd.sh     refresh the vendored copy from BD
    MODULE_SOURCE.txt   which BD commit that copy came from

No build step, no bundler, no server, no dependencies to install. **Open
`index.html` in a browser.** If you want a server for cache reasons,
`python3 -m http.server` in this directory is enough.

Published at <https://wrcstewart.github.io/ButterflyDreaming-Standalone-DroneFrac/> from `main`, root path.
Pushing to `main` redeploys; allow a minute or so.

---

## 3. The contract, and where it lives in the code

A ButterflyDreaming media module is **an iframe that speaks a handful of
`postMessage`s**. That is the whole integration surface — there is no SDK and
nothing to import.

| direction | message | meaning |
|---|---|---|
| module → host | `BD_READY` | loaded; send me a script |
| host → module | `bd_script_update` `{ script }` | the text to render |
| module → host | `bd_av_state` `{ text, fromDrift }` | its live script, on **every** render |
| module → host | `bd_module_log` `{ level, line }` | its console, forwarded out of the iframe |
| host → module | `bd_ui_config` `{ hideControls, hostChrome }` | optional; see §4 |

Two details in `index.html` are load-bearing and easy to undo by accident:

- **The message listener is attached BEFORE `frame.src` is set.** The module
  announces `BD_READY` the moment it loads; a listener added afterwards misses
  it and the page sits there empty. The `frame.src = ...` line is deliberately
  the last statement in the file.
- **`fromDrift` marks a frame a timer produced, not a person.** The host keeps
  a `live` variable that follows every frame, but only writes the textarea on
  non-drift frames — otherwise it fights anyone typing and destroys the undo
  history. **Copy reads `live`, not the textarea**, so it is never stale.

---

## 4. `bd_ui_config` — two flags that are NOT the same flag

    hideControls   the HOST supplies the stepper column; hide mine
    hostChrome     the host draws things AROUND this iframe (default TRUE)

BD reserves layout for furniture only BD draws — it stamps its ↓↑ arrows into
this module's dock slot, for which the grid holds a whole area. A host that
stamps nothing into that reserve gets it as lost picture. (This module has ONE
slot, where the two older music modules have two — its layout is the Kolam
shape, a visual area plus a single control column, not the music-panel grid.)

These were one flag until 2026-09-30 and had to be split, because the two cases
pull apart exactly here:

| | hideControls | hostChrome |
|---|---|---|
| BD itself | false | true |
| an Ancillary Viewer | **true** | false |
| **this page** | **false** | **false** |

A standalone wants the chrome released and the steppers **kept**. That
combination was unreachable before the split. `hostChrome` defaults to `true`
so a host that says nothing keeps BD's behaviour; `hideControls` implies it.

---

## 5. The script format, and the two rules that bind a renderer

Lines beginning `%%bd_` are directives; everything else is prose. A block
directive opens with `[` and closes on a line that is exactly `%%bd_]`.

**`_p_` asks for a control.** `%%bd_p_angle` means *give this one a stepper*;
`%%bd_angle` means *use this value and offer no control*. The mark is
**presentation only** — it never changes what a directive means, and a module
strips it before looking the value up.

- **RULE 1 — the writer reconstructs the form it read.** A script that arrived
  carrying `%%bd_p_angle` must be written back carrying `%%bd_p_angle`. Get
  this wrong and merely moving a stepper silently changes which controls exist.
- **RULE 2 — a script with no mark anywhere keeps every control.** Marking is
  opt-in, so nothing written before the convention changes behaviour.
- **RULE 9 — a module's default script carries no directive it cannot act on.**
  A directive in a default script is a promise the module keeps.

The full set (RULES 1–9) is in BD's `CollagePlanStarted_2026-09-22.md`.

---

## 6. Preparing something for ButterflyDreaming

If you build a new module, or change this one in a way BD must see, this is the
checklist. **A new module needs FOUR registries and nobody has ever remembered
all four unprompted.**

### 6.1 The four registries (all in the BD repo)

| what | where |
|---|---|
| `MODULES` — embedded + standalone URLs | `viewer.js` (~line 2783) |
| `AV_VIEWER_MODULES` — which modules have a viewer page | `viewer.js` (~line 13297) |
| `AV_RENDERERS` — module id → renderer path | `AV/kolam.html` (~line 149) |
| `express.static` route — `/bd_X/` → the source dir | `server.js` (~lines 163–205) |

Note the route name and the directory name differ on purpose: `/bd_M_ABC/`
serves `./M_Music/`. Do not "fix" that.

### 6.2 The database side

Memgraph, reached through `node bd_tool.js` at the BD repo root.

    node bd_tool.js cypher "MATCH (n) WHERE n.name STARTS WITH 'bd_V_Kolam3D' RETURN n.name, n.seq, n.hasModuleScript"

A module occupies three kinds of node: a **Cluster**, a **gateway** TextNode
carrying `seq = -1`, and one or more **content** TextNodes carrying
`hasModuleScript = '<module id>'` and `seq >= 1`. The content node's text IS the
default script.

**Every DB-mutating `bd_tool.js` subcommand takes a pre-flight backup by
default. Do not pass `--no-backup`.**

**Editing stored text does not reach a running BD.** Node text loads with the
graph at boot, so re-tapping a node shows the stale copy. After a DB edit, say
so: *reload BD*.

### 6.3 Cache-busters and canaries

- `AV/kolam.html` loads renderers as `AV_RENDERERS[m] + '?v=NN'`. **Bump `NN`
  on any change to a module.** iOS Safari caches an iframe `src` hard, and a
  stale renderer means layout fixes silently never arrive.
- BD, the AV and `sr_editor` each host their **own** canary — a visible border
  rotating red → green → blue on every change to a cached file. They are
  independent; one says nothing about another.
- **THIS MODULE HAS ITS OWN**, unlike the other media modules: the **Play
  button's background colour**, declared in `music_module.html`'s stylesheet.
  Rotate it on every change to the module. It was added after three rounds were
  lost to "is this my edit or a cached copy", and it earns its keep — but note
  what it does NOT cover: a canary certifies **the file it lives in**. The HTML
  can be demonstrably current while the audio it pulls is stale, which is why
  the sample URLs carry a content hash as well.
- A module change still needs BD's canary rotated and the AV's `?v=` bumped,
  because BD serves this module to its own users.

### 6.4 Two-phase deploy

**Receivers before writers.** A renderer must be able to READ a new form before
anything WRITES one. A new module ships as a receiver from day one.

---

## 7. BDX / AVX / RX — the next stage

There is a second, independent harness, and it is where this repo's ideas grow
up. Repo <https://github.com/wrcstewart/bdx-demo>, local checkout
`~/bdx_demo`, pages <https://wrcstewart.github.io/bdx-demo/>.

| | what it is | where it runs |
|---|---|---|
| **BDX** | the controller — script panel, steppers, renderer | GitHub Pages (static) |
| **AVX** | the viewer — renders what it is told, no controls | GitHub Pages (static) |
| **RX** | the relay — a rendezvous for two browsers on different devices | a Node host |

RX is **live** at <https://rx.virtualfictions.uk/health>, on the existing
Discourse VPS behind a Cloudflare tunnel.

**The claim it makes:** the module architecture needs nothing of BD — no
Memgraph, no corpus, no graph, no pairing, no curation, no speech. And the
dependency ladder is worth stating precisely, because it is easy to overclaim
in either direction:

1. **Same machine → no server at all.** If the controller *opened* the viewer it
   holds a window handle, and `postMessage` reaches it, cross-origin included.
   Measured at **~1 ms, against ~30 ms through a socket**.
2. **Cross-device → a rendezvous is unavoidable.** Two browsers on two devices
   cannot reach each other; no window handle exists. That is the *only* reason
   the socket path exists in BD at all.
3. **Whose rendezvous is a free choice.** Run RX yourself (~10 lines around
   `bd_relay.js`, no account), or point at ours.

**How this page relates to it.** This repo is a BDX with the relay left out:
script panel, steppers, renderer, on a URL, no corpus. The next step for any of
these four pages is the same one — **add a View button** that opens an AVX and
drives it. Same machine needs no relay at all (tier 1), which makes it a genuinely
small change: claim the window *inside the click* (see §8), then `postMessage`
the script to it on every `bd_av_state`.

`AV/bd_av_client.js` in the BD repo (414 lines) is the viewer shim and **is the
third-party contract** — the artifact someone else would use.

---

## 8. Traps already paid for

Each of these cost a debugging round. They are not hypothetical.

- **A gesture does not survive an `await`.** `window.open` and clipboard writes
  are both refused after one. Claim the resource *inside* the click — open
  `about:blank` first and navigate later; hand the clipboard the *promise*.
  Safari refuses what Chrome allows. `index.html`'s Copy button has a
  select-the-text fallback for exactly this.
- **A missing asset fails silently.** The module loads its pads from
  `sources/`, listed in `sources/manifest.json`. If a pad 404s, `Tone.loaded()`
  never resolves, `bufferReady` stays false and **Play simply never enables** —
  while every control that needs only the script text behaves normally. It reads
  as a broken audio library and is a missing file. `sync_from_bd.sh` copies the
  samples with the module for this reason.
- **A sample URL must be versioned.** The module requests
  `sources/<file>?v=<hash>` from the manifest. Without it a rebuilt pad can go
  on sounding like the old one indefinitely, behind a browser or a CDN — with
  the canary saying the page is current, so you doubt your edit rather than the
  cache. Cost a round exactly that way.
- **Copying a file copies its claims.** Three of these four hosts were spliced
  from the fourth, and shipped six comments true only of the origin — one of
  which was a layout bug wearing a comment's clothes. After generating siblings
  from a template, read each against *the thing it now describes*. Grep the
  copies for the origin's proper nouns.
- **`node --check` parses as CommonJS** and silently passes ES-module errors.
  For an HTML file, extract the `<script>` body and check that.
- **A check whose filter excludes the failing pattern proves nothing.** Said
  after a "clean" grep reported four broken call sites as fine.
- **Test the path, not a stage of it.** A regex bug survived a test that ran on
  raw text and so never reached the normaliser that caused it.
- **iOS inputs below 16px auto-zoom on focus.** Every focusable input needs
  `font-size: 16px` or larger.

---

## 9. Developments worth trying

Ordered roughly by ratio of interest to effort. None is started.

### Load your own sample  *(the one to do first)*

Everything bundled is CC0 because the pads are **redistributed**, and that rules
out most sample libraries — a "royalty-free" licence governs royalties and
usually forbids passing the file on. See §8 and `sources/SOURCES.md`.

A **local file load** sidesteps that entirely: the user grants a file, nothing is
bundled, and anyone can granulate material we could never ship.
`decodeAudioData` on a `File` is a few lines, and `Tone.GrainPlayer` takes a
buffer directly.

The care needed is honesty about reproduction. A granular drone IS its source
file, so a script naming a local sample reproduces **nothing** elsewhere. RULE 9
says a module's script carries no directive it cannot act on — so a local load
should be visibly a private experiment, not a `%%bd_sample` value that looks
shareable and is not.

### The grain parameters are NOT Signals — know this before adding modulation

`detune`, `grainSize`, `overlap` and `playbackRate` are **plain numbers** in
Tone 14, not Signals. You cannot connect an LFO to any of them; the docs read as
though you can and the source says otherwise. They are read when a grain FIRES,
so a write lands at the next grain and the effective modulation rate is
`1/grainSize` — five a second at the 0.2 default.

That is why the trajectory is **scheduled** rather than connected, and why there
are no LFOs here. For drone-speed movement five steps a second is far finer than
the ear resolves, and the lever if it ever is not is a **smaller grainSize**,
not another oscillator. Downstream is the opposite: everything in the effects
tail IS a Signal, so that is where smooth modulation belongs.

### A second trajectory destination

`playbackRate` is the obvious one left. Pitch (`detune`) and position
(`playbackRate`) are independent in granular — that is the whole point of the
technique — and only pitch is currently driven by the walk. Letting the walk
also steer *where in the sample* it is reading would give a second axis of
travel, and the turtle already has information to spare: direction of travel,
depth in the string, position within a run.

### Velocity, or rather amplitude per grain

Every grain currently sounds at the same level. `Tone.GrainPlayer` has no
per-grain gain, so this would mean scheduling a `Tone.Gain` alongside the
trajectory — slightly awkward, and the single biggest change available to how
mechanical it sounds.

### A third channel, and a chord of the walk

`offsetCH2` reads the walk at one offset, two octaves up. A third at a different
offset and interval would make it a genuine triad built from one walk. The
constants to generalise are `CH2_CENTS` and the single `grain2`.

### Bake is the least-tested path in the module

`Tone.Offline` with the offline context's own transport. It is written and
verified against Tone's documented pattern, but if anything here is broken this
is where to look first.

## 10. Where the rest of the knowledge is

The BD repo is the source of truth for everything above.

| | |
|---|---|
| `DOCS_INDEX.md` | what each of ~40 docs *is* |
| `PLANNING_REGISTER.md` | how far each design is *built*, evidence-based, ending in every unbuilt item in one table |
| `CHANGELOG.md` | newest-first narrative log; the friendly read |
| `CollagePlanStarted_2026-09-22.md` | the `%%bd_p_` convention and RULES 1–9 |
| `BDX_DEMO_PLAN.md` | §7 above, in full |
| `AV/README.md` | the Ancillary Viewer, and the 1 ms vs 30 ms measurement |

**Start with the two indexes.** They exist so that an arriving agent does not
have to grep.

### Known inconsistency, not yet fixed

`bd_M_DroneFrac` is in BD's `MODULES` table with an `embedded` entry only — no
`page` entry pointing at THIS repository, because the repo did not exist when
the module was registered. Adding it is one line in `viewer.js`.

Separately, `standalone` for the three older modules still points at the
retired `preview.html` pages. See the note on `page` versus `standalone` in
`MODULES` before touching either: they are not two names for the same thing.

---

*Licence CC0. Do what you like with it.*
