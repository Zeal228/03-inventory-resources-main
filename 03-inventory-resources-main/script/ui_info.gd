extends Control

# Ссылки на узлы внутри контейнеров
@onready var name_input = $VBoxContainer/HBoxContainer/TextEdit
@onready var start_button = $VBoxContainer/Button


func _on_start_button_pressed():
	# Получаем текст из поля и убираем случайные пробелы по бокам
	var player_name = name_input.text.strip_edges()
	
	# Проверка из задания: имя должно быть больше 2 символов
	if player_name.length() <= 2:
		print("Ошибка: Имя слишком короткое! Нужно больше 2 символов.")
		# Тут можно выкрасить рамку в красный или изменить текст в Label
		return
		
	Global.player_name = player_name
	
	# Меняем сцену на вашу игровую карту
	get_tree().change_scene_to_file("res://scenes/Forest.tscn") # Укажите правильный путь к карте
