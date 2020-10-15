extends Control

# Map: PlayerRef <-> PlayerCardInstance
var PlayersCards = {}
const PlayerCardScene = preload("res://scenes/additional/player_cloud_card.tscn")

####################################################################
#	BASE
####################################################################
func _ready():
	pass

func _process(delta):
	pass

####################################################################
#	PUBLIC
####################################################################
func remove_player_card(player):
	if !PlayersCards.has(player):
		print("There is no card of given player within a cloud.")
	else:
		self.remove_child(PlayersCards[player])
		PlayersCards.erase(player)
		self.update_player_text()
				
func add_player_card(player):
	if !PlayersCards.has(player):
		var NewCard = PlayerCardScene.instance()
		
		NewCard.init(self, player)
		NewCard.rect_position += Vector2(250.0, 0.0).rotated(2 * PI * randf())
		PlayersCards[player] = NewCard
		
		self.add_child(NewCard)
		self.update_player_text()
	else:
		print("There is already card of this player in the cloud.")

func get_player_cards():
	return PlayersCards.values()

func update_player_text():
	if PlayersCards.size() == 1:
		$PlayersCounter.text = "1 player"
	else:
		$PlayersCounter.text = str(PlayersCards.size()) + " players"
		
