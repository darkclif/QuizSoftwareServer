extends Control

const WHITE_COLOR = Color8(255, 255, 255, 255)
const GREEN_COLOR = Color8(0, 255, 0, 255)

var PlayerRef = null

enum AnswerType {
	PENDING,
	ANSWERED
}

# Go to
var TargetPos : Vector2 = Vector2()
var GoToActivated : bool = false

var OtherIconsList : Array = []
var V : Vector2 = Vector2()

const MAX_PUSH_DIST : float = 100.0
const MAX_FORCE : float = 20.0

####################################################################
#	BASE
####################################################################
func _ready():
	# Connect to player info change
	GameState.connect("LOGIC_PLAYER_INFO_REFRESHED", self, "_on_player_info_update")
	GameState.connect("LOGIC_PLAYER_CONNECTED_CHANGE", self, "_on_player_connected_change")

func _process(delta):
	pass

func _physics_process(delta):
	if !self.GoToActivated:
		return
	
	# Calculate players vectors
	var PlayerForces = Vector2()

	for p in OtherIconsList:
		if p == self:
			continue
		
		var ToCard = p.get_position() - self.get_position()
		var Force = -ToCard.normalized() * max(0.0, MAX_PUSH_DIST - ToCard.length())
		PlayerForces += Force

	# Go to target position
	var ToCenter = (self.rect_position - self.TargetPos)
	ToCenter -= ToCenter.normalized() * 20.0 # go to circle around target point to not hide answer
	var Target = ToCenter.normalized() * min(1000.0, lerp(0.0, 1000.0, ToCenter.length() / 100.0))
	var Err = -Target - V
	V += delta * (Err + PlayerForces * 10.0 - V * 0.98)
	V = V.clamped(500.0)
	
	self.rect_position += delta * V 

####################################################################
#	PUBLIC
####################################################################
func init(player, other_icons):
	# Other cards refs
	self.PlayerRef = player
	self.OtherIconsList = other_icons
	self.update_data()
	self.update_connected()
	
func go_to(pos):
	# Go to position of answer box
	self.GoToActivated = true
	self.TargetPos = pos + Vector2(-35.0, -59.0)

func update_data():
	# Set this card data
	$NickLabel.text = PlayerRef.Nick
	$Icon.texture = ResourceManager.get_icon_atlas(PlayerRef.IconId)

func update_connected():
	$labConnected.visible = !PlayerRef.Connected

func set_answer_indicator(flag):
	$labAnswerStatus.visible = flag
	
####################################################################
#	HANDLERS
####################################################################
func _on_player_info_update(player):
	if player == self.PlayerRef:
		self.update_data()

func _on_player_connected_change(player, flag):
	if player == self.PlayerRef:
		self.update_connected()
