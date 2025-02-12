package scorpio

import chipmunk._
import chipmunk.amba.{AxiLiteToAxi4Bridge, AxiResp}
import chipmunk.component.acorn.AcornDpToAxiLiteBridge
import chipmunk.component.spi._
import chisel3._
import circt.stage._

class ScorpioChip extends RawModule {
  val clock    = IO(Input(Clock()))
  val reset    = IO(Input(AsyncReset()))
  val spi      = IO(Slave(new SpiIO(hasMisoValid = true)))
  val d2d      = IO(Slave(new JayLinkIO))
  val complete = IO(Output(Bool()))

  val clockSys: Clock      = clock
  val resetSys: AsyncReset = AsyncResetSyncDessert.withSpecificClockDomain(clockSys, reset)

  withClockAndReset(clockSys, resetSys) {
    val uAxiNic = Module(new AxiNic)

    val uSpiDebugger = Module(new SpiDebugger(hasMisoValid = true))
    uSpiDebugger.io.sSpi <> spi

    val uSpiDebuggerAcorn2AxiL = Module(new AcornDpToAxiLiteBridge())
    uSpiDebuggerAcorn2AxiL.io.sAcornD <> uSpiDebugger.io.mDbg
    val uSpiDebuggerAxiL2Axi =
      Module(new AxiLiteToAxi4Bridge(dataWidth = 32, addrWidth = 32, idWidth = 1, writeId = 0, readId = 0))
    uSpiDebuggerAxiL2Axi.io.sAxiL <> uSpiDebuggerAcorn2AxiL.io.mAxiL
    uSpiDebuggerAxiL2Axi.io.mAxi4 <> uAxiNic.io.sSpi

    val uNpu = Module(new ScorpioNpu)
    uNpu.io.sAxi <> uAxiNic.io.mNpu
    complete := uNpu.io.complete

    val uJayLinkSlave = Module(new JayLinkSlaveBbox)
    uJayLinkSlave.clock   := clockSys
    uJayLinkSlave.reset   := resetSys
    uJayLinkSlave.txClock := d2d.rx.clock
    uJayLinkSlave.axiData <> uAxiNic.io.sD2dData
    uJayLinkSlave.jaylink <> d2d
    uAxiNic.io.mD2dCtrl.aw.ready    := false.B
    uAxiNic.io.mD2dCtrl.ar.ready    := false.B
    uAxiNic.io.mD2dCtrl.w.ready     := false.B
    uAxiNic.io.mD2dCtrl.r.valid     := false.B
    uAxiNic.io.mD2dCtrl.r.bits.data := 0.U
    uAxiNic.io.mD2dCtrl.r.bits.last := false.B
    uAxiNic.io.mD2dCtrl.r.bits.resp := AxiResp.RESP_OKAY
    uAxiNic.io.mD2dCtrl.r.bits.id.foreach { _ := 0.U }
    uAxiNic.io.mD2dCtrl.b.valid := false.B
    uAxiNic.io.mD2dCtrl.b.bits.id.foreach { _ := 0.U }
    uAxiNic.io.mD2dCtrl.b.bits.resp := AxiResp.RESP_OKAY
  }
}
