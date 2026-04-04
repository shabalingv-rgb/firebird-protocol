extends Button

func _on_test_violation_btn_pressed():
	GameState.add_violation()
	print("Нарушений: ", GameState.security_violations)
	if GameState.is_game_over:
		print("Вас уволили!")


func _on_pressed() -> void:
	_on_test_violation_btn_pressed()
