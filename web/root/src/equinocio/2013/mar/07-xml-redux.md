# XML Redux

## Introdução
Existem muitas, muitas formas de gerar e consumir XML em Perl.
No [StackOverflow](http://stackoverflow.com/questions/tagged/perl+xml), encontramos de tudo nas respostas, envolvendo desde as expressões regulares e até [XML::Twig][xmltwig], passando por [XML::Simple][xmlsimple] e [XML::Parser][xmlparser].
É importante ressaltar que *todas as opções são válidas* (bem, exceto as expressões regulares, né... e, pensando bem, exceto o [XML::Simple][xmlsimple]): não existe *um único jeito certo* de trabalhar com [Extensible Markup Language](https://en.wikipedia.org/wiki/Xml) em Perl.

Todavia, algumas técnicas e alguns módulos do *namespace* `XML::` do [CPAN](https://metacpan.org/) ainda permanecem um mistério para a maioria dos programadores.
O objetivo do presente artigo é demonstrar o que *Modern Perl* nos oferece quando o assunto é XML.

## XML::Hash::LX
Muitas vezes, o formato XML é utilizado apenas como um *container* para os dados estruturados.
São os casos para se considerar o uso de [JSON][jsonxs] ou [YAML][yamlxs].
Já quando o projeto em questão **exige** o uso do XML, muitos ainda insistem em apelar para o módulo [XML::Simple][xmlsimple].
Só que nem sempre ele é, de fato, simples, por assumir alguns *defaults* nada convencionais.
A título de exemplo, iremos processar um [sitemap.xml](http://www.sitemaps.org/protocol.html) típico.
É claro que [existe um módulo no CPAN para isso][wwwsitemap], mas o jeito *one-liner* de extrair URLs de um *sitemap* via [XML::Simple][xmlsimple] seria:

    perl -MXML::Simple -E 'say $_->{loc} for @{XMLin("sitemap.xml")->{url}}'

Eis um *default* estranho: o nó-raiz, `urlset`, é descartado
(pela minha experiência, esse é o *default* menos estranho desse módulo).

A alternativa mais apropriada, com API mais consistente, e enraizada no excelente e robusto [XML::LibXML][libxml], é o [XML::Hash::LX][xmlhash].
Eis como usá-lo para o mesmo objetivo:

    perl -MXML::Hash::LX -0777 -nE 'say $_->{loc} for @{xml2hash($_)->{urlset}{url}}' sitemap.xml

Esse módulo é menos "mágico" e respeita o [principle of least astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment)
(o que é muito bom na hora de debugar!).
Por outro lado, o fato de utilizar o [libxml][libxmlbin] por baixo dos panos o deixa 2x mais rápido do que o [XML::Simple](xmlsimple)!

Já para gerar um XML a partir de um *hash*, é a coisa mais trivial
(ao contrário do [XML::Simple][xmlsimple], cujos *defaults* estranhos tornam o *output* irreconhecível):

    perl -MXML::Hash::LX -e 'print hash2xml {env => \%ENV}'

### Bônus
 - [XML::LibXML::Simple][xmllibxmlsimple] é uma alternativa *drop-in* para **leitura** de XML via [XML::LibXML][libxml], utilizando a interface compatível com a do [XML::Simple][xmlsimple] (a interface continua ruim, mas o [libxml][libxmlbin] salva a pátria);
 - [App::p](https://metacpan.org/module/App::p) é um *upgrade* para *one-liners* em Perl que traz atalhos inclusive para as conversões `hash <=> XML <=> JSON <=> YAML`.

## XML::Compile
Segue um padrão bastante comum ao trabalhar com os dados alheios em JSON:

    for my $addr (@{$json->{results}}) {
        next if 
            ref($addr->{types}) ne 'ARRAY' or
            ref($addr->{address_components}) ne 'ARRAY' or
            ref($addr->{geometry}) ne 'HASH' or
            ref($addr->{geometry}->{location}) ne 'HASH' or
            not defined($addr->{geometry}->{location_type}) or
            not grep m{^(route|street|postal_code)}i, @{$addr->{types}};
        ...
    }

No caso do JSON, a validação da estrutura dos dados fica "por conta do leitor".
Existem formas mais ou menos elegantes de fazê-lo, sendo a mais trivial encapsular todo o tratamento dentro de um bloco `eval { ... }`.
Com XML, **não precisa ser assim**, afinal, temos XSD, [XML Schema Definition](https://en.wikipedia.org/wiki/Xsd)!

Voltando para o caso do `sitemap.xml`, a definição oficial do *schema* encontra-se em [http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd](http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd):

    $ curl -O http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd
    $ xmllint --noout --schema sitemap.xsd sitemap.xml
    sitemap.xml validates

[xmllint](http://manpages.ubuntu.com/manpages/natty/man1/xmllint.1.html) é um utilitário que faz parte da distribuição do [libxml][libxmlbin] e, entre outras coisas, faz o papel do (finado) [HTML Tidy](http://tidy.sourceforge.net/).
O fato do nosso `sitemap.xml` ter sido validado com o *schema* `sitemap.xsd` significa que uma boa parte das "verificações manuais" se torna desnecessária.

### Leitura
O próximo passo é fazer tudo de uma vez: tanto a validação quanto o *parsing*.
É exatamente esse o papel do módulo [XML::Compile][xmlcompile].
O seu nome descreve precisamente o seu *modus operandi*, mas ofusca as vantagens obtidas ao usá-lo:

    #!/usr/bin/env perl
    use 5.010;
    use strict;
    use warnings;

    use Carp qw(croak);
    use XML::Compile::Schema;

    my $schema  = XML::Compile::Schema->new('sitemap.xsd');
    my $reader  = $schema->compile(
        READER          => '{http://www.sitemaps.org/schemas/sitemap/0.9}urlset',
        sloppy_floats   => 1,
        sloppy_integers => 1,
    );

    my $data    = eval { $reader->('sitemap.xml') };
    croak "XML error: $@" unless defined $data;
    for my $url (@{$data->{url}}) {
        say $url->{loc};
    }

O código acima, apesar de levantar as suspeitas, é suficientemente robusto para a tarefa (listar as URLs de um *sitemap*).
A validação funciona no melhor estilo "it is better to `die()` than to `return()` in failure": faltando o arquivo 100% coerente com o *schema*, o programa aborta.
Caso contrário, é garantido que `$data` seja um *HashRef* com a chave `url` presente e apontando para um *ArrayRef* contendo um ou mais *HashRef*'s, cada um com a chave `loc` apontando para a URL.
Ufffa, é mais fácil fazer do que descrever `;)`

O mais importante aqui é o trecho do `$schema->compile(...)`.
Vamos por partes:

 - `READER => '{http://www.sitemaps.org/schemas/sitemap/0.9}urlset'`: definimos aqui que iremos **ler** o elemento `urlset` no *namespace* `http://www.sitemaps.org/schemas/sitemap/0.9` (O que é *namespace*? É aquilo que o atributo `xmlns` do elemento do XML define);
 - `sloppy_floats`: XML, por ser abstrato, não define a precisão dos números com o ponto flutuante. Por *default*, [XML::Compile][xmlcompile] usará [Math::BigFloat](https://metacpan.org/module/Math::BigFloat). Em 99.999% dos casos, *this is madness*. `sloppy_floats` é meio que um grito *THIS IS SPARTAAAAA*, assumindo que a precisão nativa do Perl é mais que o suficiente.
 - `sloppy_integers`: idem, para os inteiros (por *default*, [Math::BigInt](https://metacpan.org/module/Math::BigInt)).

Existem muitas outras configurações, recomendo estudar a [documentação][xmlcompile] exaustivamente.
De interesse imediato, seriam as opções:

 - `key_rewrite => [qw(UNDERSCORES)]`: é comum utilizar-hífen-como-delimitador no glorioso mundo do XML. Há quem prefira o_outro_jeito;
 - `ignore_unused_tags => qr/^_/`: exclusivo para o modo `WRITER`; ignora tags que começam com `_` (caso contrário, resultaria em erros).

### Gravação
Para quem acha que **gerar** um XML na base de `print`, interpolação e concatenação, é mais fácil do que **ler** um: não tente fazer isso, os *edge cases*
(*encoding* e *named entities*, entre outros) são chatos demais.
Eis um gerador simples de *sitemap*:

    #!/usr/bin/env perl
    use strict;
    use warnings;

    use XML::Compile::Schema;
    use XML::LibXML::Document;

    my $schema  = XML::Compile::Schema->new('sitemap.xsd');
    my $writer  = $schema->compile(
        WRITER  => '{http://www.sitemaps.org/schemas/sitemap/0.9}urlset',
        use_default_namespace => 1, # elimina os prefixos <x0:...>
    );
    my $doc     = XML::LibXML::Document->new(1.0 => 'UTF-8');

    my $data = { url => [
        {
            loc         => 'http://blogs.perl.org/users/stas/',
            lastmod     => time(), # time() retorna Unix timestamp!
            changefreq  => 'monthly',
            priority    => 1.0,
        },
    ] };
    my $xml = $writer->($doc, $data);
    $doc->setDocumentElement($xml);

    print $doc->toString(1); # auto-indent ;)

Uma parte bem legal e *eye-candy* fica por conta do `$doc->toString(1)`: o *pretty-printing*, com a indentação automática:

    <?xml version="1" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <url>
        <loc>http://blogs.perl.org/users/stas/</loc>
        <lastmod>2013-03-03</lastmod>
        <changefreq>monthly</changefreq>
        <priority>1</priority>
      </url>
    </urlset>

Outra parte que se destaca menos, mas também muito importante: `lastmod => time` automagicamente vira `<lastmod>2013-03-03</lastmod>`.
Não chega a ser um [ORM], mas já ajuda!

## trang
> Não tenho um XSD para o meu XML, e agora José?

Aqui existem duas saídas:

1. Aprenda a escrever um XSD;
2. Utilize uma ferramenta que infere o *schema* a partir dos seus dados!

A primeira é óbvia e é a que eu recomendo.
Já a segunda pode ser uma "rodinha de bicicleta" no caminho para a primeira.
Para o tal, temos a ferramenta [trang][trang]:

    $ java -jar trang.jar sitemap.xml sitemap.rnc
    $ cat sitemap.rnc
    default namespace = "http://www.sitemaps.org/schemas/sitemap/0.9"
    namespace xsi = "http://www.w3.org/2001/XMLSchema-instance"

    start =
      element urlset {
        attribute xsi:schemaLocation { text },
        element url {
          element loc { xsd:anyURI },
          element lastmod { xsd:dateTime }?,
          element changefreq { xsd:NCName },
          element priority { xsd:decimal }
        }+
      }

No exemplo acima, produzimos, automagicamente, um *schema* no formato [RELAX NG Compact](https://en.wikipedia.org/wiki/RELAX_NG#Compact_syntax)
(mais amigável para os olhos humanos).
[trang][trang] também gera XSD, que é o que precisamos para deixar o [XML::Compile][xmlcompile] feliz:

    $ java -jar trang.jar sitemap.xml sitemap2.xsd

O arquivo gerado é bem mais simples do que o *schema* original (ao qual felizmente temos acesso irrestrito).
Isso implica que nem todo *sitemap* será processável com esse *schema*; um ou outro utilizará definições não-contempladas no exemplo usado para a inferência.
Inclusive, dependendo do exemplo, alguns elementos opcionais podem ser considerados como necessários.
De qualquer forma, já é um bom começo para ao menos **ter** um *schema*!

## XML::Rabbit

Observei acima que o [XML::Compile][xmlcompile] é *quase* um [Object-relational mapping][orm].
Então, o [XML::Rabbit][xmlrabbit] chega mais perto ainda:

    #!/usr/bin/env perl
    package Sitemap;
    use XML::Rabbit::Root;

    add_xpath_namespace sitemap => 'http://www.sitemaps.org/schemas/sitemap/0.9';
    has_xpath_object_list url   => '/sitemap:urlset/sitemap:url' => 'Sitemap::URL';

    finalize_class;

    package Sitemap::URL;
    use XML::Rabbit;

    has_xpath_value loc         => './sitemap:loc';
    has_xpath_value lastmod     => './sitemap:lastmod';
    has_xpath_value changefreq  => './sitemap:changefreq';
    has_xpath_value priority    => './sitemap:priority';

    finalize_class;

    package main;
    use 5.010;
    use strict;
    use warnings;

    my $sitemap = Sitemap->new(file => 'sitemap.xml');
    for my $url (@{$sitemap->url}) {
        say $url->loc;
    }

Aqui, meramente comunico a existência de tal módulo, pois o tutorial escrito [pelo próprio autor](https://metacpan.org/author/ROBINS), que ensina a implementar um [cliente para a API do Last::FM][lastfm], é insuperável.
Só destaco que vale a pena dar uma olhada na ferramenta [dump_xml_structure](https://metacpan.org/module/dump_xml_structure), que ajuda a analisar a estrutura do XML:

    $ dump_xml_structure sitemap.xml
    node: /x:urlset
    attr: /x:urlset/@xsi:schemaLocation
    node: /x:urlset/text()
    node: /x:urlset/x:url
    node: /x:urlset/x:url/*
    node: /x:urlset/x:url/*/text()
    node: /x:urlset/x:url/text()
    Namespace: xsi=http://www.w3.org/2001/XMLSchema-instance
    Namespace: x=http://www.sitemaps.org/schemas/sitemap/0.9

## Autor
Stanislaw Pusep

 - [blogs.perl.org/users/stas](http://blogs.perl.org/users/stas/)
 - [coderwall.com/creaktive](https://coderwall.com/creaktive)
 - [github.com/creaktive](https://github.com/creaktive)
 - [twitter.com/creaktive](https://twitter.com/creaktive)

##Revisão

 - [Daniel de Oliveira Mantivani](https://github.com/mantovani)
 - [Eden Cardim](https://github.com/edenc)
 - [Leonardo Ruoso](https://github.com/leonardoruoso)
 - [Renato CRON](https://github.com/renatoaware)

## Licença
![CC-BY-SA](http://i.creativecommons.org/l/by-sa/3.0/80x15.png)
Texto sob [Creative Commons - Atribuição - Partilha nos Mesmos Termos 3.0 Não Adaptada](http://creativecommons.org/licenses/by-sa/3.0/deed.pt_BR).

[wwwsitemap]: https://metacpan.org/module/WWW::Sitemap::XML
[xmlparser]: https://metacpan.org/module/XML::Parser
[xmlsimple]: https://metacpan.org/module/XML::Simple
[xmltwig]: https://metacpan.org/module/XML::Twig

[libxml]: https://metacpan.org/module/XML::LibXML
[libxmlbin]: http://xmlsoft.org/
[orm]: https://en.wikipedia.org/wiki/Object-relational_mapping
[xmlcompile]: https://metacpan.org/module/XML::Compile
[xmlhash]: https://metacpan.org/module/XML::Hash::LX
[xmllibxmlsimple]: https://metacpan.org/module/XML::LibXML::Simple
[xmlrabbit]: https://metacpan.org/module/XML::Rabbit

[jsonxs]: https://metacpan.org/module/JSON::XS
[lastfm]: http://blog.robin.smidsrod.no/2011/09/30/implementing-www-lastfm-part-1
[trang]: http://www.thaiopensource.com/relaxng/trang.html
[yamlxs]: https://metacpan.org/module/YAML::XS
