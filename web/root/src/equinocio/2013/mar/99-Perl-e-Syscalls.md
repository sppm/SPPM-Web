# Trabalhando com Perl e Chamadas de Sistema (Syscalls)

## Resumo

Em algum momento podemos precisar recorrer ao uso de chamadas de sistema (ou syscall) do sistema operacional para efetuar alguma tarefa, seja relacionada a entrada e saída de dados (I/O), manipulação de processos ou mesmo por curiosidade. Neste artigo vamos ver brevemente com podemos manipular as syscalls do sistema operacional em Perl dando enfase nos ambientes Linux e Mac OS X.

## Introdução

Nos modernos sistemas operacionais toda a tarefa de controle de processos, alocação de recursos e I/O é feita exclusivamente pelo sistema operacional e a interface com o Kernel para efetuar estas tarefas se chamam chamadas de sistema. Se formos pensar em como funciona a CPU do nosso computador, ela é um simples executador de tarefas: se eu passar um conjunto de tarefas que escreva em um arquivo, por exemplo, a CPU vai fazer independente disso ser permitido ou não. Isto no passado foi um grande desafio para suportar múltiplos usuários, por exemplo, por para conseguir detectar uma atividade de I/O de forma a suspender um processo e dar uma fatia de tempo da cpu a outro processo.

Quem traz o conceitos como o de permissão de acesso a um determinado arquivo, por exemplo, é o sistema operacional. Como nós não podemos executar determinados tipos de tarefas diretamente o que nos resta é pedir, através de uma syscall, para que o Kernel faça uma determinada tarefa e vamos receber um status de sucesso ou erro de acordo com o contexto (checar permissões por exemplo). Isto só é possível por que as modernas CPUs podem trabalhar em dois modos: o *real* (onde ela pode executar todas as instruções) e o *protegido* (onde só é possível executar um subconjunto restrito de instruções).

O Kernel do sistema operaciona, por exemplo, roda em modo real e, dessa forma, pode efetuar todas as tarefas necessarias para o funcionamento do sistema. Quando rodamos o programa de um usuário, por exemplo o editor de texto, este roda no modo protegido e só poderá fazer certas atividades através de uma chamada de sistema pois o mesmo roda em modo *protegido*. É tarefa do sistema operacional dividir o tempo da cpu entre vários processos (num pseudo-paralelismo) e controlar o estado da CPU afim de introduzir um isolamento real entre os diversos processos e os recursos controlados pelo sistema. Dessa forma dizemos que os programas rodam em *user land* enquanto que a real atividade de I/O executa em *kernel land*.

Feita esta introdução, vamos analisar algumas syscalls mais interessantes e vamos fazer uso da subrotina built-in *syscall* do Perl.

## Lista de Syscalls

Uma coisa importante deve ser dita: cada sistema operacional (SO) oferece um conjunto diferente de chamadas de sistemas. Dessa forma formos optar por invocar uma ou mais syscalls devemos prestar atenção na questão da portabilidade do nosso software. Nesse caso é interessante restringir o software a rodar em outros SOs sob pena de não funcionar corretamente. De cara percebemos que o built-in *syscall* não foi implementado para alguns SOs como Win32, VMS, RISC OS, VOS e VM/ESA. Na duvida consulte sempre o [http://perldoc.perl.org/perlport.html#syscall](perlport).

O Linux, por exemplo, possui 139 chamadas de sistema diferente, onde podemos destacar

* `sys_exit` - termina o processo corrente
* `sys_fork` - cria um processo filho
* `sys_getpid` - retorna o pid do processo
* `sys_read` - le dados a partir de um file descriptor
* `sys_write` - escreve dados (semelhante ao sys_read)
* `sys_open` - abre um arquivo ou dispositivo
* `sys_close` - fecha um arquivo ou dispositivo
* `sys_waitpid` - aguarda pelo termino de um determinado processo
* `sys_mount` - monta um novo sistema de arquivos
* `sys_umount` - desmonta um sistema de arquivos
* `sys_getuid` - pega o identificador do usuário corrente (0 significa root)
* `sys_kill` - envia um sinal para um determinado processo

Cada chamada de sistema espera um conjunto de parâmetros especificos para aquela atividade. O sys_fork, por exemplo, não requer nenhum parâmetro, por outro lado para ler um arquivo precisamos informar o número do file descriptor, um buffer e o tamanho máximo do buffer. O retorno da syscall também é importante: no caso do fork podemos distinguir entre o processo pai ou filho enquanto o read retorna o número de bytes lidos daquele file descriptor.

É possível encontrar a lista completa [http://asm.sourceforge.net/syscall.html](aqui).

Como o Mac OS X é baseado em BSD, ele possui muitas syscalls semelhantes ao Linux.

###Invocando a Primeira Chamada de Sistema

O built-in syscall é definido, na documentação, como algo que recebe um número e uma lista

	syscall NUMBER, LIST

O número que devemos passar para a subrotina é o numero da syscall, definida no arquivo syscall.h do seu sistema operacional. Como estou utilizando um Mac neste momento, eu consultei o /usr/include/sys/syscall.h e vi que o valor de `SYS_getpid` é 20. Também sei que esta chamada de sistema não exige nenhum argumento, portanto posso fazer um breve teste:

	$ perl -e 'print "pid, por variavel = $$, por syscall = " . syscall(20) . "\n";'
	pid, por variavel = 8023, por syscall = 8023

Podemos importar a lista de todas as chamadas de sistema através do programa h2ph

	$ cp /usr/include/sys/syscall.h .
	$ h2ph -d . syscall.h
	syscall.h -> syscall.ph
	$ head syscall.ph
	require '_h2ph_pre.ph';

	no warnings 'redefine';

	unless(defined(&_SYS_SYSCALL_H_)) {
	    eval 'sub _SYS_SYSCALL_H_ () {1;}' unless defined(&_SYS_SYSCALL_H_);
	    require 'sys/appleapiopts.ph';
	    if(defined(&__APPLE_API_PRIVATE)) {
		eval 'sub SYS_syscall () {0;}' unless defined(&SYS_syscall);
		eval 'sub SYS_exit () {1;}' unless defined(&SYS_exit);
		...

dessa forma, podem carregar uma lista das syscalls disponíveis e tornar o código um pouco mais legível (e até portavel)

	use strict;
	use warnings;
	use feature 'say';

	require 'syscall.ph';

	say "pid = $$, via syscall = ",syscall(SYS_getpid());

que executando retornará

	$ perl a.pl
	pid = 8144, via syscall = 8144

Uma outra syscall interessante é a sync, que escreve todo os buffers em memória nos discos físicos (uma das ultimas atividades antes de desligar um servidor, por exemplo).

	require "syscall.ph";
	syscall SYS_sync();

###Syscalls que exigem parâmetros

Um bom exemplo é a chamada de sistema `sys_write`, que recebe o número do file descriptor, uma string e o comprimento da mesma para escrever.

	require "syscall.ph";

	my $msg = "mensagem para ser escrita na saída de erro (STDERR)";
	syscall(SYS_write(), 2, $msg, length $msg);

neste caso estamos chamado a syscall passando número 2, que geralmente é associado a saída de erro.

Outro exemplo interessante é a chamada de sistema sysinfo (presente no Linux) pode retornar uma série de informações do sistema como uptime, memória disponivel, etc. Para invocar esta syscall devemos passar uma estrutura de dados que será preenchida com estas informações, a struct sysinfo.

	struct sysinfo {
	   long uptime;             /* Seconds since boot */
	   unsigned long loads[3];  /* 1, 5, and 15 minute load averages */
	   unsigned long totalram;  /* Total usable main memory size */
	   unsigned long freeram;   /* Available memory size */
	   unsigned long sharedram; /* Amount of shared memory */
	   unsigned long bufferram; /* Memory used by buffers */
	   unsigned long totalswap; /* Total swap space size */
	   unsigned long freeswap;  /* swap space still available */
	   unsigned short procs;    /* Number of current processes */
	   char _f[22];             /* Pads structure to 64 bytes */
	};

Como sabemos, uma struct em C não é a mesma coisa que um hash em Perl, para decodificar isto precisamos utilizando o built-in unpack

	require "syscall.ph";

    my $buf = "\0" x 64;

    syscall(SYS_sysinfo(), $buf) == 0 or die "$!\n";

	# 'l L9 S' significa:
	# 1 long
	# 9 entradas de um unsigned long
	# String (null termined)
    my ($uptime, $load1, $load5, $load15, $totalram, $freeram,
        $sharedram, $bufferram, $totalswap, $freeswap, $procs)
            = unpack "l L9 S", $buf;

    print <<EOT;
    ${\(int $uptime / 86400)} days uptime
    $totalram RAM, $freeram free (${\(int $freeram/$totalram*100)}%)
    $totalswap swap, $freeswap free (${\(int $freeswap/$totalswap*100)}%)
	EOT

que retorna

    142 days uptime
    528662528 RAM, 35692544 free (6%)
    536862720 swap, 506224640 free (94%)

###Considerações Finais

De posse da documentação oficial das chamadas de sistema do seu sistema operacional é possível utilizar perl para fazer uma interface direta com o kernel, bastando respeitar as convenções e lembrar de fazer o unpack correto da resposta quando necessário. Isto pode ter muitas aplicações, geralmente com algum propósito muito especifico. Perl provê interfaces para as principais chamadas de sistema como fork, print, read, stat ou select mas isso não significa que não podemos chamar uma syscall específica para fazer algo que ou não é provida pela linguagem ou queremos ter um controle maior do que esta acontecendo.

É interessante perceber que Perl é uma linguagem de propósito geral, que suporta tanto uma abstração como orientação a objetos como oferece suporte a chamadas de sistema. Isso nos dá uma grande flexibilidade e podemos expandir o pequeno set de operações que a linguagem nos oferece indo trabalhar com algo especifico de uma familia de sistemas operacionais (sacrificando a portabilidade) mas que possa fazer sentido na resolução do nosso problema. De qualquer forma, minha preferência é sempre utilizar os built-ins do Perl, quando possível, por ser algo mais uniforme e cujo comportamento é descrito pela documentação da linguagem e não daquela particular chamada de sistema, naquele particular sistema operacional. Eu vejo esta possibilidade (de usar syscall) como algo especial e que merece ser testada de forma muito objetiva para evitar uma dor de cabeça (como trocar o número da syscall - nós vamos descobrir apenas quando o código executar).

## AUTOR

Tiago Peczenyj


[github.com/peczenyj](https://github.com/peczenyj/) / [pacman.blog.br](http://pacman.blog.br/) / [CPAN:PACMAN](https://metacpan.org/author/PACMAN) / [@pac_man](https://twitter.com/pac_man)

###Licença

Texto sob Creative Commons - Atribuição - Partilha nos Mesmos Termos 3.0 Não Adaptada,
mais informações em [http://creativecommons.org/licenses/by-sa/3.0/](http://creativecommons.org/licenses/by-sa/3.0/)