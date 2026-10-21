# Fala que eu transcrevo!

App desktop (macOS, Windows e Linux) que transcreve vídeos **localmente e offline**
usando o [Whisper](https://github.com/openai/whisper) via
[whisper.cpp](https://github.com/ggml-org/whisper.cpp). Nada sai do computador.

Nomes técnicos: pasta e pacote Dart `transcritor`, bundle id `dev.rssviana.transcritor`,
executável `transcritor` no Windows e no Linux.

## Como funciona

A interface segue o handoff de design em `design/HANDOFF.md` (referência visual em
`design/referencia.html`). São 4 telas:

1. **Início** — arraste (ou escolha, `Cmd/Ctrl+O`) um vídeo local, escolha o idioma (padrão
   português do Brasil, ou "Detectar automaticamente") e a qualidade (modelo Tiny a Large
   Turbo). Abaixo dos cartões aparece o que o modelo escolhido significa na prática.
2. **Primeira execução** — aparece se faltar ffmpeg ou whisper-cli, com o comando de instalação
   do seu sistema e o botão "Já instalei, verificar de novo".
3. **Transcrevendo** — etapas (áudio separado → modelo pronto/baixando → transcrevendo → pronto),
   porcentagem, tempo restante estimado e prévia ao vivo do texto. Ao terminar, o sistema mostra
   uma notificação.
4. **Resultado** — clique num trecho para editar, clique no horário para copiá-lo, busque no
   texto (`Cmd/Ctrl+F`), copie tudo ou salve. Cada botão abre a janela "Salvar" do sistema,
   começando na pasta do vídeo, para escolher pasta e nome; depois dá para "Mostrar na pasta".
   Formatos:
   - **TXT** — texto corrido, um trecho por linha
   - **SRT** e **VTT** — legendas com tempos
   - **MD** — Markdown com título, idioma, modelo, data e parágrafos com tempo de início
   - **PDF** — mesmo conteúdo do Markdown, em A4, com a fonte Noto Sans embutida
     (cobre latim, grego e cirílico; japonês e outros alfabetos não aparecem no PDF)

Por baixo: o **ffmpeg** extrai o áudio em WAV 16 kHz mono numa pasta temporária e o
**whisper-cli** transcreve; o progresso vem do parse da saída dos dois processos.

Os modelos ggml **não vão no instalador**: são baixados do Hugging Face no primeiro uso
para a pasta de suporte do app (no macOS,
`~/Library/Application Support/dev.rssviana.transcritor/models`).

| Modelo | Arquivo | Tamanho | Rapidez | Precisão |
|---|---|---|---|---|
| Tiny | `ggml-tiny.bin` | ~75 MB | 5 | 1 |
| Base | `ggml-base.bin` | ~142 MB | 4 | 2 |
| Small (padrão, "Ideal") | `ggml-small.bin` | ~466 MB | 3 | 3 |
| Medium | `ggml-medium.bin` | ~1,5 GB | 2 | 4 |
| Large Turbo | `ggml-large-v3-turbo.bin` | ~1,5 GB | 2 | 5 |

## Desenvolvimento

Requisitos: Flutter 3.38+, e `ffmpeg` + `whisper-cli` instalados.

```bash
brew install ffmpeg whisper-cpp   # macOS
flutter pub get
flutter test
flutter run -d macos
```

Prints das 4 telas em 1120 × 780 (ou outro tamanho), com as fontes reais, em `build/screens/`,
para comparar com `design/referencia.html`:

```bash
SCREENSHOTS=1 flutter test test/screens
SCREENSHOTS=1 SIZE=720x600 flutter test test/screens
```

Tamanho e título da janela ficam no código nativo (sem plugin): `macos/Runner/MainFlutterWindow.swift`,
`windows/runner/main.cpp` + `win32_window.cpp` (mínimo) e `linux/runner/my_application.cc`.

No macOS o projeto usa **Swift Package Manager** para os plugins (veja `flutter: config:` no
`pubspec.yaml`), então não precisa de CocoaPods. O App Sandbox está **desligado** nos
entitlements: o app precisa executar ffmpeg/whisper-cli e ler vídeos de qualquer pasta, o que
não combina com o sandbox. Isso impede publicar na Mac App Store, mas não a distribuição direta.

### Estrutura

```
lib/
  main.dart              # tema, troca de telas (AppShell)
  src/core/              # Dart puro, testado em test/
    catalog.dart           # modelos, idiomas, formatos
    binary_locator.dart    # onde procurar ffmpeg e whisper-cli
    commands.dart          # argumentos do ffmpeg e do whisper-cli
    progress.dart          # parse de progresso e segmentos
    progress_plan.dart     # peso das etapas e tempo restante
    export.dart            # .txt, .srt, .vtt, .md, parágrafos, rótulos de tempo
    pdf_export.dart        # .pdf (pacote pdf, Noto Sans em assets/fonts)
    search.dart            # busca sem acento/maiúsculas
    system.dart            # comandos de instalação por SO e notificação
    transcriber.dart       # etapas com Process.start + cancelamento + miniatura
    model_store.dart       # download dos modelos (HttpClient, .part → rename)
  theme/
    app_colors.dart        # todos os tokens do handoff + AccentPalette (accent trocável)
    app_text.dart          # estilos de texto (Bricolage, Inter, JetBrains Mono)
  ui/
    controller.dart        # estado das 4 telas (ChangeNotifier)
    screens/               # home, setup, progress, result
    widgets/               # ícones SVG, botões, header, cartão do arquivo
```

Fontes da interface embutidas em `assets/fonts` (licenças OFL ao lado). São fontes variáveis; o
peso e o eixo óptico vão em `FontVariation`. A altura de linha "normal" de cada fonte é fixada em
`app_text.dart` para bater com o navegador (o Flutter usaria as métricas "win", ~18% mais altas).
Paleta (Midnight Violet `#2F243A`, Vintage Grape `#444054`, Silver `#BEBBBB`, Almond Silk
`#FAC9B8`, Salmon `#DB8A74`) e ícone "Onda que se acalma" vêm do pacote de design em `design/`
(`design/logo/` tem os arquivos originais). Ícone instalado em:

- macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (versão com margem e sombra)
- Windows: `windows/runner/resources/app_icon.ico`
- Linux: `linux/assets/app_icon.png`, instalado em `data/` e aplicado à janela em
  `linux/runner/my_application.cc`
- Header do app: `assets/brand/icon.svg`

## Onde o app procura os binários

Em ordem, parando no primeiro encontrado (`lib/src/core/binary_locator.dart`):

1. **Pasta empacotada com o app**
   - macOS: `Fala que eu transcrevo!.app/Contents/Resources/bin/`
   - Windows e Linux: `bin/` ao lado do executável
2. `PATH` do sistema
3. Pastas comuns: `/opt/homebrew/bin`, `/usr/local/bin` (macOS); `/usr/local/bin`, `/usr/bin`,
   `/snap/bin` (Linux); `%LOCALAPPDATA%\FalaQueEuTranscrevo\bin` (e `bin\Release`) no Windows.
   Apps abertos pelo Finder não herdam o `PATH` do shell, por isso o fallback.

### Comandos de instalação da tela "Primeira execução"

| SO | ffmpeg | whisper-cli |
|---|---|---|
| macOS | `brew install ffmpeg` | `brew install whisper-cpp` (os dois juntos viram um comando só) |
| Windows | `winget install Gyan.FFmpeg` | não há pacote no winget: um comando de PowerShell baixa o `whisper-bin-x64.zip` oficial para `%LOCALAPPDATA%\FalaQueEuTranscrevo\bin` |
| Linux | `sudo apt install ffmpeg` | `sudo snap install whisper-cpp && sudo snap alias whisper-cpp.cli whisper-cli` (snap **não oficial**) |

Ainda não testados em Windows e Linux de verdade. O snap tem confinamento estrito e pode não
enxergar o WAV temporário em `/tmp`; nos builds distribuídos o whisper-cli vai empacotado e essa
tela não aparece.

Nomes aceitos: `ffmpeg` e `whisper-cli` (ou o nome antigo `whisper-cpp`), com `.exe` no Windows.

## Empacotando os binários para distribuir

Os binários do Homebrew dependem de bibliotecas dinâmicas do próprio Homebrew, então **não
servem para empacotar**. Use builds estáticos:

### ffmpeg

| Plataforma | Fonte sugerida |
|---|---|
| Windows x64 | [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds/releases) — `ffmpeg-master-latest-win64-gpl.zip` (estático) |
| Linux x64 | BtbN — `ffmpeg-master-latest-linux64-gpl.tar.xz` (estático) |
| macOS arm64 | [ffmpeg.martin-riedl.de](https://ffmpeg.martin-riedl.de/) (estático) |

Só o executável `ffmpeg` é necessário. Atenção à licença: builds "gpl" são GPL; para
distribuir, inclua o aviso de licença e o link para o código-fonte do ffmpeg.

### whisper-cli

Compile o whisper.cpp com bibliotecas estáticas:

```bash
git clone --depth 1 https://github.com/ggml-org/whisper.cpp
cd whisper.cpp
cmake -B build -DBUILD_SHARED_LIBS=OFF -DWHISPER_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --target whisper-cli -j
# saída: build/bin/whisper-cli  (Windows: build/bin/Release/whisper-cli.exe)
```

No macOS o Metal (GPU) já vem ligado e os shaders ficam embutidos no binário.

### Onde colocar

```bash
# macOS (depois de flutter build macos --release)
APP="build/macos/Build/Products/Release/Fala que eu transcrevo!.app"
mkdir -p "$APP/Contents/Resources/bin"
cp ffmpeg whisper-cli "$APP/Contents/Resources/bin/"
codesign --force --deep -s - "$APP"   # ad-hoc; para distribuir, use Developer ID + notarização

# Linux (depois de flutter build linux --release)
mkdir -p build/linux/x64/release/bundle/bin
cp ffmpeg whisper-cli build/linux/x64/release/bundle/bin/

# Windows (depois de flutter build windows --release)
#   build\windows\x64\runner\Release\bin\ffmpeg.exe
#   build\windows\x64\runner\Release\bin\whisper-cli.exe
```

## Builds no GitHub Actions

`.github/workflows/build.yml` compila o app para macOS, Windows e Linux, baixa/compila
ffmpeg e whisper-cli estáticos, coloca tudo na pasta `bin` e publica um artefato por
plataforma. Roda em push de tag `v*` ou manualmente (workflow_dispatch).

## Limitações conhecidas

- Sem assinatura/notarização no macOS: na primeira abertura, use botão direito → Abrir.
- Sem instaladores (dmg/msi/AppImage) ainda: os artefatos são a pasta do app compactada.
- Arquivos sem trilha de áudio falham na etapa do ffmpeg (a mensagem de erro mostra o motivo).
- A notificação de fim usa `osascript` (macOS), `notify-send` (Linux) e um balão do PowerShell
  (Windows). No macOS ela aparece como vinda do "Script Editor".

> O workflow ainda não rodou: o projeto não tem repositório remoto. Ao subir para o GitHub,
> confira o primeiro run, principalmente o download do ffmpeg do macOS (fonte de terceiros).
