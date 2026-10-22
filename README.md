<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="design/logo/lockup/lockup-transparente-escuro@2x.png">
    <img alt="Fala que eu transcrevo!" src="design/logo/lockup/lockup-transparente-claro@2x.png" width="420">
  </picture>
</p>

<p align="center">
  Vídeo vira texto, sem sair do seu computador.<br>
  Transcrição <b>local e offline</b> com o <a href="https://github.com/openai/whisper">Whisper</a>
  (via <a href="https://github.com/ggml-org/whisper.cpp">whisper.cpp</a>). Nada é enviado para a internet.
</p>

<p align="center">
  <a href="https://github.com/rssviana/fala-que-eu-transcrevo/releases/latest/download/FalaQueEuTranscrevo-windows-setup.exe"><img alt="Baixar para Windows (.exe)" src="https://img.shields.io/badge/Windows-Baixar%20.exe-DB8A74?style=for-the-badge&logo=windows&logoColor=white&labelColor=2F243A"></a>
  <a href="https://github.com/rssviana/fala-que-eu-transcrevo/releases/latest/download/FalaQueEuTranscrevo-macos.dmg"><img alt="Baixar para macOS (.dmg)" src="https://img.shields.io/badge/macOS-Baixar%20.dmg-DB8A74?style=for-the-badge&logo=apple&logoColor=white&labelColor=2F243A"></a>
  <a href="https://github.com/rssviana/fala-que-eu-transcrevo/releases/latest/download/FalaQueEuTranscrevo-linux-x86_64.AppImage"><img alt="Baixar para Linux (.AppImage)" src="https://img.shields.io/badge/Linux-Baixar%20.AppImage-DB8A74?style=for-the-badge&logo=linux&logoColor=white&labelColor=2F243A"></a>
</p>

<p align="center">
  <a href="https://github.com/rssviana/fala-que-eu-transcrevo/releases/latest">Todas as versões</a> ·
  <a href="https://github.com/rssviana/fala-que-eu-transcrevo/actions/workflows/build.yml"><img alt="Build" src="https://github.com/rssviana/fala-que-eu-transcrevo/actions/workflows/build.yml/badge.svg"></a>
</p>

> [!WARNING]
> **Aviso importante:** esta aplicação é apenas para fins de aprendizagem e testes e não tem fins
> comerciais. Podem ocorrer erros na execução. Baixe e use por sua conta e risco.

## Instalação

O ffmpeg e o whisper-cli já vão dentro do instalador. Os modelos do Whisper são baixados pelo
próprio app no primeiro uso (de 75 MB a 1,5 GB, conforme a qualidade escolhida).

Os instaladores ainda **não são assinados**, então o sistema avisa na primeira abertura:

- **macOS** (Apple Silicon): abra o `.dmg` e arraste o app para Aplicativos. Na primeira vez, se
  aparecer que o app não pode ser aberto, vá em Ajustes do Sistema → Privacidade e Segurança e
  clique em **Abrir Mesmo Assim**.
- **Windows** (64 bits): rode o `.exe`. Se o SmartScreen avisar, clique em **Mais informações** →
  **Executar assim mesmo**.
- **Linux** (x86_64): dê permissão de execução e abra:
  `chmod +x FalaQueEuTranscrevo-linux-x86_64.AppImage && ./FalaQueEuTranscrevo-linux-x86_64.AppImage`

Nomes técnicos: pasta e pacote Dart `transcritor`, identificador `dev.fqet.falaqueeutranscrevo`,
executável `transcritor` no Windows e no Linux.

## Como funciona

São 4 telas:

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
para a pasta `models` dentro da pasta de dados do app:

- macOS: `~/Library/Application Support/dev.fqet.falaqueeutranscrevo/models`
- Windows: `%APPDATA%\dev.fqet.falaqueeutranscrevo\models`
- Linux: `~/.local/share/dev.fqet.falaqueeutranscrevo/models`

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
  uma Release com nomes fixos, que são os arquivos dos botões de download acima:
  - `FalaQueEuTranscrevo-macos.dmg` (Apple Silicon, assinatura ad-hoc)
  - `FalaQueEuTranscrevo-windows-setup.exe` (Inno Setup, `packaging/windows/installer.iss`)
  - `FalaQueEuTranscrevo-linux-x86_64.AppImage` (`packaging/linux/`)

O whisper-cli (versão fixa em `WHISPER_CPP_VERSION`) é compilado estático em cada plataforma. O
ffmpeg vem dos builds estáticos do BtbN no Windows e no Linux e é compilado do código-fonte oficial
no macOS (com cache). A versão do app vem do `version:` do `pubspec.yaml`.

## Limitações conhecidas

- Sem assinatura de código: macOS sem notarização e Windows sem certificado (ver Instalação).
- macOS só para Apple Silicon por enquanto (o runner `macos-14` é arm64).
- Arquivos sem trilha de áudio falham na etapa do ffmpeg (a mensagem de erro mostra o motivo).
- A notificação de fim usa `osascript` (macOS), `notify-send` (Linux) e um balão do PowerShell
  (Windows). No macOS ela aparece como vinda do "Script Editor".

> O workflow ainda não rodou: o projeto não tem repositório remoto. Ao subir para o GitHub,
> confira o primeiro run, principalmente o download do ffmpeg do macOS (fonte de terceiros).
