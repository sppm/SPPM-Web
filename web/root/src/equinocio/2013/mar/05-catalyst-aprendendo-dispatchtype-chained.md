Catalyst - aprendendo o DispatchType::Chained
=====================

O Catalyst vem com alguns dispatchers instalados por padrão. Se você não sabe o conceito de dispacher, recomendo ler antes [o artigo sobre dispacher com Web::Simple](http://sao-paulo.pm.org/equinocio/2013/mar/02-comecando-com-web-simple).

Neste artigo, vou considerar que você já sabe instalar módulos do cpan e que saiba utilizar o terminal para iniciar programas e editar arquivos (usando seu editor preferido).


## Iniciando uma App

Antes de mais nada, vamos criar uma App Catalyst. Você precisa do pacote **Catalyst::Devel** para poder continuar.

    $ cd /tmp/; catalyst.pl MyApp

Isso vai criar uma app catalyst com nome MyApp. Os arquivos que vamos modificar são os controllers.

    created "MyApp/lib/MyApp/Controller/Root.pm"

para subir para testes, digite

    $ cd MyApp;
    $ perl script/myapp_server.pl -dr

> Nota:`-d` mostra o debug, e o `-r` manda reiniciar o catalyst a cada alteração nos arquivos.

### Analisando a saída

Com o debug ativado, o catalyst mostra quais são os *actions* que foram carregados, e quais são as classes e métodos que eles foram declarados.


    [debug] Loaded Private actions:
    .----------------------+--------------------------------------+--------------.
    | Private              | Class                                | Method       |
    +----------------------+--------------------------------------+--------------+
    | /default             | MyApp::Controller::Root              | default      |
    | /end                 | MyApp::Controller::Root              | end          |
    | /index               | MyApp::Controller::Root              | index        |
    '----------------------+--------------------------------------+--------------'

    [debug] Loaded Path actions:
    .-------------------------------------+--------------------------------------.
    | Path                                | Private                              |
    +-------------------------------------+--------------------------------------+
    | /                                   | /index                               |
    | /...                                | /default                             |
    '-------------------------------------+--------------------------------------'


Veja que, existem duas partes separadas: uma com os *Private actions*, e outras com os *Path actions*.

#### Private actions

Cada *Private action* é apresentado por 3 colunas, *Private*, *Class* e *Method*. São, respectivamente, o caminho em formato texto para acessar a action, a classe em que ela foi definida, e em qual *sub* ela foi definida.

#### Path actions

No path action, é exibido o Path e o private pth dele. Path é o caminho do endpoint que dispara os private actions. No exemplo acima, existem apenas 2 endpoints, porém, não são 2 URLs.

Uma URL precisa determinar um objeto (seja pagina, arquivo ou diretorio, impressora), enquanto os endpoints são textos que determinam qual serviço deve ser acesso.


No catalyst, é utlizado o `...` e `*` como marcadores. Explicarei cada um deles mais para frente.

Utilizando os dispachers padrões, - e desconsiderando que existem os de Regexp - o catalyst trata as URLs recebidas separando-as por `/` e tratando cada um dos pedaços para tentar encontrar o endpoint.

É importante saber que apenas a última barra é ignorada. Isso é uma "ajuda" do catalyst, mas é para facilitar quem utiliza ele.

#### Testando eles

Se você acessar [http://0:3000/](http://0:3000/) você irá ver a tela inicial do catalyst, e no log, ira aparecer algo parecido com:

    [info] *** Request 1 (0.001/s) [18387] [Sat Mar  2 15:02:25 2013] ***
    [debug] Path is "/"
    [debug] "GET" request for "/" from "127.0.0.1"
    [debug] Response Code: 200; Content-Type: text/html; charset=utf-8; Content-Length: 5472
    [info] Request took 0.002763s (361.925/s)
    .------------------------------------------------------------+-----------.
    | Action                                                     | Time      |
    +------------------------------------------------------------+-----------+
    | /index                                                     | 0.000193s |
    | /end                                                       | 0.000159s |
    '------------------------------------------------------------+-----------'

Perceba o debug `[debug] Path is "/"` diz qual foi o path capturado e logo em seguida quais os actions foram executados.

o método `/end` mais proximo do action sempre é executado, caso exista. Vamos falar sobre isso depois.

Se olharmos o Root.pm, iremos ver `sub index :Path :Args(0) {`.

`Args(0)` significa que esse método não recebe nenhum argumento. O `:Path` significa esse método deve representar uma action, cujo endpoint será '/' (pois não enviar nada para o Path significa o mesmo que `:Path('/')`.


Agora se você acessar, por exemplo, [http://0:3000/caminho/que-nao-existe](http://0:3000/caminho/que-nao-existe) ? Nesse caso, o path `/...' entra em ação.

    [info] *** Request 3 (0.001/s) [19108] [Sat Mar  2 15:10:41 2013] ***
    [debug] Path is "/"
    [debug] Arguments are "caminho/que-nao-existe"
    [debug] "GET" request for "caminho/que-nao-existe" from "127.0.0.1"
    [debug] Response Code: 404; Content-Type: text/html; charset=utf-8; Content-Length: 14
    [info] Request took 0.002096s (477.099/s)
    .------------------------------------------------------------+-----------.
    | Action                                                     | Time      |
    +------------------------------------------------------------+-----------+
    | /default                                                   | 0.000080s |
    | /end                                                       | 0.000108s |
    '------------------------------------------------------------+-----------'


Perceba que, o path continua sendo o `/`, porem, `caminho/que-nao-existe` virou argumento para o método. Isso porque, na definição do `default`não foi dito quantos argumentos ele recebia `sub default :Path {`. Veja, não existe `Args`, portanto, tudo que não satisfazer nenhuma action, vai acabar virando argumento este action. Ou seja, é um bom jeito de fazer 404.

> Observação: o nome dos métodos não influenciam no comportamento deles. Portanto se você alterar de `sub index`, para `sub index.t_page :Path('/') :Args(0) {` e `sub not_found_page :Path {` o código vai continuar funcionando perfeitamente.


### Porque usar Chained

Você pode estar se perguntando, "se funciona definindo os endpoints usando path, porque preciso usar chained?".

Quando você começa mais páginas, você *precisa* tentar diminuir a quantidade de regras de negócio que você escreve mais de uma vez. É por isso que usamos models, para poder reaproveitar as regras em diferentes situações. Isso tem que ocorrer com as regras de dispacher também.

Vamos considerar o exemplo mais usado, que você tem um blog, e que suas urls são:

    /post/<id>/<titulo>
    /post/new
    /post/<id>/edit
    /post

Portanto, para acessar o post, você faria um GET em /post/<id>/<titulo>, para ver o template da pagina, GET /post/new e POST /post/new para salvar, GET /post/<id>/edit para ver o form para editar, e POST /post/<id>/edit. GET /post/ seria a lista com todos os posts

o código para carregar o conteúdo do *post* seja do banco, ou de qualquer outro lugar, só precisa ser escrito uma vez, tanto para `/post/<id>/<titulo>` como para `/post/<id>/edit` e veremos isso mais pra frente.

### Ok, mas cadê o Chained ?

Calma, antes de aprender o chained, você precisava saber o que é path (ou endpoint) e o que são actions!


## Modificando o controller

No *Root.pm*, é de senso comum, criar um action que vai ser executado em todos os requests que você construir usando chained.


    sub root: Chained('/') PathPart('') CaptureArgs(0) {
        my ( $self, $c ) = @_;

        push @{$c->stash->{métodos}}, ':root:';
    }

Analisando agora esse código:

* `Chained('/')` diz que esta sub esta ligada no `/`, ou seja, é a raiz do site.
* `PathPart('')` diz que nada será adicionado no endpoint, então essa sub não muda o caminho urls.
* `CaptureArgs(0)` diz que nenhum parâmetro será capturado para este action. Nesse caso, `CaptureArgs(0)` e `CaptureArgs` tem o mesmo significado, mas com o número aparecendo fica mais claro.

O código adiciona na *stash* do *request* uma mensagem para que seja exibida no final. Como a ideia aqui é apenas mostrar o chained, não vou focar em Template nem banco de dados e/ou session.

Se você já salvou o arquivo, a saída agora vai ter uma seção com os *Chained Actions*, porém vazia.

    [debug] Loaded Chained actions:
    .-------------------------------------+--------------------------------------.
    | Path Spec                           | Private                              |
    +-------------------------------------+--------------------------------------+
    '-------------------------------------+--------------------------------------'

Isso é porque o nenhuma sub que utiliza `CaptureArgs` representa um endpoint sozinha.

Para ter um endpoint, agora, vamos criar um novo controller, chamado Post.pm, assim:

    package MyApp::Controller::Post;
    use Moose;
    use namespace::autoclean;
    use utf8;

    BEGIN { extends 'Catalyst::Controller' }

    sub base: Chained('/root') PathPart('post') CaptureArgs(0) {
        my ( $self, $c ) = @_;

        push @{$c->stash->{métodos}}, ':base do Post.pm:';

        $c->stash->{posts} = [
            'Post 1', 'Post 2', 'Post 3'
        ];
    }

    __PACKAGE__->meta->make_immutable;

    1;

Veja que agora, foi definido um `Chained('/root')`, e que `/root` é o caminho para o **Private action** do método que o chained seja feito.

`CaptureArgs` novamente vazio, pois não queremos nenhum parâmetro por enquanto. `PathPart('post')` faz com que o endpoint agora tenha `post` como parte dele.

Neste momento, o debug continua vazio. Vamos adicionar o método onde ficaria a listagem dos posts.


    sub list: Chained('base') PathPart('') Args(0) {
        my ( $self, $c ) = @_;
        push @{$c->stash->{métodos}}, ':lista de posts:';

        push @{$c->stash->{métodos}},
            "\t$_\n" for @{$c->stash->{posts}};

    }

`Args(0)` é o que diz que esse action deve se tornar um endpoint.

    .-------------------------------------+--------------------------------------.
    | Path Spec                           | Private                              |
    +-------------------------------------+--------------------------------------+
    | /post                               | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | => /post/list                        |
    '-------------------------------------+--------------------------------------'

Olhando no debug, mostra que o endpoint `/post` irá executar, na ordem, as rotinas `/root`, depois `/post/base`, depois termina em `/post/list`.

Se você abrir essa pagina, vamos encontrar um erro.

    [debug] Path is "/post/list"
    [debug] "GET" request for "post/" from "127.0.0.1"
    [error] Caught exception in MyApp::Controller::Root->end "Catalyst::Action::RenderView could not find a view to forward to."
    [debug] Response Code: 500; Content-Type: text/html; charset=utf-8; Content-Length: 13934
    [info] Request took 0.008614s (116.090/s)
    .------------------------------------------------------------+-----------.
    | Action                                                     | Time      |
    +------------------------------------------------------------+-----------+
    | /root                                                      | 0.000102s |
    | /post/base                                                 | 0.000071s |
    | /post/list                                                 | 0.000065s |
    | /end                                                       | 0.000253s |
    '------------------------------------------------------------+-----------'

O catalyst executou partindo do `/root` até chegar em `/end`, e quando chegou no `/end` não encontrou como o conteúdo devia ser desenhado. Como aqui é apenas um exemplo, vamos alterar o código do `/end` para imprimir o conteúdo do `@{$c->stash->{métodos}}` em forma de texto.

Novamente no **Root.pm**, altere `sub end : ActionClass('RenderView') {}` por:

    sub end : ActionClass('RenderView') {
        my ( $self, $c ) = @_;

        return if $c->res->body;
        $c->res->content_type('text/plain');
        $c->res->body( join "\n", @{$c->stash->{métodos}} );
    }

Agora, quando você acessar [http://0.0.0.0:3000/post](http://0.0.0.0:3000/post) ou [http://0.0.0.0:3000/post/](http://0.0.0.0:3000/post/) vai retornar:

    :root:
    :base do Post.pm:
    :lista de posts:
        Post 1

        Post 2

        Post 3

> Info: Se você adicionar um `sub end : ActionClass('RenderView')` dentro do **Post.pm**, o `/end` do __Root.pm não__ vai ser executado, isso boa parte das vees não é realmente o que você quer, mas de qualquer maneira, se você realmente quer implementar um `end` no seu próprio controller, você pode fazer um `$c->forward('/end')` forçando o método do _Root.pm_ ser executado.

Agora que já temos um método para listar, vamos criar o endpoint que carrega o post acessado na stash.

    sub object: Chained('base') PathPart('') CaptureArgs(1) {
        my ( $self, $c, $id ) = @_;
        push @{$c->stash->{métodos}}, ':carregar post:';

        if ($id =~ /^[0-9]$/ && exists $c->stash->{posts}[$id]){

            push @{$c->stash->{métodos}}, 'Carregou post ' . $c->stash->{posts}[$id];

        }else{
            push @{$c->stash->{métodos}}, '!post não encontrado!';
            $c->detach;
        }
    }


Lembre-se que esse action não cria nenhum endpoint, portanto, é preciso adicionar um método para exibir.

    sub show_post: Chained('object') PathPart('') Args {
        my ( $self, $c, $id ) = @_;
        push @{$c->stash->{métodos}}, '^^^^^^^^^^ é o post!';
    }


Agora no debug, foi adicionado:

    | /post/*/...                         | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | -> /post/object (1)                  |
    |                                     | => /post/show_post                   |


Isso faz com que possamos acessar [http://0.0.0.0:3000/post/1/oque-for/que-tiver-aqui](http://0.0.0.0:3000/post/1/oque-for/que-tiver-aqui) que vai aparecer:

    :root:
    :base do Post.pm:
    :carregar post:
    Carregou post Post 2
    ^^^^^^^^^^ é o post!


E na saída do debug:

    [debug] Path is "/post/show_post"
    [debug] Arguments are "oque-for/que-tiver-aqui"
    [debug] "GET" request for "post/1/oque-for/que-tiver-aqui" from "127.0.0.1"
    [debug] Response Code: 200; Content-Type: text/plain; Content-Length: 82
    [info] Request took 0.004938s (202.511/s)
    .------------------------------------------------------------+-----------.
    | Action                                                     | Time      |
    +------------------------------------------------------------+-----------+
    | /root                                                      | 0.000090s |
    | /post/base                                                 | 0.000058s |
    | /post/object                                               | 0.000095s |
    | /post/show_post                                            | 0.000078s |
    | /end                                                       | 0.000298s |
    '------------------------------------------------------------+-----------'

Veja que, novamente, o "oque-for/que-tiver-aqui" virou argumento para o action *show_post*, pois não foi definido quantos argumentos ele receberia, e apenas que ele pode receber. Isso foi dito pelo `Args`.

Se você alterar para `sub show_post: Chained('object') PathPart('') Args(2) {` o método só será executado em [http://0.0.0.0:3000/post/1/um/dois](http://0.0.0.0:3000/post/1/um/dois) mas [http://0.0.0.0:3000/post/1/um/dois/tres](http://0.0.0.0:3000/post/1/um/dois/tres) vai executar o `/...` que é o *Not Found*.

Veja que se você acessar o post 9, [http://0.0.0.0:3000/post/9](http://0.0.0.0:3000/post/9), que não existe, o `$c->detach;` cuida de desviar o fluxo para o `end` mais próximo, e não executa os actions seguintes (que seria o `show_post`, neste caso).

    .------------------------------------------------------------+-----------.
    | Action                                                     | Time      |
    +------------------------------------------------------------+-----------+
    | /root                                                      | 0.000086s |
    | /post/base                                                 | 0.000059s |
    | /post/object                                               | 0.000123s |
    | /end                                                       | 0.000125s |
    '------------------------------------------------------------+-----------'

Vamos agora criar o susposto edit. O procedimento é bem semelhante ao do `show_post`:

    sub edit_post: Chained('object') PathPart('edit') Args(0) {
        my ( $self, $c, $id ) = @_;
        push @{$c->stash->{métodos}}, 'Editando o post acima!';
    }

Agora você pode acessar [http://0.0.0.0:3000/post/1/edit](http://0.0.0.0:3000/post/1/edit) e vai aparecer:

    :root:
    :base do Post.pm:
    :carregar post:
    Carregou post Post 2
    Editando o post acima!

Perceba que, da mesma forma que no show, se você carregar um post inexistente, o código de edit não irá ser executado. Isso significa que você só precisou fazer a verificação que o post existe uma vez, e que toda vez que o código de edit for executado, o post já existe.

Para criar o endpoint `/post/new`, você faria:

    sub new_post: Chained('base') PathPart('new') Args(0) {
        my ( $self, $c, $id ) = @_;
        push @{$c->stash->{métodos}}, 'Criando novo post:';
    }

Então depois de ver todos estes exemplos, fica muito mais simples entender como funciona os *chained actions* do catalyst.

### Algumas dicas:

* Tente criar um controller para cada coisa no seu site. Quanto mais separado, mais simples fica de manter e reutilizar o código.
* O nome do controller e dos métodos não interferem nos endpoints. Porém, os *private paths* são criados com base neles.
* Tente utilizar ao máximo o carregamento de objetos em actions com `CaptureArgs(XX)` e deixar os endpoints sempre com `Args(0)` ou `Args`, isso vai poupar algumas dores de cabeças quando você ter muitos actions chained espalhados.


### Chained + DBIx::Class

Depois de um tempo utilizando Chained para criar endpoints REST, você percebe algumas coisas que facilitam o desenvolvimento. O exemplo abaixo não foi testado, mas deve para você com pequenos ajustes.

Post.pm:

    package MyApp::Controller::Post;
    use Moose;
    use namespace::autoclean;
    use utf8;

    BEGIN { extends 'Catalyst::Controller' }

    sub base: Chained('/root') PathPart('post') CaptureArgs(0) {
        my ( $self, $c ) = @_;

        # verificaria as permissoes do usuário atual para acessar o conteúdo

        # carrega o model em stash->{collection}
        $c->stash->{collection} = $c->model('DB::Post');
    }

    sub list: Chained('base') PathPart('') Args(0) {
        my ( $self, $c ) = @_;

        # percorre a lista no collection e adiciona em algum lugar as
        # linhas para poder renderizar
        while (my $row = $c->stash->{collection}->next){
            push @{$c->stash->{algum_lugar}}, $row;
        }
    }

    sub object: Chained('base') PathPart('') CaptureArgs(1) {
        my ( $self, $c, $id ) = @_;

        $c->detach('/erro_usuário_maldito') unless $id =~ /^[0-9]$/;

        $c->stash->{collection} = $c->stash->{collection}->find({$id});
        # especificando collection e separando o object pois o object pode ser apenas um hash
        # e nao mais um ResultSet com where.
        $c->stash->{object} = $c->stash->{post} = $c->stash->{collection}->next;

        if (!$c->stash->{object}){
            # coloca na stash alguma coisa pra dizer que foi 404
            $c->detach;
        }
    }

    sub show_post: Chained('object') PathPart('') Args {
        my ( $self, $c, $id ) = @_;

        # aqui seria apenas o template já utilizar o stash.object e stash.post
        # pois já foi carregado e já existe
    }

    # edit e a "mesma" coisa para delete
    sub edit_post: Chained('object') PathPart('edit') Args(0) {
        my ( $self, $c, $id ) = @_;

        if ($c->req->params->{conteúdo_editado}){
            $c->stash->{collection}->update( {   } );
        }
    }


    sub new_post: Chained('base') PathPart('new') Args(0) {
        my ( $self, $c, $id ) = @_;

        if ($c->req->params->{conteúdo_post}){
            # insere
            $c->stash->{collection}->create( {  }  )
            # faz redirect para a pagina de lista (?)
            # isso depende de cada sistema!
        }
    }

    __PACKAGE__->meta->make_immutable;

    1;

e junto com isso, você pode criar o controller **Post/Comment.pm** assim:


    package MyApp::Controller::Post::Comment;
    use Moose;
    use namespace::autoclean;
    use utf8;

    BEGIN { extends 'Catalyst::Controller' }

    sub base: Chained('/post/object') PathPart('comment') CaptureArgs(0) {
        my ( $self, $c ) = @_;

        # aqui que fica legal
        # $c->stash->{collection} já existe, e um resultset com um where de comment_id lá dentro
        $c->stash->{collection} = $c->stash->{collection}->comments;
        # a partir de agora, supondo que existe o relacionamento
        # entre comments e comentarios cujo nome é comments,
        # stash->{collection} contém todos os comentarios.

        # lembre-se que nao foi executada query aqui.
    }

    sub list: Chained('base') PathPart('') Args(0) {
        my ( $self, $c ) = @_;

        # aqui seria o list dos comentarios...
        while (my $row = $c->stash->{collection}->next){
            push @{$c->stash->{lugar_dos_comentarios}}, $row;
        }
    }

    # carregando um comentario apenas
    sub object: Chained('base') PathPart('') CaptureArgs(1) {
        my ( $self, $c, $id ) = @_;

        $c->detach('/erro_usuário_maldito') unless $id =~ /^[0-9]$/;

        $c->stash->{collection} = $c->stash->{collection}->find({$id});

        $c->stash->{object} = $c->stash->{comment} = $c->stash->{collection}->next;

        if (!$c->stash->{object}){
            # coloca na stash alguma coisa pra dizer que foi 404
            $c->detach;
        }
    }

    sub show_comment: Chained('object') PathPart('') Args {
        my ( $self, $c, $id ) = @_;
        # já tem na stash tanto object que é o comentario,
        # como post, que é o post.
    }


    sub edit_comment: Chained('object') PathPart('edit') Args(0) {
        my ( $self, $c, $id ) = @_;

        if ($c->req->params->{conteúdo_editado}){
            $c->stash->{collection}->update( { } );
        }
    }


    sub new_comment: Chained('base') PathPart('new') Args(0) {
        my ( $self, $c, $id ) = @_;

        if ($c->req->params->{conteúdo_comment}){
            # insere na tabela de posts já associado ao
            # post, gracas ao DBIC
            $c->stash->{collection}->create( {  }  );
        }
    }

    __PACKAGE__->meta->make_immutable;

    1;


Isso o seguinte debug:

    .-------------------------------------+--------------------------------------.
    | Path Spec                           | Private                              |
    +-------------------------------------+--------------------------------------+
    | /post/*/comment/*/edit              | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | -> /post/object (1)                  |
    |                                     | -> /post/comment/base (0)            |
    |                                     | -> /post/comment/object (1)          |
    |                                     | => /post/comment/edit_comment        |
    | /post/*/comment                     | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | -> /post/object (1)                  |
    |                                     | -> /post/comment/base (0)            |
    |                                     | => /post/comment/list                |
    | /post/*/comment/new                 | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | -> /post/object (1)                  |
    |                                     | -> /post/comment/base (0)            |
    |                                     | => /post/comment/new_comment         |
    | /post/*/comment/*/...               | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | -> /post/object (1)                  |
    |                                     | -> /post/comment/base (0)            |
    |                                     | -> /post/comment/object (1)          |
    |                                     | => /post/comment/show_comment        |
    | /post/*/edit                        | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | -> /post/object (1)                  |
    |                                     | => /post/edit_post                   |
    | /post                               | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | => /post/list                        |
    | /post/new                           | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | => /post/new_post                    |
    | /post/*/...                         | /root (0)                            |
    |                                     | -> /post/base (0)                    |
    |                                     | -> /post/object (1)                  |
    |                                     | => /post/show_post                   |
    '-------------------------------------+--------------------------------------'


Fazendo com que o `object` de cada controller carregue na *stash* o próprio objecto, assim como sua *collection* inteira, facilita, pois a action que fazer chained não precisa saber exatamente qual o nome foi utilizado na chain anterior. E criar uma copia do objecto atual ajuda a você não perder nenhum objecto já carregado (por exemplo, quando carregar os comentarios, não perder o post que já foi feito query para consultar ele)


Fim!
----------

Gostou? Tem alguma sugestão ou dúvida? Deixe nos comentários abaixo ou no twitter. Catalyst não é nenhum *bicho de 7 cabeças*, basta aprender cada pedaço por vez. *Chained actions* são utilizadas de monte e é necessário entende-las bem para não se confundir!

## AUTOR

Renato CRON

[github.com/renatoaware](https://github.com/renatoaware/) / [github.com/renatocron](https://github.com/renatocron/) / [CPAN:RentoCRON](https://metacpan.org/author/RENTOCRON) / [@renato_cron](https://twitter.com/renato_cron)

Licença
------
Texto sob Creative Commons - Atribuição - Partilha nos Mesmos Termos 3.0 Não Adaptada,
mais informações em [http://creativecommons.org/licenses/by-sa/3.0/](http://creativecommons.org/licenses/by-sa/3.0/)

