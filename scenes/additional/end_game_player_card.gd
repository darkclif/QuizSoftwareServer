extends Control

# Consts
const COLOR_1 = Color8(237, 228, 45, 255)
const COLOR_2 = Color8(209, 209, 199, 255)
const COLOR_3 = Color8(242, 164, 61, 255)
const COLOR_N = Color8(255, 255, 255, 255)

const COLOR_ARRAY : Array = [COLOR_1, COLOR_2, COLOR_3, COLOR_N]
const POSITION_SUFIXES : Array = ['st', 'nd', 'rd', 'th']

const POINTS_FORMAT : String = "(%d pts)"

####################################################################
#	BASE
####################################################################
func _ready():
	pass
	
####################################################################
#	PUBLIC
####################################################################
func init(player = null, place : int = 0):
	# player = null only while debugging
	if !player:
		player = GameState.get_dummy_player()
	
	# Set icon
	$ctrlIcon.init(player)
	
	# Set position text
	$labPlace.text = str(1 + place) + ' ' + POSITION_SUFIXES[clamp(place, 0, 3)]
	$labPlace.modulate = COLOR_ARRAY[clamp(place, 0, 3)]
	
	# Set points
	$labScore.text = POINTS_FORMAT % (player.get_points())
	
	# Set statistics
	$gridStats/labRatio.text = "%.2f %%" % float(player.get_correct_answer_ratio())
	$gridStats/labAverage.text = "%.1f sec." % float(player.get_average_answer_time())
	$gridStats/labBestStreak.text = str(player.get_best_streak())
	$gridStats/labWorstStreak.text = str(player.get_worst_streak())
	$gridStats/labBlunders.text = str(player.get_blunders())
