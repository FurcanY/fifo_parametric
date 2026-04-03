import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, Timer
import random
from collections import deque

# --- Yardımcı Fonksiyon: Reset ve Clock ---
async def setup_fifo(dut):
    """Sıfırlama ve Clock başlatma rutini (Her testin başında çağrılır)"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    dut.rst_ni.value = 0
    dut.wr_valid_i.value = 0
    dut.rd_ready_i.value = 0
    dut.din_i.value = 0
    await RisingEdge(dut.clk_i)
    await Timer(5, unit="ns")
    dut.rst_ni.value = 1
    await RisingEdge(dut.clk_i)

# --- TEST 1: Tam Dolum ve Boşaltım ---
@cocotb.test()
async def test_fifo_full_empty(dut):
    """Senaryo 1 & 2: FIFO'yu tamamen doldur, full_o kontrol et ve boşalt."""
    await setup_fifo(dut)
    depth = 16
    test_data = [random.randint(0, 255) for _ in range(depth)]

    dut._log.info("Test: Tam Dolum Başlıyor...")
    for data in test_data:
        dut.din_i.value = data
        dut.wr_valid_i.value = 1
        await RisingEdge(dut.clk_i)
    
    dut.wr_valid_i.value = 0
    await Timer(1, unit="ps") # Lojik yayılım için kısa bekleme
    assert dut.full_o.value == 1, "Hata: FIFO dolu ama full_o sinyali düşük!"

    dut._log.info("Test: Boşaltma ve Veri Doğrulama Başlıyor...")
    for expected_val in test_data:
        dut.rd_ready_i.value = 1
        await ReadOnly() # FWFT olduğu için veri zaten hazır
        assert int(dut.dout_o.value) == expected_val, f"Hata! Beklenen: {hex(expected_val)}, Gelen: {hex(int(dut.dout_o.value))}"
        await RisingEdge(dut.clk_i)
    
    dut.rd_ready_i.value = 0
    await Timer(1, unit="ps")
    assert dut.empty_o.value == 1, "Hata: FIFO boş ama empty_o sinyali düşük!"

# --- TEST 2: Aynı Anda Yazma ve Okuma (Shadow Model) ---
@cocotb.test()
async def test_fifo_simultaneous_rw(dut):
    """Senaryo 3: Rastgele aynı anda yazma ve okuma ile veri bütünlüğü testi."""
    await setup_fifo(dut)
    shadow_fifo = deque()
    
    dut._log.info("Test: Shadow Model ile Rastgele RW Başlıyor...")
    for i in range(200):
        # 1. Mevcut durumu gör
        is_full  = (dut.full_o.value == 1)
        is_empty = (dut.empty_o.value == 1)
        
        # 2. Karar ver
        do_write = random.choice([True, False]) and not is_full
        do_read  = random.choice([True, False]) and not is_empty

        # 3. Doğrulama
        if do_read:
            actual_val = int(dut.dout_o.value)
            expected_val = shadow_fifo[0]
            assert actual_val == expected_val, f"Adım {i}: Beklenen {hex(expected_val)}, Gelen {hex(actual_val)}"

        # 4. Sinyalleri Sür
        if do_write:
            val = random.randint(0, 255)
            dut.din_i.value = val
            dut.wr_valid_i.value = 1
            shadow_fifo.append(val)
        else:
            dut.wr_valid_i.value = 0

        if do_read:
            dut.rd_ready_i.value = 1
            shadow_fifo.popleft()
        else:
            dut.rd_ready_i.value = 0

        await RisingEdge(dut.clk_i)
        await Timer(1, unit="ps")

# --- TEST 3: Overflow (Taşma) Koruması ---
@cocotb.test()
async def test_fifo_overflow(dut):
    """Senaryo 4: Dolu FIFO'ya yazma denemesi ve verinin bozulmadığını doğrulama."""
    await setup_fifo(dut)
    
    dut._log.info("Test: Overflow Koruması Kontrol Ediliyor...")
    # 1. Doldur
    while dut.full_o.value == 0:
        dut.wr_valid_i.value = 1
        dut.din_i.value = 0xFE
        await RisingEdge(dut.clk_i)
    
    # 2. Doluyken farklı bir veri yazmaya çalış
    dut.din_i.value = 0xAD 
    await RisingEdge(dut.clk_i)
    dut.wr_valid_i.value = 0
    

    dut.rd_ready_i.value = 1
    await ReadOnly()
    assert int(dut.dout_o.value) == 0xFE, "Hata: Overflow durumunda veri üzerine yazıldı!"

# --- TEST 4: Çalışma Anında Reset ---
@cocotb.test()
async def test_fifo_reset_during_op(dut):
    """Ekstra Senaryo: İşlem yaparken reset atıldığında pointerların sıfırlanması."""
    await setup_fifo(dut)
    
    dut._log.info("Test: Çalışma Anında Reset Kontrolü...")
    # Biraz veri yaz
    for _ in range(5):
        dut.din_i.value = 0x55
        dut.wr_valid_i.value = 1
        await RisingEdge(dut.clk_i)
    
    # Reset at
    dut.rst_ni.value = 0
    await RisingEdge(dut.clk_i)
    dut.rst_ni.value = 1
    await Timer(1, unit="ps")
    
    assert dut.empty_o.value == 1, "Hata: Reset sonrası FIFO boş değil!"