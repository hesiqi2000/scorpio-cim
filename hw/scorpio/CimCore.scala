package scorpio

import chipmunk._
import chipmunk.stream._
import chisel3._
import chisel3.experimental.ExtModule

class CimCore(memWidth: Int = 17, idataWidth: Int = 512, addrWidth: Int = 6, outputWidth: Int = 16) extends Module {
  val io = IO(new Bundle {
    val writeReq = Slave(Flow(new Bundle {
      val data = Input(UInt((memWidth).W))
      val addr = Input(UInt(addrWidth.W))
    }))
    val computeReq = Slave(Flow(new Bundle {
      val data      = Input(UInt(idataWidth.W))
      val exp       = Input(UInt(8.W))
    }))
    val computeResp = Master(Flow(new Bundle {
      val data = Output(UInt(outputWidth.W))
    }))
  })

  val uBbox = Module(new CimCoreBbox)
  uBbox.clock     := clock
  uBbox.reset     := reset
  uBbox.cim.wen   := io.writeReq.valid
  uBbox.cim.wdata := io.writeReq.bits.data
  uBbox.cim.waddr := io.writeReq.bits.addr

  uBbox.cim.idata           := io.computeReq.bits.data
  uBbox.cim.ren             := io.computeReq.valid
  uBbox.cim.idata_exp       := io.computeReq.bits.exp

  io.computeResp.bits.data := uBbox.cim.odata
  io.computeResp.valid     := uBbox.cim.odata_valid
}

class CimCoreBbox(memWidth: Int = 17, idataWidth: Int = 512, addrWidth: Int = 6, outputWidth: Int = 16)
    extends ExtModule {
  require(idataWidth == 512, "idataWidth must be 512")
  require(memWidth == 17, "memWidth must be 17")
  require(addrWidth == 6, "addrWidth must be 6")
  require(outputWidth == 16, "outputWidth must be 16")

  val clock = IO(Input(Clock()))
  val reset = IO(Input(Reset()))
  val cim = IO(new Bundle {
    val idata       = Input(UInt(idataWidth.W))
    val idata_exp   = Input(UInt(8.W))
    val wdata       = Input(UInt((memWidth).W))
    val ren         = Input(Bool())
    val wen         = Input(Bool())
    val waddr       = Input(UInt(addrWidth.W))
    val odata       = Output(UInt(outputWidth.W))
    val odata_valid = Output(Bool())
  })

  override def desiredName = "CimMacro"
}
