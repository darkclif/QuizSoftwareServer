extends Control

var TmpPlayers = []

####################################################################
#	BASIC
####################################################################
func _ready():
	$labStartGame.mouse_filter = Control.MOUSE_FILTER_PASS

	# Events
	GameState.connect("LOGIC_NEW_PLAYER", self, "_on_new_player")
	GameState.connect("LOGIC_REMOVE_PLAYER", self, "_on_remove_player")

func _process(delta):   
	pass
	
####################################################################
#	LOGIC
####################################################################
func show_settings():
	get_tree().get_root().add_child(GameState.sceneSettings)

func _on_new_player(player):
	$PlayersCloud.add_player_card(player)	

func _on_remove_player(player):
	$PlayersCloud.remove_player_card(player)

####################################################################
#	BUTTONS
####################################################################
func _on_labStartGame_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		self.queue_free()
		GameState.transition_main_to_question()

func _on_btnSettings_pressed():
	self.show_settings()
