# Cineo 0.10 — Estúdio do Criador

Implementação: cadastro privado em duas etapas (informações e selfie), liberação automática após o prazo de um minuto medido pelo servidor, suspensão/restauração pelo administrador com histórico, indicadores próprios, estimativas e views públicas por série. A selfie não faz reconhecimento facial ou prova de identidade, não altera o selo de verificado e não é exibida publicamente. Cadastro disponível a maiores de 18 anos declarados.

A contagem começa nesta versão; não há views retroativas fabricadas. Uma view válida por conta/episódio/dia, após 10 segundos de reprodução ou 80% dos vídeos menores. O servidor limita o crédito ao tempo decorrido, progresso e tempo ativo informado; existem proteções básicas, não uma auditoria antifraude completa. Visualizações próprias não contam. A tarifa de cada crédito é registrada: 40 centavos por mil views, equivalente a 0,04 centavo por view. Arredondamento apenas na apresentação. O total é uma estimativa, sem saque ou pagamento automático. Views de criadores ainda não aprovados ou suspensos não geram estimativa. A exclusão da conta do espectador anonimiza o registro e preserva agregados.

Dados de nome civil, nascimento e selfie ficam fora do perfil público e do cache de navegação. A selfie usa bucket privado e URL temporária de dois minutos exclusiva do administrador. A rotina de manutenção remove fotos após 30 dias; retirar o cadastro remove a selfie imediatamente. Telas de selfie e cadastro administrativo bloqueiam capturas no Android. Exclusão da conta também remove a foto. Exportação de privacidade inclui os dados próprios do cadastro.

Resultados não usam amostras fictícias no aplicativo real. Os testes de UI usam fixtures; o teste transacional do banco desfaz todos os registros criados. Os 24 testes Node, 13 testes JVM de cache, testes transacionais SQL e a regressão instrumentada no Android API 35 passaram. A execução gerou 113 capturas, incluindo entrada, informações, envio da selfie com imagem de teste, espera sem cronômetro, métricas, suspensão e administração. A tela privada da selfie usa FLAG_SECURE e não foi capturada; o teste verificou essa proteção e o envio do JPEG de teste. A captura de selfie não testa reconhecimento facial ou liveness, recursos que não foram implementados.


## Artefato validado

- Commit do APK: `3a9006a2930334f1add18a5f5e8bee7152abe377`.
- [Validação Android](https://github.com/paulogtmt2-cyber/cineo-dramas/actions/runs/42052179337).
- APK 0.10.0 / versionCode 10: 5.905.349 bytes, SHA-256 `e1f53f5b17b0bb0f41742ddf9506eb5a2af134e73eae38907bf87e1e5145bfad`.
- Certificado de atualização conferido com apksigner: `b5755f77ddaa869b456d7134296947773cc1c89b217c7933841ffe54c487bc0e`, idêntico ao 0.9.
- Homologação v8 e produção v16: mesmo bundle `49dfcafdf3270c33dc05bfbd6bce062e74ea4c20dd6605096d53e526f3517fbd`.
- Leituras autenticadas de cadastro próprio, estúdio, lista administrativa, catálogo, capítulos e avatar público passaram em ambos os ambientes. O endpoint público da foto devolve somente nome artístico e avatar. Não foram criados cadastros ou views fictícias permanentes.
- As quatro tabelas novas têm RLS e não concedem leitura a anon/authenticated. RPCs de aprovação e contagem não têm EXECUTE para esses papéis. O bucket da selfie é privado. O verificador de segurança retornou somente as categorias já conhecidas: RLS sem política (intencional em tabelas restritas ao servidor) e proteção contra senha vazada desabilitada na configuração de Auth.

[Download do APK publicado](https://njyjwcjrirqmbvsizqar.supabase.co/storage/v1/object/public/cineo-app/Cineo_Dramas_0.10.0.apk). Os bytes públicos foram comparados ao APK validado; a API de atualização confirmou versionCode 10.
