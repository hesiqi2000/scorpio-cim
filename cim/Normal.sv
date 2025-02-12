module Normal (
    input   var logic   [21 : 0]                sum,
    input   var logic   [7 : 0]                 emax,
    input   var logic   [7 : 0]                 cim_idata_exp,
    
    output  var logic   [15 : 0]                cim_odata
);
    
    logic   [7 : 0]    normal_exp, cim_odata_exp, cim_odata_man;

    always_comb begin
        if (sum[21] != sum[20]) begin
            normal_exp = emax + 8;
            cim_odata_man = sum[21 : 14];
        end else if (sum[21] != sum[19]) begin
            normal_exp = emax + 7;
            cim_odata_man = sum[20 : 13];
        end else if (sum[21] != sum[18]) begin
            normal_exp = emax + 6;
            cim_odata_man = sum[19 : 12];
        end else if (sum[21] != sum[17]) begin
            normal_exp = emax + 5;
            cim_odata_man = sum[18 : 11];
        end else if (sum[21] != sum[16]) begin
            normal_exp = emax + 4;
            cim_odata_man = sum[17 : 10];
        end else if (sum[21] != sum[15]) begin
            normal_exp = emax + 3;
            cim_odata_man = sum[16 : 9];
        end else if (sum[21] != sum[14]) begin
            normal_exp = emax + 2;
            cim_odata_man = sum[15 : 8];
        end else if (sum[21] != sum[13]) begin
            normal_exp = emax + 1;
            cim_odata_man = sum[14 : 7];
        end else if (sum[21] != sum[12]) begin
            normal_exp = emax;
            cim_odata_man = sum[13 : 6];
        end else if (sum[21] != sum[11]) begin
            normal_exp = emax - 1;
            cim_odata_man = sum[12 : 5];
        end else if (sum[21] != sum[10]) begin
            normal_exp = emax - 2;
            cim_odata_man = sum[11 : 4];
        end else if (sum[21] != sum[9]) begin
            normal_exp = emax - 3;
            cim_odata_man = sum[10 : 3];
        end else if (sum[21] != sum[8]) begin
            normal_exp = emax - 4;
            cim_odata_man = sum[9 : 2];
        end else if (sum[21] != sum[7]) begin
            normal_exp = emax - 5;
            cim_odata_man = sum[8 : 1];
        end else if (sum[21] != sum[6]) begin
            normal_exp = emax - 6;
            cim_odata_man = sum[7 : 0];
        end else if (sum[21] != sum[5]) begin
            normal_exp = emax - 7;
            cim_odata_man = {sum[6 : 0], 1'b0};
        end else if (sum[21] != sum[4]) begin
            normal_exp = emax - 8;
            cim_odata_man = {sum[5 : 0], 2'b0};
        end else if (sum[21] != sum[3]) begin
            normal_exp = emax - 9;
            cim_odata_man = {sum[4 : 0], 3'b0};
        end else if (sum[21] != sum[2]) begin
            normal_exp = emax - 10;
            cim_odata_man = {sum[3 : 0], 4'b0};
        end else if (sum[21] != sum[1]) begin
            normal_exp = emax - 11;
            cim_odata_man = {sum[2 : 0], 5'b0};
        end else if (sum[21] != sum[1]) begin
            normal_exp = emax - 12;
            cim_odata_man = {sum[1 : 0], 6'b0};
        end else if (sum[21] != sum[0]) begin
            normal_exp = emax - 13;
            cim_odata_man = {sum[0], 7'b0};
        end else if (sum[21] == 1'b0) begin
            normal_exp = '0;
            cim_odata_man = '0;
        end else if (sum[21] == 1'b1) begin
            normal_exp = emax - 7;
            cim_odata_man = '1;
        end
    end

    assign cim_odata_exp = (cim_odata_man == '0) ? '0 : (normal_exp + cim_idata_exp - 127);

    assign  cim_odata = {cim_odata_exp, cim_odata_man};

endmodule: Normal