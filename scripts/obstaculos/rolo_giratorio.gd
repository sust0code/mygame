extends AnimatableBody3D
# Um poste com um rolo comprido que gira em volta dele, varrendo a pista.
# Quem for pego pelo rolo leva uma pancada: quanto mais longe do poste,
# mais rápido o rolo passa e mais forte é a batida (usa o sistema de nocaute).

## Nome que aparece no evento de nocaute.
@export var nome_exibido: String = "Rolo giratório"
## Rapidez do giro (radianos por segundo; 6,28 = uma volta). Negativo gira ao contrário.
@export var velocidade_de_giro: float = 1.6
## "Peso" do rolo para calcular a pancada (kg). Maior = derruba mais fácil.
@export var massa_do_rolo: float = 100.0


func _ready() -> void:
	$AreaDeBatida.body_entered.connect(_ao_bater_em)


func _physics_process(delta: float) -> void:
	rotate_y(velocidade_de_giro * delta)


# O rolo encostou em alguém.
func _ao_bater_em(corpo: Node3D) -> void:
	if not corpo.has_method("receber_impacto"):
		return
	# A velocidade do rolo no ponto onde ele pegou o jogador: é o giro
	# vezes a distância até o poste (a ponta do rolo anda mais rápido).
	var do_poste_ate_o_jogador := corpo.global_position - global_position
	do_poste_ate_o_jogador.y = 0.0
	var velocidade_no_ponto := (Vector3.UP * velocidade_de_giro).cross(do_poste_ate_o_jogador)
	# A pancada "vem" de trás do movimento do rolo, na direção do jogador.
	var de_onde_veio := corpo.global_position + Vector3.UP * 0.9 - velocidade_no_ponto.normalized()
	corpo.receber_impacto(nome_exibido, massa_do_rolo, velocidade_no_ponto, de_onde_veio)
