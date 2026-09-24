extends Node3D
# A plateia do programa: vários bonequinhos (corpo + cabeça) sentados na
# arquibancada, balançando. Quando algo marcante acontece (nocaute, queda,
# chegada), eles pulam de empolgação por alguns segundos.
#
# Para não pesar no computador, os bonecos são desenhados com "MultiMesh":
# um jeito da Godot desenhar centenas de cópias do mesmo formato de uma vez.
# Eles são criados pelo código, então só aparecem ao apertar F5.

## Quantos degraus tem a arquibancada, e o tamanho de cada um.
@export var fileiras: int = 5
@export var profundidade_do_degrau: float = 1.6
@export var altura_do_degrau: float = 0.8
## Comprimento da arquibancada (metros) e espaço entre um boneco e outro.
@export var comprimento: float = 120.0
@export var espaco_entre_bonecos: float = 2.4

const CORES := [
	Color(1.0, 0.3, 0.4), Color(0.2, 0.6, 1.0), Color(1.0, 0.85, 0.1),
	Color(0.35, 0.9, 0.35), Color(1.0, 0.55, 0.15), Color(0.75, 0.4, 1.0),
	Color(0.95, 0.95, 0.95),
]
# Tipos de evento que deixam a plateia empolgada.
const EVENTOS_EMPOLGANTES := ["nocaute", "caiu_da_pista", "chegada", "inicio_da_prova"]

var _corpos: MultiMesh
var _cabecas: MultiMesh
var _bases: Array[Vector3] = []   # onde cada boneco está sentado
var _fases: Array[float] = []     # cada um balança num tempo diferente
var _tempo: float = 0.0
var _empolgacao: float = 0.0      # segundos de empolgação que ainda faltam


func _ready() -> void:
	for fileira in fileiras:
		var quantos := int(comprimento / espaco_entre_bonecos)
		for i in quantos:
			_bases.append(Vector3(
				profundidade_do_degrau * (fileira + 0.5),
				altura_do_degrau * (fileira + 1),
				-espaco_entre_bonecos * (i + 0.5) - randf_range(0.0, 0.6)))
			_fases.append(randf() * TAU)

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true  # cada cópia usa a sua cor

	var formato_do_corpo := CapsuleMesh.new()
	formato_do_corpo.radius = 0.28
	formato_do_corpo.height = 1.0
	formato_do_corpo.radial_segments = 6
	formato_do_corpo.material = material
	var formato_da_cabeca := SphereMesh.new()
	formato_da_cabeca.radius = 0.22
	formato_da_cabeca.height = 0.44
	formato_da_cabeca.radial_segments = 6
	formato_da_cabeca.rings = 3
	formato_da_cabeca.material = material

	_corpos = _criar_multimesh(formato_do_corpo)
	_cabecas = _criar_multimesh(formato_da_cabeca)
	for i in _bases.size():
		_corpos.set_instance_color(i, CORES.pick_random())
		_cabecas.set_instance_color(i, Color(1.0, 0.8, 0.62))  # cor de pele

	RegistroDeEventos.evento_registrado.connect(_ao_registrar_evento)


func _criar_multimesh(formato: Mesh) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = formato
	multimesh.instance_count = _bases.size()
	var desenho := MultiMeshInstance3D.new()
	desenho.multimesh = multimesh
	add_child(desenho)
	return multimesh


func _ao_registrar_evento(evento: Dictionary) -> void:
	if evento.get("tipo", "") in EVENTOS_EMPOLGANTES:
		_empolgacao = 2.5


func _process(delta: float) -> void:
	_tempo += delta
	_empolgacao = maxf(_empolgacao - delta, 0.0)
	# Balançando de leve, ou pulando alto se estiverem empolgados.
	var altura_do_pulo := 0.5 if _empolgacao > 0.0 else 0.06
	var rapidez := 9.0 if _empolgacao > 0.0 else 2.0
	for i in _bases.size():
		var pulo := absf(sin(_tempo * rapidez + _fases[i])) * altura_do_pulo
		var base := _bases[i] + Vector3.UP * pulo
		_corpos.set_instance_transform(i, Transform3D(Basis(), base + Vector3.UP * 0.5))
		_cabecas.set_instance_transform(i, Transform3D(Basis(), base + Vector3.UP * 1.2))
