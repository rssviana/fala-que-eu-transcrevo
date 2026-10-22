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

## Modelos

Os modelos do Whisper não vão no instalador: o app baixa o escolhido no primeiro uso.

| Modelo | Tamanho | Rapidez | Precisão |
|---|---|---|---|
| Tiny | ~75 MB | 5 | 1 |
| Base | ~142 MB | 4 | 2 |
| Small (recomendado) | ~466 MB | 3 | 3 |
| Medium | ~1,5 GB | 2 | 4 |
| Large Turbo | ~1,5 GB | 2 | 5 |

Eles ficam na pasta `models` dentro da pasta de dados do app:

- macOS: `~/Library/Application Support/dev.fqet.falaqueeutranscrevo/models`
- Windows: `%APPDATA%\dev.fqet.falaqueeutranscrevo\models`
- Linux: `~/.local/share/dev.fqet.falaqueeutranscrevo/models`

## Contribua

Quer rodar o projeto, entender o código ou ajudar? Veja o [guia de contribuição](contribua.md).
