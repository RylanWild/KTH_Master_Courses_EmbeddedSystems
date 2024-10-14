#include <stdbool.h>
#include <stdio.h>
struct Program1Output {
    bool x;
    bool y;
};

struct Program1Output program_1(bool a, bool b, bool *prev_s) {//need a,b,pre(s) to determine next_s
    struct Program1Output output;

    // Forbidden: a and b shall not be active at the same time
    if (a && b) {
        output.x = false;
        output.y = false;
    } else {
        // Compute the next value of s based on the previous value of s and inputs a, b
        bool next_s;
        if ((!*prev_s && a) || (*prev_s && !a && !b)) {
            next_s = true;
        } else {
            next_s = false;
        }

        // Update the value of s for the next cycle
        *prev_s = next_s;

        // Compute the outputs x and y based on the current value of s and inputs a, b
        output.x = b || (a && *prev_s);
        output.y = *prev_s && b;
    }

    return output;
}

int main() {
    // Define variables to hold inputs and previous value of s
    bool a, b, prev_s;
    
    // Initialize the previous value of s
    prev_s = false;
    for(int i=0;i<10;i++){
    // Get inputs from the user
    printf("Enter the value of a (0 or 1): ");
    scanf("%d", &a);
    printf("Enter the value of b (0 or 1): ");
    scanf("%d", &b);
    
    // Call the program_1 function to compute outputs x and y
    struct Program1Output output = program_1(a, b, &prev_s);
    
    // Display the outputs
    printf("Output x: %d\n", output.x);
    printf("Output y: %d\n", output.y);
    }
    return 0;
}
