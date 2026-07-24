# 🌙 Morgana Project (Godot 4)

## 🎮 Mecânicas Principais

### Movimentação e Exploração
O jogo possui um mundo aberto focado em mobilidade tática. O jogador não está preso; é possível avançar para interceptar os inimigos cedo ou recuar até o portão para uma defesa de emergência.
- **Múltiplos Pulos:** A maga consegue executar até 4 pulos consecutivos no ar. Cada pulo perde um pouco de força propositalmente, permitindo alcançar inimigos altos de forma cadenciada sem encostar na barra de vida do topo da tela.
- **Câmera Dinâmica:** A câmera segue a maga suavemente na horizontal, mas é travada no eixo vertical durante os saltos. Isso mantém um enquadramento cinematográfico que realça as ricas camadas de Paralaxe ao fundo sem balançar a visão.

### Combate e Magia (Player Controls)
O combate primário da Morgana é regido por um **Cooldown Global** visual (que pisca na cabeça da personagem), impedindo ataques desenfreados e recompensando precisão.
- **Disparo Mágico (Botão Esquerdo):** Ataque básico em linha reta em direção ao cursor do mouse. Segurar o botão permite disparos sucessivos. Com atributos futuros de evolução, pode atirar sozinho ou perfurar. Dano base inicial é 25.
- **Ataque de Aura (Botão Direito):** Uma explosão em área de 360 graus com um raio de impacto formidável (160 pixels). Possui um cooldown levemente mais rápido e inflige muito dano (100). Mecânica ideal para "Crowd Control" caso a horda encoste muito na maga.
- **Stun / Paralisia:** Quando tocada fisicamente por um monstro, Morgana sofre um impacto contundente, sua câmera treme intensamente e a movimentação é congelada por `0.5s` (enquanto ela cai livremente sujeita à gravidade).

---

### Orbes e Familiares (Assistência Autônoma)
Morgana nunca luta sozinha. Ela é orbitada por **Orbes Familiares**, pequenos satélites autônomos impulsionados por Inteligência Artificial que escaneiam o campo de batalha.

Destaca-se o poderoso **Orbe de Combo** (`ai_familiar.gd`):
- **Sistema de Busca Inteligente:** O orbe varre dinamicamente os arredores com base no seu raio de detecção (`detection_radius`) e seleciona automaticamente o monstro do grupo `"enemies"` mais próximo, atirando bolas de fogo guiadas, complementando o poder de fogo da maga.
- **Sinergia com o Multiplicador (Kill Chain):** As estatísticas do orbe sobem agressivamente com o seu desempenho. Se nenhum monstro cruzar a linha da vila, o Multiplicador cresce, injetando os seguintes *Tiers* de poder na orbe:
  - **Tier Baixo (x1 a x2):** O orbe é azul e contido. Dispara aproximadamente a cada 1.6s, com dano padrão de assistência (15) e órbita tranquila.
  - **Tier Médio (x3 a x5):** As cores esquentam para tons magnéticos (Rosa e Roxo). O raio de busca enxerga quase a tela inteira (450px) e seus disparos saem mais rápido que a cada 1 segundo. Seu dano dobra (28).
  - **Tier Ouro (x8 a x10):** Ao construir um combo perfeito, a Orbe assume um brilho Dourado resplandecente, crescendo fisicamente de tamanho. Seu dano beira 45 por tiro, a velocidade orbital se torna frenética, e seus tiros **ganham propriedade perfurante (`pierce = true`)**, esburacando a horda impiedosamente.
- **Gatilhos de Evolução (Loja):** Sob o capô, o código do orbe possui os vetores de evolução `_evo_damage_bonus`, `_evo_speed_bonus` e `_evo_scale_mult`. Quando comprados através de um sistema de Upgrades ou conquistados, essas evoluções somam atributos permanentemente ignorando o multiplicador do combo.

---

### Ciclo de Jogo (O Ecossistema de Multi-Waves)
Abandonamos as arenas baseadas em timers únicos e implementamos o moderno fluxo de **Ondas (Waves)** orquestrado centralmente pelo `GameManager`. 
A sobrevivência divide-se em 5 Waves intensas rumo à Vitória.
- **Alternância de Fases:** O jogo vive em um ciclo entre a `GamePhase.PREPARATION` e `GamePhase.WAVE`.
- **Fase de Preparação:** A contagem regressiva no topo muda para cor branda e marca o alívio. Os nascimentos (Spawns) são interrompidos. Todo esse sistema foi montado com base modular para que painéis de "Lojas de Upgrades" possam surgir entre os combates de maneira síncrona, enquanto a Morgana pode andar livre.
- **Fase de Horda:** A cor pulsa. A dificuldade da vida e movimento dos novos inimigos é escalonada drasticamente com um Multiplicador interno da onda corrente. A Wave 1 pode exigir 30 segundos, enquanto a Wave 5 será brutal, gerando enxames raivosos.

### Inimigos e a Defesa do Portão
O cerne do jogo é a defesa inflexível do perímetro do lado esquerdo do mapa (`GATE_X = 200.0`).
- A saúde da vila (hud superior) se inicia em 100%. Sempre que um morcego escapar e atravessar a barreira oeste, ele despenca a Integridade da Vila (O HUD reage piscando vermelho e o `Camera Shake` é ativado alertando do perigo). Bater 0% significa **Game Over**.
- **Ameaça e Táticas**: 
  - *Comuns e Velozes* invadem com pressa e forçam a movimentação ágil.
  - *Gigantes* são colossais, roxos, possuem um HP massivo e causam dano alto, porém, eles carregam o atributo sagrado `defeat_heal`. Matá-los antes de chegarem regenera ativamente a saúde da sua vila, tornando-os o "medkit" do jogo.

### Sistema de Áudio Escalonável e Limpo
A complexidade dos combates pode ter mais de 40 atores independentes trocando ataques, magias explodindo, e orbes orbitando simultaneamente na Wave 5. Para lidar com toda essa pressão sonora de forma refinada, empregamos o Padrão de Arquitetura de Áudio:
- **`AudioManager` (Autoload / Singleton):** Foi estruturado uma rede de *Round-Robin Pool* mantendo dezenas de instâncias engatilhadas (AudioStreamPlayers).
- Isso significa que ao chamar `AudioManager.play_sfx("action")`, o código busca a pista de som apropriada (Dano no heroi, Morte do inimigo, Dano na vila, Clique de botões ou Impacto no orbe) e designa para um canal não intrusivo. Um som recém ativado **nunca** muta ou corta a magia que acabou de ser disparada. Tudo opera junto organicamente.

---

## 🌍 Rodando no Navegador
Graças à engenharia construída sobre a base do Godot 4, o jogo exporta diretamente para o GitHub Pages (Web/HTML5). O redimensionamento flexível (*stretch mode = canvas_items*) enquadra o cenário em monitores Ultrawide ou Laptops sem cortes da Interface.
