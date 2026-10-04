extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var speed := 5.0

var forward := false
var backward := false
var left := false
var right := false

func _ready():
create_world()
create_player()
create_camera()
create_controls()

func create_world():
var light = DirectionalLight3D.new()
light.rotation_degrees = Vector3(-55, -30, 0)
light.light_energy = 1.2
add_child(light)

var ground = StaticBody3D.new()
ground.name = "Ground"
add_child(ground)

var mesh = MeshInstance3D.new()
var box = BoxMesh.new()
box.size = Vector3(80, 0.2, 80)
mesh.mesh = box
mesh.position.y = -0.1
ground.add_child(mesh)

var collision = CollisionShape3D.new()
var shape = BoxShape3D.new()
shape.size = Vector3(80, 0.2, 80)
collision.shape = shape
collision.position.y = -0.1
ground.add_child(collision)

func create_player():
player = CharacterBody3D.new()
player.name = "Player"
player.position = Vector3(0, 1, 0)
add_child(player)

var mesh = MeshInstance3D.new()
var capsule = CapsuleMesh.new()
capsule.height = 2.0
capsule.radius = 0.45
mesh.mesh = capsule
player.add_child(mesh)

var collision = CollisionShape3D.new()
var shape = CapsuleShape3D.new()
shape.height = 2.0
shape.radius = 0.45
collision.shape = shape
player.add_child(collision)

func create_camera():
camera = Camera3D.new()
camera.position = Vector3(0, 5, 8)
camera.look_at(player.position)
add_child(camera)

func create_controls():
var layer = CanvasLayer.new()
add_child(layer)

var up = make_button("↑", Vector2(100, 500))
var down = make_button("↓", Vector2(100, 610))
var left_btn = make_button("←", Vector2(10, 555))
var right_btn = make_button("→", Vector2(190, 555))

layer.add_child(up)
layer.add_child(down)
layer.add_child(left_btn)
layer.add_child(right_btn)

up.button_down.connect(func(): forward = true)
up.button_up.connect(func(): forward = false)

down.button_down.connect(func(): backward = true)
down.button_up.connect(func(): backward = false)

left_btn.button_down.connect(func(): left = true)
left_btn.button_up.connect(func(): left = false)

right_btn.button_down.connect(func(): right = true)
right_btn.button_up.connect(func(): right = false)

func make_button(text_value: String, pos: Vector2) -> Button:
var b = Button.new()
b.text = text_value
b.position = pos
b.size = Vector2(80, 80)
b.add_theme_font_size_override("font_size", 32)
return b

func _physics_process(delta):
if player == null:
return

var direction := Vector3.ZERO

if forward:
direction.z -= 1
if backward:
direction.z += 1
if left:
direction.x -= 1
if right:
direction.x += 1

if direction.length() > 0:
direction = direction.normalized()

player.velocity.x = direction.x * speed
player.velocity.z = direction.z * speed

if not player.is_on_floor():
player.velocity.y -= 20.0 * delta
else:
player.velocity.y = 0

player.move_and_slide()

camera.position = player.position + Vector3(0, 5, 8)
camera.look_at(player.position)
