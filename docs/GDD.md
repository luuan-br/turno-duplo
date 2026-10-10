# [Título provisório: "TURNO DUPLO"]
### Game Design Document — v0.2 (revisado)

---

## 1. Conceito e Premissa

**Logline:**
Um recruta idealista entra para a academia de polícia sonhando em fazer a diferença — e descobre que a cidade real é mais lenta, mais burocrática e mais perigosa do que qualquer treinamento preparou ele. Anos depois, já detetive endurecido pelo trabalho e tentando não perder a família pelo caminho, ele puxa o fio de um caso aparentemente pequeno que revela uma conspiração enorme o suficiente para colocar a cidade inteira em chamas — e ele é o único que está no lugar certo, na hora errada, pra impedir.

**Referências e o que cada uma empresta:**

| Referência | O que puxamos dela |
|---|---|
| **World's Scariest Police Chases** (PS1) | A crueza e a adrenalina das perseguições — colisões, spike strips, PIT maneuver, a sensação de caos real de câmera de helicóptero/dashcam |
| **Driver 2** (PS1) | Entrar/sair do carro livremente, a fantasia de dirigir como policial, perseguições com objetivo narrativo (não mundo aberto — puxamos a *sensação* de dirigir pela cidade, dentro de mapas contidos por missão) |
| **Police Stories** (Steam) | O lado tático/procedural — abordagens, breach & clear, decisões não-letais vs. letais, ritmo mais lento e cerebral |
| **Duro de Matar 4.0 (Live Free or Die Hard)** | Escalada: um policial comum contra uma ameaça desproporcional, sátira ácida sobre burocracia policial que vira pura ação, conflito família-vs-dever, humor no meio do caos |
| **GTA 1 / GTA 2** (1997/1999) | Prova de conceito histórica: polícia-e-ladrão em topdown/pixel art funciona — perseguições, bloqueios, nível de procurado, tudo num engine 2D. Mesma geração retrô de WSPC e Driver 2. |
| **Retro City Rampage** | Referência moderna de como um topdown pixel art consegue entregar direção, perseguição e ação com identidade retrô coesa. |
| **Intravenous 2: Mercenarism** | Referência de execução: topdown 2.5D tático moderno, stealth/combate com peso e consequência — usado como vara de medir qualidade de produção pro lado tático do jogo. |
| **Of Guards and Thieves** | Referência de assimetria cops-vs-robbers em topdown — reforça a fantasia central de perseguição/captura sob a ótica policial. |

**A grande ideia estrutural:**
O jogo é desenhado para **mudar de ritmo junto com a carreira do protagonista**. Isso não é só tema narrativo — é a espinha dorsal do game design:

- No começo, você é **lento, procedural, supervisionado** (academia).
- No meio, você é **rotineiro, mas com picos de adrenalina** (patrulha nas ruas).
- Depois, você é **metódico e investigativo, mas emocionalmente sob pressão** (detetive).
- No final, tudo colide: **perseguições, tiroteios, infiltração** — a cidade inteira vira o parquinho de perseguição estilo *World's Scariest Police Chases*, mas agora com tudo que você aprendeu nos atos anteriores.

Ou seja: o jogador não aprende só mecânicas novas a cada ato — ele **sente a carreira** do personagem na pele, do boletim de ocorrência ao "yippee-ki-yay".

---

## 2. Estrutura Narrativa (4 Atos)

### ATO 1 — A Academia
*Ritmo: lento, tutorial, disciplinado*

- Protagonista é recruta novato. Funciona como tutorial diegético: estande de tiro, abordagem tática, primeiros socorros, direção defensiva, procedimento operacional padrão.
- Inspiração direta de **Police Stories**: sequências curtas e metódicas, decisões de uso da força, avaliação de desempenho.
- Estabelece o **motivo pessoal** do protagonista pra ter entrado na corporação: o pai de Mark foi policial da cidade por 25 anos e nunca falava sobre o trabalho em casa — Mark entra tentando entender esse silêncio (Seção 4).
- Introduz colegas de turma (rivalidade, amizade, um instrutor durão-mas-justo).
- Fecha com a formatura — o jogador escolhe/recebe sua primeira lotação.

### ATO 2 — Novato nas Ruas
*Ritmo: moderado, cotidiano com picos*

- Estrutura em **missões contidas e lineares** (não mundo aberto): cada turno de patrulha é um "nível" curto e desenhado à mão — um trecho de bairro, uma rua comercial, um conjunto habitacional — com objetivo claro, não um mapa gigante pra explorar livremente.
- Dirigir a viatura entra como trecho de missão (ir do ponto A ao B respondendo ao rádio), não como mundo livre no estilo Driver 2/GTA — a inspiração de Driver 2 aqui é a *sensação* de estar ao volante como policial, não a estrutura aberta.
- Loop de patrulha: abordagens de trânsito, chamados de rotina, pequenos furtos — intercalados com **perseguições curtas e brutais** (a dose inicial de *World's Scariest Police Chases*), sempre dentro do escopo contido da missão.
- Parceiro/FTO (Field Training Officer) como dupla clássica de filme policial — gera humor, confiança, e depois consequência emocional.
- Um "medidor de reputação/comunidade" reage a como o jogador lida com abordagens (excesso de força vs. de-escalada), plantando o tema de "que tipo de policial eu quero ser".
- Sub-plot residual: uma série de crimes aparentemente desconexos (assaltos a caixas eletrônicos, falhas "aleatórias" em semáforos, um hacker sendo perseguido e escapando) — o jogador nem percebe ainda, mas é a semente do Ato 4.
- Fecha com o incidente que muda tudo: o parceiro/FTO de Mark, Sgt. Doyle, é ferido em serviço num confronto que parece rotina (Seção 10). Mark nota um detalhe na cena que não fecha e insiste em investigar por conta própria — o faro analítico que chama a atenção da Capitã Okafor e da Divisão de Investigações.

### ATO 3 — Emblema de Detetive
*Ritmo: mais lento de novo, mas tenso — pressão em vez de ação*

- Muda o gameplay pra investigação: quadro de evidências, interrogatórios, cena de crime, informantes, vigilância.
- Tema **Duro de Matar 4.0**: o protagonista tenta equilibrar a vida familiar (cônjuge, filho crescendo) com um caso que consome cada vez mais tempo — cenas domésticas como contraponto emocional.
- O caso "pequeno" do Ato 2 se revela ser a ponta de uma operação muito maior e cuidadosamente planejada: um roubo de precisão mirando a consolidação bancária que vai acontecer no Cais (Seção 5) — Kessler usa sabotagem de infraestrutura como ferramenta pra cobrir o golpe, não como um ataque em si.
- Ponto de virada duplo: a investigação revela que Doyle foi quem vazou informação operacional pra Kessler (Seção 10) — e, quase ao mesmo tempo, Kessler percebe que Mark está perto demais e a família dele passa a ser ameaçada, tornando o caso pessoal.

### ATO 4 — A Cidade em Chamas
*Ritmo: frenético, ação pura, catártico*

- Aqui o jogo "solta a mão": perseguições em larga escala, tiroteios, infiltração tática — só que agora usando **tudo** que o jogador aprendeu: precisão tática do Ato 1, direção e perseguição do Ato 2, dedução/uso de pistas do Ato 3.
- Estrutura de "um homem contra o sistema" clássica de Duro de Matar: o protagonista, isolado do apoio institucional normal, precisa impedir o vilão sozinho (ou quase).
- Clímax pessoal (extrair e proteger Sarah e Emma) + clímax público (impedir o roubo de Kessler no Cais antes que a operação se conclua). A questão do Doyle já foi resolvida no Ato 3 — o Ato 4 é sobre a família e sobre Kessler.
- Epílogo: contraste entre o recruta ingênuo do Ato 1 e quem ele se tornou — abre gancho pra continuação sem deixar ponta solta.

---

## 3. Pilares de Design (rascunho — a validar)

1. **Ritmo como narrativa** — a progressão de mecânicas *é* o arco do personagem, não só power creep.
2. **Identidade dupla de gameplay, em missões contidas** — patrulha/perseguição (ação) e investigação (procedural, cerebral) como duas metades que se alternam e depois se fundem, sempre dentro de níveis lineares/semi-lineares desenhados à mão — sem mundo aberto, sem mapa gigante pra preencher.
3. **Peso pessoal acima da escala do vilão** — por maior que fique a ameaça, a câmera nunca larga o drama familiar/pessoal do protagonista.
4. **Perseguições que doem** — física arcade simples por baixo (Seção 8), mas com feedback de impacto exagerado (dano em estágio, screen shake, knockback, PIT simulado — Seção 7) que vende a crueza de *World's Scariest Police Chases*. O peso é sentido pelo jogador, não simulado com física real.

---

## 4. Protagonista

**Nome provisório:** Marcus "Mark" Reyes *(fácil de trocar — só um gancho pra não ficar "o protagonista")*

**Arquétipo:** o idealista que vira cínico que vira herói relutante — o clássico arco de policial de filme dos anos 90/2000, mas jogado devagar o suficiente pra doer.

**Background:**
- Cresceu vendo o pai (ou uma figura paterna) como policial da cidade — não um herói perfeito, alguém cansado, que cumpriu 25 anos de plantão e nunca falava sobre o trabalho em casa. Mark entra na corporação tentando entender esse silêncio, ou provar que dá pra ser diferente.
- Entra na Academia mais como **idealista** do que como durão — é bom em procedimento, ruim em política interna. Isso gera atrito com colegas mais "malandros" desde o Ato 1.

**Arco emocional pelos atos:**
- **Ato 1 (Academia):** ingênuo, disciplinado, acredita no sistema. Choque de realidade: aprende que seguir a cartilha à risca nem sempre é o caminho certo.
- **Ato 2 (Patrulha):** o dia a dia desgasta o idealismo. O parceiro/FTO vira o contrapeso — cínico, experiente, "engraçadinho" — e ensina Mark os atalhos do ofício (nem todos limpos). Mark começa a formar sua própria régua moral.
- **Ato 3 (Detetive):** promovido, mas isolado — o trabalho investigativo é solitário, leva trabalho pra casa (literal e emocionalmente). A família — a esposa Sarah e a filha pré-adolescente Emma (Seção 10) — sente a ausência dele. O casamento está tenso, não quebrado — ainda dá tempo de consertar, o que é a aposta emocional do jogo.
- **Ato 4 (Ação):** tudo que ele aprendeu — disciplina da Academia, instinto de rua, frieza analítica de detetive — converge. Ele para de seguir o manual e começa a *improvisar*, o momento "McClane" da história. O crescimento não é "virar um super-soldado", é ele finalmente confiar no próprio julgamento.

**Tom de voz:** seco, autodepreciativo sob pressão (humor de Die Hard, mas dosado — não é piada o tempo todo), fica mais calado quanto mais cansado.

---

## 5. Antagonista e Conspiração Central

**Vilão principal (provisório):** Adrian Kessler — *o Arquiteto*

- Ex-contratante militar/logística de operações especiais que migrou pro crime como quem migra de carreira: crime é **um projeto a ser gerenciado com eficiência**. Não é um ideólogo nem busca plateia — e é exatamente por isso que a mágoa pessoal dele, quando aparece, é mais perturbadora do que um monólogo: ele não precisa que ninguém saiba que foi ele. A satisfação é privada.
- **Motivação dupla, mas assimétrica:** lucro e controle de risco vêm primeiro — é o que rege cada decisão tática, cada escolha de alvo, cada corte na operação. Mas por baixo disso existe uma mágoa real: anos atrás, Kessler coordenava um contrato crítico de segurança/resposta a emergências pra própria prefeitura de Bellmont. Quando um desastre expôs falhas que ele havia sinalizado repetidamente (e que foram ignoradas por corte de orçamento vindo de cima), a cidade precisava de um culpado público — e ele foi convenientemente descartável. Perdeu o contrato, a reputação, e no rastro disso a família também se afastou. Ele não se vê como vilão: se vê como alguém que fez tudo certo dentro do que lhe deram e foi descartado mesmo assim.
- Isso não vira discurso nem justificativa pro jogador simpatizar — Kessler não filosofa sobre isso em voz alta. Mas ele **escolhe** alvos, rotas e o momento do golpe de um jeito que humilha especificamente as pessoas/instituições que o descartaram (ex: o funcionário que assinou o corte de orçamento agora está na sala de comando na noite do golpe; o banco que financiou a "modernização" que o substituiu é o cofre que ele está roubando). O prazer dele é particular e silencioso — ele sorri baixinho, não faz vídeo pra imprensa.
- Modus operandi: comanda uma equipe pequena e altamente especializada — cada um com uma função clara, como um esquadrão: um infiltrador/hacker (sabota trânsito, câmeras, comunicação), um "wheelman" (motorista de fuga — vira um **rival recorrente de perseguição** pro jogador ao longo do jogo, ótimo gancho pra escalar a inspiração de World's Scariest Police Chases de ato pra ato) e músculo de apoio pontual. Nada de exército — a ameaça continua pessoal e tangível, cabendo nos mapas contidos.
- Kessler quase nunca atira primeiro nem se expõe — ele **planeja**. Isso cria um contraponto interessante com Mark: dois profissionais metódicos, um do lado da lei e outro fora dela, e o clímax é o momento em que Mark para de seguir o plano de Kessler e o obriga a improvisar pela primeira vez. Também funciona como espelho temático: Kessler é o que Mark pode virar se deixar o trabalho consumir tudo — a mesma frustração institucional que Mark sente no Ato 2/3, levada ao extremo.

**O alvo (o porquê de Bellmont, especificamente):**
- Os bancos de Bellmont estão consolidando suas reservas físicas numa única operação de segurança no Cais/Zona Industrial, por economia de custo logístico — uma janela de uma noite só, com transporte blindado e cofre temporário fortemente guardados, mas **a cidade toda precisa cooperar** (trânsito controlado, semáforos sincronizados pros comboios, energia estável). É exatamente esse tipo de operação municipal coordenada que dá a Kessler a superfície de ataque perfeita: sabotar a coordenação da cidade sabota a segurança do alvo.

**A ponte com a Academia/Ato 1 (twist de meio de jogo):**
- O FTO que treinou Mark, Sgt. Ray Doyle (Seção 10), tem uma ligação antiga com Kessler — colegas de uma unidade militar/contratante anos atrás — e agora cobre uma dívida grave sob ameaça. Não é vilania gratuita: é um homem decente que tomou uma decisão ruim sob pressão real (dívida, ameaça à própria família) e agora está preso nela.
- A informação que ele vaza pra Kessler não é ideológica — é operacional: escala de plantão, protocolos de resposta, pontos cegos da corporação. Isso mantém Kessler coerente com sua identidade: ele não corrompe por crença, corrompe por utilidade.
- Isso dá ao jogador um "e se" emocional: o mentor que ensinou Mark a seguir as regras é quem está, silenciosamente, ajudando a burlá-las — não por maldade, mas por estar encurralado.

**Escalada da conspiração (heist de precisão, não terrorismo — em escala de cidade média, contida):**
1. Pequenos golpes em caixas eletrônicos e furtos "aleatórios" (sementes no Ato 2) — na verdade testes de acesso, financiamento inicial e reconhecimento de resposta policial (Kessler estuda os tempos de reação da própria corporação de Mark).
2. Falhas "isoladas" de semáforo e câmeras de trânsito (Ato 2/3) — mapeamento silencioso da rede de infraestrutura que será usada na noite do grande golpe.
3. Na noite da consolidação bancária (Ato 4): sabotagem coordenada de trânsito, energia e comunicação pra isolar o Cais, atrasar reforços e criar caos visível pelas ruas (a dose grande de perseguições estilo *World's Scariest Police Chases*) — enquanto a operação real e silenciosa acontece no cofre, quase sem testemunhas.

---

## 6. Setting — A Cidade

**Nome provisório:** Bellmont *(cidade média americana fictícia — mantém a estética dos filmes/jogos de referência sem prender a um lugar real)*

Como o jogo é **missão-a-missão e não mundo aberto**, a cidade não precisa ser um mapa contínuo gigante — ela existe como uma coleção de **distritos pequenos e bem caracterizados**, cada um servindo um ato/tema específico. Isso também facilita produção (mapas menores, mais detalhados, reaproveitáveis em replays).

| Distrito | Ato principal | Personalidade |
|---|---|---|
| **Academia Regional de Bellmont** | Ato 1 | Complexo isolado nos arredores — estande de tiro, pista de direção defensiva, alojamentos. Contido por natureza, ótimo pra tutorial. |
| **Ironside** (bairro residencial/comercial modesto) | Ato 2 | O "chão de fábrica" da patrulha — ruas de casas, comércio local, um pouco decadente. Onde Mark aprende o ofício de verdade. |
| **Downtown Bellmont** (distrito financeiro/prefeitura) | Ato 3 | Torres de escritório, delegacia central, arquivo de evidências, bares de informante. Frio, vertical, institucional — reflete o isolamento do trabalho de detetive. |
| **Cais/Zona Industrial + Corredor Elevado + Prédio da Prefeitura** | Ato 4 | Onde o clímax acontece — poucos mapas, mas grandes e verticais/lineares, pensados pra perseguição e infiltração tática (a "torre Nakatomi" de Bellmont, se quisermos ser diretos sobre a referência). |

Essa estrutura por distritos também permite reaproveitar cenários entre atos com propósito narrativo — por exemplo, voltar a Ironside no Ato 4 e ver o bairro que Mark patrulhava agora em pânico, dá peso emocional sem precisar desenhar mapa novo.

---

## 7. Estilo Visual, Câmera, Engine e Plataforma

**Perspectiva:** topdown 2.5D, pixel art. Uma câmera só serve tanto as sequências táticas/investigativas (estilo *Police Stories*, *Intravenous 2*) quanto as perseguições e tiroteios (estilo *GTA 1/2*, *Retro City Rampage*) — sem precisar manter dois sistemas de câmera/renderização diferentes.

- **Câmera dinâmica por contexto:** fechada, mais lenta e estática nas sequências táticas/procedurais (abordagem, breach & clear, cena de crime); mais aberta e com leve atraso/zoom-out nas perseguições e tiroteios, pra vender velocidade e caos sem trocar de engine.
- **Veículos:** sprites com rotação suave (não sprites pré-renderizados em ângulos fixos como no GTA1 original) — fluido e viável em Godot com bem menos trabalho de arte do que 3D exigiria.
- **Feedback de impacto:** já que não há modelagem 3D de dano, a crueza do *World's Scariest Police Chases* vem de screen shake, sprites de dano por estágio, partículas, knockback de física 2D e giro forçado simulando PIT maneuver.
- **Referências diretas de execução/qualidade de produção:** *Intravenous 2: Mercenarism* (peso tático em topdown 2.5D) e *Of Guards and Thieves* (assimetria cops-vs-robbers em topdown).

**Engine:** Godot — o desenvolvedor já tem experiência prévia com a engine em outro projeto, o que reduz risco técnico e curva de aprendizado. Também é uma escolha sólida pra 2D/2.5D pixel art e pra build Android (leve, bom suporte a export mobile, sem custo de licença).

**Plataforma:** o jogo é **primariamente mobile (Android)**. Isso é uma restrição de design que atravessa tudo o que vier depois — em especial mecânicas e UI:

- **Controles em tela (touch)** precisam ser desenhados desde já como parte da mecânica, não adicionados depois: provavelmente joystick virtual + botões contextuais pra tiro/ação, ou um esquema ponto-e-toque (tap-to-move/tap-to-shoot) mais parecido com *Police Stories*/*Intravenous* nas partes táticas, e um esquema mais direto (joystick + acelerar) nas perseguições. Isso precisa ser decidido explicitamente na seção de mecânicas.
- **Sessões pensadas pra mobile** (jogadas mais curtas, pausáveis a qualquer momento) reforçam a decisão já tomada de **missões contidas e lineares** em vez de mundo aberto — combina muito bem.
- **Orçamento de performance e de assets enxuto** (pixel art 2.5D, mapas pequenos) é amigável com a variedade de hardware Android no mercado.
- Pontos a decidir mais adiante: orientação de tela (retrato vs. paisagem — paisagem tende a servir melhor tanto perseguição quanto tático), e se haverá versão PC/Steam como port futuro (não bloqueia decisões agora, mas vale manter os controles touch abstraídos de um input genérico pra não fechar a porta).

---

## 8. Mecânicas e Controles (Touch/Mobile)

**Revisado após 4 rodadas de teste em celular real.** Cada rodada corrigiu algo que só o toque de verdade revelou — resumo histórico rápido (não repetir os erros): rodada 1, manche direito escondido atrás de "só aparece com alvo perto" e botão único "ação" ambíguo; rodada 2, zonas de toque fixadas em pixel (não cobriam a borda real da tela) e direção da perseguição "horrível" com manche único direção+aceleração; rodada 3, testamos trocar o manche direito por uma zona de "olhar" estilo shooter mobile (arrastar livre, sem origem) — a direção da perseguição também passou a ser relativa à tela em vez de ao carro; rodada 4 (abaixo, versão atual), o usuário pediu o **manche direito de volta**: a referência a COD Mobile/PUBG Mobile/Free Fire era sobre a **disposição dos botões na tela**, não sobre copiar o comportamento de arrastar livre — revertido, mantendo tudo o mais que funcionou (botão de atirar sempre visível, tiro por raycast, portas por estado, direção da perseguição relativa à tela). As seções abaixo já refletem a versão corrigida.

**Decisão de base (mantida):** orientação **paisagem**. Manche esquerdo fixo por âncora (fração real da tela, não pixel) pra movimento/direção.

### Layout atual

| Input | Função |
|---|---|
| **Manche esquerdo** (polegar esquerdo) | Movimento do personagem. Na perseguição, indica **a direção pra onde o jogador quer que o carro vá na tela** (não mais "esquerda/direita do carro" — ver Modo Perseguição). |
| **Manche direito** (polegar direito, metade direita da tela) | Preso a uma origem, como o esquerdo — mira enquanto tocado. **Totalmente desacoplado do manche esquerdo**: soltar faz a mira **congelar** onde estava, não seguir a direção de movimento. (Testamos o oposto antes — mira acompanhando devagar a direção de movimento quando solta — e parecia bom isolado, mas em gameplay de verdade, numa sala com mais alvos e obstáculo, deixava tudo travado; revertido a pedido do usuário.) A disposição da tela (manche à direita, botão de ação no canto) segue a referência visual de COD Mobile/PUBG Mobile/Free Fire — só a disposição, não o comportamento de arrastar livre (testado e revertido antes, por outro motivo). |
| **Botão "Atirar"** | **Sempre visível, sempre disponível** (não depende mais de alcance ou de ter alvo específico). Atirar dispara um raio de verdade na direção que o personagem está olhando — pode acertar o alvo, uma parede (bloqueia o tiro) ou objetos do cenário (ver abaixo). |
| **Botões contextuais por objeto** | Cada objeto interativo mostra a ação que faz sentido pro **estado dele**, não sempre o mesmo botão: porta trancada → "Arrombar" (toque=rápido/barulhento, segurar=devagar/silencioso); porta destrancada → "Abrir" (simples, sem forçar). |
| **Perseguição: botões próprios** | **Acelerar**, **Frear** (freia; se já parado, dá ré) e **Freio de mão/PIT** — três botões dedicados no lado direito, como jogo de corrida mobile de verdade. |

### Modo Tático/Investigativo (DNA de *Police Stories* / *Intravenous 2*, disposição de tela estilo *COD Mobile/Free Fire*)
- Velocidade de movimento **capada e cautelosa** por padrão — empurrar o manche perto do máximo (limiar tolerante, não exige 100% cravado) por ~2s libera um sprint barulhento, com um anel visual mostrando o progresso do carregamento.
- **Espiar em quinas:** encostar o manche esquerdo de leve perto de uma esquina mostra o ícone de espiar; segurar revela a linha de visão sem expor o personagem.
- **Cobertura automática:** encostar numa parede/objeto entra em cobertura (muda o sprite, a câmera fecha mais, conforme já decidido na Seção 7).
- **Mira e tiro como sistema aberto, não "trava no inimigo":** o botão "Atirar" está sempre disponível; o que muda é o que o raio acerta. Isso abre espaço tático real — atirar numa lâmpada pra escurecer um cômodo, quebrar um objeto de propósito pra fazer barulho e distrair, ou simplesmente atirar no inimigo. A parede bloqueia o tiro (não atravessa), o que também ensina o jogador a usar cobertura de verdade.
- **Linha de mira em tempo real:** o raio de tiro é calculado a cada frame (não só ao apertar Atirar) e desenhado como uma linha até onde bateria — sem isso, testado no celular, a direção do tiro era difícil de entender só pela orientação do personagem. Verde quando ia acertar algo válido, branca quando não. Alvos já neutralizados são excluídos do cálculo do raio — sem isso, a mira "parava" num alvo abatido em vez de passar pro que estivesse atrás.
- **Portas com ações diferentes por estado:** uma porta trancada só oferece "Arrombar"; uma porta destrancada só oferece "Abrir" (instantâneo, sem escolha de rápido/devagar, porque não há nada pra forçar). O conjunto de botões nasce do estado do objeto, não é fixo.
- **Feedback em tempo real pra toque-vs-segurar:** o botão "Arrombar" preenche um anel enquanto é segurado, mudando de cor ao passar do limiar rápido→devagar — sem isso (só um texto de instrução), testado no celular, ficava confuso saber se o resultado ia ser rápido ou devagar antes de soltar o dedo.

### Modo Perseguição/Direção (DNA de *GTA 1/2*, *World's Scariest Police Chases*)
- **Direção relativa à tela, não ao carro:** o manche esquerdo aponta pra onde o jogador quer que o carro vá (como um manche de movimento normal), e o carro gira o nariz até lá numa taxa máxima limitada — não é giro instantâneo, continua "sendo um carro". Isso resolve a confusão relatada de esquerda/direita "virar de sentido" dependendo de como o carro já está orientado na tela (o antigo esquema era tipo volante, relativo ao próprio carro).
- Acelerar e frear continuam **botões dedicados**, sem mudança — já testaram bem nas rodadas anteriores.
- **Freio de mão/PIT**: segurar aperta a curva (derrapagem); encostado atrás de um alvo e segurando, tenta o **PIT maneuver** (giro forçado no carro-alvo, ecoando WSPC).
- **Atirar dirigindo** (Ato 4, mecânica de maestria): usa **mira automática** — quando um alvo entra num cone à frente do carro e dentro do alcance, a mira trava sozinha e um botão "Atirar" aparece. O jogador nunca aponta manualmente enquanto dirige (empilhar dirigir + mirar manual não funcionou nos testes).

### Risco e consequência no combate tático (decisões confirmadas com o usuário)
O usuário jogou o Ato 4 inteiro e deu o feedback: "tudo parece simples demais, pouca gameplay e ação". Diagnóstico: não é falta de missão, é que o combate tático (repetido em 10+ fases) nunca teve risco — inimigos ficam parados esperando o tiro, não reagem, não atiram de volta, o jogador é imortal. Decisões fechadas antes de prototipar:
- **Cobertura vira física real, não só indicador visual**: se uma parede estiver entre o inimigo e o jogador, o raio do inimigo bate nela e não chega — a mesma geometria que já bloqueia o tiro do jogador agora protege o jogador também.
- **Prototipado primeiro no sandbox** (`sandbox/tatico.gd`), não direto nas missões reais — é mudança de sistema compartilhado por 10+ fases já aprovadas, risco de regressão alto demais pra pular a validação.

**Revisão depois do 1º teste do piloto (retorno do usuário — substitui a 1ª versão, que tinha 4 de vida e "atordoado" ao zerar):**
- **Um tiro derruba.** "Não tem por que o jogador ter mais de uma vida." A exceção é o **colete**: com ele o jogador aguenta alguns tiros (`VEST_HITS`, hoje 2), sem ele cai no primeiro. Colete encaixa na regra "equipamento muda automaticamente por ato" (Seção 11) — cada missão decide se o Mark está de colete, sem loja.
- **Derrubado = a missão recomeça do início** (decisão do usuário, preferida a checkpoint antes do combate). Isso **reverte a decisão anterior de "consequência suave"**: com um tiro letal, ficar atordoado e voltar com vida não fazia sentido. Pra repetir o diálogo de abertura não ficar cansativo, **toda caixa de diálogo tem "Pular >>"**, que encerra a sequência inteira. Cuidado registrado: recomeçar recarrega a cena, então uma missão com combate **não pode** mexer em medidor do `GameState` antes do combate (contaria duas vezes) — nenhuma das atuais mexe.
- **Colete por ato, sem loja** (Seção 11): Academia sem combate de risco; Ato 2 (patrulha) colete leve, segura 1 tiro; Ato 4 (ação) colete tático, segura 2.
- **Onde já está aplicado:** Ato 4 Fases 1 (Infiltrar), 3 (Extração), 5 (Cofre, parte a pé) e 6 (Arquiteto), e Ato 2 Turno 6 (Incidente — o atirador já começa em combate, emboscada de verdade). A Academia (Ato 1) continua sem risco de propósito — é treino.
- **Visão em cone fixo** (~70°, não 360°) e alcance limitado. Percepção não é instantânea: um medidor de detecção enche mais rápido de perto e mais devagar de longe — dá tempo de recuar se for visto de relance.
- **Sem visão através de parede.** O guarda só acompanha o jogador enquanto tem linha de visão; perdeu, vai até a última posição conhecida e procura, depois volta pra patrulha. (Bug da 1ª versão: depois do primeiro alerta ele seguia mirando o jogador atrás de parede.)
- **Escuro reduz a visão** (alcance cai bastante com a luminária apagada) — paga o "atirar na lâmpada" que já existia desde o 3º teste de controles.
- **Som**: tiro, sprint, caixa quebrando, luminária e arrombar rápido fazem barulho com raio próprio; arrombar devagar é silencioso (paga a escolha rápido/devagar que já existia). Guarda que ouve vai investigar; parede abafa o som (raio cai pra 60%). Quebrar a caixa à distância serve de distração.
- **Aviso antes do tiro**: o guarda mostra a linha de mira por ~0,7s antes de atirar. Com tiro letal, isso é o que torna a morte justa — o jogador tem tempo de sair da linha ou voltar pra cobertura.
- **Mira mais solta e toque duplo pra atirar**: o giro da mira passou de taxa fixa (que deixava giro grande lento — "travado") pra suavização exponencial; tocar duas vezes no manche direito atira, além do botão ATIRAR. Por enquanto só ligado no sandbox (`double_tap_action` no manche), até ser aprovado.

Piloto aprovado no celular ("ficou muito bom") e espalhado pras missões de combate (ver "Onde já está aplicado" acima), usando os componentes compartilhados `actors/tactical_player.gd`, `actors/enemy_guard.gd` e `actors/combat_layer.gd`.

### Risco real nas perseguições
Mesmo diagnóstico do combate a pé: o carro inimigo só dava voltas, nunca escapava, nunca ameaçava, e o carro do jogador era indestrutível. Mesmas regras de consequência do combate (cair = recomeça a missão do início):
- **Lataria**: batida forte (pela velocidade relativa contra o que foi atingido) machuca o carro e corta a velocidade; raspão e encostar devagar não machucam. Uma batida de frente a toda velocidade tira ~25%. **Carro destruído = missão recomeça.**
- **O suspeito escapa**: longe demais (~380px) por tempo demais (~4s) e ele some — a missão recomeça. Uma barra "Fugindo" mostra o quanto falta. Substitui a perseguição infinita em círculo.
- **Inimigo que ameaça, só onde a história pede**: Ato 2 é um motorista em pânico — nada de tiro, o risco é lataria, obstáculos e fuga. No Ato 4 o carro do Ghost tem um **passageiro que atira** (com a mesma linha de mira visível antes do tiro dos guardas — dá pra quebrar a linha atrás de contêiner) e o Ghost dá **freada brusca** quando o jogador cola atrás. Na fuga do Cofre, dois reforços: um **tenta bater** (e recua depois de cada batida, pra não ficar grudado), outro **atira**.
- **Pistas com obstáculo**: quarteirão/pátio no meio (não dá pra cortar caminho), postes nas curvas, carros estacionados, barreiras em zigue-zague na fuga do Cofre.
- **Formas de encerrar** continuam as já definidas: PIT (Ato 2), bater até quebrar e atirar no pneu (Ato 4); na fuga, atirar pra trás ou fazer quem vem atrás bater.
- **Onde está aplicado:** Ato 2 Turno 4, Ato 4 Fases 2 e 5 (fuga). A Direção Defensiva da Academia (Ato 1 Fase 3) fica sem risco — é treino.
- Componentes: `actors/player_car.gd`, `actors/enemy_car.gd`, `actors/chase_layer.gd`; o `sandbox/perseguicao.gd` é a referência viva com tudo ligado.

### Pendência: layout de controles configurável
Ideia do usuário, ainda não implementada no protótipo (é um sistema à parte — editor de posição + salvar preferência — e não faz sentido misturar com validar o "feel" das mecânicas, que é o objetivo do protótipo atual): no jogo final, o jogador deve poder **reposicionar manches e botões onde achar melhor**, com uma disposição padrão definida por nós (a da Seção 8 acima) já pronta de fábrica. Fica pra quando o projeto sair da fase de sandbox pra UI de configurações de verdade.

### Pendência confirmada: sistema de munição e pegar arma de suspeito
Confirmado pelo usuário durante a produção da Ato 1 Fase 1: o jogo vai ter um **sistema de munição**, e quando a arma do jogador ficar sem balas, ele deve poder **pegar a arma de um suspeito** (presumivelmente rendido/neutralizado) pra continuar o combate. A mecânica de "pegar arma na bancada" da Fase 1 (zona de interação + botão contextual "Pegar" + estado "tem arma") já foi desenhada de propósito genérica o bastante pra virar a base desse sistema depois — não é uma mecânica isolada só daquela cena. Ainda não implementado: contagem de munição de verdade, nem a interação de pegar arma de um suspeito específico.

### Múltiplas formas de encerrar perseguição (Ato 2+) — resolvido no Ato 4
Sugerido pelo usuário ao testar o PIT de treino da Ato 1 Fase 3: perseguições de verdade (fora do exercício de treino, que é só sobre aprender o PIT básico) deveriam poder terminar de mais de um jeito, não só PIT. Implementado na Fase 2 do Ato 4 ("A Perseguição", contra o Ghost):
- **Atirar no pneu** — ✅ implementado: mira automática por cone à frente do carro (mesma mecânica de "atirar dirigindo" da Seção 8), acerta quando alinhado e dentro do alcance.
- **Bater até o carro quebrar** — ✅ implementado: dano acumulado por colisão real (`get_slide_collision`), com cooldown entre batidas pra não contar a mesma como várias.
- **Perseguir até o suspeito desistir** — ainda não implementado (precisaria de um estado de "moral"/rendição na IA do carro perseguido); não foi necessário pro Ghost, que é um adversário de verdade, não um fugitivo assustado.
- **Fechar o carro** (bloquear a rota) — ainda não implementado; fica como variedade extra pra uma eventual perseguição futura, não bloqueante pro Ato 4 atual.

O PIT clássico (Ato 1 Fase 3, Ato 2 Turno 4) continua existindo nas fases que o ensinam — a Fase 2 do Ato 4 deliberadamente não repete PIT, pra reforçar que agora o jogador tem mais de uma ferramenta.

### Modo Diálogo / Quadro de Evidências
- Sem manches: tela cheia de toque direto (tocar opções de diálogo, tocar e conectar pistas no quadro). O contraste de interface (de twin-stick pra toque direto) reforça o contraste de ritmo entre ação e investigação, em vez de precisar de uma transição de câmera cara de produzir.

### Interrogatório (leitura de deixas) — piloto no sandbox
Resposta ao Ato 3 ser a parte mais rasa do jogo depois que combate e perseguição ganharam risco real. Componente `ui/interrogation.gd` (movido a dados), piloto em `sandbox/interrogatorio.gd`.
- **Rodadas**: o suspeito fala e deixa escapar uma **deixa** (linguagem corporal); o jogador escolhe **PRESSIONAR**, **APOIAR** ou **MOSTRAR PROVA** (abre a lista de provas que o Mark tem, com prova falsa no meio).
- **A deixa segue uma regra fixa, pra ser leitura e não chute:**
  - **Nervoso** (mexe nas mãos, fala rápido, sua) → mentindo sob pressão → **pressionar** quebra.
  - **Assustado** (encolhe, olha pra porta, voz baixa) → com medo, não mentindo → **apoiar** faz falar; pressionar fecha.
  - **Calmo demais** (sorri, resposta ensaiada) → mentira preparada → só a **prova certa** quebra.
- **Errar gasta paciência**; sem paciência o suspeito se fecha. **Sem fail state**: a história segue com o que foi conseguido até ali — diferente do combate, aqui recomeçar não faz sentido (investigação, não reflexo).
- **Regra de ouro (Seção 9):** cada informação revelada precisa valer algo depois. **Plano de aplicação, a confirmar depois do teste do sandbox:**
  - **Ato 3 Fase 2 (Lou/Miko)**: interrogar o informante escolhido. Informação completa → uma pista a mais no Quadro (Fase 4) e a rotina do vigia na Vigilância (Fase 3). Se ele se fechar → avisa o grupo, e o vigia da Fase 3 fica mais atento.
  - **Ato 3 Fase 6 (Doyle)**: o confronto vira interrogatório antes da escolha de 3 vias. A paciência do Doyle vem da relação construída no Ato 2 (`doyle_relationship`). Ler certo → ele admite a dívida que o encurralou (motivação do ROTEIRO), mudando o tom da escolha e uma fala do Epílogo.

### Mecânicas introduzidas por Ato

| Ato | Mecânicas novas | Controles envolvidos |
|---|---|---|
| **1 — Academia** | Mira e tiro (estande), abordagem tática básica (arrombar, espiar), direção defensiva num circuito seguro — tudo em doses curtas e supervisionadas | Manche direito + botão Atirar (mira), botão contextual (arrombar), manche esquerdo (direção, sem risco) |
| **2 — Patrulha** | Abordagens com diálogo (afeta medidor de reputação), perseguições curtas a pé e de carro, PIT maneuver, comando simples pro parceiro/FTO | Modo diálogo, modo perseguição completo, botão contextual pequeno (comando) |
| **3 — Detetive** | Quadro de evidências (minigame de conectar pistas), exame de cena de crime (interagir com objetos destacados), interrogatório (diálogo com leitura de "deixas"), vigilância furtiva (cobertura + espiar, sem combate) | Modo diálogo/quadro, modo tático em ritmo mais lento e sem tiro |
| **4 — Ação** | Fusão total: atirar dirigindo, breach & clear com múltiplos inimigos e cobertura, perseguições com o "wheelman" rival, prompts contextuais rápidos (segurar/arrastar) em momentos de cinemática de improviso | Todos os modos combinados — o pagamento de tudo que foi ensinado isoladamente nos atos anteriores |

### Nota técnica (Godot)
- `ui/virtual_joystick.gd`: manche preso a uma origem — usado pro movimento/direção **e** pra mira (`right_stick = true`). `ui/contextual_button.gd`: botão com distinção toque-rápido/segurar. Ambos `Control`-based, feitos à mão (não `TouchScreenButton`), posicionados por **âncora** (fração real da tela) em vez de pixel fixo — importante: pixel fixo não cobre a borda real em celulares com proporção diferente da assumida. (Existiu um `ui/look_zone.gd` de arrastar livre na rodada 3, removido na rodada 4 a pedido do usuário — não recriar sem pedido explícito.)
- Movimento de personagem via `CharacterBody2D`; carros via `CharacterBody2D` com física arcade simplificada (sem `RigidBody2D` completo) — mais previsível e fácil de ajustar "feel" num projeto solo.
- Tiro é um **raycast de física de verdade** (`PhysicsRayQueryParameters2D` + `intersect_ray`, com `collide_with_areas` e `collide_with_bodies` ligados, excluindo o próprio jogador) — não um cone/dot-product contra um alvo fixo. Isso é o que permite acertar cenário (parede bloqueia, objetos interativos reagem) em vez de só um inimigo pré-definido.
- **Reivindicação de toque compartilhada** (`InputBridge.try_claim_touch(index)`/`release_touch(index)`): zonas de toque que se sobrepõem (ex.: manche direito perto do botão Atirar, que agora é sempre visível) podiam ser processadas por dois controles ao mesmo tempo, interrompendo o arraste do manche — sentido no teste como "mira menos suave" e "às vezes não aparece". Cada dedo agora só pode pertencer a um controle por vez.
- **Ordem de registro na árvore decide quem ganha a disputa por um toque sobreposto: no Godot, quem é adicionado por último recebe o evento primeiro** (o oposto do que se assumiria por padrão). O manche direito cobre a metade direita inteira da tela (sem faixa reservada — isso criava área morta quando os botões estavam invisíveis, a maior parte do tempo); os botões são adicionados **depois** do manche, então ganham a disputa e respondem normalmente quando estão visíveis.
- Input abstraído por **nome de ação livre** (`autoload/input_bridge.gd`: `move_vector`, `aim_touching` + `add_aim_delta`/`consume_aim_delta` pro giro de mira, e `press("breach")`/`press("shoot")`/`press("accelerate")` etc. por nome) em vez do par fixo `action_primary`/`action_secondary` do desenho original. Continua abstraído da UI de toque, então um port PC/gamepad no futuro não exige redesenhar a lógica de jogo (pendência da Seção 7).

---

## 9. Estrutura de Missões e Progressão

**Princípio geral:** campanha **enxuta e linear na espinha dorsal**, sem hub explorável. Navegação entre missões via uma tela de seleção simples (mural de casos/prancheta — combina com a estética de delegacia e com sessões curtas de mobile), não um mundo pra atravessar andando. Isso também evita o maior risco de "campanha arrastada": preencher espaço com deslocamento sem propósito.

**Regra de ouro para conteúdo secundário:** nenhum conteúdo opcional entra só pra ter mais coisa pra fazer. Todo side-content precisa cumprir **pelo menos um** destes critérios, ou é cortado do escopo:
1. Move um medidor rastreado (reputação, relação com a família) que muda diálogo ou o epílogo.
2. Planta um retorno concreto mais tarde na história (uma testemunha, um favor, uma vantagem tática no Ato 4).
3. Aprofunda um personagem que **já é central** — nunca um NPC descartável só pra ter side quest.

**Escopo alvo:** 24 missões principais (4 + 6 + 8 + 6, ver tabela abaixo) + um punhado de vinhetas opcionais curtas (não dezenas) — campanha de aprox. 5–6 horas. Suficiente pra sustentar o arco dos 4 atos sem esticar.

| Ato | Moldura | Missões principais | Conteúdo opcional (com a regra de ouro aplicada) |
|---|---|---|---|
| **1 — Academia** | "Dias de instrução" | 4 missões curtas e 100% lineares (tiro, abordagem, direção defensiva, avaliação final) | Nenhum — o ato já é curto e focado por natureza, não precisa de padding |
| **2 — Novato nas Ruas** | "Turnos" | 6 turnos, cada um com 1 chamado obrigatório que avança a trama/personagem | Até 2 chamados de rádio opcionais por turno (2–3 min cada): cada um afeta o medidor de reputação **e** planta uma testemunha/favor que retorna no Ato 3 ou 4. Cenas curtas e opcionais com o FTO fora do turno alimentam o medidor de relação (paga no twist do Ato 3). |
| **3 — Emblema de Detetive** | "O Caso" em 3 movimentos internos (Pistas → Padrão → Confronto) | 8 missões (cena de crime, interrogatório, vigilância, confronto com Doyle, presença pessoal do Kessler, ameaça à família) | Em vez de leads paralelos genéricos: **escolha de qual informante/testemunha pressionar** — rotas alternativas pro mesmo objetivo, não trabalho extra. Vinhetas domésticas opcionais (jantar em casa vs. ficar até tarde no caso) alimentam o medidor de família, que muda o tom do Ato 4 e do epílogo. |
| **4 — A Cidade em Chamas** | "A Noite" (uma noite contínua) | 6 missões grandes: infiltrar o Cais, perseguir o wheelman Ghost, extrair Sarah e Emma em segurança, restabelecer o controle da infraestrutura sabotada (usando a dica de Emma no scanner — Seção 10), arrombar o cofre, confronto final com Kessler | Desvios opcionais de resgate a NPCs estabelecidos antes (o comerciante de Ironside, a testemunha do Ato 3) — só existem porque o mundo foi construído antes; recompensam quem jogou o conteúdo opcional anterior em vez de ser aleatório. |

**Por que sem hub:** um hub andável (voltar à delegacia, escolher onde ir) soa natural pra um jogo assim, mas — dado que já decidimos mundo contido, sessões mobile curtas e um time solo — ele só adicionaria tempo de deslocamento sem conteúdo novo. A tela de seleção de caso entrega a mesma sensação de "escolher o próximo capítulo" sem o custo de produção nem o risco de arrastar o ritmo.

**Ramificação:** a espinha principal continua linear (sem múltiplos finais bifurcados, fora do escopo pra um projeto solo) — a variação vem do **conteúdo e tom**, não da estrutura: quem negligenciou a família ou queimou pontes no Ato 2 sente isso em diálogos e no epílogo do Ato 4, mas percorre a mesma sequência de missões que todo mundo. Mantém a promessa de "as coisas têm peso" sem o custo de produção de narrativa ramificada de verdade.

---

## 10. Elenco de Apoio

Escopo deliberadamente enxuto — cada personagem existe porque já tem uma função mecânica ou narrativa amarrada em seções anteriores, não porque "todo cop drama tem um". Nomes provisórios, fáceis de trocar.

### Capitã Diane Okafor — a constante institucional
- **Papel:** instrutora dura-mas-justa na Academia (Ato 1) — e, por economia de elenco, é também quem mais tarde comanda a delegacia e promove Mark a detetive (Ato 2→3). Reaparece no Ato 4 como a autoridade que *quer* ajudar mas tem as mãos atadas pela burocracia/pela crise, forçando Mark a agir sozinho sem precisar de uma versão barata do "capitão que não acredita em você".
- **Função de jogo:** dá o tom de cada tutorial no Ato 1 (avaliação de desempenho) e é quem formaliza a transferência de Mark pra Investigações no fim do Ato 2 — a mesma cara acompanha o jogador do primeiro ao último ato, reforçando continuidade com pouco elenco.

### Sgt. Ray Doyle — o FTO / parceiro de patrulha
- **Papel:** parceiro de Mark no Ato 2. Cínico, engraçado, ensina os atalhos do ofício (Seção 4). O **medidor de relação** opcional da Seção 9 é com ele.
- **O twist:** Doyle é a "ponte com a Academia" da Seção 5 — o vínculo antigo com Kessler que o leva a vazar informação operacional, não por maldade, por estar encurralado (dívida/ameaça à família).
- **O incidente que fecha o Ato 2:** Doyle é ferido em serviço — na hora, parece um acidente de trabalho comum e é o que empurra Mark pra Investigações. Só no Ato 3 o jogador descobre que o "acidente" tem relação direta com a operação de Kessler já em andamento — recontextualiza a cena retroativamente, o tipo de peso que vale mais que um NPC novo.
- **Pagamento do medidor de relação:** quanto mais o jogador investiu na relação no Ato 2, mais pesada é a cena de confronto/decisão sobre Doyle no Ato 3 (entregá-lo, dar uma saída, confrontá-lo pessoalmente antes da corregedoria) — afeta diálogo e o epílogo, sem ramificar a missão em si (consistente com a Seção 9).

### Oficial Theo Marsh — o rival que vira parceiro
- **Papel no Ato 1:** colega de turma ambicioso e "engomadinho", puxa atrito com o idealismo desajeitado de Mark — fricção leve, não vilania.
- **Papel no Ato 4:** com Doyle fora de ação (ferido, depois exposto), é Theo quem assume o posto de parceiro nas missões de ação do Ato 4 — um parceiro novo, mais alinhado ao "manual", que espelha quem Mark era no Ato 1. Substitui a necessidade de criar um personagem novo pro clímax e fecha o arco de Mark aprendendo a confiar de novo depois da traição de Doyle.

### Sarah Reyes — a família (cônjuge)
- **Papel:** enfermeira ou professora — profissão prática, deliberadamente não-policial, pra contrastar com o mundo de Mark. Ancora as cenas domésticas do Ato 3 (Seção 9).
- **Função de jogo:** o **medidor de família** opcional (jantar em casa vs. ficar no caso) muda o tom das cenas com ela no Ato 4 — não o resultado da missão, mas o peso emocional do resgate/reconciliação no clímax.

### Emma Reyes — a filha (pré-adolescente)
- **Detalhe de caracterização com pagamento mecânico:** hobby de rádio amador/escuta de scanner policial — parece só um traço de personalidade, mas é a plantação de um pequeno momento de agência dela no Ato 4 (ela capta algo no scanner relevante pra Mark), em vez de ficar passiva como "a criança em perigo" genérica.

### O informante de Ironside (a escolha do Ato 3)
- **Lou** (dono de bar, contatos de rua) e **Miko** (ex-associado técnico de Kessler, contatos do lado hacker) são as duas rotas alternativas mencionadas na Seção 9 pra pressionar em busca da mesma pista — dão sabor de escolha sem duplicar trabalho de missão.

### Wade "Ghost" Calloway — o wheelman de Kessler
- **Papel:** o motorista de fuga da operação (Seção 5) — em vez de ficar anônimo, é um rival recorrente de perseguição: aparece sem nome/rosto revelado numa fuga do Ato 2 (planta a rivalidade cedo), reaparece como pista no Ato 3, e é o antagonista direto das grandes perseguições do Ato 4. Dá uma identidade fixa pro "momento de perseguição" que se repete a cada ato, em vez de perseguições desconectadas.
- O resto da equipe de Kessler (infiltradora/hacker, músculo de apoio) permanece funcional e sem nome de peso — não precisam de arco, só de papel claro em missão, mantendo o elenco enxuto.

---

## 11. Progressão e Economia

**Decisão central: sem XP, sem loja, sem grind.** Um sistema tradicional de pontos-de-experiência/moeda/upgrade contradiria o próprio Pilar 1 (Seção 3: "a progressão de mecânicas é o arco do personagem, não power creep"). Se o jogador pudesse comprar/grindar pra ficar mais forte, o ritmo deixaria de contar a carreira do Mark e passaria a contar o quanto o jogador farmou — exatamente o tipo de sistema genérico que você não quer.

**O que substitui isso:**

1. **Desbloqueio de mecânica 100% narrativo** — já definido na tabela da Seção 8. O jogador não "sobe de nível", ele aprende uma técnica nova porque a história chegou naquele ponto (estande de tiro no Ato 1, PIT maneuver no Ato 2, atirar dirigindo só no Ato 4). Isso já *é* o sistema de progressão do jogo — não falta nada em cima.

2. **Equipamento muda automaticamente por ato/posto, sem menu de compra:**

| Ato | Equipamento | Motivo diegético |
|---|---|---|
| 1 — Academia | Pistola de treino, sem colete | Recruta, ambiente controlado |
| 2 — Patrulha | Pistola de serviço, cassetete/taser, colete básico | Farda padrão de policial novato |
| 3 — Detetive | Arma à paisana, kit de coleta de evidência, sem farda | Investigação, discrição |
| 4 — Ação | Colete tático, arma emprestada/de operação (ex: carabina), acesso a equipamento requisitado pra crise | A noite exige mais do que o padrão — pedido/emprestado, não comprado |

No combate com risco real (Seção 8), o colete tem efeito mecânico: o básico do Ato 2 segura 1 tiro, o tático do Ato 4 segura 2; sem colete, um tiro derruba.

Isso entrega a sensação mobile de "ficar mais equipado com o tempo" sem abrir a porta pra uma loja ou pra grind — é *fixo* por ato, todo jogador tem o mesmo em cada ponto da história.

3. **Os medidores já existentes (Reputação, Relação com Doyle, Relação com a família — Seção 9/10) são a "economia" real do jogo.** Em vez de moeda que compra poder, são um **capital narrativo**: o que o jogador "gasta" tempo/escolhas construindo paga em diálogo, em quem aparece pra ajudar no Ato 4, e no tom do epílogo — nunca em dano extra ou vida extra. Reforça a Seção 9 em vez de competir com ela.

**Opcional, escopo baixo, não-bloqueante:** cosméticos puramente visuais (variação de farda, skin de viatura) desbloqueados por completar conteúdo opcional — dá aquele gostinho de "coleção" que jogadores de mobile esperam, sem nenhum efeito mecânico e sem exigir sistema de loja. Fica como "nice-to-have" pra depois do core do jogo estar pronto, não como requisito.

**Modelo de monetização: pago único (premium).** Sem anúncios, sem IAP, sem loot/gacha — coerente com o resto desta seção: não existe nada pra vender incrementalmente, já que não há moeda nem power creep no design. O jogador compra o jogo uma vez e tem acesso à campanha inteira.

---

## Próximos passos sugeridos
- [x] Perfil detalhado do protagonista
- [x] Antagonista(s) e a conspiração central
- [x] Setting (cidade fictícia, por distritos)
- [x] Estilo visual, câmera, engine e plataforma
- [x] Mecânicas e controles touch por ato
- [x] Estrutura de missões e progressão
- [x] Elenco de apoio, com nomes e papéis definidos
- [x] Sistemas de progressão/economia
- [x] Modelo de monetização (pago único/premium)
- [x] Primeiro protótipo/slice jogável — sandbox de controles (tático + perseguição), validado no celular em 8 rodadas de teste real ("fechou é isso!"). Ver `CLAUDE.md` pro histórico completo das correções.
- [x] Primeira missão de conteúdo real — Ato 1, Fase 1 "Chegada" (`missions/ato1_fase1_chegada.gd`): câmera seguindo o Mark, ele se apresenta à Okafor, Theo participa (fala + atira 2 dos 4 alvos), Okafor guia visualmente até o estande, motivo pessoal do Mark. Ainda não testada no celular. Estabelece o padrão de câmera + NPC de apoio pras próximas fases.
- [x] Preparo pra tradução futura (`tr()` nas falas/HUD de conteúdo real) e `CHANGELOG.md` pra acompanhar mudanças.
- [x] Ato 1, Fase 2 — Abordagem Tática (`missions/ato1_fase2_abordagem.gd`): casa de treinamento com ameaças e civis/reféns misturados (discriminar antes de atirar, não só acertar), Okafor/Theo observam de fora e avaliam. Ainda não testada no celular. 3º arquivo com a mesma lógica de jogador tático (movimento/mira/cobertura/tiro) — bateu a "regra dos três"; se uma 4ª missão tática precisar do mesmo, vale extrair um componente compartilhado em vez de copiar de novo.
- [x] Ato 1, Fase 3 — Direção Defensiva (`missions/ato1_fase3_direcao.gd`): circuito fechado sem risco, 3 checkpoints + PIT de prática. Contraste narrativo pago: o Theo, que provocava o Mark por cuidadoso nas Fases 1/2, quase bate de pressa aqui, e a Okafor valoriza a direção controlada do Mark pela primeira vez sem ressalva. Ainda não testada no celular. Ato 1 (Academia) agora tem 3 das 4 fases construídas — falta só a Avaliação Final/Formatura.
- [x] Ato 1, Fase 4 — Avaliação Final / Formatura (`missions/ato1_fase4_formatura.gd`): fecha o Ato 1. Escopo deliberadamente narrativo — sem repetir tiro/abordagem/direção (já testados nas Fases 1/2/3 com peso próprio; sem save entre cenas pra referenciar desempenho específico, repetir seria conteúdo genérico). Cerimônia de formatura: avaliação da Okafor, respeito mútuo com o Theo, lotação do Mark pra Ironside sob o Sgt. Ray Doyle — fecha o gancho pro Ato 2. **Ato 1 (Academia) completo: as 4 fases do ROTEIRO estão construídas.** Ainda não testada no celular.
- [x] Prototipar o Quadro de Evidências (Ato 3) — `ui/evidence_board.gd` (novo): minigame de conectar pares de pista tocando dois de cada vez, usado na Fase 4. Modo Diálogo com ramificação de conversa de verdade **continua pendente** — as fases seguem usando a caixa de texto linear (`ui/story_box.gd`) e a escolha simples (`ui/choice_prompt.gd`, agora suportando até 3 opções) pra decisão com peso, sem ramificar a estrutura de missão.
- [x] Prototipar a fusão tático+perseguição (atirar dirigindo, Ato 4) — resolvido na Fase 2 (mira automática por cone pra atirar no pneu do Ghost) e na Fase 5 (trecho de fuga atirando pra trás depois do breach & clear do Cofre). Junto, resolveu também a pendência de "múltiplas formas de encerrar perseguição" (atirar no pneu + bater até acumular dano, além do PIT já validado).
- [x] **Ato 2 (Novato nas Ruas) completo — os 6 turnos** (`missions/ato2_turno1_a_dupla.gd` a `ato2_turno6_incidente.gd`), construídos de uma vez a pedido do usuário (feedback vem depois, turno por turno — ainda não testados no celular). Novo: `autoload/game_state.gd` (medidores atravessando cenas, necessário porque reputação/relação com Doyle se acumulam ao longo de vários turnos) e `ui/choice_prompt.gd` (escolha binária simples, alimenta os medidores — não é o Modo Diálogo completo). **Ato 2 fecha com a transferência de Mark pra Investigações — gancho pro Ato 3.**
- [x] **Ato 3 (Emblema de Detetive) completo — as 8 fases** (`missions/ato3_fase1_cena_revisitada.gd` a `ato3_fase8_descoberto.gd`), construídas de uma vez a pedido do usuário (feedback vem depois, fase por fase — ainda não testadas no celular). `autoload/game_state.gd` expandido com `family_meter`, `informant_chosen`, `doyle_fate`, `ghost_named`. **Ato 3 fecha com a invasão de casa (Fase 8 "Descoberto") — Kessler ainda sem nome revelado, mas a família de Mark já é alvo direto — gancho pro Ato 4.**
- [x] **Ato 4 (A Cidade em Chamas) completo — as 6 fases + Epílogo** (`missions/ato4_fase1_infiltrar.gd` a `ato4_epilogo.gd`), construídas de uma vez a pedido do usuário (feedback vem depois, fase por fase — ainda não testadas no celular). Resolve as duas últimas pendências grandes de mecânica da Seção 8 (fusão tático+perseguição e múltiplas formas de encerrar perseguição, ver acima). **Campanha completa: 24 missões principais + epílogo, Ato 1 ao Ato 4, conforme a Seção 9.**
- [x] **Navegação automática entre fases** (`autoload/mission_flow.gd`, novo autoload) — pedido explícito do usuário depois de sentir o atrito de voltar pro menu entre toda fase do Ato 2/3. Define a ordem canônica das 25 cenas da campanha; cada missão mostra "Próxima Fase >" ao concluir. Aplicado em toda a campanha (Atos 1–4), não só no Ato 4.
