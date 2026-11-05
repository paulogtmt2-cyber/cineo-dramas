# Cineo 0.12 — Clipes e missões de lançamento

Estado: implementação em validação. Não confundir capturas e números sintéticos de instrumentação com métricas ou saldos de produção.

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

44 testes Node e cenários transacionais com rollback passaram (publicação, agendamento, repetição, suspensão, orçamento, bônus, reserva e cancelamento). Compilação Android, 156 capturas previstas, homologação e APK final ainda pendentes.
