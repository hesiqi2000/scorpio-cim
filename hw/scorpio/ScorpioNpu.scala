package scorpio

import chipmunk._
import chipmunk.amba._
import chipmunk.component.acorn.{AcornDpIO, Axi4ToAcornDpBridge}
import chipmunk.regbank._
import chisel3._

class ScorpioNpu extends Module {
  val io = IO(new Bundle {
    val sAxi     = Slave(new Axi4IO(dataWidth = 64, addrWidth = 19, idWidth = 5))
    val complete = Output(Bool())
  })

  val uFrontend = Module(new NpuFrontend)
  val uBackend  = Module(new NpuBackend)
  val uInBuf0    = Module(new InputBuffer(1))
  val uInBuf1    = Module(new InputBuffer(1))
  val uInBuf2    = Module(new InputBuffer(1))
  val uInBuf3    = Module(new InputBuffer(1))
  val uOutBuf   = Module(new OutputBuffer(1))
  val uRsam     = Module(new Rsam(1))

  uFrontend.io.sAxi <> io.sAxi
  uBackend.io.config <> uFrontend.io.config
  uBackend.io.start     := uFrontend.io.start
  uFrontend.io.complete := uBackend.io.complete
  uFrontend.io.px_config_reg_wb    := uBackend.io.px_config_reg_wb
  uFrontend.io.px_config_reg_wb_en := uBackend.io.px_config_reg_wb_en

  uBackend.io.ibufAccess0 <> uInBuf0.io.int
  uBackend.io.ibufAccess1 <> uInBuf1.io.int
  uBackend.io.ibufAccess2 <> uInBuf2.io.int
  uBackend.io.ibufAccess3 <> uInBuf3.io.int
  uBackend.io.obufAccess <> uOutBuf.io.int

  uFrontend.io.ibufAccess0 <> uInBuf0.io.ext
  uFrontend.io.ibufAccess1 <> uInBuf1.io.ext
  uFrontend.io.ibufAccess2 <> uInBuf2.io.ext
  uFrontend.io.ibufAccess3 <> uInBuf3.io.ext
  uFrontend.io.obufAccess <> uOutBuf.io.ext
  uFrontend.io.cimAccess <> uBackend.io.cimAccessIO

  uFrontend.io.rsamAccess <> uRsam.io.ext
  uBackend.io.rsamAccess <> uRsam.io.int

  io.complete := uBackend.io.complete
}
