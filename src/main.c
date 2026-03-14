#include "ping.h"

int ft_ping(int argc, char **argv){
    if(parse(argc, argv) == 1)
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