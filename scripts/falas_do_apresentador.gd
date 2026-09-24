class_name FalasDoApresentador
extends RefCounted
# TODAS as falas do apresentador Gilberto Glamour ficam aqui.
# Para mudar, acrescentar ou apagar frases, é só editar as listas abaixo:
# cada frase fica entre aspas "assim", separada da próxima por vírgula.
# O jogo sorteia uma frase da lista a cada vez, então quanto mais frases,
# menos repetitivo.

const FALAS := {
	# Quando o episódio abre (antes de largar).
	"boas_vindas": [
		"Boa noite, Brasil! Está começando o AO VIVO E SEM ENSAIO!",
		"Luz, câmera e... alguém viu meu roteiro? Não temos! Vamos lá!",
		"Bem-vindos ao programa mais perigoso da TV aberta!",
	],
	# Quando o jogador cruza a linha de largada.
	"inicio": [
		"Valendo! O cronômetro está correndo!",
		"E lá vai ele! Coragem ou falta de juízo?",
		"Largou! Plateia, segura o coração!",
	],
	# Quando o jogador é nocauteado.
	"nocaute": [
		"Que tombo, minha gente!",
		"UUUUH! Essa doeu até em mim!",
		"Repete! Repete! Que imagem maravilhosa!",
		"Alguém chama a produção... ou não, a audiência subiu!",
		"Caiu bonito! Nota dez na queda!",
	],
	# Quando o jogador cai para fora da pista.
	"queda_da_pista": [
		"Tchibum! Direto para a piscina!",
		"Saiu da pista! Volta, volta, que o show não pode parar!",
		"Isso não estava no roteiro... porque não temos roteiro!",
		"Mergulho olímpico! Mas a prova é de corrida!",
	],
	# Quando o jogador passa por um ponto de controle.
	"checkpoint": [
		"Ponto de controle! Daqui ninguém te tira!",
		"Salvou o progresso! Agora pode cair à vontade!",
	],
	# Quando o jogador cruza a linha de chegada.
	"chegada": [
		"CHEGOU! Que prova, que talento, que desastre lindo!",
		"Terminou! A plateia está de pé!",
		"Chegou inteiro! Bom... quase inteiro!",
	],
}


# Sorteia uma frase do momento pedido (ex.: "nocaute").
# Se o momento não existir ou estiver vazio, devolve um texto vazio.
static func sortear(momento: String) -> String:
	var lista: Array = FALAS.get(momento, [])
	if lista.is_empty():
		return ""
	return lista.pick_random()
