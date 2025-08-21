
#include <stddef.h>
#include <string.h>
#include <assert.h>

#include "params.h"
#include "uint.h"
#include "fp.h"

uint64_t *fp_mul_counter = NULL;
uint64_t *fp_sq_counter = NULL;
uint64_t *fp_inv_counter = NULL;
uint64_t *fp_sqt_counter = NULL;

bool fp_eq(fp const *x, fp const *y)
{
    uint64_t r = 0;
    for (size_t k = 0; k < LIMBS; ++k)
        r |= x->c[k] ^ y->c[k];
    return !r;
}

void fp_set(fp *x, uint64_t y)
{
    uint_set((uint *) x, y);
    fp_enc(x, (uint *) x);
}

static void reduce_once(uint *x)
{
    uint t;
    if (!uint_sub3(&t, x, &p))
        *x = t;
}

void fp_add3(fp *x, fp const *y, fp const *z)
{
    bool c = uint_add3((uint *) x, (uint *) y, (uint *) z);
    (void) c; assert(!c);
    reduce_once((uint *) x);
}

void fp_add2(fp *x, fp const *y)
{
    fp_add3(x, x, y);
}

void fp_sub3(fp *x, fp const *y, fp const *z)
{
    if (uint_sub3((uint *) x, (uint *) y, (uint *) z))
        uint_add3((uint *) x, (uint *) x, &p);

}

void fp_sub2(fp *x, fp const *y)
{
    fp_sub3(x, x, y);
}


/* Montgomery arithmetic */

void fp_enc(fp *x, uint const *y)
{
	
    fp_mul3(x, (fp *) y, &r_squared_mod_p);
}

void fp_dec(uint *x, fp const *y)
{
	printf("unit 1 -->:   ");
				uint_print(&uint_1);
				printf("\n");
				printf("A.z -->:   ");
				uint_print(y);
				printf("\n");
    fp_mul3((fp *) x, y, (fp *) &uint_1);
	printf("x -->:   ");
				uint_print(x);
				printf("\n");
}

void fp_mul3(fp *x, const fp *y, const fp *z) {
    uint64_t t[LIMBS * 2 + 1] = {0};  // Temporary buffer for 512*512->1024 bit multiply

    // 1. Schoolbook multiplication with 64-bit limbs
    for (size_t i = 0; i < LIMBS; ++i) {
        uint64_t carry = 0;
        for (size_t j = 0; j < LIMBS; ++j) {
            __uint128_t product = (__uint128_t)y->c[i] * z->c[j] + t[i + j] + carry;
            t[i + j] = (uint64_t)product;
            carry = product >> 64;
        }
        t[i + LIMBS] = carry;
    }

    // 2. Montgomery reduction (64-bit word granularity)
    for (size_t i = 0; i < LIMBS; ++i) {
        uint64_t m = (t[i] * inv_min_p_mod_r) & UINT64_MAX;

        __uint128_t carry = 0;
        for (size_t j = 0; j < LIMBS; ++j) {
            carry += (__uint128_t)m * p.c[j] + t[i + j];
            t[i + j] = (uint64_t)carry;
            carry >>= 64;
        }
        
        // Propagate final carry
        for (size_t j = i + LIMBS; carry && j < LIMBS * 2; ++j) {
            carry += t[j];
            t[j] = (uint64_t)carry;
            carry >>= 64;
        }
    }

    // 3. Final result extraction
    uint64_t borrow = 0;
    for (size_t i = 0; i < LIMBS; ++i) {
        __uint128_t temp = (__uint128_t)t[LIMBS + i] - p.c[i] - borrow;
        x->c[i] = (uint64_t)temp;
        borrow = (temp >> 64) & 1;
    }
    
    // 4. Conditional subtraction
    if (borrow) {
        for (size_t i = 0; i < LIMBS; ++i) {
            x->c[i] = t[i + LIMBS];
        }
    }
}




void fp_mul2(fp *x, fp const *y)
{
    fp_mul3(x, x, y);
}

void fp_sq2(fp *x, fp const *y)
{
    if (fp_sq_counter) ++*fp_sq_counter;
    uint64_t *mulcnt = fp_mul_counter;
    fp_mul_counter = NULL;
    fp_mul3(x, y, y);
    fp_mul_counter = mulcnt;
}

void fp_sq1(fp *x)
{
    fp_sq2(x, x);
}

/* (obviously) not constant time in the exponent */
static void fp_pow(fp *x, uint const *e)
{
/* 	int j;
	j = 0; */
    fp y = *x;
    *x = fp_1;
    for (size_t k = 0; k < LIMBS; ++k) {
        uint64_t t = e->c[k];
        for (size_t i = 0; i < 64; ++i, t >>= 1) {
            if (t & 1)
                fp_mul2(x, &y);
            fp_sq1(&y);
			/* j = j+1;
			printf("y^in for loop -->:   ");
			uint_print(&y);
			printf("\n");
			printf("\n");
			printf("i for loop -->:   ");
			printf("Printing Integer value %d", j);
			printf("\n");
			printf("\n"); */
        }
    }
}

void fp_inv(fp *x)
{
    if (fp_inv_counter) ++*fp_inv_counter;
    uint64_t *mulcnt = fp_mul_counter;
    fp_mul_counter = NULL;
    fp_pow(x, &p_minus_2);
    fp_mul_counter = mulcnt;
}

bool fp_issquare(fp *x)
{
    if (fp_sqt_counter) ++*fp_sqt_counter;
    uint64_t *mulcnt = fp_mul_counter;
    fp_mul_counter = NULL;
    fp_pow(x, &p_minus_1_halves);
    fp_mul_counter = mulcnt;
    return !memcmp(x, &fp_1, sizeof(fp));
}


void fp_random(fp *x)
{
    uint_random((uint *) x, &p);
}

