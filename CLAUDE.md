# Ao Vivo e Sem Ensaio

Jogo co-op online de 1 a 4 jogadores, em primeira pessoa, 3D low-poly colorido.
Os jogadores são participantes de um programa de TV caótico apresentado por
**Gilberto Glamour**. Cada fase é um episódio com tema e provas diferentes. A meta
é sobreviver à temporada e ganhar **R$ 1 milhão** na Grande Final. O progresso é
medido pela **audiência**, que sobe com provas vencidas e também com desastres
engraçados. Duração total: 3 a 4 horas. O objetivo é um dia publicar na Steam.

O documento de design completo (episódios, chefes, sistemas) está em **`GDD.md`**.
Consulte-o antes de criar qualquer fase ou sistema novo.

## Sobre quem está desenvolvendo

- **Iniciante total em programação.** Nunca programou antes deste projeto.
- Todas as explicações devem ser em **português simples**, sem jargão. Quando um
  termo técnico for inevitável (ex.: "nó", "cena", "sinal"), explique o que ele
  significa na primeira vez que aparecer.
- Sempre explique **o que cada arquivo faz** e dê o **passo a passo exato para
  testar** na Godot (quais botões clicar, quais teclas apertar, o que deve acontecer).
- Prefira soluções simples e legíveis a soluções "espertas". Comente o código em
  português, explicando o porquê de cada parte.
- Avance em passos pequenos: cada entrega deve poder ser testada sozinha.

## Tecnologia

- **Engine:** Godot **4.7** (é a versão instalada no computador de quem desenvolve).
- **Linguagem:** GDScript (a linguagem própria da Godot). Não usar C#.
- **Visual:** 3D low-poly colorido (formas simples, cores fortes, sem texturas
  realistas).

### Regras de versão (Godot 4.7)

- Sempre usar recursos, nós, funções e sintaxe que existem na **Godot 4.7**.
- Não usar sintaxe da Godot 3 (ex.: `KinematicBody`, `onready var` sem `@`,
  `export var` sem `@`, `yield`) nem recursos que só existem em versões mais
  novas que a 4.7.
- **Na dúvida se algo existe ou funciona igual na 4.7, avisar em vez de
  adivinhar.** Dizer claramente o que não foi confirmado e como verificar.
- Antes de entregar, validar o projeto com a Godot 4.7 sem janela (`--headless`):
  abrir o projeto, conferir que não há erros nem avisos e testar o comportamento
  com um script que simula as teclas.
- Nomes de arquivos, nós, variáveis e ações de controle em português, sem acento
  (ex.: `jogador.gd`, `velocidade`, `mover_frente`).

## Organização das pastas

```
project.godot      -> configuração do projeto (nome, cena inicial, controles)
GDD.md             -> documento de design do jogo (o "roteiro" criativo)
cenas/             -> arquivos .tscn (as "fases" e os "objetos montados")
scripts/           -> arquivos .gd (o código em GDScript)
```

Arquivos importantes:
- `scripts/config_nocaute.gd` — **todos** os números de ajuste do nocaute
  (força mínima, altura de queda, tempo atordoado). Mudar só ali.
- `scripts/registro_de_eventos.gd` — autoload `RegistroDeEventos`, o
  "caderninho" de eventos da partida.

A pasta `.godot/` é gerada automaticamente pela Godot e não vai para o Git.
A cena `cenas/principal.tscn` é, por enquanto, uma **área de testes** (chão,
caixas, rampa, pilha e torre laranja com escada), não uma fase do jogo final.

## Roteiro do projeto (etapas)

1. **Personagem em primeira pessoa** — anda com WASD, olha com o mouse e pula
   com espaço. ✅ feita
2. **Pegar, carregar e arremessar** — objetos com física que o jogador agarra,
   segura na frente da câmera e arremessa. ✅ feita
3. **Nocaute** — o jogador é nocauteado (vira um boneco mole, "ragdoll") e
   depois se levanta. Não existe morte no jogo. ✅ feita
4. **Episódio 1 para um jogador** — "O Piloto": gincana de obstáculos infláveis
   e o chefe A Parede, com começo, meio e fim.
5. **Multiplayer** — de 1 a 4 jogadores online na mesma partida.
6. **Sistemas do programa** — medidor de audiência, chat de voz por proximidade,
   provas com microfone e replay automático dos melhores momentos.
7. **Episódios 2 a 5** — Cozinha ao Vivo, Especial de Terror, Show de Talentos
   e Reality na Selva.
8. **Grande Final** — fuga dos bastidores, tomada da sala de controle e chefe
   final Gilberto Glamour na Roleta do Destino.
9. **Opcionais** — chat de lives votando em surpresas e missão secreta de
   sabotador.

## Como os objetos pegáveis funcionam (base para o multiplayer)

- Todo objeto que pode ser pego usa o script `scripts/objeto_pegavel.gd`
  (tipo `ObjetoPegavel`, um `RigidBody3D`). O peso é a propriedade `mass`.
- O objeto guarda uma **lista** `segurado_por` com os jogadores que o seguram,
  e é o próprio objeto que calcula a força para ir até a frente deles (média
  dos pontos de todos). Não trocar isso por "um jogador só".
- `jogadores_necessarios` diz quantos jogadores precisam segurar juntos para
  levantar. Com menos gente, o objeto só é arrastado pelo chão.
- Cada jogador tem `forca` (kg que carrega bem). Peso acima disso deixa o
  jogador lento, faz o objeto pender e diminui a força do arremesso.
- Cada jogador tem uma `direcao_de_segurar`, que gira aos poucos até a direção
  da câmera, com limite de rapidez que cai com o peso. É isso que faz um objeto
  pesado "ficar para trás" ao virar a câmera, dando a volta pelo lado de fora
  do jogador em vez de atravessá-lo.

## Como o nocaute funciona (base para o multiplayer)

- Não existe vida nem morte. O jogador tem um `estado`: `NORMAL`,
  `NOCAUTEADO` ou `LEVANTANDO` (em `scripts/jogador.gd`).
- Causas: batida de `ObjetoPegavel` (energia ½·massa·velocidade², só a parte
  da velocidade na direção do jogador), queda alta, ou a tecla **K** de teste
  (só funciona rodando pela Godot, em modo debug).
- Quem avisa a batida é o **objeto** (`receber_impacto`); quem decide se cai
  é o **jogador**. No multiplayer, só o dono do jogador deve decidir isso.
- No nocaute, o jogador desliga a própria cápsula e cria um
  `cenas/boneco_ragdoll.tscn` no cenário (partes `RigidBody3D` ligadas por
  `ConeTwistJoint3D`). Ao levantar, volta para onde o tronco do boneco caiu.
- Todo nocaute vira um evento no `RegistroDeEventos` com `tipo`, `jogador`,
  `id_jogador`, `causa`, `fonte`, `forca_do_impacto`, `altura_da_queda`,
  `tempo_atordoado`, `posicao` e `tempo`. A audiência e o replay (etapa 6)
  devem **escutar o sinal `evento_registrado`**, e não mexer no jogador.

## Testes automáticos

Autoloads (como `RegistroDeEventos`) **não** existem quando um script roda
com `godot -s`. Para testar o jogo, rodar o script de teste como autoload
numa **cópia** do projeto (fora do repositório), com a cena principal aberta.

O multiplayer só entra na etapa 5. Até lá, tudo é pensado para um jogador, mas
sem decisões que atrapalhem o multiplayer depois.
