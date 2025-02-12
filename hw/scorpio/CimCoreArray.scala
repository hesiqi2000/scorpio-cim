package scorpio

import chipmunk._
import chipmunk.stream._
import chisel3._
import chisel3.util.{Cat}

class CimCoreArray(idataWidth: Int = 512, memWidth: Int = 17, addrWidth: Int = 6, outputWidth: Int = 16) extends Module {
  val io = IO(new Bundle {
    // from soc
    val cimAccessIO = Slave(new CimAccessIO())
    // from input buffer
    val cim_idata   = Input(UInt(idataWidth.W))  
    // from and to NpuBackend
    val cimRCtrlIO  = Input(new CimRCtrlIO())

    val cim_odata       = Output(UInt(16.W))  
    val cim_odata_valid = Output(UInt(1.W))
  })

  val cimWRMng = Module(new CimWRMng())
  cimWRMng.io.cimAccessIO <> io.cimAccessIO
  cimWRMng.io.compCimRCtrlIO <> io.cimRCtrlIO

  val cimCore = Module(new CimCore)
  cimCore.io.writeReq.valid := cimWRMng.io.cimWCtrlIO.cim_wen.asBool
  cimCore.io.writeReq.bits.data := cimWRMng.io.cimWCtrlIO.cim_wdata
  cimCore.io.writeReq.bits.addr := cimWRMng.io.cimWCtrlIO.cim_waddr
  cimCore.io.computeReq.valid := cimWRMng.io.cimRCtrlIO.cim_ren.asBool
  cimCore.io.computeReq.bits.data := io.cim_idata
  cimCore.io.computeReq.bits.exp := cimWRMng.io.cimRCtrlIO.cim_idata_exp
  
  io.cim_odata := cimCore.io.computeResp.bits.data
  io.cim_odata_valid := cimCore.io.computeResp.valid

}
