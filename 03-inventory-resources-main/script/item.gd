extends Node2D

@export var item_resources: ItemData
@export var sprite: Sprite2D

# Кулдаун, чтобы предмет не подбирался в ту же милисекунду, когда вылетел из игрока
var is_ready_to_pickup: bool = false

func _ready() -> void:
	# Настраиваем текстуру
	if item_resources and sprite:
		sprite.texture = item_resources.icon
	
	# ЖЕСТКАЯ НАСТРОЙКА ФИЗИКИ: Включаем сканирование коллизий, если забыли в инспекторе
	var area = get_node_or_null("Area2D")
	if area:
		area.monitoring = true
		area.monitorable = true
		# Если сигнал не привязан в инспекторе, привязываем его кодом для надежности
		if not area.body_entered.is_connected(_on_area_2d_body_entered):
			area.body_entered.connect(_on_area_2d_body_entered)

	# Через 0.4 секунды разрешаем подбирать предмет
	await get_tree().create_timer(0.4).timeout
	is_ready_to_pickup = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Проверяем кулдаун
	if not is_ready_to_pickup:
		return
		
	# Проверяем игрока по имени ИЛИ по принадлежности к классу/группе
	if body.name == "Player" or body.is_in_group("Player"):
		if item_resources:
			# Добавляем в глобальный инвентарь
			Global.add_item(item_resources)
			
			# Оповещаем систему, что инвентарь обновился (чтобы обновились слоты на экране)
			if Global.has_signal("inventory_updated"):
				Global.inventory_updated.emit()
				
			print("Успешно подобрано: ", item_resources.name)
			queue_free() # Уничтожаем предмет в мире
