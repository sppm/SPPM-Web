# Manipulando Binários Cobol com Perl

## Introdução

O mainframe usa codificação EBCDIC internamente é usado por grandes corporações ao redor do mundo, no dia a dia integrar esse tipo de sistema com a data warehouse envolve alguns desafios únicos.

![](/root/static/images/equinocio/2013/cobol/imagem1.png)

Nesse artigo será abordado como ler dados do binário COBOL.

## Cobol Data File

O binário COBOL é um arquivo posicional em que a sequência dos bytes representa um dado. Que pode ser dos seguintes tipos:

    "A" para caracteres alpha  (A-Z, a-z, e espaços).
	"9" para um campo numérico (apenas números 0-9) .
	"X" qualquer caracter (incluindo binário).

O intuito desse artigo não é ensinar como programar em COBOL, é de apenas ensinar como lêr. Quando um binário COBOL é gerado não existe nenhuma informação que diga informação sobre
aquele dado. É necessário ter o que chamamos de **COBOL Copy Book**, que não é nada além de um texto que diz o tamanho de cada linha e o que os bytes representam.
Dentro do binário COBOL não tem nada, além de dados sem sentido. Para que eles façam sentido é necessário um arquivo de "metainformação" dizendo o que cada posição representa.

![](/root/static/images/equinocio/2013/cobol/imagem2.png)

Por exemplo vamos criar um arquivo binário com as seguintes posições:

	"Copy Book"
	9(4)
	A(3)
	A(3)

Bom lendo o **copy book** podemos saber que o tamanho de cada linha é de 10 bytes (4+3+3).

Vamos criar um binário fictício:

	perl -MEncode 'binmode STDOUT;print encode("posix-bc","1234foobar5678foobar8765foobaz7485foobar")' \
	> arquivo.cobol

Vamos salva-lo como *arquivo.cobol* e agora vamos lêr o arquivo.

	#!/usr/bin/perl

	use strict;
	use warnings;
	use Encode;

	open my $fh,'<','arquivo.cobol' or die $!;
	binmode $fh;

	# - Cada linha tem 10 bytes
	my ($buff,$length) = (undef,10);
	while(read($fh,$buff,$length)) {
		my $line = decode("posix-bc",$buff);
		print "Linha por linha $line\n";
	}

Porém no COBOL é comum comprimir os dados do tipo numérico pela metade (+1) usando **Nibbles**.

## Nibbles

Se você estiver usando uma máquina byte addressable como a 80x86. Para representar o número zero por exemplo será necessário usar 8 bits *00000000*. Se você quiser manipular os bits individualmentes será necessário pegar um byte inteiro e fazer isso manualmente. Um Nibble é o conjunto de 4 bits, portanto um byte tem dois nibbles.

![](/root/static/images/equinocio/2013/cobol/imagem3.png)

Com 4 bits temos a possibilidade de fazer 16 diferentes combinações (2**4) e com 8 bits podemos ter 256 combinações (2**8) diferentes.

Como é muito extenso ler um nibble usando binário usamos o sistema hexadecimal:

	0123456789ABCDEF (16 caracteres)

## Comp-3

Quando criamos um arquivo binário COBOL nós temos a opção de comprimir os campos numéricos (tamanho / 2 + 1).

Por exemplo o número *999787* em hexadecimal seria *39 39 39 37 38 37*, que ocuparia 6 bytes e teria 12 nibbles.

O que o comp-3 faz é o sistema inverso, ele grava *99 97 87* hexadecimal mais uma letra que indica se o número é positivo ou negativo, por isso a fórmula é (tamanho / 2 + 1).
Resumindo, quando um campo for do tipo comp-3 será necessário pegar o valor em hexadeciamal que já será o valor real do número.

Por exemplo *99 97 87 44* em hexadecimal será o número *999787* positivo, onde o *44* representa a letra *D* que diz que o número é positivo, se fosse a letra *C* o número seria negativo.

## Convert::IBM390

Para não ter que ficar fazendo as conversões usando "unpack" manualmente, existe o seguinte módulo, [Convert::IBM390](https://metacpan.org/module/GROMMEL/Convert-IBM390-0.27/lib/Convert/IBM390.pm).

## Referências

 - [0] - <http://en.wikipedia.org/wiki/EBCDIC>
 - [1] - Art of Assembly Language Programming
 - [2] - <http://www.3480-3590-data-conversion.com/article-packed-fields.html>

## Autor

Daniel de Oliveira Mantovani


<daniel.oliveira.mantovani@gmail.com>