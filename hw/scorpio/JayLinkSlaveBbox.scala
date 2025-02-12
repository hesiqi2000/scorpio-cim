package scorpio

import chisel3._
import chisel3.experimental.ExtModule
import chipmunk.amba._
import chipmunk._

class JayLinkIO extends Bundle with IsMasterSlave {
  val tx = Output(new Bundle {
    val clock          = Clock()
    val flit_valid     = Bool()
    val flit_bits      = UInt(8.W)
    val creditARW_free = Bool()
    val replayPkgID    = Bool()

  })
  val rx = Input(new Bundle {
    val clock         = Clock()
    val flit_valid    = Bool()
    val flit_bits     = UInt(16.W)
    val creditRB_free = Bool()
    val replayPkgID   = Bool()
  })

  override def isMaster = false
}

class JayLinkSlaveBbox extends ExtModule {
  val clock   = IO(Input(Clock()))
  val reset   = IO(Input(Reset()))
  val txClock = IO(Input(Clock()))

  val jaylink = IO(Slave(new JayLinkIO()))
  val axiData = IO(Master(new Axi4IO(dataWidth = 64, addrWidth = 32, idWidth = 4)))
  // val axiCtrl = IO(Slave(new Axi4IO(dataWidth = 32, addrWidth = 32, idWidth = 5)))
}
