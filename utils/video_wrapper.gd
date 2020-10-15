extends Control

# Consts
const TIME_TO_REPEAT : float = 7.5 # time to repeat a video

# Phase
enum VideoState {
	IDLE		= 0
	PLAY 		= 1,
	WAITING 	= 2,
	STOP 		= 3
}

# Vars
var CurrentTime : float = 0.0
var CurrentPhase = VideoState.IDLE

####################################################################
#	BASE
####################################################################
func _ready():
	pass

func _process(delta):
	if CurrentPhase == VideoState.WAITING:
		self.CurrentTime -= delta
		self.update_progress_bar()
		
		if self.CurrentTime <= 0.0:
			$vidVideoPlayer.play()
			
			self.CurrentPhase = VideoState.PLAY
			
	elif CurrentPhase == VideoState.PLAY:
		if !$vidVideoPlayer.is_playing():
			self.CurrentTime = TIME_TO_REPEAT
			self.update_progress_bar()
			
			self.CurrentPhase = VideoState.WAITING
			
		
####################################################################
#	PUBLIC
####################################################################
func play():
	if self.CurrentPhase != VideoState.PLAY:
		$vidVideoPlayer.play()
		self.CurrentPhase = VideoState.PLAY
		
func stop():
	$vidVideoPlayer.stop()
	self.CurrentPhase = VideoState.STOP

func set_paused(flag):
	$vidVideoPlayer.set_paused(flag)

func set_stream(stream):
	$vidVideoPlayer.set_stream(stream)

####################################################################
#	PRIVATE
####################################################################
func update_progress_bar():
	$progTimeToPlay.value = (1.0 - (self.CurrentTime / self.TIME_TO_REPEAT)) * $progTimeToPlay.max_value

func _on_btnPause_toggled(button_pressed):
	self.set_paused(button_pressed)
