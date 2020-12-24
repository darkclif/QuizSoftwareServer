extends Node

# Consts
const IconsTexture = preload("res://resources/icons/icons.png")
const QuestionsFile : String = "questions.txt"

# Icons data
var ICON_SIZE = 200
var ICONS_PER_ROW = 5
var ICONS_COUNT = 10

# Dummy questions
var DummyQuestionList = [{
		"id": 9999,
		"question": "You see this question because question file was not loaded.",
		"answers": ["1", "2", "3", "4"]
	},
]

####################################################################
#	BASE
####################################################################
func _ready():
	pass 

####################################################################
#	PUBLIC
####################################################################
func get_icon_atlas(icon_id):
	var CorrectId = int(max(0, min(ICONS_COUNT - 1, icon_id)))
	
	if CorrectId != icon_id:
		print("Wrong icon id!")
	
	var NewAtlas = AtlasTexture.new()
	
	NewAtlas.atlas = IconsTexture
	NewAtlas.region = Rect2(
		(CorrectId % ICONS_PER_ROW) * ICON_SIZE,
		(CorrectId / ICONS_PER_ROW) * ICON_SIZE,
		ICON_SIZE,
		ICON_SIZE
	)
	
	return NewAtlas

func get_question_database():
	var QFile = File.new()
	var ReturnQuestions = self.DummyQuestionList
	
	# File does not exit
	var QuestionFilePath = Settings.get_root_folder().plus_file(QuestionsFile)
	if !QFile.file_exists(QuestionFilePath):
		GameState.add_console_line("[FATAL] Question file does not exist.")
		self.DummyQuestionList[0]['question'] += "(ERROR: File does not exist.)"
		return ReturnQuestions
	
	QFile.open(QuestionFilePath, File.READ)
	
	var Content = QFile.get_as_text()
	var Result = JSON.parse(Content)
	
	# Bad format
	if Result.error != OK:
		GameState.add_console_line("[FATAL] Bad JSON format in question file.")
		self.DummyQuestionList[0]['question'] += "(ERROR: Bad JSON format.)"
		return ReturnQuestions
		
	ReturnQuestions = Result.result 
	QFile.close()
	
	return ReturnQuestions

####################################################################
#	PUBLIC
####################################################################
func check_file_exists(path):
	var FileCheck = File.new()
	return FileCheck.file_exists(path)
