//
// Created by minggang on 2018/11/9.
//

#ifndef MOTAN_LUA_BUFFER_H
#define MOTAN_LUA_BUFFER_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "motan.h"

typedef enum {
    M_BIG_ENDIAN, M_LITTLE_ENDIAN
} byte_order_t;

typedef struct {
    uint8_t *buffer;
    byte_order_t order;
    uint32_t write_pos;
    uint32_t read_pos;
    size_t capacity;
    uint8_t _read_only;
} motan_bytes_buffer_t;

__unused static void die(const char *fmt, ...) {
    va_list arg;

    va_start(arg, fmt);
    vfprintf(stderr, fmt, arg);
    va_end(arg);
    fprintf(stderr, "\n");
    exit(-1);
}


__unused static void dump_bytes(const uint8_t *bs, int len) {
    for (int i = 0; i < len; i++) {
        printf("%02x", (uint8_t) bs[i]);
    }
    printf("\n");
}

__unused static void mb_dump(motan_bytes_buffer_t *mb) {
    fprintf(stderr, "mb: %p,", mb);
    fprintf(stderr, "read_only: %s,", mb->_read_only ? "true" : "false");
    fprintf(stderr, "write_pos: %d,", mb->write_pos);
    fprintf(stderr, "read_post: %d,", mb->read_pos);
    fprintf(stderr, "capacity: %zu,", mb->capacity);
    fprintf(stderr, "buffer: %p\n", mb->buffer);
}

extern motan_bytes_buffer_t *motan_new_bytes_buffer(size_t capacity, byte_order_t order);

extern motan_bytes_buffer_t *
motan_new_bytes_buffer_from_bytes(const uint8_t *raw_bytes, size_t size, byte_order_t order, uint8_t read_only);

extern void motan_free_bytes_buffer(motan_bytes_buffer_t *mb);

extern void mb_write_bytes(motan_bytes_buffer_t *mb, const uint8_t *bytes, int len);

extern void mb_write_byte(motan_bytes_buffer_t *mb, uint8_t u);

extern void mb_write_uint16(motan_bytes_buffer_t *mb, uint16_t u);

extern void mb_write_uint32(motan_bytes_buffer_t *mb, uint32_t u);

extern void mb_write_uint64(motan_bytes_buffer_t *mb, uint64_t u);

extern void mb_write_varint(motan_bytes_buffer_t *mb, uint64_t u, int *len);

extern void mb_set_write_pos(motan_bytes_buffer_t *mb, uint32_t pos);

extern void mb_set_read_pos(motan_bytes_buffer_t *mb, uint32_t pos);

extern int mb_remain(motan_bytes_buffer_t *mb);

extern void mb_reset(motan_bytes_buffer_t *mb);

extern int mb_read_bytes(motan_bytes_buffer_t *mb, uint8_t *bs, int len);

extern int mb_read_byte(motan_bytes_buffer_t *mb, uint8_t *u);

extern int mb_read_uint16(motan_bytes_buffer_t *mb, uint16_t *u);

extern int mb_read_uint32(motan_bytes_buffer_t *mb, uint32_t *u);

extern int mb_read_uint64(motan_bytes_buffer_t *mb, uint64_t *u);

extern int mb_read_varint(motan_bytes_buffer_t *mb, uint64_t *u);

static inline uint64_t zigzag_encode(int64_t u) {
    return (u << 1) ^ (u >> 63);
}

static inline int64_t zigzag_decode(uint64_t n) {
    return (n >> 1) ^ -((int64_t) n & 1);
}

// 高位低址
static inline void big_endian_write_uint16(uint8_t *buffer, uint16_t n) {
    buffer[0] = (uint8_t) (n >> 8);
    buffer[1] = (uint8_t) n;

}

static inline void big_endian_write_uint32(uint8_t *buffer, uint32_t n) {
    buffer[0] = (uint8_t) (n >> 24);
    buffer[1] = (uint8_t) (n >> 16);
    buffer[2] = (uint8_t) (n >> 8);
    buffer[3] = (uint8_t) n;
}

static inline void big_endian_write_uint64(uint8_t *buffer, uint64_t n) {
    buffer[0] = (uint8_t) (n >> 56);
    buffer[1] = (uint8_t) (n >> 48);
    buffer[2] = (uint8_t) (n >> 40);
    buffer[3] = (uint8_t) (n >> 32);
    buffer[4] = (uint8_t) (n >> 24);
    buffer[5] = (uint8_t) (n >> 16);
    buffer[6] = (uint8_t) (n >> 8);
    buffer[7] = (uint8_t) n;
}

static inline uint16_t big_endian_read_uint16(uint8_t *buffer) {
    return ((uint16_t) buffer[0] << 8) | (uint16_t) buffer[1];
}

static inline uint32_t big_endian_read_uint32(uint8_t *buffer) {
    return ((uint32_t) buffer[0] << 24)
           | ((uint32_t) buffer[1] << 16)
           | ((uint32_t) buffer[2] << 8)
           | (uint32_t) buffer[3];
}

static inline uint64_t big_endian_read_uint64(uint8_t *buffer) {
    return ((uint64_t) buffer[0] << 56)
           | ((uint64_t) buffer[1] << 48)
           | ((uint64_t) buffer[2] << 40)
           | ((uint64_t) buffer[3] << 32)
           | ((uint64_t) buffer[4] << 24)
           | ((uint64_t) buffer[5] << 16)
           | ((uint64_t) buffer[6] << 8)
           | (uint64_t) buffer[7];

}

// 高位高址
static inline void little_endian_write_uint16(uint8_t *buffer, uint16_t n) {
    buffer[1] = (uint8_t) (n >> 8);
    buffer[0] = (uint8_t) n;

}

static inline void little_endian_write_uint32(uint8_t *buffer, uint32_t n) {
    buffer[3] = (uint8_t) (n >> 24);
    buffer[2] = (uint8_t) (n >> 16);
    buffer[1] = (uint8_t) (n >> 8);
    buffer[0] = (uint8_t) n;
}

static inline void little_endian_write_uint64(uint8_t *buffer, uint64_t n) {
    buffer[7] = (uint8_t) (n >> 56);
    buffer[6] = (uint8_t) (n >> 48);
    buffer[5] = (uint8_t) (n >> 40);
    buffer[4] = (uint8_t) (n >> 32);
    buffer[3] = (uint8_t) (n >> 24);
    buffer[2] = (uint8_t) (n >> 16);
    buffer[1] = (uint8_t) (n >> 8);
    buffer[0] = (uint8_t) n;
}

static inline uint16_t little_endian_read_uint16(uint8_t *buffer) {
    return ((uint16_t) buffer[1] << 8) | (uint16_t) buffer[0];
}

static inline uint32_t little_endian_read_uint32(uint8_t *buffer) {
    return ((uint32_t) buffer[3] << 24)
           | ((uint32_t) buffer[2] << 16)
           | ((uint32_t) buffer[1] << 8)
           | (uint32_t) buffer[0];
}

static inline uint64_t little_endian_read_uint64(uint8_t *buffer) {
    return ((uint64_t) buffer[7] << 56)
           | ((uint64_t) buffer[6] << 48)
           | ((uint64_t) buffer[5] << 40)
           | ((uint64_t) buffer[4] << 32)
           | ((uint64_t) buffer[3] << 24)
           | ((uint64_t) buffer[2] << 16)
           | ((uint64_t) buffer[1] << 8)
           | (uint64_t) buffer[0];

}

#endif //MOTAN_LUA_BUFFER_H
