package scorpio

import chipmunk._
import chipmunk.amba._
import chisel3._
import chisel3.util._
import chisel3.experimental.ExtModule
import chisel3.experimental.dataview.DataViewable

class AxiNic extends Module {
  val io = IO(new Bundle {
    val sSpi     = Slave(new Axi4IO(dataWidth = 32, addrWidth = 32, idWidth = 1))
    val mD2dCtrl = Master(new Axi4IO(dataWidth = 64, addrWidth = 32, idWidth = 5))
    val sD2dData = Slave(new Axi4IO(dataWidth = 64, addrWidth = 32, idWidth = 4))
    val mNpu     = Master(new Axi4IO(dataWidth = 64, addrWidth = 32, idWidth = 5))
  })

  val uBbox = Module(new AxiNicBbox)
  uBbox.clock  := clock
  uBbox.resetn := !reset.asBool
  io.sSpi <> uBbox.sSpi.viewAs[Axi4IO]
  io.mD2dCtrl <> uBbox.mD2dCtrl.viewAs[Axi4IO]
  io.sD2dData <> uBbox.sD2dData.viewAs[Axi4IO]
  io.mNpu <> uBbox.mNpu.viewAs[Axi4IO]
}

class AxiNicBbox extends ExtModule {
  val clock  = IO(Input(Clock())).suggestName("clk_axiclk")
  val resetn = IO(Input(Reset())).suggestName("clk_axiresetn")
  val sSpi = FlatIO(Slave(new Axi4IORtlConnector(dataWidth = 32, addrWidth = 32, idWidth = 1, postfix = Some("s_spi"))))
  val mD2dCtrl = FlatIO(
    Master(new Axi4IORtlConnector(dataWidth = 64, addrWidth = 32, idWidth = 5, postfix = Some("m_d2ds_ctrl")))
  )
  val sD2dData = FlatIO(
    Slave(new Axi4IORtlConnector(dataWidth = 64, addrWidth = 32, idWidth = 4, postfix = Some("s_d2ds_data")))
  )
  val mNpu = FlatIO(
    Master(new Axi4IORtlConnector(dataWidth = 64, addrWidth = 32, idWidth = 5, postfix = Some("m_npu")))
  )

  override def desiredName = "nic400_1"
}
