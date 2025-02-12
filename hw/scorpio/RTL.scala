package scorpio

import chisel3._
import circt.stage._

object RtlEmitter extends App {
  val targetDir = "generate/hw"

  val chiselArgs = Array(f"--target-dir=$targetDir", "--split-verilog")
  val firtoolOpts =
    Array("--disable-all-randomization", "-repl-seq-mem", f"-repl-seq-mem-file=seq-mem.conf")

  ChiselStage
    .emitSystemVerilogFile(new ScorpioChip, chiselArgs, firtoolOpts)
  println(f">>> RTL emitted in \"$targetDir\" directory.")
}
