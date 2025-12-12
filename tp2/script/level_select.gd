extends Control

# === LEVEL SELECT - STYLE JEU ===
# Sélection des niveaux avec le style visuel du jeu

@onready var levels_container: GridContainer = $CanvasLayer/MainContainer/ContentContainer/LevelsContainer
@onready var total_stars_label: Label = $CanvasLayer/MainContainer/TopBar/StarsPanel/HBox/TotalStars
@onready var title_label: Label = $CanvasLayer/MainContainer/ContentContainer/TitleContainer/Title

# Textures
var star_full_texture: Texture2D
var star_empty_texture: Texture2D

# Animation
var level_buttons: Array[Control] = []
var time_passed: float = 0.0

func _ready() -> void:
	# Charger les textures
	_load_textures()
	
	# Initialiser avec animation
	modulate.a = 0
	_setup_levels()
	_update_total_stars()
	
	# Animation d'entrée
	await get_tree().create_timer(0.1).timeout
	_play_intro_animation()

func _process(delta: float) -> void:
	time_passed += delta

func _load_textures() -> void:
	if ResourceLoader.exists("res://medias/ui/star_full.png"):
		star_full_texture = load("res://medias/ui/star_full.png")
	if ResourceLoader.exists("res://medias/ui/star_empty.png"):
		star_empty_texture = load("res://medias/ui/star_empty.png")

func _play_intro_animation() -> void:
	# Fade in général
	var main_tween: Tween = create_tween()
	main_tween.tween_property(self, "modulate:a", 1.0, 0.4)
	
	await main_tween.finished
	
	# Animation des boutons de niveau (apparition en cascade)
	for i in range(level_buttons.size()):
		var button: Control = level_buttons[i]
		button.modulate.a = 0
		button.scale = Vector2(0.3, 0.3)
		button.pivot_offset = button.size / 2
		
		var btn_tween: Tween = create_tween()
		btn_tween.set_parallel(true)
		btn_tween.tween_property(button, "modulate:a", 1.0, 0.3).set_delay(i * 0.12)
		btn_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.5).set_delay(i * 0.12).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _setup_levels() -> void:
	# Nettoyer le container
	for child in levels_container.get_children():
		child.queue_free()
	
	level_buttons.clear()
	
	# Créer un bouton pour chaque niveau
	var levels: Array = GameManager.get_all_levels()
	for level_id in levels:
		var level_button: Control = _create_level_button(level_id)
		levels_container.add_child(level_button)
		level_buttons.append(level_button)

func _create_level_button(level_id: String) -> Control:
	var config: Dictionary = GameManager.get_level_config(level_id)
	var is_unlocked: bool = GameManager.is_level_unlocked(level_id)
	var is_completed: bool = GameManager.is_level_completed(level_id)
	var stars: int = GameManager.get_level_stars(level_id)
	var has_star_req: bool = GameManager.has_star_requirement(level_id)
	var stars_required: int = GameManager.get_stars_required(level_id)
	
	# Container principal pour le niveau
	var container: PanelContainer = PanelContainer.new()
	container.custom_minimum_size = Vector2(220, 180)
	
	# Style du panel basé sur l'état
	var style: StyleBoxFlat = StyleBoxFlat.new()
	
	if is_unlocked:
		if is_completed:
			# Complété - Vert nature
			style.bg_color = Color(0.18, 0.55, 0.25, 0.95)
			style.border_color = Color(0.3, 0.75, 0.35, 1)
		else:
			# Débloqué - Bleu ciel
			style.bg_color = Color(0.25, 0.45, 0.65, 0.95)
			style.border_color = Color(0.4, 0.65, 0.85, 1)
	else:
		# Verrouillé - Gris pierre
		style.bg_color = Color(0.3, 0.3, 0.35, 0.95)
		style.border_color = Color(0.5, 0.5, 0.55, 1)
	
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 8
	style.shadow_offset = Vector2(3, 5)
	
	container.add_theme_stylebox_override("panel", style)
	
	# Contenu du panel
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	
	# Marge intérieure
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.add_child(vbox)
	
	# Icône du niveau
	var icon_container: CenterContainer = CenterContainer.new()
	var level_icon: Label = Label.new()
	level_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_icon.add_theme_font_size_override("font_size", 48)
	
	if not is_unlocked:
		level_icon.text = "🔒"
		level_icon.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		if level_id == "boss":
			level_icon.text = "👹"  # Boss
		elif level_id == "niveau_2":
			level_icon.text = "🏰"  # Château
		else:
			level_icon.text = "🌲"  # Forêt
	
	icon_container.add_child(level_icon)
	vbox.add_child(icon_container)
	
	# Nom du niveau
	var name_label: Label = Label.new()
	name_label.text = config.get("name", level_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	
	if not is_unlocked:
		name_label.modulate = Color(0.7, 0.7, 0.7, 1)
	
	vbox.add_child(name_label)
	
	# Condition spéciale pour le boss
	if has_star_req and not is_unlocked:
		var req_container: HBoxContainer = HBoxContainer.new()
		req_container.alignment = BoxContainer.ALIGNMENT_CENTER
		req_container.add_theme_constant_override("separation", 5)
		
		var req_label: Label = Label.new()
		req_label.text = str(stars_required) + " ⭐ requises"
		req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_label.add_theme_font_size_override("font_size", 14)
		req_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 1))
		
		req_container.add_child(req_label)
		vbox.add_child(req_container)
	
	# Étoiles
	var stars_container: HBoxContainer = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_container.add_theme_constant_override("separation", 6)
	
	for i in range(3):
		if star_full_texture and star_empty_texture:
			var star_rect: TextureRect = TextureRect.new()
			star_rect.custom_minimum_size = Vector2(32, 32)
			star_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			star_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			if is_unlocked and i < stars:
				star_rect.texture = star_full_texture
				star_rect.modulate = Color(1, 1, 1, 1)
			else:
				star_rect.texture = star_empty_texture
				star_rect.modulate = Color(0.5, 0.5, 0.5, 0.5) if is_unlocked else Color(0.3, 0.3, 0.3, 0.3)
			
			stars_container.add_child(star_rect)
		else:
			var star_label: Label = Label.new()
			star_label.add_theme_font_size_override("font_size", 24)
			if is_unlocked and i < stars:
				star_label.text = "⭐"
			else:
				star_label.text = "☆"
				star_label.modulate = Color(0.5, 0.5, 0.5, 0.6)
			stars_container.add_child(star_label)
	
	vbox.add_child(stars_container)
	
	# Meilleur temps si complété
	if is_completed:
		var best_time: float = GameManager.get_level_best_time(level_id)
		if best_time < 999999:
			var time_label: Label = Label.new()
			time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			time_label.text = "⏱ " + _format_time(best_time)
			time_label.add_theme_font_size_override("font_size", 16)
			time_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
			vbox.add_child(time_label)
	
	container.add_child(margin)
	
	# Rendre cliquable si débloqué
	if is_unlocked:
		var button_area: Button = Button.new()
		button_area.flat = true
		button_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button_area.set_anchors_preset(Control.PRESET_FULL_RECT)
		button_area.pressed.connect(_on_level_pressed.bind(level_id, container))
		button_area.mouse_entered.connect(_on_button_hover.bind(container, true))
		button_area.mouse_exited.connect(_on_button_hover.bind(container, false))
		container.add_child(button_area)
	
	return container

func _on_button_hover(container: Control, is_hovering: bool) -> void:
	var target_scale: Vector2 = Vector2(1.08, 1.08) if is_hovering else Vector2(1.0, 1.0)
	container.pivot_offset = container.size / 2
	
	var hover_tween: Tween = create_tween()
	hover_tween.tween_property(container, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Effet de brillance
	if is_hovering:
		var glow_tween: Tween = create_tween()
		glow_tween.tween_property(container, "modulate", Color(1.15, 1.15, 1.15, 1), 0.15)
	else:
		var glow_tween: Tween = create_tween()
		glow_tween.tween_property(container, "modulate", Color(1, 1, 1, 1), 0.15)

func _format_time(seconds: float) -> String:
	var minutes: int = int(seconds) / 60
	var secs: int = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

func _update_total_stars() -> void:
	var total: int = GameManager.get_total_stars()
	var max_stars: int = GameManager.get_max_possible_stars()
	total_stars_label.text = "%d / %d" % [total, max_stars]

func _on_level_pressed(level_id: String, button_container: Control) -> void:
	var config: Dictionary = GameManager.get_level_config(level_id)
	if config.has("scene_path"):
		# Animation de clic
		button_container.pivot_offset = button_container.size / 2
		
		var click_tween: Tween = create_tween()
		click_tween.tween_property(button_container, "scale", Vector2(0.85, 0.85), 0.1)
		click_tween.tween_property(button_container, "scale", Vector2(1.15, 1.15), 0.15)
		
		await click_tween.finished
		
		# Fade out
		var fade_tween: Tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
		
		await fade_tween.finished
		
		GameManager.start_level(level_id)
		get_tree().change_scene_to_file(config["scene_path"])

func _on_back_button_pressed() -> void:
	var exit_tween: Tween = create_tween()
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	await exit_tween.finished
	
	if ResourceLoader.exists("res://scenes/menu_principal.tscn"):
		get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")
	else:
		print("⚠️ Menu principal non trouvé")

func _on_reset_button_pressed() -> void:
	# Animation de shake sur les boutons
	for button in level_buttons:
		var shake_tween: Tween = create_tween()
		shake_tween.tween_property(button, "rotation", 0.1, 0.05)
		shake_tween.tween_property(button, "rotation", -0.1, 0.05)
		shake_tween.tween_property(button, "rotation", 0.0, 0.05)
	
	await get_tree().create_timer(0.2).timeout
	
	# Fade out des boutons
	var reset_tween: Tween = create_tween()
	reset_tween.tween_property(levels_container, "modulate:a", 0.0, 0.2)
	
	await reset_tween.finished
	
	GameManager.reset_all_progress()
	_setup_levels()
	_update_total_stars()
	
	# Réapparition
	levels_container.modulate.a = 1.0
	_play_intro_animation()
