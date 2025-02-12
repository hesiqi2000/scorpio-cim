module ClockCounter 
(
    input   var logic                           clock,
    input   var logic                           reset,

    input   var logic                           cim_ren,

    output  var logic                           rsam_reset,
    output  var logic                           vcam_reset,
    output  var logic                           psum_start
);

    logic   [3:0]   cycle_counter;     
    logic           vcam_reset_temp;

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            cycle_counter <= 0;
            rsam_reset <= 0;
        end else if (cim_ren) begin
            if (cycle_counter == 4'd8) begin
                cycle_counter <= 0;
            end else begin
                cycle_counter <= cycle_counter + 1;
            end
            if (cycle_counter == 4'b0) begin
                rsam_reset <= 1;
            end else begin
                rsam_reset <= 0;
            end
        end else begin
            cycle_counter <= 0;
            rsam_reset <= 0;
        end
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            vcam_reset_temp <= 0;
        end else if (cycle_counter == 4'd8) begin
            vcam_reset_temp <= 1;
        end else begin
            vcam_reset_temp <= 0;
        end
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            psum_start <= '0;
        end else if (cycle_counter == 4'd4) begin
            psum_start <= '1;
        end else begin
            psum_start <= '0;
        end
    end

    logic [1:0] vcam_reset_d;

    always_ff @(posedge clock or negedge reset) begin
        if (reset) begin
            vcam_reset_d <= 2'b0;  
        end else begin
            vcam_reset_d <= {vcam_reset_d[0], vcam_reset_temp}; 
        end
    end

    assign  vcam_reset = vcam_reset_d[1];


endmodule
