
extends Node


# === HUD EN JEU - EN HAUT À DROITE ===
# Affiche le timer et les étoiles potentielles en temps réel
# Utilise les assets Kenney UI Pack

@onready var timer_label: Label = $TopRightContainer/MainPanel/VBoxContainer/TimerContainer/TimerLabel
@onready var deaths_label: Label = $TopRightContainer/MainPanel/VBoxContainer/DeathsContainer/DeathsLabel
@onready var star1: TextureRect = $TopRightContainer/MainPanel/VBoxContainer/StarsContainer/Star1
@onready var star2: TextureRect = $TopRightContainer/MainPanel/VBoxContainer/StarsContainer/Star2
@onready var star3: TextureRect = $TopRightContainer/MainPanel/VBoxContainer/StarsContainer/Star3

var current_level_id := ""
var level_config := {}
var elapsed_time := 0.0
var is_running := false

# Textures d'étoiles
var star_full_texture: Texture2D
var star_empty_texture: Texture2D

func _ready() -> void:
	# Charger les textures d'étoiles
	star_full_texture = load("res://medias/ui/star_full.png")
	star_empty_texture = load("res://medias/ui/star_empty.png")
	
	# Détecter le niveau actuel
	current_level_id = _detect_current_level()
	
	if current_level_id != "" and has_node("/root/GameManager"):
		level_config = GameManager.get_level_config(current_level_id)
		is_running = true
		print("🎮 HUD initialisé pour: ", current_level_id)
	else:
		print("⚠️ GameManager non trouvé ou niveau non détecté")
	
	# Initialiser l'affichage
	_update_display()

func _detect_current_level() -> String:
	var scene_path := get_tree().current_scene.scene_file_path
	if "niveau_1" in scene_path:
		return "niveau_1"
	elif "niveau_2" in scene_path:
		return "niveau_2"
	elif "boss" in scene_path:
		return "boss"
	return ""

func _process(delta: float) -> void:
	if not is_running:
		return
	
	# Mettre à jour le temps
	elapsed_time += delta
	
	# Mettre à jour l'affichage
	_update_display()

func _update_display() -> void:
	# Mettre à jour le timer
	if timer_label:
		timer_label.text = _format_time(elapsed_time)
		
		# Changer la couleur selon le temps
		if level_config.has("time_3_stars"):
			if elapsed_time <= level_config["time_3_stars"]:
				timer_label.modulate = Color(0.3, 1.0, 0.3)  # Vert
			elif elapsed_time <= level_config["time_2_stars"]:
				timer_label.modulate = Color(1.0, 1.0, 0.3)  # Jaune
			else:
				timer_label.modulate = Color(1.0, 0.5, 0.3)  # Orange
	
	# Mettre à jour les morts
	if deaths_label and has_node("/root/GameManager"):
		var deaths := GameManager.death_count
		deaths_label.text = str(deaths)
		
		# Changer la couleur selon les morts
		if level_config.has("deaths_3_stars"):
			if deaths <= level_config["deaths_3_stars"]:
				deaths_label.modulate = Color(0.3, 1.0, 0.3)  # Vert
			elif deaths <= level_config["deaths_2_stars"]:
				deaths_label.modulate = Color(1.0, 1.0, 0.3)  # Jaune
			else:
				deaths_label.modulate = Color(1.0, 0.5, 0.3)  # Orange
	
	# Mettre à jour les étoiles (prédiction)
	_update_stars_prediction()

func _update_stars_prediction() -> void:
	if not star1 or not star2 or not star3:
		return
	
	if level_config.is_empty():
		return
	
	var deaths := 0
	if has_node("/root/GameManager"):
		deaths = GameManager.death_count
	
	# Calculer les étoiles potentielles
	var predicted_stars := _calculate_predicted_stars(elapsed_time, deaths)
	
	# Mettre à jour les textures des étoiles
	if star_full_texture and star_empty_texture:
		star1.texture = star_full_texture if predicted_stars >= 1 else star_empty_texture
		star2.texture = star_full_texture if predicted_stars >= 2 else star_empty_texture
		star3.texture = star_full_texture if predicted_stars >= 3 else star_empty_texture
		
		# Ajuster l'opacité des étoiles vides
		star1.modulate.a = 1.0 if predicted_stars >= 1 else 0.4
		star2.modulate.a = 1.0 if predicted_stars >= 2 else 0.4
		star3.modulate.a = 1.0 if predicted_stars >= 3 else 0.4

func _calculate_predicted_stars(time: float, deaths: int) -> int:
	if level_config.is_empty():
		return 3
	
	var time_stars := 1
	var death_stars := 1
	
	# Étoiles basées sur le temps
	if time <= level_config.get("time_3_stars", 60):
		time_stars = 3
	elif time <= level_config.get("time_2_stars", 120):
		time_stars = 2
	
	# Étoiles basées sur les morts
	if deaths <= level_config.get("deaths_3_stars", 0):
		death_stars = 3
	elif deaths <= level_config.get("deaths_2_stars", 2):
		death_stars = 2
	
	# Moyenne des deux (arrondie vers le bas, minimum 1)
	return max(1, (time_stars + death_stars) / 2)

func _format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var secs := int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

# Fonction pour arrêter le timer (appelée quand le niveau est gagné)
func stop_timer() -> void:
	is_running = false
	print("⏱️ Timer arrêté à: ", _format_time(elapsed_time))

# Fonction pour redémarrer le timer
func restart_timer() -> void:
	elapsed_time = 0.0
	is_running = true
