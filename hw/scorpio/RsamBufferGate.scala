package scorpio

import chipmunk._
import chipmunk.component.acorn._
import chisel3.util._
import chisel3._
import chisel3.util.{Cat}


class RsamAccessIO(dataWidth: Int, addrWidth: Int) extends Bundle with IsMasterSlave {
  val address   = Input(UInt(addrWidth.W))
  val enable    = Input(Bool())
  val isWrite   = Input(Bool())
  val readData  = Output(UInt(dataWidth.W))
  val writeData = Input(UInt(dataWidth.W))

  val searchLine = Input(UInt(dataWidth.W))
  val searchMode = Input(UInt(dataWidth.W))
  val searchEn   = Input(Bool())
  val searchData = Output(UInt((1<<addrWidth).W))
  override def isMaster = false
}

class RsamBufferGate(bufAddrWidth: Int) extends Module {
  val io = IO(new Bundle {
    val sAcornDp   = Slave(new AcornDpIO(dataWidth = 64, addrWidth = bufAddrWidth + 3)) 
    val mBufAccess = Master(new RsamAccessIO(dataWidth = 64, addrWidth = bufAddrWidth))
  })
  
  val uDp2Sp = Module(new AcornDpToSpBridge(io.sAcornDp.dataWidth, io.sAcornDp.addrWidth))
  uDp2Sp.io.sAcornD <> io.sAcornDp
  val sAcornSp = uDp2Sp.io.mAcornS

  val cmdWrData = RegInit(0.U(64.W))
  val cmdAddrReg      = RegInit(0.U(bufAddrWidth.W))
  val cmdEnableReg    = RegInit(false.B)
  val cmdIsWriteReg   = RegInit(false.B)

  // no need bank here, select in buffer.scala buffer define

  // val isRead     = sAcornSp.cmd.bits.read
  // val isWrite    = !isRead

  val wmask64    = FillInterleaved(8, sAcornSp.cmd.bits.wmask).asUInt 
  val wdata64    = sAcornSp.cmd.bits.wdata(63, 0)

  sAcornSp.cmd.ready := true.B
  when(sAcornSp.cmd.fire) {
    cmdWrData := (wdata64 & wmask64) | (cmdWrData & ~wmask64)
    cmdAddrReg    := sAcornSp.cmd.bits.addr.msBits(bufAddrWidth)
    cmdIsWriteReg := !sAcornSp.cmd.bits.read
  }

  // cmdEnableReg := sAcornSp.cmd.fire
  cmdEnableReg := Mux(
    sAcornSp.cmd.bits.read,
    sAcornSp.cmd.fire,
    sAcornSp.cmd.fire && sAcornSp.cmd.bits.wmask.msBit
  )
  io.mBufAccess.enable    := cmdEnableReg
  io.mBufAccess.address   := cmdAddrReg
  io.mBufAccess.writeData := cmdWrData
  io.mBufAccess.isWrite   := cmdIsWriteReg

  io.mBufAccess.searchLine := 0.U
  io.mBufAccess.searchMode := 0.U
  io.mBufAccess.searchEn   := false.B

  // read response
  val respValid    = RegNext(sAcornSp.cmd.fire, false.B)
  val respValidReg = RegNext(respValid, init=false.B)
  val respDataReg  = io.mBufAccess.readData
  
  // respond to AcornSP
  sAcornSp.resp.valid       := respValidReg
  sAcornSp.resp.bits.rdata  := respDataReg
  sAcornSp.resp.bits.status := false.B
}