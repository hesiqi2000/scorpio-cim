package scorpio

import chipmunk._
import chipmunk.component.acorn.AcornSpIO
import chisel3._
import chisel3.ltl.Delay
import chisel3.util._

class NpuBackend extends Module {
  val io = IO(new Bundle {
    val config   = Input(new NpuConfigIO())
    val start    = Input(Bool())
    val complete = Output(Bool())

    val px_config_reg_wb = Output(UInt(64.W))
    val px_config_reg_wb_en = Output(Bool())

    val cimAccessIO = Slave(new CimAccessIO())
    val ibufAccess0 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess1 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess2 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))
    val ibufAccess3 = Master(new BufferAccessIO(dataWidth = 128, addrWidth = 7))

    val obufAccess = Master(new BufferAccessIO(dataWidth = 16, addrWidth = 7))
    val rsamAccess = Master(new RsamAccessIO(dataWidth = 64, addrWidth = 8))
  })

  val pixiBackend = Module(new PixiBackend())
  pixiBackend.io.config := io.config
  io.px_config_reg_wb := pixiBackend.io.px_config_reg_wb
  io.px_config_reg_wb_en := pixiBackend.io.px_config_reg_wb_en

  pixiBackend.io.ibufAccess0.readData := io.ibufAccess0.readData
  pixiBackend.io.ibufAccess1.readData := io.ibufAccess1.readData
  pixiBackend.io.ibufAccess2.readData := io.ibufAccess2.readData
  pixiBackend.io.ibufAccess3.readData := io.ibufAccess3.readData

  val cimCoreArray = Module(new CimCoreArray())
  cimCoreArray.io.cim_idata := Cat(io.ibufAccess3.readData, io.ibufAccess2.readData, io.ibufAccess1.readData, io.ibufAccess0.readData)
  cimCoreArray.io.cimAccessIO <> io.cimAccessIO

  // State Definitions
  val s_idle :: s_cim_cal :: Nil = Enum(2)
  val state = RegInit(s_idle)

  // Counter for looping
  val ibufExecIter = RegInit(0.U(32.W))
  val ibufLoop1Iter = RegInit(0.U(7.W))
  val ibufLoop0Iter = RegInit(0.U(7.W))
  val ibufIdx = RegInit(0.U(8.W))

  val obufExecIter = RegInit(0.U(32.W))
  val obufLoop1Iter = RegInit(0.U(7.W))
  val obufLoop0Iter = RegInit(0.U(7.W))

  // Registers for output signal control
  val ibuf_ren = RegInit(false.B)
  val cim_ren = RegInit(false.B)
  val obuf_wen = RegInit(false.B)
  val ibufAddr = RegInit(0.U(7.W))
  val obufAddr = RegInit(0.U(7.W))

  io.complete := state === s_idle

  switch(state) {
    is(s_idle) {
      when(io.start) {
        state := s_cim_cal

        ibufExecIter := 0.U
        ibufLoop1Iter := 0.U
        ibufLoop0Iter := 0.U
        ibufIdx := 0.U
        obufExecIter := 0.U
        obufLoop1Iter := 0.U
        obufLoop0Iter := 0.U
        ibufAddr := io.config.ibufBaseAddr
        obufAddr := io.config.obufBaseAddr
      }
    }
    is(s_cim_cal) {
        when (ibufExecIter < io.config.execIter) {
        
            when(ibufIdx === io.config.cimBitCount + io.config.cimStationCount){
                ibufIdx := 0.U
            } .otherwise{
                ibufIdx := ibufIdx + 1.U
            }
            when(ibufLoop0Iter === io.config.ibufLoop0Iter && ibufIdx === io.config.cimBitCount + io.config.cimStationCount){
                ibufLoop0Iter := 0.U
            } .elsewhen(ibufIdx === io.config.cimBitCount + io.config.cimStationCount){
                ibufLoop0Iter := ibufLoop0Iter + 1.U
            }

            when(ibufLoop0Iter === io.config.ibufLoop0Iter && ibufIdx === io.config.cimBitCount + io.config.cimStationCount && ibufLoop1Iter === io.config.ibufLoop1Iter){
                ibufLoop1Iter := 0.U
            } .elsewhen(ibufLoop0Iter === io.config.ibufLoop0Iter && ibufIdx === io.config.cimBitCount + io.config.cimStationCount){
                ibufLoop1Iter := ibufLoop1Iter + 1.U
            }

            when(ibufLoop0Iter === io.config.ibufLoop0Iter && ibufIdx === io.config.cimBitCount + io.config.cimStationCount && ibufLoop1Iter === io.config.ibufLoop1Iter){
                {ibufExecIter := ibufExecIter + 1.U}
        }
        }

        when(ibuf_ren.asBool && ibufLoop0Iter === io.config.ibufLoop0Iter){
            ibufAddr := ibufAddr + io.config.ibufLoop1Step
        } .elsewhen(ibuf_ren.asBool){
            ibufAddr := ibufAddr + io.config.ibufLoop0Step
        }

        when(ibufExecIter === io.config.execIter)
        {
            ibuf_ren := false.B
            cim_ren := false.B
        }. elsewhen(ibufIdx === 0.U) {
            ibuf_ren := true.B
            cim_ren := true.B
        } .elsewhen(ibufIdx <= io.config.cimBitCount) {
            ibuf_ren := false.B
            cim_ren := true.B
        } .otherwise {
            ibuf_ren := false.B
            cim_ren := false.B
        }
            
        when (obufExecIter < io.config.execIter && cimCoreArray.io.cim_odata_valid.asBool) {

            when(obufLoop0Iter === io.config.obufLoop0Iter){
                obufLoop0Iter := 0.U
            } .otherwise{
                obufLoop0Iter := obufLoop0Iter + 1.U
            }

            when(obufLoop0Iter === io.config.obufLoop0Iter && obufLoop1Iter === io.config.obufLoop1Iter){
                obufLoop1Iter := 0.U
            } .elsewhen(obufLoop0Iter === io.config.obufLoop0Iter){
                obufLoop1Iter := obufLoop1Iter + 1.U
            }


            when(obufLoop0Iter === io.config.obufLoop0Iter && obufLoop1Iter === io.config.obufLoop1Iter){
                {obufExecIter := obufExecIter + 1.U}
            }
        }

        when(cimCoreArray.io.cim_odata_valid.asBool && obufLoop0Iter === io.config.obufLoop0Iter){
            obufAddr := obufAddr + io.config.obufLoop1Step
        } .elsewhen(cimCoreArray.io.cim_odata_valid.asBool){
            obufAddr := obufAddr + io.config.obufLoop0Step
        }

        when (obufExecIter === io.config.execIter){
            state := s_idle
        }
  }
  }
  // Control the access signals for the buffers

  io.rsamAccess <> pixiBackend.io.rsamAccess
  
  val scoIbufAddr = ShiftRegister(ibufAddr, 4)
  val scoIbufEnable = ShiftRegister(ibuf_ren, 4)
  val scoIbufIsWrite = false.B
  val scoIbufWriteData = 0.U

  io.ibufAccess0.address := Mux(scoIbufEnable, scoIbufAddr, pixiBackend.io.ibufAccess0.address)
  io.ibufAccess0.enable := Mux(scoIbufEnable, scoIbufEnable, pixiBackend.io.ibufAccess0.enable)
  io.ibufAccess0.isWrite := Mux(scoIbufEnable, scoIbufIsWrite, pixiBackend.io.ibufAccess0.isWrite)
  io.ibufAccess0.writeData := Mux(scoIbufEnable, scoIbufWriteData, pixiBackend.io.ibufAccess0.writeData)

  io.ibufAccess1.address := Mux(scoIbufEnable, scoIbufAddr, pixiBackend.io.ibufAccess1.address)
  io.ibufAccess1.enable := Mux(scoIbufEnable, scoIbufEnable, pixiBackend.io.ibufAccess1.enable)
  io.ibufAccess1.isWrite := Mux(scoIbufEnable, scoIbufIsWrite, pixiBackend.io.ibufAccess1.isWrite)
  io.ibufAccess1.writeData := Mux(scoIbufEnable, scoIbufWriteData, pixiBackend.io.ibufAccess1.writeData)

  io.ibufAccess2.address := Mux(scoIbufEnable, scoIbufAddr, pixiBackend.io.ibufAccess2.address)
  io.ibufAccess2.enable := Mux(scoIbufEnable, scoIbufEnable, pixiBackend.io.ibufAccess2.enable)
  io.ibufAccess2.isWrite := Mux(scoIbufEnable, scoIbufIsWrite, pixiBackend.io.ibufAccess2.isWrite)
  io.ibufAccess2.writeData := Mux(scoIbufEnable, scoIbufWriteData, pixiBackend.io.ibufAccess2.writeData)

  io.ibufAccess3.address := Mux(scoIbufEnable, scoIbufAddr, pixiBackend.io.ibufAccess3.address)
  io.ibufAccess3.enable := Mux(scoIbufEnable, scoIbufEnable, pixiBackend.io.ibufAccess3.enable)
  io.ibufAccess3.isWrite := Mux(scoIbufEnable, scoIbufIsWrite, pixiBackend.io.ibufAccess3.isWrite)
  io.ibufAccess3.writeData := Mux(scoIbufEnable, scoIbufWriteData, pixiBackend.io.ibufAccess3.writeData)

  io.obufAccess.address := obufAddr
  io.obufAccess.enable := cimCoreArray.io.cim_odata_valid
  io.obufAccess.isWrite := true.B
  io.obufAccess.writeData := cimCoreArray.io.cim_odata

  cimCoreArray.io.cimRCtrlIO.cim_ren := cim_ren
  cimCoreArray.io.cimRCtrlIO.cim_idata_exp := io.config.cimAlignedExp

}
