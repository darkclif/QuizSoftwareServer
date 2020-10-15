extends Control

const POINTS_SUFIX : String = " pts"
const LAST_POINTS_FORMAT : String = "+ %d pts"

####################################################################
#	BASE
####################################################################
func _ready():
	pass

####################################################################
#	PUBLIC
####################################################################
func init(player, max_pts):
	var Points = player.get_points()
	var FillValue = (float(Points) / float(max_pts)) * $progPoints.max_value
	$progPoints.value = FillValue
	$labStartGame.text = str(Points) + POINTS_SUFIX
	$labLastPoints.text = LAST_POINTS_FORMAT % (player.clear_last_points())
	
	$contIcon.init(player)
	
