# Cineo / Dramas — Android 0.3

Aplicativo Android nativo em português para assistir e publicar séries, novelas e mini dramas independentes. O catálogo mostra apenas produções aprovadas. O backend ativo é a Edge Function `cineo` do Supabase; o servidor Python na pasta `backend` é um protótipo anterior e não é necessário para este APK.

## Experiência implementada

- Login, cadastro, reenvio de confirmação e alteração de senha com verificação da senha atual.
- Sessão com renovação e refresh token criptografado pelo Android Keystore. Nenhuma senha ou chave de serviço no APK.
- Início cinematográfico com acesso direto ao episódio, faixas horizontais de capas, continuar assistindo com progresso, filtros por gênero e busca em grade.
- Minha lista e curtidas sincronizadas na conta; comentários por episódio com paginação. Nome de exibição, foto e progresso continuam locais.
- Detalhes, capa, sinopse, classificação e episódios; player único com controles sobrepostos que se ocultam, barra de busca, tempo, avanço/retrocesso de 10 segundos, velocidade, próximo episódio, seletor de episódios e tela cheia.
- Estúdio do criador: criar/editar rascunho, escolher capa, enviar MP4 e acompanhar análise e justificativas.
- Administração: contadores reais, filas por situação, prévia dos episódios, aprovação e reprovação com motivo.
- Estados vazios, mensagens em português e proteção contra respostas atrasadas de uma tela anterior.

## Fluxo e permissões

Rascunho → Em análise → Publicada ou Correções solicitadas. Corrigir uma produção reprovada a devolve a rascunho. Durante a análise, a edição é bloqueada no servidor e no banco. Produções aprovadas ficam imutáveis nesta versão; não há ainda revisão de novos episódios de uma produção já publicada.

As funções SQL de transição e edição são SECURITY INVOKER e executáveis apenas pelo service_role. A Edge Function autentica o token e verifica propriedade/administrador. Vídeos e capas usam buckets privados e URLs assinadas de uma hora. A função não exige JWT na camada do gateway porque login e cadastro são públicos; todas as rotas privadas validam o usuário internamente. As tabelas sociais têm RLS e nenhuma permissão para anon/authenticated; somente o servidor autenticado as acessa, sempre usando o usuário do token. Curtidas são únicas por usuário/episódio, salvos por usuário/produção; interações exigem produção publicada e episódio pertencente a ela. Comentários públicos não expõem email nem identificador do usuário.

## Limites claros

- MP4 até 25 MiB por episódio. Recomenda-se H.264/AAC; não há transcodificação no servidor.
- Capas JPEG até 2 MiB; o app redimensiona a imagem antes do envio.
- Upload em primeiro plano, sem retomada após interrupção. Não fechar o app durante o envio.
- Progresso não sincroniza entre aparelhos. Não há notificações push, download offline, transcodificação adaptativa ou legendas automáticas. Comentários são publicados imediatamente, limitados a 1.000 caracteres; a análise prévia continua sendo das produções.
- Excluir permanentemente produções/arquivos não faz parte desta versão.
- O projeto Supabase usa o plano gratuito e seus limites; não há promessa de armazenamento ou tráfego ilimitados.
- As séries dos mockups são ilustrativas. A conta possui um rascunho técnico privado de 2 segundos para verificação, que não foi publicado.

## Build e testes

Java 17, Android SDK 35, Gradle 8.9. `gradle -p android assembleDebug assembleDebugAndroidTest` compila o aplicativo e o pacote de testes. GitHub Actions inicia Android 15/API 35 em um Pixel 6 virtual e executa o teste de telas e reprodução com fixtures somente no pacote de testes. O script `ci/android-ui.sh` guarda capturas e exige sucesso antes de disponibilizar o APK.

Validação real do backend em 31/10/2026: login e role admin, renovação de sessão, catálogo/produções/contadores, envio e leitura assinada de capa e MP4, declaração de direitos obrigatória, envio para fila, bloqueio de edição pendente, reprovação com motivo, correção para rascunho e ausência de rascunhos no catálogo. A aprovação e a rejeição de um ator não autorizado foram verificadas em uma transação revertida, sem publicar conteúdo de teste.

A verificação de senhas comprometidas do Supabase continua desativada na configuração da conta. Referência: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Instalação

O artefato `Cineo-Dramas-APK` contém um APK de teste. A chave de debug passa a ser reutilizada por cache do workflow, mas pode ser diferente da versão 0.1 já instalada. Se Android informar conflito de assinatura, remover a versão antiga e instalar a nova resolve; a conta e produções continuam no Supabase. A distribuição pela Play Store requer assinatura de release privada e preparação própria.
