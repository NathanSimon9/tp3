extends Node

# === GAME MANAGER ===
# Autoload pour gérer la progression des niveaux et les étoiles
# Ajouter dans Project Settings > Autoload avec le nom "GameManager"

# Structure des données de niveau
# {
#   "niveau_1": {"unlocked": true, "completed": false, "stars": 0, "best_time": 999999, "best_deaths": 999},
#   "niveau_2": {"unlocked": false, "completed": false, "stars": 0, "best_time": 999999, "best_deaths": 999},
#   ...
# }

const SAVE_PATH := "user://game_progress.save"

# Configuration des niveaux
var levels_config := {
	"niveau_1": {
		"scene_path": "res://scenes/niveau_1.tscn",
		"name": "Niveau 1",
		"time_3_stars": 60.0,   # Temps max pour 3 étoiles (en secondes)
		"time_2_stars": 120.0,  # Temps max pour 2 étoiles
		"deaths_3_stars": 0,    # Morts max pour 3 étoiles
		"deaths_2_stars": 2,    # Morts max pour 2 étoiles
		"unlock_type": "default",  # Se débloque en complétant le niveau précédent
	},
	"niveau_2": {
		"scene_path": "res://scenes/niveau_2.tscn",
		"name": "Niveau 2",
		"time_3_stars": 90.0,
		"time_2_stars": 180.0,
		"deaths_3_stars": 1,
		"deaths_2_stars": 3,
		"unlock_type": "default",
	},
	"boss": {
		"scene_path": "res://scenes/boss.tscn",
		"name": "Boss Final",
		"time_3_stars": 120.0,
		"time_2_stars": 240.0,
		"deaths_3_stars": 0,
		"deaths_2_stars": 2,
		"unlock_type": "stars",  # Se débloque avec un nombre d'étoiles
		"stars_required": 4,     # Nombre d'étoiles requis
	}
}

# Données de progression du joueur
var progress_data := {}

# Données de la session en cours
var current_level := ""
var level_start_time := 0.0
var death_count := 0

func _ready() -> void:
	load_progress()

# === GESTION DE LA SAUVEGARDE ===

func save_progress() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(progress_data)
		file.close()
		print("💾 Progression sauvegardée!")

func load_progress() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			progress_data = file.get_var()
			file.close()
			print("📂 Progression chargée!")
	
	# Initialiser les données manquantes
	_initialize_missing_levels()

func _initialize_missing_levels() -> void:
	var level_keys: Array = levels_config.keys()
	for i in range(level_keys.size()):
		var level_id: String = level_keys[i]
		if not progress_data.has(level_id):
			var config: Dictionary = levels_config[level_id]
			var is_unlocked: bool = false
			
			# Premier niveau toujours débloqué
			if i == 0:
				is_unlocked = true
			# Niveau avec condition d'étoiles
			elif config.get("unlock_type", "default") == "stars":
				is_unlocked = get_total_stars() >= int(config.get("stars_required", 0))
			
			progress_data[level_id] = {
				"unlocked": is_unlocked,
				"completed": false,
				"stars": 0,
				"best_time": 999999.0,
				"best_deaths": 999
			}

# Vérifier et mettre à jour les déblocages (appelé après chaque changement)
func _check_unlocks() -> void:
	for level_id in levels_config.keys():
		var config: Dictionary = levels_config[level_id]
		if config.get("unlock_type", "default") == "stars":
			var required: int = config.get("stars_required", 0)
			if get_total_stars() >= required:
				if not progress_data[level_id]["unlocked"]:
					progress_data[level_id]["unlocked"] = true
					print("🔓 BOSS DÉBLOQUÉ! Étoiles: ", get_total_stars(), "/", required)

func reset_all_progress() -> void:
	progress_data.clear()
	_initialize_missing_levels()
	save_progress()
	print("🔄 Progression réinitialisée!")

# === GESTION DES NIVEAUX ===

func start_level(level_id: String) -> void:
	current_level = level_id
	level_start_time = Time.get_unix_time_from_system()
	death_count = 0
	print("🎮 Niveau démarré: ", level_id, " à ", level_start_time)

func add_death() -> void:
	death_count += 1
	print("💀 Mort #", death_count)

func complete_level() -> void:
	print("📍 complete_level() appelé - current_level = '", current_level, "'")
	
	if current_level.is_empty():
		print("⚠️ Aucun niveau en cours!")
		return
	
	if not progress_data.has(current_level):
		print("⚠️ Niveau '", current_level, "' non trouvé dans progress_data!")
		_initialize_missing_levels()
	
	var elapsed_time: float = Time.get_unix_time_from_system() - level_start_time
	var stars: int = calculate_stars(current_level, elapsed_time, death_count)
	
	print("🏆 Niveau terminé!")
	print("   📍 Niveau: ", current_level)
	print("   ⏱️ Temps: ", "%.1f" % elapsed_time, "s")
	print("   💀 Morts: ", death_count)
	print("   ⭐ Étoiles: ", stars)
	
	# Mettre à jour les données
	var level_data: Dictionary = progress_data[current_level]
	level_data["completed"] = true
	
	# Garder le meilleur score
	if stars > int(level_data["stars"]):
		level_data["stars"] = stars
		print("   🆕 Nouveau record d'étoiles!")
	if elapsed_time < float(level_data["best_time"]):
		level_data["best_time"] = elapsed_time
		print("   🆕 Nouveau record de temps!")
	if death_count < int(level_data["best_deaths"]):
		level_data["best_deaths"] = death_count
	
	# Mettre à jour le dictionnaire
	progress_data[current_level] = level_data
	
	# Débloquer le niveau suivant
	_unlock_next_level(current_level)
	
	# Vérifier les déblocages spéciaux (boss, etc.)
	_check_unlocks()
	
	save_progress()
	print("💾 Sauvegarde effectuée pour ", current_level, " avec ", level_data["stars"], " étoiles")

func calculate_stars(level_id: String, time: float, deaths: int) -> int:
	print("📊 Calcul étoiles pour ", level_id)
	print("   ⏱️ Temps: ", time, "s")
	print("   💀 Morts: ", deaths)
	
	if not levels_config.has(level_id):
		print("   ⚠️ Config non trouvée, retourne 1")
		return 1
	
	var config: Dictionary = levels_config[level_id]
	var time_stars: int = 1
	var death_stars: int = 1
	
	print("   📋 Config - time_3_stars: ", config["time_3_stars"], ", time_2_stars: ", config["time_2_stars"])
	print("   📋 Config - deaths_3_stars: ", config["deaths_3_stars"], ", deaths_2_stars: ", config["deaths_2_stars"])
	
	# Étoiles basées sur le temps
	if time <= float(config["time_3_stars"]):
		time_stars = 3
	elif time <= float(config["time_2_stars"]):
		time_stars = 2
	
	# Étoiles basées sur les morts
	if deaths <= int(config["deaths_3_stars"]):
		death_stars = 3
	elif deaths <= int(config["deaths_2_stars"]):
		death_stars = 2
	
	print("   ⭐ time_stars: ", time_stars, ", death_stars: ", death_stars)
	
	# Moyenne des deux (arrondie vers le bas, minimum 1)
	var result: int = max(1, (time_stars + death_stars) / 2)
	print("   🎯 Résultat final: ", result, " étoiles")
	return result

func _unlock_next_level(completed_level: String) -> void:
	var level_keys: Array = levels_config.keys()
	var current_index: int = level_keys.find(completed_level)
	
	if current_index >= 0 and current_index < level_keys.size() - 1:
		var next_level: String = level_keys[current_index + 1]
		var next_config: Dictionary = levels_config[next_level]
		
		# Ne pas débloquer automatiquement les niveaux avec condition spéciale
		if next_config.get("unlock_type", "default") == "default":
			progress_data[next_level]["unlocked"] = true
			print("🔓 Niveau débloqué: ", next_level)

# Obtenir le nombre d'étoiles requis pour un niveau
func get_stars_required(level_id: String) -> int:
	if levels_config.has(level_id):
		return int(levels_config[level_id].get("stars_required", 0))
	return 0

# Vérifier si un niveau a une condition d'étoiles
func has_star_requirement(level_id: String) -> bool:
	if levels_config.has(level_id):
		return levels_config[level_id].get("unlock_type", "default") == "stars"
	return false

# === GETTERS ===

func is_level_unlocked(level_id: String) -> bool:
	if progress_data.has(level_id):
		return progress_data[level_id]["unlocked"]
	return false

func is_level_completed(level_id: String) -> bool:
	if progress_data.has(level_id):
		return progress_data[level_id]["completed"]
	return false

func get_level_stars(level_id: String) -> int:
	if progress_data.has(level_id):
		return int(progress_data[level_id]["stars"])
	return 0

func get_level_best_time(level_id: String) -> float:
	if progress_data.has(level_id):
		return float(progress_data[level_id]["best_time"])
	return 999999.0

func get_total_stars() -> int:
	var total: int = 0
	for level_id in progress_data.keys():
		total += int(progress_data[level_id]["stars"])
	return total

func get_max_possible_stars() -> int:
	return levels_config.size() * 3

func get_all_levels() -> Array:
	return levels_config.keys()

func get_level_config(level_id: String) -> Dictionary:
	if levels_config.has(level_id):
		return levels_config[level_id]
	return {}
