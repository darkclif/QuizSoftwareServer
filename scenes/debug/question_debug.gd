extends Control

# Scenes
const PlayerIconSmallScene = preload("res://scenes/additional/player_card_small.tscn")
const COLOR_BLUE = Color8(150.0, 180.0, 255.0, 255.0)

# Question internal states
enum QuestionState {
	PRE_SPLASH = 1,			# show short splash screen before question
	MAIN_PHASE = 2,			# show question
	POST_PHASE = 3,			# make time for icons to move
	POST_WAIT_PHASE = 5,	# show correct question and then go next scene
	PAUSE_MODE = 4			# -- pause mode
}

enum QuestionType {
	UNKNOWN = 0
	NORMAL 	= 1,
	IMAGE 	= 2,
	VIDEO 	= 3
}

# Consts
const PRE_PHASE_TIME : float = 3.5
#const MAIN_PHASE_TIME : float = 60.0
#const POST_PHASE_TIME : float = 10.0
#const POST_WAIT_PHASE_TIME : float = 40.0

# FOR DEBUG:
const MAIN_PHASE_TIME : float = 3.0
const POST_PHASE_TIME : float = 3.0
const POST_WAIT_PHASE_TIME : float = 5.5

# Questions data
var QuestionData = null
var CurrentQuestionType = QuestionType.UNKNOWN

var QuestionId : int = -1
var QuestionText : String = ""
var AnswerList : Array = []
var CorrectAnswerId : int = 0 

var PlayerReadyCount : int = 0
var PlayerAnsweredCount : int = 0

class PlayerQuestionData:
	var AnswerId : int = -1
	var IconRef = null
	var Ready : bool = false

var PlayersDataDict : Dictionary = {} # PlayerRef -> PlayerQuestionData
var PlayerIconList : Array = []
var AnswerBoxes : Array = []

var CurrentTime : float = 0.0
var CurrentState = QuestionState.PAUSE_MODE
var StateBeforePause = CurrentState

# Debug
var DbgQuestionDatabase = null
var DbgQuestionNumber : int = 0

####################################################################
#	BASE
####################################################################
func _ready():
	$rectPause/labPause.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Prepare starting phase
	# self.setup_pre_phase()
	
	# Load question database
	self.DbgQuestionDatabase = ResourceManager.get_question_database()
	self.init(self.DbgQuestionDatabase[DbgQuestionNumber])
	
	# Attach events
	GameState.connect("LOGIC_PLAYER_ANSWERED", self, "_on_player_give_answer")
	GameState.connect("LOGIC_PLAYER_READY", self, "_on_player_ready")
	
	# Prepare array of answer boxes to map question number to control
	self.AnswerBoxes.append($contAnswers/ctrlAnswer1)
	self.AnswerBoxes.append($contAnswers/ctrlAnswer2)
	self.AnswerBoxes.append($contAnswers/ctrlAnswer3)
	self.AnswerBoxes.append($contAnswers/ctrlAnswer4)
		
	# Spawn icons and create player data
	var IconContainer = $contPlayerIcons
	var Players = GameState.get_players()
	
	for p in Players:
		var NewIcon = PlayerIconSmallScene.instance()
		PlayerIconList.append(NewIcon)
		NewIcon.init(p, PlayerIconList)
		
		var NewPlayerData = PlayerQuestionData.new()
		NewPlayerData.IconRef = NewIcon
		PlayersDataDict[p] = NewPlayerData
		
		IconContainer.add_child(NewIcon)
		

func _process(delta):
	if self.CurrentState == QuestionState.PRE_SPLASH:
		self.CurrentTime -= delta
		self.update_pre_timer_label()
		
		if self.CurrentTime <= 0.0:
			self.setup_main_phase()
			self.CurrentState = QuestionState.MAIN_PHASE
		
	elif self.CurrentState == QuestionState.MAIN_PHASE:
		self.CurrentTime -= delta
		self.update_timer_label()
		
		if self.CurrentTime <= 0.0:
			self.setup_post_phase()
			self.CurrentState = QuestionState.POST_PHASE
		
	elif self.CurrentState == QuestionState.POST_PHASE:
		self.CurrentTime -= delta
		self.update_timer_label()
		
		if self.CurrentTime <= 0.0:
			self.setup_post_wait_phase()
			self.CurrentState = QuestionState.POST_WAIT_PHASE
	
	elif self.CurrentState == QuestionState.POST_WAIT_PHASE:
		self.CurrentTime -= delta
		self.update_timer_label()

		if self.CurrentTime <= 0.0:
			self.next_scene()
	
	elif self.CurrentState == QuestionState.PAUSE_MODE:
		pass

####################################################################
#	SETUP PHASES
####################################################################
func setup_pre_phase():
	# Setup pre phase
	self.CurrentTime = PRE_PHASE_TIME
	$rectSplash.visible = true
	self.update_pre_timer_label()

func setup_main_phase():
	# Hide pre splash screen
	$rectSplash.visible = false
	
	# Start video if video question
	if self.CurrentQuestionType == QuestionType.VIDEO:
		$ctrlVideoQuestion/vidVideoPlayer.play()
	
	# Set timer
	self.CurrentTime = MAIN_PHASE_TIME
	self.update_timer_label()
	
	# Send question to players
	GameState.send_question_to_players(self.QuestionData)

func setup_post_phase():
	# Change timer look
	self.CurrentTime = POST_PHASE_TIME
	$rectBgTimer.visible = false
	
	# Stop video if video question
	if self.CurrentQuestionType == QuestionType.VIDEO:
		$ctrlVideoQuestion/vidVideoPlayer.stop()
	
	# Clear icons from answer indicator
	for p in self.PlayersDataDict:
		self.PlayersDataDict[p].IconRef.set_answer_indicator(false)
	
	# Icons movement
	self.push_icon_to_answers()
	
func setup_post_wait_phase():
	# Change timer look
	self.CurrentTime = POST_WAIT_PHASE_TIME
	$rectBgTimer.modulate = COLOR_BLUE
	$rectBgTimer.visible = true
	self.update_timer_label()

	# Show correct answer
	self.AnswerBoxes[self.CorrectAnswerId].set_correct()
	
	# Send correct question to players
	GameState.send_correct_answer_to_players(self.QuestionId, self.CorrectAnswerId)
	
	# Count points
	for p in self.PlayersDataDict:
		var Data = self.PlayersDataDict[p]
		
		if Data.AnswerId == self.CorrectAnswerId:
			p.add_point()

func next_scene():
	# Preceed to next scene
	self.queue_free()
	GameState.transition_question_to_next()

####################################################################
#	PRIVATE
####################################################################
func set_answer_boxes_texts():
	$contAnswers/ctrlAnswer1.set_text(self.AnswerList[0])
	$contAnswers/ctrlAnswer2.set_text(self.AnswerList[1])
	$contAnswers/ctrlAnswer3.set_text(self.AnswerList[2])
	$contAnswers/ctrlAnswer4.set_text(self.AnswerList[3])

func update_timer_label():
	$rectBgTimer/labTimerText.text = str(int(self.CurrentTime))

func update_pre_timer_label():
	$rectSplash/labSplashTimer.text = str(int(self.CurrentTime))

func push_icon_to_answers():
	for p in self.PlayersDataDict:
		var Data = self.PlayersDataDict[p]
		
		if Data.AnswerId != -1:
			# Player answered question
			var BoxPos = self.AnswerBoxes[Data.AnswerId].get_center()
			Data.IconRef.go_to(BoxPos)
			
			# Detach from contPlayerIcons
			var GlobalPos = Data.IconRef.rect_global_position
			
			$contPlayerIcons.remove_child(Data.IconRef)
			self.add_child(Data.IconRef)
			
			Data.IconRef.rect_global_position = GlobalPos

####################################################################
#	PUBLIC
####################################################################
func init(question):
	$ctrlNormalQuestion.visible = false
	$ctrlImageQuestion.visible = false
	$ctrlVideoQuestion.visible = false
	$ctrlVideoQuestion/vidVideoPlayer.stop()
	
	# Make some data shortcuts
	self.QuestionData = question # we will send this data to a player soon
	
	self.QuestionId = question["id"]
	self.QuestionText = question["question"]
	
	# Shuffle, but we must know where is answer that was on 0 index (correct answer)
	var TmpAnswerList = question["answers"]
	var Permutation = range(4)
	Permutation.shuffle()
	
	self.AnswerList = []
	for p in Permutation:
		self.AnswerList.append(TmpAnswerList[p])
	
	# Set correct answer number after shuffle and keep shuffled order for players
	self.CorrectAnswerId = Permutation.rfind(0)
	self.QuestionData['answers'] = self.AnswerList
	
	self.setup_question()
	self.set_answer_boxes_texts()

func setup_question():
	# Check question type
	if self.QuestionData.has('img'):
		self.init_image_question()
		self.CurrentQuestionType = QuestionType.IMAGE
	elif self.QuestionData.has('vid'):
		self.init_video_question()
		self.CurrentQuestionType = QuestionType.VIDEO
	else:
		self.init_normal_question()
		self.CurrentQuestionType = QuestionType.NORMAL

func init_normal_question():
	# Normal
	$ctrlNormalQuestion.visible = true
	
	# Set text
	$ctrlNormalQuestion/labQuestionText.text = self.QuestionText

func init_image_question():
	# Image
	$ctrlImageQuestion.visible = true
	
	# Set text
	$ctrlImageQuestion/labQuestionTextSmall.text = self.QuestionText
	
	# Set image
	var ImageSrc = "res://question_images/" + str(self.QuestionData['img'])
	
	var FileCheck = File.new()
	if FileCheck.file_exists(ImageSrc):
		$ctrlImageQuestion/rectImage.texture = load(ImageSrc)
	else:
		GameState.add_console_line("[LOGIC][ERROR] Cannot load image to a question. Src: '%s'" % (ImageSrc))

func init_video_question():
	# Video
	$ctrlVideoQuestion.visible = true
	
	# Set text
	$ctrlVideoQuestion/labQuestionRight.text = self.QuestionText
	
	# Set video
	var VideoSrc = "res://question_videos/" + str(self.QuestionData['vid'])
	
	var FileCheck = File.new()
	if FileCheck.file_exists(VideoSrc):
		var Stream = VideoStreamWebm.new()
		Stream.set_file(VideoSrc)
		
		$ctrlVideoQuestion/vidVideoPlayer.set_stream(Stream)
		$ctrlVideoQuestion/vidVideoPlayer.play()
	else:
		GameState.add_console_line("[LOGIC][ERROR] Cannot load video to a question. Src: '%s'" % (VideoSrc))
	
####################################################################
#	HANDLERS
####################################################################
func _on_player_give_answer(player_ref, question_id, answer_id):
#	if self.CurrentState != QuestionState.MAIN_PHASE:
#		GameState.add_console_line("[WARNING] Player tried to answer but MAIN_PHASE passed.")
#		return
	
	if question_id != self.QuestionId:
		GameState.add_console_line("[WARNING] Player tried to answer but provided invalid question id.")
		return

	if !PlayersDataDict.has(player_ref):
		GameState.add_console_line("[WARNING] Player not present in QuestionScene tried to answer question.")
		return
		
	var PlayerData = PlayersDataDict[player_ref]
	if PlayerData.AnswerId != -1:
		GameState.add_console_line("[WARNING] Player tried to answer two times for the same question.")
		return 
	
	self.PlayerAnsweredCount += 1
	if self.PlayerAnsweredCount == self.PlayersDataDict.size():
		self.CurrentTime = min(self.CurrentTime, 5.0)
	
	PlayerData.AnswerId = answer_id
	PlayerData.IconRef.set_answer_indicator(true)

func _on_player_ready(player_ref):
	# Accept only in waiting phase
	if self.CurrentState != QuestionState.POST_WAIT_PHASE:
		return
		
	if !self.PlayersDataDict.has(player_ref):
		GameState.add_console_line("[WARNING] Player not present in QuestionScene tried to be ready.")
		return
		
	# Set data
	if !self.PlayersDataDict[player_ref].Ready:
		var PlayerData = self.PlayersDataDict[player_ref]

		PlayerData.IconRef.set_answer_indicator(true)
		PlayerData.Ready = true
		self.PlayerReadyCount += 1
	
	# Check for preceed
	if self.PlayersDataDict.size() == self.PlayerReadyCount:
		self.CurrentTime = min(self.CurrentTime, 5.0)

func _on_labPause_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == BUTTON_LEFT:
		if self.CurrentState == QuestionState.PAUSE_MODE:
			self.CurrentState = self.StateBeforePause
			
			$rectPause/labPause.text = "Pause"
		else:
			self.StateBeforePause = self.CurrentState
			self.CurrentState = QuestionState.PAUSE_MODE
		
			$rectPause/labPause.text = "Unpause"

func _on_Button_pressed():
	self.DbgQuestionNumber -= 1
	if self.DbgQuestionNumber < 0:
		self.DbgQuestionNumber = self.DbgQuestionDatabase.size() - 1
	self.init(self.DbgQuestionDatabase[DbgQuestionNumber])
	
func _on_Button2_pressed():
	self.DbgQuestionNumber += 1
	if self.DbgQuestionNumber > self.DbgQuestionDatabase.size() - 1:
		self.DbgQuestionNumber = 0
	self.init(self.DbgQuestionDatabase[DbgQuestionNumber])
