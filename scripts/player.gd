extends Node

# Data
#var InfoUpdated = false # if info was updated by player at least once
var Connected = true

var DeviceUID = null
var PlayerId = -1

var Nick : String = ""
var IconId : int = 0

# In game
var Points : int = 0
var LastPoints : int = 0
var LastAnsweredQuestionId : int = -1

#
# Additional stats
#
var CurrentPointsStreak : int = 0 # correct in row
var BestPointsStreak : int = 0

var CurrentBadStreak : int = 0 # incorrect in row
var BestBadStreak : int = 0

var AnsweredQuestionsCount : int = 0 # for calculating correct ratio

var AverageAnswerTime : float = 0.0

# blunder is when all playeres answered correctly except this one
var Blunders : int = 0

####################################################################
#	BASE
####################################################################
func _ready():
	pass

func init(player_id, nick, icon_id, hash_id):
	self.DeviceUID = hash_id
	self.info_update(nick, icon_id)

####################################################################
#	PUBLIC
####################################################################
func get_points():
	return self.Points

func give_answer(flag : bool, time : float = 0.0):	
	self.AnsweredQuestionsCount += 1
	self.AverageAnswerTime += (time - AverageAnswerTime) / (self.AnsweredQuestionsCount)

	if flag:
		# Base
		self.Points += 1
		self.LastPoints += 1
		
		# Additional: Good Streak
		self.CurrentPointsStreak += 1
		self.BestPointsStreak = max(self.BestPointsStreak, self.CurrentPointsStreak)
		
		# Additional: Bad Streak
		self.CurrentBadStreak = 0
	else:
		# Additional: Good Streak
		self.CurrentPointsStreak = 0
		
		# Additional: Bad Streak
		self.CurrentBadStreak += 1
		self.BestBadStreak = max(self.BestBadStreak, self.CurrentBadStreak)
		
func clear_last_points():
	var TmpPoints = self.LastPoints
	self.LastPoints = 0
	return TmpPoints
	
func add_blunder():
	self.Blunders += 1

func get_serialized():
	var PlayerData = {}
	PlayerData['uid'] = self.DeviceUID
	PlayerData['name'] = self.Nick
	PlayerData['icon_id'] = self.IconId
	PlayerData['points'] = self.Points
	
	return PlayerData

####################################################################
#	STATISTICS
####################################################################
func get_correct_answer_ratio():
	return (float(self.Points) / max(1.0, float(self.AnsweredQuestionsCount)))

func get_average_answer_time():
	return self.AverageAnswerTime

func get_best_streak():
	return self.BestPointsStreak

func get_worst_streak():
	return self.BestBadStreak

func get_blunders():
	return self.Blunders

####################################################################
#	PACKET HANDLERS
####################################################################
func set_connected(flag):
	self.Connected = flag

func is_player_connected():
	return self.Connected

func info_update(nick, icon_id):
	self.Nick = nick
	self.IconId = icon_id
	
