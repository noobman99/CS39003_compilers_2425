/* Sample File */

// External Declarations
extern int counter;
static const double E = 2.71828;
volatile unsigned short LIMIT = 1000;

// Function prototype
void manipulate_array(int arr[], int size);
float calc_average(int num, ...);

// Function definitions
inline int sum_of_squares(int x, int y)
{
    return (x * x) + (y * y);
}

int oldStyleFunc(a, b)
int a, b;
{
    return a * b;
}

int main(int argc, char *argv[])
{
    // Declaration statements
    unsigned long factorial = 1;
    double d1 = 1.23e2, d2 = -45.6;
    char ch = '@';
    char msg[] = "Welcome to C programming!";
    int primes[] = {13, 17, 19, 23, 29};
    register unsigned int loop_count = 100;

    // Assignment Expression
    factorial *= 2;
    loop_count -= 10;

    // Logical Expression
    _Bool condition = (factorial > 1 && loop_count <= 90) || (factorial < LIMIT);

    // Iteration Statements
    for (int i = 1; i <= 5; i++)
    {
        factorial *= i;
        printf("Factorial at step %d: %lu\n", i, factorial);
    }

    do
    {
        printf("Loop count is: %u\n", loop_count);
    } while (--loop_count > 80);

    // Arithmetic & Logical Expressions
    int shifted_val = primes[2] << 1;
    int bitwise_res = shifted_val & shifted_val;

    // Function Calls
    int square_sum = sum_of_squares(primes[0], primes[1]);
    printf("Sum of squares: %d\n", square_sum);

    float avg = calc_average(3, primes[0], primes[1], primes[2]);
    printf("Average: %.2f\n", avg);

    // Selection Statements & Jump Statements
    if (factorial > 100)
    {
        printf("Factorial is large\n");
    }
    else if (bitwise_res == 0)
    {
        printf("Bitwise result is zero\n");
    }
    else
    {
        printf("Factorial is within normal range\n");
    }

    switch (shifted_val)
    {
    case 10:
        printf("Shifted value is 10\n");
        break;
    case 26:
        printf("Shifted value is 26\n");
        break;
    default:
        printf("Unknown shifted value\n");
        break;
    }

    // Cast Expression
    float div_result = (float)shifted_val / primes[1];

// Labelled Statement & Goto
result_label:
    printf("This is a labelled statement!\n");

    if (div_result > 1.0)
    {
        goto result_label;
    }

    // Final return statement
    return 0;
}
