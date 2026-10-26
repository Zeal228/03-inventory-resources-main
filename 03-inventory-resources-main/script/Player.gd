extends CharacterBody2D

var speed = 40

# --- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ИГРОКА ---
var is_sitting: bool = false 
var is_tool_equipped: bool = false  
@export var item_resources: ItemData
@export var hand: Sprite2D
@export var anim: AnimatedSprite2D

var equipped_tool: ItemData = null # Текущий инструмент в логике (для проверки деревом)

func _ready():
	if has_node("Label"):
		$Label.text = Global.player_name
	Global.add_item(item_resources)	
	
	# --- СВЕРХНАДЕЖНЫЙ АВТОНОМНЫЙ ЧИТ-КОД ---
	# Если оригинальный файл ресурса поврежден или не найден, создаем инструмент прямо в памяти!
	var test_axe = load("res://resources/axe.tres") 
	if not test_axe:
		test_axe = ItemData.new()
		test_axe.name = "axe"
		test_axe.is_tool = true
		# Загружаем любую стандартную иконку Godot для теста, если вашей нет
		test_axe.icon = load("res://icon.svg") 
	
	# Очищаем инвентарь от багов и принудительно кладем туда наш рабочий топор
	Global.inventory.clear()
	Global.inventory.append(test_axe)
	Global.active_slot_index = 0
	
	# Сразу принудительно привязываем его к переменной экипировки
	equipped_tool = test_axe
	is_tool_equipped = true
	print("Защищенный тестовый топор успешно внедрен в слот 0!")

func _physics_process(_delta):
	var input = Vector2(
		Input.get_action_strength('ui_right') - Input.get_action_strength('ui_left'), 
		Input.get_action_strength('ui_down') - Input.get_action_strength('ui_up'))
	velocity = input.normalized() * speed
	
	if is_sitting:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# ЗАДАЧА 02: Поворот спрайта
	if input.x > 0:
		anim.flip_h = true
		if hand: hand.flip_h = true
	elif input.x < 0:
		anim.flip_h = false
		if hand: hand.flip_h = false
		
	if input != Vector2.ZERO:
		anim.play('walk')
	else:
		anim.play('idle')
		
	move_and_slide()

# --- СИСТЕМА ВЫБОРА (C9): Безопасное обновление слотов ---
func update_hand_visual():
	# Принудительно очищаем руку визуально при прокрутке колесика
	if hand:
		hand.texture = null 
	
	if Global.inventory.size() > 0:
		var current_index = Global.active_slot_index % Global.inventory.size()
		var item = Global.inventory[current_index]
		if item:
			equipped_tool = item if item.is_tool else null
			is_tool_equipped = item.is_tool
			return
			
	equipped_tool = null
	is_tool_equipped = false

func change_selection(direction: int):
	if Global.inventory.size() == 0: return
	
	Global.active_slot_index = (Global.active_slot_index + direction) % Global.inventory.size()
	if Global.active_slot_index < 0: Global.active_slot_index = Global.inventory.size() - 1
	
	update_hand_visual()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('drop_item'):
		drop_item()
	# Колесико мыши: переключение слотов
	if event.is_action_pressed('next_item'):
		change_selection(1)
	if event.is_action_pressed('prev_item'):
		change_selection(-1)
		
	# --- НАЖАТИЕ ЛКМ (use_tool): Жесткая и гарантированная активация топора ---
	if event.is_action_pressed('use_tool'):
		# Подстраховка: если из-за прокрутки сбились переменные, берем топор напрямую из инвентаря
		if not equipped_tool and Global.inventory.size() > 0:
			var item = Global.inventory[Global.active_slot_index % Global.inventory.size()]
			if item and item.is_tool:
				equipped_tool = item

		# Визуальное переключение (Задача 01)
		if equipped_tool:
			if hand.texture == null:
				hand.texture = equipped_tool.icon
				print("Успех: Топор отображен в руке!")
			else:
				hand.texture = null
				print("Успех: Топор убран из руки!")
					
	# Блок взаимодействия (сидение)
	if event.is_action_pressed('interact'):
		if is_sitting:
			is_sitting = false
			anim.play('idle')
		else:
			is_sitting = true
			anim.play('sit')

@export var item_world_scene: PackedScene

func drop_item():
	if Global.inventory.size() > 0:
		# Высчитываем безопасный текущий индекс слота
		var current_index = Global.active_slot_index % Global.inventory.size()
		var item_to_drop = Global.inventory[current_index]
		
		if item_to_drop:
			# 1. Спавним ровно ОДНУ штуку в мире под ногами
			spawn_dropped_item(item_to_drop)
			
			# 2. ЕСЛИ В СТАКЕ БОЛЬШЕ ОДНОГО ПРЕДМЕТА — просто уменьшаем количество на 1
			if item_to_drop.amount > 1:
				item_to_drop.amount -= 1
				print("Выброшена 1 шт. В инвентаре осталось: ", item_to_drop.amount)
			else:
				# 3. ЕСЛИ ПРЕДМЕТ БЫЛ ПОСЛЕДНИМ (amount == 1) — полностью удаляем слот
				Global.inventory.remove_at(current_index)
				print("Слот инвентаря полностью очищен.")
		
		# Корректируем индекс, чтобы он не улетел за границы массива после удаления
		Global.active_slot_index = clamp(Global.active_slot_index, 0, Global.inventory.size() - 1)
		
		# Обновляем интерфейс и руку игрока
		Global.inventory_updated.emit()
		update_hand_visual()

func spawn_dropped_item(item_to_drop: ItemData):
	var new_item = item_world_scene.instantiate()
	
	# 1. Передаем данные ресурса ДО добавления на сцену
	new_item.item_resources = item_to_drop
	
	# 2. Добавляем предмет на карту
	get_tree().current_scene.add_child(new_item)
	
	# 3. ИСПОЛЬЗУЕМ ГЛОБАЛЬНЫЕ КООРДИНАТЫ (Устраняет баг улетания предмета в пустоту)
	var random_offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
	new_item.global_position = self.global_position + random_offset
	
	print("Предмет успешно выброшен в глобальной точке: ", new_item.global_position)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == 'Player':
		get_tree().change_scene_to_file("res://scenes/mushrooms.tscn")
