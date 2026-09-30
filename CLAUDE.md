# TURNO DUPLO — guia para o Claude

Jogo de polícia-e-ladrão pra celular (**paisagem, Android**), topdown 2.5D pixel art, **Godot 4.7 + GDScript**. Projeto pessoal do usuário. GDD e roteiro fechados; **Ato 1 (Academia) completo em conteúdo real, controles validados**. Já é repositório git.
Este arquivo é o ponto de partida de cada conversa; os detalhes ficam nos documentos abaixo.

## Onde está cada coisa
- `docs/GDD.md`: documento de design, a fonte de verdade. 11 seções: premissa e referências, estrutura narrativa por ato, pilares de design, protagonista, antagonista/conspiração, cidade, estilo visual/câmera/engine/plataforma, mecânicas e controles (touch), estrutura de missões, elenco de apoio, progressão/economia. **Toda decisão nova entra aqui antes de seguir em frente** — não deixar decisão só na conversa.
- `docs/ROTEIRO.md`: a história resumida fase a fase, por ato — a tradução narrativa da estrutura de missões do GDD (Seção 9). Consultar antes de escrever qualquer cena/diálogo de verdade, pra não repetir ou contradizer o que já foi fechado.
- `autoload/input_bridge.gd`: camada única de input abstraída por ação (move/aim/primary/secondary) — GDD Seção 8. Manches e botões touch escrevem aqui; qualquer sandbox/cena lê daqui. Teclado (WASD) funciona em paralelo só pra testar rápido no editor.
- `ui/virtual_joystick.gd`, `ui/contextual_button.gd`: os controles touch reutilizáveis (manche flutuante, botão com distinção toque-rápido/segurar). `ui/story_box.gd`: caixa de texto sequencial pra narrativa linear — placeholder até o Modo Diálogo/Quadro de Evidências (com escolha) ser prototipado de verdade. Reaproveitar essas três em qualquer cena nova, não duplicar.
- `sandbox/`: os protótipos de controle (`menu.tscn` → `tatico.tscn` / `perseguicao.tscn`). Caixa cinza, geometria construída por código — controles já validados no celular (8 rodadas), servem de referência de "feel" pras missões de verdade.
- `missions/`: conteúdo real da campanha, seguindo `docs/ROTEIRO.md` fase a fase.
  - `ato1_fase1_chegada.gd` (Fase 1 — Chegada): 3 áreas (rua/estacionamento → entrada → estande), câmera seguindo o jogador, NPCs parados até o jogador chegar perto (proximidade dispara diálogo), Okafor guia até o estande, Theo participa (atira primeiro), mecânica de pegar arma na bancada antes de poder atirar.
  - `ato1_fase2_abordagem.gd` (Fase 2 — Abordagem Tática): casa de treinamento com alvos-ameaça e alvos-não-ameaça (civil/refém) misturados — discriminar antes de atirar é o gancho mecânico de "decisões de uso da força". Okafor/Theo ficam de fora observando, não entram com o jogador.
  - `ato1_fase3_direcao.gd` (Fase 3 — Direção Defensiva): circuito fechado sem risco (3 checkpoints + PIT de prática num carro-alvo), reaproveitando a física de direção/freio/PIT do sandbox de perseguição. Contraste narrativo pago: o Theo, que provocava o Mark por cuidadoso nas Fases 1/2, quase bate de pressa aqui — primeira vez que a Okafor elogia o Mark sem ressalva.
  - As duas primeiras reaproveitam os controles do sandbox tático (validados) + `story_box.gd` pra narrativa. **3 arquivos com a mesma lógica de jogador tático (movimento/mira/cobertura/tiro) quase idêntica — bateu a "regra dos três"**: se uma 4ª missão tática precisar do mesmo, extrair um componente compartilhado em vez de copiar de novo. (O controlador de carro da Fase 3 é só a 2ª cópia — ainda não bateu a regra dos três.)
- `export_presets.cfg`: preset Android (build clássico, sem Gradle) — gera `build/android/turno-duplo.apk`.
- `CHANGELOG.md`: o que mudou, mais recente primeiro. Tudo que se faz entra em **[Não lançado]** (não versionamos ainda — sem número de versão até o usuário decidir marcar um marco).

## Como trabalhamos
- **Conversa e textos do jogo em português do Brasil.**
- O projeto está em **pré-produção**: o processo até aqui foi construir o GDD seção por seção, sempre revisando consistência entre seções quando algo novo muda uma decisão anterior (já aconteceu — GDD passou de v0.1 pra v0.2 numa revisão de inconsistências).
- Quando o usuário pede "o que você acha" ou "faça a sugestão", ele quer uma **recomendação concreta e justificada**, não uma lista de opções genérica — decide e explica o porquê, oferece alternativa só se fizer sentido.
- **Regra de ouro herdada da Seção 9 do GDD:** nada entra no jogo (mecânica, personagem, conteúdo opcional) só por preencher espaço — precisa mover um medidor rastreado, plantar um retorno concreto mais tarde na história, ou aprofundar personagem que já é central. Vale como princípio geral, não só pra side-content.
- O usuário deixou claro que **não quer campanha arrastada nem conteúdo genérico** — ao propor mecânica, missão ou personagem novo, checar se paga alguma coisa depois (referência: a revisão que criou "O Aviso" no Ato 3 e o touchpoint do Theo no Ato 2, ambos resolvendo gaps que o próprio usuário apontou).
- **Commits:** repositório git já existe, com commits feitos pelo usuário. Continua a regra: só commitar quando o usuário pedir explicitamente, nunca por conta própria.
- **Toda mudança relevante entra no `CHANGELOG.md`** (seção `[Não lançado]`), do jeito que o outro projeto do usuário (Casa Cheia) já faz.
- **Texto de conteúdo real (missões, falas) é preparado pra tradução desde já — confirmado com o usuário:** falas passam por `story.say([...], [...])`, que aplica `tr()` sozinho (não precisa embrulhar cada linha no chamador); textos de HUD/formato (`"Alvos: %d/%d"`) precisam de `tr()` **antes** do `%`. O `sandbox/` (menu, tático, perseguição) fica **de fora de propósito, e o usuário confirmou que é assim mesmo**: é ferramenta de teste descartável, não vai ao jogo final, traduzir seria trabalho jogado fora. Ainda não existe arquivo `.csv` de tradução — isso só faz sentido quando houver um segundo idioma de verdade pra preencher; por ora o `tr()` sozinho já deixa tudo pronto pra quando isso acontecer.

## Decisões de design já fechadas (resumo rápido — detalhe sempre no GDD)
- **Sem mundo aberto:** missões contidas e lineares, sem hub andável, seleção de caso tipo mural entre missões.
- **Câmera única topdown 2.5D** pra todos os modos de jogo (tático, perseguição, diálogo) — sem sistema de câmera separado por modo.
- **Controles touch:** twin-stick contextual (manche esquerdo = movimento/direção; manche direito = mira, só aparece com alvo no alcance; botões contextuais grande/pequeno mudam de função por modo). "Atirar dirigindo" é exclusivo do Ato 4, de propósito.
- **Sem XP, loja ou grind:** progressão é 100% narrativa (mecânica nova = a história chegou lá); equipamento muda automaticamente por ato. Monetização: **pago único (premium)**, sem ads/IAP.
- **Elenco fixo:** Mark Reyes (protagonista), Capitã Diane Okafor, Sgt. Ray Doyle (FTO, revelado como vazamento pro vilão), Oficial Theo Marsh (rival que vira parceiro), Sarah e Emma Reyes (família), Lou/Miko (informantes), Wade "Ghost" Calloway (wheelman rival), Adrian Kessler (vilão — motivação dupla: lucro/controle de risco primeiro, mágoa pessoal silenciosa por baixo).
- **24 missões principais** (4 Academia + 6 Patrulha + 8 Detetive + 6 Ação), ~5–6h de campanha.

## Próximo passo
**Ato 1 (Academia) está completo** — as 4 fases do `docs/ROTEIRO.md` construídas (`missions/ato1_fase1_chegada.gd` até `ato1_fase4_formatura.gd`). Controles do sandbox validados em 8 rodadas de teste. Resumo do que existe: `CHANGELOG.md`. Detalhes técnicos/gotchas de cada rodada de teste: "Estado atual" abaixo.

**Ainda não testado no celular** desde a última rodada de correções (bug do `hold_time()`, mira atravessando alvo abatido, manches desacoplados, PIT exigindo contato físico). É o próximo passo antes de decidir entre:
- Começar o **Ato 2** (Novato nas Ruas) — primeiro turno de patrulha com o Sgt. Doyle.
- Prototipar o **Modo Diálogo/Quadro de Evidências** de verdade (Ato 3) — hoje só existe `story_box.gd`, linear e sem escolha.
- Prototipar a **fusão tático+perseguição** (atirar dirigindo, Ato 4) — só existe no papel.

**Pendências registradas no GDD Seção 8 (nenhuma implementada ainda):** layout de controles configurável pelo jogador; sistema de munição + pegar arma de suspeito (a mecânica de pegar arma da Fase 1 já foi desenhada genérica o bastante pra virar a base disso); múltiplas formas de encerrar perseguição de verdade no Ato 2+ (atirar no pneu, perseguir até desistir, bater até quebrar, fechar o carro).

**Padrões estabelecidos, pra repetir:** `Camera2D` filho do player com `position_smoothing_enabled` sempre que a missão for maior que uma sala só; NPCs de apoio como `Node2D` com `move_toward()` pra beats guiados, sem IA/pathfinding de verdade; uma fase sem mecânica nova pra ensinar pode ser majoritariamente narrativa (Fase 4) em vez de repetir gameplay já validado nas fases anteriores.

## Comandos (Godot em `D:\Godot`)
```
G="/d/Godot/Godot_v4.7.2-stable_win64_console.exe"
$G --headless --path . --import                              # reimportar depois de criar scripts/cenas
$G --headless --path . res://sandbox/tatico.tscn              # roda a cena de cabeça (pega erro de script; alguns segundos e mate o processo — não há tela pra fechar sozinho)
$G --headless --path . res://sandbox/perseguicao.tscn         # idem, sandbox de perseguição
$G --path . res://sandbox/menu.tscn                           # roda com janela, pra testar com mouse no PC (emula toque)
$G --headless --path . --export-debug "Android" build/android/turno-duplo.apk   # gera o APK de debug (preset em export_presets.cfg)
```
Isso pega **erro de script/parse**, não substitui testar no celular — o feel de toque só se confirma no aparelho.

**Android SDK já está instalado** em `C:\Users\luuan\AppData\Local\Android\Sdk` (usado pelo outro projeto) — o export de debug assina sozinho com o keystore de debug padrão, sem precisar configurar nada a mais. `adb` fica em `.../Sdk/platform-tools/adb.exe`.
```
.../adb.exe devices                          # confere se o celular está conectado (USB debugging ligado)
.../adb.exe install -r build/android/turno-duplo.apk   # instala direto por USB
```
Sem cabo à mão: servir o APK na rede Wi-Fi (`python -m http.server 8000` na pasta `build/android`) e abrir `http://<IP do PC>:8000/turno-duplo.apk` no celular, como o outro projeto já faz.

## Estado atual
- GDD v0.2 fechado, `ROTEIRO.md` fechado e sincronizado com o GDD (mesma contagem de fases/atos).
- **Protótipo de controles validado no celular** (`project.godot` + `autoload/`, `ui/`, `sandbox/`) em 8 rodadas de teste real — "fechou é isso!" (ver retornos abaixo pro histórico completo).
- **Ato 1 (Academia) completo**: 4 fases de conteúdo real em `missions/`, seguindo `docs/ROTEIRO.md`. Ver `CHANGELOG.md` pro resumo do que cada fase tem.
- **APK de debug gerado** (`build/android/turno-duplo.apk`, preset em `export_presets.cfg`, build clássico sem Gradle). Ver GDD Seção 8 pra decisão de controle atual (já reflete todos os retornos abaixo).
  - **Retorno do 1º teste:** manche esquerdo/movimento ótimo; manche direito nunca apareceu (bug: condicionado a ter alvo por perto); botão único "AÇÃO" confuso; dirigir com manche único (direção+aceleração juntos) "ficou horrível". Corrigido: botões contextuais viraram um por ação; perseguição ganhou botões dedicados de acelerar/frear. `input_bridge.gd` mudou pra ações por nome livre em vez do par fixo `action_primary`/`action_secondary`.
  - **Retorno do 2º teste:** manche direito com "canto morto" (zona fixada em pixel assumindo 960×540; a tela real é mais larga) — corrigido com **âncoras relativas à tela real** em tudo. Soltar o manche direito virava a visão instantaneamente — suavizado (rápido mirando, lento voltando pra direção de movimento). Sprint nunca disparava (limiar de 95% de deflexão quase impossível de sustentar) — baixado + anel visual de progresso. Direção do carro "muito difícil" — zona-morta + suavização + taxa de giro menor.
  - **Retorno do 3º teste:** pediu pra ir na linha de COD Mobile/PUBG Mobile/Free Fire pro tático — trocamos o manche direito por `ui/look_zone.gd` (zona de olhar sem origem fixa, arrastar livre) e o botão "Atirar" virou **sempre visível/disponível**. Tiro virou **raycast de física real** (`PhysicsRayQueryParameters2D`) — acerta parede (bloqueia), alvo, ou objetos do cenário: adicionamos luminária (apaga/acende) e caixa (quebra) pra demonstrar atirar no cenário como estratégia. Porta ganhou uma variante destrancada (Abrir) além da trancada (Arrombar). Direção da perseguição virou relativa à **tela** em vez de ao **carro** (resolve a confusão de esquerda/direita mudar de sentido conforme a orientação do carro).
  - **Retorno do 4º teste:** o usuário quis o **manche direito de volta** — a referência a COD Mobile/PUBG/Free Fire era só sobre a **disposição dos botões na tela**, não sobre copiar o comportamento de arrastar livre. `ui/look_zone.gd` removido, `ui/virtual_joystick.gd` restaurado com `right_stick=true` pra mira. Mantido tudo o mais da rodada 3 (botão atirar sempre visível, raycast, portas por estado, direção da perseguição relativa à tela — aprovada: "controle do veículo está muito bom"). Carro estava rápido demais — `MAX_SPEED` 240→185. Pedido novo registrado como pendência na Seção 8 do GDD, **não implementado**: layout de controles configurável pelo jogador.
  - **Retorno do 5º teste:** perseguição confirmada 100% boa, sem mudança. No tático, a mira "não estava tão suave como antes" e "às vezes não aparece" — o usuário suspeitou (corretamente) que era clicar em cima de botões invisíveis. Causa real: o botão ATIRAR (sempre visível desde a rodada 3) fica perto o bastante do manche direito pra as duas zonas de toque se sobreporem, e cada controle decidia sozinho "esse toque é meu" sem checar se outro já tinha pego — o mesmo toque sendo processado por dois controles ao mesmo tempo interrompia o arraste do manche. Corrigido com **reivindicação de toque compartilhada** (`InputBridge.try_claim_touch`/`release_touch`, usado em `virtual_joystick.gd` e `contextual_button.gd`) — cada dedo só pertence a um controle por vez. Também corrigido de quebra um vazamento: se um botão some enquanto pressionado, agora libera a reivindicação (antes o dedo ficava "preso" pra sempre nesse caso).
  - **Retorno do 6º teste:** ainda existia uma área (perto de onde ARROMBAR/ABRIR aparecem) onde tocar não mostrava o manche direito. Causa: o manche direito tinha `anchor_bottom = 0.75` pra "reservar" espaço pros botões embaixo — mas como esses botões ficam invisíveis a maior parte do tempo, essa faixa reservada virava área morta permanente. Corrigido: manche cobre a metade direita **inteira** (`anchor_bottom = 1.0`); pra os botões continuarem respondendo, coloquei-os **antes** do manche na árvore, assumindo (errado, ver abaixo) que ordem de adição = prioridade de toque. Suavizei também a mira: `FACING_TURN_SPEED_AIMING` 14.0 → 9.0 rad/s.
  - **Retorno do 7º teste:** a suposição da rodada 6 estava invertida — nenhum botão (Atirar/Arrombar/Abrir) respondia mais a toque nenhum. No Godot, **quem é adicionado por último na árvore recebe o evento de toque primeiro**, não o primeiro. Corrigido invertendo a ordem em `_build_controls()`: manche direito adicionado primeiro (cobrindo a tela toda, sem área morta), botões adicionados depois (ganham a disputa quando visíveis).
  - **Retorno do 8º teste: "fechou é isso!" — controles do tático e da perseguição aprovados.** Não há pendência de controle conhecida no momento.
  - **Fase 2 (celular):** bug real em `hold_time()` — quem lia a duração do toque *depois* de soltar sempre via 0.0 (a função se recusa a responder pra uma ação que já não está mais "segurada"), então a porta sempre registrava como arrombada rápido, não importa quanto o jogador segurasse de verdade. Corrigido com `InputBridge.last_hold_time()`, que captura a duração no instante do soltar, antes do estado ser limpo — **usar essa função, não `hold_time()`, pra decidir algo depois que o botão já foi solto.**
  - **Fase 2 (celular):** mira parava em alvo/ameaça/civil já neutralizado em vez de passar pro que estivesse atrás — corrigido excluindo do raio qualquer alvo com `hit == true`.
  - **Fase 2 (celular):** manches desacoplados de vez — "mira segue a direção de movimento quando solta" (validado como bom isoladamente numa rodada anterior) causava gameplay travada em cena mais cheia. Esquerdo só move, direito é o único jeito de mudar a mira; sem tocar nele, a mira congela onde estava.
  - **Fase 3 (celular):** PIT "chegar perto e segurar o botão parado" foi descrito como "não fez muito sentido" — sem contato físico entre os carros, nenhum feedback real. Corrigido pra exigir colisão de verdade via `CharacterBody2D.get_slide_collision_count()`/`get_slide_collision()`, além do alinhamento e do botão segurado — **esse é o padrão a seguir pra qualquer mecânica futura de "bater em algo com o carro".**
- Repositório git com commits do usuário (não commitar por conta própria — só quando pedido).
