# Helper macros to convert spaces into question marks and back again
e :=
sp := $(e) $(e)
qs = $(subst ?,$(sp),$1)
sq = $(subst $(sp),?,$1)

# Get name of this Makefile (avoid getting word 0 and a starting space)
makefile_name := $(wordlist 1,1000,$(MAKEFILE_LIST))

# Get path of this Makefile
makefile_path := $(call qs,$(dir $(call sq,$(abspath $(call sq,$(makefile_name))))))

# Get path where the Application is
application_path := $(call qs,$(abspath $(call sq,$(makefile_path)./)))

# Change makefile_name to a relative path
makefile_name := $(subst $(call sq,$(application_path))/,,$(call sq,$(abspath $(call sq,$(makefile_name)))))

# Get relative path to makefile from application_path
makefile_path_relative := $(subst $(call sq,$(application_path))/,,$(call sq,$(abspath $(call sq,$(makefile_path)))))

# Get path to Middlewares
Middlewares_path := Middlewares

# Get path to Drivers
Drivers_path := Drivers

# Get OS path
rtos_path := FreeRTOS

# Get identification of this system
ifeq ($(OS),Windows_NT)
UNAME := MINGW32_NT-6.2
else
UNAME := $(shell uname -s)
endif

board_name := ST/STM32F769I-DISCO
platform := cortex_m7

.PHONY: all clean assets flash intflash

all: $(filter clean,$(MAKECMDGOALS))
all clean assets:
	@cd "$(application_path)" && $(MAKE) -r -f $(makefile_name) -s $(MFLAGS) _$@_

flash intflash: all
	@cd "$(application_path)" && $(MAKE) -r -f $(makefile_name) -s $(MFLAGS) _$@_

# Directories containing application-specific source and header files.
# Additional components can be added to this list. make will look for
# source files recursively in comp_name/src and setup an include directive
# for comp_name/include.
components := TouchGFX/gui target TouchGFX/generated/gui_generated

# Location of folder containing bmp/png files.
asset_images_input  := TouchGFX/assets/images

# Location of folder to search for ttf font files
asset_fonts_input  := TouchGFX/assets/fonts

# Location of folder where the texts.xlsx is placed
asset_texts_input  := TouchGFX/assets/texts

build_root_path := build
object_output_path := $(build_root_path)/$(board_name)
binary_output_path := $(build_root_path)/bin

# Location of output folders where autogenerated code from assets is placed
asset_root_path := TouchGFX/generated
asset_images_output := $(asset_root_path)/images
asset_fonts_output := $(asset_root_path)/fonts
asset_texts_output := $(asset_root_path)/texts

#include application specific configuration
include $(application_path)/TouchGFX/config/gcc/app.mk

# corrects TouchGFX Path
touchgfx_path := touchgfx
# touchgfx_path := ${subst ../,,$(touchgfx_path)}
# touchgfx_path := $(subst $(call sq,$(makefile_path))/,,$(call sq,$(abspath $(call sq,$(touchgfx_path)))))

os_source_files := $(shell find $(rtos_path)/source -name *.c)
os_source_files += $(shell find $(rtos_path)/portable -name *.c)

os_include_paths := $(rtos_path)/include
os_include_paths += $(rtos_path)/portable/GCC/ARM_CM7/r0p1
os_include_paths += $(rtos_path)/CMSIS_RTOS

os_wrapper := $(touchgfx_path)/os/OSWrappers.cpp

### END OF USER SECTION. THE FOLLOWING SHOULD NOT BE MODIFIED ###

st_link_executable := st-flash

target_executable := target.elf
target_hex := target.hex

assembler         := arm-none-eabi-gcc
assembler_options += -g  \
                    -fno-exceptions\
                    $(no_libs) -mthumb -mno-thumb-interwork  \
                     -Wall
assembler_options += $(float_options)

c_compiler         := arm-none-eabi-gcc
c_compiler_options += -g \
                    -mthumb -fno-exceptions \
                    -mno-thumb-interwork -std=c99 \
                    $(no_libs) \
                    -Os -fno-strict-aliasing -fdata-sections -ffunction-sections
#TODO removed -Wall

c_compiler_options += $(float_options)

cpp_compiler         := arm-none-eabi-g++
cpp_compiler_options += -g -mthumb \
                    $(no_libs) \
                    -mno-thumb-interwork -fno-rtti -fno-exceptions  \
                    -Os -fno-strict-aliasing -fdata-sections -ffunction-sections

#TODO removed -Wall

cpp_compiler_options += $(float_options)

linker         := arm-none-eabi-g++
linker_options += -g -Wl,-static -mthumb $(no_libs) -mno-thumb-interwork \
                  -fno-exceptions -specs=nosys.specs -fno-rtti \
                  -Os -fno-strict-aliasing -Wl,--gc-sections

objcopy  := arm-none-eabi-objcopy
archiver := arm-none-eabi-ar
strip    := arm-none-eabi-strip

# Additional toolchain configuration for Cortex-M7 targets.

float_options := -mfpu=fpv5-sp-d16 -mfloat-abi=softfp

assembler_options += -mthumb -mcpu=cortex-m7 -Wno-psabi $(float_options) -DCORE_M7 -D__irq=""
c_compiler_options += -mthumb -mcpu=cortex-m7 -Wno-psabi $(float_options) -DCORE_M7 -D__irq=""
cpp_compiler_options += -mthumb -mcpu=cortex-m7 -Wno-psabi $(float_options) -DCORE_M7 -D__irq=""
linker_options += -mcpu=cortex-m7 -Wno-psabi $(float_options)

#include everything + specific vendor folders
framework_includes := $(touchgfx_path)/framework/include

#this needs to change when assset include folder changes.
all_components := $(components)
all_components += $(asset_fonts_output)
all_components += $(asset_images_output)
all_components += $(asset_texts_output)

#keep framework include and source out of this mess! :)
include_paths := $(library_includes)
include_paths += $(foreach comp, $(all_components), $(comp)/include)
include_paths += $(framework_includes)
include_paths += $(source_Middlewares_paths)

source_paths = $(foreach comp, $(all_components), $(comp)/src)

# Finds files that matches the specified pattern. The directory list
# is searched recursively. It is safe to invoke this function with an
# empty list of directories.
#
# Param $(1): List of directories to search
# Param $(2): The file pattern to search for
define find
  $(foreach dir,$(1),$(foreach d,$(wildcard $(dir)/*),\
    $(call find,$(d),$(2))) $(wildcard $(dir)/$(strip $(2))))
endef
unexport find

fontconvert_font_files := $(shell find $(asset_fonts_input) -iname *.ttf)
fontconvert_font_files += $(shell find $(asset_fonts_input) -iname *.otf)
fontconvert_font_files += $(shell find $(asset_fonts_input) -iname *.bdf)

source_files := $(call find, $(source_paths), *.cpp)

board_c_files := $(call find, $(Drivers_path)/BSP/STM32F769I-Discovery, *.c)
board_c_files += $(Drivers_path)/BSP/Components/otm8009a/otm8009a.c
board_c_files += $(Drivers_path)/BSP/Components/ft6x06/ft6x06.c

board_c_files += $(shell find $(Drivers_path)/STM32F7xx_HAL_Driver/Src -name '*.c')
board_c_files += $(call find, Core/Src, *.c)
board_c_files += $(rtos_path)/CMSIS_RTOS/cmsis_os.c

board_cpp_files := Core/Src/main.cpp
board_cpp_files += $(call find, TouchGFX/target, *.cpp)

board_include_paths := TouchGFX/gui/include
board_include_paths += TouchGFX/target
board_include_paths += TouchGFX/platform/os
board_include_paths += TouchGFX/generated/fonts/include
board_include_paths += TouchGFX/generated/images/include
board_include_paths += TouchGFX/generated/texts/include
board_include_paths += TouchGFX/generated/gui_generated/include
board_include_paths += $(framework_includes)
board_include_paths += $(Drivers_path)/BSP/STM32F769I-Discovery
board_include_paths += $(Drivers_path)/STM32F7xx_HAL_Driver/Inc
board_include_paths += $(Drivers_path)/CMSIS/Include
board_include_paths += $(Drivers_path)/CMSIS/Device/ST/STM32F7xx/Include
board_include_paths += Core/Inc
board_include_paths += $(Drivers_path)/BSP/Components/otm8009a

asm_source_files := startup_stm32f769xx.s

c_compiler_options += -DST -DSTM32F769xx
cpp_compiler_options += -DST -DSTM32F769xx

include_paths += platform/os $(board_include_paths) $(os_include_paths)

c_source_files := $(call find, $(source_paths), *.c) $(os_source_files) $(board_c_files)
source_files += $(os_wrapper) \
                $(board_cpp_files)

object_files := $(source_files) $(c_source_files)
# Start converting paths
object_files := $(object_files:$(touchgfx_path)/%.cpp=$(object_output_path)/touchgfx/%.o)
object_files := $(object_files:%.cpp=$(object_output_path)/%.o)
object_files := $(object_files:$(Middlewares_path)/%.c=$(object_output_path)/Middlewares/%.o)
object_files := $(object_files:$(Drivers_path)/%.c=$(object_output_path)/Drivers/%.o)
object_files := $(object_files:%.c=$(object_output_path)/%.o)
dependency_files := $(object_files:%.o=%.d)

object_asm_files := $(asm_source_files:%.s=$(object_output_path)/%.o)
object_asm_files := $(patsubst $(object_output_path)/%,$(object_output_path)/%,$(object_asm_files))

# textconvert_script_path := $(touchgfx_path)/framework/tools/textconvert
# textconvert_executable := $(call find, $(textconvert_script_path), *.rb)

text_database := $(asset_texts_input)/texts.xlsx

libraries := touchgfx
library_include_paths := $(touchgfx_path)/lib/core/$(platform)/gcc

.PHONY: _all_ _clean_ _assets_ _flash_ _intflash_ generate_assets build_executable

# Force linking each time
.PHONY: $(binary_output_path)/$(target_executable)

_all_: generate_assets

ifeq ($(shell find "$(application_path)" -wholename "$(application_path)/$(binary_output_path)/extflash.bin" -size +0c | wc -l | xargs echo),1)
_flash_: _extflash_
else
_flash_: _intflash_
endif

_extflash_:
	@$(st_link_executable) -c -P $(binary_output_path)/target.hex 0x90000000 -Rst

_intflash_:
	@$(st_link_executable) -c -P $(binary_output_path)/intflash.hex 0x08000000 -Rst

generate_assets: _assets_
	@$(MAKE) -f $(makefile_name) -r -s $(MFLAGS) build_executable
build_executable: $(binary_output_path)/$(target_executable)

$(binary_output_path)/$(target_executable): $(object_files) $(object_asm_files)
	@echo Linking $(@)
	@mkdir -p $(@D)
	@mkdir -p $(object_output_path)
	@$(file >$(build_root_path)/objects.tmp) $(foreach F,$(object_files),$(file >>$(build_root_path)/objects.tmp,$F))
	@$(linker) \
		$(linker_options) -T $(makefile_path_relative)/STM32F769NIHx_FLASH.ld -Wl,-Map=$(@D)/application.map $(linker_options_local) \
		$(patsubst %,-L%,$(library_include_paths)) \
		@$(build_root_path)/objects.tmp $(object_asm_files) -o $@ \
		-Wl,--start-group $(patsubst %,-l%,$(libraries)) -Wl,--end-group
	@rm -f $(build_root_path)/objects.tmp
	@echo "Producing additional output formats..."
	@echo "  target.hex   - Combined internal+external hex"
	@$(objcopy) -O ihex $@ $(@D)/target.hex
	@echo "  intflash.elf - Internal flash, elf debug"
	@$(objcopy) --remove-section=ExtFlashSection $@ $(@D)/intflash.elf 2>/dev/null
	@echo "  intflash.hex - Internal flash, hex"
	@$(objcopy) -O ihex --remove-section=ExtFlashSection $@ $(@D)/intflash.hex
	@echo "  extflash.bin - External flash, binary"
	@$(objcopy) -O binary --only-section=ExtFlashSection $@ $(@D)/extflash.bin

$(object_output_path)/touchgfx/%.o: $(touchgfx_path)/%.cpp TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(cpp_compiler) \
		-MMD -MP $(cpp_compiler_options) $(cpp_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/%.o: %.cpp TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(cpp_compiler) \
		-MMD -MP $(cpp_compiler_options) $(cpp_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/touchgfx/%.o: $(touchgfx_path)/%.c TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(c_compiler) \
		-MMD -MP $(c_compiler_options) $(c_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/%.o: %.c TouchGFX/config/gcc/app.mk
	@echo Compiling $<
	@mkdir -p $(@D)
	@$(c_compiler) \
		-MMD -MP $(c_compiler_options) $(c_compiler_options_local) $(user_cflags) \
		$(patsubst %,-I%,$(include_paths)) \
		-c $< -o $@

$(object_output_path)/%.o: %.s TouchGFX/config/gcc/app.mk
	@echo Compiling ASM $<
	@mkdir -p $(@D)
	@$(assembler) \
		$(assembler_options) \
		$(patsubst %,-I %,$(os_include_paths)) \
		-c $< -o $@

ifeq ($(MAKECMDGOALS),build_executable)
$(firstword $(dependency_files)): TouchGFX/config/gcc/app.mk
	@rm -rf $(object_output_path)
-include $(dependency_files)
endif

_assets_: BitmapDatabase $(asset_texts_output)/include/texts/TextKeysAndLanguages.hpp

alpha_dither ?= no
dither_algorithm ?= 2
remap_identical_texts ?= yes

.PHONY: BitmapDatabase
BitmapDatabase:
	@echo Converting images
	@$(imageconvert_executable) -dither $(dither_algorithm) -alpha_dither $(alpha_dither) -opaque_image_format $(opaque_image_format) -non_opaque_image_format $(non_opaque_image_format) $(screen_orientation) -r $(asset_images_input) -w $(asset_images_output)

$(asset_texts_output)/include/texts/TextKeysAndLanguages.hpp: $(text_database) TouchGFX/config/gcc/app.mk $(textconvert_executable) $(fontconvert_executable) $(fontconvert_font_files)

_clean_:
	@echo Cleaning
	@rm -rf $(build_root_path)
	# Do not remove gui_generated