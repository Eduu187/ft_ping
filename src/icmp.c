#include "ping.h"

unsigned short calculate_checksum(unsigned short *buf, int size) {
    unsigned long sum = 0;
    
    while (size > 1) {
        sum += *buf++;
        size -= 2;
    }
    
    if (size == 1)
        sum += *(unsigned char *)buf;
    
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    
    return ~sum;
}

int send_icmp_echo(int sock, struct sockaddr_in *dest, int seq, t_args *args) {
    char packet[64];
    struct icmp *icmp_hdr;
    struct timeval *tv;
    int packet_size = 8 + 56;
    
    memset(packet, 0, sizeof(packet));
    icmp_hdr = (struct icmp *)packet;
    
    icmp_hdr->icmp_type = ICMP_ECHO;
    icmp_hdr->icmp_code = 0;
    icmp_hdr->icmp_id = getpid() & 0xffff;
    icmp_hdr->icmp_seq = seq;
    icmp_hdr->icmp_cksum = 0;
    
    tv = (struct timeval *)(packet + 8);
    gettimeofday(tv, NULL);
    
    for (int i = 16; i < 64; i++)
        packet[i] = i % 256;
    
    icmp_hdr->icmp_cksum = calculate_checksum((unsigned short *)packet, packet_size);
    
    if (sendto(sock, packet, packet_size, 0, (struct sockaddr *)dest, sizeof(*dest)) < 0) {
        perror("ft_ping: sendto");
        return -1;
    }
    
    if (args->flood) {
        printf(".");
        fflush(stdout);
    }
    
    return 0;
}

double recv_icmp_reply(int sock, int timeout, int *seq, t_args *args) {
    struct sockaddr_in from;
    struct ip *ip_hdr;
    struct icmp *icmp_hdr;
    struct timeval tv_recv, *tv_send;
    struct timeval tv_timeout;
    fd_set readfds;
    char packet[1500];
    int from_len = sizeof(from);
    int n;
    char src_ip[INET_ADDRSTRLEN];
    int ttl;
    double rtt;
    FD_ZERO(&readfds);
    FD_SET(sock, &readfds);
    
    tv_timeout.tv_sec = timeout;
    tv_timeout.tv_usec = 0;
    
    n = select(sock + 1, &readfds, NULL, NULL, &tv_timeout);
    if (n < 0) {
        perror("ft_ping: select");
        return -1.0;
    }
    if (n == 0)
        return -2.0;
    
    gettimeofday(&tv_recv, NULL);
    
    memset(packet, 0, sizeof(packet));
    n = recvfrom(sock, packet, sizeof(packet), 0, (struct sockaddr *)&from, (socklen_t *)&from_len);
    if (n < 0) {
        perror("ft_ping: recvfrom");
        return -1.0;
    }
    
    ip_hdr = (struct ip *)packet;
    int ip_hdr_len = ip_hdr->ip_hl * 4;
    ttl = ip_hdr->ip_ttl;
    
    icmp_hdr = (struct icmp *)(packet + ip_hdr_len);
    
    if (icmp_hdr->icmp_type != ICMP_ECHOREPLY) {
        inet_ntop(AF_INET, &from.sin_addr, src_ip, INET_ADDRSTRLEN);
        if (args->verbose) {
            print_icmp_error(icmp_hdr->icmp_type, icmp_hdr->icmp_code, src_ip, ttl, args);
        }
        return -2.0;
    }
    
    if (icmp_hdr->icmp_id != (getpid() & 0xffff))
        return -2.0;
    
    *seq = icmp_hdr->icmp_seq;
    
    tv_send = (struct timeval *)(packet + ip_hdr_len + 8);
    
    rtt = (tv_recv.tv_sec - tv_send->tv_sec) * 1000.0;
    rtt += (tv_recv.tv_usec - tv_send->tv_usec) / 1000.0;
    
    inet_ntop(AF_INET, &from.sin_addr, src_ip, INET_ADDRSTRLEN);
    
    if (args->flood) {
        printf("\b \b");
        fflush(stdout);
    } else {
        printf("%d bytes from %s: icmp_seq=%d ttl=%d time=%.1f ms\n", 
               n - ip_hdr_len, src_ip, icmp_hdr->icmp_seq, ttl, rtt);
    }
    
    if (args->audible) {
        printf("\a");
        fflush(stdout);
    }
    
    return rtt;
}

int ping_loop(int sock, struct sockaddr_in *dest_addr, t_args *args, t_ping_stats *stats, const char *hostname) {
    int seq = 0;
    int max_count = (args->count > 0) ? args->count : 4;
    struct timeval tv_start, tv_now;
    double rtt;
    
    extern t_global_state g_state;
    
    stats->packets_sent = 0;
    stats->packets_received = 0;
    stats->min_rtt = 999999.0;
    stats->max_rtt = 0.0;
    stats->avg_rtt = 0.0;
    stats->total_rtt = 0.0;
    
    gettimeofday(&tv_start, NULL);
    
    for (int i = 0; i < max_count; i++) {
        if (g_state.interrupted)
            break;
        
        if (args->deadline > 0) {
            gettimeofday(&tv_now, NULL);
            double elapsed = (tv_now.tv_sec - tv_start.tv_sec) * 1000.0;
            elapsed += (tv_now.tv_usec - tv_start.tv_usec) / 1000.0;
            if (elapsed >= args->deadline * 1000.0) {
                break;
            }
        }
        
        stats->packets_sent++;
        
        if (send_icmp_echo(sock, dest_addr, i, args) < 0)
            return -1;
        
        rtt = recv_icmp_reply(sock, args->timeout, &seq, args);
        if (rtt >= 0) {
            stats->packets_received++;
            stats->total_rtt += rtt;
            if (rtt < stats->min_rtt)
                stats->min_rtt = rtt;
            if (rtt > stats->max_rtt)
                stats->max_rtt = rtt;
        } else if (rtt == -2.0) {
            if (!args->flood)
                printf("Request timeout for icmp_seq %d\n", i);
        }
        
        if (!args->flood && i < max_count - 1 && args->interval > 0)
            usleep((int)(args->interval * 1000000));
    }
    
    if (args->flood)
        printf("\n");
    
    stats->packets_lost = stats->packets_sent - stats->packets_received;
    if (stats->packets_received > 0)
        stats->avg_rtt = stats->total_rtt / stats->packets_received;
    
    print_stats(stats, hostname);
    
    return 0;
}

void print_stats(t_ping_stats *stats, const char *hostname) {
    printf("\n--- %s statistics ---\n", hostname);
    printf("%d packets transmitted, %d packets received, %.1f%% packet loss\n",
           stats->packets_sent, stats->packets_received,
           (stats->packets_lost * 100.0) / stats->packets_sent);
    
    if (stats->packets_received > 0) {
        printf("round-trip min/avg/max = %.1f/%.1f/%.1f ms\n",
               stats->min_rtt, stats->avg_rtt, stats->max_rtt);
    }
}

void print_icmp_error(int icmp_type, int icmp_code, const char *src_ip, int ttl, t_args *args) {
    (void)args;
    (void)ttl;
    
    switch (icmp_type) {
        case ICMP_UNREACH:
            printf("From %s icmp_seq=? Destination Unreachable ", src_ip);
            switch (icmp_code) {
                case ICMP_UNREACH_NET: printf("(Network unreachable)\n"); break;
                case ICMP_UNREACH_HOST: printf("(Host unreachable)\n"); break;
                case ICMP_UNREACH_PROTOCOL: printf("(Protocol unreachable)\n"); break;
                case ICMP_UNREACH_PORT: printf("(Port unreachable)\n"); break;
                default: printf("(Code %d)\n", icmp_code); break;
            }
            break;
        case ICMP_TIMXCEED:
            printf("From %s icmp_seq=? Time exceeded: ttl=%d\n", src_ip, ttl);
            break;
        case ICMP_REDIRECT:
            printf("From %s: Redirect\n", src_ip);
            break;
        default:
            printf("From %s: ICMP type %d code %d\n", src_ip, icmp_type, icmp_code);
            break;
    }
}
