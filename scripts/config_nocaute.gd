class_name ConfigNocaute
extends RefCounted
# TODOS os números do sistema de nocaute ficam aqui, em um só lugar.
# Para deixar o jogo mais "fácil" ou mais "caótico", é só mudar estes valores.
#
# "const" quer dizer "constante": um valor fixo, que não muda durante o jogo.

# --- O que causa um nocaute ---

## Força mínima de uma batida para nocautear (em "joules", a energia do impacto).
## A conta é: metade do peso × velocidade × velocidade. A velocidade pesa mais!
## Exemplos com o valor 300:
##   caixa pequena (3 kg) a 12 m/s  ->  216  (não derruba)
##   caixa média   (8 kg) a 12 m/s  ->  576  (derruba)
##   caixa pesada (45 kg) caindo de 1,5 m  ->  ~660  (derruba)
const FORCA_MINIMA_IMPACTO: float = 300.0

## Altura mínima de queda para nocautear (em metros).
## Pular da plataforma cinza (2,7 m) não derruba; cair da torre laranja (6 m) derruba.
const ALTURA_MINIMA_QUEDA: float = 4.0

# --- Quanto tempo o jogador fica atordoado ---

## Tempo atordoado, em segundos, no nocaute mais fraco e no mais forte.
const TEMPO_ATORDOADO_MINIMO: float = 3.0
const TEMPO_ATORDOADO_MAXIMO: float = 5.0

## A partir desta força de batida, o tempo atordoado é o máximo.
const FORCA_PARA_TEMPO_MAXIMO: float = 1200.0
## A partir desta altura de queda, o tempo atordoado é o máximo.
const ALTURA_PARA_TEMPO_MAXIMO: float = 8.0

## Duração da "animação" de se levantar, em segundos.
const TEMPO_PARA_LEVANTAR: float = 0.8

# --- Física do boneco mole ---

## Peso do jogador (kg). Usado para calcular o empurrão que ele leva.
const MASSA_DO_JOGADOR: float = 70.0
## Quanto o boneco é arremessado ao levar uma batida. Maior = voa mais longe.
const MULTIPLICADOR_DO_EMPURRAO: float = 1.5


# Transforma a "intensidade" do nocaute (de 0 = fraquinho até 1 = fortíssimo)
# em segundos de atordoamento, entre o mínimo e o máximo.
static func tempo_de_atordoamento(intensidade: float) -> float:
	return lerpf(TEMPO_ATORDOADO_MINIMO, TEMPO_ATORDOADO_MAXIMO, clampf(intensidade, 0.0, 1.0))
