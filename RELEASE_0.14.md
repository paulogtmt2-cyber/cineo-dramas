# Cineo 0.14 — perfis públicos e comunidade

Estado: implementação em validação; APK ainda não publicado.

Perfil público redesenhado: foto circular, nome, @usuário único, selo, bio e link HTTPS, contadores de seguindo/seguidores/publicações, seguir ou deixar de seguir, compartilhamento e abas de séries e posts. A própria conta recebe Editar perfil e não pode seguir a si mesma. A verificação administrativa fica no menu de opções. Listas de pessoas, séries e posts têm paginação.

O editor permite alterar nome público, @usuário, biografia, link e foto. Os identificadores aceitam 3–24 caracteres ASCII e são únicos, sem diferenciar maiúsculas. Perfis anteriores recebem um identificador estável que pode ser personalizado. Não há email, nascimento, selfie privada ou dados de pagamento na identidade pública. Links não são buscados pelo servidor; o aplicativo abre o navegador após mostrar o domínio.

Posts de texto (até 2.000 caracteres) são publicados por criadores ativos ou administradores e passam pela fila de análise. O autor acompanha pendências e motivos de recusa e pode remover o post. Somente aprovados aparecem para terceiros. A administração aprova ou recusa com motivo, registrando a decisão. Posts e seguidores não criam visualizações nem créditos financeiros.

Links de perfil abrem a página de acesso ao app e o endereço cineo://profile/ID. Bloqueios impedem acesso ao perfil e novas conexões entre as contas. Perfis infantis recebem somente criadores com conteúdo permitido para sua idade, sem bio, link, posts ou listas de pessoas.

As funções de publicação em etapas, Clipes, missões e financeiro da versão 0.13 foram preservadas. Pagamentos continuam manuais.

Validação: 61 testes Node e testes SQL com rollback passaram, cobrindo nomes únicos, seguir idempotente, deixar de seguir, bloqueios, proibição de seguir a própria conta, posts pendentes, recusa e aprovação administrativa. Compilação, regressão Android e homologação ainda pendentes.
