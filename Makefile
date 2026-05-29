rom_name := hydrademo

asm_sources := $(shell find src -name '*.asm')
asm_dependencies := $(asm_sources:src/%.asm=build/%.d)
obj_sources := $(asm_sources:src/%.asm=build/%.o)
gfx_sources := $(shell find gfx -name '*.png')
compiled_gfx_sources := $(foreach ext,2bpp attrmap pal,$(gfx_sources:gfx/%.png=src/gfx/%.$(ext)))

$(rom_name).gbc: $(obj_sources) build/
	rgblink -o $(rom_name).gbc -m build/$(rom_name).map -- $(obj_sources)
	rgbfix -csv -l 0x33 -p 0xFF -t "Hydra Demo" -- $(rom_name).gbc

$(obj_sources): build/%.o: src/%.asm build/%.d
	rgbasm -o $@ -Wall -- $<

build/%.d: src/%.asm
	rgbasm -M build/$*.d -MC -MP -o build/$*.o -Wall -- src/$*.asm
	
-include $(asm_dependencies)

$(foreach ext,2bpp attrmap pal,src/gfx/%.$(ext)) &: gfx/%.png
	rgbgfx -ACmOP -o src/gfx/$*.2bpp -- $<

build/:
	mkdir build