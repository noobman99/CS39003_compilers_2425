/* Test File */

typedef unsigned int uint;

static const float e = 2.718;
auto num = 42;
_Bool flag = 0;
enum color
{
    Red = 1,
    Green,
    Blue
};
/*
    /* Nested comment */
struct point
{
    int x;
    int y;
};

union data
{
    char c;
    double d;
};

inline int square(int n);

void main()
{
    // Testing basic types and constants
    int a = 10;            // integer-constant
    enum color col = Blue; // enum-constant
    double d1 = 3.14;      // floating-constant
    double d2 = 3.1e2;
    double d3 = .1e-2;
    char ch = 'A'; // "character-constant"
    char newline = '\n';

    // Testing string literals
    char empty[1] = "";
    char message[] = "Hello, World!\\\"\n";

    // Testing punctuators and operators
    int x = 5, y = 10;
    x++;
    y--;
    x = x & y;
    x = x * y;
    x = x + y;
    x = x - y;
    x = !y;
    x = ~y;
    x = x / y;
    x = x % y;
    x = x << 2;
    x = x >> 1;
    x = x ^ y;
    x = x | y;
    x = (x > y) ? x : y;
    x *= y;
    x /= y;
    x %= y;
    x += y;
    x -= y;
    x <<= 1;
    x >>= 2;
    x &= y;
    x ^= 1;
    x |= 0;

    struct point *p;
    if (!p)
    {
        p = (struct point *)malloc(sizeof(struct point));
        p->x = 0;
        p->y = 0;
    }

    switch (col)
    {
    case Red:
        p->x = 1;
        break;
    case Green:
        p->x = 2;
        break;
    case Blue:
        p->x = 3;
        break;
    default:
        p->x = 0;
        break;
    }

    int count = 5;
    while (count > 0)
    {
        count--;
    }

    for (int i = 0; i < 10; i++)
    {
        if (i % 2 == 0)
        {
            continue;
        }
        else
        {
            break;
        }
    }

    if (x < 100)
    {
        x = 100;
    }
    else
    {
        x = 50;
    }

    // Testing comments
    // This is a single line comment

    /* This is a multi-line comment.
     * This comment has multiple lines. */

    @ // Invalid token
        a = 'AB'
}
