package scorpio

import chipmunk._
import chipmunk.stream._
import chisel3._
import chisel3.experimental.ExtModule

class PixiBackend extends Module {
  val io = IO(new Bundle {
    val config   = Input(new NpuConfigIO())

    val px_config_reg_wb = Output(UInt(64.W))
    val px_config_reg_wb_en = Output(Bool())

    val ibufAccess0 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess1 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess2 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess3 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))

    val rsamAccess = Master(new RsamAccessIO(dataWidth = 64, addrWidth = 8))
  })

    val u_fsm_total = Module(new PixiBbox)
    u_fsm_total.clk := clock
    u_fsm_total.rst_n := !reset.asBool
    u_fsm_total.mode.config_reg := io.config.rsamConfig
    
    io.px_config_reg_wb := u_fsm_total.mode.config_reg_wb
    io.px_config_reg_wb_en := u_fsm_total.mode.config_reg_wb_en

    io.rsamAccess.address := u_fsm_total.rsam.fsm_addr
    io.rsamAccess.enable := u_fsm_total.rsam.fsm_ena
    io.rsamAccess.isWrite := u_fsm_total.rsam.fsm_wen
    io.rsamAccess.writeData := u_fsm_total.rsam.fsm_wdata
    io.rsamAccess.searchLine := u_fsm_total.rsam.fsm_sl
    io.rsamAccess.searchMode := u_fsm_total.rsam.fsm_sm
    io.rsamAccess.searchEn := u_fsm_total.rsam.fsm_sen

    u_fsm_total.rsam.rdata := io.rsamAccess.readData
    u_fsm_total.rsam.sdata := io.rsamAccess.searchData

    io.ibufAccess0.address := u_fsm_total.ib_0.fsm_addr
    io.ibufAccess0.enable := u_fsm_total.ib_0.fsm_ena
    io.ibufAccess0.isWrite := u_fsm_total.ib_0.fsm_wen
    u_fsm_total.ib_0.rdata := io.ibufAccess0.readData
    io.ibufAccess0.writeData := u_fsm_total.ib_0.fsm_wdata

    io.ibufAccess1.address := u_fsm_total.ib_1.fsm_addr
    io.ibufAccess1.enable := u_fsm_total.ib_1.fsm_ena
    io.ibufAccess1.isWrite := u_fsm_total.ib_1.fsm_wen
    u_fsm_total.ib_1.rdata := io.ibufAccess1.readData
    io.ibufAccess1.writeData := u_fsm_total.ib_1.fsm_wdata

    io.ibufAccess2.address := u_fsm_total.ib_2.fsm_addr
    io.ibufAccess2.enable := u_fsm_total.ib_2.fsm_ena
    io.ibufAccess2.isWrite := u_fsm_total.ib_2.fsm_wen
    u_fsm_total.ib_2.rdata := io.ibufAccess2.readData
    io.ibufAccess2.writeData := u_fsm_total.ib_2.fsm_wdata

    io.ibufAccess3.address := u_fsm_total.ib_3.fsm_addr
    io.ibufAccess3.enable := u_fsm_total.ib_3.fsm_ena
    io.ibufAccess3.isWrite := u_fsm_total.ib_3.fsm_wen
    u_fsm_total.ib_3.rdata := io.ibufAccess3.readData
    io.ibufAccess3.writeData := u_fsm_total.ib_3.fsm_wdata

}

class PixiBbox() extends ExtModule {
    val clk = IO(Input(Clock()))
    val rst_n = IO(Input(Reset()))
    val mode = IO(new Bundle {
        val config_reg       = Input(UInt(64.W))
        val config_reg_wb    = Output(UInt(64.W))
        val config_reg_wb_en = Output(Bool())
    })
    val rsam = IO(new Bundle {
        val fsm_addr = Output(UInt(8.W))
        val fsm_wdata = Output(UInt(64.W))
        val fsm_wen = Output(Bool())
        val fsm_ena = Output(Bool())
        val fsm_sl = Output(UInt(64.W))
        val fsm_sm = Output(UInt(64.W))
        val fsm_sen = Output(Bool())
        val rdata = Input(UInt(64.W))
        val sdata = Input(UInt(256.W))
    })
    val ib_0 = IO(new Bundle {
        val fsm_addr = Output(UInt(7.W))
        val fsm_wdata = Output(UInt(128.W))
        val fsm_wen = Output(Bool())
        val fsm_ena = Output(Bool())
        val rdata = Input(UInt(128.W))
    })
    val ib_1 = IO(new Bundle {
        val fsm_addr = Output(UInt(7.W))
        val fsm_wdata = Output(UInt(128.W))
        val fsm_wen = Output(Bool())
        val fsm_ena = Output(Bool())
        val rdata = Input(UInt(128.W))
    })
    val ib_2 = IO(new Bundle {
        val fsm_addr = Output(UInt(7.W))
        val fsm_wdata = Output(UInt(128.W))
        val fsm_wen = Output(Bool())
        val fsm_ena = Output(Bool())
        val rdata = Input(UInt(128.W))
    })
    val ib_3 = IO(new Bundle {
        val fsm_addr = Output(UInt(7.W))
        val fsm_wdata = Output(UInt(128.W))
        val fsm_wen = Output(Bool())
        val fsm_ena = Output(Bool())
        val rdata = Input(UInt(128.W))
    })
    
  override def desiredName = "fsm_total"
}
