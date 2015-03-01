Web::Simple
==========


Para quem não sabe, [Web::Simple](https://metacpan.org/module/Web::Simple), é um modulo para criar pequenas aplicações web.

Ele é rápido e ele é pequeno, e funciona utilizando pĺack, assim como quase todos frameworks agora =)

Se você ainda não sabe quando deve utilizar [Web::Simple](https://metacpan.org/module/Web::Simple) ou Catalyst, uma dica é: se não existem muitas regras[1] e você vai se virar com os módulos para conversar com as apis[2] faça com [Web::Simple](https://metacpan.org/module/Web::Simple).


[1] "muitas regras" na verdade, é se você vai ter que escrever muitos dispatchers.

[2] API do twitter, OAuth, etc.. essas APIs já estão prontas para integrar com o catalyst, então porque repetir tudo?

O que é um dispatcher
--------------------

Em palavras para novatos, dispatcher é o meio que você diz ao framework qual código cada URL deve executar.

No caso do Web::Simple, a lógica é definida no retorno da `sub dispatch_request`.

O retorno de `dispatch_request` deve ser uma **ARRAY** de várias outras subs. Essas *subs* são escritas usando [atributos](http://perldoc.perl.org/perlsub.html#Subroutine-Attributes "Subroutine-Attributes") que informam quando elas devem ser executadas.


Hello World da documentação:

    sub dispatch_request {
        sub (GET) {
          [ 200, [ 'Content-type', 'text/plain' ], [ 'Hello world!' ] ]
        },
        sub () {
          [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
        }
    }

Acima, o código retorna duas `subs` cada uma retorna uma **ARRAYREF**, onde o primeiro valor é o status do HTTP, o segundo são os headers, e por último o conteúdo.

Instalando e começando a usar
----------------------------

Considerando que você já instalou o *cpanm* seja via local::lib ou perlbrew, execute:

    $ cpanm Web::Simple;
    $ cpanm Starman

Apos instalar o [Web::Simple](https://metacpan.org/module/Web::Simple) e o Starman, crie em algum lugar:

    $ cd /tmp/

com o seu editor favorito, abra o arquivo HelloWorld.psgi e escreva nele:


    #!/usr/bin/env perl

    package HelloWorld;
    use Web::Simple;

    sub dispatch_request {
        sub (GET) {
            [ 200, [ 'Content-type', 'text/plain' ], [ 'Hello world!' ] ]
        },
        sub () {
            [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
        }
    }

    HelloWorld->run_if_script;

Volte para o terminal, e suba o starman:

    $ starman HelloWorld.psgi --workers 2

Com esses parâmetros, o starman sobe a sua app na porta 5000 com bind para 0.0.0.0, usando 2 workers.

Acesse [http://0.0.0.0:5000](http://0.0.0.0:5000 0.0.0.0:5000) e veja, seu Hello World! está na tela.

Agora, edite seu arquivo para ficar assim:

    #!/usr/bin/env perl

    package HelloWorld;
    use Web::Simple;
    use utf8;
    use Encode;

    sub dispatch_request {
        sub (GET) {
            [ 200, [ 'Content-type', 'text/plain; charset=utf-8' ], [
                encode("utf8", 'São Paulo Perl mongers')
            ] ]
        },
        sub () {
            [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
        }
    }

    HelloWorld->run_if_script;

Se você recarregar sua página, o texto não vai mudar. Para isso, é necessário que recarregue sua app.

Faça um ps aux para descobrir qual o PID master do starman:

    renato@ood:/tmp/ws$ ps aux|grep starman
    renato    4080  1.1  0.0  10932  6964 pts/6    S+   06:36   0:00 starman master HelloWorld.psgi --workers 2
    renato    4081  0.4  0.0  12412  7844 pts/6    S+   06:36   0:00 starman worker HelloWorld.psgi --workers 2
    renato    4082  0.2  0.0  12412  7844 pts/6    S+   06:36   0:00 starman worker HelloWorld.psgi --workers 2
    renato    4085  0.0  0.0   4396   832 pts/7    R+   06:36   0:00 grep --color=auto starman

No caso , o PID do master é o 4080, o primeiro da lista. Envie um sinal de HUP para ele:

    $ kill -HUP 4080

Agora se você acessar [http://0.0.0.0:5000](http://0.0.0.0:5000 0.0.0.0:5000) você irá ver `São Paulo Perl mongers` escrito corretamente. Se você remover o `use utf8`, junto com o Encode e o encode("utf8", ...) também vai funcionar **sem erro de encoding**, porém, o perl está apenas passando pra frente o que você escreveu, sem saber o que é, e o browser respeitando o que foi dito no header.

A melhor forma é você saber qual o encoding é o seu conteúdo e sempre tratar isso.

Agora que você já tem uma aplicação rodando, também sabe como reiniciar ela, vamos entender o que acontece no dispatcher.

A primeira sub, disse apenas no seu atributo, que seu request era GET. Sem informar nada, entende-se que todas URLs digitadas serão afetadas. Portanto, [http://0.0.0.0:5000/foobar](http://0.0.0.0:5000/foobar /foobar) vai exibir o mesmo conteúdo.

A outra sub, não disse nada, ou seja, ela é o jeito que o *Matt S Trout* criou para fazer o "not found", ou seja, esse método é executado quando nenhuma das outras regras se aplicarem.

Para ver o 405 em ação, execute, se você tem curl instalado:

    $ curl -X POST http://0.0.0.0:5000/
    Method not allowed

Veja que, DELETE, HEAD e OPTIONS também não são aceitos, mas GET são:

    $ curl -X GET http://0.0.0.0:5000/
    São Paulo Perl mongers

Web::Simple - especificações das regras do dispatcher
-------------
Regras foram retiradas com base na documentação do dia 26/02/2013.

**Por método HTTP: **

`sub (GET) {`
match com base no METHOD do HTTP. Nesse caso, GET.

`sub (GET|HEAD) {`
GET ou HEAD entrariam nessa regra.

**Por caminho, o famoso *Path*:**

`sub (/login) {`
Uma sub com atributo começando com / significa uma regra por path. Nesse caso, o mais simples, o caminho inteiro é considerado. Ou seja, quando alguém acessar http://0.0.0.0:5000/login ele será executado.


`sub (/user/*) {` aqui, parâmetros são **capturados** por posição. Cada `*` pode ser qualquer valor, edite seu arquivo para:

    sub (/user/*) {
        my ($self, $user_id) = @_;
        [ 200, [ 'Content-type', 'text/plain; charset=utf-8' ], [
            encode("utf8", 'Olá, user ' . $user_id )
        ] ]
    },

Faça o `kill -HUP` para reiniciar e depois acesse [http://0.0.0.0:5000/user/1456789](http://0.0.0.0:5000/user/1456789) então você vai ver o texto "Olá, user 1456789"

Você pode juntar vários desses:

`sub (/user/*/*) { my ($self, $user_1, $user_2) = @_;` e/ou dependendo e como você quer:

`sub (/alguma-coisa/*/sua-outra-url/*) { my ($self, $alguma_1, $outra_2) = @_;`


Vamos com outro exemplo agora, se você tem a url `/processos-por-ids/123/134/1456/856/624` você precisa escrever:

`sub (/processos-por-ids/**) { my ($self, $ids) = @_; my @ids = split qr|/|, $ids; `

    sub (/processos-por-ids/**) {
        my ($self, $ids) = @_;
        my @ids = split qr|/|, $ids;

        [ 200, [ 'Content-type', 'text/plain; charset=utf-8' ], [
            encode("utf8", "IDs:\n" . join("\n", @ids) )
        ] ]
    },

Pronto! Agora supondo que você queria editar vários processos de uma vez, você poderia criar:

    sub (/processos-por-ids/**/editar) {
        my ($self, $ids) = @_;
        my @ids = split qr|/|, $ids;
        ...
    }

> Observações: Como o Web::Simple tenta tratar as extensões dos "arquivos", então você precisa tomar cuidados, pois por padrão, o Web::Simple não considera da regra nada que fica depois de um ponto final na url.

    /one/*       matches /one/two.three    and captures "two"
    /one/*.*     matches /one/two.three    and captures "two.three"
    /**          matches /one/two.three    and captures "one/two"
    /**.*        matches /one/two.three    and captures "one/two.three"


E por último, mas não menos importante, existe a regra dos 3 pontinhos...

`sub (/foo/...) {` Ela significa, que "pode ter algo aqui, mas talvez não" e também te da uma chance de criar sub encadeadas recursivamente.

    /foo         # não faz match
    /foo/        # faz o match e reseta o path para '/' para as proximas subs encadeadas
    /foo/bar/baz # faz o match e reseta o path para '/bar/baz' para as proximas subs encadeadas

Perceba que /foo ficou de fora. Para incluir ele, você tem que fazer `sub (/foo...) {` sem colocar a barra depois do foo.

    /foo         # faz match e o path vira ''

Um uso bom, seria começar tudo com /... para e isso capturado como idioma do site. /pt/<resto do site> ou /en/<resto do site>.

Esses dois códigos abaixo são equivalentes:

    sub (/foo)   { 'I match /foo' },
    sub (/foo/...) {
        sub (/bar) { 'I match /foo/bar' },
        sub (/*)   { 'I match /foo/{id}' },
    }

e

    sub (/foo...) {
        # execute código aqui que são uteis para todas as chamdas.
        sub (~)    { 'I match /foo' },
        sub (/bar) { 'I match /foo/bar' },
        sub (/*)   { 'I match /foo/{id}' },
    }

Então quando você utiliza `/foo...` você acessa o path '' utilizando `~`

O segundo jeito de escrever é "melhor" pois permite que você possa escrever apenas uma vez o código que vai ser utilizado em todas as subs daquele escopo. Por exemplo, o resultset do DBIC.

    sub (/user...) {
        my $user_rs = $schema->resultset('User');
        sub (~) { $user_rs },
        sub (/*) { $user_rs->find($_[1]) },
    }


**parâmetros com nomes**

As vezes, você pode querer receber os parâmetros em um **HASHREF** no lugar de recebelos em variaveis separadas.

    sub (/*:one/*:two/*:three/*:four) {
        my ($self, $hash) = @_;
        use Data::Dumper;
        [ 200, [ 'Content-type', 'text/plain; charset=utf-8' ], [

            Dumper $hash

        ] ]
    },

Acessando [http://0.0.0.0:5000/um/dois/tres/quatro](http://0.0.0.0:5000/um/dois/tres/quatro) vai ser algo parecido com:

    $VAR1 = {
        'three' => 'tres',
        'one' => 'um',
        'two' => 'dois',
        'four' => 'quatro'
    };

**Marcações por extensão**

Como foi já foi dito, o [Web::Simple](https://metacpan.org/module/Web::Simple) tem meios para tratar as extensões. Então você pode criar:

`sub (.html) {` isso geralmente é utilizado para escolher o meio que você vai renderizar.


**Capturando Query e body parameter**

Eles podem ser capturados com:

    sub (?<param spec>) { # match URI query
    sub (%<param spec>) { # match body params

É possível capturar os parâmetros *encodados* via application/x-www-form-urlencoded ou multipart/form-data.

Existem várias maneiras de capturar:

    param~        # parâmetro opcional
    param=        # parâmetro requerido
    @param~       # parâmetro opcional e multiplo
    @param=       # parâmetro requerido e multiplo
    :param~       # opcional e vai para um hashref
    :param=       # requerido e vai para um hashref
    :@param~      # opcional e vão para uma arrayref dentro de um hashref
    :@param=      # requerido e vão para uma arrayref dentro do hashref
    *             # tudo vai para um hashref
    @*            # todos os parâmetros que não foram capturados antes, vão para um hashref

> Note que se você mandou caputrar um parâmetro como multiplo, você sempre vai recebe-lo via array, mesmo se for apenas um item ?foo.
> No outro caso, se você mandou capturar apenas um, e o parâmetro aparece varias vezes, apenas a última vez é considerada.


Exemplo de como receber o order-by e o numero da pagina pela URL:

    sub (?page=&order_by~) {
        my ($self, $page, $order_by) = @_;
        return unless $page =~ /^\d+$/;
        ...
    }

Exemplo de como receber todos os parâmetros para um hashref de arrayref:

    sub(?@*) {
        my ($self, $params) = @_;
        use Data::Dumper;
        [ 200, [ 'Content-type', 'text/plain; charset=utf-8' ], [
            Dumper $params
        ] ]
    },

Acessando [http://0.0.0.0:5000/qualquerurl?abc=23&34=3&foo=1&foo=2](http://0.0.0.0:5000/qualquerurl?abc=23&34=3&foo=1&foo=2) vai gerar:

    $VAR1 = {
          '34' => [
                  '3'
                ],
          'abc' => [
                   '23'
                 ],
          'foo' => [
                   '1',
                   '2'
                 ]
        };

**Combinando regras**

Os tres diferentes tipos de regras podem ser combinados usando `+`, os tipos são:

- por método
- por path
- parâmetros query/body (e/ou upload)

`sub (GET + /user/*) {` captura o /user/* apenas em requests GET

`sub (GET|POST) {` GET ou POST, todos os paths

`sub ((GET|POST) + /user/*) {` GET ou POST + path

`sub (!/user/foo + /user/*) {` Path negado, por exemplo, todos /user/<qualuer coisa> mas não /user/foo

`sub ( !(POST|PUT|DELETE) ) {` Captura o que nao for nem POST, nem PUT, nem DELETE, ou seja, GET|OPTIONS|HEAD e os que invetarem em outras versoes de HTTP.

> Note que você pode utilizar espaços a vontade, para facilitar a leitura.

Fim!
----------

O [Web::Simple](https://metacpan.org/module/Web::Simple) tem sistema de regras muito legal, que facilita para você criar aplicações que ficam *no meio* de outras, usando [Plack::Middleware](https://metacpan.org/module/Plack::Middleware), você pode dar uma olhada em [Otimizando o Uso de Memória e CPU em Servidores Web com Starman](http://edencardim.me/post/30779246487/otimizando-o-uso-de-memoria-e-cpu-em-servidores-web-com) que no final dele, existe um exemplo de como subir várias aplicações sob um mesmo PSGI.

Na versão que o [Pendant](https://github.com/edenc/Pendant) se encontrava no dia 26/02/2013, ele utilizava [Web::Simple](https://metacpan.org/module/Web::Simple) para traduzir arquivos de Markdown/POD/etc para HTML. Você pode ver isso [nesse tree do github](https://github.com/edenc/Pendant/blob/315c2c9ec7b83e1b3f9df3f4181d47453847e7eb/lib/Pendant.pm).

## AUTOR

Renato CRON


[github.com/renatoaware](https://github.com/renatoaware/) / [github.com/renatocron](https://github.com/renatocron/) / [CPAN:RentoCRON](https://metacpan.org/author/RENTOCRON) / [@renato_cron](https://twitter.com/renato_cron)

Licença
------
Texto sob Creative Commons - Atribuição - Partilha nos Mesmos Termos 3.0 Não Adaptada,
mais informações em [http://creativecommons.org/licenses/by-sa/3.0/](http://creativecommons.org/licenses/by-sa/3.0/)

