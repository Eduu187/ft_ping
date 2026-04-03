#include "ping.h"
#include <string.h>

int resolve_hostname(const char *hostname, char *ip_str, struct sockaddr_in *sockaddr) {
    struct addrinfo hints, *res;
    int status;

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_RAW;

    if ((status = getaddrinfo(hostname, NULL, &hints, &res)) != 0) {
        fprintf(stderr, "ft_ping: %s: %s\n", hostname, gai_strerror(status));
        return 1;
    }

    struct sockaddr_in *ipv4 = (struct sockaddr_in *)res->ai_addr;
    *sockaddr = *ipv4;

    inet_ntop(res->ai_family, &(ipv4->sin_addr), ip_str, INET_ADDRSTRLEN);

    freeaddrinfo(res);
    return 0;
}