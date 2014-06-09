# Site da São Paulo.pm em Catalyst

Este é um código para gerenciar os conteudos do site [http://sao-paulo.pm.org](http://sao-paulo.pm.org)

É uma tentativa do RenatoCRON de colocar todos os artigos/equinocios no ar, num site novo e rapidamente, mas com cuidados para qualquer pessoa com boa vontade poder continuar os trabalhos no código.


## Iniciando o banco:

Se deseja subir o site na sua propria maquina, você precisa antes subir o banco.

Antes de tudo, você precisa instalar as dependencias e configurar o seu sqitch. Procure sobre isso no seu Search Engine favorito antes de começar a comitar aqui!

    $ cd web;
    $ vim sqitch.conf # configure e salve a conexao com o seu postgres, usuario e host.
    $ git update-index --assume-unchanged sqitch.conf # nao commite suas configurações!
    $ createdb sppm_dev # se foi esse que você nome que escolheu.
    $ sqitch deploy # isso faz o deploy no banco


## Modificando o banco

Se for fazer alterações no banco, por favor, utilize este padrão:

    $ cd web;
    $ sqitch add (00X)-foo-bar-sua-alteracao --requires (00X-1)-alteracao anterior -n 'uma descricao sobre o que você ira alterar'
    $ vim script/schema.dump.sh # altere a conexão com o banco
    $ git update-index --assume-unchanged script/schema.dump.sh # nao commite suas configurações!
    $ ./script/schema.dump.sh # execute




