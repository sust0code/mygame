extends Area3D
# Ponto de controle (checkpoint): quando o jogador passa por aqui, este vira
# o lugar onde ele reaparece se cair da pista.
#
# "Area3D" é uma região invisível que não bate em nada, só avisa quando
# alguém entra ou sai dela (pelos sinais body_entered e body_exited).

## Número do ponto de controle (1, 2, 3...), só para o evento ficar claro.
@export var numero: int = 1

const COR_DESLIGADO := Color(1.0, 0.8, 0.1)  # amarelo
const COR_LIGADO := Color(0.2, 0.9, 0.3)     # verde

var ativado: bool = false
var _material_da_faixa: StandardMaterial3D

# Onde e virado para onde o jogador reaparece (um marcador dentro da cena).
@onready var ponto_de_retorno: Marker3D = $PontoDeRetorno


func _ready() -> void:
	# A faixa ganha um material só dela, para poder mudar de cor sem mudar
	# a cor dos outros pontos de controle.
	_material_da_faixa = StandardMaterial3D.new()
	_material_da_faixa.albedo_color = COR_DESLIGADO
	$Faixa.material_override = _material_da_faixa
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node3D) -> void:
	if not corpo.has_method("definir_ponto_de_retorno"):
		return  # não é um jogador (pode ser uma bola, uma caixa...)
	corpo.definir_ponto_de_retorno(ponto_de_retorno.global_transform)

	# Na primeira vez, fica verde e anota o evento.
	# (No multiplayer, cada jogador vai ter o seu próprio ponto de retorno;
	# a cor verde mostra só que alguém já passou por aqui.)
	if not ativado:
		ativado = true
		_material_da_faixa.albedo_color = COR_LIGADO
		RegistroDeEventos.registrar({
			"tipo": "checkpoint",
			"numero": numero,
			"jogador": corpo.name,
			"id_jogador": corpo.id_jogador,
		})
