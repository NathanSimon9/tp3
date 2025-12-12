extends CharacterBody2D

# === SCRIPT PERSONNAGE AVEC SYSTÈME DE PROGRESSION ===
# Remplace le script inline dans logique_personnages.tscn

# --- Vitesse ---
const SPEED := 200.0
const BOOST_SPEED := 400.0
const JUMP_VELOCITY := -500.0

# --- États ---
enum Etat { COURIR, MARCHE, REPOS, SAUT, MORT, ACROUPIR }
var etat_courant := Etat.REPOS

# --- Vie ---
var has_died := false
var has_won := false 
var max_hp := 3
var hp := max_hp
@onready var hearts := $"../CanvasLayer/HBoxContainer".get_children()

# --- Invincibilité ---
var is_invincible := false
var invincibility_duration := 1.0

# --- Pièces ---
var coins := 0
var coins_required := 15
var has_all_coins := false
@onready var coin_label: Label = null

# --- Position de départ ---
var start_position := Vector2.ZERO

# --- Mouvement autorisé ---
var can_move := true  

# --- Direction mémorisée ---
var desired_direction := 0  
var is_sprinting := false   

# --- NOUVEAU: Niveau actuel ---
var current_level_id := ""

func _ready() -> void:
	$AnimatedSprite2D.modulate = Color(1,1,1,1)
	start_position = global_position
	is_invincible = false
	update_hearts()
	
	# Trouver le label des pièces de manière sécurisée
	if has_node("../CanvasLayer/CoinCounter/Label"):
		coin_label = get_node("../CanvasLayer/CoinCounter/Label")
	elif has_node("../UI/CoinCounter/Label"):
		coin_label = get_node("../UI/CoinCounter/Label")
	else:
		print("⚠️ Label des pièces non trouvé! (Normal si pas de pièces dans ce niveau)")
	
	update_coins()
	
	# Vérifier si le VictoryLabel existe avant de le modifier
	if has_node("../CanvasLayer2/VictoryLabel"):
		$"../CanvasLayer2/VictoryLabel".visible = false
	
	# === NOUVEAU: Détecter et démarrer le niveau ===
	current_level_id = _detect_current_level()
	if current_level_id != "" and has_node("/root/GameManager"):
		GameManager.start_level(current_level_id)
		print("🎮 Niveau détecté: ", current_level_id)

# === NOUVEAU: Détecter le niveau actuel ===
func _detect_current_level() -> String:
	var scene_path := get_tree().current_scene.scene_file_path
	if "niveau_1" in scene_path:
		return "niveau_1"
	elif "niveau_2" in scene_path:
		return "niveau_2"
	elif "boss" in scene_path:
		return "boss"
	return ""

# --- Nouvelle fonction pour les checkpoints ---
func set_checkpoint(new_position: Vector2) -> void:
	start_position = new_position
	print("🚩 Nouveau point de respawn: ", start_position)

# --- Fonction d'invincibilité ---
func start_invincibility() -> void:
	is_invincible = true
	
	# Effet de clignotement
	for i in range(5):  # Clignoter 5 fois (1 seconde)
		$AnimatedSprite2D.modulate.a = 0.3  # Semi-transparent
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate.a = 1.0  # Opaque
		await get_tree().create_timer(0.1).timeout
	
	is_invincible = false
	$AnimatedSprite2D.modulate = Color(1,1,1,1)
	print("🛡️ Invincibilité terminée")

# --- Mets à jour les cœurs ---
func update_hearts():
	for i in range(len(hearts)):
		if i < hp:
			hearts[i].texture = preload("res://medias/coeur.png")
		else:
			hearts[i].texture = preload("res://medias/coeur_vide.png")

# --- Mets à jour les pièces ---
func update_coins():
	if coin_label != null:
		coin_label.text = str(coins) + "/" + str(coins_required)
	else:
		print("Pièces: ", coins, "/", coins_required)

# --- Ajoute une pièce ---
func add_coin(amount: int = 1) -> void:
	if has_won:
		return
	coins += amount
	update_coins()
	
	# Vérifier si on a toutes les pièces
	if coins >= coins_required:
		has_all_coins = true
		print("✅ Toutes les pièces collectées ! Allez à la porte !")

# --- Fonction victoire ---
func win_game():
	if has_won:
		return
	has_won = true
	
	# === NOUVEAU: Arrêter le HUD timer ===
	var hud = get_tree().get_first_node_in_group("level_hud")
	if hud and hud.has_method("stop_timer"):
		hud.stop_timer()
	
	# === NOUVEAU: Compléter le niveau ===
	if has_node("/root/GameManager"):
		GameManager.complete_level()

	# Vérifier que les nœuds existent avant de les utiliser
	if has_node("../CanvasLayer2/VictoryLabel"):
		$"../CanvasLayer2/VictoryLabel".visible = true
	
	if has_node("../AnimationPlayer"):
		$"../AnimationPlayer".play("new_animation")
		$"../AnimationPlayer".animation_finished.connect(_on_animation_finished)
	else:
		# Si pas d'AnimationPlayer, passer directement à la sélection de niveaux
		await get_tree().create_timer(2.0).timeout
		_go_to_level_select()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "new_animation":
		# === MODIFIÉ: Aller à la sélection des niveaux ===
		_go_to_level_select()
	if anim_name == "RESET":
		# === MODIFIÉ: Aller à la sélection des niveaux ===
		_go_to_level_select()
	
	# Arrêter les sons de manière sécurisée
	if has_node("../AudioStreamPlayer2D"):
		$"../AudioStreamPlayer2D".stop()
	if has_node("../AudioStreamPlayer2D2"):
		$"../AudioStreamPlayer2D2".stop()
	if has_node("../AudioStreamPlayer2D3"):
		$"../AudioStreamPlayer2D3".stop()
	if has_node("../AudioStreamPlayer2D4"):
		$"../AudioStreamPlayer2D4".stop()
	
	if has_node("AudioStreamPlayer2D6"):
		$AudioStreamPlayer2D6.play()

	can_move = false
	velocity.x = 0
	etat_courant = Etat.REPOS
	$AnimatedSprite2D.play("repos")

# === NOUVEAU: Fonction pour aller à la sélection de niveaux ===
func _go_to_level_select() -> void:
	if ResourceLoader.exists("res://scenes/level_select.tscn"):
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	else:
		print("⚠️ Scène level_select.tscn non trouvée!")
		# Fallback: recharger la scène actuelle
		get_tree().reload_current_scene()

# --- Fonction défaite ---
func lose_game():
	if has_won:
		return

	# Vérifier que le label existe
	if has_node("../CanvasLayer2/VictoryLabel"):
		var victory_label = $"../CanvasLayer2/VictoryLabel"
		victory_label.text = "Vous avez perdu !"
		victory_label.visible = true

	# Arrêter les sons de manière sécurisée
	if has_node("AudioStreamPlayer2D5"):
		$AudioStreamPlayer2D5.play()
	if has_node("../AudioStreamPlayer2D3"):
		$"../AudioStreamPlayer2D3".stop()
	if has_node("../AudioStreamPlayer2D4"):
		$"../AudioStreamPlayer2D4".stop()

	can_move = false
	velocity.x = 0

	await get_tree().create_timer(5.0).timeout
	get_tree().reload_current_scene()

# --- Physique et états ---
func _physics_process(delta: float) -> void:
	if not can_move:
		velocity += get_gravity() * delta
		move_and_slide()
		return

	var input_direction := Input.get_axis("marche_arriere", "marche")
	var pressing_bas := Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("bas")
	var sprint_pressed := Input.is_key_pressed(KEY_SHIFT)

	# --- Mémorisation ---
	if input_direction != 0:
		desired_direction = input_direction
	elif not Input.is_action_pressed("marche") and not Input.is_action_pressed("marche_arriere"):
		desired_direction = 0

	if sprint_pressed and desired_direction != 0:
		is_sprinting = true
	elif not sprint_pressed:
		is_sprinting = false

	# --- Gravité ---
	velocity += get_gravity() * delta

	# --- Mort ---
	if etat_courant == Etat.MORT:
		move_and_slide()
		return

	# --- EN L'AIR ---
	if not is_on_floor():
		etat_courant = Etat.SAUT

		# Animation SAUT ou TOMBER
		if velocity.y > 0:
			$AnimatedSprite2D.play("tomber")
		else:
			$AnimatedSprite2D.play("sauter")

		# Garder vitesse horizontale
		if is_sprinting:
			velocity.x = desired_direction * BOOST_SPEED
		else:
			velocity.x = desired_direction * SPEED

		if pressing_bas:
			velocity.y = 600

		if Input.is_action_just_pressed("sauter") and is_on_floor():
			velocity.y = JUMP_VELOCITY

	else:
		# --- AU SOL ---
		var direction = desired_direction

		if pressing_bas:
			etat_courant = Etat.ACROUPIR
		elif direction == 0:
			etat_courant = Etat.REPOS
		elif sprint_pressed:
			etat_courant = Etat.COURIR
		else:
			etat_courant = Etat.MARCHE

		match etat_courant:
			Etat.REPOS:
				$AnimatedSprite2D.play("repos")
				velocity.x = 0
				if Input.is_action_just_pressed("sauter"):
					$AudioStreamPlayer2D.play()
					velocity.y = JUMP_VELOCITY

			Etat.MARCHE:
				$AnimatedSprite2D.play("marcher")
				velocity.x = direction * SPEED
				if Input.is_action_just_pressed("sauter"):
					$AudioStreamPlayer2D.play()
					velocity.y = JUMP_VELOCITY

			Etat.COURIR:
				$AnimatedSprite2D.play("courire")
				velocity.x = direction * BOOST_SPEED
				if Input.is_action_just_pressed("sauter"):
					$AudioStreamPlayer2D.play()
					velocity.y = JUMP_VELOCITY

			Etat.ACROUPIR:
				$AnimatedSprite2D.play("acroupir")
				if is_on_floor():
					velocity.x = lerp(velocity.x, 0.0, 1.0 * delta)
				else:
					velocity.y = 600

	$AnimatedSprite2D.flip_h = velocity.x < 0
	move_and_slide()

# --- Mort dans le trou ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if has_won:
		return
	if body == self:
		_die_and_reset()

func _die_and_reset() -> void:
	if has_won or is_invincible:
		return
	
	# === NOUVEAU: Tracker la mort ===
	if has_node("/root/GameManager"):
		GameManager.add_death()
	
	etat_courant = Etat.MORT
	var knock_dir = sign(global_position.x - start_position.x)
	if knock_dir == 0:
		knock_dir = 1
	velocity.x = 100 * knock_dir
	velocity.y = 0
	$AnimatedSprite2D.play("meurt")
	$AudioStreamPlayer2D5.play()
	$AudioStreamPlayer2D3.play()
	$AnimatedSprite2D.modulate = Color(1,1,1,0.5)
	hp -= 1
	update_hearts()
	await get_tree().create_timer(1.0).timeout

	if hp <= 0:
		lose_game()
		return

	hp = max(hp, 0)
	global_position = start_position
	
	# Attendre que le personnage se stabilise
	await get_tree().process_frame
	await get_tree().process_frame
	
	velocity = Vector2.ZERO
	etat_courant = Etat.REPOS
	
	$AnimatedSprite2D.modulate = Color(1,1,1,1)
	$AnimatedSprite2D.play("repos")
	
	# Invincibilité temporaire
	start_invincibility()

# --- Mort par ennemi ---
func _die_hit_and_reset(enemy_global_position: Vector2) -> void:
	if has_won or is_invincible:
		return
	if has_died:
		return
	
	# === NOUVEAU: Tracker la mort ===
	if has_node("/root/GameManager"):
		GameManager.add_death()
	
	has_died = true
	hp -= 1
	update_hearts()
	etat_courant = Etat.MORT
	var knock_dir = sign(global_position.x - enemy_global_position.x)
	if knock_dir == 0:
		knock_dir = 1
	velocity.x = 300 * knock_dir
	velocity.y = -200
	$AnimatedSprite2D.modulate = Color(1,0.5,0.5,1)
	$AnimatedSprite2D.play("meurt_frapper")
	$AudioStreamPlayer2D2.play()
	await get_tree().create_timer(1.0).timeout
	has_died = false

	if hp <= 0:
		lose_game()
		return

	hp = max(hp, 0)
	global_position = start_position
	
	# Attendre que le personnage se stabilise
	await get_tree().process_frame
	await get_tree().process_frame
	
	velocity = Vector2.ZERO
	etat_courant = Etat.REPOS
	
	$AnimatedSprite2D.modulate = Color(1,1,1,1)
	$AnimatedSprite2D.play("repos")
	
	# Invincibilité temporaire
	start_invincibility()

func apply_spring_force(force: Vector2) -> void:
	velocity.y = force.y

func _on_area_2d_2_body_entered(body: Node2D) -> void:
	if has_won:
		return
	if body.has_method("_die_hit_and_reset"):
		body._die_hit_and_reset(global_position)

# ===== 🚪 ENTRER DANS LA PORTE (Niveau 1) =====
func _on_porte_body_entered(body: Node2D) -> void:
	if has_won:
		return
	
	if body == self:
		# Vérifier si le joueur a toutes les pièces
		if has_all_coins:
			print("🎉 Niveau terminé ! Passage à la sélection...")
			
			# FIGER LE PERSONNAGE SUR LA PORTE
			can_move = false
			velocity = Vector2.ZERO
			etat_courant = Etat.REPOS
			$AnimatedSprite2D.play("repos")
			
			# DÉSACTIVER LE PANNEAU DE MESSAGE
			if has_node("../PanneauMessage"):
				var panneau = get_node("../PanneauMessage")
				if panneau.has_method("disable_message"):
					panneau.disable_message()
				else:
					panneau.queue_free()
			
			win_game()
		else:
			# Afficher un message si pas toutes les pièces
			var pieces_manquantes = coins_required - coins
			print("❌ Il vous manque encore ", pieces_manquantes, " pièce(s) !")

# ===== 🔥 ENTRER DANS LE BOSS (Niveau 2) =====
func _on_boss_body_entered(body: Node2D) -> void:
	if has_won:
		return
	
	if body == self:
		# Vérifier si le joueur a toutes les pièces
		if has_all_coins:
			print("🎉 Niveau 2 terminé ! Passage à la zone boss...")
			
			# FIGER LE PERSONNAGE
			can_move = false
			velocity = Vector2.ZERO
			etat_courant = Etat.REPOS
			$AnimatedSprite2D.play("repos")
			
			# DÉSACTIVER LE PANNEAU DE MESSAGE
			if has_node("../PanneauMessage"):
				var panneau = get_node("../PanneauMessage")
				if panneau.has_method("disable_message"):
					panneau.disable_message()
				else:
					panneau.queue_free()
			
			# COMPLÉTER LE NIVEAU AVANT LA TRANSITION
			win_game()
		else:
			# Afficher un message si pas toutes les pièces
			var pieces_manquantes = coins_required - coins
			print("❌ Il vous manque encore ", pieces_manquantes, " pièce(s) !")
