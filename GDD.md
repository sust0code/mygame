# Ao Vivo e Sem Ensaio — Documento de Design (GDD)

> **GDD** (Game Design Document) é o documento que descreve **como o jogo é**:
> história, fases, regras e sistemas. Ele guia o desenvolvimento e pode mudar
> com o tempo. Quando algo mudar no jogo, atualize aqui também.

## 1. Visão geral

| Item | Definição |
|---|---|
| **Nome** | Ao Vivo e Sem Ensaio |
| **Gênero** | Co-op caótico / party game em primeira pessoa |
| **Jogadores** | 1 a 4, online |
| **Câmera** | Primeira pessoa |
| **Visual** | 3D low-poly colorido |
| **Duração** | 3 a 4 horas (temporada completa) |
| **Plataforma alvo** | PC (Steam) |
| **Engine** | Godot 4.7, GDScript |

## 2. Conceito

Os jogadores são participantes de um **programa de TV caótico** apresentado por
**Gilberto Glamour**. Cada fase é um **episódio** com tema e provas diferentes.

- **Meta:** sobreviver à temporada e ganhar **R$ 1 milhão** na Grande Final.
- **Progresso:** medido pela **audiência**. Ela sobe quando os jogadores vencem
  provas, e **também** quando acontecem desastres engraçados. Falhar de um
  jeito divertido também é recompensado.
- **Reviravolta:** na Grande Final, os jogadores descobrem que **o programa era
  armado**.

## 3. Personagens

- **Os participantes (jogadores):** de 1 a 4 competidores do programa.
- **Gilberto Glamour:** o apresentador. Carismático diante das câmeras e,
  nos bastidores, o responsável pela armação. É o chefe final.

## 4. Estrutura da temporada (episódios)

Cada episódio tem um tema, provas próprias e termina com um **chefe**.

| # | Episódio | Provas / ambiente | Chefe |
|---|---|---|---|
| 1 | **O Piloto** | Gincana de obstáculos infláveis | **A Parede**: paredes com recortes em que os jogadores precisam se encaixar |
| 2 | **Cozinha ao Vivo** | Ingredientes que fogem | **Chef Explosivo** |
| 3 | **Especial de Terror** | Casa escura; um fantasma caça os jogadores pelo som da voz | **O Fantasma** |
| 4 | **Show de Talentos** | Karaokê com microfone | **Banda Rival** |
| 5 | **Reality na Selva** | Provas de sobrevivência | **Urso Animatrônico** |
| F | **Grande Final** | O programa era armado: fuga dos bastidores e tomada da sala de controle | **Gilberto Glamour** na **Roleta do Destino** |

## 5. Sistemas principais

1. **Pegar, carregar e arremessar objetos.** Objetos com física, que podem ser
   pesados a ponto de exigir mais de um jogador. *(Já existe no projeto.)*
2. **Nocaute com ragdoll.** Não existe morte: o jogador é nocauteado, vira um
   boneco mole ("ragdoll") e depois volta ao jogo.
3. **Chat de voz por proximidade.** Quanto mais perto, mais alto se ouve o outro
   jogador.
4. **Provas que usam o microfone.** Gritar, ficar em silêncio, cantar.
   (Ex.: no Especial de Terror, o fantasma ouve a voz dos jogadores.)
5. **Medidor de audiência.** Mostra o progresso. Sobe com provas vencidas e
   com desastres engraçados.
6. **Replay automático dos melhores momentos** ao fim de cada episódio, com
   opção de **salvar um clipe vertical** (formato para celular e redes sociais).

## 6. Opcionais (futuro)

- **Chat de lives votando em surpresas:** quem assiste à transmissão de um
  jogador vota em eventos que acontecem no jogo.
- **Missão secreta de sabotador:** um jogador recebe em segredo a missão de
  atrapalhar os outros.

## 7. Roteiro de desenvolvimento

1. Personagem em primeira pessoa ✅
2. Pegar / carregar / arremessar ✅
3. Nocaute
4. Episódio 1 para um jogador
5. Multiplayer
6. Sistemas do programa (audiência, voz, microfone, replay)
7. Episódios 2 a 5
8. Grande Final
9. Opcionais

## 8. Riscos técnicos (para investigar antes de cada etapa)

Alguns sistemas são bem mais difíceis que o resto e ainda **não foram
confirmados** na Godot 4.7. Antes de começar cada um, vale fazer um teste
pequeno para ver se é viável:

- **Chat de voz e provas com microfone:** exigem capturar o som do microfone e,
  no caso da voz, enviá-lo pela internet para os outros jogadores.
- **Replay e clipe vertical:** exigem gravar o que aconteceu na partida e
  transformar isso em vídeo. É um dos sistemas mais complexos da lista.
- **Multiplayer online:** exige decidir como os jogadores se conectam (por
  exemplo, pela própria Steam) e manter a física igual para todos.

## 9. Pontos em aberto

Decisões de design que ainda não foram tomadas:

- O que acontece se a audiência ficar baixa demais? (Existe derrota?)
- Quanto tempo dura um nocaute e como o jogador volta?
- Como o jogo funciona com 1 jogador em provas pensadas para vários?
- O prêmio de R$ 1 milhão é dividido entre os jogadores ou disputado?
