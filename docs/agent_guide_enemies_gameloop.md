# Guia de Arquitetura: Inimigos e Game Loop (Morgana)

Este documento destina-se a orientar agentes e desenvolvedores sobre a arquitetura do ecossistema de inimigos e do ciclo de jogo (Game Loop). A base do projeto utiliza um padrão de classes herdadas e singletons (`Autoloads`), sendo orientada a grupos do Godot (`"enemies"`).

---

## 1. O Game Loop (Ciclo Principal)

O fluxo e o ritmo da partida são controlados integralmente pelo **`GameManager`** (Singleton localizado em `scripts/game_manager.gd`).

### Fases do Jogo (`GameManager.GamePhase`)
O jogo é dividido rigidamente em 3 fases temporais:
1. **`COUNTDOWN` (15 segundos):** Tempo para a jogadora agir antes do caos iniciar. A taxa de spawn dos inimigos costuma ser lenta e branda. Funciona como fase de exploração/coleta.
2. **`HORDE` (60 segundos):** A principal fase de defesa. A taxa de spawn atinge o ápice de frenesi. O `GameManager` emite o sinal `horde_started`.
3. **`ENDED`:** Alcançada quando o tempo da Horda zera (Vitória) ou a Vila cai (Derrota). O jogo congela os atuadores principais (`is_game_active = false`).

### Gerenciamento de Status
- **Integridade da Vila (`village_integrity`):** Inicia em `100.0`. Quando um inimigo cruza a linha de limite (`GATE_X`), a integridade sofre dano. Quando atinge `<= 0`, dispara o `_trigger_game_over()`.
- **Score e Combo:** O `GameManager` controla ativamente a pontuação multiplicada por abates em série (`combo_streak`), concedendo benefícios globais, como fortalecimento dos ataques aliados (Familiares/Orbes).
- **Restart Rápido:** A função `restart_match()` redefine o placar e envia sinais para todas as interfaces reagirem sem precisar recarregar todos os nós da memória principal imediatamente.

---

## 2. A Camada Base (EnemyBase)

Para a criação de inimigos, foi adotada a abstração genérica em `scripts/enemy_base.gd`. **TODO novo inimigo** no jogo deve estender `EnemyBase` e não mais `CharacterBody2D` puro.

### O que o `EnemyBase` resolve automaticamente:
- **Agrupamento:** Coloca o nó no grupo global `"enemies"`.
- **Gerenciamento de Vida (HP):** Aplica dano, chama o efeito visual de _flash hurt_ e orquestra o sumiço do inimigo.
- **Lógica de Morte (`die()`):** Registra o abate na pontuação via `GameManager`, emite um possível valor de cura à vila (`defeat_heal`) e executa um pop de partículas (`_dissolve_into_smoke()`).
- **Condição de Escapatória:** Checa iterativamente se o inimigo cruzou a barreira (`global_position.x <= GATE_X`) para subtrair vida da vila usando a variável `village_damage`.

### Implementando um novo inimigo:
Qualquer filho de `EnemyBase` só precisa se preocupar com:
1. Modificar os valores do inspetor (`max_hp`, `move_speed`, `village_damage`, `defeat_score`).
2. Adicionar o nó `AnimatedSprite2D` obrigatório (chamado `Animation`) e o `CollisionShape2D`.
3. Usar o hook `_enemy_ready()` para qualquer lógica de inicialização (como escolher variantes de tipo), visto que o `_ready()` original já está ocupado alocando no grupo `"enemies"`.

*(Exemplo prático de herança encontra-se em `scripts/bat.gd`)*

---

## 3. O Spawner Genérico (EnemySpawner)

Os inimigos são orquestrados e instanciados em tela pelo **`EnemySpawner`** (script `scripts/enemy_spawner.gd`).

### Principais Funcionalidades:
- **Tabela de Drops (Spawn Table):** Você pode carregar um Array de `SpawnEntry`, definindo Cenas + Pesos (ex: 70% Goblin, 30% Demônio). O spawner sempre sorteará com precisão estatística.
- **Modos de Spawns (Spawn Modes):** 
  - `CAMERA_RELATIVE`: Spawna o inimigo numa posição X relativa à borda da câmera atual, garantindo pressão constante independentemente de onde o player ande.
  - `ABSOLUTE`: Usa uma coordenada fixa global, ideal para bosses.
- **Rate de Spawn Dinâmico:** Os intervalos de nascimento são alterados automaticamente ao consultar o `GameManager.current_phase`.
- **Ondas Manuais (`spawn_wave()`):** Pode ser chamado externamente (por gatilhos no mapa) para gerar agrupamentos instantâneos de N inimigos, espaçados horizontalmente.

---

## 4. Integração com Entidades (Consumidores)

Todo o ecossistema age dinamicamente sobre o grupo `"enemies"`. Agentes que criarem novas funções devem manter a seguinte filosofia:

- **Colisões da Player:** A classe `player.gd` (em sua HurtBox) escaneia interseções buscando o grupo `"enemies"`. Portanto, qualquer nó desse grupo paralisará a jogadora e anulará seus frames.
- **Automação Aliada (Familiares):** A classe `ai_familiar.gd` (as Orbes protetoras) faz um scaneamento do inimigo **mais próximo em raio** dentro do grupo `"enemies"`. O dano será aplicado via Duck Typing (tentando chamar o método `.take_damage()`).
- **HUD:** Exclusivamente visual. Todo feedback escrito ou sinal que transita no `hud.gd` deve utilizar jargões de "Inimigos" para se manter neutro a futuras atualizações e consumirá os sinais padronizados `enemy_defeated_changed`.
