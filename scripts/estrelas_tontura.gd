extends Node3D
# Estrelinhas amarelas girando em cima da cabeça de quem está atordoado.
# As estrelas são desenhadas pelo próprio código (5 pontas, estilo desenho
# animado), então não precisamos de nenhum arquivo de imagem.

## O nó que as estrelas seguem (a cabeça do boneco).
@export var seguir: Node3D
@export var quantidade: int = 4
## Distância das estrelas até o centro do círculo, em metros.
@export var raio_do_circulo: float = 0.3
## Altura acima da cabeça, em metros.
@export var altura: float = 0.35
## Rapidez do giro (em "radianos por segundo"; 6,28 = uma volta).
@export var velocidade_de_giro: float = 4.0


func _ready() -> void:
	# Material amarelo, sem sombra, visível dos dois lados e sempre virado
	# para a câmera ("billboard"), para a estrela nunca aparecer "de lado".
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.9, 0.1)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	var malha := _criar_malha_de_estrela(0.09, 0.04)

	# Espalha as estrelas em um círculo.
	for i in quantidade:
		var estrela := MeshInstance3D.new()
		estrela.mesh = malha
		estrela.material_override = material
		var angulo := TAU * i / quantidade  # TAU = uma volta inteira
		estrela.position = Vector3(cos(angulo), 0.0, sin(angulo)) * raio_do_circulo
		add_child(estrela)


func _process(delta: float) -> void:
	if seguir != null:
		global_position = seguir.global_position + Vector3.UP * altura
	rotate_y(velocidade_de_giro * delta)


# Monta uma estrela chata de 5 pontas com triângulos saindo do centro.
# São 10 "fatias": alternando ponta (raio grande) e cantinho (raio pequeno).
func _criar_malha_de_estrela(raio_da_ponta: float, raio_do_canto: float) -> ArrayMesh:
	var ferramenta := SurfaceTool.new()
	ferramenta.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		var angulo_1 := TAU * i / 10.0
		var angulo_2 := TAU * (i + 1) / 10.0
		var raio_1 := raio_da_ponta if i % 2 == 0 else raio_do_canto
		var raio_2 := raio_do_canto if i % 2 == 0 else raio_da_ponta
		ferramenta.add_vertex(Vector3.ZERO)
		ferramenta.add_vertex(Vector3(sin(angulo_1), cos(angulo_1), 0.0) * raio_1)
		ferramenta.add_vertex(Vector3(sin(angulo_2), cos(angulo_2), 0.0) * raio_2)
	return ferramenta.commit()
