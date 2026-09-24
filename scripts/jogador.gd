extends CharacterBody3D
# Este script controla o personagem em primeira pessoa.
# "CharacterBody3D" é um tipo de corpo que a Godot move do jeito que a gente
# mandar, mas que ainda bate em paredes e fica em cima do chão.

# O boneco mole que aparece no lugar do jogador quando ele é nocauteado.
# "preload" carrega a cena uma vez só, quando o jogo abre.
const CENA_DO_BONECO := preload("res://cenas/boneco_ragdoll.tscn")

# Os "estados" em que o jogador pode estar. Um "enum" é só uma lista de nomes
# para opções fixas, mais fácil de ler do que usar números 0, 1, 2.
enum Estado {
	NORMAL,      # andando, pulando, pegando coisas
	NOCAUTEADO,  # virou boneco mole e está atordoado no chão
	LEVANTANDO,  # se levantando (ainda sem controle)
}

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
@export var arremesso_minimo: float = 2.25
@export var arremesso_maximo: float = 12.0
## Quantos segundos segurando o botão para chegar na força máxima.
@export var tempo_de_carga: float = 1.2
## Rapidez máxima para girar um objeto leve ao redor do corpo (em "radianos
## por segundo"; 6,28 = uma volta inteira). Objetos pesados giram bem mais
## devagar que isso: é o que faz eles "ficarem para trás" ao virar a câmera.
@export var giro_maximo_com_objeto: float = 8.0
## Força com que o jogador empurra caixas ao esbarrar nelas andando.
@export var forca_de_empurrao: float = 2.0

# --- Voltar ao ponto de controle ---
## Se o jogador cair abaixo desta altura (fora da pista ou do mapa), ele volta
## para o último ponto de controle (ou para onde começou a fase).
@export var altura_limite: float = -10.0

# --- Chão escorregadio (ex.: a rampa de sabão do Episódio 1) ---
## Quanto as pernas conseguem acelerar no escorregadio (m/s²). Pouco = sem controle.
@export var aceleracao_no_escorregadio: float = 6.0
## Quanto o escorregadio freia sozinho. Perto de 0 = desliza quase para sempre.
@export var atrito_no_escorregadio: float = 0.2
## Velocidade máxima deslizando (m/s).
@export var velocidade_maxima_escorregando: float = 14.0

# --- Multiplayer (futuro) ---
## Número que identifica este jogador na partida. Hoje é sempre 1. No
## multiplayer, cada jogador terá o seu, e ele vai junto em cada evento.
@export var id_jogador: int = 1

# A gravidade vem das configurações do projeto (padrão: 9,8, igual à Terra).
var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Objeto que está no centro da mira agora (ou "null" = nenhum).
var objeto_na_mira: ObjetoPegavel = null
# Objeto que o jogador está segurando agora (ou "null" = mãos vazias).
var objeto_segurado: ObjetoPegavel = null
# Carga do arremesso: vai de 0 (nada) até 1 (força máxima).
var carga: float = 0.0
var carregando_arremesso: bool = false
# Direção em que o objeto segurado está agora, em volta do jogador. Ela vai
# girando aos poucos até a direção da câmera: rápido com objeto leve,
# devagar com objeto pesado.
var direcao_de_segurar: Vector3 = Vector3.FORWARD

# --- Nocaute ---
# (Os números de ajuste do nocaute ficam todos em scripts/config_nocaute.gd.)
var estado: Estado = Estado.NORMAL
# O boneco mole que está no chão agora (ou "null" se não estiver nocauteado).
var boneco: Node3D = null
var tempo_atordoado_restante: float = 0.0
# Para medir quedas: o ponto mais alto desde que o pé saiu do chão.
var estava_no_chao: bool = true
var altura_maxima_no_ar: float = 0.0
# Velocidade logo antes do último movimento (ao bater no chão, a velocidade
# já virou zero; esta guarda como ele vinha caindo).
var velocidade_antes_de_mover: Vector3 = Vector3.ZERO
# Altura normal da cabeça (a animação de levantar volta para ela).
var altura_da_cabeca: float = 1.6
# Coisas da câmera do nocaute.
var alvo_da_camera: Vector3 = Vector3.ZERO
var lado_da_camera: Vector3 = Vector3.FORWARD
var tempo_caido: float = 0.0

# --- Ponto de controle e terreno ---
# Onde (e virado para onde) o jogador reaparece se cair da pista.
# Começa sendo o lugar onde ele nasceu; os pontos de controle trocam isso.
var ponto_de_retorno: Transform3D
# Zonas de terreno especial em que o jogador está agora (escorregadio, lento...).
var zonas_de_terreno: Array[Node] = []

# "Cabeca" é o nó que segura a câmera. Giramos ele para olhar para cima e para baixo.
@onready var cabeca: Node3D = $Cabeca
@onready var camera: Camera3D = $Cabeca/Camera3D
# Um "raio" invisível que sai do centro da câmera para frente e diz no que bate.
@onready var raio_de_mira: RayCast3D = $Cabeca/Camera3D/RaioDeMira
# Peças da interface (o que aparece "colado" na tela).
@onready var mira: ColorRect = $Interface/Mira
@onready var texto_acao: Label = $Interface/TextoAcao
@onready var barra_de_forca: ProgressBar = $Interface/BarraDeForca
# A "cápsula" invisível que é o corpo do jogador para a física.
@onready var colisao: CollisionShape3D = $Colisao
# Uma segunda câmera, que fica "de fora" filmando o boneco caído.
@onready var camera_nocaute: Camera3D = $CameraNocaute


# _ready() roda uma vez, quando o personagem aparece na cena.
func _ready() -> void:
	# Prende e esconde o cursor do mouse dentro da janela do jogo.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# O raio da mira não deve bater no próprio jogador.
	raio_de_mira.add_exception(self)
	barra_de_forca.visible = false
	altura_da_cabeca = cabeca.position.y
	ponto_de_retorno = global_transform


# _unhandled_input() roda toda vez que acontece algo no teclado ou mouse.
func _unhandled_input(evento: InputEvent) -> void:
	# Mouse se mexeu: gira o corpo para os lados e a cabeça para cima/baixo.
	# (Caído no chão não dá para olhar em volta: quem manda é a câmera do nocaute.)
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			and estado != Estado.NOCAUTEADO:
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

	# Daqui para baixo são ações que só valem com o jogador em pé e no controle.
	if estado != Estado.NORMAL:
		return

	# K (tecla de teste): o próprio jogador cai. Só funciona rodando pela
	# Godot ("debug"); no jogo final exportado ela não faz nada.
	if evento.is_action_pressed("nocaute_teste") and OS.is_debug_build():
		# Um empurrãozinho para trás e para cima, para ele tombar de costas.
		var para_tras := transform.basis.z * 2.5 + Vector3.UP * 1.0
		nocautear("teste", "tecla K", 0.0, 0.5, para_tras)
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
	# Caído ou se levantando, o jogador não anda: cada estado cuida de si.
	if estado == Estado.NOCAUTEADO:
		_processar_nocaute(delta)
		return
	if estado == Estado.LEVANTANDO:
		_processar_levantando(delta)
		return

	_atualizar_mira()
	_atualizar_direcao_de_segurar(delta)

	# Enquanto o botão está apertado, a carga sobe até 1.
	if carregando_arremesso:
		carga = minf(carga + delta / tempo_de_carga, 1.0)

	# Carregar peso deixa o jogador mais lento (e pulando menos).
	var multiplicador := _multiplicador_de_peso()
	# Alguns terrenos (como a piscina de bolinhas) também deixam mais lento.
	var velocidade_atual := velocidade * multiplicador * _multiplicador_de_terreno()

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

	if _em_terreno_escorregadio():
		# No escorregadio, o movimento funciona diferente (veja a função).
		_andar_escorregando(direcao, delta)
	elif direcao != Vector3.ZERO:
		velocity.x = direcao.x * velocidade_atual
		velocity.z = direcao.z * velocidade_atual
	else:
		# Sem tecla apertada: freia até parar.
		velocity.x = move_toward(velocity.x, 0, velocidade)
		velocity.z = move_toward(velocity.z, 0, velocidade)

	# 4) Aplica o movimento. move_and_slide() cuida de colisões com paredes e chão.
	velocidade_antes_de_mover = velocity
	move_and_slide()

	# Caiu para fora da pista? Volta para o último ponto de controle.
	if global_position.y < altura_limite:
		voltar_ao_ponto_de_retorno()
		return

	_verificar_queda()
	_empurrar_objetos()
	_atualizar_interface()


# ---------------------------------------------------------------------------
# Pegar, soltar e arremessar
# ---------------------------------------------------------------------------

func pegar_objeto(objeto: ObjetoPegavel) -> void:
	objeto_segurado = objeto
	# O objeto começa a ser puxado a partir da direção em que ele está agora
	# (e não já na frente da câmera). Assim, um objeto pesado que estava de
	# lado demora um pouco para vir para a frente.
	var para_o_objeto := objeto.global_position - camera.global_position
	if para_o_objeto.length() > 0.01:
		direcao_de_segurar = para_o_objeto.normalized()
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
# Resposta: um pouco à frente do jogador, na "direcao_de_segurar" (que vai
# alcançando a câmera aos poucos). Objetos grandes ficam mais longe, e
# enquanto carrega o arremesso o objeto vem um pouco para trás.
func ponto_de_segurar(objeto: ObjetoPegavel) -> Vector3:
	var distancia := distancia_de_segurar + objeto.raio - carga * 0.4
	return camera.global_position + direcao_de_segurar * distancia


# ---------------------------------------------------------------------------
# Nocaute
# ---------------------------------------------------------------------------

# Algo bateu no jogador: uma caixa, uma bola gigante, um rolo giratório...
# Quem chama é a própria coisa que bateu, dizendo:
#   fonte: o nome dela (vai para o evento e para as falas do apresentador)
#   massa: o peso dela (kg)
#   velocidade_da_fonte: a velocidade dela ANTES da batida
#   posicao_da_fonte: de onde ela veio (para saber se veio "contra" o jogador)
# Aqui o jogador decide se a pancada foi forte o bastante para cair.
func receber_impacto(fonte: String, massa: float, velocidade_da_fonte: Vector3,
		posicao_da_fonte: Vector3) -> void:
	if estado != Estado.NORMAL:
		return

	# Só conta a parte da velocidade que vem NA DIREÇÃO do jogador. Assim,
	# andar contra uma caixa parada não derruba ninguém.
	var centro_do_corpo := global_position + Vector3.UP * 0.9
	var para_mim := (centro_do_corpo - posicao_da_fonte).normalized()
	var velocidade_contra_mim := maxf(velocidade_da_fonte.dot(para_mim), 0.0)

	# Força da batida = metade do peso × velocidade × velocidade (em joules).
	var forca_do_impacto := 0.5 * massa * velocidade_contra_mim * velocidade_contra_mim
	if forca_do_impacto < ConfigNocaute.FORCA_MINIMA_IMPACTO:
		return

	# De 0 (batida no limite) até 1 (batida fortíssima): decide o tempo no chão.
	var intensidade := (forca_do_impacto - ConfigNocaute.FORCA_MINIMA_IMPACTO) \
		/ (ConfigNocaute.FORCA_PARA_TEMPO_MAXIMO - ConfigNocaute.FORCA_MINIMA_IMPACTO)
	# O empurrão: objeto pesado e rápido joga o boneco mais longe.
	var empurrao := velocidade_da_fonte * massa / ConfigNocaute.MASSA_DO_JOGADOR \
		* ConfigNocaute.MULTIPLICADOR_DO_EMPURRAO
	empurrao = empurrao.limit_length(10.0)

	# "call_deferred" = fazer isso logo em seguida, e não agora. A batida é
	# avisada no meio do cálculo da física, e a Godot não deixa criar corpos
	# novos (o boneco) bem nesse momento.
	nocautear.call_deferred("objeto", fonte, forca_do_impacto, intensidade, empurrao)


# Transforma o jogador em boneco mole.
# causa: "objeto", "queda" ou "teste". fonte: o que causou (nome do objeto).
# forca_do_impacto: em joules. intensidade: de 0 a 1 (define o tempo no chão).
# empurrao: velocidade extra (m/s) que o boneco ganha. altura_da_queda: em metros.
func nocautear(causa: String, fonte: String, forca_do_impacto: float, intensidade: float,
		empurrao: Vector3, altura_da_queda: float = 0.0) -> void:
	if estado != Estado.NORMAL:
		return  # já está no chão (ex.: duas batidas ao mesmo tempo)

	estado = Estado.NOCAUTEADO
	soltar_objeto()  # quem cai, larga o que estava segurando
	if objeto_na_mira != null:
		objeto_na_mira.destacar(false)
		objeto_na_mira = null
	tempo_atordoado_restante = ConfigNocaute.tempo_de_atordoamento(intensidade)

	# Anota o nocaute no caderninho de eventos (para audiência e replay no futuro).
	RegistroDeEventos.registrar({
		"tipo": "nocaute",
		"jogador": name,
		"id_jogador": id_jogador,
		"causa": causa,
		"fonte": fonte,
		"forca_do_impacto": snappedf(forca_do_impacto, 0.1),
		"altura_da_queda": snappedf(altura_da_queda, 0.01),
		"tempo_atordoado": snappedf(tempo_atordoado_restante, 0.01),
		"posicao": global_position,
	})

	# Desliga a cápsula do jogador: agora quem bate nas coisas é o boneco.
	colisao.set_deferred("disabled", true)

	# Cria o boneco mole no mesmo lugar e virado para o mesmo lado.
	boneco = CENA_DO_BONECO.instantiate()
	get_parent().add_child(boneco)
	boneco.global_transform = global_transform
	boneco.comecar(velocidade_antes_de_mover, empurrao, self)

	# Troca para a câmera de fora. Ela começa exatamente onde estavam os
	# olhos do jogador e vai se afastando aos poucos (sem "pulo" na imagem).
	camera_nocaute.global_transform = camera.global_transform
	camera_nocaute.fov = camera.fov
	camera_nocaute.current = true
	alvo_da_camera = boneco.posicao_do_corpo()
	# A câmera fica na frente de onde o jogador olhava, virada para ele.
	lado_da_camera = -transform.basis.z
	lado_da_camera.y = 0.0
	lado_da_camera = lado_da_camera.normalized()
	tempo_caido = 0.0
	# Um "zoom" leve, de desenho animado, no primeiro segundo.
	create_tween().tween_property(camera_nocaute, "fov", 55.0, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Roda 60 vezes por segundo enquanto o jogador está caído.
func _processar_nocaute(delta: float) -> void:
	_mover_camera_de_nocaute(delta)
	_atualizar_interface()
	# O boneco caiu para fora da pista? Nem espera: volta no ponto de controle.
	if boneco.posicao_do_corpo().y < altura_limite:
		_registrar_queda_da_pista()
		_levantar(true)
		return
	tempo_atordoado_restante -= delta
	if tempo_atordoado_restante <= 0.0:
		_levantar()


# A câmera de fora segue o boneco de longe, sempre suave (sem girar junto
# com ele, que é o que dá enjoo). Ela balança devagar de um lado para o
# outro, como se o cinegrafista também estivesse tonto.
func _mover_camera_de_nocaute(delta: float) -> void:
	tempo_caido += delta
	# "lerp" aproxima um valor do outro aos poucos. O "1 - exp(...)" deixa
	# essa suavidade igual em computadores rápidos e lentos.
	alvo_da_camera = alvo_da_camera.lerp(boneco.posicao_do_corpo(), 1.0 - exp(-6.0 * delta))
	var posicao_desejada := alvo_da_camera + lado_da_camera * 2.6 + Vector3.UP * 2.0
	camera_nocaute.global_position = camera_nocaute.global_position.lerp(
		posicao_desejada, 1.0 - exp(-3.0 * delta))
	camera_nocaute.look_at(alvo_da_camera, Vector3.UP)
	# O balancinho: inclina no máximo 10 graus, bem devagar.
	camera_nocaute.rotate_object_local(Vector3.FORWARD, deg_to_rad(10.0) * sin(tempo_caido * 1.5))


# Fim do atordoamento: o jogador volta a ser ele mesmo, onde o boneco caiu.
# (Ou no último ponto de controle, se "no_ponto_de_retorno" for verdadeiro.)
func _levantar(no_ponto_de_retorno: bool = false) -> void:
	estado = Estado.LEVANTANDO

	if no_ponto_de_retorno:
		global_transform = ponto_de_retorno
		cabeca.rotation.x = 0.0
	else:
		# Coloca o jogador em pé no chão, embaixo do tronco do boneco.
		global_position = _procurar_chao_embaixo_de(boneco.posicao_do_corpo())
	velocity = Vector3.ZERO
	colisao.set_deferred("disabled", false)
	boneco.queue_free()  # "queue_free" = apagar o boneco assim que possível
	boneco = null

	# Volta para a câmera dos olhos, começando "deitado": a cabeça começa
	# baixa e torta, e sobe até a altura normal com um pequeno "quique".
	camera.current = true
	cabeca.position.y = 0.35
	cabeca.rotation.z = deg_to_rad(35.0)
	# Um "Tween" anima um valor de um número até outro durante um tempo.
	var animacao := create_tween().set_parallel(true)  # as duas animações juntas
	animacao.tween_property(cabeca, "position:y", altura_da_cabeca, ConfigNocaute.TEMPO_PARA_LEVANTAR) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacao.tween_property(cabeca, "rotation:z", 0.0, ConfigNocaute.TEMPO_PARA_LEVANTAR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# "chain" = depois que as duas acabarem, devolve o controle.
	animacao.chain().tween_callback(_terminar_de_levantar)


# Enquanto se levanta: só a gravidade age (para ele assentar no chão).
func _processar_levantando(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity.y -= gravidade * delta
	move_and_slide()
	_atualizar_interface()


func _terminar_de_levantar() -> void:
	estado = Estado.NORMAL
	# Recomeça a medição de queda do zero (levantar não conta como cair).
	estava_no_chao = true
	altura_maxima_no_ar = global_position.y


# Mede quedas: guarda o ponto mais alto enquanto está no ar e, ao tocar o
# chão, vê de quantos metros caiu.
func _verificar_queda() -> void:
	if is_on_floor():
		if not estava_no_chao:
			var altura_da_queda := altura_maxima_no_ar - global_position.y
			if altura_da_queda >= ConfigNocaute.ALTURA_MINIMA_QUEDA:
				# Força da queda = metade do peso do jogador × velocidade².
				var velocidade_da_queda := maxf(-velocidade_antes_de_mover.y, 0.0)
				var forca_do_impacto := 0.5 * ConfigNocaute.MASSA_DO_JOGADOR \
					* velocidade_da_queda * velocidade_da_queda
				var intensidade := (altura_da_queda - ConfigNocaute.ALTURA_MINIMA_QUEDA) \
					/ (ConfigNocaute.ALTURA_PARA_TEMPO_MAXIMO - ConfigNocaute.ALTURA_MINIMA_QUEDA)
				nocautear("queda", "", forca_do_impacto, intensidade, Vector3.ZERO, altura_da_queda)
		estava_no_chao = true
	else:
		if estava_no_chao:
			# Acabou de sair do chão: começa a medir daqui.
			altura_maxima_no_ar = global_position.y
			estava_no_chao = false
		altura_maxima_no_ar = maxf(altura_maxima_no_ar, global_position.y)


# Procura o chão embaixo de um ponto, com um "raio" invisível apontando para
# baixo (ignorando o boneco e o próprio jogador).
func _procurar_chao_embaixo_de(ponto: Vector3) -> Vector3:
	var consulta := PhysicsRayQueryParameters3D.create(ponto + Vector3.UP, ponto + Vector3.DOWN * 3.0)
	var ignorar: Array[RID] = boneco.rids_das_partes()
	ignorar.append(get_rid())
	consulta.exclude = ignorar
	var resultado := get_world_3d().direct_space_state.intersect_ray(consulta)
	if resultado.is_empty():
		return ponto
	return resultado.position


# ---------------------------------------------------------------------------
# Pontos de controle e terrenos especiais
# ---------------------------------------------------------------------------

# Chamado por um ponto de controle (scripts/ponto_de_controle.gd) quando o
# jogador passa por ele: "se cair, volte para cá".
func definir_ponto_de_retorno(novo_ponto: Transform3D) -> void:
	ponto_de_retorno = novo_ponto


# O jogador caiu da pista: reaparece no último ponto de controle.
func voltar_ao_ponto_de_retorno() -> void:
	soltar_objeto()
	global_transform = ponto_de_retorno
	cabeca.rotation.x = 0.0
	velocity = Vector3.ZERO
	# Recomeça a medição de queda (reaparecer não conta como cair).
	estava_no_chao = true
	altura_maxima_no_ar = global_position.y
	_registrar_queda_da_pista()


func _registrar_queda_da_pista() -> void:
	RegistroDeEventos.registrar({
		"tipo": "caiu_da_pista",
		"jogador": name,
		"id_jogador": id_jogador,
		"posicao": global_position,
	})


# Chamados pelas zonas de terreno (scripts/zona_de_terreno.gd) quando o
# jogador entra ou sai delas.
func entrar_na_zona(zona: Node) -> void:
	if not zona in zonas_de_terreno:
		zonas_de_terreno.append(zona)


func sair_da_zona(zona: Node) -> void:
	zonas_de_terreno.erase(zona)


# Está pisando em alguma zona escorregadia?
func _em_terreno_escorregadio() -> bool:
	for zona in zonas_de_terreno:
		if zona.escorregadia:
			return true
	return false


# Junta a lentidão de todas as zonas em que o jogador está (1 = normal).
func _multiplicador_de_terreno() -> float:
	var resultado := 1.0
	for zona in zonas_de_terreno:
		resultado *= zona.multiplicador_de_velocidade
	return resultado


# Andar no escorregadio: em vez de a velocidade obedecer na hora às teclas,
# as teclas só dão um "empurrãozinho" e o jogador vai deslizando. Numa
# ladeira, a gravidade ainda puxa ladeira abaixo.
func _andar_escorregando(direcao: Vector3, delta: float) -> void:
	var deslize := Vector2(velocity.x, velocity.z)
	# 1) O empurrãozinho das pernas.
	deslize += Vector2(direcao.x, direcao.z) * aceleracao_no_escorregadio * delta
	# 2) A ladeira: a parte da gravidade que aponta "morro abaixo".
	if is_on_floor():
		var normal := get_floor_normal()  # a direção "para cima" do chão inclinado
		var morro_abaixo := (Vector3.DOWN - normal * normal.dot(Vector3.DOWN)) * gravidade
		deslize += Vector2(morro_abaixo.x, morro_abaixo.z) * delta
	# 3) Um atrito bem fraquinho e um limite de velocidade.
	deslize *= 1.0 - atrito_no_escorregadio * delta
	deslize = deslize.limit_length(velocidade_maxima_escorregando)
	velocity.x = deslize.x
	velocity.z = deslize.y


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


# Gira a "direcao_de_segurar" em direção à câmera, com um limite de rapidez
# que depende do peso. Com peso, o limite cai muito: a caixa de 45 kg leva
# cerca de 1 segundo para dar um quarto de volta ao redor do jogador.
func _atualizar_direcao_de_segurar(delta: float) -> void:
	var frente_da_camera := -camera.global_transform.basis.z
	if objeto_segurado == null:
		direcao_de_segurar = frente_da_camera
		return

	var fator := objeto_segurado.fator_de_forca()
	# fator * fator: o peso pesa ainda mais no giro do que na subida.
	# O mínimo de 0,3 evita que um objeto enorme fique totalmente travado.
	var giro_permitido := maxf(giro_maximo_com_objeto * fator * fator, 0.3) * delta
	var angulo := direcao_de_segurar.angle_to(frente_da_camera)
	if angulo <= giro_permitido:
		direcao_de_segurar = frente_da_camera
	else:
		# "slerp" gira uma direção em direção a outra, pelo caminho curvo.
		direcao_de_segurar = direcao_de_segurar.slerp(frente_da_camera, giro_permitido / angulo)


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
	# Caído ou levantando: sem mira e sem barra.
	mira.visible = estado == Estado.NORMAL
	if estado != Estado.NORMAL:
		texto_acao.text = "NOCAUTE!" if estado == Estado.NOCAUTEADO else ""
		barra_de_forca.visible = false
		return

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
