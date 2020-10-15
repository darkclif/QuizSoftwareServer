extends Node

# Signals for game logic
signal LOGIC_NEW_PLAYER(player)
signal LOGIC_REMOVE_PLAYER(player)
signal LOGIC_PLAYER_INFO_REFRESHED(player)
signal LOGIC_PLAYER_CONNECTED_CHANGE(player, flag)
signal LOGIC_PLAYER_ANSWERED(player, question_id, answer_id)
signal LOGIC_PLAYER_READY(player)

# Scenes
const QuestionScene = preload("res://scenes/base/question.tscn")
const GameEndScene = preload("res://scenes/base/game_end.tscn")
const SummaryScene = preload("res://scenes/base/summary.tscn")

var playerClass = preload("res://scripts/player.gd")
var sceneSettingsRes = preload("res://scenes/debug/settings.tscn")

# Global scenes
var sceneSettings = null

# Game flow
enum GameState {
	IDLE 			= 0,
	SHOW_QUESTION 	= 1,
#	END_QUESTION	= 2,
	SUMMARY			= 3,
	END_GAME		= 4
}

# Question format:
#{
#	"id": int_id
#	"question": "",
#	"answers": [4 : String]
#}
var QuestionDatabase = []

const SUMMARY_DELAY : int = 4 # 0 = no summary
var CurrentQuestionID : int = -1
var CurrentGameState = GameState.IDLE

# For save
const SaveFileSrc = "res://save.json"
var AnsweredQuestionsIds = []

# Game
var players = []
var playerIdCurr = 0 # player id counter

####################################################################
#	BASE
####################################################################
func _ready():
	randomize()
	
	# Network
	NetworkState.connect("PCK_CONNECTION_WANT", self, "_connection_want_received")
	NetworkState.connect("PCK_INFO_UPDATE", self, "_info_update_received")
	NetworkState.connect("PCK_GIVE_ANSWER", self, "_give_answer_received")
	NetworkState.connect("PCK_PLAYER_READY", self, "_player_ready_received")

	self.sceneSettings = sceneSettingsRes.instance()

func _process(delta):
	pass

####################################################################
#	PUBLIC
####################################################################
func add_console_line(line):
	print(line)
	self.sceneSettings.add_console_line(line)

func get_players():
	return self.players
	
func get_current_question_data():
	if self.CurrentQuestionID < 0 or self.CurrentQuestionID >= self.QuestionDatabase.size():
		return null
	else:
		return self.QuestionDatabase[self.CurrentQuestionID]

func save_to_file():
	var SaveFile = File.new()
	SaveFile.open(SaveFileSrc, File.WRITE)

	# Serialize player data
	var PlayersData = []
	for p in self.players:
		PlayersData.append(p.get_serialized())
		
	# Prepare data
	var SaveData = {}
	SaveData['questions'] = self.AnsweredQuestionsIds
	SaveData['players'] = PlayersData
	
	# Save to file
	SaveFile.store_buffer(JSON.print(SaveData).to_utf8())
	SaveFile.close()

####################################################################
#	LOGIC
####################################################################
func get_next_player_id():
	playerIdCurr += 1
	return playerIdCurr

func push_scene(scene):
	get_tree().get_root().add_child(scene)	

func push_next_question_scene():
	# Save game data before each question
	self.save_to_file()
	
	# Push question scene
	var NextQuestion = self.get_current_question_data()
	
	if NextQuestion.has('id'):
		self.AnsweredQuestionsIds.append(NextQuestion['id'])
	
	var NewScene = QuestionScene.instance()
	NewScene.init(NextQuestion)
	self.push_scene(NewScene)

####################################################################
#	SCENE TRANSITION
####################################################################
# Question -> Question/End/Summary
func transition_question_to_next():
	# Abort when transition from wrong state
	if CurrentGameState != GameState.IDLE and !CurrentGameState != GameState.SUMMARY:
		return
	
	self.CurrentQuestionID += 1
	# Check if out of questions
	if self.CurrentQuestionID < self.QuestionDatabase.size():
		# Check for show summary
		if SUMMARY_DELAY != 0 and !(CurrentQuestionID % SUMMARY_DELAY):
			# Show summary
			var NewScene = SummaryScene.instance()
			self.push_scene(NewScene)

			self.CurrentGameState = GameState.SUMMARY
		else:
			# Push question scene
			self.push_next_question_scene()
			
			self.CurrentGameState = GameState.SHOW_QUESTION
	else:
		# End game
		var NewScene = GameEndScene.instance()
		NewScene.init(self.players)
		self.push_scene(NewScene)
		
		self.add_console_line("[INFO] Game ended.")
		self.CurrentGameState = GameState.END_GAME

# Summary -> Question
func transition_summary_to_question():
	# Abort when transition from wrong state
	if CurrentGameState != GameState.SUMMARY:
		return
		
	# Push question scene
	self.push_next_question_scene()
	
	self.CurrentGameState = GameState.SHOW_QUESTION

# Main -> Summary
func transition_main_to_question():
	# Start
	if CurrentGameState != GameState.IDLE:
		return
	
	# Prepare to start new game
	self.CurrentQuestionID = 0
	
	# Load question database
	QuestionDatabase = ResourceManager.get_question_database()
	QuestionDatabase.shuffle()

	# Push scene
	if self.CurrentQuestionID < self.QuestionDatabase.size():
		self.add_console_line("[INFO] Game started.")
		
		var NewScene = SummaryScene.instance()
		self.push_scene(NewScene)
		
		self.CurrentGameState = GameState.SUMMARY
	else:
		# Probably question not loaded?
		self.add_console_line("[ERROR] No question in database. Game ended.")
		self.CurrentGameState = GameState.END_GAME

####################################################################
#	NETWORK
####################################################################
func set_player_connected(player, flag):
	player.set_connected(flag)
	self.emit_signal('LOGIC_PLAYER_CONNECTED_CHANGE', player, flag)

func create_new_player(nick, icon_id, uid):
	var NewPlayerId = get_next_player_id() 
	var NewPlayer = playerClass.new()
	NewPlayer.init(NewPlayerId, nick, icon_id, uid)
	self.players.append(NewPlayer)
	
	self.emit_signal("LOGIC_NEW_PLAYER", NewPlayer)
	return NewPlayer

func send_question_to_players(question_data):
	for p in self.players:
		NetworkState.question_send_send(p, question_data)
		
func send_correct_answer_to_players(question_id, correct_id):
	for p in self.players:
		NetworkState.question_correct_send(p, question_id, correct_id)

####################################################################
#	HANDLERS
####################################################################
#func _connection_want_received(ip, device_id):
#	pass

func _info_update_received(player, dict):
	# Check data correctness
	var NewNick = dict['nick']
	if NewNick.length() < 3 or NewNick.length() > 12:
		add_console_line('[LOGIC] Invalid nick.')
		return
	
	var NewIconId = dict['icon_id']
	if NewIconId < 0 or NewIconId > 9:
		add_console_line('[LOGIC] Invalid icon id.')
		return
	
	# Correct
	player.info_update(NewNick, NewIconId)
	self.emit_signal("LOGIC_PLAYER_INFO_REFRESHED", player)

func _give_answer_received(player, dict):
	if not players.has(player):
		add_console_line('[LOGIC][ERROR] Player wanted to answer but is not in game.')
		return

	var QuestionId = dict['question_number']
	var AnswerId = dict['answer_number']
	
	# Check answer valid
	if AnswerId < 0 or AnswerId > 3:
		add_console_line('[LOGIC][ERROR] Player send invalid answer id.')
		return
	
	# Correct
	self.emit_signal("LOGIC_PLAYER_ANSWERED", player, QuestionId, AnswerId)
	
func _player_ready_received(player, dict):
	if not players.has(player):
		add_console_line('[LOGIC][ERROR] Player wanted to answer but is not in game.')
		return
	
	# Correct
	self.emit_signal("LOGIC_PLAYER_READY", player)

func _i_am_lost_received(player_id):
	var findPlayer = null
	if players.has(player_id):
		findPlayer = players[player_id]
		
	if not findPlayer:
		add_console_line('[LOGIC][ERROR] Cannot find player with id %s' % str(player_id))
		return
	
	# Correct
	NetworkState.you_are_here_send(player_id, int(CurrentGameState), findPlayer.nick, findPlayer.iconId)
		
		
