#include "ping.h"

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
    
    init_args(&args);

    if(parse(argc, argv, &args) != 0)
        return(1);
    
    return(0);
}


int main(int argc, char **argv) {
    // 1. Parsing: Processar argc/argv (flags e destino)
    return ft_ping(argc, argv);
    // 2. DNS: Resolver hostname para IP
    // 3. Setup: Abrir Raw Socket (requer privilégios)
    // 4. Signals: Configurar handle para SIGINT (estatísticas)
    
    // 5. Loop Principal (ft_ping):
    //    - Montar pacote ICMP (Header + Payload + Checksum)
    //    - Enviar e marcar tempo
    //    - Receber resposta (usando select/poll para timeout)
    //    - Validar resposta (identificador e checksum)
    //    - Calcular RTT e imprimir (respeitando a indentação do inetutils) [cite: 71]
    
    // 6. Encerramento: Exibir sumário de estatísticas e fechar socket
}