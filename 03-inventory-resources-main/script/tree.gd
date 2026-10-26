extends Node2D

@export var item_resources: ItemData

func _on_area_2d_body_entered(body: Node2D) -> void:
	# 1. Проверяем, что вошел именно Игрок
	if body.name == 'Player':
		# 2. Проверяем, что у игрока РЕАЛЬНО отображается инструмент в руке (спрайт не пустой)
		if body.hand and body.hand.texture != null:
			# 3. Проверяем, что этот инструмент в логике существует
			if body.equipped_tool:
				# Переводим имя в нижний регистр, чтобы избежать ошибок с регистром букв (Axe/axe)
				var tool_name = body.equipped_tool.name.to_lower()
				
				# 4. Если это топор — рубим дерево!
				if tool_name == 'axe' or tool_name == 'топор':
					spawn_wood()
					queue_free()
					print("Дерево успешно срублено топором!")
					return

		# Если условия не выполнены, дерево не рубится
		print("Нельзя срубить! Топор должен быть в руках (активирован на ЛКМ).")

func spawn_wood():
	if item_resources:
		Global.add_item(item_resources)
