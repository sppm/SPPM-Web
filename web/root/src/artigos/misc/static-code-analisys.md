# Análise Estática de Código (em Perl)

## Why?

Por um lado, a expressividade do Perl é uma benção, permitindo que a velocidade da escrita do código acompanhe a velocidade do pensamento do programador `:)`

Por outro, é inevitável deixarmos bombas-relógio no *source* que nenhum teste detecta, e que tendem a "detonar" linhas bem distantes daquelas que o `perl` mostra na mensagem de erro.

Então, que tal colocarmos Perl para analisar código Perl?

## Perl::Critic

Sem dúvida, é o maior e o mais importante representante das ferramentas de análise estática. A ferramenta [perlcritic](https://metacpan.org/module/perlcritic) avalia o código-fonte de acordo com as diretrizes do livro [Perl Best Practices](http://shop.oreilly.com/product/9780596001735.do), além de outras métricas, como, por exemplo, [complexidade ciclomática](https://pt.wikipedia.org/wiki/Complexidade_ciclom%C3%A1tica).

No melhor estilo de *gamification*, existem "níveis de dificuldade" de 1 a 5 (com os nomes sugestivos: *brutal*, *cruel*, *harsh*, *stern* e *gentle*).

Como exemplo, segue o *output* de `perlcritic -3 test.pl`:

    Code not contained in explicit package at line 1, column 1.  Violates encapsulation.  (Severity: 4)
    Found use of Class::ISA. This module is deprecated by the Perl 5 Porters at line 4, column 1.  Find an alternative module.  (Severity: 5)
    Found use of Switch. This module is deprecated by the Perl 5 Porters at line 5, column 1.  Find an alternative module.  (Severity: 5)
    Module does not end with "1;" at line 5, column 1.  Must end with a recognizable true value.  (Severity: 4)

É de suma importância notar que o Perl::Critic não impõe um estilo padronizado e não obriga a adotar nenhuma das chamadas boas práticas! Segue um trecho que gera certa hostilidade por parte do Perl::Critic, juntamente com uma solução imediata:

    my $const_value = eval $const_name . '()'; ## no critic

Curiosamente, o nível *harsh* invalida esse uso indiscriminado de *flag*, sugerindo um controle mais consciente sobre as regras da validação (esse tipo de sintaxe possui escopo de validade):

    my $const_value = eval {
        ## no critic (ProhibitNoStrict ProhibitNoWarnings)
        no strict qw(refs);
        no warnings qw(once);
        return *$const_name->();
    };

Para regras/exceções personalizadas da forma recorrente, existe o `~/.perlcriticrc`:

    severity = harsh

    [TestingAndDebugging::RequireUseWarnings]
    equivalent_modules = common::sense

    [TestingAndDebugging::RequireUseStrict]
    equivalent_modules = common::sense

Dica: vale a pena consultar a [lista de policies](https://metacpan.org/release/Perl-Critic) que acompanham o Perl::Critic por *default*. Já o [Perl::Critic::Pulp](https://metacpan.org/release/Perl-Critic-Pulp) é um *bundle* com outras *policies* úteis, tais como [Perl::Critic::Policy::Modules::ProhibitModuleShebang](https://metacpan.org/module/Perl::Critic::Policy::Modules::ProhibitModuleShebang) (que proíbe o uso de `#!/usr/bin/perl` em arquivos `.pm`). Para habilitá-lo, basta incluir, em `~/.perlcriticrc`:

    [Modules::ProhibitModuleShebang]
    severity = gentle

Outra coisa sensata é incluir, nos módulos lançados no CPAN, um teste que faça o uso do [Test::Perl::Critic](https://metacpan.org/module/Test::Perl::Critic) (tais testes devem obrigatoriamente verificar se `$ENV{AUTHOR_TESTING}` está setado, [CPAN Testers](http://cpantesters.org/) agradecem!).

Por fim, para fazer um *test-drive*, existe o *webservice* [perlcritic.com](http://perlcritic.com/), feito nos moldes do [validator.w3.org](http://validator.w3.org/).

## Perl::MinimumVersion

Sabe aquele momento constrangedor quando o seu código funciona para você mas não para `$insira_o_nome_da_pessoa`? Muitas vezes, pode ser um mero `$a //= 1` ou um `map { s/^\s+|\s+$//gr } @b` numa única linha de código de um programa de mil linhas. O utilitário [perlver](https://metacpan.org/module/perlver) ajuda a evitar esse tipo de constrangimento. Por um lado, avisa qual é a menor versão do Perl necessária para rodar um dado *script*. Por outro, `perlver --blame test.pl` aponta no código os possíveis "exageros":

     ------------------------------------------------------------
     File    : test.pl
     Line    : 8
     Char    : 4
     Rule    : _perl_5010_operators
     Version : 5.010
     ------------------------------------------------------------
     //=
     ------------------------------------------------------------

[Test::MinimumVersion](https://metacpan.org/module/Test::MinimumVersion) facilita a criação de testes automáticos (não esquecer de tratar `$ENV{RELEASE_TESTING}` adequadamente!).

## Perl::PrereqScanner

Outra coisa constrangedora é não informar os pré-requisitos necessários para rodar um dado *script*. [Dist::Zilla](http://dzil.org/) resolve essa parte perfeitamente, mas cria outro inconveniente: dependências de módulos obscuros para tarefas triviais (estou falando de você, [Text::Trim](https://metacpan.org/module/Text::Trim)). Para revisar manualmente a lista de dependências, nada como um [scan_prereqs](https://metacpan.org/module/RJBS/Perl-PrereqScanner-1.015/bin/scan_prereqs):

`scan_prereqs --combine lib/ t/`

    Carp             = 0
    Config           = 0
    Fcntl            = 0
    HTTP::Date       = 0
    LWP::Protocol    = 0
    LWP::UserAgent   = 0
    Net::Curl::Easy  = 0
    Net::Curl::Multi = 0
    Net::Curl::Share = 0
    Scalar::Util     = 0
    base             = 0
    strict           = 0
    utf8             = 0
    warnings         = 0

Como complemento, é interessante cruzar a lista de dependências com as reportadas pelo [corelist](https://metacpan.org/module/corelist) (parte do [Module::CoreList](https://metacpan.org/module/Module::CoreList)); muitas das dependências não são propriamente "dependências", por fazerem parte do Perl desde os tempos mais primórdios.

Curiosidade: `corelist` às vezes pode fazer o papel do `perlver`. Por exemplo, para saber aonde/quando a sintaxe `given/when` apareceu, rodamos `corelist --feature switch`:

    Data for 2013-03-11
    feature "switch" was first released with the perl v5.9.5 feature bundle

## Test::Mojibake

[scan_mojibake](https://metacpan.org/module/scan_mojibake) ajuda a lidar com os erros de codificaÃ§Ã£o, reportando o uso indevido/incoerente de `use utf8` / ``:

    not ok 13 - Mojibake test for t/bad/bad-latin1.pl_
    #   Failed test 'Mojibake test for t/bad/bad-latin1.pl_'
    #   at /Users/stas/perl5/perlbrew/perls/perl-5.16.2/lib/site_perl/5.16.2/Test/Mojibake.pm line 168.
    # Non-UTF-8 unexpected in t/bad/bad-latin1.pl_, line 6 (source)
    not ok 14 - Mojibake test for t/bad/bad-utf8.pl_
    #   Failed test 'Mojibake test for t/bad/bad-utf8.pl_'
    #   at /Users/stas/perl5/perlbrew/perls/perl-5.16.2/lib/site_perl/5.16.2/Test/Mojibake.pm line 168.
    # UTF-8 unexpected in t/bad/bad-utf8.pl_, line 5 (source)

## Test::Vars

Se o [GCC](https://www.gnu.org/software/gcc/) reclama sobre a alocação de variáveis não-utilizadas, por que o Perl não?! Entra o [Test::Vars](https://metacpan.org/module/Test::Vars). Infelizmente, ele não tem um utilitário *stand-alone*. O jeito é, no diretório do projeto, dar um:

    perl -MTest::Vars -e 'all_vars_ok()'

É importante que o arquivo `MANIFEST` esteja presente, pois é de lá que o Test::Vars coleta os nomes dos módulos. Exemplo de *output*:

    # $result is used once in &LWP::Protocol::ftp::__ANON__[lib/LWP/Protocol/ftp.pm:307] at lib/LWP/Protocol/ftp.pm line 278
    # $mtime is used once in &LWP::Protocol::ftp::request at lib/LWP/Protocol/ftp.pm line 357
    # $mode is used once in &LWP::Protocol::ftp::request at lib/LWP/Protocol/ftp.pm line 357
    not ok 14 - lib/LWP/Protocol/ftp.pm
    #   Failed test 'lib/LWP/Protocol/ftp.pm'
    #   at -e line 1.

## Pod::Coverage

Documentação feita pela metade é pior do que nenhuma documentação. [Pod::Coverage](https://metacpan.org/module/Pod::Coverage) detecta as declarações de funções/métodos no código e verifica se tem seção respectiva no [POD](http://perldoc.perl.org/perlpod.html). O utilitário `pod_cover` também requer presença do `MANIFEST`:

    Summary:
     sub routines total    : 63
     sub routines covered  : 56
     sub routines uncovered: 7
     total coverage        : 88.88%

E, claro, temos o [Test::Pod::Coverage](https://metacpan.org/module/Test::Pod::Coverage).

## Wrapping up

[Dist::Zilla::PluginBundle::TestingMania](https://metacpan.org/module/Dist::Zilla::PluginBundle::TestingMania) junta alguns desses (e muitos outros) analisadores estáticos para a sua conveniência.

## AUTHOR

Stanislaw Pusep

 - [blogs.perl.org/users/stas](http://blogs.perl.org/users/stas/)
 - [coderwall.com/creaktive](https://coderwall.com/creaktive)
 - [github.com/creaktive](https://github.com/creaktive)
 - [twitter.com/creaktive](https://twitter.com/creaktive)

## Licença
![CC-BY-SA](http://i.creativecommons.org/l/by-sa/3.0/80x15.png)
Texto sob [Creative Commons - Atribuição - Partilha nos Mesmos Termos 3.0 Não Adaptada](http://creativecommons.org/licenses/by-sa/3.0/deed.pt_BR).

## CRON Edited

Movido da quarentena do equinocio de 2013 para os artigos.
