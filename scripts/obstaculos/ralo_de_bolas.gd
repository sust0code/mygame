extends Area3D
# "Ralo" no fim da rampa das bolas: toda bola gigante que entra aqui some.
# Assim as bolas não invadem o resto da pista.


func _ready() -> void:
	body_entered.connect(_ao_entrar)


func _ao_entrar(corpo: Node3D) -> void:
	if corpo is BolaGigante:
		corpo.queue_free()
