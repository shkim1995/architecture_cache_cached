`timescale 1ns / 1ps


module cacheLine(
    
    input clk,
    
    //for read 
    input rWrite,
    input[11:0] targetTag,
    input[15:0] targetData[3:0],
    
    output valid,
    output[11:0] tag,
    output[63:0] data
);
    
    reg valid;
    reg[11:0] tag;
    reg[63:0] data;
    
    initial valid<= 0;
    
    initial tag <= 0;
    
    //read data update
    always @(posedge clk) begin
    
        if(rWrite) begin
            
            data[63:48]<=targetData[0];
            data[47:32]<=targetData[1];
            data[31:16]<=targetData[2];
            data[15:0]<=targetData[3];
                        
        end
    
    end
  

endmodule

module Icache(
    
    //inverse clk
    input clk,

    input readC,
    input[15:0] addrC,
    inout[15:0] dataC,
    output readyC,
    
    output readM,
    output[15:0] addrM,
    inout [15:0] dataM[3:0],
    input readyM
    

);
    
    
    ////get targets from addr
    
    wire[11:0] targetTag;
    wire[1:0] targetIdx;
    wire[1:0] targetBlock;
    
    assign targetTag = addrC[15:4];
    assign targetIdx = addrC[3:2];
    assign targetBlock = addrC[1:0];
    
    
    //////initiate cache lines
    
    wire valids[3:0];
    wire[11:0] tags[3:0];
    wire[63:0] datas[3:0];
   
    reg rWrite;
    initial rWrite<=0;
    
    generate
        genvar k;
        for(k=0; k<3; k=k+1) begin : dff
            cacheLine cl( 
            .clk(clk),
           
           //for read 
           .rWrite(rWrite),
           .targetTag(targetTag),
           .targetData(dataM[k]),
           
           .valid(valids[k]),
           .tag(tags[k]),
           .data(datas[k])
           
           );
        end
    endgenerate
    
    
    //////outputs    
    
    reg readyC;
    initial readyC<=0;
    
    wire[15:0] dataC;
    assign dataC = targetBlock==0 ? datas[targetIdx][63:48] : 
                   targetBlock==1 ? datas[targetIdx][47:32] : 
                   targetBlock==2 ? datas[targetIdx][31:15] : 
                   datas[targetIdx][15:0];
    
    reg readM;
    initial readM<=0;
    
    wire[15:0] addrM;
    assign addrM = addrC;
    
    
    //logic
    
    reg waitState;
    initial waitState<=0;
    
    reg readState;
    initial readState <= 0;
    
    always @(readC or addrC) begin
        
        waitState <= 0;
        readState <= 0;
        readyC <= 0;
        
        if(readC) begin
            
            //hit
            if(targetTag==tags[targetIdx]) begin
               readyC<=1; 
            end
            
            //miss
            else begin
                readM <= 1;
                waitState <= 1;
            end    
        end
        
    end
    
    always @(posedge clk) begin
        
        if(readyM && waitState) begin
            waitState <= 0;
            readState <= 1;
            rWrite <= 1;
        end
        
        if(readState) begin
            rWrite <= 0;
            readState <= 0;
            readyC <= 1;
        end
    
    end
                   
    
endmodule
