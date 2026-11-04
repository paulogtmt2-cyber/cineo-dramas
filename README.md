# Cineo / Dramas — Android 0.6

Aplicativo Android nativo em português para assistir e publicar séries, novelas e mini dramas independentes. O catálogo mostra apenas produções aprovadas. O backend ativo é a Edge Function `cineo` do Supabase; o servidor Python na pasta `backend` é um protótipo anterior e não é necessário para este APK.

## Experiência implementada

- Login, cadastro, reenvio de confirmação e alteração de senha com verificação da senha atual.
- Sessão com renovação e refresh token criptografado pelo Android Keystore. Nenhuma senha ou chave de serviço no APK.
- Início cinematográfico com acesso direto ao episódio, faixas horizontais de capas, continuar assistindo com progresso, filtros por gênero e busca em grade.
- Minha lista e curtidas sincronizadas na conta; comentários por episódio com paginação. Perfil público (nome, foto e biografia), progresso, curtidas e lista sincronizam com a conta. O progresso também tem cópia local.
- Detalhes, capa, sinopse, classificação e episódios; player único com controles sobrepostos que se ocultam, barra de busca, tempo, avanço/retrocesso de 10 segundos, velocidade, próximo episódio, seletor de episódios e tela cheia.
- Estúdio do criador: criar/editar rascunho, escolher capa, enviar MP4 e acompanhar análise e justificativas.
- Administração: contadores reais, filas por situação, prévia dos episódios, aprovação e reprovação com motivo.
- Estados vazios, mensagens em português e proteção contra respostas atrasadas de uma tela anterior.

## Fluxo e permissões

Rascunho → Em análise → Publicada ou Correções solicitadas. Corrigir uma produção reprovada a devolve a rascunho. Durante a análise, a edição é bloqueada no servidor e no banco. Produções aprovadas recebem capítulos novos pelo estúdio: rascunho do capítulo → análise → aprovação ou correção. Os capítulos anteriores continuam publicados. Mídias de capítulos publicados e em análise ficam bloqueadas para edição.

As funções SQL de transição e edição são SECURITY INVOKER e executáveis apenas pelo service_role. A Edge Function autentica o token e verifica propriedade/administrador. Vídeos e capas usam buckets privados e URLs assinadas de uma hora. A função não exige JWT na camada do gateway porque login e cadastro são públicos; todas as rotas privadas validam o usuário internamente. As tabelas sociais têm RLS e nenhuma permissão para anon/authenticated; somente o servidor autenticado as acessa, sempre usando o usuário do token. Curtidas são únicas por usuário/episódio, salvos por usuário/produção; interações exigem produção publicada e episódio pertencente a ela. Comentários públicos não expõem email nem identificador do usuário.

## Limites claros

- MP4 até 25 MiB por episódio. Recomenda-se H.264/AAC; não há transcodificação no servidor.
- Capas JPEG até 2 MiB; o app redimensiona a imagem antes do envio.
- Upload em primeiro plano, sem retomada após interrupção. Não fechar o app durante o envio.
- A central de avisos é interna ao aplicativo; não há push em segundo plano. Compartilhamento usa links cineo:// e requer o app instalado. Vídeos não têm download offline ou transcodificação automática. O criador envia versões econômicas MP4 e legendas WebVTT (até 200 KB); capítulos já publicados ficam imutáveis. Comentários são imediatos, com respostas, curtidas, spoiler e denúncia.
- Excluir permanentemente produções/arquivos não faz parte desta versão.
- O projeto Supabase usa o plano gratuito e seus limites; não há promessa de armazenamento ou tráfego ilimitados.
- As séries dos mockups são ilustrativas. A conta possui um rascunho técnico privado de 2 segundos para verificação, que não foi publicado.

## Build e testes

Java 17, Android SDK 35, Gradle 8.9. `gradle -p android assembleDebug assembleDebugAndroidTest` compila o aplicativo e o pacote de testes. GitHub Actions inicia Android 15/API 35 em um Pixel 6 virtual e executa o teste de telas e reprodução com fixtures somente no pacote de testes. O script `ci/android-ui.sh` guarda capturas e exige sucesso antes de disponibilizar o APK.

Validação real do backend em 31/10/2026: login e role admin, renovação de sessão, catálogo/produções/contadores, envio e leitura assinada de capa e MP4, declaração de direitos obrigatória, envio para fila, bloqueio de edição pendente, reprovação com motivo, correção para rascunho e ausência de rascunhos no catálogo. A aprovação e a rejeição de um ator não autorizado foram verificadas em uma transação revertida, sem publicar conteúdo de teste.

A verificação de senhas comprometidas do Supabase continua desativada na configuração da conta. Referência: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Instalação

O artefato `Cineo-Dramas-APK` contém um APK de teste. A chave de debug passa a ser reutilizada por cache do workflow, mas pode ser diferente da versão 0.1 já instalada. Se Android informar conflito de assinatura, remover a versão antiga e instalar a nova resolve; a conta e produções continuam no Supabase. A distribuição pela Play Store requer assinatura de release privada e preparação própria.

## Novidades da versão 0.4

- Trailers, temporadas, número do capítulo, duração e retomada sincronizada.
- Seguir criadores/séries, aba Seguindo, central de avisos e calendário de estreias no fuso do aparelho.
- Perfil público com nome, biografia e foto JPEG ajustada até 130 KB; email não aparece publicamente.
- Estúdio para novos capítulos, mídias econômicas, WebVTT e revisão independente. O capítulo de série publicada começa privado e só entra no catálogo após aprovação.
- ADM escolhe destaque e coleções por título, ordena ou oculta coleções e analisa denúncias. Ocultar/restaurar conteúdo é reversível; não existe exclusão permanente.
- Estatísticas calculadas no banco por produção: espectadores distintos com progresso registrado, conclusões por usuário/episódio e curtidas. Não são estimativas de audiência total e dependem do envio de progresso pelo app.
- Player com dois toques para buscar, gesto vertical na lateral direita para volume, trava de toques, tamanho/ativação de legendas e escolha de qualidade.
- Carregamento com espaços reservados para capas, transições suaves, resposta ao toque e botão de tentar novamente em falhas de requisição.

O destaque utiliza somente produções aprovadas e liberadas. Estreias aprovadas aparecem no calendário; vídeos só são liberados na data. As tabelas novas têm RLS e acesso direto negado a anon/authenticated. A API valida o usuário e a autorização em cada rota. Funções de revisão, agregação e notificações são SECURITY INVOKER e somente service_role pode executá-las.

Verificação 0.4: teste Android com 36 capturas, decodificação H.264, busca no vídeo, tela cheia preservando posição, velocidade, comentário, legendas, trava, importação do progresso e link de série. A API real foi verificada em 14 leituras autenticadas, bloqueio anônimo e entradas inválidas. Revisão de capítulo, notificação e estatísticas foram testadas em transação revertida, sem publicar conteúdo fictício.

## Player vertical 0.5

A tela de assistir agora é um player de dramas vertical: vídeo com ajuste de proporção, ações na lateral, título/sinopse sobrepostos, barra de busca discreta e seletor de episódios em painel inferior. Não há cartões ou botões grandes abaixo do vídeo. Contagens vêm da API; nenhuma audiência é simulada no APK.

Deslizar para cima avança um capítulo e para baixo retorna. Um gesto muda apenas um capítulo, preserva o progresso do anterior e respeita primeiro/último capítulo. A área da barra de busca fica fora do reconhecimento de troca vertical. Toque pausa/retoma, dois toques buscam 10 segundos. O volume está em Mais e nos botões do aparelho. A trava de toques bloqueia troca de capítulo, botões e busca, com uma ação visível de desbloqueio.

O menu Mais reúne velocidade, qualidade, legendas, volume, trava, barras do sistema, compartilhar e denunciar. Apenas episódios fornecidos pela API para o usuário atual entram na sequência. Prévia privada não recebe interações públicas.

## Experiência completa 0.6

1. Capas por rota autenticada com cache local, mensagem de erro e nova tentativa. A imagem original existente foi conferida: JPEG 836×470, HTTP 200.
2. Editor de enquadramento com arraste, zoom e prévia. Cartaz 2:3 e banner 16:9 têm arquivos separados.
3. Categorias criadas, ordenadas, ativadas ou ocultadas pelo ADM; vinculação por produção.
4. Busca por texto/criador, gênero, classificação, categoria, duração total conhecida e série concluída.
5. Histórico paginado por conta, retomada e remoção individual do progresso.
6. Marcação manual de assistido ou não assistido pelo histórico e pelas opções do episódio.
7. Reprodução automática configurável, contagem regressiva de 5 segundos e cancelamento.
8. Temporizador de 15/30/60 minutos ou fim do episódio.
9. Modo de foco oculta sinopse e ações, com botão para restaurá-las.
10. Preferências de gêneros na primeira entrada e edição posterior.
11. Recomendações pelos gêneros escolhidos e produções semelhantes ao gênero da série.
12. Nota de 1 a 5 por usuário/produção, média e quantidade reais calculadas no banco.
13. Coleções pessoais com nome, renomeação, inclusão e retirada de séries.
14. Até três comentários fixados por criador; primeira página os apresenta antes dos demais.
15. Bloqueio/desbloqueio de contas; comentários bloqueados são filtrados pelo servidor.
16. Suporte: WhatsApp +55 21 96691-3668 e protocolos persistentes com respostas do ADM no app. O WhatsApp abre um rascunho; o usuário confirma o envio.
17. Histórico de mudanças de situação de produções/capítulos com data e motivo. Registros novos são gerados no banco; produções antigas têm um registro da situação anterior à atualização.
18. Fila de múltiplos MP4 com título/numeração editáveis, situação por arquivo e nova tentativa. IDs estáveis evitam duplicação se a resposta de um envio se perder.
19. Diagnóstico do player distingue falha de conexão, arquivo inválido e formato incompatível.
20. Página de versões e novidades, com link de download quando existe uma versão superior.

Limites: uploads e fila funcionam em primeiro plano; manter o app aberto. Após interrupção, a nova tentativa reenvia o arquivo inteiro, não continua do byte anterior. A fila e preferências do player são locais e separadas por conta; listas, avaliações, bloqueios, histórico, interesses e protocolos ficam na conta. Não há conversão automática de qualidade ou de legendas. Duração desconhecida não entra no filtro por tempo. Os arquivos continuam limitados a MP4 25 MB, imagens JPEG 2 MB e legendas WebVTT 200 KB.

As novas tabelas têm RLS e acesso direto negado aos clientes; a Edge Function valida o usuário e a propriedade/administrador. O APK de teste publicado fica em um bucket público dedicado, sem incluir credenciais ou mídias privadas. A publicação de uma atualização é restrita ao ADM.
