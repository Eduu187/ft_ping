#include <stdio.h>
#include <unistd.h>
#include <getopt.h>

typedef struct  s_args {
    // Obrigatórios 
    int     verbose;        // -v: Ver detalhes de pacotes e erros [cite: 47]
    int     help;           // -?: Mostrar ajuda e sair 

    // Bônus de Comportamento [cite: 56]
    int     count;          // -c: Número de pacotes a enviar
    double  interval;       // -i: Tempo entre envios (pode ser 0.2s, por exemplo)
    int     deadline;       // -w: Tempo total de execução em segundos
    int     timeout;        // -W: Tempo de espera por um reply (em segundos)
    
    // Bônus de Rede [cite: 56]
    int     ttl;            // --ttl: Time to Live customizado
    int     packet_size;    // -s: Tamanho do payload (padrão costuma ser 56)
    int     flood;          // -f: Enviar pacotes o mais rápido possível
    int     audible;        // -a: Beep em cada resposta (bônus extra comum)

    // Destino
    char    *destination;   // O Hostname ou IP fornecido pelo usuário 
}               t_args;

int parse(int argc, char** argv);