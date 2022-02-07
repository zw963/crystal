{% skip_file if flag?(:without_interpreter) %}
require "./spec_helper"
require "../loader/spec_helper"

describe Crystal::Repl::Interpreter do
  context "variadic calls" do
    before_all do
      FileUtils.mkdir_p(SPEC_CRYSTAL_LOADER_LIB_PATH)
      build_c_dynlib(compiler_datapath("interpreter", "sum.c"))
    end

    it "promotes float" do
      interpret(<<-CR).should eq 3.5
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lsum")]
        lib LibSum
          fun sum_float(count : Int32, ...) : Float32
        end

        LibSum.sum_float(2, 1.2_f32, 2.3_f32)
        CR
    end

    it "promotes int" do
      interpret(<<-CR).should eq 5
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lsum")]
        lib LibSum
          fun sum_int(count : Int32, ...) : Int32
        end

        LibSum.sum_int(2, 1_u8, 4_i16)
        CR
    end

    it "promotes enum" do
      interpret(<<-CR).should eq 5
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lsum")]
        lib LibSum
          fun sum_int(count : Int32, ...) : Int32
        end

        enum E : Int8
          ONE = 1
        end

        enum F : UInt16
          FOUR = 4
        end

        LibSum.sum_int(2, E::ONE, F::FOUR)
        CR
    end

    after_all do
      FileUtils.rm_rf(SPEC_CRYSTAL_LOADER_LIB_PATH)
    end
  end

  describe "function pointers" do
    before_all do
      FileUtils.mkdir_p(SPEC_CRYSTAL_LOADER_LIB_PATH)
      build_c_dynlib(compiler_datapath("libs", "funptr.c"))
    end

    it "passes function pointer to function" do
      interpret(<<-CR).should eq 120
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lfunptr")]
        lib LibFun
          fun funptr(f : Int32 -> Int32) : Int32
        end

        LibFun.funptr -> (i : Int32) { i * 10 }
        CR
    end

    it "assigns function pointer to global var" do
      interpret(<<-CR).should eq 120
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lfunptr")]
        lib LibFun
          $fun_ptr : Int32 -> Int32
        end

        LibFun.fun_ptr = -> (i : Int32) { i * 10 }
        LibFun.fun_ptr.call(12)
        CR
    end

    it "passes function pointer and calls it later" do
      interpret(<<-CR).should eq 420
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lfunptr")]
        lib LibFun
          fun funptr_set(f : Int32 -> Int32) : Void

          fun funptr_call : Int32
        end

        LibFun.funptr_set -> (i : Int32) { i * 10 }
        LibFun.funptr_call
        CR
    end

    pending "assigns function pointer to global var and calls it later" do
      interpret(<<-CR).should eq 420
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lfunptr")]
        lib LibFun
          $fun_ptr : Int32 -> Int32

          fun funptr_call : Int32
        end

        LibFun.fun_ptr = -> (i : Int32) { i * 10 }
        LibFun.funptr_call
        CR
    end

    pending "passes function pointer to function var and reads it from global var" do
      interpret(<<-CR).should eq 420
        @[Link(ldflags: "-L#{SPEC_CRYSTAL_LOADER_LIB_PATH} -lfunptr")]
        lib LibFun
          $fun_ptr : Int32 -> Int32

          fun funptr_set(f : Int32 -> Int32) : Void
        end

        LibFun.funptr_set -> (i : Int32) { i * 10 }
        LibFun.fun_ptr.call(42)
        CR
    end

    after_all do
      FileUtils.rm_rf(SPEC_CRYSTAL_LOADER_LIB_PATH)
    end
  end
end
