// testing Loop + Function Call

int printi(int n)
{
    return n;
}

int main()
{
    int n = 5;
    int fact = 1;

    while (n > 0)
    {
        fact *= n;
        n--;
    }

    printi(fact);
}