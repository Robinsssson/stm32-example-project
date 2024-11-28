toolchain("arm-gcc")

    set_description("ARM Compiler of GCC")
    set_kind("cross")

    on_load(function(toolchain)
        if toolchain:is_plat("windows") then
            toolchain:set("toolset", "cc", "arm-none-eabi-gcc.exe")
            toolchain:set("toolset", "ld", "arm-none-eabi-gcc.exe")
            toolchain:set("toolset", "ar", "arm-none-eabi-ar.exe")
            toolchain:set("toolset", "as", "arm-none-eabi-gcc.exe")
        else
            toolchain:set("toolset", "cc", "arm-none-eabi-gcc")
            toolchain:set("toolset", "ld", "arm-none-eabi-gcc")
            toolchain:set("toolset", "ar", "arm-none-eabi-ar")
            toolchain:set("toolset", "as", "arm-none-eabi-gcc")
        end
    end)
toolchain_end()

rule("generate-hex")
    after_build(function(target)
        print("$(env ARM_TOOL)")
        print("after_build: generate hex files")
        local out = target:targetfile() or ""
        local gen_fi = "build/" .. target:name()
        print(string.format("%s => %s", out, gen_fi))
        -- https://github.com/xmake-io/xmake/discussions/2125
        -- os.exec("arm-none-eabi-objdump -S "..out.." > "..gen_fi..".asm")
        -- local asm = os.iorun("arm-none-eabi-objdump -S build/cross/cortex-m4/release/minimal-proj")
        -- io.writefile(gen_fi..".asm", asm)
        if is_plat("windows") then
            os.execv("arm-none-eabi-objcopy.exe", {"-Obinary", out, gen_fi .. ".bin"})
            os.execv("arm-none-eabi-objdump.exe", {"-S", out}, {stdout = gen_fi .. ".asm"})
            os.execv("arm-none-eabi-objcopy.exe", {"-O", "ihex", out, gen_fi .. ".hex"})
        else
            os.execv("arm-none-eabi-objcopy", {"-Obinary", out, gen_fi .. ".bin"})
            os.execv("arm-none-eabi-objdump", {"-S", out}, {stdout = gen_fi .. ".asm"})
            os.execv("arm-none-eabi-objcopy", {"-O", "ihex", out, gen_fi .. ".hex"})
        end
        os.mv(out, gen_fi .. ".elf") -- add .elf file
        --  -I binary
        -- $(Q) $(OBJ_COPY) -O ihex $@ $(BUILD_DIR)/$(TARGET).hex
        -- $(Q) $(OBJ_COPY) -O binary $@ $(BUILD_DIR)/$(TARGET).bin
        -- os.exec("qemu-system-arm -M stm32-p103 -nographic -kernel"..bin_out)
    end)
    after_clean(function(target)
        local gen_fi = "build/" .. target:name()
        os.rm(gen_fi .. ".*")
    end)
rule_end()

task("qemu")
    on_run(function()
        print("Run binary in Qemu!")
        local bin_out = os.files("$(buildir)/*.bin")[1]
        if bin_out then
            os.exec("qemu-system-arm -M stm32-p103 -nographic -kernel " .. bin_out)
        else
            print("Do not find bin file in $(buildir)/")
        end
    end)
    set_menu {
        -- Settings menu usage
        usage = "xmake qemu",

        -- Setup menu description
        description = "Run binary in Qemu!"
    }
task_end()
