//
// Created by minggang on 2018/11/9.
//
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

#include "buffer.h"

int main() {
    motan_bytes_buffer_t *mb = motan_new_bytes_buffer(1024, M_BIG_ENDIAN);
    assert(mb != NULL);

    mb_write_byte(mb, 1);
    uint8_t b;
    mb_read_byte(mb, &b);
    mb_reset(mb);
    assert(1 == b);

    char *bs = "this is a test";
    int len = strlen(bs);
    mb_write_bytes(mb, (uint8_t *) bs, len);
    uint8_t *rb = (uint8_t *) malloc(len + 1);
    rb[len] = '\0';
    mb_read_bytes(mb, rb, len);
    assert(strcmp(bs, (const char *) rb) == 0);
    free(rb);

    uint16_t u16_test_v = 16;
    mb_write_uint16(mb, u16_test_v);
    uint16_t u16;
    mb_read_uint16(mb, &u16);
    mb_reset(mb);
    assert(u16_test_v == u16);

    uint32_t u32_test_v = (uint32_t) 0xffffffff;
    mb_write_uint32(mb, u32_test_v);
    uint32_t u32;
    mb_read_uint32(mb, &u32);
    assert(u32_test_v == u32);

    uint64_t u64_test_v = (uint64_t) 0xffffffffffffffffL;
    mb_write_uint64(mb, u64_test_v);
    uint64_t u64;
    mb_read_uint64(mb, &u64);
    mb_reset(mb);
    assert(u64_test_v == u64);

    int varint_len;
    mb_write_varint(mb, zigzag_encode(u64_test_v), &varint_len);
    mb_read_varint(mb, &u64);
    u64 = zigzag_decode(u64);
    assert(u64_test_v == u64);

    mb_write_varint(mb, zigzag_encode(u32_test_v), &varint_len);
    mb_read_varint(mb, &u64);
    u32 = zigzag_decode(u64);
    assert(u32_test_v == u32);

    motan_free_bytes_buffer(mb);
    return 0;
}
