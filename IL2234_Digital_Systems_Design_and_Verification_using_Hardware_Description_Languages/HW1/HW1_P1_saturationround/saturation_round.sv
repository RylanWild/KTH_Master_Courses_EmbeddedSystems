`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/11 01:51:31
// Design Name: 
// Module Name: saturation_round
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module saturation_round #(parameter I=5, parameter Fin=16-I, parameter Fout=8-I)(
     input logic [15:0] in,//signed
     input logic up_down,//round up=1,round down=0
     output logic [7:0] out
     
     //output  reg in_dec_int,
     //output  reg in_dec_frac,
     //output reg  out_dec_int,
     //output reg  out_dec_frac
     
    );

    always_comb begin
      
      //negative or positive
      
        case (up_down)
            1'b1://round up
             begin 
                if(in[15]==0)//positive number
                    begin      
                  //out=in[15:8]+2<<<(8-I);
                        out={in[15],(in[14:8]+1)};//add 1
                    end
                 else//negative number
                    begin
                       out={in[15],in[14:8]};
                    end      
             end
        
            1'b0://round down
             begin
                    if(in[15]==0)//positive number
                    begin              
                         out={in[15],in[14:8]};
                    end
                    
                   else //negative number
                    begin
                        //out={in[15],in[14:8]+1};//add 1
                      out[7]=in[15];
                      out[6:0]=in[14:8]+1;
                      //out=in[15:8]+1;  
                    end      
             end
             default: out=8'b00000000;   
        
        endcase
        /*
        //-------------------------signed binary to decimal---------------------------
        in_dec_int=8'd00000000;
        in_dec_frac=0;
        out_dec_int=8'd00000000;
        out_dec_frac=0;
        
        if (in[15]==0)//positive 
         begin
            for(int i=0;i<I-1;i++)
                begin
                in_dec_int=in_dec_int+in[16-I+i]*(2>>>i);
                end
            for(int j=0;j<16-I;j++)
                begin
                in_dec_frac=in_dec_frac+in[j]*(2<<<(16-I-j));
                end
         end
        
        else//negative
        begin
            for(int i=0;i<I-1;i++)
                begin
                in_dec_int=-(in_dec_int+in[16-I+i]*(2>>>i));
                end
            for(int j=0;j<16-I;j++)
                begin
                in_dec_frac=in_dec_frac+in[j]*(2<<<(16-I-j));
                end
         end
       */
     end
     
endmodule
