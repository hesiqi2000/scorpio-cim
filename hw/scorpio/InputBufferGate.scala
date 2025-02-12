package scorpio

import chipmunk._
import chipmunk.component.acorn._
import chisel3.util._
import chisel3._

class InputBufferGate(bufAddrWidth: Int) extends Module {
  val io = IO(new Bundle {
    val sAcornDp   = Slave(new AcornDpIO(dataWidth = 64, addrWidth = bufAddrWidth + 4))
    val mBufAccess = Master(new BufferAccessIO(dataWidth = 128, addrWidth = bufAddrWidth))
  })

  val uDp2Sp = Module(new AcornDpToSpBridge(io.sAcornDp.dataWidth, io.sAcornDp.addrWidth))
  uDp2Sp.io.sAcornD <> io.sAcornDp
  val sAcornSp = uDp2Sp.io.mAcornS

  val cmdWrDataMsbReg = RegInit(0.U(64.W))
  val cmdWrDataLsbReg = RegInit(0.U(64.W))
  val cmdAddrReg      = RegInit(0.U(bufAddrWidth.W))
  val cmdEnableReg    = RegInit(false.B)
  val cmdIsWriteReg   = RegInit(false.B)
  val cmdBankReg      = RegInit(0.U(1.W))

  sAcornSp.cmd.ready := true.B
  when(sAcornSp.cmd.fire) {
    when(sAcornSp.cmd.bits.addr(3)) {
      cmdWrDataMsbReg := (sAcornSp.cmd.bits.wdata & FillInterleaved(
        8,
        sAcornSp.cmd.bits.wmask
      )) | (cmdWrDataMsbReg & (~FillInterleaved(8, sAcornSp.cmd.bits.wmask)).asUInt)
    }.otherwise {
      cmdWrDataLsbReg := (sAcornSp.cmd.bits.wdata & FillInterleaved(
        8,
        sAcornSp.cmd.bits.wmask
      )) | (cmdWrDataLsbReg & (~FillInterleaved(8, sAcornSp.cmd.bits.wmask)).asUInt)
    }
    cmdAddrReg    := sAcornSp.cmd.bits.addr.msBits(bufAddrWidth)
    cmdBankReg    := sAcornSp.cmd.bits.addr(3)
    cmdIsWriteReg := !sAcornSp.cmd.bits.read
  }
//  cmdEnableReg := sAcornSp.cmd.fire && sAcornSp.cmd.bits.wmask.msBit && sAcornSp.cmd.bits.addr.lsBits(4) === 0xC.U
  cmdEnableReg := Mux(
    sAcornSp.cmd.bits.read,
    sAcornSp.cmd.fire,
    sAcornSp.cmd.fire && sAcornSp.cmd.bits.wmask.msBit && sAcornSp.cmd.bits.addr(3)
  )
  io.mBufAccess.enable    := cmdEnableReg
  io.mBufAccess.address   := cmdAddrReg
  io.mBufAccess.writeData := Cat(cmdWrDataMsbReg, cmdWrDataLsbReg)
  io.mBufAccess.isWrite   := cmdIsWriteReg

  val respValid    = RegNext(sAcornSp.cmd.fire, false.B)
  val respBank     = RegEnable(cmdBankReg, 0.U, io.mBufAccess.enable && !io.mBufAccess.isWrite)
  val respDataBank = Mux(respBank === 0.U, io.mBufAccess.readData(63, 0), io.mBufAccess.readData(127, 64))

  val respValidReg = RegNext(respValid, false.B)
//  val respDataReg  = RegEnable(respDataBank, 0.U, respValid)
  val respDataReg = respDataBank

  sAcornSp.resp.valid       := respValidReg
  sAcornSp.resp.bits.rdata  := respDataReg
  sAcornSp.resp.bits.status := false.B
}
