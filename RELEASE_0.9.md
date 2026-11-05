# Cineo 0.9 — tempo de abertura e navegação

Alterações Android preparadas e compiladas localmente. Ainda não há um APK 0.9 assinado para atualizar o 0.8, nem execução dos testes de interface da versão 0.9 no emulador. O proprietário autorizou continuar a publicação do código no repositório público para executar a validação e gerar o APK atualizado.

## Alterações concretas

- Tela inicial usa `/v9/start`: catálogo inicial, perfil, preferências, progresso e faixas em uma resposta. As consultas internas independentes são executadas em paralelo. Paginação em lotes de 24 produções por demanda.
- Snapshots isolados por conta e espectador, com limite de tamanho, validade e limpeza no logout. Dados de autenticação, aparelhos e administração não são armazenados nesse cache. Perfis infantis não usam cache persistente em disco.
- Conteúdo recente aparece primeiro; a atualização acontece em segundo plano. O callback de uma lista não é repetido para anexar itens em duplicidade. A tela inicial atualiza o conteúdo e preserva a posição.
- Leituras usam uma fila separada de uploads e operações de escrita. Consultas de telas abandonadas são descartadas e suas conexões canceladas. Consultas não ativam o bloqueio dos botões de navegação.
- Capas usam primeiro a imagem em memória ou disco e depois o endereço assinado. A API autenticada com base64 fica como recuperação para um endereço expirado. Imagens fora da área visível não são baixadas. Solicitações do mesmo arquivo são agrupadas; o tamanho da decodificação acompanha o uso.
- Assinaturas de imagens e vídeos são obtidas em lotes no servidor, incluindo temporadas, versões de qualidade e áudio. O processo é limitado a quatro lotes simultâneos.
- Curtidas e salvos respondem antes da confirmação, com reversão em caso de falha. Dados recentes do feed são preservados após a ação; listas alteradas são atualizadas.
- Histórico de pesquisas por espectador, com exclusão disponível. Sugestões locais usam o catálogo já recebido enquanto a busca completa consulta o servidor.
- Medição local de consultas e leituras do conteúdo salvo em Preferências → Velocidade do aplicativo. A identificação de versão usa o pacote instalado.
- Funções existentes de classificação, séries, publicação, moderação, privacidade, legendas, continuidade e preparação do próximo episódio foram preservadas.

## Verificação realizada

- 18 testes Node do servidor passaram. Incluem proteção de perfis infantis e equipe, paginação, resposta inicial, assinatura em lotes e concorrência limitada.
- 13 verificações JVM do código real de cache passaram: leitura imediata, persistência, conta/espectador, exclusão de dados privilegiados, invalidação após escrita, descarte de respostas antigas e limpeza no logout.
- Compilação do aplicativo Android e dos testes instrumentados passou localmente com JDK 17 e SDK 35. Esses testes instrumentados foram atualizados para verificar abertura sem rede e navegação durante uma consulta demorada, mas ainda não foram executados no emulador para esta versão.
- Homologação autenticada verificou `/v9/start`, `/v9/catalog`, capítulos, preferências de perfil e área administrativa existente. As URLs dos vídeos e das capas foram conferidas sem alterar produções publicadas.
- Medição do caminho de abertura pela rede deste ambiente: sete respostas sequenciais somaram 46.499 ms; a nova resposta principal levou 5.588 ms. Isso não é um benchmark do telefone do usuário e exclui restauração de autenticação, desenho da tela e início do vídeo.
- O servidor de produção recebeu o pacote idêntico ao validado na homologação v5: produção v15, bundle `e809d06b49f6db5330322611374576c205e2db8311e99304b108ebde579cb9c4`. O APK 0.8 continua compatível; o novo fluxo e o cache Android dependem do futuro APK 0.9.

## Limites

Conteúdo ainda não recebido e o início de novos vídeos dependem da rede. O cache evita repetir esperas por conteúdo recente, sem prometer abertura instantânea de informação inédita. A assinatura de atualização está no fluxo existente de compilação do repositório; não foi criada outra chave nem solicitado que o usuário desinstale o aplicativo.
