#include <sys/socket.h>
#include <arpa/inet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <netdb.h>

// gcc -g -o libmotan_tools.so -fPIC -shared motan_tools.c

// gcc -c -g  motan_tools.c -o motan_tools.o
// gcc motan_tools.o -dynamiclib -o libmotan_tools.dylib
// sudo cp libmotan_tools.dylib /usr/local/lib/
void perror(const char *);
int close(int);
int get_local_ip(char *ifname, char *ip)
{
    char *temp = NULL;
    int inet_sock;
    struct ifreq ifr;

    inet_sock = socket(AF_INET, SOCK_DGRAM, 0);

    memset(ifr.ifr_name, 0, sizeof(ifr.ifr_name));
    memcpy(ifr.ifr_name, ifname, strlen(ifname));

    if (0 != ioctl(inet_sock, SIOCGIFADDR, &ifr))
    {
        perror("ioctl error");
        return -1;
    }
    temp = inet_ntoa(((struct sockaddr_in *)&(ifr.ifr_addr))->sin_addr);
    memcpy(ip, temp, strlen(temp));
    ip[strlen(temp)] = '\0';
    close(inet_sock);
    return 0;
}

int get_local_ip_from_host_and_port(const char *host, int port, char *ip);
int get_local_ip_from_host_and_port(const char *host, int port, char *ip)
{
    int udp_sock = -1;
    struct hostent *hp = gethostbyname(host);
    if (hp == NULL)
    {
        return -1;
    }
    int i = 0;
    for (; hp->h_addr_list[i] != NULL; i++)
    {
        struct in_addr *addr = (struct in_addr *)hp->h_addr_list[i];
        struct sockaddr_in server_addr;
        memset(&server_addr, 0x00, sizeof(server_addr));
        server_addr.sin_family = hp->h_addrtype;
        server_addr.sin_port = htons(port);
        memcpy(&server_addr.sin_addr, hp->h_addr_list[i], hp->h_length);
        udp_sock = socket(AF_INET, SOCK_DGRAM, 0);
        if (udp_sock < 0)
        {
            perror("create socket");
            continue;
        }
        if (connect(udp_sock, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
        {
            perror("connect");
            close(udp_sock);
            udp_sock = -1;
            continue;
        }
        struct sockaddr_in local_addr;
        socklen_t addr_len = sizeof(local_addr);
        memset(&local_addr, 0x00, sizeof(local_addr));
        if (getsockname(udp_sock, (struct sockaddr *)&local_addr, &addr_len) < 0)
        {
            perror("get socket address");
            close(udp_sock);
            udp_sock = -1;
            continue;
        }
        strcpy(ip, inet_ntoa(local_addr.sin_addr));
        close(udp_sock);
        break;
    }
    if (udp_sock < 0)
    {
        return -1;
    }
    return 0;
}

char *itoa(u_int64_t value, char *result, int base);
char *itoa(u_int64_t value, char *result, int base)
{
    // check that the base if valid
    if (base < 2 || base > 36)
    {
        *result = '\0';
        return result;
    }

    char *ptr = result, *ptr1 = result, tmp_char;
    u_int64_t tmp_value;

    do
    {
        tmp_value = value;
        value /= base;
        *ptr++ = "zyxwvutsrqponmlkjihgfedcba9876543210123456789abcdefghijklmnopqrstuvwxyz"[35 + (tmp_value - value * base)];
    } while (value);

    // Apply negative sign
    // if (tmp_value < 0)
    // 	*ptr++ = '-';
    *ptr-- = '\0';
    while (ptr1 < ptr)
    {
        tmp_char = *ptr;
        *ptr-- = *ptr1;
        *ptr1++ = tmp_char;
    }
    return result;
}

int get_request_id_bytes(const char *request_id_str, char *rs_bytes);
int get_request_id_bytes(const char *request_id_str, char *rs_bytes)
{
    char bytes[8];
    int width = 8, i = 0;
    u_int64_t j = 0xff;
    u_int64_t rid_num = strtoull(request_id_str, NULL, 10);
    for (; i < 8; i++)
    {
        width--;
        bytes[width] = (j & rid_num) >> (i * 8);
        j = j << 8;
    }
    memcpy(rs_bytes, bytes, 8 * sizeof(char));
    return 0;
}

int get_request_id(uint8_t bytes[8], char *request_id_str);
int get_request_id(uint8_t bytes[8], char *request_id_str)
{
    int bytes_len = 8; // request_id is fixed to 8 bytes
    u_int64_t r_id = (u_int64_t)bytes[0] << (bytes_len - 1) * 8;
    int i = 0;
    for (i = 1; i < bytes_len; i++)
    {
        if (i <= bytes_len - 2)
            r_id = r_id | (u_int64_t)bytes[i] << (bytes_len - (i + 1)) * 8;
        else
            r_id = r_id | (u_int64_t)bytes[i];
    }
    itoa(r_id, request_id_str, 10);
    return 0;
}
