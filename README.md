# fifo_parametric



### Debug Modu

Debug modunu aktif etmek için Makefile'daki `V_FLAGS` içinde `-DFIFO_PARAMETRIC_DEBUG` tanımlıdır. Debug çıktıları:

```verilog
`ifdef FIFO_PARAMETRIC_DEBUG
    always_ff @(posedge clk) begin
        if (tick_s) begin
            $display("[DEBUG] %t | LED Durumu Degisti: %b", $time, led_r);
        end
    end
`endif
```

## Simülasyon Çıktıları

- **Dalga formu**: `sim/vcd/trace.vcd`
- **Simülasyon logu**: `sim/logs/sim.log`
- **Cocotb logu**: `sim/logs/cocotb.log`


## Dökümantasyon

Parametrik ve FWFT (First-Word Fall-Through) mimarisine sahip bir FIFO birimidir.

Temel Özellikler:
- Parametrik Yapı: Veri genişliği (WIDTH) ve derinliği (DEPTH) ayarlanabilir.
- FWFT Desteği: İlk veri yazıldığı anda okuma ucunda (dout_o) hazır bekler, gecikme (latency) teorik olarak yoktur.
- Ready-Valid Handshake: AXI4-Stream standartlarına uyumlu el sıkışma protokolü.
- N+1 Pointer : Tam dolu ve tam boş durumlarını ayırt etmek için optimize edilmiş pointer yapısı.


|**Sinyal İsmi**|**Yön**|**Genişlik**|**Açıklama**|
|---|---|---|---|
|`clk_i`|Giriş|1|Sistem saat sinyali (Yükselen kenar tetiklemeli)|
|`rst_ni`|Giriş|1|Senkron aktif-düşük reset sinyali|
|**Yazma Grubu**||||
|`wr_valid_i`|Giriş|1|Yazma geçerlilik sinyali (Master veriyi sürmeye hazır)|
|`wr_ready_o`|Çıkış|1|Yazma hazır sinyali (FIFO veri alabilir - `!full`)|
|`din_i`|Giriş|`WIDTH`|FIFO giriş veri yolu|
|**Okuma Grubu**||||
|`rd_valid_o`|Çıkış|1|Okuma geçerlilik sinyali (FIFO'da veri var - `!empty`)|
|`rd_ready_i`|Giriş|1|Okuma hazır sinyali (Slave veriyi almaya hazır)|
|`dout_o`|Çıkış|`WIDTH`|FIFO çıkış veri yolu (FWFT)|
|**Durum Grubu**||||
|`full_o`|Çıkış|1|FIFO'nun tamamen dolu olduğunu belirtir|
|`empty_o`|Çıkış|1|FIFO'nun tamamen boş olduğunu belirtir|


---


![fifo](./docs/images/image.png)


clk_i 3. yükselen kenarında Data A FIFO'ya yazılır.