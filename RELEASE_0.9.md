# Cineo 0.9 — tempo de abertura e navegação

APK 0.9.0 (versionCode 9) compilado e testado no Android API 35. Código publicado com autorização do proprietário. Validação automática concluída: [execução 42043072447](https://github.com/paulogtmt2-cyber/cineo-dramas/actions/runs/42043072447), commit `d1fa64d91fa41fbf8ab081e8678219454abcb53e`.

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
- Compilação do aplicativo Android e dos testes instrumentados passou localmente com JDK 17 e SDK 35. A execução no emulador API 35 também passou: regressão instrumentada de telas e player, 107 capturas, abertura imediata com conteúdo salvo sem rede e navegação durante uma consulta artificialmente demorada. As verificações de interface usam dados de teste; os endpoints reais foram verificados separadamente.
- Homologação autenticada verificou `/v9/start`, `/v9/catalog`, capítulos, preferências de perfil e área administrativa existente. As URLs dos vídeos e das capas foram conferidas sem alterar produções publicadas.
- Medição do caminho de abertura pela rede deste ambiente: sete respostas sequenciais somaram 46.499 ms; a nova resposta principal levou 5.588 ms. Isso não é um benchmark do telefone do usuário e exclui restauração de autenticação, desenho da tela e início do vídeo.
- O servidor de produção recebeu o pacote idêntico ao validado na homologação v5: produção v15, bundle `e809d06b49f6db5330322611374576c205e2db8311e99304b108ebde579cb9c4`. O APK 0.8 continua compatível; o novo fluxo e o cache Android estão incluídos no APK 0.9.

## Limites

Conteúdo ainda não recebido e o início de novos vídeos dependem da rede. O cache evita repetir esperas por conteúdo recente, sem prometer abertura instantânea de informação inédita. A assinatura do APK foi validada com apksigner e comparada ao 0.8: certificado SHA-256 `b5755f77ddaa869b456d7134296947773cc1c89b217c7933841ffe54c487bc0e`. A atualização pode ser instalada sobre a versão anterior. APK: 5.889.829 bytes; SHA-256 `c7a0e9d8afd0f05b937bf9f9f2941abe5e1179116241182a6fcbb0870320b505`.

## Download publicado

[Instalar Cineo 0.9.0](https://njyjwcjrirqmbvsizqar.supabase.co/storage/v1/object/public/cineo-app/Cineo_Dramas_0.9.0.apk). Os bytes recebidos do endereço público foram comparados ao APK validado; a API de atualização confirmou versionCode 9.
