package scorpio

import chipmunk._
import chipmunk.component.acorn.AcornSpIO
import chisel3._
import chisel3.ltl.Delay
import chisel3.util._

class BufferAccessIO(dataWidth: Int, addrWidth: Int) extends Bundle with IsMasterSlave {
  val address   = Input(UInt(addrWidth.W))
  val enable    = Input(Bool())
  val isWrite   = Input(Bool())
  val readData  = Output(UInt(dataWidth.W))
  val writeData = Input(UInt(dataWidth.W))

  override def isMaster = false
}

class BufferSramConfigIO(dataWidth: Int) extends Bundle with IsMasterSlave {
  val wtsel = Input(UInt(2.W))
  val rtsel = Input(UInt(2.W))
  val bweb  = Input(UInt(dataWidth.W))

  override def isMaster = false
}

class SramWrapperSp128bx128d extends BlackBox with HasBlackBoxResource {
  val io = IO(new Bundle {
    val clock = Input(Clock())

    val rw = new Bundle {
      val enable  = Input(Bool())
      val addr    = Input(UInt(7.W))
      val write   = Input(Bool())
      val dataIn  = Input(UInt(128.W))
      val dataOut = Output(UInt(128.W))
    }

    val config = Slave(new BufferSramConfigIO(dataWidth = 128))
  })
  addResource("/SramWrapperSp128bx128d.sv")
}

class SramWrapperSp16bx128d extends BlackBox with HasBlackBoxResource {
  val io = IO(new Bundle {
    val clock = Input(Clock())

    val rw = new Bundle {
      val enable  = Input(Bool())
      val addr    = Input(UInt(7.W))
      val write   = Input(Bool())
      val dataIn  = Input(UInt(16.W))
      val dataOut = Output(UInt(16.W))
    }

    val config = Slave(new BufferSramConfigIO(dataWidth = 16))
  })
  addResource("/SramWrapperSp16bx128d.sv")
}


class InputBuffer(val memNum: Int, val memAddrWidth: Int = 7, val memDataWidth: Int = 128) extends Module {
  val memIndexWidth: Int = log2Ceil(memNum)

  val io = IO(new Bundle {
    val ext    = Slave(new BufferAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth + memIndexWidth))
    val int    = Slave(new BufferAccessIO(dataWidth = memNum * memDataWidth, addrWidth = memAddrWidth))
  })

  val extSramPorts = Wire(Vec(memNum, new BufferAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth)))
  val extSramPortsReadDataSelect = RegNext(io.ext.address.lsBits(memIndexWidth), 0.U)
  for (idx <- 0 until memNum) {
    extSramPorts(idx).address   := io.ext.address.msBits(memAddrWidth)
    extSramPorts(idx).enable    := io.ext.enable && io.ext.address.lsBits(memIndexWidth) === idx.U
    extSramPorts(idx).isWrite   := io.ext.isWrite
    extSramPorts(idx).writeData := io.ext.writeData
    io.ext.readData             := extSramPorts(extSramPortsReadDataSelect).readData
  }

  val intSramPorts = Wire(Vec(memNum, new BufferAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth)))
  val intSramPortReadData = for (idx <- 0 until memNum) yield {
    intSramPorts(idx).address   := io.int.address
    intSramPorts(idx).enable    := io.int.enable
    intSramPorts(idx).isWrite   := io.int.isWrite
    intSramPorts(idx).writeData := io.int.writeData(memDataWidth * (idx + 1) - 1, memDataWidth * idx)
    intSramPorts(idx).readData
  }
  io.int.readData := VecInit(intSramPortReadData).asUInt

  for (idx <- 0 until memNum) {
    val mem = Module(new SramWrapperSp128bx128d)
    mem.io.clock := clock

    mem.io.rw.enable := intSramPorts(idx).enable || extSramPorts(idx).enable
    mem.io.rw.addr   := Mux(intSramPorts(idx).enable, intSramPorts(idx).address, extSramPorts(idx).address)
    mem.io.rw.write  := Mux(intSramPorts(idx).enable, intSramPorts(idx).isWrite, extSramPorts(idx).isWrite)
    mem.io.rw.dataIn := Mux(intSramPorts(idx).enable, intSramPorts(idx).writeData, extSramPorts(idx).writeData)
    extSramPorts(idx).readData := mem.io.rw.dataOut
    intSramPorts(idx).readData := mem.io.rw.dataOut

    mem.io.config.wtsel := 0.U
    mem.io.config.rtsel := 1.U
    mem.io.config.bweb  := 0.U

  }
}

class OutputBuffer(val memNum: Int, val memAddrWidth: Int = 7, val memDataWidth: Int = 16) extends Module {
  val memIndexWidth: Int = log2Ceil(memNum)

  val io = IO(new Bundle {
    val ext    = Slave(new BufferAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth + memIndexWidth))
    val int    = Slave(new BufferAccessIO(dataWidth = memNum * memDataWidth, addrWidth = memAddrWidth))
  })

  val extSramPorts = Wire(Vec(memNum, new BufferAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth)))
  val extSramPortsReadDataSelect = RegNext(io.ext.address.lsBits(memIndexWidth), 0.U)
  for (idx <- 0 until memNum) {
    extSramPorts(idx).address   := io.ext.address.msBits(memAddrWidth)
    extSramPorts(idx).enable    := io.ext.enable && io.ext.address.lsBits(memIndexWidth) === idx.U
    extSramPorts(idx).isWrite   := io.ext.isWrite
    extSramPorts(idx).writeData := io.ext.writeData
    io.ext.readData             := extSramPorts(extSramPortsReadDataSelect).readData
  }

  val intSramPorts = Wire(Vec(memNum, new BufferAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth)))
  val intSramPortReadData = for (idx <- 0 until memNum) yield {
    intSramPorts(idx).address   := io.int.address
    intSramPorts(idx).enable    := io.int.enable
    intSramPorts(idx).isWrite   := io.int.isWrite
    intSramPorts(idx).writeData := io.int.writeData(memDataWidth * (idx + 1) - 1, memDataWidth * idx)
    intSramPorts(idx).readData
  }
  io.int.readData := VecInit(intSramPortReadData).asUInt

  for (idx <- 0 until memNum) {
    val mem = Module(new SramWrapperSp16bx128d)
    mem.io.clock := clock

    mem.io.rw.enable := intSramPorts(idx).enable || extSramPorts(idx).enable
    mem.io.rw.addr   := Mux(intSramPorts(idx).enable, intSramPorts(idx).address, extSramPorts(idx).address)
    mem.io.rw.write  := Mux(intSramPorts(idx).enable, intSramPorts(idx).isWrite, extSramPorts(idx).isWrite)
    mem.io.rw.dataIn := Mux(intSramPorts(idx).enable, intSramPorts(idx).writeData, extSramPorts(idx).writeData)
    extSramPorts(idx).readData := mem.io.rw.dataOut
    intSramPorts(idx).readData := mem.io.rw.dataOut

    mem.io.config.wtsel := 0.U
    mem.io.config.rtsel := 1.U
    mem.io.config.bweb  := 0.U
  }
}
