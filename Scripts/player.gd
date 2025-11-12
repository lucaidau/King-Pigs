extends CharacterBody2D

# --- Const ---
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const SPIRTE_WIDTH = 58.0

# --- Node child --- 
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hit_box: Area2D = $AttackHitBox

# --- Propeties --- 
var state :String = "idle"
var was_in_air :bool = false
var can_move = false
var is_attacking = false
var facing_direction = 1
var base_attack_damage :int = 25

# --- Health System --- 
var max_hp: int = 100
var curr_hp: int = max_hp
var is_dead: bool = false
var is_hit: bool = false
var invicible_time: float = 0.5

func _ready() -> void:
	Deactive_hitbox()
	pass

# --- Movement system --- 
func _physics_process(delta: float) -> void:
	#Disable movement
	if not can_move:
		return
	
	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_attacking:
		Attack()
		return
	
	#if is_attacking:
		#can_move = false
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle horizontal movement
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = direction * SPEED
		facing_direction = direction
		# Flip horizontal sprite & collision
		if direction > 0:
			anim.flip_h = false
			anim.position.x = 0

		else:
			anim.flip_h = true
			anim.position.x = -SPIRTE_WIDTH/2
			

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Handle animation state
	if not is_attacking:
		if not is_on_floor():
			was_in_air = true
			if velocity.y >=0:
				state = "fall"
			else:
				state = "jump"
		else:
			if was_in_air:
				state = "ground"
				was_in_air = false
			if state != "ground" or anim.animation_finished:
				if direction != 0:
					state =  "run"
				else:
					state = "idle"

	move_and_slide()
	if not is_attacking:
		Do_Anim(state)

# --- Animation state --- 
func Do_Anim(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

# --- Attack system ---
func Attack() -> void:
	is_attacking = true
	can_move = false
	state = "attack"
	Do_Anim("attack")
	#velocity.x = 0
	Active_hitbox()
	
	await anim.animation_finished
	Deactive_hitbox()
	
	is_attacking = false
	can_move = true
	state = "idle"

func Active_hitbox() -> void:
	attack_hit_box.monitoring = true
	attack_hit_box.scale.x = facing_direction
	
func Deactive_hitbox() -> void:
	attack_hit_box.monitoring = false

# --- Signal function
func _on_attack_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		if body.has_method("Take_damage"):
			body.Take_damage(base_attack_damage)

# --- Take damage ---
func Take_damage(amount: int, dir: int = 0) -> void:
	if is_dead or is_hit:
		return
		
	curr_hp -= amount
	print("Current player hp: ", curr_hp)
	
	is_hit = true
	can_move = false
	anim.play("hit")
	
	flash_effect()
	
	if dir != 0:
		velocity.x = 200 * -dir
		velocity.y = -100
	move_and_slide()
	
	if curr_hp <= 0:
		Die()
		
	else:
		await get_tree().create_timer(invicible_time).timeout
		is_hit = false
		can_move = true

func flash_effect() -> void:
	var flash_time = 3
	for i in range(flash_time):
		anim.modulate = Color(1,0,0)
		await get_tree().create_timer(0.1).timeout
		anim.modulate = Color(1,1,1)
		await get_tree().create_timer(0.1).timeout
	

func Die() -> void:
	is_dead = true
	anim.play("dead")
	can_move = false
	print("Player deaded")
	await anim.animation_finished
	get_tree().paused = true
	
