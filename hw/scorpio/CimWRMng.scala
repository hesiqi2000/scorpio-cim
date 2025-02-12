package scorpio

import chipmunk.Slave
import chisel3._
import chisel3.util.{Cat, ShiftRegister}

// * cim read control io
class CimRCtrlIO extends Bundle {
  val cim_ren       = UInt(1.W)
  val cim_idata_exp = UInt(8.W)
}

// * cim weight write io
class CimWCtrlIO extends Bundle {
  val cim_wen      = Input(UInt(1.W))
  val cim_wdata    = Input(UInt(17.W))
  val cim_waddr    = Input(UInt(6.W)) 
}

class CimWRMng extends Module {
  val io = IO(new Bundle {
    // from soc for write control
    val cimAccessIO = Slave(new CimAccessIO(addrWidth = 6))
    // from npubackend compute ctrl
    val compCimRCtrlIO = Input(new CimRCtrlIO())
    // to CimCore
    val cimWCtrlIO = Flipped(new CimWCtrlIO())
    val cimRCtrlIO = Output(new CimRCtrlIO())
  })

  val soc_cim_wvalid_reg = RegNext(io.cimAccessIO.wvalid, 0.U(1.W))
  val soc_cim_waddr_reg  = RegNext(io.cimAccessIO.waddr, 0.U(6.W))
  val soc_cim_wdata_reg  = RegNext(io.cimAccessIO.wdata, 0.U(64.W))

  io.cimWCtrlIO.cim_wen      := soc_cim_wvalid_reg
  io.cimWCtrlIO.cim_waddr    := soc_cim_waddr_reg
  io.cimWCtrlIO.cim_wdata    := soc_cim_wdata_reg(16, 0)

  val cim_ren       = RegNext(io.compCimRCtrlIO.cim_ren, 0.U(1.W))
  val cim_idata_exp = RegNext(io.compCimRCtrlIO.cim_idata_exp, 0.U(8.W))

  io.cimRCtrlIO.cim_ren         := cim_ren
  io.cimRCtrlIO.cim_idata_exp   := cim_idata_exp

}
