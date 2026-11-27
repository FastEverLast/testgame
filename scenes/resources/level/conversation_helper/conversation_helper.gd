extends Area2D

@export var speakers : Array[Node2D]
@export var audiences : Array[Node2D]
@export var lines : Array[String]
@export var pause_between := 0.5
@export var walk_direction := Vector2.UP
@export var walk_time := 0.6
@export var guard := false
@export var base := false
@export var cat := false

var _playing := false
var _player : Node2D = null

func _on_body_entered(body : Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if (GameState.current_form != GameState.Form.GUARD) and guard:
		return
	if (GameState.current_form != GameState.Form.BASE) and base:
		return
	if (GameState.current_form != GameState.Form.CAT) and cat:
		return
	if _playing:
		return
	
	var key : String = get_tree().current_scene.scene_file_path + "/" + str(name)	# Unique name for this conversation: the level plus this node's name
	if GameState.seen_conversations.has(key):	# Already seen, even before dying
		return
	
	if speakers.size() != lines.size() or audiences.size() != lines.size():
		push_error("Not equal amounts of speakers and lines to say")
		return
	
	_player = body
	
	_playing = true
	GameState.reading = true
	
	for i in speakers:
		i.start_talking() # Stop the guard from walking.
		
	_player.talk_direction = walk_direction
	await get_tree().create_timer(walk_time, false).timeout
	_player.talk_direction = Vector2.ZERO
		
	for x in lines.size():
		var speaker : Node2D = speakers[x]
		var audience : Node2D = audiences[x] # Lets the speaker know who to turn to.
		
		for guard in speakers: 
			if guard == speaker:
				guard.face(audience) # Look at who you are talking to.
			elif audience.is_in_group("player"):
				guard.face(audience)
			else:
				guard.face(speaker) # Otherwhise look at the person speaking.
			
		var bubble : Node = speaker.get_node("SpeechBubble")
		await bubble.say(lines[x]) # Wait until he has finished his line.
		await get_tree().create_timer(pause_between, false).timeout
		
	for guard in speakers:
		guard.stop_talking()
	GameState.reading = false
	GameState.seen_conversations.append(key)
	_playing = false
