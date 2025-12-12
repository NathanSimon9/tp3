extends Control

# === PAUSE MENU AVEC BOUTON SÉLECTION NIVEAUX ===

func _ready() -> void:
	$CanvasLayer/CenterContainer/AnimationPlayer.play("RESET")
	_desactivation()
	
func _activation():
	%quitter.disabled = false
	%resume.disabled = false
	%recommencer.disabled = false
	if has_node("%niveaux"):
		%niveaux.disabled = false

func _desactivation():
	%quitter.disabled = true
	%resume.disabled = true
	%recommencer.disabled = true
	if has_node("%niveaux"):
		%niveaux.disabled = true

func _process(_delta: float) -> void:
	testEsc()

func resume() -> void:
	get_tree().paused = false
	$CanvasLayer/CenterContainer/AnimationPlayer.play_backwards("blur")
	_desactivation()

func paused() -> void:
	get_tree().paused = true
	$CanvasLayer/CenterContainer/AnimationPlayer.play("blur")
	_activation()

func testEsc() -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			paused()

func _on_resume_pressed() -> void:
	resume()

func _on_recommencer_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quitter_pressed() -> void:
	get_tree().quit()

# === NOUVEAU: Bouton sélection des niveaux ===
func _on_niveaux_pressed() -> void:
	get_tree().paused = false
	if ResourceLoader.exists("res://scenes/level_select.tscn"):
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	else:
		print("⚠️ Scène level_select.tscn non trouvée!")
