extends Node3D

var player: CharacterBody3D
var car: CharacterBody3D
var camera: Camera3D

var driving := false
var speed := 5.0
var car_speed := 0.0

var joystick := Vector2.ZERO
var camera_touch := Vector2.ZERO

var health := 100
var wanted := 0

var buildings = [
Vector3(-18, 4, -18),
Vector3(0, 6, -20),
Vector3(18, 3, -18),
Vector3(-22, 5, 5),
Vector3(22, 4, 6),
Vector3(-15, 7, 22),
Vector3(5, 5, 20),
Vector3(22, 8, 22)
]

func _ready():
create_world()
create_player()
create_car()
create_camera()
create_mobile_controls()


# ---------------- WORLD ----------------

func create_world():
var light = DirectionalLight3D.new()
light.rotation_degrees = Vector3(-55, -35, 0)
light.light_energy = 1.3
add_child(light)

var environment = WorldEnvironment.new()
var env = Environment.new()
env.background_mode = Environment.BG_COLOR
env.background_color = Color(0.45, 0.65, 0.9)
env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
env.ambient_light_color = Color(0.7, 0.7, 0.7)
env.ambient_light_energy = 0.8
environment.environment = env
add_child(environment)

# Ground
var ground = StaticBody3D.new()
add_child(ground)

var mesh = MeshInstance3D.new()
var box = BoxMesh.new()
box.size = Vector3(100, 0.2, 100)
mesh.mesh = box
mesh.position.y = -0.1
ground.add_child(mesh)

var collision = CollisionShape3D.new()
var shape = BoxShape3D.new()
shape.size = Vector3(100, 0.2, 100)
collision.shape = shape
collision.position.y = -0.1
ground.add_child(collision)

# Roads
create_road(Vector3(0, 0.02, 0), Vector3(100, 0.04, 10))
create_road(Vector3(0, 0.03, 0), Vector3(10, 0.05, 100))

# Buildings
for position in buildings:
create_building(position)


func create_road(position: Vector3, size: Vector3):
var road = MeshInstance3D.new()
var mesh = BoxMesh.new()
mesh.size = size
road.mesh = mesh
road.position = position
add_child(road)


func create_building(position: Vector3):
var building = StaticBody3D.new()
building.position = position
add_child(building)

var mesh = MeshInstance3D.new()
var box = BoxMesh.new()
box.size = Vector3(8, position.y * 2, 8)
mesh.mesh = box
mesh.position.y = position.y
building.add_child(mesh)

var collision = CollisionShape3D.new()
var shape = BoxShape3D.new()
shape.size = Vector3(8, position.y * 2, 8)
collision.shape = shape
collision.position.y = position.y
building.add_child(collision)


# ---------------- PLAYER ----------------

func create_player():
player = CharacterBody3D.new()
player.name = "Player"
player.position = Vector3(0, 1.2, 8)
add_child(player)

var mesh = MeshInstance3D.new()
var capsule = CapsuleMesh.new()
capsule.height = 2
capsule.radius = 0.45
mesh.mesh = capsule
player.add_child(mesh)

var collision = CollisionShape3D.new()
var shape = CapsuleShape3D.new()
shape.height = 2
shape.radius = 0.45
collision.shape = shape
player.add_child(collision)


# ---------------- CAR ----------------

func create_car():
car = CharacterBody3D.new()
car.name = "Car"
car.position = Vector3(0, 0.8, 3)
add_child(car)

var body = MeshInstance3D.new()
var box = BoxMesh.new()
box.size = Vector3(2.2, 0.8, 4.2)
body.mesh = box
car.add_child(body)

var collision = CollisionShape3D.new()
var shape = BoxShape3D.new()
shape.size = Vector3(2.2, 0.8, 4.2)
collision.shape = shape
car.add_child(collision)


# ---------------- CAMERA ----------------

func create_camera():
camera = Camera3D.new()
camera.current = true
add_child(camera)
update_camera()


func update_camera():
var target = player

if driving:
target = car

camera.position = target.position + Vector3(0, 6, 9)
camera.look_at(target.position + Vector3(0, 1, 0))


# ---------------- MOBILE CONTROLS ----------------

func create_mobile_controls():
var layer = CanvasLayer.new()
layer.name = "MobileHUD"
add_child(layer)

# Left analog
var stick = Button.new()
stick.name = "LeftAnalog"
stick.text = "●"
stick.position = Vector2(55, 480)
stick.size = Vector2(150, 150)
stick.add_theme_font_size_override("font_size", 48)
layer.add_child(stick)

stick.button_down.connect(func():
joystick = Vector2(0, -1)
)

stick.button_up.connect(func():
joystick = Vector2.ZERO
)

# Right face buttons
var triangle = make_control("△", Vector2(1080, 390), layer)
var circle = make_control("○", Vector2(1160, 465), layer)
var cross = make_control("×", Vector2(1080, 540), layer)
var square = make_control("□", Vector2(1000, 465), layer)

triangle.pressed.connect(enter_exit_car)
circle.pressed.connect(action_button)
cross.pressed.connect(jump_button)
square.pressed.connect(attack_button)

# Shoulder buttons
var l1 = make_control("L1", Vector2(60, 390), layer)
var r1 = make_control("R1", Vector2(1160, 300), layer)

l1.pressed.connect(camera_left)
r1.pressed.connect(camera_right)

# HUD
var health_label = Label.new()
health_label.name = "Health"
health_label.text = "♥ 100"
health_label.position = Vector2(35, 35)
health_label.add_theme_font_size_override("font_size", 26)
layer.add_child(health_label)

var wanted_label = Label.new()
wanted_label.name = "Wanted"
wanted_label.text = "★"
wanted_label.position = Vector2(1120, 35)
wanted_label.add_theme_font_size_override("font_size", 30)
layer.add_child(wanted_label)


func make_control(label_text: String, pos: Vector2, layer: CanvasLayer) -> Button:
var button = Button.new()
button.text = label_text
button.position = pos
button.size = Vector2(70, 70)
button.add_theme_font_size_override("font_size", 26)
layer.add_child(button)
return button


# ---------------- ACTIONS ----------------

func enter_exit_car():
if not driving:
if player.position.distance_to(car.position) < 4:
driving = true
player.visible = false
else:
driving = false
player.visible = true
player.position = car.position + Vector3(2, 0, 0)


func action_button():
print("Action")


func jump_button():
if not driving and player.is_on_floor():
player.velocity.y = 7


func attack_button():
wanted = min(wanted + 1, 5)
print("Wanted level: ", wanted)


func camera_left():
camera.rotation.y += 0.2


func camera_right():
camera.rotation.y -= 0.2


# ---------------- GAME LOOP ----------------

func _physics_process(delta):
if driving:
update_car(delta)
else:
update_player(delta)

update_camera()


func update_player(delta):
var direction := Vector3.ZERO

direction.x = joystick.x
direction.z = joystick.y

if direction.length() > 0:
direction = direction.normalized()

player.velocity.x = direction.x * speed
player.velocity.z = direction.z * speed

if not player.is_on_floor():
player.velocity.y -= 20.0 * delta
else:
player.velocity.y = 0

player.move_and_slide()


func update_car(delta):
var direction := Vector3.ZERO

direction.x = joystick.x
direction.z = joystick.y

if direction.length() > 0:
direction = direction.normalized()
car_speed = lerp(car_speed, 12.0, delta * 4.0)
else:
car_speed = lerp(car_speed, 0.0, delta * 5.0)

car.velocity.x = direction.x * car_speed
car.velocity.z = direction.z * car_speed
car.move_and_slide()
