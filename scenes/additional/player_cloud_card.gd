extends Control

const WHITE_COLOR = Color8(255, 255, 255, 255)
const GREEN_COLOR = Color8(0, 255, 0, 255)

var Dumping = 0.98
var KValue = 3.0
var V = Vector2()

var CloudPtr = null
var MAX_PUSH_DIST = 200.0
var PUSH_FORCE = 100.0
const CENTER_DIST : float = 200.0

var PlayerRef = null

enum AnswerType {
	PENDING,
	ANSWERED
}

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
	# Calculate players vectors
	var PlayerForces = Vector2()
	
	var players = CloudPtr.get_player_cards()
	for p in players:
		if p == self:
			continue 
		
		var ToCard = p.get_position() - self.get_position()
		var Force = -ToCard.normalized() * max(0.0, 150.0 - ToCard.length())
		PlayerForces += Force

	# Simulate spring 	
	# var F = - KValue * (self.rect_position - StartingPos) - V * Dumping 
	var ToCenter = (self.rect_position.normalized() * CENTER_DIST) - self.rect_position
	V += delta * (ToCenter * 30.0 - V * Dumping + PlayerForces * 20.0)
	
	self.rect_position += delta * V 

####################################################################
#	PUBLIC
####################################################################
func init(players_cloud, player):
	# Other cards refs
	CloudPtr = players_cloud
	PlayerRef = player
	self.update_data()

func update_data():
	# Set this card data
	$ControlSize/NickLabel.text = PlayerRef.Nick
	$ControlSize/Icon.texture = ResourceManager.get_icon_atlas(PlayerRef.IconId)

func update_connected():
	$ControlSize/labConnected.visible = !PlayerRef.Connected

####################################################################
#	HANDLERS
####################################################################
func _on_player_info_update(player):
	if player == self.PlayerRef:
		self.update_data()

func _on_player_connected_change(player, flag):
	if player == self.PlayerRef:
		self.update_connected()
