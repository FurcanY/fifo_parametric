`timescale 1ns/1ps

module fifo_parametric_tb;

    // --- Simülasyon Sinyalleri ---
    localparam int WIDTH_ = 8;
    localparam int DEPTH_ = 16;
    localparam int CLOCK_PERIOD = 10;

    logic               clk_i      ;
    logic               rst_ni     ;
    logic               wr_valid_i ;
    logic               wr_ready_o ;
    logic [WIDTH_-1:0]  din_i      ;
    logic               rd_valid_o ;
    logic               rd_ready_i ;
    logic [WIDTH_-1:0]  dout_o     ;
    logic               full_o     ;
    logic               empty_o    ;
    
    // --- Clock Oluşturma ---
    initial begin
        clk_i = 0; 
        forever #(CLOCK_PERIOD/2) clk_i = ~clk_i;
    end

    // --- Unit Under Test (UUT) ---
    fifo_parametric #(.WIDTH(WIDTH_), .DEPTH(DEPTH_)) uut (.*);

    // --- Wave Form İşlemleri ---
    initial begin
        if ($test$plusargs("trace")) begin
            $dumpfile("sim/vcd/trace.vcd");
            $dumpvars(0, fifo_parametric_tb);
        end
    end
    
    // --- Test Akışı ---
    initial begin
        // Başlangıç Değerleri
        rst_ni = 0; wr_valid_i = 0; rd_ready_i = 0;
        
        $display("\n-----------------------------------------------------");
        $display("  STARTING: Parametric FIFO IP Verification");
        $display("-----------------------------------------------------\n");

        reset_fifo(5);

        // --- TEST 1: Basit Yazma/Okuma ---
        $display("[%0t] [TEST 1] Ardışık Yazma ve Okuma Başlıyor...", $time);
        write_fifo(8'h55);
        write_fifo(8'hAA);
        write_fifo(8'hBB);
        write_fifo(8'hCC);

        read_fifo(8'h55);
        read_fifo(8'hAA);
        read_fifo(8'hBB);
        read_fifo(8'hCC);

        // --- TEST 2: Kapasite ve Bayrak Kontrolü ---
        $display("\n[%0t] [TEST 2] Kapasite Limit Testleri Başlıyor...", $time);

        for (int i = 0; i < DEPTH_; i++) begin
            write_fifo(8'h10 + i[WIDTH_-1:0]);
        end

        // Full Kontrolü
        assert (full_o === 1'b1) 
            $display("[%0t] [SUCCESS] FIFO Tam Dolu Bayrağı Doğrulandı.", $time);
        else 
            $error("[%0t] [ERROR] FIFO Dolu Olmalıydı!", $time);

        // Dolu FIFO'ya Yazma Denemesi (Overflow Check)
        write_fifo(8'hFF); 

        // FIFO'yu Boşaltma
        for (int i = 0; i < DEPTH_; i++) begin
            read_fifo(8'h10 + i[WIDTH_-1:0]);
        end

        // Empty Kontrolü
        assert (empty_o === 1'b1) 
            $display("[%0t] [SUCCESS] FIFO Tam Boş Bayrağı Doğrulandı.", $time);
        else 
            $error("[%0t] [ERROR] FIFO Boş Olmalıydı!", $time);
        
        // --- TEST 2.1: Underflow Kontrolü (Hatalı Okuma Denemesi) ---
        $display("[%0t] [TEST 2.1] Underflow Koruması Test Ediliyor...", $time);
        // read_fifo kullanmıyoruz çünkü kilitler (timeout verir). Manuel kontrol:
        rd_ready_i = 1'b1;
        @(posedge clk_i);
        rd_ready_i = 1'b0;
        assert (rd_valid_o === 1'b0) 
            $display("[%0t] [SUCCESS] Boş FIFO'dan veri okunması engellendi.", $time);
        else 
            $error("[%0t] [ERROR] Boş FIFO'dan geçersiz veri çıktı!", $time);

        // --- TEST 3: Simultaneous RW ---
        $display("\n[%0t] [TEST 3] Eş Zamanlı Yazma/Okuma Testi...", $time);
        test_simultaneous_rw();

        $display("\n-----------------------------------------------------");
        $display("  VERIFICATION COMPLETE - ALL TESTS PASSED");
        $display("-----------------------------------------------------\n");
        #100;
        $finish;
    end

// --- Taskler ---

task automatic reset_fifo(int clk_time);
    begin
        $display("[%0t] [SYSTEM] Reset uygulanıyor...", $time);
        rst_ni = 1'b0;
        #(CLOCK_PERIOD * clk_time);
        rst_ni = 1'b1;
        @(posedge clk_i);
        $display("[%0t] [SYSTEM] Reset kaldırıldı.", $time);
    end
endtask

task automatic write_fifo(input logic [WIDTH_-1:0] input_data);
    begin
        if (full_o) begin
            $display("[%0t] [WARNING] Yazma Reddedildi: FIFO Dolu! (Data: %h)", $time, input_data);
        end else begin
            @(posedge clk_i);
            wr_valid_i = 1'b1;
            din_i = input_data;
            @(posedge clk_i);
            wr_valid_i = 1'b0;
            $display("[%0t] [WRITE] Veri içeri alındı: %h", $time, input_data);
        end
    end
endtask

task automatic read_fifo(input logic [WIDTH_-1:0] expected_data);
    begin
        // Senkronizasyon ve Timeout
        fork : timeout_block
            begin
                wait(rd_valid_o);
            end
            begin
                #(CLOCK_PERIOD * 10);
                if (!rd_valid_o) begin
                    $display("[%0t] [FATAL] Okuma Hatası: Veri gelmedi (Timeout)!", $time);
                    $finish;
                end
            end
        join_any
        disable fork;

        // Veri Doğrulaması
        assert (dout_o === expected_data)
            $display("[%0t] [READ] Doğrulandı: %h", $time, dout_o);
        else begin
            $display("[%0t] [ERROR] Uyuşmazlık! Beklenen: %h, Gelen: %h", $time, expected_data, dout_o);
            $finish;
        end

        @(posedge clk_i);
        rd_ready_i = 1;
        @(posedge clk_i);
        rd_ready_i = 0;
    end
endtask

task automatic test_simultaneous_rw();
    begin
        fork
            write_fifo(8'hAB);
            read_fifo(8'hAB);
        join
        $display("[%0t] [INFO] Eş zamanlı işlem başarıyla tamamlandı.", $time);
    end
endtask

endmodule
