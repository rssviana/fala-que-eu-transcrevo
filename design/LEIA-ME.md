# Fala que eu transcrevo! · pacote de redesign

Conteúdo:

- `HANDOFF.md`: especificação completa (tokens de cor e tipografia, as 4 telas, estados, textos, comportamento, mapeamento para Flutter, onde colocar os ícones, checklist de aceite).
- `referencia.html`: referência visual das 4 telas. Abra no navegador. É a fonte de verdade para valores exatos.
- `logo/`: ícone novo ("Onda que se acalma") pronto para Windows (.ico), macOS (PNGs do AppIcon + .icns), Linux (PNGs), o SVG fonte, a marca solta e o logo com o nome.

Paleta: Midnight Violet `#2F243A` · Vintage Grape `#444054` · Silver `#BEBBBB` · Almond Silk `#FAC9B8` · Salmon `#DB8A74`.

Fontes (não incluídas; baixe os TTF e embuta como assets, todas OFL): Bricolage Grotesque, Inter, JetBrains Mono.

## Prompt sugerido para o Claude Code

Descompacte esta pasta na raiz do projeto Flutter (por exemplo em `design/`) e envie:

> Leia `design/referencia.html` para entender o visual e depois `design/HANDOFF.md` inteiro. Implemente o redesign no app Flutter exatamente como especificado: tokens de cor e tipografia, as 4 telas e seus estados, e troque o ícone do app em Windows, macOS e Linux usando os arquivos de `design/logo/` (seção "Ícone do app"). Baixe e embuta as fontes Bricolage Grotesque, Inter e JetBrains Mono. No final, rode o app em 1120×780, tire prints das 4 telas, compare com `referencia.html` e ajuste as diferenças. Use o checklist de aceite do HANDOFF.md para confirmar que terminou.
