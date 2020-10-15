extends Control

####################################################################
#	BASE
####################################################################
func _ready():
	pass 

####################################################################
#	PRIVATE
####################################################################
func add_console_line(line):
	$console.add_line(line)

####################################################################
#	BUTTONS
####################################################################
func _on_btn_exit_pressed():
	get_tree().get_root().remove_child(self)

func _on_btn_broadcast2_pressed():
	NetworkState.should_connect_udp(true)

func _on_btn_broadcast_pressed():
	NetworkState.should_start_tcp(true)
	
