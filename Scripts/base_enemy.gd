extends CharacterBody2D
class_name BaseEnemy

# --- State ---
enum States {IDLE, CHASE, ATTACK, HURT, DEAD}
var curr_state: States = States.IDLE
var target_player: Node2D = null

# --- Propeties
@export var move_speed: float = 100.0
@export var attack_range: float = 50.0
@export var attack_damage: int = 20
@export var max_hp: int = 100
var curr_hp: int

# --- Nodes ---
@onready var sight: Area2D = $Sight
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_timmer: Timer = $HurtTimer
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	curr_hp = max_hp
	
	Connet_signal()
	Change_state(States.IDLE)
	Change_animation("idle")
	print("Gravity: ", get_gravity())
	pass
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	
	match curr_state:
		States.IDLE:
			Handle_Idle()
		States.CHASE:
			Handle_Chase()
		States.ATTACK:
			Handle_Attack()
		States.HURT:
			Handle_Hurt()
		States.DEAD:
			Handle_Dead()
	
	if curr_state!= States.HURT and curr_state != States.DEAD:
		move_and_slide()
		
# --- Signal ---
func Connet_signal() -> void:
	sight.body_entered.connect(_on_sight_body_entered)
	sight.body_exited.connect(_on_sight_body_exited)
	
	hurt_timmer.timeout.connect(_on_hurt_timer_timeout)
	
func _on_sight_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body
		Change_state(States.CHASE)

	
func _on_sight_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = null
		Change_state(States.IDLE)
	
func _on_hurt_timer_timeout() -> void:
	if curr_state == States.HURT:
		if target_player:
			Change_state(States.CHASE)
		else:
			Change_state(States.IDLE)

func _on_attack_timer_timeout() -> void:
	if curr_state == States.ATTACK:
		Attack()
		attack_timer.start()
		
# --- State Machine ---
func Change_state(new_state: States) -> void:
	if curr_state == new_state:
		return
	
	curr_state = new_state
	print("Current state: %s" % [curr_state]) 
	match new_state:
		States.IDLE:
			Change_animation("idle")
			velocity = Vector2.ZERO
		States.CHASE:
			Change_animation("run")
		States.ATTACK:
			Change_animation("attack")
			velocity = Vector2.ZERO
			attack_timer.start()
		States.HURT:
			Change_animation("hit")
			velocity = Vector2.ZERO
			hurt_timmer.start(0.5)
		States.DEAD:
			Change_animation("dead")
			velocity = Vector2.ZERO
			
	pass
	
func Change_animation(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)
		
	if velocity.x != 0:
		anim.flip_h = velocity.x > 0
	pass
	
func Handle_Idle() -> void:
	pass
	
func Handle_Chase() -> void:
	if target_player:
		var target_pos = target_player.global_position
		var curr_pos = global_position
		
		var distance = curr_pos.distance_to(target_pos)
		var direction = (target_pos - curr_pos).normalized()
		if distance <= Get_Attack_range():
			Change_state(States.ATTACK)
			return
			
		velocity.x = direction.x  * move_speed
	else:
		Change_state(States.IDLE)

	
func Handle_Attack() -> void:
	if target_player:
		var distance = global_position.distance_to(target_player.global_position)
		if distance > Get_Attack_range() * 1.1:
			Change_state(States.CHASE)
		
	else:
		Change_state(States.IDLE)
	pass
	
func Handle_Hurt() -> void:
	
	pass
	
func Handle_Dead() -> void:
	print("Enemy deaded")
	await anim.animation_finished
	queue_free()
	pass
	
# --- General Actions ---
func Take_damage(amount: int) -> void:
	if curr_state == States.DEAD:
		return
	
	curr_hp -= amount
	print("%s took %d damage. Current HP: %d" % [name, amount, curr_hp])
	
	if curr_hp <= 0:
		Die()
	else:
		Change_state(States.HURT)
		

func Die() -> void:
	Change_state(States.DEAD)
	pass

func Attack() -> void:
	if target_player and global_position.distance_to(target_player.global_position) <= Get_Attack_range() * 1.1:
		print("Attacked")
		if target_player.has_method("Take_damage"):
			target_player.Take_damage(attack_damage)
		pass
	pass
	
func Get_Attack_range() -> float:
	return attack_range
