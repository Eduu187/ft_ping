#include "ping.h"

int g_sock = -1;
t_ping_stats *g_stats = NULL;
char *g_hostname = NULL;
int g_interrupted = 0;

void signal_handler(int sig) {
    (void)sig;
    g_interrupted = 1;
}

void init_args(t_args *args) {
    args->verbose = 0;
    args->count = -1;      
    args->interval = 1.0;  
    args->deadline = 0;
    args->timeout = 1;     
    args->ttl = 64;        
    args->packet_size = 56;
    args->flood = 0;
    args->audible = 0;
    args->destination = NULL;
}

int ft_ping(int argc, char **argv){
    t_args args;
    struct sockaddr_in dest_addr;
    char ip_str[INET_ADDRSTRLEN];
    int sock = -1;
    t_ping_stats stats;
    int result = 1;

    init_args(&args);

    if (parse(argc, argv, &args) != 0)
        return (1);
    
    if (args.destination == NULL)
        return (0);
    
    if (resolve_hostname(args.destination, ip_str, &dest_addr) != 0 ||
        (sock = setup_raw_socket(&args)) < 0)
        return (1);
    signal(SIGINT, signal_handler);
    g_sock = sock;
    g_stats = &stats;
    g_hostname = args.destination;
    
    printf("PING %s (%s): %d data bytes\n", args.destination, ip_str, args.packet_size);
    
    if (ping_loop(sock, &dest_addr, &args, &stats, args.destination) < 0)
        return (1);
    
    result = 0;

    if (sock >= 0)
        close(sock);
    return result;
}


int main(int argc, char **argv) {
    return ft_ping(argc, argv);
}