`timescale 1ns / 1ps

/* Description
**
** original work by Sam Skalicky, originally found here:
** http://opencores.org/project,fixed_point_arithmetic_parameterized
**
**
** Modified by Sung Ho Lee in 2023.12.07
**
** Modified features:
** Original modules not use 2's complement system
** => changed to use 2's complement system
*/

module qadd #(
	//Parameterized values
	parameter Q = 15,
	parameter N = 32
	)
	(
    input 	wire [N-1:0] a,
    input 	wire [N-1:0] b,
    output 	wire [N-1:0] c
    );

	assign c = a + b;

endmodule
