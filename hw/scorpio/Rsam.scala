package scorpio

import chipmunk._
import chipmunk.component.acorn.AcornSpIO
import chisel3._
import chisel3.ltl.Delay
import chisel3.util._

class RsamWrapper64bx256d extends BlackBox with HasBlackBoxResource {
  val io = IO(new Bundle {
    val clock = Input(Clock())

    val rw = new Bundle {
      val enable  = Input(Bool())
      val addr    = Input(UInt(8.W))
      val write   = Input(Bool())
      val dataIn  = Input(UInt(64.W))
      val dataOut = Output(UInt(64.W))
    }

    val search = new Bundle {
      val sen     = Input(Bool())
      val sm      = Input(UInt(64.W))
      val sl      = Input(UInt(64.W))
      val sdataOut = Output(UInt(256.W))
    }
  })
  addResource("/RsamWrapper64bx256d.sv")
}

class Rsam(val memNum: Int, val memAddrWidth: Int = 8, val memDataWidth: Int = 64) extends Module {
  val memIndexWidth: Int = log2Ceil(memNum)

  val io = IO(new Bundle {
    val ext    = Slave(new RsamAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth + memIndexWidth))
    val int    = Slave(new RsamAccessIO(dataWidth = memNum * memDataWidth, addrWidth = memAddrWidth))
  })

  val extRsamPorts = Wire(Vec(memNum, new RsamAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth)))
  val extRsamPortsReadDataSelect = RegNext(io.ext.address.lsBits(memIndexWidth), 0.U)
  for (idx <- 0 until memNum) {
    extRsamPorts(idx).address   := io.ext.address.msBits(memAddrWidth)
    extRsamPorts(idx).enable    := io.ext.enable && io.ext.address.lsBits(memIndexWidth) === idx.U
    extRsamPorts(idx).isWrite   := io.ext.isWrite
    extRsamPorts(idx).writeData := io.ext.writeData
    extRsamPorts(idx).searchLine := 0.U
    extRsamPorts(idx).searchMode := 0.U
    extRsamPorts(idx).searchEn   := false.B
    io.ext.readData             := extRsamPorts(extRsamPortsReadDataSelect).readData
  }

  io.ext.searchData := 0.U

  val intRsamPorts = Wire(Vec(memNum, new RsamAccessIO(dataWidth = memDataWidth, addrWidth = memAddrWidth)))
  val intRsamPortsReadData = for (idx <- 0 until memNum) yield {
    intRsamPorts(idx).address   := io.int.address
    intRsamPorts(idx).enable    := io.int.enable
    intRsamPorts(idx).isWrite   := io.int.isWrite
    intRsamPorts(idx).writeData := io.int.writeData(memDataWidth * (idx + 1) - 1, memDataWidth * idx)
    intRsamPorts(idx).searchLine := io.int.searchLine(memDataWidth * (idx + 1) - 1, memDataWidth * idx)
    intRsamPorts(idx).searchMode := io.int.searchMode(memDataWidth * (idx + 1) - 1, memDataWidth * idx)
    intRsamPorts(idx).searchEn   := io.int.searchEn
    intRsamPorts(idx).readData
  }
  io.int.readData := VecInit(intRsamPortsReadData).asUInt

  val intRsamPortsCompareData = for (idx <- 0 until memNum) yield {
    intRsamPorts(idx).searchData
  }
  io.int.searchData := VecInit(intRsamPortsCompareData).asUInt

  for (idx <- 0 until memNum) {
    val mem = Module(new RsamWrapper64bx256d)
    mem.io.clock := clock

    mem.io.rw.enable := intRsamPorts(idx).enable || extRsamPorts(idx).enable
    mem.io.rw.addr   := Mux(intRsamPorts(idx).enable, intRsamPorts(idx).address, extRsamPorts(idx).address)
    mem.io.rw.write  := Mux(intRsamPorts(idx).enable, intRsamPorts(idx).isWrite, extRsamPorts(idx).isWrite)
    mem.io.rw.dataIn := Mux(intRsamPorts(idx).enable, intRsamPorts(idx).writeData, extRsamPorts(idx).writeData)
    mem.io.search.sen := intRsamPorts(idx).searchEn
    mem.io.search.sm  := intRsamPorts(idx).searchMode
    mem.io.search.sl  := intRsamPorts(idx).searchLine
    extRsamPorts(idx).readData := mem.io.rw.dataOut
    extRsamPorts(idx).searchData := 0.U
    intRsamPorts(idx).readData := mem.io.rw.dataOut
    intRsamPorts(idx).searchData := mem.io.search.sdataOut
  }
}
