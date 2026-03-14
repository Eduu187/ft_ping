#include "ping.h"

int parse(int argc, char** argv, t_args *args) {
    int c;
    while (1) {
        static struct option long_options[] = {
            {"ttl", required_argument, 0, 't'}, 
            {0, 0, 0, 0}
        };
        int option_index = 0;
        
        c = getopt_long(argc, argv, "?vc:i:w:W:s:fat:", long_options, &option_index);
        
        if (c == -1) break;

        switch (c) {
            case 'v': args->verbose = 1; break;         
            case 'c': args->count = atoi(optarg); break; 
            case 'i': args->interval = atof(optarg); break;
            case 'w': args->deadline = atoi(optarg); break;
            case 'W': args->timeout = atoi(optarg); break;
            case 's': args->packet_size = atoi(optarg); break;
            case 'f': args->flood = 1; break;
            case 'a': args->audible = 1; break;
            case 't': args->ttl = atoi(optarg); break;   
            case '?': 
            default:
                usage();
                return (2);
        }
    }
    
    if (optind < argc) {
        args->destination = argv[optind]; 
        if (optind + 1 < argc) {
            printf("ft_ping: extra target: %s\n", argv[optind + 1]);
            return (1);
        }
    } else {
        printf("ft_ping: usage error: Destination address required\n");
        return (1);
    }
    return (0);
}