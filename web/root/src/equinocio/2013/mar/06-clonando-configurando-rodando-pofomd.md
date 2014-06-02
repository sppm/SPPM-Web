Clonando, configurando e rodando o "Para onde foi o meu dinheiro?"
======================================================================

Sistema elaborado para demonstrar os gastos públicos, classificados por FUNÇÃO de Governo e seus detalhamentos. Esta ferramenta permite ao usuário conhecer toda a tramitação orçamentária, indicando inclusive quem recebeu o recurso empenhado. A proposta é fornecer condições de maior clareza do destino dos tributos, bem como maior “mobilidade” no manuseio das informações obtidas. (Para saber mais acesse o [site do projeto](http://www.paraondefoiomeudinheiro.com.br/sobre)).

O sistema é totalmente escrito tem Perl e neste artigo veremos como clonar o projeto do Github, configurar o ambiente local e rodar o sistema em sua máquina para poder contribuir e ajudar na complementação e evolução deste sistema.

O projeto, atualmente, esta no perfil do W3C Brasil no Github, que fica no endereço https://github.com/W3CBrasil/POFOMD. É dele que faremos o clone do projeto para usarmos neste artigo.

Para fazer este clone, você deve ter o git instalado em sua máquina. Em máquinas debian-like você pode instalá-lo simplesmente digitando: 

    $ sudo apt-get install git

Com o git instalado, na linha de comando vamos clonar o projeto da seguinte forma:

    $ git clone git://github.com/W3CBrasil/POFOMD.git

Após este comando o nosso sistema já estará clonado dentro da pasta POFOMD. Para que o sistema funcione corretamente, precisaremos ter instalados em nossa máquina alguns pacotes específicos e, principalmente, o Perl e uma base de dados, que neste caso vamos usar o PostgreSQL.

Em debians-like, usaremos o seguinte comando para instalar tudo o que precisamos no nosso sistema:

    $ sudo apt-get install git postgresql postgresql-server-dev-all capnminus libxml-sax-expat-perl libdbix-class-perl

Agora, entraremos dentro da pasta do nosso projeto e instalaremos todas as dependências Perl necessárias para o nosso projeto específico:

    $ cd POFOMD
    $ sudo cpanm inc::Module::Install
    $ sudo cpanm Module::Install::Catalyst
    $ sudo cpanm --installdeps .
    $ sudo perl Makefile.PL

A partir deste ponto, já temos tudo o que precisamos instalado em nosso ambiente local, basta agora ajustarmos as configurações do banco de dados PostgreSQL para que o nosso sistema o utilize corretamente. A modelagem do banco de dados é totalmente baseada em tabelas multidimensionais, onde há uma tabela de fato (gasto) e todas as outras são dimensões. No caso específico deste projeto, onde há uma grande quantidade de dados para serem agrupados para uso, isso facilita muito a utilização de bancos relacionais.

    $ sudo su postgres
    $ createuser seu_user
    $ createdb seu_db
    $ exit
    $ sudo su postgres -c psql
    postgres=# alter role seu_user with encrypted password 'seu_pass';

Configurações de banco de dados ajustadas, vamos agora instalar todas as tabelas necessárias para o nosso projeto:

    $ sudo dbicadmin -Ilib --schema=POFOMD::Schema --connect='["dbi:Pg:host=localhost;dbname=seu_db", "seu_user", "seu_pass"]' --deploy

E agora você deve ajustar o arquivo **pofomd.conf**, que fica na raiz do projeto, e colocar todas as configurações corretas de conexão com o banco de dados.

A partir de agora temos tudo corretamente configurado para começar a brincar com nosso projeto. O único problema é que não temos nenhum dado em nossa base. Para resolver isso vamos seguir os passos abaixo para baixar, desempacotar e inserir dados de exemplo baixados diretamente do site da Secretaria da Fazenda de SP.

    * Faça o download do arquivo de exemplo no link https://www.fazenda.sp.gov.br/SigeoLei131/Paginas/DownloadReceitas.aspx?flag=2&ano=2012
    * Descompacte o arquivo
    * Edite o arquivo de importação script/import/sp_to_pg.pl e configure corretamente suas credenciais de banco.
    * Entre no diretório lib '$ cd lib'
    * execute o arquivo de migração;

        $ sudo perl ../script/import/sp_to_pg.pl 2012 path/para/o/seu/arquivo.csv

That's it! Basta agora rodar o comando:

    $ script/pofomd_server.pl -r

E o seu projeto já esta rodando localmente, pronto para receber as suas modificações e contribuições!


Let's Hack The Planet!

Alê Borba <ale.alvesborba@gmail.com>