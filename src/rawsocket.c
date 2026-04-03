#include "ping.h"
#include <sys/time.h>

int setup_raw_socket(t_args *args) {
    int sock;
    struct timeval tv;
    int ttl_value;

    sock = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
    if (sock < 0) {
        perror("ft_ping: socket");
        return -1;
    }

    ttl_value = args->ttl;
    if (setsockopt(sock, IPPROTO_IP, IP_TTL, &ttl_value, sizeof(ttl_value)) < 0) {
        perror("ft_ping: setsockopt IP_TTL");
        close(sock);
        return -1;
    }

    tv.tv_sec = args->timeout;
    tv.tv_usec = 0;
    if (setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
        perror("ft_ping: setsockopt SO_RCVTIMEO");
        close(sock);
        return -1;
    }

    return sock;
}
