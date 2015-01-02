# I/O Não Bloqueante com IO::Select "na unha"

## Resumo

Quem já lidou com entrada e saída de dados com multiplas fontes (sejam varios arquivos ou sockets) sabe da complexidade envolvida e dos desafios de performance/latência envolvidos. Imagine distribuir um stream de video ao vivo para dezenas de milhares de clientes ou processar eventos oriundos de multiplas fontes, como dados financeiros de uma bolsa de valores. Neste artigo vou introduzir uma forma de resolver alguns problemas usando multiplexação de I/O através da api IO::Select, que utiliza o conceito de I/O não bloqueante, através de uma simples aplicação de chat como exemplo.

## Introdução

Um dos problemas de lidar com entrada e saída de dados (seja com arquivos ou através de uma rede, por exemplo) é a diferença de tempo nas operações (leitura ou escrita) se compararmos com as mesmas operações em memória. Tipicamente é muito mais rapido escrever um conjunto de bytes na memória e isso se deve à natureza dos dispositivos: ao gravar em um disco existe uma operação física de mover o cabeçote até uma dada posição e fazer todo o trabalho magnético, mecânico e as vezes optico. Hoje em dia, a latência para ler 1 MB sequencial na memória ram pode ser cerca de 80 vezes mais rapido do que ler em um disco rígido (é claro, tudo depende do hardware envolvido), como pode ser encontrado [aqui](https://gist.github.com/jboner/2841832).

Essa diferença entre á latência do I/O e operações em memória foi uma das motivações para criar os primeiros sistemas operacionais de tempo compartilhado. Foi percebido, por exemplo, que no tempo gasto esperando que uma operação de I/O fosse concluida poderiam ser feitas outras operações em memória, no caso se um computador estivesse executando um programa financeiro que manipulava dados ele poderia ceder parte do seu tempo na cpu para um programa de engenharia que basicamente fazia diversos calculos numéricos e assim os recursos da maquina eram utilizados de forma mais racional.

Hoje em dia o sistema operacional é responsável pelas operações de entrada e saída e quando um processo precisa fazer uma dessas operações a CPU não fica esperando que a leitura (ou escrita) termine, ela coloca o processo em um estado de espera executa outros processos (dando uma pequena fatia de tempo para cada processo de acordo com o algoritmo usado no escalonador de processos) e, dessa forma, simulamos que um sistema operacional executa varios processos simultâneamente (como quando estamos com varias abas do browser, o editor de texto, o player de musica e o cliente de email abertos ao mesmo tempo). O panorama é melhor com as modernas CPUs que possuem varios pares de núcleos, oferencendo paralelismo real aliado ao pseudo-paralelismo do algoritmo do sistema operacional.

## I/O bloqueante

Uma das características das operações de entrada e saída é que elas são geralmente *bloqueantes*, isto é, no exemplo abaixo

	open my $file,'<', "picture.jpg" or die $!;
	binmode $file;
	my ($buf, $data, $n);
	while (($n = read $file, $data, 4) != 0) {
	  print "$n bytes read\n";
	  $buf .= $data;
	}
	close($file);

cada vez que a subrotina "read" é invocada, o processo vai bloquear até que a leitura seja completa. Isso parece ser razoável se estamos tralhando com apenas um arquivo (ou um socket de rede) mas se for preciso lidar com muitas operações em diferentes arquivos/sockets, estes bloqueios podem ser um problema.

Dependendo do problema que queremos resolver, isto pode não ser tão ruim assim. Imagine um servidor HTTP, que apenas serve arquivos estáticos: o HTTP é um protocolo stateless, ou seja, tudo o que precisamos fazer para fazer o download de um arquivo é fazer um unico request correto (não há memória do que ja foi feito, por assim dizer). É claro que nós temos exemplos onde isto não é verdade, no caso de um conteúdo protegido para um dado usuario, numa dada sessão (iniciada em uma tela de login). Isto só é possivel pois construimos em cima do HTTP uma abstração de sessão, utilizando cookies (por exemplo) para associar uma sessão (em um banco de dados) à um usuario, por exemplo.

Este tipo de detalhe faz toda a diferença se queremos determinar como um sistema vai escalar. Imagine que queremos atender 4000 requisições dentro de um segundo: uma arquitetura stateless é muito mais facil de conseguir isso pois, teoricamente, bastariamos ter 40 servidores capazes de atender 100 requisições por segundo atrás de um conjunto de balanceadores de carga. Como cada servidor não mantem estado, simplificamos a solução do problema e podemos, inclusive, usar IO bloqueante através de servidores baseados em forking/spawning, como no exemplo abaixo em pseudo-código:

	while(1){
		my $connection = $socket->accept();

		# a chamada fork vai criar um subprocesso, copiando o processo pai
		# em memória, assim o filho cuida da nova conexão e o pai apenas
		# espera novos clientes - não bloqueia lidar com multiplos clientes
		# pois cada cliente é responsabilidade de um processo apenas.
		if(my $pid = fork) {
			# no processo pai, fechamos o socket e
			# continuamos esperando novas conexoes
			$connection->close();
		} else {
			# no processo filho,
			# lemos o socket e processamos o request
			$connection->read();
		}
	}

Esta é uma razão pela qual preferir pela imutabilidade em certos casos nos traz grandes vantágens: como gerenciar um estado mutável pode ser uma tarefa complexa, sistemas onde temos o nosso estado "imutável" tende a escalar com mais facilidade, por esta razão linguagens funcionais como Erlang fazem tanto sucesso para resolver esta classe de problemas. Mas usar uma linguagem funcional não é uma bala de prata. Outra coisa é achar que apenas criar um novo processo resolve os nossos problemas: cada processo é relativamente caro dependendo do sistema operacional e mesmo utilizando tecnicas como Copy on Write *podemos* ter uma ineficiente no uso dos recursos da maquina em algum momento, se formos atender um número muito grante de requests.

Agora, vamos imaginar, por exemplo, uma aplicação de chat, onde varios clientes podem se conectar e trocar informações entre si. Este exemplo é interessante pois nós temos um estado interno no nosso sistema, afinal todos os clientes interagem com todos e se nós distribuirmos a carga entre varios processos nós teremos a complexidade extra de sincronizar e nos comunicar entre os processos também! Se o nosso servidor utilizar IO bloqueante, provavelmente vamos ter algo como:

	# iniciamos o nosso servidor tcp
	my $server = IO::Socket::INET->new(
	    Proto     => 'tcp',
	    Reuse     => 1,
	    Listen    => SOMAXCONN,
	    LocalPort => 9090) or die "ops... $!\n";

	# main loop
	while(1){
		for my $socket_in (@sockets){
			perform_read $socket_in;
		}
		process_data;
		for my $socket_out (@sockets){
			perform_write $socket_out;
		}
	}

imagine o caso se o cliente 1 enviou a mensagem "oi" para o cliente 2. eu vou ler as entradas de todos os clientes, vou processar os dados e vou escrever a mensagem para todos os clientes, no caso o cliente 2. Mas se eu tiver varios clientes e nem todos estão escrevendo algo? Este é o problema com IO bloqueante: é preciso estabelecer um timeout pois não é possivel saber se virá alguma sequencia de bytes ou não. Assim imagine que trabalhamos com timeout de 1 segundo e tenha, por exemplo, 1000 clientes. Cada ciclo de processamento poderá levará até 2 mil segundos para ser completado. Parece ser ineficiente se tudo passar por apenas um processo (e seriamos forçado a trabalhar, por exemplo, com o overhead de ter multiplos processos -as vezes em maquinas diferentes- e, dependendo da natureza da aplicação, ficará bem complexo - não que seja possivel fugir disso).

Como visto até agora, podemos usar I/O não bloqueante de forma satisfatória em algumas condições: onde cada bloqueio na operação de read/write não seja um problema e temos a opção de distribuir o processamento via fork. Para outros problemas isto simplesmente não é aceitavel pois em um dado regime de acesso o sistema pode não responder de forma adequada.

### I/O não bloqueante

E se fosse possivel ler apenas de quem está enviando dados? Ou escrever em quem está pronto para receber? Seria uma dica e tanto. Este é o principio do I/O não bloqueante e neste artigo vamos ver um exemplo "simples": um chat. No começo da internet as primeiras salas de bate papo eram serviços onde se conectava via um programa chamado telnet, que abria uma simples conexão tcp-ip com o servidor, e dezenas de pessoas podiam conversar de acordo com a implementação do servidor (alguns sistemas eram verdadeiros jogos de MMORPG onde alem de conversar era possivel jogar rpg de forma textual, por exemplo, os chamados MUDs). Este exemplo é interessante pois é bem facil de interagir.

Um outro motivo para utilizar um exemplo com sockets é que a API do IO::Select funciona muito bem em ambientes POSIX, mas em termos de portabilidade o *select* foi implementado apenas para sockets em ambiente Win32 e VMS, e é confiavel apenas em sockets no RiscOS. É possivel adaptar o exemplo para arquivos ou outro tipo de dispositivo de entrada e saída mas irá funcionar apenas em alguns sistemas operacionais como o Linux, FreeBSD e o MacOS X (na duvida, siga o perlport).

Felizmente, nesses sistemas operacionais, praticamente tudo relacionado a I/O pode ser visto como um arquivo (um socket, um dispositivo, um pipe entre processos), então a interface é praticamente a mesma (sera usado read/write independente do *filehandle* ser um socket ou um arquivo).

Existem, basicamente, duas formas de trabalhar com I/O não bloqueante seguindo a interface POSIX: select e poll. Os dois se baseam na seguinte ideia: os filehandles que queremos tratar de forma não bloqueante são registrados no select (ou no poll) e então perguntamos, no nosso main loop, para o select (ou poll), quais filehandles podem ser lidos/escritos naquele momento. É por isto que esta tecnica é chamada de multiplexação de I/O, pois não estamos lendo ou escrevendo em varios streams ao mesmo tempo, mas selecionamos quem pode ser acessado e não perdemos tempo com timeouts.

Um fato importante a respeito de I/O: nem sempre a CPU controla todo o processo de entrada e saída de dados. Existem tecnicas como a DMA (Direct Memory Access) onde a CPU simplesmente diz para a controladora de disco "copie dos dados que estão na região X de memória e me avise quando terminar". Por isto a escolha do sistema operacional é importante para uma dada aplicação que faça I/O de forma intensiva. Para obter uma melhor performance o conjunto todo (software, hardware, sistema operacional) é importante.

A primeira coisa que precisamos fazer para trabalhar com select é escolher qual a abordagem: se procedural, utilizando a subrotina *select* ou orientada a objetos, utilizando IO::Select (ambas built-in). IMHO a interface OO é mais interessante de trabalhar, mas nada impede que a interface procedural seja usada.

Agora, para utilizar o select é necessario que o filehandle tenha o bit de não bloqueante (O_NONBLOCK) ativado, sem isto o nosso programa não vai funcionar. Por exemplo, se iniciarmos o nosso servidor utilizando IO::Socket::INET como mostramos anteriormente, ele vai possuir o seguinte conjunto de flags:

	Flags      00000010 do filehandle $server
	-------------------
	O_RDONLY   00000000
	O_WRONLY   00000001
	O_RDWR     00000010
	O_NONBLOCK 00000100

como podemos ver, apenas O_RDWR está ativo, o que significa que podemos escrever e ler nesse filehandle.

Temos duas formas de setar o bit O_NONBLOCK, o primeiro é utilizando a subrotina *fcntl*

	my $flags = fcntl($socket, F_GETFL, 0)       or die "Can't get flags for socket: $!\n";
	fcntl($socket, F_SETFL, $flags | O_NONBLOCK) or die "Can't make socket nonblocking: $!\n";

ou utilizando IO::Handle, basta usar o método *blocking*

	$socket->blocking(0);

a outra é especificar na hora de abrir o filehandle. No caso do IO::Socket::INET basta fazer

	my $socket = IO::Socket::INET->new(
	    Proto     => 'tcp',
	    Reuse     => 1,
	    Listen    => SOMAXCONN,
	    LocalPort => 9090,
	    Blocking  => 0
	    ) or die "ops... $!\n";

agora vamos adicionar este socket ao nosso select

	my $select = IO::Select->new;

	$select->add($server);

e assim construimos o nosso main loop

	sub process_read{}
	sub process_data{}
	sub process_write{}

	use constant TIMEOUT => 0.5;

	while(1) {
	  foreach my $socket ($select->can_read(TIMEOUT)){
	    process_read $socket;
	  }
	  process_data;
	  foreach my $socket ($select->can_write(TIMEOUT)){
	    process_write $socket;
	  }
	}

perceba que o código é semelhante ao primeiro exemplo, a diferença é que primeiro eu vou processar quem eu posso ler (can_read), depois vou analisar cada entrada para, no final, escrever em que eu posso (can_write). E nosso tutorial de IO não bloqueante terminaria aqui, se não fosse necessario adicionar o codigo necessário para fazer o nosso exemplo funcionar.

Vamos estabelecer o que cada função de processamento faz. Neste exemplo, ao processar a leitura de cada socket vamos guardar os bytes recebidos em um *buffer* de memória (um buffer por cliente, neste caso) porém, caso o socket seja o $server, vamos aceitar a nova conexão, registrando no select.

	sub process_read{
	  my $socket = shift;

	  # diferenciando o servidor dos clientes
	  if ($socket == $server) {
	    process_new_connection;
	  } else {
	    process_read_to_buffer $socket;
	  }
	}

e as nossas novas subrotinas serão:

	# nossa lista de clientes conectados
	my %clients;

	sub process_new_connection {
	  # vou atribuir um nome, ou id, randomico
	  my $name = rand();

	  # nosso log :)
	  say "new client: $name connected!\n";

	  # aceito a conexão e adiciono no select
	  my $new = $server->accept;
	  $select->add($new);

      # agora vou avisar cada cliente que temos gente nova!
	  foreach my $client (values %clients){
	    $client->{out_buffer} .= "\n$name connected...\n";
	  }

	  # adiciono uma estrutura de dados associado a este cliente/socket
	  $clients{$new} = { name => $name, in_buffer => "", out_buffer => ""};
	}

	sub process_read_to_buffer {
	  my $socket = shift;

      # aqui eu verifico se tenho o socket na minha lista de clientes
	  if( exists $clients{$socket} ){
		  # aqui vou tentar ler de forma bufferizada
	      my $rv = $socket->sysread(my $data, POSIX::BUFSIZ, 0);

		 if(defined($rv) && length $data) {
			  # se eu recebi algo, vou escrever no buffer de entrada
	          $clients{$socket}->{in_buffer} .= $data;
	      } elsif ($! != POSIX::EAGAIN) {
		      # caso contrario, significa que o cliente Desconectou
	          my $name = $clients{$socket}->{name};

	          say "delete client $name";

		      # removo da lista de clientes
	          delete $clients{$socket};
			  # e vou avisar todo mundo
	          foreach my $client (values %clients){
	            $client->{out_buffer} .= "\n$name disconnect...\n";
	          }
	      }
	  # se eu não tenho, removo do select e fecho o socket.
	  } else {
	      say "client disconnected";
	      $select->remove($socket);
	      $socket->close;
	  }
	}

Agora vamos processar os buffers de saida. É possivel perceber que para cada socket eu associo um hash contendo o nome, e dois buffers, um de entrada e um de saida. Percebam que estou escrevendo na saida padrão o que esta acontecendo através da subrotina *say*, apenas para ver o que esta acontecendo. Isto também é uma atividade de I/O e cada chamada de say é bloqueante! Pode não adiantar de nada ler os sockets de forma não bloqueante se, em dado momento, temos uma chamada que bloqueia o processo. O ideal é que TODO o I/O seja feito de forma que o processo nunca bloqueie e é por esta razão que temos duas entradas no hash que representa cada cliente do nosso servidor de chat: toda a comunicação é processada em memoria como é possivel ver abaixo:

	sub process_data{
	  # todos falam com todos:
	  foreach my $a (values %clients){
	    my $name    = $a->{name};
	    my $message = $a->{in_buffer};

		# o protocolo é simples: tudo o que eu escrever, será mostrado para todos na "sala"
	    # se não tenho nada para dizer, vamos para o proximo
	    next unless $message;
	    foreach my $b (values %clients){
	      # escrevo no buffer de saida de todos
	      $b->{out_buffer} .= "\n" . ( $b->{name} eq $name ? "You": $name ) . " say: $message";
	    }

	    # limpo o meu buffer
	    $a->{in_buffer} = '';
	  }
	}

e quando eu puder escrever, vou escrever:

	sub process_write{
	  my $socket = shift;

	  return unless (exists($clients{$socket}) &&    # vou escrever apenas nos clientes conectados
	      length($clients{$socket}->{out_buffer}));  # e vou escrever apenas se houver algum buffer

	  # aqui vou escrever de forma bufferizada
	  my $rv = $socket->syswrite($clients{$socket}->{out_buffer}, POSIX::BUFSIZ);

	  # e vou remover a quantidade de bytes que eu escrevi do buffer.
	  if ($rv || $! == POSIX::EAGAIN) {
	      substr($clients{$socket}->{out_buffer}, 0, $rv) = '';
	      $clients{$socket}->{out_buffer} = '' unless length $clients{$socket}->{out_buffer};
	  }
	}

perceba que eu utilizei esta tecnica para gerenciar de forma mais racional os recursos do sistema operacional. Através da API POSIX do select, é possivel trabalhar com I/O de forma que o processo nunca bloqueie em cada operação de I/O (apesar de ter um timeout nas operações). Importante: sempre utilize sysread e syswrite (operações bufferizadas) quando for utilizar operações em conjunto de um select ou poll. Não tente usar read ou o operador diamante < $file >.

Uma coisa importante de mencionar é o uso do **POSIX::EAGAIN** - que significa "Resource temporarily unavailable". Isto é importante pois no modo não bloqueante as chamadas sysread and syswrite ainda podem bloquear por alguma razão (por exemplo se o filehandle foi acessado diretamente e não houve auxilio do select, como neste [exemplo](http://docstore.mik.ua/orelly/perl/cookbook/ch07_15.htm) ), nesse caso a chamada ira retornar undef e $! receberá o valor de EAGAIN.

O codigo final do nosso servidor de chat pode ser encontrado [aqui](https://gist.github.com/peczenyj/5127157).

### Considerações finais

Acredito que o exemplo, apesar de simples, é interessante o suficiente para ser expandido de forma a comportar soluções mais complexas. Fica como sugestão ao leitor expandir a subrotina *process_data* de forma a suportar um pequeno protocolo, por exemplo as mensagens que começarem com @ seriam comandos da nossa sala de chat, assim teriamos

* @help - mostra esta tabela
* @who - mpstra quem esta conectado
* @rename [novo nome] - renomeia o usuario (afinal 0.489873510410206 é algo feio)
* @quit - sai da sala
* @stat - mostra estatisticas do servidor (uptime, versao, etc)
* @say [mensagem] - envia mensagem para todos / podemos ignorar o que nao começa por @
* @privmsg [x] - envia mensagem privada para o usuario x

Um outro exemplo, até mais interessante, seria construir um replicador de eventos. Nesse poderiamos criar um script que escuta em duas portas (9090 e 9099, por exemplo) e tudo o que conectar na porta 9090 e escrever lá, será transmitido para os clientes conectados na porta 9099. Imagine que na porta 9090 estamos recebendo um stream de um video ao vivo e temos N clientes conectados na 9099 consumindo este video, se o protocolo de streaming não necessitar de algum handshake entre o servidor e o cliente. Um exemplo desse tipo de protocolo é o HTTP Streamming, que é basicamente uma playlist em ascii contendo URLs com trechos de 10 segundos de video, geralmente trabalhando com um buffer de 30 segundos (de atraso). Os clientes podem consumir a lista de urls e então fazer o download do video. Nem tudo precisa ser trafego de bytes, alguns procotos podem (as vezes devem) ser simples e até textuais.

É interessar ressaltar que muitos sistemas complexos só consequem escalar para trabalhar com milhares de requests ao mesmo tempo devido a simplicidade dos seus protocolos e da sua implementação.

### Utilizando I/O Não bloqueante na prática

O IO::Select é uma interface interessante e é built-in do perl desde a versão 5.00307, porém pode ser maçante utilizar o select de forma crua. No cpan podemos encontrar muitas opções como IO::Multiplex, que oferece a opção de criar uma classe ou objeto e seta-lo como callback de forma que podemos criar interfaces mais consistentes e escrevemos menos codigo. Por exemplo, utilizando IO::Multiplex precisamos basicamente escrever uma subrotina *mux_input* ao inves de escrever um script com 116 linhas (é um dos primeiros exemplos da documentação). Outro exemplo interessante é o Net::Server::NonBlocking.

Existem outras opções de trabalhar com I/O não bloqueante em Perl, destacando-se Coro, POE e Any::Event, este ultimo oferece uma interface comum as demais implementações, todas as opções estão disponíveis no CPAN.

Se queremos trabalhar com muitos filehandles de forma eficiente, temos que fazer uso de uma interface eficiente e robusta, entretanto o fluxo de execução normal do nosso programa pode não ser obvio, por exemplo em sistemas baseados em callbacks pode ser dificil de testar adequadamente (ou nossos testes podem utilizar mocks da API mas apenas para os casos mais simples). E as vezes é tentador criar callbacks como subrotinas anônimas que retornam outras subrotinas anônimas e em um dado momento fica obscuro como testar ou como tratar de forma eficiente exceções dentro do nosso codigo.

Um detalhe importante: o select conseque trabalhar com até 1024 filehandles. Para trabalhar com mais uma alternativa é utilizar poll (através de IO::Poll). Um boa discussão sobre select versus poll pode ser encontrada [aqui](http://daniel.haxx.se/docs/poll-vs-select.html).

Um outro perigo: Veja por exemplo que estamos trabalhando com memoria o tempo todo: imagine que alguem conecta e começa a inundar o sistema com bytes e mais bytes. Isto pode ser válido do ponto de vista do protocolo e levar a exaustão de recursos! A maxima aqui é verificar tudo e setar limites sempre, mesmo que a interação seja entre serviços. Imagine que temos um sistema A que envia eventos para o sistema B, e o sistema B trata de rotear esses eventos para diferentes clientes. Se não houver clientes conectados ou a conectividade entre B e os clientes esteja prejudicada com muita perda de pacote, pode ser que A escreva numa taxa maior do que B conseque enviar para os clientes, levando a um estouro de memória.

Por fim, neste exemplo eu adicionei um log com, basicamente, um say escrevendo na saida padrão (e poderia ser um log em arquivo). Este é um erro basico como ja comentei - pois o processo vai bloquear e numa situação real pode significar um sistema até inoperante pois é ineficiente para lidar com o proprio log (ao inves de utilizar o select para gerenciar a escrita na STDIN também). O Any::Event possui, por exemplo, um sistema de log não bloqueante que vale a pena ser considerado. Existem soluções para bancos de dados como o Mango, um cliente non-blocking para MongoDB.

###Curiosidade

É possivel criar uma pausa de fração de segundos usando select, através da forma

	select(undef, undef, undef, 0.25);

neste caso uma pausa de 0.25 segundos. Não é incomum encontrar scripts com este tipo de construção.

###Referencias

O livro 'Advanced Programming in the UNIX(R) Environment' de W. Richard Stevens aborta alguns aspectos da API Não bloqueante POSIX adotada neste artigo, indo a fundo com algumas exemplos em C.

O capitulo 13 do livro 'Network Programming With Perl' do Lincoln D. Stein possui mais detalhes e exemplos, como um servidor de chat com o Bot Eliza e um cliente http.

[Aqui](http://www.perlmonks.org/?node_id=881518) pode ser encontrado alguns detalhes e exemplos interessantes da implementação em perl do select.

###AUTOR

Tiago Peczenyj, [github.com/peczenyj](https://github.com/peczenyj/) / [pacman.blog.br](http://pacman.blog.br/) / [CPAN:PACMAN](https://metacpan.org/author/PACMAN) / [@pac_man](https://twitter.com/pac_man)

###Licença

Texto sob Creative Commons - Atribuição - Partilha nos Mesmos Termos 3.0 Não Adaptada,
mais informações em [http://creativecommons.org/licenses/by-sa/3.0/](http://creativecommons.org/licenses/by-sa/3.0/)