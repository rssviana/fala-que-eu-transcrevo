# Contribua com o Fala que eu transcrevo!

Guia para quem quer rodar o projeto, entender o código ou gerar os instaladores.
Voltar para o [README](README.md).

Nomes técnicos: pasta e pacote Dart `transcritor`, identificador `dev.fqet.falaqueeutranscrevo`,
executável `transcritor` no Windows e no Linux.

## Como funciona por baixo

O **ffmpeg** extrai o áudio em WAV 16 kHz mono numa pasta temporária e o **whisper-cli**
(whisper.cpp) transcreve; os dois rodam como processos filhos, e o progresso vem do parse da
saída deles. Os modelos são os arquivos ggml do repositório
[ggerganov/whisper.cpp no Hugging Face](https://huggingface.co/ggerganov/whisper.cpp):

| Modelo | Arquivo |
|---|---|
| Tiny | `ggml-tiny.bin` |
| Base | `ggml-base.bin` |
| Small | `ggml-small.bin` |
| Medium | `ggml-medium.bin` |
| Large Turbo | `ggml-large-v3-turbo.bin` |

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
   `/snap/bin` (Linux); `%LOCALAPPDATA%\dev.fqet.falaqueeutranscrevo\bin` (e `bin\Release`) no Windows.
   Apps abertos pelo Finder não herdam o `PATH` do shell, por isso o fallback.

### Comandos de instalação da tela "Primeira execução"

| SO | ffmpeg | whisper-cli |
|---|---|---|
| macOS | `brew install ffmpeg` | `brew install whisper-cpp` (os dois juntos viram um comando só) |
| Windows | `winget install Gyan.FFmpeg` | não há pacote no winget: um comando de PowerShell baixa o `whisper-bin-x64.zip` oficial para `%LOCALAPPDATA%\dev.fqet.falaqueeutranscrevo\bin` |
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

## Builds e releases no GitHub Actions

`.github/workflows/build.yml`:

- **push na `main` e pull requests**: `flutter analyze` + `flutter test`.
- **Actions → Build → Run workflow**: também gera os três instaladores como artefatos do run.
- **tag `v*`** (ex.: `git tag v0.1.0 && git push origin v0.1.0`): gera os instaladores e publica
  uma Release com nomes fixos, que são os arquivos dos botões de download do [README](README.md):
  - `FalaQueEuTranscrevo-macos.dmg` (Apple Silicon, assinatura ad-hoc)
  - `FalaQueEuTranscrevo-windows-setup.exe` (Inno Setup, `packaging/windows/installer.iss`)
  - `FalaQueEuTranscrevo-linux-x86_64.AppImage` (`packaging/linux/`)

O whisper-cli (versão fixa em `WHISPER_CPP_VERSION`) é compilado estático em cada plataforma. O
ffmpeg vem dos builds estáticos do BtbN no Windows e no Linux e é compilado do código-fonte oficial
no macOS (com cache). A versão do app vem do `version:` do `pubspec.yaml`.

## Limitações conhecidas

- Sem assinatura de código: macOS sem notarização e Windows sem certificado (ver Instalação no [README](README.md#instalação)).
- macOS só para Apple Silicon por enquanto (o runner `macos-14` é arm64).
- Arquivos sem trilha de áudio falham na etapa do ffmpeg (a mensagem de erro mostra o motivo).
- A notificação de fim usa `osascript` (macOS), `notify-send` (Linux) e um balão do PowerShell
  (Windows). No macOS ela aparece como vinda do "Script Editor".
