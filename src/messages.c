#include "ping.h"

void usage(void) {
    printf("Usage: ft_ping [options] <destination>\n\n");
    printf("Options:\n");
    printf("  <destination>      DNS name or IP address\n");
    printf("  -a                 use audible ping\n");
    printf("  -c <count>         stop after <count> replies\n");
    printf("  -f                 flood ping\n");
    printf("  -i <interval>      seconds between sending each packet\n");
    printf("  -s <size>          use <size> as number of data bytes to be sent\n");
    printf("  -t <ttl>           define time to live\n");
    printf("  -v                 verbose output\n");
    printf("  -w <deadline>      reply wait <deadline> in seconds\n");
    printf("  -W <timeout>       time to wait for response\n");
    printf("  -?                 print help and exit\n");
}