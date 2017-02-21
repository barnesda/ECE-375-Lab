/*
BumpBot

PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
*/
#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
    DDRB = 0b11110000;      // configure Port B pins for input/output
    DDRD = 0b00000000;        // Configure Port D's pins as an inputs
    PORTD = 0b00000011;        // Pull-up resistors on used pins
    //PORTB = 0b11110000;     // set initial value for Port B outputs
    // (initially, disable both motors)

    PORTB = 0b01100000;        // Initiate the tekbot by move forward
    while (1) { // loop forever

        if((~PIND & 0b00000010) || (~PIND & 0b00000011) ){    //Left whisker or both whiskers has been depressed
            PORTB = 0b00000000;     // move backward
            _delay_ms(500);         // wait for 500 ms
            PORTB = 0b01000000;     // turn right
            _delay_ms(2000);        // wait for 2 s
            PORTB = 0b01100000;        // move forward
        }
        else if(~PIND & 0b00000001){    //Right whisker has been depressed
            PORTB = 0b00000000;     // move backward
            _delay_ms(500);         // wait for 500 ms
            PORTB = 0b00100000;     // turn left
            _delay_ms(2000);        // wait for 2 s
            PORTB = 0b01100000;        // move forward
        }
    }

    /*
    PORTB = 0b01100000;     // make TekBot move forward
    _delay_ms(500);         // wait for 500 ms
    PORTB = 0b00000000;     // move backward
    _delay_ms(500);         // wait for 500 ms
    PORTB = 0b00100000;     // turn left
    _delay_ms(1000);        // wait for 1 s
    PORTB = 0b01000000;     // turn right
    _delay_ms(2000);        // wait for 2 s
    PORTB = 0b00100000;     // turn left
    _delay_ms(1000);        // wait for 1 s
    */
}
