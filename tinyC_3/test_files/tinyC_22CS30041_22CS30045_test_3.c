// test_case3.c
int main()
{
    int n = 5;
    int fact = 1;

    while (n > 0)
    {
        fact *= n;
        n--;
    }

    return fact;
}