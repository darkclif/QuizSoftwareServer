extends Control

# Scenes
const PlayerSummaryScene = preload("res://scenes/additional/summary_player.tscn")

# Consts
const NEXT_QUESTION_TIMER : float = 10.5

# Vars
var NextQuestionTimer : float = 0.0
var Pause : bool = false

# Custom player sorting 
class PlayerSorterClass:
	static func sort(p1, p2):
		return p1.get_points() > p2.get_points()

####################################################################
#	BASE
####################################################################
func _ready():
	var Players = GameState.get_players().duplicate()
	
	# Get max points to adjust progress bar
	var MaxPoints = 1
	for p in Players:
		if p.get_points() > MaxPoints:
			MaxPoints = p.get_points()
	
	# Sort players
	Players.sort_custom(PlayerSorterClass, 'sort')
	
	# Spawn players
	for p in Players:
		var NewSummary = PlayerSummaryScene.instance()
		NewSummary.init(p, MaxPoints)
		
		$hboxPlayers.add_child(NewSummary)
	
	# Set timer
	self.NextQuestionTimer = NEXT_QUESTION_TIMER

func _process(delta):
	if !self.Pause:
		self.NextQuestionTimer -= delta
		$labCounter.text = str(int(self.NextQuestionTimer))
	
	if self.NextQuestionTimer <= 0.0:
		self.show_next_question()
		
####################################################################
#	PUBLIC
####################################################################
func _on_btnPause_toggled(button_pressed):
	self.Pause = button_pressed
		
####################################################################
#	PRIVATE
####################################################################
func show_next_question():
	# Show next question
	self.queue_free()
	GameState.transition_summary_to_question()



