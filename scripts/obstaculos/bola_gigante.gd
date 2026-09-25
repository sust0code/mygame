class_name BolaGigante
extends RigidBody3D
# Bola gigante com física, que desce a rampa rolando na direção do jogador.
# Se bater forte, derruba (a mesma regra das caixas: avisa o jogador da
# batida e ele decide se cai).

@export var nome_exibido: String = "Bola gigante"
## Depois de quantos segundos a bola some sozinha (para não acumular bolas).
@export var tempo_de_vida: float = 15.0

const CORES := [
	Color(1.0, 0.3, 0.4), Color(0.2, 0.7, 1.0), Color(1.0, 0.85, 0.1),
	Color(0.5, 0.9, 0.3), Color(0.8, 0.4, 1.0),
]

var _velocidade_antes_da_batida: Vector3 = Vector3.ZERO
# Há quanto tempo a bola está (quase) parada. Bola parada "estoura", para
# nunca ficar entalada bloqueando o caminho.
var _tempo_parada: float = 0.0


func _ready() -> void:
	# Cada bola sai de uma cor sorteada.
	var material := StandardMaterial3D.new()
	material.albedo_color = CORES.pick_random()
	$Malha.material_override = material
	# Liga o "sensor de batidas" (igual ao das caixas).
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_ao_encostar_em)


func _physics_process(delta: float) -> void:
	_velocidade_antes_da_batida = linear_velocity
	tempo_de_vida -= delta
	if linear_velocity.length() < 0.5:
		_tempo_parada += delta
	else:
		_tempo_parada = 0.0
	if tempo_de_vida <= 0.0 or global_position.y < -20.0 or _tempo_parada > 2.0:
		queue_free()


func _ao_encostar_em(corpo: Node) -> void:
	if corpo.has_method("receber_impacto"):
		corpo.receber_impacto(nome_exibido, mass, _velocidade_antes_da_batida, global_position)
