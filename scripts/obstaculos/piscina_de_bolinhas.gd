extends Node3D
# Enche a piscina com bolinhas coloridas de verdade (com física).
# As bolinhas são criadas pelo código quando o jogo começa, por isso elas
# não aparecem no editor, só ao apertar F5.
#
# Truque das "camadas de colisão": as bolinhas ficam numa camada só delas
# (a camada 3). O jogador não "enxerga" essa camada, então anda por dentro
# da piscina sem tropeçar; mas as bolinhas enxergam o jogador e são
# empurradas quando ele passa, como numa piscina de bolinhas de verdade.

## Tamanho da área onde as bolinhas nascem (largura, altura, comprimento).
@export var tamanho: Vector3 = Vector3(7.6, 0.6, 11.6)
@export var raio_da_bolinha: float = 0.3
## Quantas bolinhas no máximo.
@export var quantidade: int = 220

const CORES := [
	Color(1.0, 0.25, 0.35), Color(0.2, 0.6, 1.0), Color(1.0, 0.85, 0.1),
	Color(0.35, 0.9, 0.35), Color(1.0, 0.5, 0.1), Color(0.75, 0.35, 1.0),
]
const CAMADA_DAS_BOLINHAS := 4  # o número 4 é a "camada 3" (1, 2, 4, 8...)


func _ready() -> void:
	# Todas as bolinhas usam o mesmo formato (economiza memória).
	var malha := SphereMesh.new()
	malha.radius = raio_da_bolinha
	malha.height = raio_da_bolinha * 2.0
	malha.radial_segments = 8  # poucos lados = visual low-poly
	malha.rings = 4
	var forma := SphereShape3D.new()
	forma.radius = raio_da_bolinha

	var materiais: Array[StandardMaterial3D] = []
	for cor in CORES:
		var material := StandardMaterial3D.new()
		material.albedo_color = cor
		materiais.append(material)

	# Distribui as bolinhas numa grade (lado a lado, sem se encostar).
	var espaco := raio_da_bolinha * 2.0 + 0.02
	var colunas := int(tamanho.x / espaco)
	var fileiras := int(tamanho.z / espaco)
	var criadas := 0
	for fileira in fileiras:
		for coluna in colunas:
			if criadas >= quantidade:
				return
			var bolinha := RigidBody3D.new()
			bolinha.mass = 0.2
			bolinha.collision_layer = CAMADA_DAS_BOLINHAS
			bolinha.collision_mask = 1 | CAMADA_DAS_BOLINHAS  # vê o mundo, o jogador e as outras bolinhas
			var desenho := MeshInstance3D.new()
			desenho.mesh = malha
			desenho.material_override = materiais.pick_random()
			var colisao := CollisionShape3D.new()
			colisao.shape = forma
			bolinha.add_child(desenho)
			bolinha.add_child(colisao)
			bolinha.position = Vector3(
				-tamanho.x / 2.0 + espaco * (coluna + 0.5),
				raio_da_bolinha + randf_range(0.0, 0.1),
				-tamanho.z / 2.0 + espaco * (fileira + 0.5))
			add_child(bolinha)
			criadas += 1
