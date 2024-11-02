## Shortcomings

1. Coversion of boolean of integer in artihmetic expressions gives segmentation fault:

   ```
   int main()
   {
       int j;
       int i;
       int k;
       k = 10 + (i < j);
   }
   ```

2. Paranthesis around logical expressions gives segmentation fault.
   ```
   int main()
   {
       int i;
       int j;
       if (i == j)
       {
           i = 10;
       }
   }
   ```
   works but
   ```
   int main()
   {
       int i;
       int j;
       if ((i == j))
       {
           i = 10;
       }
   }
   ```
   does not.
