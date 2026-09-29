# Changelog

Todas as mudanças notáveis do projeto ficam aqui, da mais recente pra mais antiga. Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/). Tudo que se faz entra em **[Não lançado]**.

## [Não lançado]

### Adicionado
- **Ato 1, Fase 2 — Abordagem Tática** (`missions/ato1_fase2_abordagem.gd`): casa de treinamento com alvos-ameaça e alvos-não-ameaça (civil/refém) misturados — o jogador precisa discriminar antes de atirar, não só acertar. Okafor e Theo ficam observando de fora (não entram com o Mark) e avaliam a atuação: reação muda se acertou algum civil, e tem uma nota sobre o estilo de arrombamento (rápido/barulhento vs. devagar/limpo). Reaproveita manche, câmera, cobertura/espiar, arrombar e a linha de mira já validados.
- Ato 1 Fase 1 ganhou uma terceira área: **Rua/Estacionamento**, fora da academia, onde o Mark chega antes de entrar. Okafor e Theo agora esperam **parados** na entrada e só reagem (falam) quando o jogador chega perto (zona de proximidade), em vez de a conversa disparar sozinha ao carregar a fase.
- **Mecânica de pegar arma**: bancada no estande com botão contextual "PEGAR" — o botão ATIRAR só aparece depois de pegar a arma. Base do sistema futuro de pegar a arma de um suspeito quando a do jogador ficar sem munição (registrado como pendência de design no GDD).
- Mira suavizada ainda mais a pedido do usuário: `FACING_TURN_SPEED_AIMING` 9.0 → 6.0 rad/s (tático e missão).

### Corrigido
- Raio de mira/tiro agora exclui a bancada de armas (`weapon_rack`) além do próprio jogador — sem isso, um tiro mirado de volta pra entrada podia "acertar" a bancada em vez de alvo/parede.
- **Linha de mira em tempo real** (raio calculado todo frame, não só ao atirar) no sandbox tático e na Ato 1 Fase 1 — mostra exatamente onde o tiro vai bater antes de atirar (verde se for acertar algo válido, branco se não). Resolve a dificuldade relatada de entender a direção do tiro.
- Sequência da Ato 1 Fase 1 reescrita: Mark chega atrasado e se apresenta, Okafor cobra o atraso, Theo mostra insatisfação, o grupo vai ao estande, Okafor manda pegar arma, **Theo atira primeiro e acerta os 4 alvos**, os alvos resetam pra vez do jogador, e a reação do Theo agora **muda de verdade**: comentário de rivalidade ("Nada mal") se o jogador acertar tudo sem errar nenhum tiro, piada se ele errar algum.
- `CHANGELOG.md` (este arquivo).
- Textos preparados pra tradução futura: `tr()` aplicado nas falas (dentro de `ui/story_box.gd`, num lugar só) e nos textos de HUD/botões que aparecem em conteúdo real de jogo (`missions/`). Sandbox/menu de teste (`sandbox/`) ficam de fora de propósito — não são conteúdo que vai ser lançado.
- Ato 1 Fase 1 ("Chegada") expandida: câmera (`Camera2D`) acompanhando o Mark; diálogo de verdade com Mark se apresentando à Capitã Okafor, e o Theo Marsh interagindo; Okafor guia o jogador visualmente até o estande (anda até um ponto, sem sistema de IA completo); Theo participa atirando primeiro em 2 dos 4 alvos antes da vez do jogador.
- Documento de design (`docs/GDD.md`) e história resumida por ato/fase (`docs/ROTEIRO.md`).
- Projeto Godot 4.7 do protótipo, Android como plataforma primária.
- Camada de input abstraída por ação (`autoload/input_bridge.gd`), com reivindicação de toque compartilhada (`try_claim_touch`/`release_touch`) pra evitar conflito entre manches e botões com zonas sobrepostas.
- Controles touch reutilizáveis: manche virtual preso a uma origem (`ui/virtual_joystick.gd`), botão contextual com distinção toque-rápido/segurar (`ui/contextual_button.gd`), caixa de texto sequencial pra narrativa linear (`ui/story_box.gd` — placeholder até o Modo Diálogo com ramificação ser prototipado).
- Sandbox tático (`sandbox/tatico.gd`): mover, sprint, cobertura, espiar, arrombar/abrir porta por estado, mirar e atirar por raycast de física (acerta parede, alvo, luminária, caixa). Validado em 8 rodadas de teste num celular Android real.
- Sandbox de perseguição (`sandbox/perseguicao.gd`): dirigir com direção relativa à tela, acelerar/frear/freio de mão como botões dedicados, PIT maneuver, mira automática pra atirar dirigindo. Validado no mesmo processo de teste.
- Primeira missão de conteúdo real: Ato 1, Fase 1 — "Chegada" (`missions/ato1_fase1_chegada.gd`).
- Export preset Android, build clássico sem Gradle (`export_presets.cfg`) — gera `build/android/turno-duplo.apk`.
