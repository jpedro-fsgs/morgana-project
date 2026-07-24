extends CanvasLayer

const APPEAR_INTERVAL: float = 15.0

const AVAILABLE_ITEMS: Array[GDScript] = [
	preload("res://scripts/items/coin_magnet_item.gd"),
	preload("res://scripts/items/wand_item.gd"),
	preload("res://scripts/items/force_field_item.gd"),
	preload("res://scripts/items/scroll_orb_combo_item.gd"),
	preload("res://scripts/items/scroll_orb_blade_item.gd"),
	preload("res://scripts/items/scroll_orb_explosive_item.gd"),
	preload("res://scripts/items/scroll_wand_item.gd"),
	preload("res://scripts/items/scroll_force_field_item.gd"),
]

const ORB_ITEMS: Array[GDScript] = [
	preload("res://scripts/items/orb_combo_item.gd"),
	preload("res://scripts/items/orb_blade_item.gd"),
	preload("res://scripts/items/orb_explosive_item.gd"),
]

@onready var shop_ui: Control = $ShopUI
@onready var single_panel: Panel = $ShopUI/Panel
@onready var icon: TextureRect = $ShopUI/Panel/VBox/Icon
@onready var icon_overlay: TextureRect = $ShopUI/Panel/VBox/Icon/IconOverlay
@onready var name_label: Label = $ShopUI/Panel/VBox/NameLabel
@onready var description_label: Label = $ShopUI/Panel/VBox/DescriptionLabel
@onready var cost_label: Label = $ShopUI/Panel/VBox/CostLabel
@onready var buy_button: Button = $ShopUI/Panel/VBox/ButtonRow/BuyButton
@onready var close_button: Button = $ShopUI/Panel/VBox/ButtonRow/CloseButton
@onready var choice_panel: Panel = $ShopUI/ChoicePanel
@onready var choice_title: Label = $ShopUI/ChoicePanel/VBox/TitleLabel
@onready var choice_hint: Label = $ShopUI/ChoicePanel/VBox/HintLabel
@onready var choice_row: HBoxContainer = $ShopUI/ChoicePanel/VBox/ChoiceRow
@onready var choice_close_button: Button = $ShopUI/ChoicePanel/VBox/CloseButton
@onready var timer: Timer = $Timer

const INTRO_TITLE := "Sua primeira orbe mágica"
const INTRO_HINT := "Ela luta ao seu lado sozinha. Depois, mais orbes e evoluções vão aparecer aqui de tempos em tempos."
const DEFAULT_CHOICE_TITLE := "Escolha uma orbe"

var _current_item: ItemBase

func _ready() -> void:
	shop_ui.visible = false
	single_panel.visible = false
	choice_panel.visible = false
	timer.wait_time = APPEAR_INTERVAL
	timer.timeout.connect(_on_timer_timeout)
	buy_button.pressed.connect(_on_buy_pressed)
	close_button.pressed.connect(_close_shop)
	choice_close_button.pressed.connect(_close_shop)
	_run_intro_tutorial()

## Assim que a partida começa de verdade (fim da contagem regressiva),
## oferece a primeira orbe já explicando o que ela faz.
func _run_intro_tutorial() -> void:
	# Espera um frame pra garantir que o _ready() do Level (que pausa o jogo
	# pra contagem regressiva) já rodou antes de checarmos is_game_active.
	await get_tree().process_frame
	while not GameManager.is_game_active:
		await get_tree().create_timer(0.2).timeout

	var choices := _available_orb_choices()
	if not choices.is_empty():
		_open_orb_choice(choices, true)

func _on_timer_timeout() -> void:
	if not GameManager.is_game_active:
		return

	var orb_choices := _available_orb_choices()
	if not orb_choices.is_empty():
		_open_orb_choice(orb_choices)
		return

	var item := _pick_available_item()
	if item:
		_open_shop(item)

func _find_manager() -> OrbManager:
	return get_tree().get_first_node_in_group("orb_manager") as OrbManager

## Enquanto ainda houver orbes pra comprar (e slot livre), a loja oferece a
## escolha delas antes de qualquer outro item.
func _available_orb_choices() -> Array[ItemBase]:
	var manager := _find_manager()
	if manager == null or not manager.has_room():
		return []
	var choices: Array[ItemBase] = []
	for item_script in ORB_ITEMS:
		var item: ItemBase = item_script.new()
		if item.is_available():
			choices.append(item)
	return choices

func _pick_available_item() -> ItemBase:
	var candidates: Array[ItemBase] = []
	for item_script in AVAILABLE_ITEMS:
		var item: ItemBase = item_script.new()
		if (item.stackable or not ItemManager.is_owned(item.id)) and item.is_available():
			candidates.append(item)
	if candidates.is_empty():
		return null
	return candidates.pick_random()

func _open_orb_choice(choices: Array[ItemBase], is_intro: bool = false) -> void:
	for child in choice_row.get_children():
		child.queue_free()
	for item in choices:
		choice_row.add_child(_build_choice_card(item))

	choice_title.text = INTRO_TITLE if is_intro else DEFAULT_CHOICE_TITLE
	choice_hint.text = INTRO_HINT if is_intro else ""

	shop_ui.visible = true
	choice_panel.visible = true
	single_panel.visible = false
	GameManager.is_game_active = false

func _build_choice_card(item: ItemBase) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(150, 170)
	card.add_theme_constant_override("separation", 4)

	var icon_stack := _build_icon_stack(item, Vector2(48, 48))
	icon_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(icon_stack)

	var card_name := Label.new()
	card_name.text = item.display_name
	card_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(card_name)

	var card_desc := Label.new()
	card_desc.text = item.description
	card_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_desc.add_theme_font_size_override("font_size", 13)
	card.add_child(card_desc)

	var price := item.compute_cost()
	var card_cost := Label.new()
	card_cost.text = "Custo: %d moedas" % price
	card_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(card_cost)

	var select_button := Button.new()
	select_button.text = "Escolher"
	select_button.disabled = GameManager.money < price
	select_button.pressed.connect(func():
		if ItemManager.purchase(item):
			_close_shop()
	)
	card.add_child(select_button)

	return card

## Ícone grande do item (ex: o pergaminho) com um ícone menor por cima quando
## houver (ex: a orbe específica que aquele pergaminho evolui).
func _build_icon_stack(item: ItemBase, size: Vector2) -> Control:
	var stack := Control.new()
	stack.custom_minimum_size = size

	var base_icon := TextureRect.new()
	base_icon.anchor_right = 1.0
	base_icon.anchor_bottom = 1.0
	base_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	base_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item.icon_path != "":
		base_icon.texture = load(item.icon_path)
	stack.add_child(base_icon)

	if item.icon_overlay_path != "":
		var overlay := TextureRect.new()
		overlay.anchor_left = 0.3
		overlay.anchor_top = 0.32
		overlay.anchor_right = 0.7
		overlay.anchor_bottom = 0.72
		overlay.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay.texture = load(item.icon_overlay_path)
		stack.add_child(overlay)

	return stack

func _open_shop(item: ItemBase) -> void:
	_current_item = item
	icon.texture = load(item.icon_path) if item.icon_path != "" else null
	icon_overlay.texture = load(item.icon_overlay_path) if item.icon_overlay_path != "" else null
	icon_overlay.visible = item.icon_overlay_path != ""
	name_label.text = item.display_name
	description_label.text = item.description
	var price := item.compute_cost()
	cost_label.text = "Custo: %d moedas" % price
	buy_button.disabled = GameManager.money < price

	shop_ui.visible = true
	single_panel.visible = true
	choice_panel.visible = false
	GameManager.is_game_active = false

func _on_buy_pressed() -> void:
	if _current_item and ItemManager.purchase(_current_item):
		_close_shop()

func _close_shop() -> void:
	shop_ui.visible = false
	single_panel.visible = false
	choice_panel.visible = false
	_current_item = null
	GameManager.is_game_active = true
