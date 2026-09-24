extends Node3D
# Solta uma bola gigante de tempos em tempos, numa posição sorteada
# (de um lado a outro da largura), já rolando na direção escolhida.

const CENA_DA_BOLA := preload("res://cenas/obstaculos/bola_gigante.tscn")

## Segundos entre uma bola e outra.
@export var intervalo: float = 2.0
## Largura (em metros) da faixa onde as bolas podem nascer.
@export var largura: float = 5.0
## Velocidade com que a bola já sai (m/s).
@export var velocidade_inicial: float = 3.0
## Para onde a bola sai rolando.
@export var direcao: Vector3 = Vector3(0, 0, 1)

var _tempo: float = 0.0


func _ready() -> void:
	# A primeira bola sai logo (na metade do intervalo).
	_tempo = intervalo * 0.5


func _physics_process(delta: float) -> void:
	_tempo += delta
	if _tempo >= intervalo:
		_tempo -= intervalo
		_lancar_bola()


func _lancar_bola() -> void:
	var bola: RigidBody3D = CENA_DA_BOLA.instantiate()
	# A bola vai para o cenário (e não fica "presa" dentro do lançador).
	get_parent().add_child(bola)
	var deslocamento := randf_range(-largura / 2.0, largura / 2.0)
	bola.global_position = global_position + global_transform.basis.x * deslocamento
	bola.linear_velocity = direcao.normalized() * velocidade_inicial
