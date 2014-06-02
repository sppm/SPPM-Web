Aplicando uma Rede Neural Hopfield
==================================

Redes neurais artificiais são modelos matemáticos inspirados em redes neurais biológicas. Neurocientistas definem essas redes biológicas como séries de neurônios interconectados cuja ativação define de forma clara e reconhecível caminhos lineares. As redes artificiais têm como objetivo mimetizar essa arquitetura existente no sistema nervoso central, onde nós artificiais representam neurônios conectados entre si.

Nas áreas da engenharia e da matemática, as redes neurais são comumente utilizadas para classificação de padrões e como filtros lineares não adaptativos. Da mesma forma que as redes biológicas, redes artificiais agem como sistemas adaptativos, isso significa que cada parâmetro é alterado durante a sua operação para então ser aplicado ao problema em si. Este é o processo conhecido como fase de treinamento.

As redes neurais são basicamente sistemas, isso significa que possuem uma estrutura preparada para receber um input, processar os dados e fornececer um output. Normalmente o input da rede consiste em um array de dados originado a partir de diferentes fontes como arquivos de imagem ou som, por exemplo. Uma vez apresentado o input à rede neural, e ocorrendo a formação de um output correspondente, uma taxa de erro é estabelecida a partir da diferença existente entre a resposta e o output real. A partir desse ponto a rede neural é retro-alimentada, permitindo assim ajustes aos parâmetros (aprendizado).

A Rede Neural Hopfield
----------------------

O modelo Hopfield de rede neural é provavelmente o mais simples que existe. A rede Hopfield pode ser descrita como uma rede autassociativa, tendo uma única camada de neurônios totalmente conectada. Isso significa que apenas uma camada de nós existe e que todos estão conectados a todos. Autoassociativo significa que se a rede neural reconhecer um padrão,
ela irá retorná-lo como output.

O Módulo AI::NeuralNet::Hopfield
-------------------------------

A seguir vamos ver os detalhes do módulo AI::NeuralNet::Hopfield recentemente incluído no CPAN. Além do modelo de Hopfield é possível também encontrarmos diversos outras implementações de redes neurais artificiais no CPAN.

Por motivos de simplicidade não irei repassar os detalhes das operações com as matrizes numéricas, o cerne matemático da rede neural baseia-se em uma série de cálculos realizados com as matrizes como subtração, multiplicação, inversão e identidade. Todas essas operações podem ser facilmente encontradas na literatura.

Iniciamos a utilização da rede instanciando um objeto tipo Hopfield. Para tal, precisamos definir o número de neurônios da rede. A matriz 4x4 representa a conectividade existente entre todos os 4 neurônios.

    use AI::NeuralNet::Hopfield

    $hop = AI::NeuralNet::Hopfield->new(row => 4, col => 4);

Neste momento a matriz de conectividade também chamada de matriz de peso está vazia contendo apenas zeros, ou seja não possui memória.
Vamos definir agora um array de entrada da rede, o input. Este array será usado para o treinamento da rede e será constituído por valores booleanos. Em seguida a rede será treinada para estabelecer a memória dos neurônios.

    @input_1 = qw(true true false false);
    $hop->train(@input_1);

A partir desse momento já podemos começar a apresentar padrões à rede e avaliar o resultado do reconhecimento dos padrões. Vamos começar estando a rede com o mesmo padrão apresentado a ela:

    @input_2 = qw(true true false false);
    @result = $hop->evaluate(@input_2);

    Resultado:
    [0] "true",
    [1] "false",
    [2] "false",
    [3] "true"

Podemos ver que a rede respondeu com o mesmo padrão dado a ela inicialmente, isso ocorre por ser uma rede autoassociativa, portanto ela irá 'ecoar' o padrão reconhecido.

Vamos testar com outro padrão diferentes:

    @input_1 = qw(true false false false);
    @result = $hop->evaluate(@input_2);

    Resultado:
    [0] "true",
    [1] "false",
    [2] "false",
    [3] "true"

Nesse caso a rede respondeu novamente com o mesmo padrão. A rede não reconheceu o padrão fornecido, como o mais similar é o padrão 1001 a rede determinou que o padrão fornecido possui um erro e tentou corrigi-lo.

Uma característica das redes Hopfield é que elas sempre são treinadas para o inverso binário do padrão fornecido, neste caso o padrão 1001 (true, true, false, false). Então se fornecermos a ela o padrão inverso, teremos o mesmo padrão sendo 'ecoado'.

    @input_3 = qw(false true true false);
    @result = $hop->evaluate(@input_3);

    Resultado:
    [0] "false",
    [1] "true",
    [2] "true",
    [3] "false"

Por fim, vamos apresentar à rede um padrão totalmente estranho a ela:

    @input_4 = qw(false false false false);
    @result = $hop->evaluate(@input_4);

    Resultado:
    [0] "false",
    [1] "false",
    [2] "false",
    [3] "false"

Neste caso a rede respondeu com falso para todos os elementos, não houve tentativa de correção pois o modelo apresentado é bastante diferente do que a rede possui em memória.

Conclusão
---------

Redes neurais artificiais são sistemas extremamente eficientes para a  resolução de questões que envolvam problemas relacionados a classificação, predição e reconhecimento de padrões. é possível hoje encontrar diferentes tipos de implementações e algoritmos para tais problemas.

Por ser fácil, ágil e rápida, o Perl é uma linguagem bastante apropriada para a implementação de algoritmos de redes neurais, quem possuir curiosidade em testar outros algoritmos pode encontrá-los no CPAN buscando pelos módulos presentes em AI::NeuralNet.

Autor
----
Felipe da Veiga Leprevost
leprevost@cpan.org
















