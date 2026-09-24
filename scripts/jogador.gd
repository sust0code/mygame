extends CharacterBody3D
# Este script controla o personagem em primeira pessoa.
# "CharacterBody3D" é um tipo de corpo que a Godot move do jeito que a gente
# mandar, mas que ainda bate em paredes e fica em cima do chão.

# --- Ajustes do personagem ---
# O "@export" faz o valor aparecer no painel Inspetor da Godot, então dá para
# mudar sem mexer no código.
@export var velocidade: float = 5.0            # metros por segundo andando
@export var forca_do_pulo: float = 4.5         # quanto mais alto, mais alto o pulo
@export var sensibilidade_mouse: float = 0.003 # quanto a câmera gira por movimento do mouse

# A gravidade vem das configurações do projeto (padrão: 9,8, igual à Terra).
var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# "Cabeca" é o nó que segura a câmera. Giramos ele para olhar para cima e para baixo.
@onready var cabeca: Node3D = $Cabeca


# _ready() roda uma vez, quando o personagem aparece na cena.
func _ready() -> void:
	# Prende e esconde o cursor do mouse dentro da janela do jogo.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# _unhandled_input() roda toda vez que acontece algo no teclado ou mouse.
func _unhandled_input(evento: InputEvent) -> void:
	# Mouse se mexeu: gira o corpo para os lados e a cabeça para cima/baixo.
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-evento.relative.x * sensibilidade_mouse)
		cabeca.rotate_x(-evento.relative.y * sensibilidade_mouse)
		# Impede de olhar "além" do teto ou do chão (a cabeça daria uma cambalhota).
		cabeca.rotation.x = clamp(cabeca.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	# ESC solta o mouse (para você conseguir sair da janela).
	if evento.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Clicar na janela prende o mouse de novo.
	if evento is InputEventMouseButton and evento.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# _physics_process() roda 60 vezes por segundo. É aqui que o movimento acontece.
# "delta" é o tempo (em segundos) desde a última vez que essa função rodou.
func _physics_process(delta: float) -> void:
	# 1) Gravidade: se estiver no ar, vai caindo cada vez mais rápido.
	if not is_on_floor():
		velocity.y -= gravidade * delta

	# 2) Pulo: só pula se apertou espaço E está com o pé no chão.
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = forca_do_pulo

	# 3) Andar: lê as teclas WASD e transforma em uma direção.
	# get_vector devolve algo como (x = esquerda/direita, y = frente/trás).
	var entrada: Vector2 = Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	# "transform.basis" faz a direção seguir para onde o personagem está virado.
	var direcao: Vector3 = (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()

	if direcao != Vector3.ZERO:
		velocity.x = direcao.x * velocidade
		velocity.z = direcao.z * velocidade
	else:
		# Sem tecla apertada: freia até parar.
		velocity.x = move_toward(velocity.x, 0, velocidade)
		velocity.z = move_toward(velocity.z, 0, velocidade)

	# 4) Aplica o movimento. move_and_slide() cuida de colisões com paredes e chão.
	move_and_slide()
