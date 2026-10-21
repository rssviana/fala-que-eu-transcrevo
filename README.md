# Fala que eu transcrevo!

App desktop (macOS, Windows e Linux) que transcreve vídeos **localmente e offline**
usando o [Whisper](https://github.com/openai/whisper) via
[whisper.cpp](https://github.com/ggml-org/whisper.cpp). Nada sai do computador.

Nomes técnicos: pasta e pacote Dart `transcritor`, bundle id `dev.rssviana.transcritor`,
executável `transcritor` no Windows e no Linux.

## Como funciona

1. Você arrasta (ou escolhe) um arquivo de vídeo local — mp4, mov, mkv, webm, avi…
2. Escolhe o idioma (padrão: português do Brasil, ou "Detectar automaticamente") e o modelo.
3. O **ffmpeg** extrai o áudio em WAV 16 kHz mono para uma pasta temporária.
4. O **whisper-cli** transcreve. O progresso vem do parse da saída dos dois processos.
5. O texto aparece na tela; dá para copiar e exportar:
   - **.txt** — texto corrido, um trecho por linha
   - **.srt** — legenda com tempos
   - **.md** — Markdown com título, idioma, modelo, data e parágrafos com tempo de início
   - **.pdf** — mesmo conteúdo do Markdown, em A4, com a fonte Noto Sans embutida
     (cobre latim, grego e cirílico; japonês e outros alfabetos não aparecem no PDF)

Os modelos ggml **não vão no instalador**: são baixados do Hugging Face no primeiro uso
para a pasta de suporte do app (no macOS,
`~/Library/Application Support/dev.rssviana.transcritor/models`).

| Modelo | Tamanho | Observação |
|---|---|---|
| Tiny | ~75 MB | Muito rápido, precisão baixa |
| Base | ~142 MB | Rápido, bom para testes |
| Small (padrão) | ~466 MB | Equilíbrio |
| Medium | ~1,5 GB | Mais preciso, mais lento |
| Large v3 Turbo (q5) | ~547 MB | Ótima precisão, compacto |
| Large v3 Turbo | ~1,6 GB | Melhor precisão |

## Desenvolvimento

Requisitos: Flutter 3.38+, e `ffmpeg` + `whisper-cli` instalados.

```bash
brew install ffmpeg whisper-cpp   # macOS
flutter pub get
flutter test
flutter run -d macos
```

No macOS o projeto usa **Swift Package Manager** para os plugins (veja `flutter: config:` no
`pubspec.yaml`), então não precisa de CocoaPods. O App Sandbox está **desligado** nos
entitlements: o app precisa executar ffmpeg/whisper-cli e ler vídeos de qualquer pasta, o que
não combina com o sandbox. Isso impede publicar na Mac App Store, mas não a distribuição direta.

### Estrutura

```
lib/
  main.dart
  src/core/            # Dart puro, testado em test/
    catalog.dart         # modelos, idiomas, extensões aceitas
    binary_locator.dart  # onde procurar ffmpeg e whisper-cli
    commands.dart        # argumentos do ffmpeg e do whisper-cli
    progress.dart        # parse de progresso e segmentos
    export.dart          # .txt, .srt, .md e agrupamento em parágrafos
    pdf_export.dart      # .pdf (pacote pdf, fontes em assets/fonts)
    transcriber.dart     # pipeline com Process.start + cancelamento
    model_store.dart     # download dos modelos (HttpClient, .part → rename)
  src/ui/              # Flutter
    controller.dart      # estado da tela (ChangeNotifier)
    home_page.dart
```

## Onde o app procura os binários

Em ordem, parando no primeiro encontrado (`lib/src/core/binary_locator.dart`):

1. **Pasta empacotada com o app**
   - macOS: `Fala que eu transcrevo!.app/Contents/Resources/bin/`
   - Windows e Linux: `bin/` ao lado do executável
2. `PATH` do sistema
3. Pastas comuns: `/opt/homebrew/bin`, `/usr/local/bin` (macOS); `/usr/local/bin`, `/usr/bin`,
   `/snap/bin` (Linux). Apps abertos pelo Finder não herdam o `PATH` do shell, por isso o
   fallback.

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

> O workflow ainda não rodou: o projeto não tem repositório remoto. Ao subir para o GitHub,
> confira o primeiro run, principalmente o download do ffmpeg do macOS (fonte de terceiros).
