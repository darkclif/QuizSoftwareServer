extends Control

# Scenens 
const PlayerEndGameScene = preload("res://scenes/additional/end_game_player_card.tscn")

# Custom player sorting 
class PlayerSorterClass:
	static func sort(p1, p2):
		return p1.get_points() > p2.get_points()

####################################################################
#	BASE
####################################################################
func _ready():
	pass

####################################################################
#	PUBLIC
####################################################################
func init(players_list):
	# Sort array by points
	var Players = players_list.duplicate()
	Players.sort_custom(PlayerSorterClass, 'sort')
	
	var i : int = 0
	for p in Players:
		var NewPlayerScene = PlayerEndGameScene.instance()
		NewPlayerScene.init(p, i)
		$contPlayers.add_child(NewPlayerScene)
		
		i += 1
