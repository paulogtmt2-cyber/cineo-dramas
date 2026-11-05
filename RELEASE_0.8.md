# Cineo 0.8 — perfil, biblioteca e estúdio

A versão reorganiza o perfil em Biblioteca, Estúdio e Conta. Cada área usa seis atalhos, busca de ferramentas e personalização. O email só aparece ao abrir Dados da conta. Administração tem entrada própria e permissões verificadas no servidor.

## Recursos entregues

| Área | Implementação |
| --- | --- |
| Perfil | Identidade compacta, foto, troca de espectador, seis atalhos por área, ícones vetoriais, pesquisa por função, atalhos personalizáveis, resumo de pendências. |
| Biblioteca | Assistindo, salvas, seguindo, concluídas e abandonadas; ocultar/retomar a faixa Continue assistindo sem apagar o histórico; controle de interesse; cenas salvas; tempo restante e histórias que cabem no tempo disponível. |
| Player | Superfície vertical com deslize entre capítulos, curtidas, comentários, salvos, seletor de episódios, velocidade, qualidade, legendas, áudio, foco e temporizador. Preferência de orientação, deslize menos sensível, lembrete de maratona e aviso ao mudar de Wi-Fi para dados móveis. Resumo do criador ao retomar um capítulo e marcadores de cenas. |
| Descoberta | Sugestões durante a digitação, tolerância a pequenos erros, temas, filtros avançados, calendário pessoal, situação da publicação e coleções editoriais com descrição. Recomendações explicadas e controladas pelo espectador. |
| Estúdio | Visão de produções e processamento, assistente em três etapas, rascunho local e sincronizado, modelos de ficha, prévia, reaproveitamento de temporada/numeração, ordem visual por temporada, lacunas na sequência, materiais, recap e enquetes. |
| Equipe | Casos de produções, capítulos, revisões, recursos, denúncias e suporte. Atribuição a revisores ou atendimento, prioridades, notas internas, motivos padronizados, prévia, checklist e histórico de decisões. Reabertura de denúncia para reavaliar ou restaurar. |
| Operações | Avisos com validade sem reinstalação, pesquisas de satisfação, novidades por versão com atalhos, distribuição gradual de recursos, indicadores de reprodução e backups de metadados criptografados. |
| Segurança e recuperação | Preferências isoladas por espectador, progresso com horário da observação e proteção contra eventos antigos, recuperação de envios interrompidos, processamento priorizado, limpeza confirmada de partes temporárias e SHA-256 dos originais processados. Revisões preservam a versão pública enquanto aguardam análise. |

## Verificação

- Testes nativos no Android 15/API 35, emulador Pixel 6: 104 capturas e fluxo de reprodução com MP4 H.264, gestos, limites da sequência, bloqueio, barra de progresso, comentários e telas de conta/criação/administração.
- Asserção de geometria: seis atalhos e a entrada de administração cabem acima da navegação, sem rolagem, no tamanho e escala de texto padrão do emulador. Em escalas de acessibilidade maiores, o conteúdo pode rolar para preservar legibilidade.
- 13 testes de limites do servidor: perfil infantil, sessão, proprietário, equipe, downloads autorizados, worker assinado, busca, progresso, conflitos, atalhos e envios cancelados.
- SQL transacional com rollback: troca de capítulos, progresso antigo ignorado, equipe não atribuída bloqueada, aprovação de revisão, ocultação e restauração auditadas, atendimento, apuração de votos, limite de ações e recuperação apenas de registros ausentes.
- Testes FFmpeg: arquivo válido decodificado e convertido; arquivo corrompido rejeitado.
- Endpoints autenticados conferidos em homologação sem editar a série publicada. Chaves administrativas e senha não são incluídas no APK.

## Conferência visual

| Ponto | Resultado e decisão |
| --- | --- |
| Estrutura | A mesma ordem do conceito: identidade, busca, três áreas, seis ferramentas, administração e navegação fixa. Nenhuma pilha antiga de menus foi acrescentada ao perfil. |
| Geometria | Duas colunas e três linhas, espaçamento consistente, alvos de toque maiores que 48 dp. Entrada administrativa visível sem arrastar a tela no emulador padrão. |
| Tipografia | Nome com truncamento de segurança; títulos das ferramentas legíveis; descrições curtas; email oculto na superfície principal. Nome real vem da conta e não é uma métrica fictícia. |
| Cores | Fundo #090D14, superfícies #131C27, bordas #273240 e destaque #F20D46. A marca DRAMAS permanece rosa para manter a identidade do aplicativo. |
| Ícones | Família vetorial própria nos atalhos; lupa na busca; Biblioteca identificada como biblioteca na barra inferior. Imagem gerada é somente referência, não uma tela rasterizada. |
| Navegação | Biblioteca, Estúdio e Conta preservam o contexto e abrem ferramentas reais. Busca de ferramentas pagina resultados em grupos de seis. |
| Ambiente | Projeto Android nativo existente; verificação feita com instrumentação Android e capturas do emulador, em vez de um navegador. |

## Limites da entrega

Chromecast, PiP, notificações do sistema e troca real entre redes usam APIs Android. A validação automatizada não substitui a conferência em televisão e aparelho físico. Downloads dependem da autorização do criador. Processamento depende da fila do serviço. O backup cobre metadados; vídeos, arquivos de imagens e contas/senhas de autenticação ficam fora. A restauração adiciona registros ausentes e preserva os dados existentes.

A revisão do banco não encontrou nova exposição de tabelas privadas. RLS sem políticas é intencional nessas tabelas: acesso direto por anon/authenticated foi revogado, e as operações passam pela API autenticada. A proteção opcional contra senhas vazadas já estava desabilitada no projeto: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection.


## Identificação da entrega

- Código Android e validação nativa: `a41a37d728efde91bcaac26addd86b4a3629d0d3`.
- Execução Android: `42028633799`, concluída com sucesso. Instrumentação: `OK (1 test)`, 104 capturas, 97,654 segundos no teste.
- 32 verificações autenticadas passaram na homologação. Correção de backup conferida adicionalmente com a identidade real de serviço: descriptografia e teste de restauração de 38 tabelas, sem aplicar alterações.
- API final: produção v14, mesmo pacote da homologação v4, `ezbr_sha256=3180d143d52c04bb87498fb75127cb8ce344a3d966574e204f9553c647e3ff63`.
- Correção de permissões: a API usa Auth Admin para verificar as contas referenciadas; nenhuma permissão SELECT em `auth.users` foi concedida. A restauração mantém as chaves estrangeiras e verifica solicitações de exclusão.
- APK: 5.873.541 bytes, SHA-256 `06a526aaff92bc2c87b263a463744d05dc5fcbfec861b1e956ff7c6a8ae90478`.
- Certificado de assinatura: `b5755f77ddaa869b456d7134296947773cc1c89b217c7933841ffe54c487bc0e`, igual à versão 0.7 para instalação como atualização.
