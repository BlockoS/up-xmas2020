CC   = gcc
CXX  = g++
RASM = rasm
ECHO = echo

CCFLAGS = -W -Wall
RASMFLAGS =

ALL = bin2m12 up-xmas2020.bin up-xmas2020.m12 up-xmas2020_emu.bin up-xmas2020_emu.m12

all: $(ALL)

bin2m12: tools/bin2m12.c
	@$(ECHO) "CC    $@"
	@$(CC) $(CCFLAGS) -o $@ $^

cge2bin: tools/cge2bin.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

gfx: cge2bin
	@$(ECHO) "GEN	GFX"
	@./cge2bin -x 0 -y 0 -w 12 -h 25 ./data/0000.txt ./_data/border00.bin
	@./cge2bin -x 12 -y 0 -w 12 -h 25 ./data/0000.txt ./_data/border01.bin
	@./cge2bin -x 24 -y 0 -w 12 -h 25 ./data/0000.txt ./_data/border02.bin
	@./cge2bin -x 0 -y 0 -w 12 -h 25 ./data/0001.txt ./_data/border03.bin
	@./cge2bin -x 12 -y 0 -w 12 -h 25 ./data/0001.txt ./_data/border04.bin
	@./cge2bin -x 24 -y 0 -w 12 -h 25 ./data/0001.txt ./_data/border05.bin
	@./cge2bin -x 0 -y 0 -w 12 -h 25 ./data/0002.txt ./_data/border06.bin
	@./cge2bin -x 12 -y 0 -w 12 -h 25 ./data/0002.txt ./_data/border07.bin
	@./cge2bin -x 0 -y 0 -w 40 -h 25 ./data/0003.txt ./_data/shadow.bin

up-xmas2020.bin: gfx
	@$(ECHO) "RASM	$@"
	@$(RASM) $(RASMFLAGS) up-xmas2020.asm -o $(basename $@)

up-xmas2020_emu.bin: up-xmas2020.bin
	@$(ECHO) "RASM	$@"
	@$(RASM) -DEMU=1 $(RASMFLAGS) up-xmas2020.asm -o $(basename $@)


%.m12: %.bin bin2m12
	@$(ECHO) "M12	$@"
	@./bin2m12 $< $@ UP-XMAS2020

clean:
	@$(ECHO) "CLEANING UP..."
	@rm -f bin2m12 up-xmas2020.bin up-xmas2020.m12 up-xmas2020_emu.bin up-xmas2020_emu.m12
	@find $(BUILD_DIR) -name "*.o" -exec rm -f {} \;
