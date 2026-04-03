/*
    FIFO Kullanımı
    - button0'a basılınca 1Den 8'e kadar FIFO'ya veri yazılır.
    - Daha sonra 0.5sn aralıklarla bu verilri okur.
    - CMOD A7 35T FPGA üzerinde denenmiştir.

*/

module usage #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8
) (
    input  logic              clk_i,
    input  logic              rst_i,    // Aktif Yüksek Reset (B18)
    input  logic              button_0, // Aktif Yüksek Başlat (A18)

    output logic [WIDTH-1:0]  data_o,
    output logic              full_o,
    output logic              empty_o
);

// --- Sinyal Tanımlamaları ---
// FIFO Sinyalleri
logic [WIDTH-1:0]  din_i;
logic              wr_valid_i, wr_ready_o;
logic              rd_ready_i, rd_valid_o;

// Yazılacak Sayıyı Tutan Counter
logic [WIDTH-1:0]  data_cnt_q;

// FSM ve Zamanlayıcı Sinyalleri
enum logic [1:0] { IDLE, LOAD, READ } state_q, next_state;
localparam int MAX_COUNT = 12_000_000 / 2; // 0.5sn
logic [22:0] timer_q;
logic        btn_reg, btn_edge;

// --- Donanım Birimleri ---

// 1. Buton Kenar Dedektörü
always_ff @(posedge clk_i) begin
    btn_reg  <= button_0;
    btn_edge <= button_0 && !btn_reg;
end

// 2. FIFO Modülü
fifo_parametric #(.WIDTH(WIDTH), .DEPTH(DEPTH)) i_fifo (
    .clk_i      (clk_i),
    .rst_ni     (!rst_i), 
    .wr_valid_i (wr_valid_i),
    .wr_ready_o (wr_ready_o),
    .din_i      (din_i),
    .rd_valid_o (rd_valid_o),
    .rd_ready_i (rd_ready_i),
    .dout_o     (data_o),
    .full_o     (full_o),
    .empty_o    (empty_o)
);

// --- Ana Mantık (FSM ve Counter) ---

always_ff @(posedge clk_i or posedge rst_i) begin : sequential_logic
    if (rst_i) begin
        state_q    <= IDLE;
        timer_q    <= '0;
        data_cnt_q <= 8'd1; // Saymaya 1'den başla
    end else begin
        state_q <= next_state;
        
        unique case (state_q)
            IDLE: begin
                timer_q    <= '0;
                data_cnt_q <= 8'd1; // Her yeni başlatmada 1'e dön
            end

            LOAD: begin
                // Eğer yazma işlemi başarılıysa (valid ve ready 1 ise) sayıyı artır
                if (wr_valid_i && wr_ready_o) begin
                    data_cnt_q <= data_cnt_q + 1'b1;
                end
            end

            READ: begin
                // 0.5 saniye sayacı
                if (!empty_o) begin
                    if (timer_q == MAX_COUNT - 1) timer_q <= '0;
                    else                          timer_q <= timer_q + 1'b1;
                end
            end
            
            default: state_q <= IDLE;
        endcase
    end
end


assign din_i = data_cnt_q;

always_comb begin : combinational_fsm
    next_state = state_q;
    wr_valid_i = 1'b0;
    rd_ready_i = 1'b0;

    case (state_q)
        IDLE: if (btn_edge) next_state = LOAD;
        
        LOAD: begin
            if (full_o) next_state = READ;
            else        wr_valid_i = 1'b1; // Yer olduğu sürece yaz
        end

        READ: begin
            if (empty_o) next_state = IDLE;
            else if (timer_q == MAX_COUNT - 1) rd_ready_i = 1'b1;
        end
        
        default: next_state = IDLE;
    endcase
end

endmodule 
