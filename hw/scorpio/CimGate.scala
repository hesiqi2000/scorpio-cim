package scorpio

import chipmunk._
import chipmunk.component.acorn._
import chisel3.util._
import chisel3._

class CimAccessIO(val dataWidth: Int = 64, val addrWidth: Int = 6) extends Bundle with IsMasterSlave {
  val wvalid = Input(Bool())
  val waddr  = Input(UInt(addrWidth.W))
  val wdata  = Input(UInt(dataWidth.W))

  override def isMaster = false
}

class CimGate(bufAddrWidth: Int) extends Module {
  val io = IO(new Bundle {
    val sAcornDp   = Slave(new AcornDpIO(dataWidth = 64, addrWidth = bufAddrWidth + 3))
    val mCimAccess = Master(new CimAccessIO(dataWidth = 64, addrWidth = bufAddrWidth))
  })

  val cmdWrDataReg   = RegInit(0.U(64.W))
  val cmdWrAddrReg   = RegInit(0.U(bufAddrWidth.W))
  val cmdWrEnableReg = RegInit(false.B)

  io.sAcornDp.wr.cmd.ready := true.B
  when(io.sAcornDp.wr.cmd.fire) {
//    cmdWrDataReg := io.sAcornDp.wr.cmd.bits.wdata
    cmdWrDataReg := (io.sAcornDp.wr.cmd.bits.wdata & FillInterleaved(
      8,
      io.sAcornDp.wr.cmd.bits.wmask
    )) | (cmdWrDataReg & (~FillInterleaved(8, io.sAcornDp.wr.cmd.bits.wmask)).asUInt)
    cmdWrAddrReg := io.sAcornDp.wr.cmd.bits.addr.msBits(bufAddrWidth)
  }
//  cmdWrEnableReg := io.sAcornDp.wr.cmd.fire
  cmdWrEnableReg := io.sAcornDp.wr.cmd.fire && io.sAcornDp.wr.cmd.bits.wmask.msBit

  io.mCimAccess.wvalid := cmdWrEnableReg
  io.mCimAccess.waddr  := cmdWrAddrReg
  io.mCimAccess.wdata  := cmdWrDataReg

//  val respWrValidReg = ShiftRegister(io.mCimAccess.wvalid && io.sAcornDp.wr.cmd.bits.wmask.msBit, 2, false.B, true.B)
  val respWrValidReg = ShiftRegister(io.sAcornDp.wr.cmd.fire, 2, false.B, true.B)

  io.sAcornDp.wr.resp.valid       := respWrValidReg
  io.sAcornDp.wr.resp.bits.status := false.B

  io.sAcornDp.rd.cmd.ready := true.B
  io.sAcornDp.rd.resp.bits.status := false.B
  io.sAcornDp.rd.resp.valid := false.B
  io.sAcornDp.rd.resp.bits.rdata := 0.U
}
