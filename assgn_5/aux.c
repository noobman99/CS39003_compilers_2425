#include <stdio.h>

void mprn(int *MEM, int idx)
{
    printf("MEM[%d] set to %d\n", idx, MEM[idx]);
}

void eprn(int *R, int idx)
{
    printf("Standalone expression evaluates to %d\n", R[idx]);
}

int pwr(int arg1, int arg2)
{
    int res = 1;
    for (int i = 0; i < arg2; i++)
    {
        res *= arg1;
    }
    return res;
}