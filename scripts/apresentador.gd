extends CanvasLayer
# O "balão de fala" do apresentador Gilberto Glamour, na parte de baixo da tela.
#
# Ele não precisa que ninguém mande ele falar: ele fica "escutando" o
# caderninho de eventos (RegistroDeEventos) e, quando acontece algo que
# ele conhece (nocaute, queda da pista, chegada...), sorteia uma fala do
# arquivo scripts/falas_do_apresentador.gd e mostra na tela.

## Quantos segundos cada fala fica na tela.
@export var tempo_na_tela: float = 3.5

# Qual momento de fala combina com cada tipo de evento.
# (O "tipo" é o que está anotado no evento; o momento é a lista de falas.)
const MOMENTO_DE_CADA_EVENTO := {
	"inicio_do_episodio": "boas_vindas",
	"inicio_da_prova": "inicio",
	"nocaute": "nocaute",
	"caiu_da_pista": "queda_da_pista",
	"checkpoint": "checkpoint",
	"chegada": "chegada",
}

var tempo_restante: float = 0.0

@onready var balao: PanelContainer = $Balao
@onready var texto_da_fala: Label = $Balao/Margem/Linhas/Fala


func _ready() -> void:
	balao.visible = false
	# "connect" = começar a escutar o sinal. A cada evento novo, a função
	# _ao_registrar_evento é chamada.
	RegistroDeEventos.evento_registrado.connect(_ao_registrar_evento)


func _ao_registrar_evento(evento: Dictionary) -> void:
	var momento: String = MOMENTO_DE_CADA_EVENTO.get(evento.get("tipo", ""), "")
	if momento != "":
		falar(FalasDoApresentador.sortear(momento))


# Mostra uma frase no balão (e esconde depois de alguns segundos).
func falar(frase: String) -> void:
	if frase == "":
		return
	texto_da_fala.text = frase
	balao.visible = true
	tempo_restante = tempo_na_tela


func _process(delta: float) -> void:
	if balao.visible:
		tempo_restante -= delta
		if tempo_restante <= 0.0:
			balao.visible = false
