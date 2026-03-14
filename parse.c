// SE input == 10.10, então output é 10.0.0.10
// SE input == 10.10.10 então output é 10.10.0.10

#include "ping.h"

int parse(int argc, char** argv){
    if(argc < 2){
        printf("ping: usage error: Destination address required\n");
        return(1);
    }

}