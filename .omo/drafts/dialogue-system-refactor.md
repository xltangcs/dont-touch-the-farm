---
slug: dialogue-system-refactor
status: drafting
intent: clear
pending-action: write .omo/plans/dialogue-system-refactor.md
approach: 5-wave implementation (Resources → Component → DialogueUi → NPC → Cleanup), each independent + QA + commit.
---

# Draft: dialogue-system-refactor

## Components (topology ledger)
| id | outcome | status | evidence |
|---|---|---|---|
| C1 | DialogueTree/DialogueNode/DialogueChoice Resource classes | active | new files in scripts/ |
| C2 | DialogueComponent dialogue engine | active | new script, attaches to NPC |
| C3 | DialogueUi refactor | active | edit scenes/ui/dialogue_ui.gd |
| C4 | npc_character.gd slim-down | active | edit scenes/characters/npc_character.gd |
| C5 | Cleanup (delete old files, adjust scenes) | active | delete + scene edits |

## Resource schemas (data model contract)

C2 + C3 depend on these schemas. Must be established before Wave 1 execution:

| Class | Field | Type | Note |
|---|---|---|---|
| **DialogueChoice** | `text` | `String` | Choice display text |
| | `next_index` | `int` | Target node index (-1 = end) |
| **DialogueNode** | `speaker` | `String` | Display name |
| | `text` | `String` (multiline) | BBCode text |
| | `portrait` | `Texture2D` | Speaker portrait |
| | `next_index` | `int` | Default next node if no choices (-1 = end) |
| | `choices` | `Array[DialogueChoice]` | Branching choices |
| **DialogueTree** | `nodes` | `Array[DialogueNode]` | All nodes |
| | `start_index` | `int` | First node (default 0) |

Pattern: Follow existing Resource convention from `scripts/inventory.gd` / `scripts/item_data.gd` (extends Resource, @export fields, class_name).

## DialogueUi signal contract (DialogueUi → DialogueComponent)

C2 + C3 depend on this callback contract. Must be established before Wave 2 execution:

| Signal | When emitted | Who listens |
|---|---|---|
| `advance_requested` | Player clicks to continue after text finishes typing | DialogueComponent — calculates next node |
| `choice_selected(choice_index: int)` | Player clicks a choice button | DialogueComponent — reads choice.next_index |
| `dialogue_ended` | hide_dialogue() or force_hide() completes | DialogueComponent — restores player input |

DialogueComponent connects in `_enter_tree()`, disconnects in `_exit_tree()`.

## Open assumptions
| assumption | default | rationale | reversible |
|---|---|---|---|
| TalkPrompt Button: child of DialogueComponent (under NPC) | Button as child of DialogueComponent node. Range = `@export var interaction_range: float = 150.0`. Camera via `get_viewport().get_camera_2d()` | Button lifetime tied to NPC naturally; distance configurable per NPC. Camera null → button hidden | yes |
| Player in "player" group for lookup | get_tree().get_nodes_in_group("player")[0] | DialogueComponent needs player ref for input disable; consistent with existing "game_ui" group pattern | yes |
| DialogueTree .tres in resources/dialogues/ | resources/dialogues/ (dir to be created) | consistent with Godot conventions | yes |
| Cycle protection: max 100 node transitions | 100 transitions in DialogueComponent._traverse() | safe upper bound; push_warning on hit. Also: next_index bounds-checked before array access; out-of-range → push_error + end dialogue | yes |
| is_active on DialogueUi rejects concurrent show_dialogue | return early + push_warning. TalkPrompt callback re-checks at call-time (no caching) | prevents double-open; second NPC's prompt click during dialogue is harmless | yes |
| Player input disabled during dialogue | DialogueComponent sets player.process_mode = PROCESS_MODE_DISABLED on dialogue start, restores on end | more reliable than checking .visible — explicit on/off. No changes to main_character.gd | yes |
| BBCode typewriter fix: get_total_character_count() | RichTextLabel.get_total_character_count() | counts visible glyphs, ignores BBCode tags — correct speed | yes |

## Findings (cited)
- dialogue_ui.gd:17 — RichTextLabel supports BBCode natively, :128 uses `text.length()` → wrong speed for BBCode. Fix: `_text_label.get_total_character_count()`
- dialogue_ui.gd:39-92 — show_dialogue/show_dialogue_with_choices 90% duplicated
- dialogue_ui.gd:172-177 — match hardcodes 2 choice buttons (ChoiceBtn1/ChoiceBtn2)
- dialogue_ui.gd:202 — hide_dialogue has fade-out tween; need force_hide (skip tween, close immediately)
- npc_character.gd:81-112 — all quest logic hardcoded (Chinese strings at lines 82,91,99,101)
- npc_character.gd:116 — get_node("/root/InventoryManager") fragile path
- main_character.gd:22-23 — checks `_dialogue_ui.visible` to freeze movement. Will remain unchanged (Scope OUT). Better approach: DialogueComponent disables player.process_mode instead — explicit, no side-channel dependency
- main_scene.tscn — NPC instance at line 38, TalkPrompt at game_ui.tscn
- scenes/components/ existing components: collectable_component.gd, dropped_component.gd → project convention for component placement
- interact input action already defined in project.godot (Space/E) — not used by new design (click-to-talk); keyboard `ui_accept` for dialogue-advance unaffected
- dialogue_line.gd `side` field is dead code — confirms this file is obsolete
- Godot: `Node.process_mode = PROCESS_MODE_DISABLED` stops _process, _physics_process, _input on entire subtree — one-line player freeze

## Decisions (with rationale)
- DialogueComponent: script-only (Node). No .tscn needed — components are scripts attached to existing nodes per project convention.
- DialogueNode.text: stores BBCode strings raw. RichTextLabel renders natively. Typewriter speed uses `get_total_character_count()` (visible glyphs, not raw string length).
- conditions/actions: REMOVED from V2 design. Dialogue branches are static (choice → next_index). No runtime condition evaluation. Simpler, per user direction.
- TalkPrompt: DialogueComponent spawns Button as **child of itself (under NPC)**. In `_ready()`: cache `camera = get_viewport().get_camera_2d()`, cache `dialogue_ui` reference (see below), create Button. In `_process()`: if camera is null → hide button + return. Otherwise: map NPC world→screen via `camera.unproject_position(parent.global_position)` to set Button position. In-range (default 150px, `@export var interaction_range: float = 150.0`) → visible + clickable. Out-of-range → invisible. Button callback checks `dialogue_ui.is_active` at call-time (no caching) — clicking prompt during active dialogue is silently rejected.
- Player disable during dialogue: DialogueComponent finds player via `get_tree().get_nodes_in_group("player")` — **guard with `if players.size() == 0: push_error + return` before indexing `[0]`**. Sets `player.process_mode = PROCESS_MODE_DISABLED` when dialogue starts. Restores to `PROCESS_MODE_INHERIT` in `dialogue_ended` signal handler. This stops all movement AND keyboard input without touching main_character.gd.
- DialogueComponent range monitoring: `_process()` checks player range always — for button show/hide AND for active dialogue. If dialogue is active and player leaves range → calls `force_hide()` to close dialogue + restore player input.
- DialogueComponent → DialogueUi reference: acquired via `get_tree().get_nodes_in_group("game_ui")[0].get_node("DialogueUi")` (same pattern as npc_character.gd and main_character.gd). Cached in `_ready()` as `_dialogue_ui`. Signal connections and method calls (`show_dialogue`, `force_hide`) all go through this cached reference.
- npc_character.gd refactor: keep `get_tree().get_nodes_in_group("game_ui")[0]` pattern for finding DialogueUi (same as main_character.gd does).
- force_hide(): skips fade-out tween, immediately sets `visible=false`, clears internal state, sets `is_active=false`, emits `dialogue_ended`. (Player `process_mode` restored by DialogueComponent's `dialogue_ended` handler — single owner, no double-restore.) Called on: player walks out of range during dialogue, NPC freed (`_exit_tree()`), scene change. **Critical: wrap all cross-node calls in `_exit_tree()` with `is_instance_valid()` guard** — during scene change, DialogueUi or player may already be freed when DialogueComponent's `_exit_tree()` runs. Example: `if is_instance_valid(dialogue_ui) and dialogue_ui.is_active: dialogue_ui.force_hide()`. Same guard for signal disconnection: `if is_instance_valid(dialogue_ui): dialogue_ui.advance_requested.disconnect(...)`.
- DialogueUi signals: `advance_requested` (player clicked continue **after** text finished typing — mid-typing click skips to full text, second click emits signal), `choice_selected(choice_index: int)` (player clicked option N), `dialogue_ended` (dialogue fully closed). DialogueComponent connects in `_enter_tree()`, disconnects in `_exit_tree()` with `is_instance_valid()` guard.
- next_index bounds check: `_traverse(index)` validates `0 ≤ index < nodes.size()` before array access. Out-of-range → `push_error` + end dialogue. Cycle protection (max 100) still covers infinite loops.
- Multi-NPC: `is_active` lives on singleton DialogueUi. Only one dialogue at a time. Second NPC's prompt remains visible; TalkPrompt callback re-checks is_active at call-time — clicking during active dialogue is harmless (push_warning).
- Orphaned ChoiceBtn1/ChoiceBtn2: dynamic buttons in `.gd` replace them. Static nodes in `.tscn` remain but are unused (`.gd` clears ChoiceContainer children before rebuilding). Accepts the dead nodes as inert — no .tscn change needed.
- Null portrait handling: DialogueUi checks `if node.portrait: portrait_texture.texture = node.portrait; else: portrait_texture.texture = null` — missing texture is safe, shows no portrait.
- dialogue_line.gd deletion: run `grep -r "DialogueLine" --include "*.gd"` BEFORE deletion (not after); must return 0 results. Then delete file.

## Scope IN
- 3 new Resource .gd files (DialogueTree, DialogueNode, DialogueChoice) in `scripts/`
- 1 new Component .gd (DialogueComponent) in `scenes/components/`
- Create `resources/dialogues/` directory
- DialogueUi .gd refactor (merge methods, dynamic buttons, BBCode fix, is_active, force_hide + 3 signals: advance_requested, choice_selected, dialogue_ended)
- npc_character.gd refactor (collision → Component, ~30 lines)
- Delete: dialogue_line.gd + .uid, TalkPrompt (from game_ui.tscn)
- Create: farmer_quest.tres sample dialogue in resources/dialogues/
- Ensure main_character.gd is in "player" group (DialogueComponent needs it for process_mode disable)

Note: NPCCharacter.tscn already deleted by author — not in this plan's deletion list.

## Scope OUT (Must NOT have)
- No condition/action runtime evaluation
- No external test framework
- No DialogueUi .tscn changes (scene structure stays; orphaned ChoiceBtn1/ChoiceBtn2 are acceptable dead nodes)
- No main_character.gd changes (player freeze during dialogue is handled by DialogueComponent setting process_mode, not by modifying main_character.gd)
- No new autoloads
- No multiplayer/network dialogue support
- No JSON/CSV dialogue formats
- No multi-NPC simultaneous dialogue (DialogueUi is singleton, is_active blocks concurrent)

## Sample dialogue: farmer_quest.tres
Node 0: "旅行者，你能帮我找3块石头吗？" (speaker: "农夫") → next_index: **-1** (ignored — choices override), 2 choices:
  choice 0: "好的，我去帮你找" → next_index: 1
  choice 1: "抱歉，我现在没空" → next_index: 2
Node 1: "太感谢你了！这些石头对我的田地很重要。" → next_index: -1 (no choices, dialogue ends)
Node 2: "好吧，等你方便的时候再来找我。" → next_index: -1

Note: When a node has non-empty `choices`, `next_index` is ignored — the next node is determined solely by the selected choice. Always set `next_index = -1` for choice nodes to be explicit.

## Wave verification gates
After each wave, agent-executed cross-todo verification:
- Wave 1: `bash ls scripts/dialogue_*.gd` exists (3 files); verify each has `class_name` + `extends Resource` + correct `@export` fields
- Wave 2: Open NPC scene in editor → verify DialogueComponent node exists with `dialogue_tree` @export set, no errors in Output panel. Verify TalkPrompt Button is child of DialogueComponent (not game_ui).
- Wave 3: `grep "show_dialogue_with_choices\|_has_choices\|_choice_btn1\|_choice_btn2\|DialogueLine\|_advance" scenes/ui/dialogue_ui.gd` → 0 results. `grep "is_active\|force_hide\|get_total_character_count\|advance_requested\|choice_selected\|dialogue_ended" scenes/ui/dialogue_ui.gd` → all 6 found.
- Wave 4: `grep -n "DialogueLine\|_start_dialogue\|quest_item_name\|quest_amount\|InventoryManager" scenes/characters/npc_character.gd` → 0 results. npc_character.gd ≤ 40 lines
- Wave 5: **Before deletion:** `grep -r "DialogueLine" --include "*.gd"` → 0 results. Then delete dialogue_line.gd + .uid. `grep "TalkPrompt" scenes/ui/game_ui.tscn` → 0 results.

## BBCode typewriter verification
Test node text: `"[wave freq=5]Wavy text[/wave] and [color=red]red[/color]"` — typewriter duration must match `_text_label.get_total_character_count()` (visible: 18 chars), NOT `text.length()` (raw: 49 chars including tags).

## Multi-NPC verification
Place 2 NPCs close together in test scene. Approach both → 2 prompts visible. Click NPC A's prompt → dialogue opens. Click NPC B's prompt during dialogue → push_warning, no crash, dialogue with NPC A continues.

## Player disable verification
Dialogue opens → player cannot move (WASD) AND cannot interact (E/Space). Dialogue closes or force_hide → player can move and interact again. Walk away during active dialogue → force_hide triggers → player unfrozen.

## next_index bounds verification
Create a .tres with next_index = 99 on a 3-node tree. Start dialogue, advance → push_error in console, dialogue ends cleanly (no crash).

## Open questions
(None — all resolved)

## Approval gate
status: approved
