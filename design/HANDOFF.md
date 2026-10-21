# Handoff de design: Fala que eu transcrevo!

Implemente a interface **exatamente** como descrito aqui, em **Flutter desktop** (Windows, macOS, Linux). App de transcrição de vídeo usando `ffmpeg` + `whisper-cli`, 100% local.

## Como usar este handoff

1. **Leia primeiro `referencia.html`** (na mesma pasta). É a referência visual das 4 telas, em HTML/CSS puro: abra no navegador para ver, e leia o CSS para os valores exatos. Os tokens estão em `:root`; cada componente tem uma classe com nome claro (`.dropzone`, `.model`, `.tabs`, `.progress-card`…). Cada tela está numa moldura de 1120 × 780, o tamanho padrão da janela.
2. Use este documento para comportamento, estados e textos, e a seção **Mapeamento para Flutter** para traduzir HTML/CSS em widgets.
3. Para conferir: rode o app em 1120 × 780, tire um print de cada tela e compare com o print da tela correspondente em `referencia.html`. Ajuste até bater.

Os valores em `px` deste documento e do HTML equivalem a **pixels lógicos** no Flutter (1px = 1.0).

## Regras gerais

- Não altere layout, cores, tamanhos, textos ou espaçamentos sem motivo técnico. Se algo for impossível, anote e siga o mais perto possível.
- Toda a interface é em **português (Brasil)**. `locale: Locale('pt', 'BR')`.
- Tema único: **escuro**.
- Acessibilidade: botões só de ícone levam `tooltip` + `Semantics(label: …)`; ícones decorativos ficam fora da árvore de semântica (`ExcludeSemantics`). Onde o HTML usa `aria-pressed`/`aria-selected`, use `Semantics(selected: …)`.
- Alvos de clique com no mínimo **44px** de altura.
- Layout fluido: a janela pode ser redimensionada. As colunas quebram para uma embaixo da outra em larguras pequenas (detalhes por tela). Tamanho de janela sugerido: **1120 × 780**, mínimo **720 × 600**.
- Sem emoji. Ícones são SVG inline com traço (`stroke`), `fill="none"`, `stroke-linecap="round"`, `stroke-linejoin="round"`, viewBox `0 0 24 24`.

## Tokens

### Cores

| Token | Valor | Uso |
|---|---|---|
| `--bg` | `#2F243A` | Fundo da janela |
| `--surface` | `#3A3047` | Cartões, inputs, botões secundários |
| `--surface-sunken` | `#281E32` | Dropzone, painel de transcrição |
| `--surface-raised` | `#444054` | Botão "Copiar" do comando |
| `--surface-code` | `#241B2D` | Fundo da linha de comando |
| `--surface-hover-row` | `#3F354C` | Trecho destacado na transcrição |
| `--icon-tile` | `#444054` | Quadrado do ícone na checklist |
| `--track` | `#4A4259` | Trilho da barra de progresso, miniatura de vídeo |
| `--border` | `#4A4259` | Borda padrão |
| `--border-subtle` | `#3F354C` | Divisores internos de cartões |
| `--border-header` | `#3A3047` | Linha abaixo do header e acima do footer |
| `--border-strong` | `#5A5468` | Borda tracejada do dropzone, círculo de etapa pendente |
| `--border-button` | `#565068` | Borda do botão "Copiar" |
| `--text` | `#F6EEEA` | Texto principal |
| `--text-body` | `#E9E2E0` | Texto da transcrição final |
| `--text-strong-muted` | `#D6D2D2` | Rótulos, ícones de botões |
| `--text-muted` | `#BEBBBB` | Texto secundário |
| `--text-faint` | `#A9A3AC` | Dicas, timestamps |
| `--accent` | `#DB8A74` | Cor principal (salmon) |
| `--on-accent` | `#2F243A` | Texto/ícone sobre o accent |
| `--accent-text` | `#FAC9B8` | Links |
| `--accent-text-hover` | `#FFE3D8` | Link em hover |
| `--accent-soft-text` | `#FAC9B8` | Selos, timestamps do resultado, rótulos "Ideal" |
| `--accent-selected-bg` | `#47343F` | Fundo do cartão de modelo selecionado |
| `--accent-ring` | `rgba(219,138,116,0.22)` | Anel externo do cartão selecionado (`box-shadow: 0 0 0 4px`) |
| `--accent-card-bg` | `#3D2C3E` | Cartão "Pronto!" |
| `--accent-card-border` | `#5E4049` | Borda do cartão "Pronto!" |
| `--accent-chip-bg` | `#4A3342` | Fundo do selo de extensão (TXT/SRT/VTT) |
| `--success` | `#7FD69A` | Ponto de status OK |
| `--success-text` | `#A7E3B5` | Texto/ícone de sucesso |
| `--success-bg` | `#2E3A3B` | Fundo de selo/ícone de sucesso |
| `--warning` | `#EBC062` | Ponto de status pendente |
| `--warning-text` | `#F5D58A` | Texto de aviso |
| `--warning-bg` | `#45383A` | Fundo de selo de aviso |
| `--wave-idle` | `#5A5468` | Barras da onda fora do destaque |
| `--meter-off` | `#565068` | Pontinho de medidor apagado |
| `--meter-speed-on` | `#D6D2D2` | Pontinho aceso de "Rapidez" |

Paleta base da marca: Midnight Violet `#2F243A` (fundo), Vintage Grape `#444054` (superfícies elevadas), Silver `#BEBBBB` (texto secundário), Almond Silk `#FAC9B8` (destaques claros, links), Salmon `#DB8A74` (accent). Os demais tokens são tons intermediários derivados dela para dar profundidade e manter o contraste. Mantenha o accent como variável.

### Tipografia

Embuta as fontes no app como assets em `pubspec.yaml` (não use `google_fonts` baixando em runtime, o app é offline). Todas são OFL; inclua as licenças. Bricolage Grotesque tem eixo óptico (`opsz`): use a variante estática de 96pt para títulos ≥ 26px e a de 12pt para o resto, ou a fonte variável com `FontVariation('opsz', …)`.

| Papel | Família | Pesos |
|---|---|---|
| Display (títulos, nome do app, números grandes) | **Bricolage Grotesque** | 500, 700, 800 |
| Interface e corpo | **Inter** | 400, 500, 600, 700 |
| Mono (comandos, horários, tamanhos, extensões) | **JetBrains Mono** | 500 |

Fallbacks: `system-ui, sans-serif` e `monospace`.

Escala usada:

| Uso | Família | Tamanho / peso / extra |
|---|---|---|
| Nome do app no header | Bricolage | 19px / 800 / letter-spacing −0.01em |
| Subtítulo do header | Inter | 12.5px / 400 / `--text-muted` |
| Título do dropzone | Bricolage | 30px / 700 / −0.02em |
| H1 da tela de setup | Bricolage | 34px / 800 / line-height 1.1 / −0.02em |
| Porcentagem do progresso | Bricolage | 56px / 800 / line-height 1 / −0.03em (o `%` em 28px, `--text-muted`) |
| Título "Pronto!" | Bricolage | 26px / 800 / line-height 1.15 / −0.02em |
| Nome do modelo no cartão | Bricolage | 16px / 700 |
| Rótulo de seção | Inter | 13px / 600 / `--text-strong-muted` / letter-spacing 0.02em |
| Eyebrow ("Primeira vez por aqui") | Inter | 12.5px / 600 / uppercase / 0.08em / `--accent-soft-text` |
| Corpo | Inter | 14–15.5px / 400 |
| Texto de transcrição | Inter | 15.5px / line-height 1.6 (ao vivo) e 1.65 (resultado) |
| Botão primário | Inter | 15–15.5px / 700 |
| Dicas | Inter | 12.5–13px / `--text-faint` |
| Mono | JetBrains | 11.5–15px / 500 |

### Raios

`6px` chips de formato · `7px` selo de extensão · `9px` aba de SO e botão Copiar · `10px` tile de ícone e miniatura · `11px` logo · `12px` botões de header, linha de comando, busca, trecho · `14px` select, cartões de modelo, botões primários, botões de exportar · `16px` cartão do arquivo · `18px` cartões grandes e painéis · `22px` dropzone · `999px` pills e barras de progresso.

### Espaçamento

Header: `padding: 18px 32px`, borda inferior `1px solid --border-header`.
Conteúdo (`main`): centralizado, `padding: 28px 32px 32px` (setup: `36px 32px 40px`), `box-sizing: border-box`.
Largura máxima do `main`: Início **1040px**, Setup **760px**, Transcrevendo **1080px**, Resultado **1120px**.

## Componentes compartilhados

### Header (todas as telas)

`flex`, `flex-wrap: wrap`, `align-items: center`, `justify-content: space-between`, `gap: 16px`.

Esquerda (gap 12px):
- **Logo** ("Onda que se acalma"): o ícone do app em 38×38. Use `logo/icon.svg` (via `flutter_svg`) ou desenhe com este SVG, viewBox 64×64:
  ```svg
  <rect width="64" height="64" rx="15" fill="#2F243A"/>
  <rect x="0.5" y="0.5" width="63" height="63" rx="14.5" fill="none" stroke="#5A5468"/>
  <path d="M9 32 C11 15 16 15 18 32 C20 47 24.5 47 26.5 32 C28 23 31 23 32.5 32 C33.5 37 35.5 37 36.5 32 L46 32" fill="none" stroke="#DB8A74" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="50" y="22" width="4.5" height="20" rx="2.25" fill="#FAC9B8"/>
  ```
  Os ícones do app (dock, barra de tarefas, instaladores) estão prontos na pasta `logo/`. Veja a seção **Ícone do app**.
- Coluna com gap 2px: **"Fala que eu transcrevo!"** e **"Vídeo vira texto, sem sair do seu computador"**.

Direita muda por tela (ver cada tela).

### Pill de status

`inline-flex`, gap 8px, `padding: 7px 12px`, raio 999px, 13px/500, ponto de 8×8 redondo.
- OK: fundo `--success-bg`, texto `--success-text`, ponto `--success`. Texto: **"Tudo pronto"**.
- Pendente: fundo `--warning-bg`, texto `--warning-text`, ponto `--warning`. Texto: **"Configuração pendente"**.

### Botão de ícone (header)

44×44, raio 12px, borda `1px --border`, fundo `--surface`, cor `--text-strong-muted`, ícone 20px, `stroke-width 1.8`.

### Botão secundário com texto (header)

Altura 44px, `padding: 0 16px`, raio 12px, borda `1px --border`, fundo `--surface`, 14px, ícone 16px, gap 8px.

### Botão primário

Fundo `--accent`, texto `--on-accent`, sem borda, raio 14px, peso 700, ícone 18px (`stroke-width 2.2`) + texto com gap 10px. Altura 50px (52px no Resultado). Desabilitado: `opacity: 0.45` e `disabled`.

## Telas e fluxo

```
Abrir app
 ├─ ffmpeg ou whisper-cli faltando → Tela 2 (Setup)
 │     └─ "Já instalei, verificar de novo" → revalida → Tela 1
 └─ tudo ok → Tela 1 (Início)
        └─ vídeo escolhido + "Transcrever" → Tela 3 (Transcrevendo)
               ├─ "Cancelar" → Tela 1
               └─ concluído → Tela 4 (Resultado)
                      └─ "Nova transcrição" → Tela 1
```

Se o modelo escolhido ainda não foi baixado, o download acontece na Tela 3 como uma etapa (não é uma tela separada).

---

### Tela 1 · Início (`referencia.html`, `#tela-1`)

**Header, direita** (gap 10px): pill "Tudo pronto" · botão de ícone **Histórico** (`aria-label="Histórico"`) · botão de ícone **Configurações** (`aria-label="Configurações"`).

Ícone Histórico:
```svg
<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>
```
Ícone Configurações:
```svg
<path d="M4 7h10"/><path d="M18 7h2"/><circle cx="16" cy="7" r="2"/><path d="M4 17h2"/><path d="M10 17h10"/><circle cx="8" cy="17" r="2"/>
```

**Main**: coluna, gap 22px.

**1. Dropzone**: é um `<button>` de largura total (clique abre o seletor de arquivos; também aceita arrastar e soltar em toda a área).
- Borda `1.5px dashed --border-strong`, raio 22px, fundo `--surface-sunken`, `padding: 44px 24px 40px`, coluna centralizada, gap 18px.
- **Onda sonora** decorativa: linha de 28 barras, largura 5px, raio 3px, gap 5px, altura do contêiner 64px, centralizadas verticalmente. Alturas (px), em ordem:
  `14,22,34,26,46,58,40,28,18,30,52,64,48,36,24,40,56,44,30,20,34,50,38,26,16,24,18,12`
  Barras de índice 9 a 19 (base 0) usam `--accent`; o resto usa `--wave-idle`.
- Título: **"Solte seu vídeo aqui"**.
- Linha 15px `--text-muted`: **"ou escolha um arquivo no computador"**. O trecho "escolha um arquivo" fica em `--accent-text`, sublinhado, `text-underline-offset: 3px`.
- Chips de formato (margem superior 4px, gap 6px, quebram linha): `MP4 MOV MKV WEBM MP3 WAV`. JetBrains Mono 11.5px, `--text-muted`, borda `1px --border`, raio 6px, `padding: 4px 8px`.
- **Estado arrastando** (não está no mock, implemente assim): borda vira `--accent` sólida e o fundo `--accent-selected-bg`.
- **Estado com arquivo** (não está no mock, implemente assim): troque o conteúdo do dropzone pelo cartão de arquivo da Tela 3 (miniatura + nome + `duração · tamanho`) e um link "Trocar vídeo".

**2. Opções**: `flex`, `flex-wrap: wrap`, gap 22px, `align-items: flex-start`.

*Coluna Idioma* (`flex: 1 1 240px`, coluna, gap 10px):
- `<label for="idioma">` **"Idioma do vídeo"** (estilo rótulo de seção).
- `<select id="idioma">` com aparência customizada: altura 52px, raio 14px, borda `1px --border`, fundo `--surface`, texto `--text` 15px/500, `padding: 0 44px 0 16px`, `appearance: none`. Chevron 18px `--text-muted` posicionado a `right: 16px; top: 17px`, `pointer-events: none`: `<path d="m6 9 6 6 6-6"/>`.
- Opções: **Português (Brasil)** (padrão), **Detectar automaticamente**, **Inglês**, **Espanhol** (lista completa pode crescer depois, mantendo esses primeiros).
- Dica 12.5px `--text-faint`: **"Escolher o idioma certo deixa a transcrição mais precisa."**

*Coluna Qualidade* (`<fieldset>`, `flex: 999 1 560px`, `min-width: 0`, sem borda/padding):
- `<legend>` **"Qualidade da transcrição"** (rótulo de seção, margem inferior 10px).
- Grid: `grid-template-columns: repeat(auto-fit, minmax(120px, 1fr))`, gap 8px.
- 5 cartões de modelo, cada um um `<button aria-pressed>`, seleção única (padrão: **Small**):

| Modelo | Rapidez | Precisão | Texto de tamanho |
|---|---|---|---|
| Tiny | 5 | 1 | se baixado: `✓ Já baixado · 75 MB` / senão `Baixar · 75 MB` |
| Base | 4 | 2 | `142 MB` |
| Small (selo **Ideal**) | 3 | 3 | `466 MB` |
| Medium | 2 | 4 | `1,5 GB` |
| Large | 1 | 5 | `2,9 GB` |

  O estado "baixado" vem do disco (o mock mostra Tiny e Base baixados).
- Cartão: coluna, `align-items: flex-start`, gap 12px, `padding: 14px`, raio 14px, texto à esquerda.
  - Normal: fundo `--surface`, borda `1.5px solid --border`.
  - Selecionado: fundo `--accent-selected-bg`, borda `1.5px solid --accent`, `box-shadow: 0 0 0 4px --accent-ring`.
- Linha 1: nome (Bricolage 16/700) à esquerda; à direita, só no Small, **"Ideal"** (10.5px/600, uppercase, letter-spacing 0.06em, `--accent-soft-text`).
- Linhas 2 e 3 (coluna, gap 6px): rótulo **"Rapidez"** / **"Precisão"** (11.5px `--text-muted`) à esquerda e 5 quadradinhos 7×7, raio 2px, gap 3px, à direita. Aceso: Rapidez `--meter-speed-on`, Precisão `--accent`. Apagado: `--meter-off`.
- Linha 4: tamanho em JetBrains Mono 11.5px. Cor `--success-text` se baixado, senão `--text-faint`.

**3. Footer**: `flex`, wrap, `space-between`, gap 16px, `padding-top: 18px`, borda superior `1px --border-header`.
- Esquerda (gap 10px, 13px `--text-muted`): ícone cadeado 18px `--success-text`, depois **"Tudo acontece no seu computador. Nenhum arquivo é enviado para a internet."**
  ```svg
  <rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>
  ```
- Direita (gap 14px): dica 13px `--text-faint` + botão primário **"Transcrever"** (altura 50px, `padding: 0 26px`, 15.5px).
  - Sem vídeo: dica **"Escolha um vídeo para começar"**, botão desabilitado.
  - Com vídeo e modelo baixado: sem dica, botão ativo.
  - Com vídeo e modelo não baixado: dica **"O modelo será baixado antes (466 MB)"** (tamanho do modelo escolhido), botão ativo.
  Ícone do botão:
  ```svg
  <path d="M4 6h16"/><path d="M4 12h10"/><path d="M4 18h7"/><path d="m16 15 3 3 3-3"/>
  ```

---

### Tela 2 · Primeira execução (`referencia.html`, `#tela-2`)

Substitui o antigo banner vermelho de erro. Aparece no início se faltar qualquer dependência.

**Header, direita**: pill "Configuração pendente".

**Main** (máx. 760px), coluna, gap 24px:

1. Bloco de título (gap 10px):
   - Eyebrow **"Primeira vez por aqui"**.
   - H1 **"Falta só um passo para começar"**.
   - Parágrafo 15.5px, line-height 1.6, `--text-muted`: **"O app usa duas ferramentas gratuitas que rodam direto no seu computador. Elas ainda não foram encontradas."**

2. Checklist: cartão com borda `1px --border`, raio 18px, fundo `--surface`, `overflow: hidden`. Duas linhas (`padding: 18px 20px`, gap 14px, divisor `1px --border-subtle` entre elas):
   - Tile 40×40, raio 10px, fundo `--icon-tile`, ícone 20px `--text-strong-muted`.
   - Coluna: nome em JetBrains Mono 14.5px + descrição 13px `--text-muted`.
   - Selo de status à direita.

   | Nome | Descrição | Ícone |
   |---|---|---|
   | `ffmpeg` | Separa o áudio do vídeo | `<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M7 5v14"/><path d="M17 5v14"/><path d="M3 12h18"/>` |
   | `whisper-cli` | Transforma a fala em texto | `<rect x="9" y="3" width="6" height="11" rx="3"/><path d="M5 11a7 7 0 0 0 14 0"/><path d="M12 18v3"/>` |

   Selo "Não encontrado": `inline-flex`, gap 6px, 12.5px/500, `--warning-text` em `--warning-bg`, raio 999px, `padding: 5px 10px`, ícone 14px:
   `<circle cx="12" cy="12" r="9"/><path d="M12 8v5"/><path d="M12 16.5v.01"/>`
   Selo "Encontrado" (implemente para quando só uma falta): mesmo formato, `--success-text` em `--success-bg`, ícone `<path d="m5 12 5 5 9-10"/>`, texto **"Encontrado"**.

3. Instruções (coluna, gap 12px):
   - Linha com wrap e `space-between`: **"Instale pelo terminal"** (14px/600 `--text-strong-muted`) e as abas.
   - Abas: `role="tablist"` com `aria-label="Sistema operacional"`, `inline-flex`, gap 4px, `padding: 4px`, fundo `--surface`, borda `1px --border`, raio 12px. Cada aba é `<button role="tab" aria-selected>`, altura 36px, `padding: 0 14px`, raio 9px, 13px/600. Ativa: fundo `--border`, texto `--text`. Inativa: transparente, `--text-muted`. **Selecione por padrão o SO em que o app está rodando.**
   - Uma linha de comando por comando (coluna, gap 8px): fundo `--surface-code`, borda `1px --border`, raio 12px, `padding: 6px 6px 6px 16px`, gap 12px. `$` em mono 13.5px `--text-faint`, `<code>` mono 13.5px `--text` com `overflow-x: auto; white-space: nowrap`, e botão **"Copiar"** (`aria-label="Copiar comando"`, altura 44px, `padding: 0 14px`, raio 9px, borda `1px --border-button`, fundo `--surface-raised`, 13px/500, ícone 16px). Depois de copiar, troque o texto por **"Copiado"** por 2s.
     Ícone copiar: `<rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/>`
   - Nota 13px `--text-faint` abaixo, por SO.

   | Aba | Comandos | Nota |
   |---|---|---|
   | macOS | `brew install ffmpeg whisper-cpp` | Usa o Homebrew. Não tem? Instale em brew.sh e rode o comando acima. |
   | Windows | `winget install Gyan.FFmpeg` · `[PACOTE-DO-WHISPER-CLI]` | Rode no PowerShell. Depois feche e abra o app de novo. |
   | Linux | `sudo apt install ffmpeg` · `[COMANDO-DE-INSTALAÇÃO-DO-WHISPER-CLI]` | Exemplo para Ubuntu e Debian. Em outras distros, use o gerenciador de pacotes equivalente. |

   **Os itens entre colchetes são marcadores.** Defina o comando real para Windows e Linux antes de lançar. Mostre só os comandos das ferramentas que faltam.

4. Ações (wrap, gap 12px, `padding-top: 8px`):
   - Primário **"Já instalei, verificar de novo"** (altura 50px, `padding: 0 24px`, 15px), ícone `<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>`. Ao clicar: ícone gira enquanto verifica; se tudo ok, vai para a Tela 1; senão atualiza os selos.
   - Link **"Preciso de ajuda"** (altura 50px, `padding: 0 18px`, raio 14px, borda `1px --border`, 14px/500, `--text-strong-muted`, sem sublinhado), abre `https://github.com/ggml-org/whisper.cpp` no navegador padrão (ou a página de ajuda do projeto, se houver).

---

### Tela 3 · Transcrevendo (`referencia.html`, `#tela-3`)

**Header, direita**: botão secundário **"Cancelar"** com ícone X (`<path d="M6 6l12 12"/><path d="M18 6 6 18"/>`, `stroke-width 2`). Pede confirmação antes de cancelar.

**Main** (máx. 1080px): `flex`, wrap, gap 24px, `align-items: stretch`.

**Coluna esquerda** (`flex: 1 1 320px`, coluna, gap 18px):

1. Cartão do arquivo: gap 14px, `padding: 14px`, borda `1px --border`, raio 16px, fundo `--surface`.
   - Miniatura 76×52, raio 10px, fundo `--track` com ícone de vídeo 22px `--text-muted` (`<rect x="3" y="5" width="13" height="14" rx="2"/><path d="m16 10 5-3v10l-5-3"/>`). Se conseguir extrair um frame com ffmpeg, mostre o frame com `object-fit: cover`.
   - Nome do arquivo 14.5px/600 com reticências; abaixo, mono 12px `--text-muted`: `duração · tamanho · idioma` (ex.: `48:12 · 612 MB · Português`).

2. Cartão de progresso: coluna, gap 12px, `padding: 22px`, borda `1px --border`, raio 18px, fundo `--surface`.
   - Linha base (`align-items: baseline`, `space-between`): porcentagem grande + **"cerca de N min restantes"** (13px `--text-muted`).
   - Barra: `role="progressbar"` com `aria-valuenow`, altura 10px, raio 999px, trilho `--track`, preenchimento `--accent`. Anime a largura (`transition: width 300ms ease`).
   - Lista de etapas (`<ol>` sem marcador, margem superior 10px, gap 14px), cada uma com ícone 24×24 + texto 14px:
     - Concluída: círculo `--success-bg` com check 14px `--success-text` (`stroke-width 2.6`), texto `--text-muted`.
     - Atual: anel `2px --accent` com ponto central 8×8 `--accent`, texto `--text` 600. Dê ao ponto um pulso leve de opacidade.
     - Pendente: anel `2px --border-strong`, texto `--text-faint`.
   - Etapas, em ordem: **"Áudio separado do vídeo"** · **"Modelo {Nome} pronto"** (enquanto baixa: **"Baixando modelo {Nome} · {x} de {total}"**) · **"Transcrevendo a fala"** · **"Texto pronto para exportar"**.

3. Nota 13px `--text-faint`: **"Pode minimizar a janela. A gente avisa quando terminar."** Ao terminar, dispare uma notificação do sistema.

**Coluna direita**: "Prévia ao vivo" (`<section aria-label="Prévia ao vivo">`, `flex: 999 1 480px`, `min-width: 0`, borda `1px --border`, raio 18px, fundo `--surface-sunken`, `overflow: hidden`):
- Cabeçalho (`padding: 16px 20px`, borda inferior `1px --border-subtle`): **"Prévia ao vivo"** 14px/600 à esquerda; à direita, ponto 7×7 `--accent` + **"escrevendo…"** 12.5px `--accent-soft-text`.
- Corpo (`padding: 20px`, coluna, gap 18px, rolagem vertical que acompanha o fim): cada trecho é um grid `64px minmax(0,1fr)`, gap 14px, `align-items: baseline`. Horário mono 12px `--text-faint` (`mm:ss`, ou `h:mm:ss` acima de 1h). Texto 15.5px, line-height 1.6.
  - Trechos antigos (todos menos os 3 últimos): `--text-faint`. Os 3 últimos: `--text-strong-muted`. O trecho sendo escrito: `--text`, seguido de um cursor 2×18px `--accent` piscando (1s).

---

### Tela 4 · Resultado (`referencia.html`, `#tela-4`)

**Header, direita**: botão secundário **"Nova transcrição"** (texto `--text`, 600), ícone `+` 16px (`<path d="M12 5v14"/><path d="M5 12h14"/>`, `stroke-width 2.2`).

**Main** (máx. 1120px): `flex`, wrap, gap 24px, `align-items: flex-start`.

**Painel de transcrição** (`<section aria-label="Transcrição">`, `flex: 999 1 560px`, `min-width: 0`, borda `1px --border`, raio 18px, fundo `--surface-sunken`, `overflow: hidden`):
- Barra superior (wrap, `space-between`, gap 12px, `padding: 14px 16px 14px 20px`, borda inferior `1px --border-subtle`):
  - Nome do arquivo 15px/600 + dica 12.5px `--text-muted` **"Clique em um trecho para editar"**.
  - Busca (`flex: 0 1 240px`): `<label for="busca">` visualmente oculto **"Buscar na transcrição"**; `<input id="busca" placeholder="Buscar no texto">` altura 44px, raio 12px, borda `1px --border`, fundo `--surface`, 14px, `padding: 0 14px 0 38px`; lupa 16px `--text-faint` em `left: 14px; top: 14px` (`<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>`). Destaque os termos encontrados com fundo `--accent-selected-bg` e texto `--accent-soft-text`.
- Lista (`padding: 10px 8px 16px`, rolagem própria): cada trecho é grid `56px minmax(0,1fr)`, gap 14px, `padding: 10px 12px`, raio 12px.
  - Horário mono 12px `--accent-soft-text`, `padding-top: 3px`. **Clicar no horário copia o horário.**
  - Texto 15.5px, line-height 1.65, `--text-body`. **Clicar no texto torna o trecho editável** (contenteditable ou textarea); as edições entram nas exportações.
  - Hover e foco: fundo `--surface-hover-row`.

**Lateral** (`<aside>`, `flex: 1 1 300px`, coluna, gap 16px):

1. Cartão "Pronto!": coluna, gap 14px, `padding: 22px`, raio 18px, fundo `--accent-card-bg`, borda `1px --accent-card-border`.
   - Tile 44×44, raio 12px, fundo `--accent`, check 22px `--on-accent` `stroke-width 2.6`.
   - Título **"Pronto! Seu texto está aqui."**
   - Grid de 3 colunas iguais, gap 8px: valor mono 15px + rótulo 12px `--text-muted`: `{duração}` **de vídeo** · `{palavras}` **palavras** (milhar com ponto: `6.840`) · `{tempo} min` **para fazer**.

2. Primário de largura total **"Copiar todo o texto"** (altura 52px, 15px, ícone copiar). Após copiar: **"Copiado!"** por 2s.

3. **"Salvar como"** (rótulo de seção) + 3 botões (coluna, gap 8px). Cada um: gap 12px, `min-height: 56px`, `padding: 10px 14px`, raio 14px, borda `1px --border`, fundo `--surface`, texto à esquerda.
   - Selo da extensão: mono 12px/500, `--accent-soft-text` em `--accent-chip-bg`, raio 7px, `padding: 5px 8px`, `min-width: 34px`, centralizado.
   - Título 14px/600 + descrição 12.5px `--text-muted`.
   - Ícone de download 18px `--text-muted`: `<path d="M12 4v11"/><path d="m7 10 5 5 5-5"/><path d="M5 20h14"/>`

   | Extensão | Título | Descrição |
   |---|---|---|
   | TXT | Texto simples | Para ler, colar ou editar |
   | SRT | Legendas | YouTube, Premiere, DaVinci |
   | VTT | Legendas para web | Players HTML5 e Vimeo |

   Cada botão abre o diálogo nativo de salvar, com nome padrão igual ao do vídeo e a extensão correspondente, na mesma pasta do vídeo.

## Responsividade

- Em todas as telas, as linhas com `flex-wrap: wrap` e os `flex-basis` acima fazem as colunas empilharem sozinhas. Não use `100vh` nem colunas fixas/sticky.
- Abaixo de ~640px de largura: reduza o padding horizontal do header e do `main` de 32px para 20px.
- Os cartões de modelo se reorganizam pelo `auto-fit` (5 → 3 → 2 colunas).

## Acessibilidade e interação

- Contraste já validado para os pares acima (texto ≥ 4.5:1). Não clareie nem escureça os cinzas.
- Foco visível em tudo: `outline: 2px solid var(--accent); outline-offset: 2px` em `:focus-visible`.
- Hover: botões secundários e cartões ganham borda `--border-strong`; primário fica `filter: brightness(1.06)`.
- Transições curtas (150ms) em cor, borda e sombra. Respeite `prefers-reduced-motion` (desligue pulso, cursor piscando e giro).
- Atalhos: `Ctrl/Cmd+O` abre o seletor de vídeo na Tela 1; `Ctrl/Cmd+F` foca a busca na Tela 4.

## Ícone do app

Substitua os ícones padrão do Flutter pelos da pasta `logo/` (detalhes em `logo/LEIA-ME.txt`):

| Plataforma | Origem | Destino no projeto Flutter |
|---|---|---|
| Windows | `logo/windows/app_icon.ico` | `windows/runner/resources/app_icon.ico` |
| macOS | `logo/macos/app_icon_16.png` … `app_icon_1024.png` | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (mesmos nomes; mantenha o `Contents.json`) |
| Linux | `logo/png/icon-256.png` (e demais tamanhos) | Copie para `linux/` (ex.: `linux/assets/app_icon.png`), defina como ícone da janela em `linux/runner/my_application.cc` com `gtk_window_set_icon_from_file`, e use nos pacotes (.desktop / AppImage / snap / flatpak) |
| Dentro do app (header) | `logo/icon.svg` | `assets/brand/icon.svg`, declarado no `pubspec.yaml` |

A versão macOS já tem margem e sombra (padrão do Dock); não use os PNGs de `logo/png/` no macOS. `logo/marca/` e `logo/lockup/` são para site, README e materiais de divulgação.

## Mapeamento para Flutter

### Tokens

- Crie `lib/theme/app_colors.dart` com uma classe `AppColors` contendo **todos** os tokens de cor da tabela, com os mesmos nomes em camelCase (`bg`, `surface`, `surfaceSunken`, `accent`, `onAccent`, `accentSoftText`, `successBg`…). Ex.: `static const accent = Color(0xFFDB8A74);` e `accentRing = Color(0x38DB8A74)`.
- Deixe o accent trocável: um `ThemeExtension<AppPalette>` com os tokens derivados do accent, ou um `ValueNotifier<Color>` lido pelos widgets.
- `lib/theme/app_text.dart` com os estilos da tabela de tipografia (`brandName`, `dropzoneTitle`, `setupH1`, `percent`, `doneTitle`, `modelName`, `sectionLabel`, `eyebrow`, `body`, `hint`, `mono`…). `letterSpacing` em Flutter é absoluto: converta `em` multiplicando pelo tamanho (−0.02em em 30px = −0.6).
- `line-height` do CSS vira `height` no `TextStyle` (1.6 → `height: 1.6`).
- Monte um `ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: AppColors.bg, …)` e use `useMaterial3: true`, mas estilize os componentes à mão com os tokens; não use as cores padrão do Material.
- Desligue o splash/ripple padrão (`splashFactory: NoSplash.splashFactory`) e use as transições de hover descritas.

### Ícones

Os ícones são traços SVG (viewBox 24×24). Duas opções, nesta ordem de preferência:
1. Salve cada um como `.svg` em `assets/icons/` (copie os `<path>` deste documento ou do HTML, com `stroke="currentColor"`) e desenhe com `flutter_svg`, colorindo com `ColorFilter.mode(cor, BlendMode.srcIn)`.
2. Se preferir sem dependência, `CustomPainter` reproduzindo os mesmos paths com `StrokeCap.round` e `StrokeJoin.round`.

Não troque por Material Icons: o traço e as proporções são diferentes. O `stroke-width` varia por uso (1.8, 2, 2.2, 2.6): respeite.

### Layout CSS → widgets

| CSS no HTML | Flutter |
|---|---|
| `display:flex` coluna com `gap` | `Column` com `spacing:` (Flutter ≥ 3.27) ou `SizedBox` entre filhos |
| `display:flex` linha com `gap` | `Row` com `spacing:` |
| `flex-wrap: wrap` + `flex: 999 1 560px` / `flex: 1 1 320px` (colunas que empilham) | `LayoutBuilder`: se a largura disponível ≥ soma das bases + gap, `Row` com `Expanded(flex: …)`; senão `Column`. Bases por tela abaixo |
| `max-width` + `margin: 0 auto` | `Center` + `ConstrainedBox(constraints: BoxConstraints(maxWidth: …))` |
| `grid-template-columns: repeat(auto-fit, minmax(120px,1fr))` | `LayoutBuilder` calculando colunas = `max(1, ((w + 8) / (120 + 8)).floor())` limitado a 5, e `Wrap` ou `GridView` com essa largura de célula |
| `border-radius` | `BorderRadius.circular(…)` |
| `border: 1.5px dashed` (dropzone) | `CustomPainter` com path tracejado (traço 6, espaço 5) ou o pacote `dotted_border` |
| `box-shadow: 0 0 0 4px rgba(...)` (anel do modelo selecionado) | `BoxShadow(color: AppColors.accentRing, spreadRadius: 4, blurRadius: 0)` |
| `text-overflow: ellipsis` | `Text(…, maxLines: 1, overflow: TextOverflow.ellipsis)` |
| `overflow-x: auto` no `<code>` | `SingleChildScrollView(scrollDirection: Axis.horizontal)` |
| `transition .15s` | `AnimatedContainer(duration: Duration(milliseconds: 150))` |
| `:hover` | `MouseRegion` + estado, ou `InkWell(onHover:)` sem splash |
| `:focus-visible` (contorno accent 2px, offset 2px) | `FocusableActionDetector` / `Focus` desenhando a borda quando focado pelo teclado |
| `cursor: pointer` | `MouseRegion(cursor: SystemMouseCursors.click)` |

Bases para empilhar colunas (do HTML):
- Tela 1, opções: Idioma `240` + Qualidade `560` + gap `22` → em linha se largura ≥ 822.
- Tela 3: esquerda `320` + prévia `480` + gap `24` → em linha se ≥ 824. Em linha, a proporção é esquerda 1 : prévia ~2.2 (no frame de 1120, esquerda ≈ 320px).
- Tela 4: transcrição `560` + lateral `300` + gap `24` → em linha se ≥ 884. Em linha, lateral ≈ 300px fixos e a transcrição ocupa o resto.

### Componentes HTML → widgets

| HTML | Flutter |
|---|---|
| `<select>` de idioma | `DropdownButtonFormField` / `DropdownMenu` totalmente estilizado: altura 52, raio 14, borda `border`, fundo `surface`, chevron próprio 18px `textMuted` a 16px da direita. O menu aberto usa fundo `surfaceRaised`, raio 12, item selecionado com `accent` no texto |
| `<input>` de busca | `TextField` com `InputDecoration` sem preenchimento padrão do Material: altura 44, raio 12, borda `border` (foco: `accent`), ícone de lupa como `prefixIcon` |
| Abas de SO (`role=tablist`) | `Row` de botões custom no contêiner de raio 12; não use `TabBar` |
| Barra de progresso | `Container` trilho + `FractionallySizedBox(widthFactor: p)` animado (`TweenAnimationBuilder`) ; não use `LinearProgressIndicator` padrão |
| Onda sonora | `Row` de 28 `Container`s 5px com as alturas listadas, ou `CustomPainter` |
| Cursor piscando / ponto pulsando | `AnimationController` repetindo (1s piscar; 1.4s pulso de opacidade 1 → 0.35) |
| Trecho editável | Texto normal; ao clicar, troca por `TextField` multilinha com o mesmo estilo e sem borda |
| Dica com `title`/tooltip | `Tooltip` com fundo `surfaceRaised`, texto 12.5px |

### Integrações de desktop

- Janela: use `window_manager` para tamanho inicial 1120 × 780, mínimo 720 × 600, título "Fala que eu transcrevo!".
- Arrastar e soltar: `desktop_drop` (`DropTarget`) envolvendo o dropzone; ligue o estado "arrastando" em `onDragEntered`/`onDragExited`.
- Seletor e "Salvar como": `file_selector` (ou `file_picker`) com filtro de extensões.
- Copiar: `Clipboard.setData`.
- Notificação ao terminar: `local_notifier` ou `flutter_local_notifications`.
- Detecção do SO para pré-selecionar a aba: `Platform.isMacOS / isWindows / isLinux`.
- Atalhos `Ctrl/Cmd+O` e `Ctrl/Cmd+F`: `Shortcuts` + `Actions` com `SingleActivator(…, meta: Platform.isMacOS, control: !Platform.isMacOS)`.
- Reduzir movimento: `MediaQuery.of(context).disableAnimations`.

## Fora do escopo deste handoff

Telas de Histórico e Configurações ainda não foram desenhadas. Deixe os botões do header no lugar e, por enquanto, sem ação ou com um painel vazio usando o mesmo estilo de cartão.

## Checklist de aceite

- [ ] Fontes embutidas como assets e funcionando offline.
- [ ] Tokens em `AppColors` / estilos de texto centralizados, accent trocável.
- [ ] Ícones SVG originais (não Material Icons).
- [ ] As 4 telas batem com os prints de `referencia.html` em 1120 × 780.
- [ ] O banner vermelho antigo foi removido; dependências faltando caem na Tela 2.
- [ ] Aba do SO atual pré-selecionada na Tela 2; marcadores de comando substituídos.
- [ ] Seleção de modelo com `aria-pressed`, padrão Small, estado "baixado" vindo do disco.
- [ ] Progresso, etapas e prévia ao vivo alimentados pelo whisper-cli em tempo real.
- [ ] Copiar, editar trecho, busca e exportação TXT/SRT/VTT funcionando.
- [ ] Layout empilha corretamente em janela estreita.
