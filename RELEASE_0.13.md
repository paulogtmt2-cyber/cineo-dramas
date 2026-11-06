# Cineo 0.13 — criação em etapas e painel administrativo

Estado: publicado e verificado.

## Criadores

Há acesso ao Estúdio na navegação inferior e a “Quero ser criador” nas ferramentas do perfil. O cadastro continua privado (nome, sobrenome, nascimento e selfie); a liberação automática existente é distinta da análise de cada produção. Não há reconhecimento facial ou prova biométrica de identidade. A administração mantém a suspensão do acesso.

Após a liberação, o estúdio mostra as produções por situação, com botão + à direita e atalhos para resultados, missões e envios. A criação segue três etapas:

1. Ficha: título, capa, descrição, formato (série, novela, minissérie ou drama), gênero e classificação.
2. Capítulos: seleção de vários MP4, títulos e numeração na fila, envio em partes retomáveis e acompanhamento da validação técnica. Limite de 1.000 capítulos por produção, protegido no banco; listas e fila exibem vinte por página.
3. Ferramentas opcionais e revisão: identidade visual, trailer/estreia, temas e avisos, créditos/downloads, colaboradores, legendas/áudio/agendamento, documentos, enquetes, revisões e resultados. O criador confirma direitos e envia a produção à análise, sem publicação automática.

Rascunho de ficha é recuperável no mesmo aparelho; imagens ainda não enviadas ficam em cache e podem precisar de nova seleção se o Android limpar o cache. Identificador por rascunho evita criar uma nova produção a cada tentativa de salvamento. Uploads continuam exigindo aplicativo aberto e MP4 de até 25 MB por arquivo; o limite de capítulos não amplia a cota de armazenamento do projeto.

Novos capítulos de séries já publicadas podem ser enviados em conjunto para análise, sem retirar os capítulos anteriores do ar. Séries enviadas à análise ficam bloqueadas para edição. Envios incompletos podem ser cancelados no estúdio; a finalização trava o envio e marca o capítulo concluído na mesma transação, preservando arquivos já concluídos. Recusa mantém o motivo e permite corrigir e reenviar. Não há limite artificial de número de séries por criador ativo, respeitando as cotas do serviço e as regras de publicação.

## Administração

Painel com seis áreas sempre visíveis, sem depender de rolagem horizontal: Resumo, Análises, Criadores, Financeiro, Catálogo e Sistema. Busca local por função, contadores reais e gráfico de views válidas em 7/30/90 dias. Perfis contam os cadastros públicos existentes, e criadores ativos contam os acessos aprovados; nenhuma métrica é inventada.

As filas de produções e capítulos oferecem pesquisa por título, filtros por situação e paginação. A revisão mostra capa, ficha, condição técnica e prévias, assinando somente os vinte capítulos da página. Aprovação exige confirmação da revisão, validação técnica e acesso ativo do criador; recusa exige motivo. Decisões passam pela transação de moderação existente, com histórico e aviso ao criador. A equipe delegada mantém os casos atribuídos na central anterior.

Missões, visualizações elegíveis, bônus e saques da versão 0.12 permanecem separados e preservados; pagamentos externos continuam manuais.

## Validação

53 testes Node passaram. Testes SQL de rascunho idempotente, permissão, direitos, mídia, envio direto para o painel, recusa/reenvio/aprovação, suspensão, novos capítulos e limite de 1.000 foram concluídos com rollback, sem publicar arquivos ou gerar pagamentos de teste persistentes. Compilação e regressão Android passaram com 170 capturas e 13 verificações de cache. Onze consultas autenticadas passaram na homologação. A implantação de produção utiliza o mesmo bundle validado; uma rodada adicional de consultas autenticadas em produção foi interrompida pelo ambiente antes de gerar resultado, portanto não é contabilizada como concluída.


Commit Android validado: `e9e42aadc861f577d284172d70d60e3c6f25ca4d`.
CI: https://github.com/paulogtmt2-cyber/cineo-dramas/actions/runs/42112039897.
Servidor cineo v20: bundle `ae7177131cce5382453ab8b9f93d1301d34748adf2f7c42727d53db7a994529a`.
O ajuste final de cancelamento por titular/colaborador foi validado nos 53 testes Node locais e na implantação da função; não altera o binário Android já testado.
APK: 6.004.377 bytes; SHA-256 `61bbd163351e989625b5dab59b56b4f54dd156074257edbed017438bbcb8001c`.
Certificado SHA-256: `b5755f77ddaa869b456d7134296947773cc1c89b217c7933841ffe54c487bc0e`, igual ao das versões recentes.

## Acesso

Criador: Estúdio na barra inferior ou Perfil → Estúdio → Quero ser criador. Após liberação, + → Ficha → Capítulos → Ferramentas → Mandar produção para análise.
Administrador: Perfil → Administração → Análises → Produções em análise. Resumo, Análises, Criadores, Financeiro, Catálogo e Sistema ficam sempre visíveis.

## Download

https://njyjwcjrirqmbvsizqar.supabase.co/storage/v1/object/public/cineo-app/Cineo_Dramas_0.13.0.apk

O download público foi conferido por SHA-256 e o endpoint de atualização anuncia version_code 13.
