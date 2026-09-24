extends Node3D
# O "boneco mole" (ragdoll) que aparece no lugar do jogador quando ele é
# nocauteado. Cada parte do corpo (cabeça, tronco, braços, pernas) é um
# RigidBody3D separado, preso às outras por "juntas" (ConeTwistJoint3D),
# que funcionam como o pescoço, os ombros e o quadril: deixam girar só até
# um certo ponto. A física faz o resto: ele cai, rola e se esparrama.

@onready var tronco: RigidBody3D = $Tronco
@onready var cabeca: RigidBody3D = $Cabeca

# Todas as partes do corpo, para mexer em todas de uma vez.
var partes: Array[RigidBody3D] = []


func _ready() -> void:
	for filho in get_children():
		if filho is RigidBody3D:
			partes.append(filho)


# Chamado pelo jogador logo depois de criar o boneco.
# velocidade_do_jogador: como o jogador estava se mexendo (o boneco continua o movimento).
# empurrao: velocidade extra da batida (m/s), na direção em que ele foi atingido.
# jogador: o corpo original, que o boneco deve ignorar (senão os dois se empurram).
func comecar(velocidade_do_jogador: Vector3, empurrao: Vector3, jogador: PhysicsBody3D) -> void:
	for parte in partes:
		parte.add_collision_exception_with(jogador)
		parte.linear_velocity = velocidade_do_jogador

	# A batida pega mais no tronco, e a cabeça "chicoteia" um pouco mais (é engraçado).
	tronco.linear_velocity += empurrao
	cabeca.linear_velocity += empurrao * 1.3

	# Um giro aleatório no tronco, para ele sempre tombar (e nunca cair igual).
	tronco.angular_velocity = Vector3(randf_range(-3.0, 3.0), randf_range(-1.0, 1.0), randf_range(-3.0, 3.0))


# Onde está o "centro" do boneco agora (usado para a câmera e para levantar).
func posicao_do_corpo() -> Vector3:
	return tronco.global_position


# Lista das partes, para quem precisar ignorá-las (ex.: procurar o chão).
func rids_das_partes() -> Array[RID]:
	var lista: Array[RID] = []
	for parte in partes:
		lista.append(parte.get_rid())
	return lista
