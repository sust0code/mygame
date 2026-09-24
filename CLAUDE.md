# Mudança Desastrosa

Jogo co-op em primeira pessoa para até 4 jogadores. Os amigos precisam carregar
os móveis de uma casa até o caminhão de mudança, com física exagerada e engraçada.
O objetivo é um dia publicar na Steam.

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

- **Engine:** Godot 4 (projeto criado para 4.3 ou mais recente).
- **Linguagem:** GDScript (a linguagem própria da Godot). Não usar C#.
- Nomes de arquivos, nós, variáveis e ações de controle em português, sem acento
  (ex.: `jogador.gd`, `velocidade`, `mover_frente`).

## Organização das pastas

```
project.godot      -> configuração do projeto (nome, cena inicial, controles)
cenas/             -> arquivos .tscn (as "fases" e os "objetos montados")
scripts/           -> arquivos .gd (o código em GDScript)
```

A pasta `.godot/` é gerada automaticamente pela Godot e não vai para o Git.

## Roteiro do projeto (etapas)

1. **Personagem andando** — cena com chão e luz; personagem em primeira pessoa
   que anda com WASD, olha com o mouse e pula com espaço. ✅ feita
2. **Pegar, carregar e arremessar caixas** — objetos com física que o jogador
   pode agarrar, segurar na frente da câmera e jogar longe.
3. **Primeira fase para um jogador** — uma casa com móveis, um caminhão e um
   objetivo (colocar tudo no caminhão), com começo, meio e fim.
4. **Multiplayer** — até 4 jogadores na mesma partida, carregando móveis juntos.
5. **Conteúdo e humor** — mais fases, móveis variados, efeitos sonoros, física
   engraçada, polimento para a Steam.

O multiplayer só entra na etapa 4. Até lá, tudo é pensado para um jogador, mas
sem decisões que atrapalhem o multiplayer depois.
