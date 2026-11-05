# Cineo 0.12 — Clipes e missões de lançamento

Estado: publicado e verificado. Não confundir capturas e números sintéticos de instrumentação com métricas ou saldos de produção.

## Clipes

Aba dedicada com os primeiros episódios públicos, aprovados e tecnicamente prontos. Deslizar troca de série; um toque abre a série completa preservando progresso. O mesmo player mantém curtidas, comentários, salvar, perfil do criador, seguir, compartilhamento, legendas, qualidade, Wi-Fi e acessibilidade. Há descrição expansível e opção de desinteresse por perfil. O servidor fornece até 12 primeiros episódios por página, com links assinados, sem assinar o restante da série para o feed. Vídeos horizontais conservam proporção. Vídeos não são baixados automaticamente antes do interesse do usuário; o lote antecipa metadados e URLs dos próximos clipes. O início de uma reprodução continua sujeito à conexão.

Primeiro episódio significa a menor temporada/número; um capítulo 2 publicado não substitui um capítulo 1 ainda em análise. Faixa etária, ocultação, agendamento, suspensão do criador e curadoria são verificados no servidor. A tarifa continua R$ 0,40 por mil views elegíveis, deduplicadas por conta/episódio/dia; abrir a série depois do clipe não duplica remuneração.

## Missões

O criador aceita as regras antes de publicar. Séries em rascunho/análise entram na participação; novas séries são inscritas durante a vigência do programa. Valores iniciais: 150 centavos pela primeira série e 1 centavo por episódio. Cada série mantém a tarifa capturada ao entrar. Contas que já tinham série aprovada antes da adesão não recebem retrospectivamente o bônus de primeira série.

A publicação válida da série com pelo menos um episódio aprovado, pronto e disponível libera os créditos. Episódios adicionais entram após sua própria aprovação e publicação. Reanálise, reabertura e o mesmo caminho de mídia não geram novo crédito. O primeiro bônus é único por conta, mesmo com várias séries participantes. Rascunhos, vídeos futuros, ocultos e cadastros suspensos não liberam novos valores. Disputas em investigação suspendem novas liberações. O orçamento pode reter novos créditos, que permanecem pendentes até haver disponibilidade; já creditados não são apagados.

Bônus entram em um livro separado das views e integram o saldo disponível para saque. Pedidos reservam saldo de forma transacional; cancelamento libera a reserva. Saques continuam sujeitos ao mínimo, às regras habilitadas e ao pagamento externo manual. Nenhuma transferência bancária é executada pelo aplicativo.

## Administração

Busca por nome/título/código; verificação com motivo; curadoria de clipes por série/prioridade; relatório de sessões/views; sinal de contas com mais de cem sessões/dia para análise humana; programa de missões com pausa, tarifas, orçamento e controle de revisão; bônus manuais com confirmação e referência idempotente; histórico administrativo e financeiro. Sem teto configurado, não há um limite de orçamento automático. Pausar impede novas adesões/séries, sem revogar inscrições anteriores.

O simulador é local, identificado e não cria contas, engajamento público ou créditos. Destaques e verificados são separados de audiência. Recursos anteriores de respostas e comentários fixados, denúncias, perfil público, avisos de episódios, relatórios e saques permanecem disponíveis.

## Validação

44 testes Node, 13 verificações de cache, cenários transacionais com rollback e a regressão financeira anterior passaram. Os cenários cobrem publicação, agendamento, primeira série única entre produções, repetição, suspensão, orçamento, bônus, reserva e cancelamento. A compilação e a regressão Android passaram com 156 capturas. Nove consultas autenticadas passaram na homologação e outras nove em produção. Nenhum bônus real foi concedido nos testes.


Commit validado: `21b3170d86788c929754ea2ddc164fc4c0506c4a`.
CI: https://github.com/paulogtmt2-cyber/cineo-dramas/actions/runs/42103128674.
Servidor cineo v18: bundle `aa75111f7e7cea9fbbe1bb218385b8d6aa58b5fd4da086a4087ad029b4750cb6`.
APK: 5.971.453 bytes; SHA-256 `a8d533828a4c405d88f92e6ce973d868528dd6a575164318f407b9ba3ed82aad`.
Certificado SHA-256: `b5755f77ddaa869b456d7134296947773cc1c89b217c7933841ffe54c487bc0e`, preservado desde as versões anteriores.

## Acesso

Clipes: nova aba na navegação inferior. Missões: Perfil → Estúdio → Missões do Criador. Administração: Operações → Estúdios e financeiro → Lançamento e Clipes. Regras dos saques permanecem separadas das regras das missões.

## Download

https://njyjwcjrirqmbvsizqar.supabase.co/storage/v1/object/public/cineo-app/Cineo_Dramas_0.12.0.apk

O download público foi conferido por SHA-256 após a publicação e o endpoint de atualização anuncia version_code 12.
