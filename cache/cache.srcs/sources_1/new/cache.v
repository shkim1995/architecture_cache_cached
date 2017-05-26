`timescale 1ns / 1ps


module cacheLine(
    
    input clk,
    
    //for read 
    input rWrite,
    input[11:0] targetTag,
    input[63:0] targetData,
    
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
    always @(rWrite) begin
    
        if(rWrite) begin
            
            valid <= 1;
            data <= targetData;
            tag <= targetTag;
            $display("TARGET Data : %h", targetData);
                        
        end
    
    end
  

endmodule

module Dcache(

    //inverse clk
    input clk,

    input readC,
    input writeC,
    input[15:0] addrC,
    inout[15:0] dataC,
    output readyC,
    
    output readM,
    output writeM,
    output[15:0] addrM,
    inout [63:0] dataM,
    input readyM,
    
    output[15:0] hit,
    output[15:0] miss
);
    
    //for counting hits & misses
    reg[15:0] hit;
    reg[15:0] miss;
    initial hit<=0;
    initial miss<=0;
    
    
    ////get targets from addr
    
    wire[11:0] targetTag;
    wire[1:0] targetIdx;
    wire[1:0] targetBlock;
    
    always@ targetIdx $display("targetIdx %b", targetIdx );
    
    assign targetTag = addrC[15:4];
    assign targetIdx = addrC[3:2];
    assign targetBlock = addrC[1:0];
    
    //////initiate cache lines
    
    wire valids[3:0];
    wire[11:0] tags[3:0];
    wire[63:0] datas[3:0];
   
    reg rWrite[3:0];
    initial rWrite[0]<=0;
    initial rWrite[1]<=0;
    initial rWrite[2]<=0;
    initial rWrite[3]<=0;
    
    generate
        genvar k;
        for(k=0; k<4; k=k+1) begin : dff
            cacheLine cl( 
            .clk(clk),
           
           //for read 
           .rWrite(rWrite[k]),
           .targetTag(targetTag),
           .targetData(dataM),
           
           .valid(valids[k]),
           .tag(tags[k]),
           .data(datas[k])
           
           );
        end
    endgenerate
    
    //////outputs    
        
    reg readyC;
    initial readyC<=1;
    
    wire[15:0] dataC;
    assign dataC = !readC ? 15'bz :
                   targetBlock==0 ? datas[targetIdx][63:48] : 
                   targetBlock==1 ? datas[targetIdx][47:32] : 
                   targetBlock==2 ? datas[targetIdx][31:16] : 
                   datas[targetIdx][15:0];
    
    reg readM;
    initial readM<=0;
    
    reg writeM;
    initial writeM<=0;
    
    wire[15:0] addrM;
    assign addrM = addrC;
    
    wire[63:0] dataM;
    assign dataM = writeM ? dataC : 64'bz;
    /*dataC fix required*/
    
    always @(posedge clk) begin
        $display("%h", dataM);
    end
    //logic
    
    //read logic
        
    reg waitState;
    initial waitState<=0;
    
    reg readState;
    initial readState <= 0;
    
    
    always @(readC or addrC or targetIdx) begin
        
        waitState <= 0;
        readState <= 0;
        
        if(readC) begin
            
            //hit
            if(targetTag==tags[targetIdx] && valids[targetIdx]) begin
                $display("HIT");
                //$display("HIT, t.index %h, t.tag %h,  ");
               readyC<=1; 
               hit <= hit+1;
            end
            
            //miss
            else begin
                readyC <= 0;
                $display("MISS");
                $display("readyM %b, waitState %b, readM %b, clk %b", readyM, waitState, readM, clk);
                readM <= 1;
                waitState <= 1;
            end    
        end
        
    end
    
    always @(negedge clk) begin
        
//        $display("readyM %b, waitState %b", readyM, waitState);
        
        if(readyM && waitState) begin
            $display("DCACHE WAITSTATE, TA : %b, rWrite : %b", targetIdx, rWrite[targetIdx]);
            waitState <= 0;
            readState <= 1;
            rWrite[targetIdx] <= 1;
        end
        
        if(readState) begin
            $display("DCACHE READSTATE, %h", dataM);
            rWrite[targetIdx] <= 0;
            readState <= 0;
            readyC <= 1;
            readM<=0;
            miss <= miss+1;
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
    inout [63:0] dataM,
    input readyM,
    

    output[15:0] hit,
    output[15:0] miss
);
    
    //for counting hits & misses
    reg[15:0] hit;
    reg[15:0] miss;
    initial hit<=0;
    initial miss<=0;
    
    ////get targets from addr
    
    wire[11:0] targetTag;
    wire[1:0] targetIdx;
    wire[1:0] targetBlock;
    
    always@ targetIdx $display("targetIdx %b", targetIdx );
    
    assign targetTag = addrC[15:4];
    assign targetIdx = addrC[3:2];
    assign targetBlock = addrC[1:0];
    
    
    //////initiate cache lines
    
    wire valids[3:0];
    wire[11:0] tags[3:0];
    wire[63:0] datas[3:0];
   
    reg rWrite[3:0];
    initial rWrite[0]<=0;
    initial rWrite[1]<=0;
    initial rWrite[2]<=0;
    initial rWrite[3]<=0;
    
    generate
        genvar k;
        for(k=0; k<4; k=k+1) begin : dff
            cacheLine cl( 
            .clk(clk),
           
           //for read 
           .rWrite(rWrite[k]),
           .targetTag(targetTag),
           .targetData(dataM),
           
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
                   targetBlock==2 ? datas[targetIdx][31:16] : 
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
    
    
    always @(readC or addrC or targetIdx) begin
        
        waitState <= 0;
        readState <= 0;
        
        if(readC) begin
            
            //hit
            if(targetTag==tags[targetIdx] && valids[targetIdx]) begin
                $display("HIT");
                //$display("HIT, t.index %h, t.tag %h,  ");
               readyC<=1; 
               hit <= hit+1;
            end
            
            //miss
            else begin
            
                readyC <= 0;
                $display("MISS");
                $display("readyM %b, waitState %b, readM %b, clk %b", readyM, waitState, readM, clk);
                readM <= 1;
                waitState <= 1;
            end    
        end
        
    end
    
    always @(negedge clk) begin
        
//        $display("readyM %b, waitState %b", readyM, waitState);
        
        if(readyM && waitState) begin
            $display("WAITSTATE, TA : %b, rWrite : %b", targetIdx, rWrite[targetIdx]);
            waitState <= 0;
            readState <= 1;
            rWrite[targetIdx] <= 1;
        end
        
        if(readState) begin
            $display("READSTATE");
            rWrite[targetIdx] <= 0;
            readState <= 0;
            readyC <= 1;
            miss <= miss+1;
        end
    
    end
    
    
endmodule
