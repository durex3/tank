extends VBoxContainer
class_name HangarDirectory
## Stable cards; filtering changes visibility, never the applied equipment.

signal part_selected(id: StringName)
var service: EquipmentService
var tabs := TabBar.new()
var filter := OptionButton.new()
var search := LineEdit.new()
var count := Label.new()
var grid := GridContainer.new()
var cards: Dictionary = {}
var selected_id: StringName = &"cannon"
var weapon_id: StringName = &"cannon"
var chassis_id: StringName = &"light_tracks"

func _ready() -> void:
	tabs.add_tab("炮塔", load("res://assets/derived/ui/turret.svg"))
	tabs.add_tab("底盘", load("res://assets/derived/ui/chassis.svg"))
	tabs.tab_changed.connect(func(_index: int) -> void: refresh())
	tabs.add_theme_font_size_override("font_size", 16)
	tabs.add_theme_constant_override("h_separation", 10)
	tabs.add_theme_constant_override("icon_max_width", 20)
	tabs.add_theme_stylebox_override("tab_selected", HangarStyle.panel(Color("12c9dc"), Color("12c9dc"), 12))
	tabs.add_theme_stylebox_override("tab_unselected", HangarStyle.panel(Color("262132"), Color("262132"), 12))
	tabs.add_theme_color_override("font_selected_color", Color("08252d"))
	tabs.add_theme_color_override("icon_selected_color", Color("08252d"))
	for state: String in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var style := HangarStyle.panel(Color("16c9d5") if state == "tab_selected" else Color("211c2b"), Color.TRANSPARENT, 10)
		style.set_border_width_all(0)
		style.set_content_margin(SIDE_LEFT, 20)
		style.set_content_margin(SIDE_RIGHT, 20)
		style.set_content_margin(SIDE_TOP, 9)
		style.set_content_margin(SIDE_BOTTOM, 9)
		tabs.add_theme_stylebox_override(state, style)
	var rail := PanelContainer.new()
	var rail_style := HangarStyle.panel(Color("211c2b"), Color("3e3549"), 14)
	rail_style.set_content_margin_all(5)
	rail_style.set_border_width_all(1)
	rail.add_theme_stylebox_override("panel", rail_style)
	add_child(rail)
	rail.add_child(tabs)
	var row := HBoxContainer.new()
	add_child(row)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(count)
	for label: String in ["全部", "已拥有", "未解锁", "可升级"]:
		filter.add_item(label)
	filter.item_selected.connect(func(_index: int) -> void: refresh())
	add_child(filter)
	filter.hide()
	var group := ButtonGroup.new()
	for index: int in [0, 1, 3]:
		var pill := Button.new()
		pill.text = ["全部", "已拥有", "未解锁", "可升级"][index]
		pill.toggle_mode = true
		pill.add_theme_font_size_override("font_size", 14)
		for state: String in ["normal", "hover", "pressed"]:
			var style := HangarStyle.panel(Color("17cad5") if state == "pressed" else Color("292333"), Color("17cad5") if state == "pressed" else Color("453c50"), 18)
			style.set_border_width_all(1)
			style.set_content_margin_all(10)
			pill.add_theme_stylebox_override(state, style)
		pill.button_group = group
		pill.button_pressed = index == 0
		pill.pressed.connect(func() -> void: filter.select(index); refresh())
		row.add_child(pill)
	search.placeholder_text = "搜索部件…"
	search.add_theme_font_size_override("font_size", 14)
	search.add_theme_color_override("font_placeholder_color", Color("a49bac"))
	for state: String in ["normal", "focus"]:
		var style := HangarStyle.panel(Color("292333"), Color("18c9db") if state == "focus" else Color("514759"), 18)
		style.set_border_width_all(1)
		style.set_content_margin_all(10)
		search.add_theme_stylebox_override(state, style)
	search.custom_minimum_size.x = 150
	search.text_changed.connect(func(_text: String) -> void: refresh())
	row.add_child(search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 200
	add_child(scroll)
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	for entry: PartEntry in PartCatalog.DATA.entries:
		var card := HangarPartCard.new()
		card.custom_minimum_size = Vector2(130, 128)
		card.label_key = entry.display_name
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.pressed.connect(_select.bind(entry.id))
		grid.add_child(card)
		cards[entry.id] = card
		var index: int = _implemented_index(entry)
		card.name = ("WeaponCard" if entry.kind == PartEntry.Kind.TURRET else "ChassisCard") + str(index) if index >= 0 else str(entry.id)
	refresh()

func refresh() -> void:
	var shown: int = 0
	var total: int = 0
	for entry: PartEntry in PartCatalog.DATA.entries:
		var card: HangarPartCard = cards[entry.id]
		var owned: bool = service.profile.owns(entry.id)
		var matches: bool = entry.kind == tabs.current_tab
		total += int(matches)
		matches = matches and (search.text.is_empty() or entry.display_name.contains(search.text) or str(entry.id).contains(search.text.to_lower()))
		match filter.selected:
			1: matches = matches and owned
			2: matches = matches and not owned
			3: matches = matches and service.upgrade_error(entry.id, service.profile.level_of(entry.id)).is_empty()
		card.visible = matches
		shown += int(matches)
		card.set_selected(entry.id == selected_id if entry.kind == tabs.current_tab else (entry.id == weapon_id or entry.id == chassis_id))
		var equipped: bool = entry.id == service.profile.weapon_id or entry.id == service.profile.chassis_id
		card.caption.text = entry.display_name
		card.equipped_mark.visible = equipped
		card.upgrade_mark.visible = service.upgrade_error(entry.id, service.profile.level_of(entry.id)).is_empty()
		card.badge.text = ("Lv.%d" % service.profile.level_of(entry.id)) if owned else "🔒"
		card.rarity.text = entry.rarity_name()
		card.rarity.add_theme_color_override("font_color", [Color("b5b6c5"), Color("74acff"), Color("c38dff"), Color("ffc869")][entry.rarity])
		card.tooltip_text = "点击预览，应用后才装备" if entry.basic_ready else "设计预览 · 待实现，不可装配"
		card.artwork.texture = HangarPartArtCatalog.display_texture(entry.id)
	count.text = "%s %d / %d" % ["炮塔" if tabs.current_tab == 0 else "底盘", shown, total]

func _select(id: StringName) -> void:
	selected_id = id
	part_selected.emit(id)

func _implemented_index(entry: PartEntry) -> int:
	if entry.kind == PartEntry.Kind.TURRET:
		for i: int in range(LoadoutCatalog.WEAPONS.size()):
			if LoadoutCatalog.WEAPONS[i].id == entry.id:
				return i
	else:
		for i: int in range(LoadoutCatalog.CHASSIS.size()):
			if LoadoutCatalog.CHASSIS[i].id == entry.id:
				return i
	return -1
