package scorpio

import chipmunk._
import chipmunk.component.acorn.AcornDpIO
import chipmunk.regbank._
import chisel3._
import chisel3.util._

class NpuConfigIO extends Bundle {
  val execIter          = UInt(32.W)

  val ibufBaseAddr  = UInt(7.W)
  val ibufLoop0Iter = UInt(7.W)
  val ibufLoop0Step = UInt(7.W)
  val ibufLoop1Iter = UInt(7.W)
  val ibufLoop1Step = UInt(7.W)

  val obufBaseAddr  = UInt(7.W)
  val obufLoop0Iter = UInt(7.W)
  val obufLoop0Step = UInt(7.W)
  val obufLoop1Iter = UInt(7.W)
  val obufLoop1Step = UInt(7.W)

  val cimBitCount       = UInt(8.W)
  val cimStationCount   = UInt(8.W)
  val cimAlignedExp     = UInt(8.W)
  
  val rsamConfig    = UInt(64.W)

}

class NpuConfigRegBank extends Module {
  val io = IO(new Bundle {
    val access   = Slave(new AcornDpIO(dataWidth = 64, addrWidth = 8))
    val config   = Output(new NpuConfigIO())
    val start    = Output(Bool())
    val complete = Input(Bool())
    val px_config_reg_wb = Input(UInt(64.W))
    val px_config_reg_wb_en = Input(Bool())
  })

  val uConfigRegBank = Module(
    new RegBank(
      addrWidth = 8,
      dataWidth = 64,
      regs = Seq(
        RegElementConfig(
          name = "VERSION",
          addr = 0x0,
          fields = Seq(
            RegFieldConfig(
              "ID",
              baseOffset = 0,
              bitCount = 16,
              initValue = 0xf0.U(16.W),
              accessType = RegFieldAccessType.ReadOnly
            ),
            RegFieldConfig("TEST", baseOffset = 16, bitCount = 16, initValue = 0xef.U(16.W))
          )
        ),
        RegElementConfig(
          name = "GLOB_CTRL_0",
          addr = 0x8,
          fields = Seq(RegFieldConfig("EXEC_ITER", baseOffset = 0, bitCount = 32))
        ),
        RegElementConfig(
          name = "GLOB_CTRL_1",
          addr = 0x10,
          fields = Seq(
            RegFieldConfig("START", baseOffset = 0, bitCount = 1),
            RegFieldConfig(
              "COMPLETE",
              baseOffset = 1,
              bitCount = 1,
              accessType = RegFieldAccessType.ReadOnly,
              backdoorUpdate = true
            )
          )
        ),
        RegElementConfig(
          name = "IBUF_ADDR_0",
          addr = 0x18,
          fields = Seq(
            RegFieldConfig("BASE_ADDR", baseOffset = 0, bitCount = 7),
            RegFieldConfig("LOOP0_ITER", baseOffset = 7, bitCount = 7),
            RegFieldConfig("LOOP0_STEP", baseOffset = 14, bitCount = 7)
          )
        ),
        RegElementConfig(
          name = "IBUF_ADDR_1",
          addr = 0x20,
          fields = Seq(
            RegFieldConfig("LOOP1_ITER", baseOffset = 0, bitCount = 7),
            RegFieldConfig("LOOP1_STEP", baseOffset = 7, bitCount = 7)
          )
        ),
        RegElementConfig(
          name = "OBUF_ADDR_0",
          addr = 0x28,
          fields = Seq(
            RegFieldConfig("BASE_ADDR", baseOffset = 0, bitCount = 7),
            RegFieldConfig("LOOP0_ITER", baseOffset = 7, bitCount = 7),
            RegFieldConfig("LOOP0_STEP", baseOffset = 14, bitCount = 7)
          )
        ),
        RegElementConfig(
          name = "OBUF_ADDR_1",
          addr = 0x30,
          fields = Seq(
            RegFieldConfig("LOOP1_ITER", baseOffset = 0, bitCount = 7),
            RegFieldConfig("LOOP1_STEP", baseOffset = 7, bitCount = 7)
          )
        ),
        RegElementConfig(
          name = "CIMC_MODE",
          addr = 0x38,
          fields = Seq(
            RegFieldConfig("BIT_CNT", baseOffset = 0, bitCount = 8),
            RegFieldConfig("STATION_CNT", baseOffset = 8, bitCount = 8),
            RegFieldConfig("ALIGNED_EXP", baseOffset = 16, bitCount = 8)
          )
        ),
        RegElementConfig(
          name = "RSAM_MODE",
          addr = 0x40,
          fields = Seq(
            RegFieldConfig("CONFIG", baseOffset = 0, bitCount = 64, backdoorUpdate = true),
          )
        )
      )
    )
  )

  io.access <> uConfigRegBank.io.access

  io.config.execIter := uConfigRegBank.io.fields("GLOB_CTRL_0_EXEC_ITER").value

  io.config.cimBitCount     := uConfigRegBank.io.fields("CIMC_MODE_BIT_CNT").value
  io.config.cimStationCount := uConfigRegBank.io.fields("CIMC_MODE_STATION_CNT").value
  io.config.cimAlignedExp   := uConfigRegBank.io.fields("CIMC_MODE_ALIGNED_EXP").value

  io.config.ibufBaseAddr  := uConfigRegBank.io.fields("IBUF_ADDR_0_BASE_ADDR").value
  io.config.ibufLoop0Iter := uConfigRegBank.io.fields("IBUF_ADDR_0_LOOP0_ITER").value
  io.config.ibufLoop0Step := uConfigRegBank.io.fields("IBUF_ADDR_0_LOOP0_STEP").value
  io.config.ibufLoop1Iter := uConfigRegBank.io.fields("IBUF_ADDR_1_LOOP1_ITER").value
  io.config.ibufLoop1Step := uConfigRegBank.io.fields("IBUF_ADDR_1_LOOP1_STEP").value

  io.config.obufBaseAddr  := uConfigRegBank.io.fields("OBUF_ADDR_0_BASE_ADDR").value
  io.config.obufLoop0Iter := uConfigRegBank.io.fields("OBUF_ADDR_0_LOOP0_ITER").value
  io.config.obufLoop0Step := uConfigRegBank.io.fields("OBUF_ADDR_0_LOOP0_STEP").value
  io.config.obufLoop1Iter := uConfigRegBank.io.fields("OBUF_ADDR_1_LOOP1_ITER").value
  io.config.obufLoop1Step := uConfigRegBank.io.fields("OBUF_ADDR_1_LOOP1_STEP").value

  io.config.rsamConfig := uConfigRegBank.io.fields("RSAM_MODE_CONFIG").value

  io.start := RegNext(uConfigRegBank.io.fields("GLOB_CTRL_1_START").isBeingWritten, false.B)

  uConfigRegBank.io.fields("GLOB_CTRL_1_COMPLETE").backdoorUpdate.get.bits  := io.complete.asUInt
  uConfigRegBank.io.fields("GLOB_CTRL_1_COMPLETE").backdoorUpdate.get.valid := true.B

  uConfigRegBank.io.fields("RSAM_MODE_CONFIG").backdoorUpdate.get.bits  := io.px_config_reg_wb
  uConfigRegBank.io.fields("RSAM_MODE_CONFIG").backdoorUpdate.get.valid := io.px_config_reg_wb_en
}

