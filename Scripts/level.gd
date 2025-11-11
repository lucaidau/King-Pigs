extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var door_anim: AnimatedSprite2D = $Door/AnimatedSprite2D
@onready var player_anim: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var door: Area2D = $Door

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_walk_out()


func player_walk_out() -> void:
	player.can_move = false
	player.visible = false
	
	door_anim.play("opening")
	await door_anim.animation_finished
	
	player.visible = true
	player_anim.play("door_out")
	await player_anim.animation_finished
	player_anim.play("idle")
	
	door_anim.play("closing")
	await door_anim.animation_finished
	
	player.state = "idle"
	player.velocity = Vector2.ZERO
	await get_tree().process_frame
	player.can_move = true
	
	await get_tree().create_timer(0.8).timeout
	var tween = create_tween()
	tween.tween_property(door_anim, "modulate:a", 0.0, 0.5)
	await tween.finished
	door.visible = false
