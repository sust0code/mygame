extends Node
# "Caderninho" do programa de TV: anota tudo de marcante que acontece na partida.
#
# Este script é um "autoload": a Godot cria ele sozinha quando o jogo começa
# e qualquer outro script consegue usá-lo pelo nome RegistroDeEventos.
# (Configurado em Projeto > Configurações do Projeto > Globais / Autoload.)
#
# Por enquanto ele só anota e mostra no painel "Saída" da Godot. No futuro,
# o medidor de audiência e o replay dos melhores momentos vão "escutar" o
# sinal evento_registrado para saber o que aconteceu.

## Avisa quem estiver interessado que aconteceu um evento novo.
## (Um "sinal" é um aviso que um nó dispara e outros nós podem escutar.)
signal evento_registrado(evento: Dictionary)

## Lista de todos os eventos da partida, do mais antigo para o mais novo.
var eventos: Array[Dictionary] = []


## Anota um evento. "evento" é um Dictionary (uma ficha com campos e valores),
## por exemplo: {"tipo": "nocaute", "jogador": "Jogador", "causa": "queda"}.
func registrar(evento: Dictionary) -> void:
	# Marca a hora do evento (segundos desde que o jogo abriu).
	evento["tempo"] = Time.get_ticks_msec() / 1000.0
	eventos.append(evento)
	print("[Evento] ", evento)
	evento_registrado.emit(evento)
