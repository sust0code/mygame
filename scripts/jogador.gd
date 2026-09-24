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

# --- Ajustes de carregar objetos ---
## Quantos quilos o jogador carrega "numa boa". Mais que isso fica difícil.
@export var forca: float = 30.0
## Distância (em metros) entre a câmera e o objeto segurado.
@export var distancia_de_segurar: float = 1.2
## Velocidade do arremesso mais fraco e do mais forte (metros por segundo).
@export var arremesso_minimo: float = 3.0
@export var arremesso_maximo: float = 16.0
## Quantos segundos segurando o botão para chegar na força máxima.
@export var tempo_de_carga: float = 1.2
## Força com que o jogador empurra caixas ao esbarrar nelas andando.
@export var forca_de_empurrao: float = 2.0

# A gravidade vem das configurações do projeto (padrão: 9,8, igual à Terra).
var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Objeto que está no centro da mira agora (ou "null" = nenhum).
var objeto_na_mira: ObjetoPegavel = null
# Objeto que o jogador está segurando agora (ou "null" = mãos vazias).
var objeto_segurado: ObjetoPegavel = null
# Carga do arremesso: vai de 0 (nada) até 1 (força máxima).
var carga: float = 0.0
var carregando_arremesso: bool = false

# "Cabeca" é o nó que segura a câmera. Giramos ele para olhar para cima e para baixo.
@onready var cabeca: Node3D = $Cabeca
@onready var camera: Camera3D = $Cabeca/Camera3D
# Um "raio" invisível que sai do centro da câmera para frente e diz no que bate.
@onready var raio_de_mira: RayCast3D = $Cabeca/Camera3D/RaioDeMira
# Peças da interface (o que aparece "colado" na tela).
@onready var texto_acao: Label = $Interface/TextoAcao
@onready var barra_de_forca: ProgressBar = $Interface/BarraDeForca


# _ready() roda uma vez, quando o personagem aparece na cena.
func _ready() -> void:
	# Prende e esconde o cursor do mouse dentro da janela do jogo.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# O raio da mira não deve bater no próprio jogador.
	raio_de_mira.add_exception(self)
	barra_de_forca.visible = false


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
		carregando_arremesso = false

	# Clicar com o mouse solto só prende o mouse de novo (não arremessa nada).
	if evento is InputEventMouseButton and evento.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	# E: pega o que está na mira, ou solta o que está segurando.
	if evento.is_action_pressed("pegar"):
		if objeto_segurado != null:
			soltar_objeto()
		elif objeto_na_mira != null:
			pegar_objeto(objeto_na_mira)

	# Botão esquerdo apertado: começa a carregar a força do arremesso.
	# Só dá para arremessar o que o jogador consegue levantar.
	if evento.is_action_pressed("arremessar") and objeto_segurado != null \
			and objeto_segurado.pode_levantar():
		carregando_arremesso = true
		carga = 0.0

	# Botão esquerdo solto: arremessa!
	if evento.is_action_released("arremessar") and carregando_arremesso:
		arremessar()


# _physics_process() roda 60 vezes por segundo. É aqui que o movimento acontece.
# "delta" é o tempo (em segundos) desde a última vez que essa função rodou.
func _physics_process(delta: float) -> void:
	_atualizar_mira()

	# Enquanto o botão está apertado, a carga sobe até 1.
	if carregando_arremesso:
		carga = minf(carga + delta / tempo_de_carga, 1.0)

	# Carregar peso deixa o jogador mais lento (e pulando menos).
	var multiplicador := _multiplicador_de_peso()
	var velocidade_atual := velocidade * multiplicador

	# 1) Gravidade: se estiver no ar, vai caindo cada vez mais rápido.
	if not is_on_floor():
		velocity.y -= gravidade * delta

	# 2) Pulo: só pula se apertou espaço E está com o pé no chão.
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = forca_do_pulo * multiplicador

	# 3) Andar: lê as teclas WASD e transforma em uma direção.
	# get_vector devolve algo como (x = esquerda/direita, y = frente/trás).
	var entrada: Vector2 = Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	# "transform.basis" faz a direção seguir para onde o personagem está virado.
	var direcao: Vector3 = (transform.basis * Vector3(entrada.x, 0, entrada.y)).normalized()

	if direcao != Vector3.ZERO:
		velocity.x = direcao.x * velocidade_atual
		velocity.z = direcao.z * velocidade_atual
	else:
		# Sem tecla apertada: freia até parar.
		velocity.x = move_toward(velocity.x, 0, velocidade)
		velocity.z = move_toward(velocity.z, 0, velocidade)

	# 4) Aplica o movimento. move_and_slide() cuida de colisões com paredes e chão.
	move_and_slide()

	_empurrar_objetos()
	_atualizar_interface()


# ---------------------------------------------------------------------------
# Pegar, soltar e arremessar
# ---------------------------------------------------------------------------

func pegar_objeto(objeto: ObjetoPegavel) -> void:
	objeto_segurado = objeto
	objeto.ao_ser_pego(self)
	# O objeto segurado não bate no próprio jogador. Sem isso, ele empurraria
	# o personagem para trás, ou daria para "subir" nele e sair voando.
	add_collision_exception_with(objeto)


func soltar_objeto() -> void:
	if objeto_segurado == null:
		return
	objeto_segurado.ao_ser_solto(self)
	remove_collision_exception_with(objeto_segurado)
	objeto_segurado = null
	carregando_arremesso = false
	carga = 0.0


func arremessar() -> void:
	var objeto := objeto_segurado
	# Objetos pesados voam menos.
	var fator := objeto.fator_de_forca()
	var velocidade_do_arremesso := lerpf(arremesso_minimo, arremesso_maximo, carga) * fator
	soltar_objeto()
	# A direção da mira é a "frente" da câmera.
	var direcao_da_mira := -camera.global_transform.basis.z
	# "Impulso" é um empurrão instantâneo. Multiplicar pela massa faz a
	# velocidade final ser a mesma para qualquer peso (antes do "fator").
	objeto.apply_central_impulse(direcao_da_mira * velocidade_do_arremesso * objeto.mass)


# O objeto pergunta ao jogador: "onde você quer que eu fique?"
# Resposta: um pouco à frente da câmera. Objetos grandes ficam mais longe,
# e enquanto carrega o arremesso o objeto vem um pouco para trás.
func ponto_de_segurar(objeto: ObjetoPegavel) -> Vector3:
	var distancia := distancia_de_segurar + objeto.raio - carga * 0.4
	return camera.global_position - camera.global_transform.basis.z * distancia


# ---------------------------------------------------------------------------
# Funções auxiliares (o "_" no começo do nome indica que são de uso interno)
# ---------------------------------------------------------------------------

# Olha o que está no centro da tela e acende o destaque se for pegável.
func _atualizar_mira() -> void:
	var novo: ObjetoPegavel = null
	if objeto_segurado == null and raio_de_mira.is_colliding():
		var alvo := raio_de_mira.get_collider()
		if alvo is ObjetoPegavel and not _esta_pisando_em(alvo):
			novo = alvo

	if novo != objeto_na_mira:
		if objeto_na_mira != null:
			objeto_na_mira.destacar(false)
		objeto_na_mira = novo
		if objeto_na_mira != null:
			objeto_na_mira.destacar(true)


# Não deixa pegar a caixa em que o jogador está em cima.
func _esta_pisando_em(objeto: Node) -> bool:
	for i in get_slide_collision_count():
		var colisao := get_slide_collision(i)
		if colisao.get_collider() == objeto and colisao.get_normal().y > 0.7:
			return true
	return false


# Vai de 1 (sem peso, velocidade normal) até 0,3 (muito pesado, bem lento).
func _multiplicador_de_peso() -> float:
	if objeto_segurado == null:
		return 1.0
	# Se várias pessoas seguram, o peso é dividido entre elas.
	var peso_para_mim := objeto_segurado.mass / objeto_segurado.segurado_por.size()
	return clampf(1.0 - (peso_para_mim / forca) * 0.35, 0.3, 1.0)


# Ao andar contra uma caixa solta, dá um empurrãozinho nela.
func _empurrar_objetos() -> void:
	for i in get_slide_collision_count():
		var colisao := get_slide_collision(i)
		var outro := colisao.get_collider()
		# Só empurra de lado (normal quase horizontal), não o que está embaixo do pé.
		if outro is RigidBody3D and absf(colisao.get_normal().y) < 0.5:
			outro.apply_central_impulse(-colisao.get_normal() * forca_de_empurrao)


# Atualiza o texto de ajuda e a barra de força.
func _atualizar_interface() -> void:
	if objeto_segurado != null:
		if not objeto_segurado.pode_levantar():
			texto_acao.text = "E - Soltar\nMuito pesado! Precisa de %d jogadores para levantar" \
				% objeto_segurado.jogadores_necessarios
		elif objeto_segurado.fator_de_forca() < 1.0:
			texto_acao.text = "E - Soltar   |   Segure o botão esquerdo para arremessar\nPesado!"
		else:
			texto_acao.text = "E - Soltar   |   Segure o botão esquerdo para arremessar"
	elif objeto_na_mira != null:
		if objeto_na_mira.jogadores_necessarios > 1:
			texto_acao.text = "E - Arrastar\n(precisa de %d jogadores para levantar)" \
				% objeto_na_mira.jogadores_necessarios
		else:
			texto_acao.text = "E - Pegar"
	else:
		texto_acao.text = ""

	barra_de_forca.visible = carregando_arremesso
	barra_de_forca.value = carga
