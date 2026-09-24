class_name ZonaDeTerreno
extends Area3D
# Uma região que muda o jeito de andar de quem está dentro dela.
# Ex.: a rampa de sabão (escorregadia) e a piscina de bolinhas (lenta).
# Quem faz o efeito é o jogador (scripts/jogador.gd); a zona só avisa
# "você entrou" e "você saiu".

## Verdadeiro = o chão escorrega (o jogador desliza e demora a frear).
@export var escorregadia: bool = false
## 1 = velocidade normal. 0,5 = metade da velocidade.
@export_range(0.1, 2.0) var multiplicador_de_velocidade: float = 1.0


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _ao_entrar(corpo: Node3D) -> void:
	if corpo.has_method("entrar_na_zona"):
		corpo.entrar_na_zona(self)


func _ao_sair(corpo: Node3D) -> void:
	if corpo.has_method("sair_da_zona"):
		corpo.sair_da_zona(self)
