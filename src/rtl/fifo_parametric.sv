`timescale 1ns/1ps
/*
    modül: fifo_parametric
    yazar: Furkan Yıldırım

*/
module fifo_parametric #(
    parameter int WIDTH = 8,  // Veri genişliği
    parameter int DEPTH = 16  // FIFO derinliği
) (
    input  logic              clk_i,
    input  logic              rst_ni,      // Senkron aktif düşük reset
    // Yazma Arayüzü 
    input  logic              wr_valid_i,  // Veri yazılmak isteniyor mu?
    output logic              wr_ready_o,  // FIFO yazmaya hazır mı? (!full)
    input  logic [WIDTH-1:0]  din_i,       // Giriş verisi
    // Okuma Arayüzü
    output logic              rd_valid_o,  // FIFO'da geçerli veri var mı? (!empty)
    input  logic              rd_ready_i,  // Dış dünya okumaya hazır mı?
    output logic [WIDTH-1:0]  dout_o,      // Çıkış verisi
    // Durum Sinyalleri
    output logic              full_o,      // Tam dolu
    output logic              empty_o      // Tam boş
);

    // --- Parametre Hesaplamaları ---
    localparam int ADDR_WIDTH = $clog2(DEPTH);

    // --- Bellek Tanımlamaları ---
    logic [WIDTH-1:0] fifo_mem [0:DEPTH-1]; // Veri depolama bloğu

    // --- Pointer Sinyalleri ---
    // Pointerlar, Full/Empty ayrımı için 1 bit fazladan tanımlanır.
    logic [ADDR_WIDTH:0] wr_ptr_q; // Yazma pointer register'ı
    logic [ADDR_WIDTH:0] rd_ptr_q; // Okuma pointer register'ı

    // --- Durum Kontrol Sinyalleri ---
    logic wr_en; // Dahili yazma yetki sinyali
    logic rd_en; // Dahili okuma yetki sinyali

    // --- Atamalar (Logic) ---
    
    // FIFO Boş: Pointerlar tamamen aynı olduğunda
    assign empty_o    = (wr_ptr_q == rd_ptr_q);
    assign rd_valid_o = !empty_o; // Boş değilse veri geçerlidir
    
    // FIFO Dolu: MSB farklı, diğer bitler aynı olduğunda
    assign full_o     = (wr_ptr_q[ADDR_WIDTH] != rd_ptr_q[ADDR_WIDTH]) &&
                        (wr_ptr_q[ADDR_WIDTH-1:0] == rd_ptr_q[ADDR_WIDTH-1:0]);
    assign wr_ready_o = !full_o; // Dolu değilse yazmaya hazırdır

    // Dahili kontrol logicleri
    assign wr_en = wr_valid_i && wr_ready_o; // Geçerli veri var ve yerimiz var
    assign rd_en = rd_ready_i && rd_valid_o; // Okuma isteği var ve veri var

    // --- Yazma Operasyonu ---
    always_ff @(posedge clk_i) begin : fifo_write_block
        /* Yazma işlemi: Eğer reset yoksa ve yazma yetkisi varsa belleğe yaz */
        if (!rst_ni) begin
            wr_ptr_q <= '0;
        end else if (wr_en) begin
            fifo_mem[wr_ptr_q[ADDR_WIDTH-1:0]] <= din_i;
            wr_ptr_q <= wr_ptr_q + 1'b1;
        end
    end

    // --- Okuma Operasyonu ---
    always_ff @(posedge clk_i) begin : fifo_read_block
        /* Okuma işlemi: Pointer ilerletme */
        if (!rst_ni) begin
            rd_ptr_q <= '0;
        end else if (rd_en) begin
            rd_ptr_q <= rd_ptr_q + 1'b1;
        end
    end

    // --- Çıkış Verisi ---
    // FWFT (First-Word Fall-Through) yapısı: Veri her zaman hazır bekler.
    assign dout_o = fifo_mem[rd_ptr_q[ADDR_WIDTH-1:0]];

    // --- Debug İşlemleri ---
    `ifdef FIFO_PARAMETRIC_DEBUG
    always_comb begin : debug_logic
        // Örn: Doluluk oranı hesaplama
        /* Bu blok sadece simülasyonda gözlem amaçlıdır */
    end
    `endif

endmodule
