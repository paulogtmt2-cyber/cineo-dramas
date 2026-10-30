# Cineo Dramas — primeira base Android 0.1

Projeto inicial nativo em Java, interface em português e API Python sem dependências externas. Não é uma plataforma pronta para lançamento. Nenhum servidor foi contratado ou publicado e nenhum APK foi compilado nesta entrega.

## O que está implementado
- Cadastro e login com senha derivada por scrypt; sessões de 24 horas.
- Criador cadastra produção com título e sinopse, adiciona episódios MP4 de até 25 MB e confirma autorização de distribuição.
- Fluxo rascunho → em análise → aprovado ou reprovado com motivo.
- Painel de análise visível para administradores e protegido também no servidor.
- Catálogo consulta somente produções aprovadas.
- Vídeos pendentes acessíveis apenas ao autor e administrador, inclusive na rota de mídia.
- Reprodução com controles nativos e suporte HTTP Range no servidor.
- Bloqueio de alterações durante análise ou após aprovação; reprovados podem adicionar episódios e reenviar.
- Registro de decisões de moderação e logout que invalida a sessão.

## Executar o servidor de desenvolvimento
Requer Python 3.10 ou superior.

```sh
cd backend
python server.py
```

O servidor escuta apenas em 127.0.0.1:8080. Para conectar um celular, um operador precisa hospedar esta API atrás de HTTPS e configurar o domínio no aplicativo. Não há credenciais, domínio ou hospedagem fictícios embutidos. Não exponha diretamente o servidor HTTP de desenvolvimento.

Cadastre sua conta e atribua o papel de administrador **no servidor**, com o mesmo diretório de dados:

```sh
python server.py --admin seu-email@example.com
```

Saia e entre novamente no app. Outras contas continuam como criadores; não existe promoção a administrador pelo aplicativo.

## Compilar Android
Abra a pasta android no Android Studio com JDK 17 e SDK 35. O projeto usa Android Gradle Plugin 8.7.3 e Gradle 8.9. O wrapper binário não está incluído. Com Gradle 8.9 instalado:

```sh
gradle -p android assembleDebug
```

Saída: android/app/build/outputs/apk/debug/app-debug.apk.

Alternativa sem usar o computador local: coloque o conteúdo desta pasta em um repositório GitHub e execute manualmente o workflow “Gerar APK de teste”. O workflow está preparado, mas não foi executado nem validado nesta entrega. Um APK de produção exige chave de assinatura própria.

## Testes executados
```sh
cd backend
python -m unittest -v
```
9 testes passaram: aprovação, bloqueio de autoaprovação, privacidade dos episódios, bloqueio de edição pendente, reprovação e reenvio, envio sem episódios, impedimento de escolha de papel no cadastro, logout e decisão duplicada.

O SDK Android não está disponível no ambiente desta entrega: compilação, instalação, layout e reprodução em celular ainda precisam de validação. Os testes são da lógica da API; não comprovam funcionamento do app inteiro.

## Antes do lançamento público
Faltam hospedagem real e domínio HTTPS, armazenamento de vídeo escalável, upload retomável e em segundo plano, validação/transcodificação de vídeo (o MVP apenas verifica tamanho e assinatura MP4), limites por conta, proteção contra tentativas de login, recuperação de senha e verificação de email, remoção/substituição de episódios, revisões de produções já aprovadas, capas, busca, favoritos, denúncias, exclusão de conta, políticas aplicáveis e testes em aparelhos reais.

Nesta base, a sessão permanece só em memória e é necessário entrar novamente ao reabrir o processo. O envio usa base64 e limita os vídeos a 25 MB; não é apropriado para episódios grandes ou tráfego público. Não há monetização, notificações push, catálogo fictício ou obras de terceiros incluídas.

Referência Android usada para seleção de documentos:
https://developer.android.com/training/data-storage/shared/documents-files
