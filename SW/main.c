
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <assert.h>

#include "fp.h"
#include "csidh.h"

void uint_print(uint const *x)
{
    for (size_t i = 8*LIMBS-1; i < 8*LIMBS; --i)
        printf("%02hhx", i[(unsigned char *) x->c]);
}

void priv_print(private_key const *k)
{
    char cc = '0';
    for (size_t i = 0; i < sizeof(k->e)/sizeof(*k->e); ++i) {
        char nc = k->e[i] > 0 ? '6' : k->e[i] < 0 ? '4' : '7';
        if (nc != cc) cc = nc, printf("\x1b[3%cm", cc);
        printf(MAX_EXPONENT < 16 ? "%x" : "%02x", abs(k->e[i]));
    }
    printf("\x1b[0m");
}

int main()
{
    bool ret; (void) ret;
    clock_t t0, t1;

    private_key priv_alice, priv_bob;
    public_key pub_alice, pub_bob;
    public_key shared_alice, shared_bob;

    printf("\n");


    t0 = clock();
	//priv_alice = (private_key){ .e = {4, 5, 4, 4, 2, 4, 0, 1, 5, 1, 2, 0, 5, 2, 2, 1, 4, 3, 4, 5, 4, 4, 5, 2, 3, 4, 1, 4, 4, 1, 2, 1, 4, 2, 1, 1, 1, 1, 5, 1, 0, 4, 4, 5, 4, 4, 4, 1, 1, 2, 4, 0, 0, 3, 4, 1, 5, 5, 4, 2, 5, 0, 1, 5, 1, 4, 5, 4, 4, 4, 0, 2, 1, 4} };
	//priv_alice = (private_key){ .e = {5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5} };
	//priv_alice = (private_key){ .e = {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} };
	priv_alice = (private_key){ .e = {0, 0, 0, 0, 0, 0 ,0 ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1} };
	//priv_alice = (private_key){ .e = {5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5} };
    //csidh_private(&priv_alice);
    t1 = clock();

    printf("Alice's private key   (%7.3lf ms):\n  ", 1000. * (t1 - t0) / CLOCKS_PER_SEC);
    priv_print(&priv_alice);
    printf("\n\n");
	
	
	printf("&first_elligator_rand -->:   ");
	uint_print(&first_elligator_rand);
	printf("\n");

  /*   t0 = clock();
	priv_bob = (private_key){ .e = {3,2,2,1,2,3,5,3,2,2,1,3,2,4,4,2,4,5,1,5,2,1,4,3,5,3,4,4,1,4,2,5,2,3,5,5,5,5,3,1,2,2,2,4,1,4,2,0,0,1,1,1,3,5,1,3,4,5,5,4,4,3,0,5,1,3,5,5,4,4,5,5,5,1} };
    //csidh_private(&priv_bob);
    t1 = clock();

    printf("Bob's private key     (%7.3lf ms):\n  ", 1000. * (t1 - t0) / CLOCKS_PER_SEC);
    priv_print(&priv_bob);
    printf("\n\n"); */


    t0 = clock();
    ret = csidh(&pub_alice, &base, &priv_alice);
    assert(ret);
    t1 = clock();

    printf("Alice's public key    (%7.3lf ms):\n  ", 1000. * (t1 - t0) / CLOCKS_PER_SEC);
    uint_print(&pub_alice.A);
    printf("\n\n");


    /* t0 = clock();
    ret = csidh(&pub_bob, &base, &priv_bob);
    assert(ret);
    t1 = clock();

    printf("Bob's public key      (%7.3lf ms):\n  ", 1000. * (t1 - t0) / CLOCKS_PER_SEC);
    uint_print(&pub_bob.A);
    printf("\n\n");


    t0 = clock();
    ret = csidh(&shared_alice, &pub_bob, &priv_alice);
    assert(ret);
    t1 = clock();

    printf("Alice's shared secret (%7.3lf ms):\n  ", 1000. * (t1 - t0) / CLOCKS_PER_SEC);
    uint_print(&shared_alice.A);
    printf("\n\n");


    t0 = clock();
    ret = csidh(&shared_bob, &pub_alice, &priv_bob);
    assert(ret);
    t1 = clock();

    printf("Bob's shared secret   (%7.3lf ms):\n  ", 1000. * (t1 - t0) / CLOCKS_PER_SEC);
    uint_print(&shared_bob);
    printf("\n\n");


    printf("    ");
    if (memcmp(&shared_alice, &shared_bob, sizeof(public_key)))
        printf("\x1b[31mNOT EQUAL!\x1b[0m\n");
    else
        printf("\x1b[32mequal.\x1b[0m\n");
    printf("\n");


    printf("\n"); */
}

