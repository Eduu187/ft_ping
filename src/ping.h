#include <stdio.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <errno.h>
#include <string.h>
#include <sys/time.h>
#include <sys/select.h>
#include <signal.h>

typedef struct  s_args {
    // Obrigatórios 
    int     verbose;        // -v: Ver detalhes de pacotes e erros [cite: 47]
    int     help;           // -?: Mostrar ajuda e sair 

    // Bônus de Comportamento
    int     count;          // -c: Número de pacotes a enviar
    double  interval;       // -i: Tempo entre envios (pode ser 0.2s, por exemplo)
    int     deadline;       // -w: Tempo total de execução em segundos
    int     timeout;        // -W: Tempo de espera por um reply (em segundos)
    // Bônus de Rede
    int     ttl;            // --ttl: Time to Live customizado
    int     packet_size;    // -s: Tamanho do payload (padrão costuma ser 56)
    int     flood;          // -f: Enviar pacotes o mais rápido possível
    int     audible;        // -a: Beep em cada resposta (bônus extra comum)

    char    *destination;   // O Hostname ou IP fornecido pelo usuário 
}               t_args;

typedef struct s_ping_stats {
    int     packets_sent;
    int     packets_received;
    int     packets_lost;
    double  min_rtt;
    double  max_rtt;
    double  avg_rtt;
    double  total_rtt;
}               t_ping_stats;

typedef struct s_icmp_echo {
    struct icmphdr hdr;
    struct timeval tv;
    char    data[48];
}               t_icmp_echo;

int parse(int argc, char** argv, t_args *args);
void usage(void);
int resolve_hostname(const char *hostname, char *ip_str, struct sockaddr_in *sockaddr);
int setup_raw_socket(t_args *args);
unsigned short calculate_checksum(unsigned short *buf, int size);
int send_icmp_echo(int sock, struct sockaddr_in *dest, int seq, t_args *args);
double recv_icmp_reply(int sock, int timeout, int *seq, t_args *args);
int ping_loop(int sock, struct sockaddr_in *dest_addr, t_args *args, t_ping_stats *stats, const char *hostname);
void print_stats(t_ping_stats *stats, const char *hostname);
void print_icmp_error(int icmp_type, int icmp_code, const char *src_ip, int ttl, t_args *args);