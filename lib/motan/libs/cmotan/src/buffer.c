//
// Created by minggang on 2018/11/9.
//
#include <stdlib.h>
#include <assert.h>
#include <string.h>

#include "motan.h"
#include "buffer.h"

motan_bytes_buffer_t *
motan_new_bytes_buffer_from_bytes(const uint8_t *raw_bytes, size_t len, byte_order_t order, uint8_t read_only) {
    motan_bytes_buffer_t *mb = (motan_bytes_buffer_t *) malloc(sizeof(motan_bytes_buffer_t));
    if (mb == NULL) {
        die("Out of memory");
    }
    if (!read_only) {
        mb->buffer = (uint8_t *) malloc(len * sizeof(uint8_t));
        if (mb->buffer == NULL) {
            free(mb);
            die("Out of memory");
        }
        memcpy(mb->buffer, raw_bytes, len);
    } else {
        mb->buffer = (uint8_t *) raw_bytes;
    }
    mb->_read_only = read_only;
    mb->order = order;
    mb->read_pos = 0;
    mb->write_pos = len;
    mb->capacity = len;
    return mb;
}

motan_bytes_buffer_t *motan_new_bytes_buffer(size_t capacity, byte_order_t order) {
    motan_bytes_buffer_t *mb = (motan_bytes_buffer_t *) malloc(sizeof(motan_bytes_buffer_t));
    if (mb == NULL) {
        die("Out of memory");
    }
    mb->buffer = (uint8_t *) malloc(capacity * sizeof(uint8_t));
    if (mb->buffer == NULL) {
        free(mb);
        die("Out of memory");
    }
    mb->_read_only = 0;
    mb->order = order;
    mb->read_pos = 0;
    mb->write_pos = 0;
    mb->capacity = capacity;
    return mb;
}

void motan_free_bytes_buffer(motan_bytes_buffer_t *mb) {
    if (mb == NULL) {
        return;
    }
    if (mb->buffer != NULL) {
        if (!mb->_read_only) {
            free(mb->buffer);
        }
        mb->buffer = NULL;
    }
    free(mb);
}

static void mb_grow_buffer(motan_bytes_buffer_t *mb, size_t n) {
    assert(!mb->_read_only);
    size_t new_cap = 2 * mb->capacity + n;
    uint8_t *new_buffer = (uint8_t *) malloc(new_cap);
    if (new_buffer == NULL) {
        die("Out of memory");
    }
    memcpy(new_buffer, mb->buffer, mb->capacity);
    free(mb->buffer);
    mb->buffer = new_buffer;
    mb->capacity = new_cap;
}

void mb_set_write_pos(motan_bytes_buffer_t *mb, uint32_t pos) {
    assert(!mb->_read_only);
    if (mb->capacity < pos) {
        mb_grow_buffer(mb, pos - mb->capacity);
    }
    mb->write_pos = pos;
}

void mb_set_read_pos(motan_bytes_buffer_t *mb, uint32_t pos) {
    mb->read_pos = pos;
}

inline void mb_reset(motan_bytes_buffer_t *mb) {
    mb->read_pos = 0;
    mb->write_pos = 0;
}


inline int mb_remain(motan_bytes_buffer_t *mb) {
    return mb->write_pos - mb->read_pos;
}

void mb_write_bytes(motan_bytes_buffer_t *mb, const uint8_t *bytes, int len) {
    assert(!mb->_read_only);
    if (mb->capacity < mb->write_pos + len) {
        mb_grow_buffer(mb, len);
    }
    memcpy((void *) (mb->buffer + mb->write_pos), (void *) bytes, len);
    mb->write_pos += len;
}

void mb_write_byte(motan_bytes_buffer_t *mb, uint8_t u) {
    assert(!mb->_read_only);
    if (mb->capacity < mb->write_pos + 1) {
        mb_grow_buffer(mb, 1);
    }
    mb->buffer[mb->write_pos] = u;
    mb->write_pos++;
}

void mb_write_uint16(motan_bytes_buffer_t *mb, uint16_t u) {
    assert(!mb->_read_only);
    if (mb->capacity < mb->write_pos + 2) {
        mb_grow_buffer(mb, 2);
    }
    if (mb->order == M_BIG_ENDIAN) {
        big_endian_write_uint16(mb->buffer + mb->write_pos, u);
    } else {
        little_endian_write_uint16(mb->buffer + mb->write_pos, u);
    }
    mb->write_pos += 2;
}

void mb_write_uint32(motan_bytes_buffer_t *mb, uint32_t u) {
    assert(!mb->_read_only);
    if (mb->capacity < mb->write_pos + 4) {
        mb_grow_buffer(mb, 4);
    }
    if (mb->order == M_BIG_ENDIAN) {
        big_endian_write_uint32(mb->buffer + mb->write_pos, u);
    } else {
        little_endian_write_uint32(mb->buffer + mb->write_pos, u);
    }
    mb->write_pos += 4;
}

void mb_write_uint64(motan_bytes_buffer_t *mb, uint64_t u) {
    assert(!mb->_read_only);
    if (mb->capacity < mb->write_pos + 8) {
        mb_grow_buffer(mb, 8);
    }
    if (mb->order == M_BIG_ENDIAN) {
        big_endian_write_uint64(mb->buffer + mb->write_pos, u);
    } else {
        little_endian_write_uint64(mb->buffer + mb->write_pos, u);
    }
    mb->write_pos += 8;
}

void mb_write_varint(motan_bytes_buffer_t *mb, uint64_t u, int *len) {
    assert(!mb->_read_only);
    int l = 0;
    for (; u >= 1 << 7;) {
        mb_write_byte(mb, (uint8_t) ((u & 0x7f) | 0x80));
        u >>= 7;
        l++;
    }
    mb_write_byte(mb, (uint8_t) u);
    *len = l + 1;
}

int mb_read_bytes(motan_bytes_buffer_t *mb, uint8_t *bs, int len) {
    if (mb_remain(mb) < len) {
        return E_MOTAN_BUFFER_NOT_ENOUGH;
    }
    memcpy((void *) bs, (void *) (mb->buffer + mb->read_pos), len);
    mb->read_pos += len;
    return MOTAN_OK;
}


int mb_read_byte(motan_bytes_buffer_t *mb, uint8_t *u) {
    if (mb_remain(mb) < 1) {
        return E_MOTAN_BUFFER_NOT_ENOUGH;
    }
    *u = mb->buffer[mb->read_pos];
    mb->read_pos++;
    return MOTAN_OK;
}

int mb_read_uint16(motan_bytes_buffer_t *mb, uint16_t *u) {
    if (mb_remain(mb) < 2) {
        return E_MOTAN_BUFFER_NOT_ENOUGH;
    }
    if (mb->order == M_BIG_ENDIAN) {
        *u = big_endian_read_uint16(mb->buffer + mb->read_pos);
    } else {
        *u = little_endian_read_uint16(mb->buffer + mb->read_pos);
    }
    mb->read_pos += 2;
    return MOTAN_OK;
}

int mb_read_uint32(motan_bytes_buffer_t *mb, uint32_t *u) {
    if (mb_remain(mb) < 4) {
        return E_MOTAN_BUFFER_NOT_ENOUGH;
    }
    if (mb->order == M_BIG_ENDIAN) {
        *u = big_endian_read_uint32(mb->buffer + mb->read_pos);
    } else {
        *u = little_endian_read_uint32(mb->buffer + mb->read_pos);
    }
    mb->read_pos += 4;
    return MOTAN_OK;
}

int mb_read_uint64(motan_bytes_buffer_t *mb, uint64_t *u) {
    if (mb_remain(mb) < 8) {
        return E_MOTAN_BUFFER_NOT_ENOUGH;
    }
    if (mb->order == M_BIG_ENDIAN) {
        *u = big_endian_read_uint64(mb->buffer + mb->read_pos);
    } else {
        *u = little_endian_read_uint64(mb->buffer + mb->read_pos);
    }
    mb->read_pos += 8;
    return MOTAN_OK;
}

int mb_read_varint(motan_bytes_buffer_t *mb, uint64_t *u) {
    uint64_t r = 0;
    for (int shift = 0; shift < 64; shift += 7) {
        uint8_t b;
        int err = mb_read_byte(mb, &b);
        if (err != MOTAN_OK) {
            return err;
        }
        if ((b & 0x80) != 0x80) {
            r |= (uint64_t) b << shift;
            *u = r;
            return MOTAN_OK;
        }
        r |= (uint64_t) (b & 0x7f) << shift;
    }
    return E_MOTAN_OVERFLOW;
}
