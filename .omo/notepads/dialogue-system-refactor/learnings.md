# Dialogue System Refactor — Learnings

## Wave 1 — Task 1: DialogueChoice Resource (2026-06-25)

- Created `scripts/dialogue_choice.gd` — pure data Resource class
- Pattern: `extends Resource` + `class_name DialogueChoice` + `@export var` fields
- Fields: `text: String = "`, `next_index: int = -1`
- No methods, no `_init()`, no extra fields — intentionally minimal data carrier
- Follows existing Resource conventions in codebase (`inventory.gd`, `item_data.gd`)

## Wave 1 — Task 2: DialogueNode Resource (2026-06-25)

- Created `scripts/dialogue_node.gd` — pure data Resource class representing one node in a dialogue tree
- Pattern: `extends Resource` + `class_name DialogueNode` + `@export var` fields
- Fields: `speaker: String = ""`, `text: String = ""` (multiline), `portrait: Texture2D` (nullable), `next_index: int = -1`, `choices: Array[DialogueChoice] = []`
- `@export_multiline` used for `text` to enable multi-line editing in the inspector
- Typed array `Array[DialogueChoice]` references the DialogueChoice Resource created in Task 1
- No methods, no `_init()`, no runtime logic — minimal data carrier, consistent with Wave 1 approach

## Wave 1 — Task 3: DialogueTree Resource (2026-06-25)

- Created `scripts/dialogue_tree.gd` — pure data Resource class wrapping a collection of DialogueNodes
- Pattern: `extends Resource` + `class_name DialogueTree` + `@export var` fields
- Fields: `nodes: Array[DialogueNode] = []`, `start_index: int = 0`
- Typed array `Array[DialogueNode]` references the DialogueNode Resource created in Task 2
- No methods, no `_init()`, no traversal logic — traversal lives in DialogueComponent (Wave 2)
- This completes **Wave 1** — all 3 Resource classes (DialogueChoice, DialogueNode, DialogueTree) are now in place
- Next: Task 6 — DialogueComponent (Wave 2) which will consume DialogueTree

## Wave 1 — Task 5: UID Files for Dialogue Resources (2026-06-25)

- Created `.uid` files for the 3 dialogue Resource scripts per AGENTS.md convention (line 17-18: `.uid` files must be committed alongside `.gd` files)
- `scripts/dialogue_choice.gd.uid` → `uid://fa4f8e76-5075-4a90-8893-77127ab8cd1e`
- `scripts/dialogue_node.gd.uid` → `uid://a3091419-2401-4647-85cb-519571d7bdea`
- `scripts/dialogue_tree.gd.uid` → `uid://c23cd443-1aaf-4bdd-b43f-24d38e1c3dc8`
- UUIDs generated via PowerShell `[guid]::NewGuid().ToString()` — each is unique
- Format follows existing project convention (`uid://` prefix + UUID string)
- `dialogue_line.gd.uid` already existed (created by editor) — not modified
- This completes **Wave 1** fully — all Resource classes with companion UID files are in place
- Next: Task 6 — DialogueComponent (Wave 2) which will consume DialogueTree

## Wave 3 — Task 7: Merge show_dialogue() APIs (2026-06-25)

### Changes Made

- **Merged `show_dialogue()` and `show_dialogue_with_choices()`** into a single method:
  `func show_dialogue(node: DialogueNode, choices: Array[DialogueChoice] = []) -> void`
- **Removed**: `_lines: Array[DialogueLine]`, `_current_index: int`, `_choices: Array[String]`, `_has_choices: bool`
- **Added**: `_current_node: DialogueNode`, `_current_choices: Array[DialogueChoice] = []`
- **Removed signal**: `line_changed(line_index: int)` — UI no longer traverses a line array
- **Removed method**: `_advance()` — traversal is now the Component's responsibility (Task 11 will add `advance_requested` signal)
- **New method**: `_on_typing_complete()` — checks `_current_choices.size() > 0` and calls `_show_choice_buttons()` when typing finishes
- **Modified `_type_text()`**: Removed `auto_advance_delay` block (referenced removed `_advance()`); added `_on_typing_complete()` callback to tween chain
- **Modified `_skip_typing()`**: Now calls `_on_typing_complete()` so choices appear immediately when player skips typewriter
- **Modified `_show_choice_buttons()`**: Uses `_current_choices[i].text` (DialogueChoice.text) instead of `_choices[i]` (String)
- **Modified `_on_choice_pressed()`**: Clears `_current_choices` instead of setting `_has_choices = false`
- **Modified `hide_dialogue()`**: Clears `_current_choices` instead of `_lines` and `_choices`
- **`_show_current_line()`** simplified: reads directly from `_current_node.speaker`, `_current_node.portrait`, `_current_node.text` — no index check, no array traversal

### File Stats
- **Before**: 221 lines
- **After**: 174 lines (-47 lines, -21%)

### Design Decisions
- `auto_advance_delay` export remains but is unused — Task 9 will re-integrate it with the new architecture
- `_handle_advance()` now only skips typing; empty else block awaits Task 11's `advance_requested` signal
- Hardcoded 2-button match (`_choice_btn1`, `_choice_btn2`) retained — Task 8 will make buttons dynamic
- Old callers (`npc_character.gd`) will break temporarily — Wave 4 will refactor them

### Temporary Breakage
- `npc_character.gd` calls old API (`show_dialogue_with_choices`, `show_dialogue(lines)`) — will fail at runtime
- Non-choice node advancement is blocked (no `advance_requested` signal yet) — player sees text fully typed, cannot proceed
- These are intentional intermediate states resolved by Tasks 8-11 and Wave 4

### Dependencies
- Blocked by: Task 2 (DialogueNode class_name)
- Blocks: Tasks 8 (dynamic choice buttons), 10 (is_active/force_hide), 11 (advance_requested signal)

## BBCode Typewriter Fix (2026-06-25)

**Problem:** `_type_text()` used `text.length()` for typewriter duration and tween target. BBCode tags like `[wave]Hello[/wave]` inflated the count (21 raw chars vs 5 visible glyphs), making animation too slow.

**Fix:** Replaced with `_text_label.get_total_character_count()` in two places:
1. Tween target `visible_characters` �� counts visible glyphs only
2. Duration `float(...) * text_speed` �� scales proportionally to visible characters

**Omissions:** None. This is a pure drop-in fix �� no other logic touched.

## Wave 3 — Task 8: Dynamic Choice Buttons (2026-06-25)

### Changes Made

- **Removed `@onready _choice_btn1` and `@onready _choice_btn2`** — replaced with single `@onready var _choice_container: Control`
- **Rewrote `_show_choice_buttons()`**: Dynamically creates `Button.new()` for each `_current_choices[i]`, sets `btn.text = choice.text`, connects `_on_choice_pressed.bind(i)`, adds to `_choice_container`
- **Rewrote `_clear_choice_buttons()`**: Iterates `_choice_container.get_children()` and calls `child.queue_free()` — properly frees old buttons before creating new ones
- **Replaced `_input()` guard**: `if _choice_btn1.visible or _choice_btn2.visible` → `if _current_choices.size() > 0`
- **Removed `_ready()` null checks** for `_choice_btn1`/`_choice_btn2` — no longer relevant
- **Removed `match i:` hardcoded block** — no 2-button limit; supports 0..N choices
- `dialogue_ui.tscn` untouched — ChoiceBtn1/ChoiceBtn2 nodes remain as dead children in the scene but are no longer referenced

### Design Decisions
- Using `queue_free()` rather than `remove_child()` to properly deallocate — prevents memory leaks across multiple dialogue interactions
- `_current_choices.size() > 0` guard in `_input()` blocks advancement during typing (not just when buttons are visible) — player cannot skip typewriter when the node has choices, preventing accidental skip past choice prompts.
- `_choice_container` typed as `Control` (not the scene's `HBoxContainer`) — Godot resolves the actual type at runtime

### File Stats
- **Before**: 174 lines
- **After**: 166 lines (-8 lines)

### Dependencies
- Blocked by: Task 7 (merged show_dialogue API must exist with `_current_choices: Array[DialogueChoice]`)
- Blocks: none

## Task 10 — is_active flag & force_hide() (2026-06-25)

### Changes Made

- Added `var is_active: bool = false` as public member var (no underscore) — intentionally public so DialogueComponent can read it with `.get("is_active")`
- `show_dialogue()`: guard at top checks `if is_active -> push_warning + return`, then sets `is_active = true` after the guard passes — prevents concurrent dialogues
- `hide_dialogue()`: sets `is_active = false` before emitting `dialogue_ended`
- Added `force_hide()` method:
  - Returns immediately if not active (idempotent — safe to call anytime)
  - Kills typewriter tween via `_tween.kill()` if valid
  - Sets `_panel.modulate.a = 0.0`, `visible = false` — no fade-out animation
  - Sets `is_active = false`, clears `_current_choices`, clears `_text_label.text`
  - Emits `dialogue_ended` signal

### Key Insight

The `is_active` flag is public (no underscore) because DialogueComponent needs to read it from the outside. Godot doesn't have `get_property_list()` reflection for GDScript, so `.get("is_active")` is the standard defensive pattern. `force_hide()` has no underscore because it's a public API called externally.

### Dependencies
- Blocked by: Task 7 (show_dialogue must exist as single entry point)
- Blocks: none (head of chain)
- Consumed by: DialogueComponent (already uses `.get("is_active")` and `.has_method("force_hide")` defensively)

## Task 11 — advance_requested Signal (2026-06-25)

### Changes Made

- Added `signal advance_requested` at line 7 (alongside other signals: `dialogue_started`, `dialogue_ended`, `choice_selected`)
- Wired `advance_requested.emit()` into `_handle_advance()` else branch — emits only when typing is complete, NOT during typing
- Skip-typing flow unchanged: `_is_typing` → `_skip_typing()` → no emit (player needs a second click/tap to advance after reading)
- `_on_typing_complete()` unchanged — only shows choice buttons, emits nothing

### Control Flow

```
Player press → _input() → _handle_advance()
  ├── _is_typing == true  → _skip_typing() (typewriter complete, choices appear)
  └── _is_typing == false → advance_requested.emit()
```

### Completion Verification

- Grep for `DialogueLine`, `_advance`, `_lines`, `_current_index`, `line_changed` → 0 results in dialogue_ui.gd
- `show_dialogue(DialogueNode, Array[DialogueChoice])` remains the only entry point
- `choice_selected` and `dialogue_ended` signals unchanged
- DialogueComponent already connects to `advance_requested` defensively (`if _dialogue_ui.has_signal("advance_requested"):`)

### Dependencies
- Blocked by: Task 7 (merged show_dialogue with `_handle_advance` skeleton)
- Blocks: Task 12 (npc_character refactor depends on complete DialogueUi API)
- DialogueUi is now DONE — pure presenter that shows one node, types text, shows choices, and emits signals for Component to handle traversal.

## Task 12 — NPC Character Slim-Down (2026-06-25)

### Changes Made

- Stripped `npc_character.gd` from 122 lines to 27 lines (-78%)
- **Kept**: `@export npc_name`, `@export npc_portrait`, `@onready animated_sprite_2d`, `@onready _interaction_area`, `_player_in_range`
- **Removed**: `quest_item_name`, `quest_amount`, `_dialogue_ui`, `_talk_prompt`, `_find_game_screen()`, `_on_dialogue_ended()`, `_show_talk_prompt()`, `_hide_talk_prompt()`, `_on_talk_pressed()`, `_start_dialogue()`, `_get_item_count()`
- **Removed references**: `DialogueLine`, `InventoryManager`, `InventorySlot`
- **Added**: `@onready var dialogue_component: DialogueComponent = $DialogueComponent`
- **Body events**: Forwarded to component by setting `dialogue_component._player_in_range = true/false`
- **Design**: NPC is now a pure collision-forwarding shell — DialogueComponent handles all dialogue logic, range detection, prompt display, and traversal

### Dependencies
- Blocked by: Tasks 7-11 (DialogueUi refactor complete), Task 5/6 (DialogueComponent exists)
- Blocks: Task 13 (scene wiring — connecting NPC scene to DialogueComponent)

## Task 13 — Scene Wiring: DialogueComponent in NPC Scene (2026-06-25)

### Changes Made

- Added `DialogueComponent` child node (type `Node`) to `npc_character.tscn` as direct child of root `NpcCharacter` node
- Script: `ExtResource("2_dialogue_component")` → `uid://27d7a798-fd93-434f-a343-624352905e16` (`dialogue_component.gd`)
- Export `dialogue_tree`: `ExtResource("3_farmer_quest")` → `uid://cfarmerquest01` (`farmer_quest.tres`)
- Updated header: `load_steps=7` (1 format + 4 ext_resources + 2 sub_resources)
- Added 2 new `[ext_resource]` entries for `dialogue_component.gd` and `farmer_quest.tres`
- Existing nodes preserved: AnimatedSprite2D, Area2D, CollisionShape2D untouched

### Key Insight

- The `$DialogueComponent` reference in `npc_character.gd` (Task 12) now resolves at runtime because the child node exists in the scene
- `dialogue_tree` export set at scene level — DialogueComponent's `_ready()` will auto-load it
- Scene file grew from 34 to 40 lines (+6)

### Dependencies
- Blocked by: Tasks 5 (DialogueComponent), 12 (npc_character refactor), 14 (farmer_quest.tres)
- Blocks: Tasks 15, 16 (cleanup)

## Task 14 — Remove Static TalkPrompt from game_ui.tscn (2026-06-25)

### Changes Made

- **Removed `TalkPrompt` Button node** (lines 32-46) from `scenes/ui/game_ui.tscn` — 15 lines deleted
- TalkPrompt was a plain `Button` with `text = "对话"`, positioned at `(-80, -340)` to `(80, -290)`, anchored to bottom-center
- No `ext_resource` or `sub_resource` tied to it — pure inline node, so no `load_steps` or header adjustments needed
- Scene went from 46 lines to 31 lines (-33%)

### Verification

- **Remaining nodes intact**: CenterContainer, ForceMinePanel, BagUi, DialogueUi — all preserved with correct parents and properties
- **All 5 ext_resource entries preserved**: `1_game_ui` (script), `1_gwk6t` (ForceMinePanel), `2_bag_ui` (BagUi), `3_dialogue_ui` (DialogueUi), `5_ru5ln` (player portrait texture)
- **No "TalkPrompt" string** remains in `game_ui.tscn`
- **`main_scene.tscn`** verified — `GameScreen` instance (`ExtResource("4_pu3yx")`) references game_ui.tscn correctly; no TalkPrompt references exist

### Why This Is Safe

- The old `npc_character.gd` used `game_screen.get_node_or_null("TalkPrompt")` to show/hide a static prompt — that code was removed in Task 12
- DialogueComponent now creates its own TalkPrompt Button dynamically as a child of itself
- The dynamic approach is superior: prompt follows the NPC, no need for a global singleton Button

### Dependencies
- Blocked by: Task 12 (npc_character slim removed TalkPrompt references), Task 13 (DialogueComponent added to NPC scene)
- Blocks: none

## Task 17 — Delete Obsolete DialogueLine Files (2026-06-25)

### Changes Made

- **Deleted `scripts/dialogue_line.gd`** — superseded by `DialogueNode` (Wave 1, Task 2), no external references remain
- **Deleted `scripts/dialogue_line.gd.uid`** — companion UID file, no longer needed
- Verified zero external references before deletion: `grep -r "DialogueLine" --include "*.gd"` returned only the self-referencing `class_name DialogueLine` in the file to be deleted
- `npc_character.gd` already stripped `DialogueLine` reference in Task 12; `dialogue_ui.gd` already cleaned in Tasks 7-11

### Dependencies
- Blocked by: Task 11 (DialogueUi no longer uses DialogueLine), Task 12 (npc_character no longer references DialogueLine)
- Blocks: none
- Can parallelize with: Task 16
