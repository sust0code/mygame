class_name ObjetoPegavel
extends RigidBody3D
# Qualquer objeto que o jogador pode pegar, carregar e arremessar.
# "RigidBody3D" é um corpo com física de verdade: cai, rola, quica e bate
# nos outros sozinho, sem a gente programar isso.
#
# O "class_name" dá um nome para este tipo de objeto. Assim o jogador consegue
# perguntar "isso que estou olhando é um ObjetoPegavel?".

## Nome que aparece para o jogador (ex.: "Caixa pequena").
@export var nome_exibido: String = "Caixa"

## Quantos jogadores precisam segurar JUNTOS para levantar o objeto.
## Com menos gente, só dá para arrastar pelo chão.
## (Preparado para o multiplayer da Etapa 5.)
@export_range(1, 4) var jogadores_necessarios: int = 1

## Rapidez da "mola" que puxa o objeto para a frente do jogador.
## Maior = segue mais rápido. Menor = mais mole.
@export var rigidez_mola: float = 10.0

## Quanto o balanço é freado. Perto de 1 = quase não balança.
## Perto de 0 = balança muito, como gelatina.
@export_range(0.05, 1.0) var amortecimento_mola: float = 0.35

# Lista de jogadores que estão segurando este objeto agora.
# É uma lista (e não um só jogador) justamente para o multiplayer:
# no futuro, dois ou mais jogadores podem segurar o mesmo objeto pesado.
var segurado_por: Array = []

# Metade do tamanho do objeto (do centro até a ponta). Usado para segurar
# objetos grandes um pouco mais longe da câmera.
var raio: float = 0.5

# Velocidade do objeto logo antes do último passo da física. Quando ele bate
# em alguém, a velocidade já mudou; esta guarda como ele vinha.
var _velocidade_antes_da_batida: Vector3 = Vector3.ZERO

var _material_destaque: StandardMaterial3D
var _amortecimento_angular_original: float
var _gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# Descobre o tamanho do objeto olhando para o desenho (a "malha") dele.
	for filho in get_children():
		if filho is MeshInstance3D:
			raio = filho.get_aabb().size.length() / 2.0

	# Material usado para "acender" o objeto quando o jogador olha para ele.
	# É uma camada amarelada e meio transparente por cima da cor normal.
	_material_destaque = StandardMaterial3D.new()
	_material_destaque.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_destaque.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_destaque.albedo_color = Color(1.0, 0.95, 0.4, 0.35)

	_amortecimento_angular_original = angular_damp

	# Liga o "sensor de batidas": o sinal body_entered avisa quando o objeto
	# encosta em outro corpo. Usamos isso para nocautear quem for atingido.
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_ao_encostar_em)


# Encostou em alguém. Se for um jogador, avisa ele da batida; é o jogador
# que decide se foi forte o bastante para cair (scripts/jogador.gd).
func _ao_encostar_em(corpo: Node) -> void:
	if corpo.has_method("receber_impacto"):
		corpo.receber_impacto(self, _velocidade_antes_da_batida)


# Liga ou desliga o destaque amarelo.
func destacar(ativo: bool) -> void:
	for filho in get_children():
		if filho is MeshInstance3D:
			filho.material_overlay = _material_destaque if ativo else null


# Tem gente suficiente segurando para tirar o objeto do chão?
func pode_levantar() -> bool:
	return segurado_por.size() >= jogadores_necessarios


# Soma a força de todos os jogadores que estão segurando.
func forca_total() -> float:
	var soma := 0.0
	for jogador in segurado_por:
		soma += jogador.forca
	return soma


# Um número de 0 a 1 que diz o quanto os jogadores "dão conta" do peso.
# 1 = leve para eles. Quanto mais pesado, mais perto de 0.
# O resultado é elevado ao quadrado para o peso fazer mais diferença:
# uma caixa com o dobro do que o jogador aguenta fica com 0,25 (e não 0,5).
func fator_de_forca() -> float:
	var folga := clampf(forca_total() / mass, 0.1, 1.0)
	return folga * folga


func ao_ser_pego(jogador: Node) -> void:
	if jogador in segurado_por:
		return
	segurado_por.append(jogador)
	destacar(false)
	# Enquanto é carregado, o objeto gira menos (senão fica rodopiando).
	angular_damp = 6.0


func ao_ser_solto(jogador: Node) -> void:
	segurado_por.erase(jogador)
	if segurado_por.is_empty():
		angular_damp = _amortecimento_angular_original


# Roda 60 vezes por segundo. Só faz algo se alguém estiver segurando.
func _physics_process(_delta: float) -> void:
	_velocidade_antes_da_batida = linear_velocity

	if segurado_por.is_empty():
		return

	sleeping = false  # garante que a física do objeto está "acordada"

	# 1) Para onde o objeto quer ir: a frente de quem está segurando.
	#    Com vários jogadores, é o ponto médio entre eles.
	var alvo := Vector3.ZERO
	for jogador in segurado_por:
		alvo += jogador.ponto_de_segurar(self)
	alvo /= segurado_por.size()

	var erro: Vector3 = alvo - global_position
	var levanta := pode_levantar()
	if not levanta:
		erro.y = 0.0  # sem gente suficiente: só arrasta pelo chão

	# 2) Se o objeto ficou muito longe (preso atrás de uma parede, por
	#    exemplo), todo mundo solta.
	if erro.length() > 2.5 + raio:
		for jogador in segurado_por.duplicate():
			jogador.soltar_objeto()
		return

	# 3) A "mola": puxa o objeto na direção do alvo e freia o balanço.
	#    Como é uma mola, ele passa um pouco do ponto e volta: fica "mole".
	var aceleracao: Vector3 = erro * rigidez_mola * rigidez_mola \
		- linear_velocity * 2.0 * amortecimento_mola * rigidez_mola

	# 4) Peso: quanto mais pesado para os jogadores, mais fraca é a mola
	#    (o objeto demora a subir) e menos a gravidade é compensada
	#    (o objeto "pende" para baixo).
	var fator := fator_de_forca()
	var anti_gravidade := Vector3.UP * _gravidade * gravity_scale * fator
	if not levanta:
		aceleracao.y = 0.0
		anti_gravidade = Vector3.ZERO
		fator = 0.25  # arrasta devagar, com esforço

	apply_central_force((aceleracao * fator + anti_gravidade) * mass)
