extends AnimatableBody3D
# Plataforma pendurada por cordas que balança de um lado para o outro.
# "AnimatableBody3D" é um corpo que a gente move pelo código e que carrega
# junto quem estiver em cima dele (como um elevador ou uma esteira).

## Quantos metros ela vai para cada lado.
@export var amplitude: float = 2.5
## Rapidez do balanço. 2 = uma ida e volta a cada ~3 segundos.
@export var velocidade: float = 2.0
## Atraso do balanço (em "radianos"), para cada plataforma balançar num tempo diferente.
@export var fase: float = 0.0
## Quanto ela inclina (em graus) quando está nas pontas do balanço.
@export var inclinacao_maxima: float = 12.0

var _posicao_inicial: Vector3
var _tempo: float = 0.0


func _ready() -> void:
	_posicao_inicial = position


func _physics_process(delta: float) -> void:
	_tempo += delta
	# "sin" (seno) vai de -1 a 1 e volta, suave, como um pêndulo.
	var onda := sin(_tempo * velocidade + fase)
	var nova_posicao := _posicao_inicial + Vector3.RIGHT * amplitude * onda
	var nova_inclinacao := Basis(Vector3.BACK, -deg_to_rad(inclinacao_maxima) * onda)
	# Posição e inclinação precisam ser trocadas JUNTAS, num "transform" só.
	# (Neste tipo de corpo, mudar a posição e depois a rotação separadamente
	# faz a Godot esquecer a posição, e a plataforma só inclinaria.)
	transform = Transform3D(nova_inclinacao, nova_posicao)
