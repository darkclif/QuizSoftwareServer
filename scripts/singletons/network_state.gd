extends Node

# Signals for incoming packets
signal PCK_CONNECTION_WANT(conn, dict)

signal PCK_PING			(player, dict)
signal PCK_PING_REQ		(player, dict)
signal PCK_INFO_UPDATE	(player, dict)
signal PCK_GIVE_ANSWER	(player, dict)
signal PCK_PLAYER_READY	(player, dict)
signal PCK_I_AM_LOST	(player, dict)

# Connection and server data
var serverIp 			= ''
var serverPort 			= 8001 # tcp
var serverBroadCastPort = 8000 # udp

var socketUDP 				= PacketPeerUDP.new()
var socketUDPConnected 		= false
var socketUDPShouldConnect 	= false
var ReconnectUDPTimer : float = 0.0
const RECONNECTION_TIME_UDP : float = 5.0

var serverTCP 				= TCP_Server.new()
var serverTCPStarted 		= false
var serverTCPShouldStart 	= false
var ReconnectTCPTimer : float = 0.0
const RECONNECTION_TIME_TCP : float = 5.0

# Connections (PacketPeerStream)
var tcpPlayers = {}		# Player -> PacketPeerStream

# (connections established but not assigned to a player instance)
var tcpAwaiting = {}	# IP -> PacketPeerStream

# Packet dispatch
var packetRoutingUDP = {
	"where_server": 	funcref(self, "where_server_handle")
}

var packetRoutingTCP = {
	"connection_want": 	funcref(self, "connection_want_handle"),
	"info_update": 		funcref(self, "info_update_handle"),
	"give_answer": 		funcref(self, "give_answer_handle"),
	"i_am_lost": 		funcref(self, "i_am_lost_handle"),
	"player_ready": 	funcref(self, "player_ready_handle")
}

####################################################################
#	BASE
####################################################################
func _ready():
	# Set UDP
	socketUDP.set_broadcast_enabled(true)
	
	# Packet handlers
	self.connect("PCK_CONNECTION_WANT", self, "_on_connection_want")
	
	# Start network
	NetworkState.should_connect_udp(true)
	NetworkState.should_start_tcp(true)

func _exit_tree():
	socketUDP.close()
	serverTCP.stop()
	
func _process(delta):
	# UDP
	# Check state
	if socketUDPConnected and not socketUDP.is_listening():
		socketUDPConnected = false
	
	if socketUDPShouldConnect and not socketUDPConnected:
		if ReconnectUDPTimer <= 0.0:
			ReconnectUDPTimer = RECONNECTION_TIME_UDP
			self.start_udp_server()
		else:
			ReconnectUDPTimer -= delta
	
	if socketUDPConnected:
		self.udp_packet_handle()
	
	# TCP
	# Check state
	if serverTCPShouldStart and not serverTCP.is_listening():
		serverTCPStarted = false
	
	if serverTCPShouldStart and not serverTCPStarted:
		if ReconnectTCPTimer <= 0.0:
			ReconnectTCPTimer = RECONNECTION_TIME_TCP
			self.start_tcp_server()
		else:
			ReconnectTCPTimer -= delta
		
	if serverTCPStarted:
		self.tcp_connection_handle()
		self.tcp_packet_handle()

####################################################################
#	PUBLIC
####################################################################
func add_console_line(line):
	GameState.add_console_line(line)

func create_tcp_connection(player):
	# When you load save-file you need to create tcp connection for
	# each loaded player that is not yet connected to game.
	if not tcpPlayers.has(player):
		tcpPlayers[player] = null

func move_connection_to_main_list(ip, player):
	# Move connection from awaiting list to players list
	if not tcpAwaiting.has(ip):
		add_console_line("Cannot assign connection to player. Invalid IP adress. (%s)" % str(ip))
		return

	# Correct tcp socket
	tcpPlayers[player] = tcpAwaiting[ip]
	tcpAwaiting.erase(ip)

func should_start_tcp(val):
	serverTCPShouldStart = val
	
func should_connect_udp(val):
	socketUDPShouldConnect = val

####################################################################
#	PRIVATE LOGIC
####################################################################
func _on_connection_want(conn, dict):
	# Check if that player is already in a player list
	var PlayerIt = null
	for p in self.tcpPlayers:
		if p.DeviceUID == dict["device_id"]:
			PlayerIt = p
			
	var Ip = conn.get_stream_peer().get_connected_host()
	if PlayerIt:
		# Player with UID is already in list, send ok
		GameState.set_player_connected(PlayerIt, true)
		
		NetworkState.move_connection_to_main_list(Ip, PlayerIt)
		NetworkState.connection_accept_reconnect_send(PlayerIt)
	else:
		# Create new player and move it to tcpPlayers
		var NewPlayer = GameState.create_new_player("?", 0, dict["device_id"])
		
		NetworkState.move_connection_to_main_list(Ip, NewPlayer)
		NetworkState.connection_accept_send(NewPlayer)

####################################################################
#	NETWORK PRIVATE LOGIC
####################################################################
func start_udp_server():
	if (socketUDP.listen(serverBroadCastPort) != OK):
		add_console_line("[UDP] Error listening on port: " + str(serverBroadCastPort))
	else:
		add_console_line("[UDP] Listening on port: " + str(serverBroadCastPort))
		socketUDPConnected = true

func udp_packet_handle():
	while socketUDP.get_available_packet_count() > 0:
		var string = socketUDP.get_packet().get_string_from_ascii()
		var ip = socketUDP.get_packet_ip()
		
		if packetRoutingUDP.has(string):
			add_console_line("[UDP] '" + string + "' from " + str(ip))
			packetRoutingUDP[string].call_func()
		else:
			add_console_line("[UDP] '" + string + "' from " + str(ip) + " (unhandled)")

func start_tcp_server():
	if serverTCP.listen(serverPort) != OK:
		add_console_line("[TCP] Error listening on port: " + str(serverPort))
	else:
		add_console_line("[TCP] Listening on port: " + str(serverPort))
		serverTCPStarted = true
		
func tcp_packet_handle():
	# Awaiting connections
	for it_ip in self.tcpAwaiting:
		var conn = tcpAwaiting[it_ip]
		
		while conn.get_available_packet_count() > 0:
			var string = conn.get_packet().get_string_from_utf8()
			var ip = conn.get_stream_peer().get_connected_host()
			var resultJSON = JSON.parse(string)
	
			if resultJSON.error != OK:
				add_console_line('[TCP_AW] Cannot parse JSON from TCP packet.')
			else:
				# Awaiting connection should first send 'connection_want' packet
				var dict = resultJSON.result 
				
				if dict.has('msg') and dict['msg'] == 'connection_want' and packetRoutingTCP.has(dict['msg']):
					add_console_line("[TCP_AW] '" + dict['msg'] + "' from " + str(ip))
					packetRoutingTCP[dict['msg']].call_func(null, conn, dict)
				else:
					add_console_line("[TCP_AW] '" + dict['msg'] + "' from " + str(ip) + "(unhandled)")

	# Player connections
	for player in self.tcpPlayers:
		var conn = tcpPlayers[player]
		
		# Skip present players but 
		if not conn:
			continue
		
		# Inform that the player lost connection
		var ConnectedFlag = conn.get_stream_peer().is_connected_to_host()
		if player.is_player_connected() != ConnectedFlag:
			GameState.set_player_connected(player, ConnectedFlag)
			
		while conn.get_available_packet_count() > 0:
			var string = conn.get_packet().get_string_from_utf8()
			var ip = conn.get_stream_peer().get_connected_host()
			var resultJSON = JSON.parse(string)
	
			if resultJSON.error != OK:
				add_console_line('[TCP] Cannot parse JSON from TCP packet.')
			else:
				var dict = resultJSON.result
				
				if dict.has('msg') and packetRoutingTCP.has(dict['msg']):
					add_console_line("[TCP] '" + dict['msg'] + "' from " + str(ip))
					packetRoutingTCP[dict['msg']].call_func(player, conn, dict)
				else:
					add_console_line("[TCP] '" + dict['msg'] + "' from " + str(ip) + "(unhandled)")

func tcp_connection_handle():
	if serverTCP.is_connection_available():
		var conn = serverTCP.take_connection()
		conn.set_no_delay(true)
		
		var ip = conn.get_connected_host()
		var connWrapper = PacketPeerStream.new()
		connWrapper.set_stream_peer(conn)
		
		if self.tcpAwaiting.has(ip):
			self.tcpAwaiting[ip] = connWrapper
			add_console_line("[TCP_AW] Connection from %s overwriten in awating list." % conn.get_connected_host())
		else:
			self.tcpAwaiting[ip] = connWrapper
			add_console_line("[TCP_AW] Connection from %s added to awaiting list." % conn.get_connected_host())

func check_correct_fields(dict, fields):
	for f in fields:
		if !dict.has(f):
			return false
	return true

####################################################################
#	SEND
####################################################################
# UDP
func i_am_server_send(ip): 
	# Prepare packet
	socketUDP.set_dest_address(ip, 8000)
	var pac = "i_am_server".to_ascii()
	socketUDP.put_packet(pac)

	# Log
	self.add_console_line("Sent 'i_am_server' message to %s." % ip)

# TCP
func connection_accept_send(player):
	var Packet = {
		'msg': 'connection_accept',
		
		'player_id': player.PlayerId,
		'reconnect': false
	}
	
	return self._send_packet_helper(player, Packet)

func connection_accept_reconnect_send(player):
	var Packet = {
		'msg': 'connection_accept',
		
		'player_id': 	player.PlayerId,
		'reconnect': 	true,
		'nick':			player.Nick,
		'icon_id':		player.IconId,
	}
	
	return self._send_packet_helper(player, Packet)

func question_send_send(player, question_data):
	# Question format:
	#{
	#	"id": int_id
	#	"question": "",
	#	"answers": [4 : String]
	#}
	var Packet = {
		'msg': 'question_send',
		'question': question_data
	}
	
	return self._send_packet_helper(player, Packet)
	
func question_correct_send(player, question_id, correct_id):
	var Packet = {
		'msg': 'question_correct',
		'question_id': question_id,
		'correct_id': correct_id
	}
	
	return self._send_packet_helper(player, Packet)
	
func you_are_here_send(player, state, nick, icon_id):
	var Packet = {
		'msg': 'you_are_here'
	}
	
	return self._send_packet_helper(player, Packet)


func _send_packet_helper(player, packet):
	if not tcpPlayers.has(player):
		self.add_console_line("[TCP][ERROR][1] Cannot find TCP connection to given player.")
		self.add_console_line("[TCP][ERROR][2] Nick of that player: %s" % (player.Nick))
		return false

	var PacketString = JSON.print(packet)
	tcpPlayers[player].put_packet(PacketString.to_utf8())
	
	# Log to console
	self.add_console_line("[TCP] Sent '%s' message to player with nick %s." % [packet['msg'], player.Nick])
	return true


####################################################################
#	RECEIVE
####################################################################
# UDP
func where_server_handle(): 
	var playerIp = str(socketUDP.get_packet_ip())
	self.i_am_server_send(playerIp)
	
# TCP
func connection_want_handle(player, conn, dict):
	var fields = ['device_id']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_CONNECTION_WANT", conn, dict)
	else:
		self.add_console_line("Missing packet fields in 'connection_want'")


func info_update_handle(player, conn, dict):
	var fields = ['nick', 'icon_id']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_INFO_UPDATE", player, dict)
	else:
		self.add_console_line("Missing packet fields in 'info_update'")


func give_answer_handle(player, conn, dict):
	var fields = ['question_number', 'answer_number']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_GIVE_ANSWER", player, dict)
	else:
		self.add_console_line("Missing packet fields in 'give_answer'")


func player_ready_handle(player, conn, dict):
	var fields = []
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_PLAYER_READY", player, dict)
	else:
		self.add_console_line("Missing packet fields in 'player_ready'")

func i_am_lost_handle(player, conn, dict):
	var fields = ['player_id']
	
	if self.check_correct_fields(dict, fields):
		emit_signal("PCK_I_AM_LOST", player, dict)
	else:
		self.add_console_line("Missing packet fields in 'i_am_lost'")
