# Changelog

Todas as mudanças notáveis do projeto ficam aqui, da mais recente pra mais antiga. Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/). Tudo que se faz entra em **[Não lançado]**.

## [Não lançado]

### Adicionado
- Documento de design (`docs/GDD.md`) e história resumida por ato/fase (`docs/ROTEIRO.md`).
- Projeto Godot 4.7, Android como plataforma primária. Export preset Android, build clássico sem Gradle (`export_presets.cfg`) — gera `build/android/turno-duplo.apk`.
- Camada de input abstraída por ação (`autoload/input_bridge.gd`), com reivindicação de toque compartilhada (`try_claim_touch`/`release_touch`) pra evitar conflito entre manches e botões com zonas sobrepostas.
- Controles touch reutilizáveis: manche virtual preso a uma origem (`ui/virtual_joystick.gd`), botão contextual com distinção toque-rápido/segurar e anel de progresso em tempo real pra ações onde isso importa (`ui/contextual_button.gd`), caixa de texto sequencial pra narrativa linear com `tr()` aplicado automaticamente (`ui/story_box.gd` — placeholder até o Modo Diálogo com ramificação ser prototipado).
- Sandbox tático (`sandbox/tatico.gd`) e de perseguição (`sandbox/perseguicao.gd`) — controles validados em 8 rodadas de teste num celular Android real, servem de referência de "feel" pras missões reais.
- **Ato 1 (Academia) completo — as 4 fases de conteúdo real do `docs/ROTEIRO.md`:**
  - **Fase 1 — Chegada** (`ato1_fase1_chegada.gd`): 3 áreas (rua/estacionamento → entrada → estande); Okafor e Theo esperam parados até o jogador chegar perto (proximidade dispara diálogo); Mark se apresenta e chega atrasado (Okafor cobra, Theo se irrita); precisa pegar arma numa bancada (botão "Pegar" — base do sistema futuro de pegar arma de suspeito) antes do botão Atirar aparecer; Theo acerta os 4 alvos primeiro e eles resetam pra vez do jogador; a reação do Theo no final muda conforme o jogador erra ou não algum tiro.
  - **Fase 2 — Abordagem Tática** (`ato1_fase2_abordagem.gd`): casa de treinamento com alvos-ameaça e alvos-não-ameaça (civil/refém) misturados — discriminar antes de atirar é o gancho mecânico de "decisões de uso da força". Okafor e Theo observam de fora, não entram com o jogador; avaliação muda se acertou um civil ou pelo estilo de arrombamento.
  - **Fase 3 — Direção Defensiva** (`ato1_fase3_direcao.gd`): circuito fechado sem risco — 3 checkpoints em sequência, depois um PIT maneuver de prática que exige contato físico real com o carro-alvo (não só se aproximar e segurar um botão). Contraste narrativo: o Theo, que provocava o Mark por cuidadoso nas Fases 1/2, quase bate de tanta pressa aqui — primeira vez que a Okafor elogia o controle do Mark sem ressalva.
  - **Fase 4 — Avaliação Final / Formatura** (`ato1_fase4_formatura.gd`): fecha o ato. Escopo deliberadamente narrativo, sem repetir tiro/abordagem/direção (já testados nas fases anteriores) — cerimônia de formatura, avaliação da Okafor, respeito mútuo com o Theo, e a lotação que abre o gancho pro Ato 2: Mark vai pra Ironside, sob o Sgt. Ray Doyle.
- Mira com linha de trajetória em tempo real (raio de física calculado todo frame, não só ao atirar) — mostra onde o tiro vai bater antes de disparar, e ignora alvos/ameaças/civis já neutralizados em vez de "parar" neles.
- Textos de conteúdo real (`missions/`) preparados pra tradução futura via `tr()`; o sandbox de teste fica de fora de propósito (ferramenta descartável, não vai ao jogo final).

### Corrigido
- Bug em `hold_time()` que fazia toque-rápido-vs-segurar sempre registrar como "rápido", não importa quanto tempo o jogador segurasse de verdade — corrigido com `last_hold_time()`, que captura a duração no instante do soltar.
- Raio de mira/tiro colidindo com objetos que não deveriam bloquear (bancada de armas, alvos já neutralizados) em vez de passar direto pro que importa.
- Manches desacoplados: a mira não "segue" mais a direção de movimento quando o manche direito é solto — deixava a gameplay travada em cenas mais cheias.
- PIT maneuver exigia só proximidade + segurar um botão parado, sem contato nenhum entre os carros — corrigido pra exigir colisão física real.
