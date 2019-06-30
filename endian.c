/* endian.c - Check endianness of this machine */

#include <stdio.h>

int
main()
{
    unsigned short int x = 0x3148;
    char *p = (char *)&x;

    (void)printf("The two bytes of x: %x %x\n", *p, *(p+1));
    if (*p == 0x31) {
	printf("big endian\n");
    } else {
	printf("little endian\n");
    }
}
