# dialogue-system-refactor - Work Plan

## TL;DR (For humans)
<!-- Fill this LAST, after the detailed plan below is written, so it summarizes the REAL plan. -->
<!-- Plain English for a non-engineer: NO file paths, NO todo numbers, NO wave/agent/tool names. -->

**What you'll get:** 对话系统从硬编码NPC脚本重构为组件化架构——在编辑器里填表就能配完整对话分支，NPC挂一个组件即可对话，点击提示图标打开对话框。

**Why this approach:** 三层分离（Resource数据 → Component逻辑 → UI表现）。Resource存对话内容，Component驱动流程，UI只管渲染。新增NPC对话只需新建一个 .tres 填表。

**What it will NOT do:** 不做运行时条件判断（对话分支是静态的），不引入外部测试框架，不改 DialogueUi 场景结构，不改主角色代码。

**Effort:** Medium
**Risk:** Low — 全为已有模式的扩展，不改引擎层
**Decisions to sanity-check:** 对话"按钮实际挂在游戏UI层（CanvasLayer）而非NPC身上——否则Control节点在世界空间收不到鼠标点击；每帧用camera.unproject_position()映射NPC坐标来跟随位置

Your next move: approve, or run a high-accuracy review. Full execution detail follows below.

---

> TL;DR (machine): Medium effort, Low risk — 5-wave refactor: 3 Resource classes + Component + UI refactor + NPC slim + cleanup. Static branches, no condition eval.

## Scope
### Must have
- DialogueTree/DialogueNode/DialogueChoice Resource classes (.gd + class_name)
- DialogueComponent script (Node, attaches to any interactable object)
- Screen-space clickable prompt UI (billboard button following NPC)
- DialogueUi: merged show_dialogue method, dynamic choice buttons, BBCode typing fix, is_active/force_hide
- npc_character.gd refactored to use DialogueComponent (~30 lines)
- Sample .tres dialogue (farmer_quest.tres) demonstrating the system
- Delete: dialogue_line.gd, NPCCharacter.tscn, TalkPrompt from game_ui.tscn

### Must NOT have
- Runtime condition/action evaluation (branches are static)
- External test framework (GUT etc.)
- DialogueUi .tscn scene structure changes
- main_character.gd changes
- New autoloads
- JSON/CSV dialogue formats
- Multi-NPC simultaneous dialogue (DialogueUi is singleton, is_active blocks concurrent)

## Verification strategy
> Zero human intervention - all verification is agent-executed.
- Test decision: none (manual QA via push_error/push_warning runtime checks)
- Evidence: .omo/evidence/task-<N>-dialogue-system-refactor.md

## Execution strategy
### Parallel execution waves
Wave 1: Resource classes (C1) — 3 pure data .gd files, zero dependencies
Wave 2: DialogueComponent (C2) — depends on Wave 1 + DialogueUi exists
Wave 3: DialogueUi refactor (C3) — independent, can parallel with Wave 2
Wave 4: npc_character.gd + farmer_quest.tres (C4) — depends on Wave 2 + Wave 3
Wave 5: Cleanup (C5) — depends on Wave 4

### Dependency matrix
| Todo | Depends on | Blocks | Can parallelize with |
| --- | --- | --- | --- |
| 1-3. Resource classes | none | 5, 11 | none |
| 4. .uid files | 1-3 | none | 5 |
| 5. DialogueComponent script | 1-3 (class_name) | 6, 12 | 4, 7-11 |
| 6. Screen-space prompt UI | 5 | 12 | 7-11 |
| 7-11. DialogueUi refactor | 1-3 (DialogueNode type) | 12 (show_dialogue sig) | 5, 6 |
| 12. npc_character refactor | 5, 7-11 | 13 | 14 |
| 13. DialogueComponent on NPC | 5, 12, 14 | 15, 16 | none |
| 14. farmer_quest.tres | 1-3 | 13 | 12 |
| 15. Delete obsolete files | 11 (no DialogueLine refs) | none | 16 |
| 16. Scene cleanup | 12, 13 | none | 15 |
| 17. E2E verification | 1-16 | none | none |

## Todos
> Implementation + Test = ONE todo. Never separate.
<!-- APPEND TASK BATCHES BELOW THIS LINE WITH edit/apply_patch - never rewrite the headers above. -->
- [x] 1. Create DialogueChoice Resource
  What to do: Create `scripts/dialogue_choice.gd` — extends Resource, class_name DialogueChoice. Fields: @export var text: String = "", @export var next_index: int = -1. Must NOT: no conditions, no actions, no extra fields. Pure data carrier.
  Parallelization: Wave 1 | Blocked by: none | Blocks: 3, 6
  References: scripts/dialogue_line.gd:1-7 (existing pattern for Resource data class)
  Acceptance criteria: File exists at scripts/dialogue_choice.gd. Has class_name DialogueChoice. extends Resource. Exactly 2 @export fields (text, next_index). Godot editor recognizes class_name when opened.
  QA scenarios: Happy — New Resource dialog shows "DialogueChoice" as creatable type. Failure — missing @export → fields don't appear in Inspector. Evidence .omo/evidence/task-1-dialogue-system-refactor.md
  Commit: Y | feat(dialogue): add DialogueChoice Resource class

- [x] 2. Create DialogueNode Resource
  What to do: Create `scripts/dialogue_node.gd` — extends Resource, class_name DialogueNode. Fields: @export var speaker: String = "", @export_multiline var text: String = "", @export var portrait: Texture2D, @export var next_index: int = -1, @export var choices: Array[DialogueChoice] = []. Must NOT: no on_enter_actions, no conditions, no extra complexity.
  Parallelization: Wave 1 | Blocked by: 1 | Blocks: 3, 6
  References: scripts/dialogue_line.gd:1-7 (fields to supersede). scenes/ui/dialogue_ui.gd:102-107 (how DialogueUi reads speaker/text/portrait)
  Acceptance criteria: File at scripts/dialogue_node.gd. class_name DialogueNode. extends Resource. 5 @export fields. Array type is Array[DialogueChoice]. @export_multiline on text field.
  QA scenarios: Happy — create DialogueNode in inspector, fill text with BBCode, see multiline editor. Failure — Array element type mismatch → Godot warns. Evidence .omo/evidence/task-2-dialogue-system-refactor.md
  Commit: Y | feat(dialogue): add DialogueNode Resource class

- [x] 3. Create DialogueTree Resource
  What to do: Create `scripts/dialogue_tree.gd` — extends Resource, class_name DialogueTree. Fields: @export var nodes: Array[DialogueNode] = [], @export var start_index: int = 0. Must NOT: no extra logic, no traversal methods (those go in Component).
  Parallelization: Wave 1 | Blocked by: 2 | Blocks: 6
  References: scenes/ui/dialogue_ui.gd:21 (Array[DialogueLine] pattern)
  Acceptance criteria: File at scripts/dialogue_tree.gd. class_name DialogueTree. extends Resource. 2 @export fields. New Resource dialog shows "DialogueTree".
  QA scenarios: Happy — create .tres, add nodes array entries, each is DialogueNode. Failure — missing class_name → can't create from New Resource. Evidence .omo/evidence/task-3-dialogue-system-refactor.md
  Commit: Y | feat(dialogue): add DialogueTree Resource class

- [x] 4. Create .uid files for new scripts
  What to do: Open the Godot editor so it auto-generates .uid files for dialogue_choice.gd, dialogue_node.gd, dialogue_tree.gd. If editor unavailable, create stub .uid files manually. Must NOT: skip — .uid files are required by AGENTS.md convention.
  Parallelization: Wave 1 | Blocked by: 1,2,3 | Blocks: none
  References: AGENTS.md:17-18 (.uid files auto-generated, commit them)
  Acceptance criteria: dialogue_choice.gd.uid, dialogue_node.gd.uid, dialogue_tree.gd.uid exist with non-empty content.
  QA scenarios: Happy — files exist and contain UUID. Failure — missing .uid → editor may fail to resolve class_name references. Evidence .omo/evidence/task-4-dialogue-system-refactor.md
  Commit: Y | chore(dialogue): add .uid files for dialogue resource classes

- [x] 5. Create DialogueComponent script
  What to do: Create `scenes/components/dialogue_component.gd` — extends Node, class_name DialogueComponent. Public API: start_dialogue(tree: DialogueTree), on_player_entered(body: Node2D), on_player_exited(body: Node2D). Internal: _traverse(index), _show_node(node, choices), _on_choice(index), _on_confirm (advance to next_index). Fields: dialogue_tree: DialogueTree, dialogue_ui: DialogueUi, current_index: int = 0, player_in_range: bool, step_count: int, prompt_button: Button. Max steps: 100. On _ready: find DialogueUi via get_tree().get_nodes_in_group("game_ui")[0].get_node("DialogueUi"). Signal: dialogue_started, dialogue_ended. Must NOT: condition evaluation, action parsing, InventoryManager references.
  Parallelization: Wave 2 | Blocked by: 1,2,3 | Blocks: 6, 7
  References: scenes/ui/dialogue_ui.gd:39-64 (show_dialogue interface), npc_character.gd:81-112 (existing traversal pattern to supersede), scenes/components/collectable_component.gd (project component convention)
  Acceptance criteria: File at scenes/components/dialogue_component.gd. class_name DialogueComponent. extends Node. Has start_dialogue(tree) method. Has cycle guard (step counter ≤ 100). Finds DialogueUi through get_tree().get_nodes_in_group("game_ui"). Emits dialogue_started/dialogue_ended signals. Zero references to InventoryManager or game systems.
  QA scenarios: Happy — attach to Node2D, call start_dialogue(tree), see dialogue flow. Failure — cycle in tree → stops at 100 steps + push_warning. Failure — missing DialogueUi → push_error + return. Evidence .omo/evidence/task-5-dialogue-system-refactor.md
  Commit: Y | feat(dialogue): add DialogueComponent

- [x] 6. Add screen-space prompt UI to DialogueComponent
  What to do: DialogueComponent creates Button on game_ui CanvasLayer (NOT under NPC's world-space tree — Control nodes under Node2D don't receive mouse clicks). On _enter_tree: find game_ui via "game_ui" group, create Button child on it, store reference. In _process (only when prompt should be visible): use camera.unproject_position(parent.global_position) to set Button.position (offset Y above NPC). On _exit_tree: remove Button from game_ui. Button.text = "对话". Button handles click → calls start_dialogue(). Must NOT: create Button as child of NPC (world space), use hardcoded pixel offsets, leak Buttons on scene change.
  Parallelization: Wave 2 | Blocked by: 5 | Blocks: 7
  References: scenes/ui/game_ui.tscn:32-46 (existing TalkPrompt pattern to supersede), npc_character.gd:20-21 (body_entered/body_exited signals), npc_character.gd:56-73 (show/hide prompt logic)
  Acceptance criteria: Button is child of game_ui CanvasLayer (not NPC). Button.created and added in _enter_tree, removed in _exit_tree. Button.position syncs with NPC screen position via camera.unproject_position(). Button visible only when player_in_range AND dialogue not active. Click calls start_dialogue().
  QA scenarios: Happy — player walks into NPC range → "对话" button appears at NPC's screen position → click → dialogue opens. Happy — player leaves range → button disappears. Happy — scene change → old buttons cleaned up (_exit_tree). Failure — no camera → unproject_position returns Vector2.ZERO, push_warning. Failure — no game_ui group → push_error + return. Evidence .omo/evidence/task-6-dialogue-system-refactor.md
  Commit: Y | feat(dialogue): add screen-space prompt UI to DialogueComponent

- [x] 7. Refactor DialogueUi — merge show_dialogue methods
  What to do: In scenes/ui/dialogue_ui.gd, delete show_dialogue_with_choices(). Modify show_dialogue() to accept optional choices parameter: func show_dialogue(node: DialogueNode, choices: Array[DialogueChoice] = []) → void. Remove _has_choices field. Remove show_dialogue_with_choices entirely. Adjust internal logic: if choices array is non-empty, show choice buttons after typing finishes. Must NOT: change method name (show_dialogue stays), break existing callers.
  Parallelization: Wave 3 | Blocked by: 2 | Blocks: 8
  References: scenes/ui/dialogue_ui.gd:39-65 (show_dialogue), scenes/ui/dialogue_ui.gd:67-92 (show_dialogue_with_choices to delete), scenes/ui/dialogue_ui.gd:94-100 (_show_current_line uses _has_choices)
  Acceptance criteria: Only show_dialogue method exists. Signature is show_dialogue(node: DialogueNode, choices: Array[DialogueChoice] = []). _has_choices field removed. show_dialogue_with_choices removed. No compilation errors.
  QA scenarios: Happy — call show_dialogue(node, []) → no choices shown. call show_dialogue(node, [choice_a, choice_b]) → two choice buttons appear. Failure — call with null choices → treated as empty array. Evidence .omo/evidence/task-7-dialogue-system-refactor.md
  Commit: Y | refactor(dialogue): merge show_dialogue methods, remove _has_choices

- [x] 8. Refactor DialogueUi — dynamic choice buttons
  What to do: Replace hardcoded _choice_btn1/_choice_btn2 with dynamically generated Button array. In _show_choice_buttons(): clear existing choice children from ChoiceContainer, then for each choice in choices array: var btn = Button.new(); set text, connect pressed signal, add_child to ChoiceContainer. Remove @onready _choice_btn1/_choice_btn2. Must NOT: leave hardcoded match statement, leave unused button references.
  Parallelization: Wave 3 | Blocked by: 7 | Blocks: 10
  References: scenes/ui/dialogue_ui.gd:167-186 (_show_choice_buttons with hardcoded match), scenes/ui/dialogue_ui.gd:189-191 (_clear_choice_buttons hides hardcoded buttons), scenes/ui/dialogue_ui.tscn:74-88 (ChoiceBtn1/ChoiceBtn2 scene nodes — can keep or remove, dynamic buttons override)
  Acceptance criteria: _choice_btn1, _choice_btn2 fields and @onready removed. ChoiceContainer children cleared and rebuilt each _show_choice_buttons call. Supports any number of choices (0..N). Scene nodes for ChoiceBtn1/ChoiceBtn2 may remain but are unused (safe cleanup in separate todo).
  QA scenarios: Happy — dialogue with 3 choices → 3 buttons generated. dialogue with 5 choices → 5 buttons generated. Failure — 0 choices → no buttons, dialogue advances on confirm. Evidence .omo/evidence/task-8-dialogue-system-refactor.md
  Commit: Y | refactor(dialogue): dynamic choice button generation

- [x] 9. Refactor DialogueUi — BBCode typewriter fix
  What to do: In _type_text(), replace float(text.length()) * text_speed with float(_text_label.get_total_character_count()) * text_speed. This fixes typewriter speed calculation for BBCode-rich text. Must NOT: change any other logic in _type_text.
  Parallelization: Wave 3 | Blocked by: none (independent of 7,8) | Blocks: none
  References: scenes/ui/dialogue_ui.gd:115-133 (_type_text), scenes/ui/dialogue_ui.gd:128 (line to change: float(text.length()) * text_speed)
  Acceptance criteria: BBCode markup does not inflate typewriter duration. Plain text speed unchanged. Visible character count matches actual rendered characters.
  QA scenarios: Happy — "[color=yellow]87[/color]个石头" types at same speed as "87个石头". Failure — old code would type slower due to counting BBCode tags. Evidence .omo/evidence/task-9-dialogue-system-refactor.md
  Commit: Y | fix(dialogue): use get_total_character_count for BBCode-aware typewriter speed

- [x] 10. Refactor DialogueUi — add is_active flag and force_hide
  What to do: Add var is_active: bool = false. Set to true at start of show_dialogue(), false at end of hide_dialogue(). In show_dialogue(): if is_active → push_warning + return (reject concurrent dialogs). Add force_hide() method: kills tween, hides panel, sets visible=false, is_active=false, emits dialogue_ended if was active. Must NOT: silently overwrite active dialog.
  Parallelization: Wave 3 | Blocked by: 7 | Blocks: none
  References: scenes/ui/dialogue_ui.gd:39-41 (show_dialogue start), scenes/ui/dialogue_ui.gd:202-213 (hide_dialogue)
  Acceptance criteria: is_active field exists. Concurrent show_dialogue call → push_warning + returns. force_hide() cleanly shuts down dialogue from external code (scene change, NPC removal).
  QA scenarios: Happy — dialogue open, second NPC calls show_dialogue → rejected with warning. force_hide() during active dialogue → panel disappears, dialogue_ended emitted. Failure — force_hide while not active → no-op, no crash. Evidence .omo/evidence/task-10-dialogue-system-refactor.md
  Commit: Y | feat(dialogue): add is_active guard and force_hide

- [x] 11. Update DialogueUi to use DialogueNode instead of DialogueLine
  What to do: Replace internal Array[DialogueLine] with single DialogueNode usage. show_dialogue now takes (node: DialogueNode, choices: Array[DialogueChoice] = []). Remove _lines array, _current_index, _advance logic (component handles traversal). DialogueUi becomes a "show one node" presenter: receives node + choices → types text → shows choices → emits choice_selected(index) → caller advances. **Key semantic: between show_dialogue calls within the same dialogue session, the panel stays visible — update content in-place (name_label, text_label, portrait texture, rebuild choice buttons). Only hide_dialogue() or force_hide() close the panel. is_active stays true across node transitions within one session.** Must NOT: keep _advance() method (traversal is Component's responsibility), keep _lines array, hide/re-show panel between nodes.
  Parallelization: Wave 3 | Blocked by: 7 | Blocks: 6
  References: scenes/ui/dialogue_ui.gd:21-26 (fields to remove/replace), scenes/ui/dialogue_ui.gd:94-113 (_show_current_line, line_changed)
  Acceptance criteria: No _lines array. No _current_index. No _advance(). show_dialogue signature uses DialogueNode. choice_selected signal emits (not internally consumed — component handles). line_changed signal removed or repurposed.
  QA scenarios: Happy — Component calls show_dialogue(node, choices) → UI shows single node → choice_selected emitted → Component decides next node. Failure — old code calling with Array[DialogueLine] → compile error. Evidence .omo/evidence/task-11-dialogue-system-refactor.md
  Commit: Y | refactor(dialogue): DialogueUi consumes DialogueNode, traversal moves to Component

- [x] 12. Refactor npc_character.gd — slim to collision-only
  What to do: Strip npc_character.gd to ~30 lines. Keep: @export npc_name, npc_portrait, @onready _interaction_area, _player_in_range bool. Remove: quest_item_name, quest_amount, _dialogue_ui, _talk_prompt, _find_game_screen, _on_dialogue_ended, _show/_hide_talk_prompt, _start_dialogue, _get_item_count. Add: @onready dialogue_component: DialogueComponent = $DialogueComponent. On body_entered → call dialogue_component._on_player_entered(body). On body_exited → call dialogue_component._on_player_exited(body). Must NOT: keep any dialogue or quest logic.
  Parallelization: Wave 4 | Blocked by: 5, 11 | Blocks: 13, 14
  References: scenes/characters/npc_character.gd:1-122 (full file to refactor), scenes/characters/main_character.gd:1-20 (reference for clean component pattern)
  Acceptance criteria: npc_character.gd ≤ 40 lines. No quest/InventoryManager references. Has @onready dialogue_component. Collision signals forward to component. NPC scene still loads and displays correctly.
  QA scenarios: Happy — NPC idle animation plays, player enters Area2D → component handles prompt. Failure — DialogueComponent not found on NPC → push_error + graceful skip. Evidence .omo/evidence/task-12-dialogue-system-refactor.md
  Commit: Y | refactor(npc): slim npc_character to collision-only, delegate to DialogueComponent

- [x] 13. Add DialogueComponent to NPC scene
  What to do: Edit scenes/characters/npc_character.tscn — add child Node named "DialogueComponent", attach dialogue_component.gd script. Set dialogue_tree @export to farmer_quest.tres. Ensure NPC's Area2D body_entered/body_exited signals route to component. Must NOT: break existing NPC placement in main_scene.tscn.
  Parallelization: Wave 4 | Blocked by: 5, 12, 14 | Blocks: 15, 16
  References: scenes/characters/npc_character.tscn:1-34 (current scene), resources/dialogues/farmer_quest.tres (dialogue tree to assign)
  Acceptance criteria: npc_character.tscn has DialogueComponent child with script attached. dialogue_tree exported field set to farmer_quest.tres. Opening main_scene.tscn shows NPC with component intact and tree assigned. No errors on scene load.
  QA scenarios: Happy — open NPC scene, see DialogueComponent with dialogue_tree pointing to farmer_quest.tres. Failure — missing .tres reference → editor warns about missing resource. Evidence .omo/evidence/task-13-dialogue-system-refactor.md
  Commit: Y | feat(npc): attach DialogueComponent with farmer_quest dialogue to NPC

- [x] 14. Create sample farmer_quest.tres
  What to do: Create `resources/dialogues/farmer_quest.tres` — DialogueTree with 3-4 nodes replicating the current NPC quest dialogue. Node 0: NPC asks for stones, 2 choices (yes/no). Node 1: success response. Node 2: failure response. Node 3: goodbye. Must NOT: reference any conditions or actions (static branches only).
  Parallelization: Wave 4 | Blocked by: 1,2,3,11 | Blocks: none
  References: scenes/characters/npc_character.gd:81-112 (existing quest dialogue to replicate), scripts/dialogue_tree.gd (Resource format)
  Acceptance criteria: farmer_quest.tres exists at resources/dialogues/. Contains DialogueTree with ≥3 DialogueNodes. Has at least one node with 2 choices. Loads without errors in editor.
  QA scenarios: Happy — open .tres in inspector, see full dialogue tree with choices. Load via load("res://resources/dialogues/farmer_quest.tres") at runtime → valid DialogueTree. Failure — malformed next_index → Component catches with cycle guard. Evidence .omo/evidence/task-14-dialogue-system-refactor.md
  Commit: Y | feat(dialogue): add farmer_quest sample dialogue

- [x] 15. Delete obsolete files
  What to do: Delete scripts/dialogue_line.gd + .uid, scenes/characters/NPCCharacter.tscn. Must NOT: delete any file not explicitly listed here.
  Parallelization: Wave 5 | Blocked by: 11 (DialogueUi no longer references DialogueLine) | Blocks: none
  References: scripts/dialogue_line.gd (superseded by DialogueNode), scenes/characters/NPCCharacter.tscn (empty stub duplicate)
  Acceptance criteria: scripts/dialogue_line.gd, scripts/dialogue_line.gd.uid, scenes/characters/NPCCharacter.tscn deleted. No remaining references to DialogueLine class_name (grep for "DialogueLine" returns 0 results in .gd files).
  QA scenarios: Happy — grep "DialogueLine" → 0 results. Failure — stray reference → compile error. Evidence .omo/evidence/task-15-dialogue-system-refactor.md
  Commit: Y | chore(dialogue): remove obsolete dialogue_line.gd and NPCCharacter.tscn

- [x] 16. Clean up game_ui.tscn and main_scene.tscn
  What to do: From game_ui.tscn — remove TalkPrompt Button node (unique_id=-2061521730). From main_scene.tscn — verify NPC references still valid, remove any TalkPrompt-related setup if present. Must NOT: remove DialogueUi, BagUi, ForceMinePanel, or CenterContainer from game_ui.tscn.
  Parallelization: Wave 5 | Blocked by: 12, 13 | Blocks: none
  References: scenes/ui/game_ui.tscn:32-46 (TalkPrompt to delete), scenes/env/main_scene.tscn:1-44 (NPC instance at line 38-40)
  Acceptance criteria: game_ui.tscn has no TalkPrompt node. No "TalkPrompt" string in game_ui.tscn. main_scene.tscn NPC refs valid. Scene opens in editor without errors.
  QA scenarios: Happy — open game_ui.tscn, scene tree shows DialogueUi, BagUi, ForceMinePanel, no TalkPrompt. Open main_scene.tscn, NPC present and intact. Failure — deleted wrong node → missing UI element at runtime. Evidence .omo/evidence/task-16-dialogue-system-refactor.md
  Commit: Y | chore(scene): remove deprecated TalkPrompt, verify scene integrity

- [ ] 17. End-to-end integration verification
  What to do: Run the full flow end-to-end. Open main_scene.tscn, verify: (1) NPC shows idle animation, (2) player walks into NPC Area2D → screen-space "对话" prompt appears above NPC, (3) click prompt → DialogueUi opens with farmer_quest dialogue, (4) typewriter types BBCode text correctly, (5) choices appear dynamically, (6) clicking choice advances to correct response node, (7) dialogue ends → panel fades out → prompt reappears if still in range, (8) player leaves Area2D → prompt disappears. Must NOT: have any crashes, null references, or push_error in console.
  Parallelization: Wave 5 | Blocked by: 1-16 | Blocks: none
  References: All prior todos
  Acceptance criteria: Full flow passes all 8 steps. Console shows zero push_error, zero push_warning (except expected cycle-guard tests). File structure matches plan (no leftover files, no missing files).
  QA scenarios: Happy — complete walkthrough as described. Failure — any step fails → fix specific todo, re-verify. Evidence .omo/evidence/task-17-dialogue-system-refactor.md
  Commit: N (final QA, no code changes)

## Final verification wave
> Runs in parallel after ALL todos. ALL must APPROVE. Surface results and wait for the user's explicit okay before declaring complete.
- [ ] F1. Plan compliance audit — grep all .gd for "TalkPrompt", "DialogueLine", "show_dialogue_with_choices", "_choice_btn1", "_choice_btn2", "_has_choices", "_lines", "_advance", "quest_item_name", "quest_amount", 'get_node("/root/InventoryManager")' → 0 results
- [ ] F2. Code quality — no file > 150 lines, all @export have defaults, no orphaned .uid. Open main_scene in editor → Output panel zero errors
- [ ] F3. Manual QA — F5 run: walk into NPC range → prompt appears → click → dialogue plays → choices work → BBCode renders → dialogue ends → prompt reappears → walk away → prompt hides → walk back → prompt shows
- [ ] F4. Scope fidelity — no new autoloads, no main_character.gd changes, no DialogueUi .tscn restructure, no JSON/CSV, no condition/action eval code

## Commit strategy
One commit per todo (1-16). Format: `<type>(<scope>): <summary>`. Types: feat/refactor/fix/chore. Scopes: dialogue/npc/scene.
- 1-4: feat(dialogue) — Resource classes
- 5-6: feat(dialogue) — Component + prompt UI
- 7-11: refactor(dialogue) — DialogueUi changes
- 12: refactor(npc)
- 13: feat(npc)
- 14: feat(dialogue)
- 15-16: chore
- 17: no commit (QA only)

## Success criteria
- [ ] 16 implementation todos completed + committed
- [ ] npc_character.gd ≤ 40 lines (was 122)
- [ ] 0 references to DialogueLine class_name
- [ ] 0 references to TalkPrompt in game_ui.tscn
- [ ] DialogueUi supports N choice buttons (dynamic)
- [ ] BBCode typewriter speed correct (get_total_character_count)
- [ ] Screen-space prompt follows NPC, shows/hides with Area2D
- [ ] New NPC dialogue = new .tres file, zero code changes
- [ ] Main scene loads + plays without errors

