extends Control


# Consts
const TIMES_BLINK : int = 5
const DELTA_BLINK : float = 0.2

const GOOD_COLOR = Color8(178, 255, 150, 255)
const WHITE_COLOR = Color8(255, 255, 255, 255)

# Vars
var CurrentTime : float = 0.0
var CurrentBlickCount : int = 0
var BlinkOn : bool = false

####################################################################
# BASE
####################################################################
func _ready():
	pass

func _process(delta):
	if self.BlinkOn:
		self.CurrentTime -= delta
		
		if self.CurrentTime <= 0.0:
			if (CurrentBlickCount % 2):
				self.modulate = GOOD_COLOR
			else:
				self.modulate = WHITE_COLOR
			
			self.CurrentTime += DELTA_BLINK
			self.CurrentBlickCount += 1
			
			if self.CurrentBlickCount > TIMES_BLINK:
				self.BlinkOn = false
		

####################################################################
#	PUBLIC
####################################################################
func set_text(_text):
	$labText.text = _text
	
func set_correct():
	self.modulate = GOOD_COLOR
	
	self.BlinkOn = true
	self.CurrentTime = DELTA_BLINK
	self.CurrentBlickCount = 0
	
func get_center():
	return self.get_global_rect().position + $CenterPoint.rect_position
