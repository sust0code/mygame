extends AnimatableBody3D
# Martelo gigante (inflável) pendurado numa viga, balançando de um lado para
# o outro por cima da pista, como um pêndulo de relógio.
# O centro deste nó é o ponto onde ele está preso lá em cima. Quem for pego
# pelo martelo quando ele passa rápido (no meio do balanço) é nocauteado.
# Nas pontas do balanço ele fica devagar: é a hora de passar!

@export var nome_exibido: String = "Martelo gigante"
## Quanto ele abre para cada lado, em graus.
@export var abertura: float = 60.0
## Rapidez do balanço. 1,6 = uma ida e volta a cada ~4 segundos.
@export var velocidade: float = 1.6
## Atraso do balanço, para cada martelo balançar num tempo diferente.
@export var fase: float = 0.0
## "Peso" do martelo para calcular a pancada (kg).
@export var massa_do_martelo: float = 150.0

var _tempo: float = 0.0
var _posicao_inicial: Vector3
# Rapidez do giro agora (radianos por segundo), para calcular a pancada.
var _giro_agora: float = 0.0


func _ready() -> void:
	_posicao_inicial = position


func _physics_process(delta: float) -> void:
	_tempo += delta
	var angulo := deg_to_rad(abertura) * sin(_tempo * velocidade + fase)
	# (A "derivada" do seno é o cosseno: é assim que sabemos a rapidez agora.)
	_giro_agora = deg_to_rad(abertura) * velocidade * cos(_tempo * velocidade + fase)
	# Gira em volta do eixo Z (balança de um lado para o outro da pista).
	# Posição e rotação juntas, num transform só (regra do AnimatableBody3D).
	transform = Transform3D(Basis(Vector3.BACK, angulo), _posicao_inicial)

	for corpo in $AreaDeBatida.get_overlapping_bodies():
		_ao_bater_em(corpo)


func _ao_bater_em(corpo: Node3D) -> void:
	if not corpo.has_method("receber_impacto"):
		return
	# Velocidade do martelo no ponto onde está o jogador: giro × distância.
	var centro_do_jogador := corpo.global_position + Vector3.UP * 0.9
	var velocidade_no_ponto := (Vector3.BACK * _giro_agora).cross(centro_do_jogador - global_position)
	var de_onde_veio := centro_do_jogador - velocidade_no_ponto.normalized()
	corpo.receber_impacto(nome_exibido, massa_do_martelo, velocidade_no_ponto, de_onde_veio)
