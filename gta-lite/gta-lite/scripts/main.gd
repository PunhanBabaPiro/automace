extends Node3D

var player: CharacterBody3D
var car: CharacterBody3D
var police_car: CharacterBody3D
var camera: Camera3D

var driving := false
var speed := 5.0
var car_speed := 0.0
var wanted := 0
var health := 100

var joystick := Vector2.ZERO
var npcs: Array[CharacterBody3D] = []

var speed_label: Label
var wanted_label: Label
var health_label: Label
var mini_map: ColorRect
var pause_menu: Panel


func _ready():
create_world()
create_player()
create_car()
create_police_car()
create_npcs()
create_camera()
create_mobile_hud()


# ================= WORLD =================

func create_world():
var light := DirectionalLight3D.new()
light.rotation_degrees = Vector3(-55, -35, 0)
light.light_energy = 1.3
add_child(light)

var environment := WorldEnvironment.new()
var env := Environment.new()
env.background_mode = Environment.BG_COLOR
env.background_color = Color(0.45, 0.65, 0.9)
env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
env.ambient_light_energy = 0.8
environment.environment = env
add_child(environment)

var ground := StaticBody3D.new()
add_child(ground)

var mesh := MeshInstance3D.new()
var box := BoxMesh.new()
box.size = Vector3(100, 0.2, 100)
mesh.mesh = box
ground.add_child(mesh)

var collision := CollisionShape3D.new()
var shape := BoxShape3D.new()
shape.size = Vector3(100, 0.2, 100)
collision.shape = shape
ground.add_child(collision)

create_road(Vector3(0, 0.02, 0), Vector3(100, 0.04, 10))
create_road(Vector3(0, 0.03, 0), Vector3(10, 0.05, 100))

var positions = [
Vector3(-18, 4, -18),
Vector3(0, 6, -20),
Vector3(18, 3, -18),
Vector3(-22, 5, 5),
Vector3(22, 4, 6),
Vector3(-15, 7, 22),
Vector3(5, 5, 20),
Vector3(22, 8, 22)
]

for p in positions:
create_building(p)


func create_road(position: Vector3, size: Vector3):
var road := MeshInstance3D.new()
var mesh := BoxMesh.new()
mesh.size = size
road.mesh = mesh
road.position = position
add_child(road)


func create_building(position: Vector3):
var building := StaticBody3D.new()
building.position = position
add_child(building)

var mesh := MeshInstance3D.new()
var box := BoxMesh.new()
box.size = Vector3(8, position.y * 2, 8)
mesh.mesh = box
mesh.position.y = position.y
building.add_child(mesh)

var collision := CollisionShape3D.new()
var shape := BoxShape3D.new()
shape.size = Vector3(8, position.y * 2, 8)
collision.shape = shape
collision.position.y = position.y
building.add_child(collision)


# ================= PLAYER =================

func create_player():
player = CharacterBody3D.new()
player.position = Vector3(0, 1.2, 8)
add_child(player)

var mesh := MeshInstance3D.new()
var capsule := CapsuleMesh.new()
capsule.height = 2
capsule.radius = 0.45
mesh.mesh = capsule
player.add_child(mesh)

var collision := CollisionShape3D.new()
var shape := CapsuleShape3D.new()
shape.height = 2
shape.radius = 0.45
collision.shape = shape
player.add_child(collision)


# ================= CARS =================

func create_car():
car = create_vehicle(Vector3(0, 0.8, 3))
car.name = "PlayerCar"


func create_police_car():
police_car = create_vehicle(Vector3(14, 0.8, 14))
police_car.name = "PoliceCar"


func create_vehicle(position: Vector3) -> CharacterBody3D:
var vehicle := CharacterBody3D.new()
vehicle.position = position
add_child(vehicle)

var body := MeshInstance3D.new()
var box := BoxMesh.new()
box.size = Vector3(2.2, 0.8, 4.2)
body.mesh = box
vehicle.add_child(body)

var collision := CollisionShape3D.new()
var shape := BoxShape3D.new()
shape.size = Vector3(2.2, 0.8, 4.2)
collision.shape = shape
vehicle.add_child(collision)

return vehicle


# ================= NPC =================

func create_npcs():
var positions = [
Vector3(-8, 1, -8),
Vector3(8, 1, -12),
Vector3(-12, 1, 12),
Vector3(12, 1, 8),
Vector3(5, 1, -5)
]

for p in positions:
var npc := CharacterBody3D.new()
npc.position = p
add_child(npc)

var mesh := MeshInstance3D.new()
var capsule := CapsuleMesh.new()
capsule.height = 1.8
capsule.radius = 0.4
mesh.mesh = capsule
npc.add_child(mesh)

npcs.append(npc)


# ================= CAMERA =================

func create_camera():
camera = Camera3D.new()
camera.current = true
add_child(camera)
update_camera()


func update_camera():
var target := player

if driving:
target = car

camera.position = target.position + Vector3(0, 6, 9)
camera.look_at(target.position + Vector3(0, 1, 0))


# ================= HUD =================

func create_mobile_hud():
var layer := CanvasLayer.new()
layer.name = "MobileHUD"
add_child(layer)

health_label = Label.new()
health_label.text = "♥ 100"
health_label.position = Vector2(30, 25)
health_label.add_theme_font_size_override("font_size", 26)
layer.add_child(health_label)

wanted_label = Label.new()
wanted_label.text = "★ 0"
wanted_label.position = Vector2(1080, 25)
wanted_label.add_theme_font_size_override("font_size", 26)
layer.add_child(wanted_label)

speed_label = Label.new()
speed_label.text = "0 KM/H"
speed_label.position = Vector2(1080, 650)
speed_label.add_theme_font_size_override("font_size", 22)
layer.add_child(speed_label)

# Analog
var analog := Button.new()
analog.text = "●"
analog.position = Vector2(45, 480)
analog.size = Vector2(150, 150)
analog.add_theme_font_size_override("font_size", 42)
layer.add_child(analog)

analog.button_down.connect(func():
joystick = Vector2(0, -1)
)

analog.button_up.connect(func():
joystick = Vector2.ZERO
)

# Face buttons
var triangle := make_button("△", Vector2(1080, 385), layer)
var circle := make_button("○", Vector2(1160, 460), layer)
var cross := make_button("×", Vector2(1080, 535), layer)
var square := make_button("□", Vector2(1000, 460), layer)

triangle.pressed.connect(enter_exit_car)
circle.pressed.connect(interact)
cross.pressed.connect(jump)
square.pressed.connect(action)

# Shoulder
var l1 := make_button("L1", Vector2(50, 390), layer)
var r1 := make_button("R1", Vector2(1160, 300), layer)

l1.pressed.connect(camera_left)
r1.pressed.connect(camera_right)

# Pause
var pause := make_button("Ⅱ", Vector2(620, 25), layer)
pause.pressed.connect(toggle_pause)

create_minimap(layer)


func make_button(text_value: String, pos: Vector2, layer: CanvasLayer) -> Button:
var button := Button.new()
button.text = text_value
button.position = pos
button.size = Vector2(70, 70)
button.add_theme_font_size_override("font_size", 26)
layer.add_child(button)
return button


# ================= MINI MAP =================

func create_minimap(layer: CanvasLayer):
mini_map = ColorRect.new()
mini_map.position = Vector2(30, 30)
mini_map.size = Vector2(180, 120)
mini_map.color = Color(0.05, 0.05, 0.05, 0.75)
layer.add_child(mini_map)

var title := Label.new()
title.text = "CITY MAP"
title.position = Vector2(45, 35)
title.add_theme_font_size_override("font_size", 14)
layer.add_child(title)


# ================= ACTIONS =================

func enter_exit_car():
if not driving:
if player.position.distance_to(car.position) < 4:
driving = true
player.visible = false
else:
driving = false
player.visible = true
player.position = car.position + Vector3(2, 0, 0)


func interact():
print("NPC / world interaction")


func action():
print("Action button")


func jump():
if not driving and player.is_on_floor():
player.velocity.y = 7


func camera_left():
camera.rotation.y += 0.2


func camera_right():
camera.rotation.y -= 0.2


func toggle_pause():
if pause_menu:
pause_menu.queue_free()
pause_menu = null
get_tree().paused = false
return

pause_menu = Panel.new()
pause_menu.position = Vector2(420, 180)
pause_menu.size = Vector2(440, 300)
add_child(pause_menu)

var title := Label.new()
title.text = "STREET LITE"
title.position = Vector2(120, 30)
title.add_theme_font_size_override("font_size", 30)
pause_menu.add_child(title)

var resume := Button.new()
resume.text = "DAVAM ET"
resume.position = Vector2(120, 100)
resume.size = Vector2(200, 60)
pause_menu.add_child(resume)

resume.pressed.connect(toggle_pause)

get_tree().paused = true
pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS


# ================= GAME LOOP =================

func _physics_process(delta):
if get_tree().paused:
return

if driving:
update_car(delta)
else:
update_player(delta)

update_npcs(delta)
update_camera()

if speed_label:
if driving:
speed_label.text = str(round(abs(car_speed) * 8.0)) + " KM/H"
else:
speed_label.text = "0 KM/H"


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


func update_npcs(delta):
for npc in npcs:
npc.position.x += sin(Time.get_ticks_msec() * 0.001 + npc.position.z) * delta * 0.5
