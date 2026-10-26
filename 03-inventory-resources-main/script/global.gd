extends Node 

# --- СИГНАЛЫ ---
signal item_collected(item_name: String)
signal inventory_updated 

# --- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ И ОГРАНИЧЕНИЕ ---
var player_name: String = ""
var active_slot_index: int = 0 
var inventory: Array[ItemData] = [] 

# --- ЛИМИТ ИНВЕНТАРЯ: Ставим максимум 10 уникальных слотов ---
@export var max_inventory_size: int = 10 


# --- МЕТОД ДОБАВЛЕНИЯ ПРЕДМЕТА ---
func add_item(new_item: ItemData) -> bool:
	if not new_item: return false
	
	# Сначала ищем, есть ли уже такой предмет в инвентаре (для стаканья)
	var existing_item = null
	for item in inventory:
		if item.name == new_item.name:
			existing_item = item
			break
	
	# ЕСЛИ ПРЕДМЕТ НАЙДЕН — увеличиваем количество в существующем слоте
	if existing_item and not existing_item.is_tool:
		existing_item.amount += 1
		print("Стаканье: Количество ", existing_item.name, " увеличено до ", existing_item.amount)
		inventory_updated.emit()
		return true # Предмет успешно добавлен в стак (новые слоты не заняты)
		
	# ЕСЛИ ЭТО НОВЫЙ ПРЕДМЕТ — проверяем, не превышен ли лимит в 10 слотов
	if inventory.size() < max_inventory_size:
		new_item.amount = 1 
		inventory.append(new_item)
		print("Новый слот: Предмет ", new_item.name, " добавлен в инвентарь. Занято слотов: ", inventory.size(), "/", max_inventory_size)
		inventory_updated.emit()
		return true # Новый слот успешно добавлен
	else:
		print("Инвентарь полон! Максимум ", max_inventory_size, " предметов. Нельзя подобрать: ", new_item.name)
		return false # Места нет, подбор отклонен
