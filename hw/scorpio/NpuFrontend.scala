package scorpio

import chipmunk._
import chipmunk.amba._
import chipmunk.component.acorn._
import chipmunk.stream._
import chisel3._
import chisel3.util._

class NpuFrontend extends Module {
  val io = IO(new Bundle {
    val sAxi = Slave(new Axi4IO(dataWidth = 64, addrWidth = 19, idWidth = 5))

    val config   = Output(new NpuConfigIO())
    val start    = Output(Bool())
    val complete = Input(Bool())

    val px_config_reg_wb = Input(UInt(64.W))
    val px_config_reg_wb_en = Input(Bool())

    val ibufAccess0 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess1 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess2 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess3 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))

    val obufAccess = Master(new BufferAccessIO(dataWidth = 32, addrWidth = 7))
    val cimAccess  = Master(new CimAccessIO(dataWidth = 64, addrWidth = 6))
    val rsamAccess  = Master(new RsamAccessIO(dataWidth = 64, addrWidth = 8))
  })

  val uAxiToAcornDp = Module(
    new Axi4ToAcornDpBridge(dataWidth = io.sAxi.dataWidth, addrWidth = io.sAxi.addrWidth, idWidth = io.sAxi.idWidth)
  )
  uAxiToAcornDp.io.sAxi4 <> io.sAxi

  val uAcornDemux = Module(new NpuAcornDemux)
  uAcornDemux.io.sExt <> uAxiToAcornDp.io.mAcornW

  val uConfigRegBank = Module(new NpuConfigRegBank)
  uConfigRegBank.io.access <> uAcornDemux.io.mConfig
  io.config                  := uConfigRegBank.io.config
  io.start                   := uConfigRegBank.io.start
  io.px_config_reg_wb        <> uConfigRegBank.io.px_config_reg_wb
  io.px_config_reg_wb_en     <> uConfigRegBank.io.px_config_reg_wb_en
  uConfigRegBank.io.complete := io.complete

  val uIbufAccess0 = Module(new InputBufferGate(bufAddrWidth = 7))
  uIbufAccess0.io.sAcornDp <> uAcornDemux.io.mInBuf0
  io.ibufAccess0 <> uIbufAccess0.io.mBufAccess

  val uIbufAccess1 = Module(new InputBufferGate(bufAddrWidth = 7))
  uIbufAccess1.io.sAcornDp <> uAcornDemux.io.mInBuf1
  io.ibufAccess1 <> uIbufAccess1.io.mBufAccess

  val uIbufAccess2 = Module(new InputBufferGate(bufAddrWidth = 7))
  uIbufAccess2.io.sAcornDp <> uAcornDemux.io.mInBuf2
  io.ibufAccess2 <> uIbufAccess2.io.mBufAccess

  val uIbufAccess3 = Module(new InputBufferGate(bufAddrWidth = 7))
  uIbufAccess3.io.sAcornDp <> uAcornDemux.io.mInBuf3
  io.ibufAccess3 <> uIbufAccess3.io.mBufAccess

  val uObufAccess = Module(new OutputBufferGate(bufAddrWidth = 7))
  uObufAccess.io.sAcornDp <> uAcornDemux.io.mOutBuf
  io.obufAccess <> uObufAccess.io.mBufAccess

  val uCimGate = Module(new CimGate(bufAddrWidth = 6))
  uCimGate.io.sAcornDp <> uAcornDemux.io.mCim
  io.cimAccess <> uCimGate.io.mCimAccess

  val uRsamAccess = Module(new RsamBufferGate(bufAddrWidth = 8))
  uRsamAccess.io.sAcornDp <> uAcornDemux.io.mRsm
  io.rsamAccess <> uRsamAccess.io.mBufAccess
}

class NpuAcornDemux extends Module {
  val io = IO(new Bundle {
    val sExt    = Slave(new AcornDpIO(dataWidth = 64, addrWidth = 19))
    val mCim    = Master(new AcornDpIO(dataWidth = 64, addrWidth = 9))
    val mRsm    = Master(new AcornDpIO(dataWidth = 64, addrWidth = 11))
    val mInBuf0 = Master(new AcornDpIO(dataWidth = 64, addrWidth = 11))
    val mInBuf1 = Master(new AcornDpIO(dataWidth = 64, addrWidth = 11))
    val mInBuf2 = Master(new AcornDpIO(dataWidth = 64, addrWidth = 11))
    val mInBuf3 = Master(new AcornDpIO(dataWidth = 64, addrWidth = 11))
    val mOutBuf = Master(new AcornDpIO(dataWidth = 64, addrWidth = 10))
    val mConfig = Master(new AcornDpIO(dataWidth = 64, addrWidth = 10))
  })

  val currentWrittenSlave = RegInit(0.U(3.W))
  when(io.sExt.wr.cmd.fire) {
    currentWrittenSlave := io.sExt.wr.cmd.bits.addr.msBits(3)
  }

  val extWrCmdDemux = StreamDemux(in = io.sExt.wr.cmd, select = io.sExt.wr.cmd.bits.addr.msBits(3), num = 8)

  io.mCim.wr.cmd handshakeFrom extWrCmdDemux(0)
  io.mCim.wr.cmd.bits.addr  := extWrCmdDemux(0).bits.addr.lsBits(io.mCim.addrWidth)
  io.mCim.wr.cmd.bits.wmask := extWrCmdDemux(0).bits.wmask
  io.mCim.wr.cmd.bits.wdata := extWrCmdDemux(0).bits.wdata

  io.mInBuf0.wr.cmd handshakeFrom extWrCmdDemux(1)
  io.mInBuf0.wr.cmd.bits.addr  := extWrCmdDemux(1).bits.addr.lsBits(io.mInBuf0.addrWidth)
  io.mInBuf0.wr.cmd.bits.wmask := extWrCmdDemux(1).bits.wmask
  io.mInBuf0.wr.cmd.bits.wdata := extWrCmdDemux(1).bits.wdata

  io.mInBuf1.wr.cmd handshakeFrom extWrCmdDemux(2)
  io.mInBuf1.wr.cmd.bits.addr  := extWrCmdDemux(2).bits.addr.lsBits(io.mInBuf1.addrWidth)
  io.mInBuf1.wr.cmd.bits.wmask := extWrCmdDemux(2).bits.wmask
  io.mInBuf1.wr.cmd.bits.wdata := extWrCmdDemux(2).bits.wdata

  io.mInBuf2.wr.cmd handshakeFrom extWrCmdDemux(3)
  io.mInBuf2.wr.cmd.bits.addr  := extWrCmdDemux(3).bits.addr.lsBits(io.mInBuf2.addrWidth)
  io.mInBuf2.wr.cmd.bits.wmask := extWrCmdDemux(3).bits.wmask
  io.mInBuf2.wr.cmd.bits.wdata := extWrCmdDemux(3).bits.wdata

  io.mInBuf3.wr.cmd handshakeFrom extWrCmdDemux(4)
  io.mInBuf3.wr.cmd.bits.addr  := extWrCmdDemux(4).bits.addr.lsBits(io.mInBuf3.addrWidth)
  io.mInBuf3.wr.cmd.bits.wmask := extWrCmdDemux(4).bits.wmask
  io.mInBuf3.wr.cmd.bits.wdata := extWrCmdDemux(4).bits.wdata

  io.mOutBuf.wr.cmd handshakeFrom extWrCmdDemux(5)
  io.mOutBuf.wr.cmd.bits.addr  := extWrCmdDemux(5).bits.addr.lsBits(io.mOutBuf.addrWidth)
  io.mOutBuf.wr.cmd.bits.wmask := extWrCmdDemux(5).bits.wmask
  io.mOutBuf.wr.cmd.bits.wdata := extWrCmdDemux(5).bits.wdata

  io.mConfig.wr.cmd handshakeFrom extWrCmdDemux(6)
  io.mConfig.wr.cmd.bits.addr  := extWrCmdDemux(6).bits.addr.lsBits(io.mConfig.addrWidth)
  io.mConfig.wr.cmd.bits.wmask := extWrCmdDemux(6).bits.wmask
  io.mConfig.wr.cmd.bits.wdata := extWrCmdDemux(6).bits.wdata

  io.mRsm.wr.cmd handshakeFrom extWrCmdDemux(7)
  io.mRsm.wr.cmd.bits.addr  := extWrCmdDemux(7).bits.addr.lsBits(io.mRsm.addrWidth)
  io.mRsm.wr.cmd.bits.wmask := extWrCmdDemux(7).bits.wmask
  io.mRsm.wr.cmd.bits.wdata := extWrCmdDemux(7).bits.wdata

  val extResp = StreamMux(
    select = currentWrittenSlave,
    ins = VecInit(io.mCim.wr.resp, io.mInBuf0.wr.resp, io.mInBuf1.wr.resp, io.mInBuf2.wr.resp, io.mInBuf3.wr.resp, io.mOutBuf.wr.resp, io.mConfig.wr.resp, io.mRsm.wr.resp)
  )
  io.sExt.wr.resp << extResp

  val currentReadSlave = RegInit(0.U(3.W))
  when(io.sExt.rd.cmd.fire) {
    currentReadSlave := io.sExt.rd.cmd.bits.addr.msBits(3)
  }

  val extRdCmdDemux = StreamDemux(in = io.sExt.rd.cmd, select = io.sExt.rd.cmd.bits.addr.msBits(3), num = 8)

  io.mCim.rd.cmd handshakeFrom extRdCmdDemux(0)
  io.mCim.rd.cmd.bits.addr := extRdCmdDemux(0).bits.addr.lsBits(io.mCim.addrWidth)

  io.mInBuf0.rd.cmd handshakeFrom extRdCmdDemux(1)
  io.mInBuf0.rd.cmd.bits.addr := extRdCmdDemux(1).bits.addr.lsBits(io.mInBuf0.addrWidth)

  io.mInBuf1.rd.cmd handshakeFrom extRdCmdDemux(2)
  io.mInBuf1.rd.cmd.bits.addr := extRdCmdDemux(2).bits.addr.lsBits(io.mInBuf1.addrWidth)

  io.mInBuf2.rd.cmd handshakeFrom extRdCmdDemux(3)
  io.mInBuf2.rd.cmd.bits.addr := extRdCmdDemux(3).bits.addr.lsBits(io.mInBuf2.addrWidth)

  io.mInBuf3.rd.cmd handshakeFrom extRdCmdDemux(4)
  io.mInBuf3.rd.cmd.bits.addr := extRdCmdDemux(4).bits.addr.lsBits(io.mInBuf3.addrWidth)

  io.mOutBuf.rd.cmd handshakeFrom extRdCmdDemux(5)
  io.mOutBuf.rd.cmd.bits.addr := extRdCmdDemux(5).bits.addr.lsBits(io.mOutBuf.addrWidth)

  io.mConfig.rd.cmd handshakeFrom extRdCmdDemux(6)
  io.mConfig.rd.cmd.bits.addr := extRdCmdDemux(6).bits.addr.lsBits(io.mConfig.addrWidth)

  io.mRsm.rd.cmd handshakeFrom extRdCmdDemux(7)
  io.mRsm.rd.cmd.bits.addr := extRdCmdDemux(7).bits.addr.lsBits(io.mRsm.addrWidth)

  val extRdResp = StreamMux(
    select = currentReadSlave,
    ins = VecInit(io.mCim.rd.resp, io.mInBuf0.rd.resp, io.mInBuf1.rd.resp, io.mInBuf2.rd.resp, io.mInBuf3.rd.resp, io.mOutBuf.rd.resp, io.mConfig.rd.resp, io.mRsm.rd.resp)
  )
  io.sExt.rd.resp << extRdResp
}
