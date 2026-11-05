# Cineo 0.11 — estúdio profissional

Estado: publicado e verificado. 35 testes Node, 13 verificações de cache, testes transacionais com rollback, compilação e regressão no emulador passaram. A regressão Android gerou 140 capturas. Homologação: 19 consultas autenticadas; produção: 5 consultas autenticadas após implantação.

Commit validado: `8b90762e30e0c84917a44eeaab9a4f6dcc6d4513`.
CI: https://github.com/paulogtmt2-cyber/cineo-dramas/actions/runs/42087254930.
APK: 5.955.173 bytes; SHA-256 `5d9cdc035913af421e5604b003256da37235af443d3b543e790aa272ab957949`.
Certificado SHA-256: `b5755f77ddaa869b456d7134296947773cc1c89b217c7933841ffe54c487bc0e`, preservado desde as versões anteriores.
Servidor: cineo v17, bundle `1ff2cea325f122ad084c17618c80c731f06b24c28af894fdfd59e9d4485d9dd5`.
As capturas de instrumentação usam dados sintéticos explicitamente identificados; não representam ganhos ou audiência de contas reais.

## Funções

1. Gráficos interativos de 7, 30 e 90 dias.
2. Comparação com período anterior, sem percentual artificial quando não há base.
3. Retenção por segundo a partir de trechos observados, sem preencher saltos como assistidos.
4. Funil da audiência do primeiro episódio para os seguintes.
5. Horas de reprodução medidas nas sessões qualificadas.
6. Proporção de sessões que chegaram ao fim.
7. Espectadores novos e recorrentes, sem tentar identificar contas anonimizadas.
8. Origem: início, busca, perfil, biblioteca, compartilhamento ou não identificada.
9. Horários com mais views observadas em São Paulo, sem promessa de desempenho.
10. Metas de views e seguidores com prazo.
11. Testes A/B de cartazes e títulos, com aprovação administrativa antes da exposição.
12. Alertas de variação de pelo menos 50%, somente com base anterior mínima de 20 views.
13. Exportação CSV protegida contra fórmulas em texto.
14. Mídia kit público em PDF pelo sistema de impressão do Android.
15. Acessos revogáveis de editor, produtor e financeiro. Financeiro não acessa os documentos criativos ou solicita saque pelo titular. Permissões por produção continuam independentes.
16. Documentos privados de direitos (PDF, JPEG, PNG) por produção.
17. Disputas com parecer administrativo. Investigação impede novos fechamentos até decisão.
18. Extrato diário com estimativas e histórico de decisões.
19. Fechamento mensal revisado, imutável por período e limitado às views registradas. Frações de centavo passam ao mês seguinte.
20. Pedidos de saque com reserva de saldo, cancelamento, aprovação, recusa e registro manual do pagamento externo.

## Financeiro e privacidade

Não há transferência automática ou integração bancária. As solicitações começam desabilitadas, com mínimo e regras ainda não configurados; o administrador deve definir as condições no painel antes de habilitar. Destinos Pix são cifrados com AES-GCM no servidor e aparecem completos somente ao administrador, em tela protegida contra captura. O aplicativo não verifica automaticamente a titularidade bancária. Valores disponíveis dependem de fechamento revisado, e solicitações duplicadas não podem reservar o mesmo saldo.

Os relatórios usam medições reais e prospectivas. Versões anteriores podem não ter origem, retenção completa ou histórico de seguidores. Dados de teste são desfeitos em transações de banco e ficam isolados na instrumentação Android. O limite de uma view por conta, episódio e dia e a tarifa registrada de R$ 0,40 por mil views elegíveis foram preservados.

## Banco

Ordem dos arquivos adicionais em supabase/features: studio_growth_private_tables, studio_role_grant_history, studio_team_permissions_audited, studio_audience_reports, studio_manual_finance_functions, studio_experiment_stats, studio_playback, studio_fraction_carry, studio_payment_note. Todos usam RLS e privilégios restritos ao servidor. Revogações de equipe preservam registros inativos.

## Download

https://njyjwcjrirqmbvsizqar.supabase.co/storage/v1/object/public/cineo-app/Cineo_Dramas_0.11.0.apk

O download público foi conferido por SHA-256 após publicação e o endpoint de atualização anuncia version_code 11.
