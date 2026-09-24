extends Node3D
# Regras do Episódio 1 — "O Piloto" (gincana de obstáculos).
# Cuida do cronômetro, da largada e da chegada. As falas do apresentador
# e a empolgação da plateia vêm sozinhas, porque eles escutam os eventos
# que este script anota no RegistroDeEventos.

var tempo_de_prova: float = 0.0
var correndo: bool = false   # o cronômetro está andando?
var terminou: bool = false

@onready var jogador: CharacterBody3D = $Jogador
@onready var cronometro: Label = $InterfaceDoEpisodio/Cronometro
@onready var mensagem_grande: Label = $InterfaceDoEpisodio/MensagemGrande


func _ready() -> void:
	mensagem_grande.visible = false
	cronometro.text = "Cruze a LARGADA!"
	$LinhaDeLargada.body_entered.connect(_ao_cruzar_a_largada)
	$LinhaDeChegada.body_entered.connect(_ao_cruzar_a_chegada)
	RegistroDeEventos.registrar({"tipo": "inicio_do_episodio", "episodio": 1})


func _process(delta: float) -> void:
	if correndo:
		tempo_de_prova += delta
		cronometro.text = formatar_tempo(tempo_de_prova)


func _ao_cruzar_a_largada(corpo: Node3D) -> void:
	# (No multiplayer, cada jogador terá o seu tempo; por enquanto é um só.)
	if corpo != jogador or correndo or terminou:
		return
	correndo = true
	RegistroDeEventos.registrar({"tipo": "inicio_da_prova", "episodio": 1,
		"jogador": corpo.name, "id_jogador": corpo.id_jogador})


func _ao_cruzar_a_chegada(corpo: Node3D) -> void:
	if corpo != jogador or not correndo:
		return
	correndo = false
	terminou = true
	cronometro.text = formatar_tempo(tempo_de_prova)
	mensagem_grande.text = "CHEGOU!\n" + formatar_tempo(tempo_de_prova)
	mensagem_grande.visible = true
	# Um "pulinho" de tamanho na mensagem, estilo TV.
	mensagem_grande.pivot_offset = mensagem_grande.size / 2.0
	mensagem_grande.scale = Vector2(0.3, 0.3)
	create_tween().tween_property(mensagem_grande, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	RegistroDeEventos.registrar({"tipo": "chegada", "episodio": 1,
		"jogador": corpo.name, "id_jogador": corpo.id_jogador,
		"tempo_de_prova": snappedf(tempo_de_prova, 0.01)})


# Transforma segundos em "minutos:segundos,décimos" (ex.: 01:23.4).
static func formatar_tempo(segundos: float) -> String:
	var minutos := floori(segundos / 60.0)
	var resto := segundos - minutos * 60.0
	return "%02d:%04.1f" % [minutos, resto]
