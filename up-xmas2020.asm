org #1200

SCREEN_WIDTH = 40
SCREEN_HEIGHT = 25

FIRE_WIDTH = 29
FIRE_HEIGHT = SCREEN_HEIGHT

FIRE_FRAME_COUNT = 180

hblnk = 0xe008
vblnk = 0xe002

macro wait_vbl
    ; wait for vblank    
    ld hl, vblnk
    ld a, 0x7f
@wait0:
    cp (hl)
    jp nc, @wait0
@wait1:
    cp (hl)
    jp c, @wait1
mend

macro fire_update phase
  if {phase} == 0
    ld de, (fire_source_addr)

    exx
    ld hl, (fire_destination_addr)
fire_char equ $+1
    ld bc,0xd000
fire_attr equ $+1
    ld de,0xd800
    exx

    ld c, 12
  
  else
    ld c, FIRE_HEIGHT-12
  
  endif

@y_loop:
        ld b, FIRE_WIDTH-1
@x_loop:
            ld h,d
            ld l,e

            inc de

            ld a, (hl)
            inc hl

            add a, (hl)
            inc hl

            add a, (hl) 
            
            ld h,d
            ld l,e

            ex af,af'
            ld a, FIRE_WIDTH
            add a,l
            ld l,a
            adc a,h
            sub l
            ld h,a
            ex af,af'
 
            add a, (hl)

  if {phase} != 0
            jp z, @l1
                ld l,a
                and 3
                xor 3
                inc a
                and 4
                add a,l
@l1:
  endif

            srl a
            srl a
 
            cp 15
            jp c, @l0
                ld a, 15
@l0:
            ld (@char0), a

            exx
            ld (hl), a
            inc hl

            or gradient_attr&0xf0
            ld (@attr0), a
@attr0 equ $+1
            ld a,(gradient_attr)
            ld (de), a
            inc de

@char0 equ $+1
            ld a,(gradient_char)
            ld (bc), a
            inc bc

            exx

            dec b
            jp nz, @x_loop

        exx

        inc hl
        
        ld a, SCREEN_WIDTH - FIRE_WIDTH + 1
        add a, c
        ld c, a
        adc a, b
        sub c
        ld b, a

        ld a, SCREEN_WIDTH - FIRE_WIDTH + 1
        add a, e
        ld e, a
        adc a, d
        sub e
        ld d, a

        exx
        
        inc de

        dec c
        jp nz, @y_loop

  if {phase} != 0
    ld hl,(fire_init_addr)
    ld de,(fire_init_addr+2)
    ld (fire_init_addr),de
    ld (fire_init_addr+2),hl

    ld hl,(fire_source_addr)
    ld de,(fire_source_addr+2)
    ld (fire_source_addr),de
    ld (fire_source_addr+2),hl

    ld hl,(fire_destination_addr)
    ld de,(fire_destination_addr+2)
    ld (fire_destination_addr),de
    ld (fire_destination_addr+2),hl
  endif
mend

main:
    di
    im 1

    ld hl, 0xd000
    ld (hl), 0x00
    ld de, 0xd000+1
    ld bc, SCREEN_WIDTH*SCREEN_HEIGHT-1
    ldir

    ld hl, 0xd800
    ld (hl), 0x70
    ld de, 0xd800+1
    ld bc, SCREEN_WIDTH*SCREEN_HEIGHT-1
    ldir

PRESS_SPACE_OFFSET = 11*SCREEN_WIDTH + SCREEN_WIDTH/2 - 6
    ld hl, press_space
    ld de, 0xd000+PRESS_SPACE_OFFSET
    ld bc, 12
    ldir

    ld hl, 0xd800+PRESS_SPACE_OFFSET
    ld (hl), 0x70
    ld de, 0xd801+PRESS_SPACE_OFFSET
    ld bc, 11
    ldir

wait_key:
    ld hl, 0xe000
    ld (hl), 0xf6 
    inc hl
    bit 4,(hl)
    jp nz, wait_key
    
    ld hl, song
    xor a
    call PLY_LW_Init

    ld hl, _irq_vector
    ld (0x1039),hl

	ld hl, 0xe007               ;Counter 2.
	ld (hl), 0xb0
	dec hl
	ld (hl),1
	ld (hl),0

	ld hl, 0xe007               ;100 Hz (plays the music at 50hz).
	ld (hl), 0x74
	ld hl, 0xe005
ifdef EMU
    ld (hl), 156
else
	ld (hl), 110
endif
	ld (hl), 0

	ld hl, 0xe008 ;sound on
	ld (hl), 0x01

    ei
      
    ld hl, fire_previous+(FIRE_WIDTH*(FIRE_HEIGHT+1))
    ld de, fire_current+(FIRE_WIDTH*(FIRE_HEIGHT+1))
    ld c, FIRE_WIDTH
setup_base:
        ld a, 0x0f
        ld (hl),a
        ld (de),a
        inc hl
        inc de
        dec c
        jp nz, setup_base

    ld ixh, 8
fx0_loop:
    push ix

    ld hl, frame
    ld a,(hl)
    and 7
    inc (hl)
    add a, a
    add a, lo(border)
    ld l, a
    adc a, hi(border)
    sub l
    ld h, a
    ld a, (hl)
    inc hl
    ld b, (hl)
    ld iyl, a
    ld iyh, b

    ld bc, (border12_offset)
    ld ix, 0xd800
    add ix, bc
    call border12_fill
 
    ld bc, (border12_offset)
    ld ix, 0xd000
    add ix, bc
    call border12_fill

    ld a, (border12_x)
    ld (fire_char), a
    ld (fire_attr), a
    xor 12
    ld (border12_x), a

    ld hl,(border12_offset)
    ld de,(border12_offset+2)
    ld (border12_offset), de
    ld (border12_offset+2), hl

    pop ix

    ld ixl, FIRE_FRAME_COUNT
fire_loop:
    wait_vbl

    ld hl, (fire_init_addr)

    ld d, rand_table>>8
    ld a, (rand_offset)
    ld e, a
    ld c, FIRE_WIDTH
setup:
        ld a,(de)
        and 0x0f
        or 3
        ld (hl),a
        inc e
        inc hl
        dec c
        jp nz, setup

    ld a, e
    ld (rand_offset), a

    fire_update 0

    fire_update 1

    dec ixl
    jp nz, fire_loop

    dec ixh
    jp nz, fx0_loop

    ld ix, shadow
    ld iy, 0xd800+40*25 - 40 + 10
    call gfx_fill
    ld iy, 0xd000+40*25 - 40 + 10
    call gfx_fill
    
    call big_scroll_init
scroll_loop:
    call big_scroll_update
    jp scroll_loop

border12_fill:
    
    ld a, SCREEN_HEIGHT
.loop:
    ld (@b12sp_save), sp
    di
    
    ld sp, iy
    ld bc, 12
    add iy, bc   

    pop hl
    pop bc
    pop de
    
    exx
    pop hl
    pop bc
    pop de
    
    ld sp, ix
    push de
    push bc
    push hl

    exx
    push de
    push bc
    push hl

@b12sp_save equ $+1
    ld sp, 0x0000
    ei

    ld bc, -SCREEN_WIDTH
    add ix, bc
        
    dec a
    jp nz, .loop

    ret

gfx_fill:
    ld a, 25
.l0:
    ld l, 4
.l1:
    ld (@gfx_fill.save), sp
    di
    
    ld sp, ix
    ld bc, 10
    add ix, bc
    
    pop bc  
    pop de
    exx
    pop hl
    pop bc
    pop de
    
    ld sp, iy
    push de
    push bc
    push hl
    exx
    push de
    push bc

    ld bc,  10
    add iy, bc

@gfx_fill.save equ $+1
    ld sp, 0x0000
    ei
    
    dec l
    jp nz, .l1

    ld bc, -80
    add iy, bc
    
    dec a
    jp nz, .l0

    ret

rand_offset: defb 0

frame: defw 0

border12_offset:
    defw 40*25-40+12
    defw 40*25

border12_x:
    defb 12

press_space:
    defb 0x10,0x12,0x05,0x13,0x13,0x00,0x00,0x13,0x10,0x01,0x03,0x05

fire_init_addr:
    defw fire_previous+(FIRE_WIDTH*FIRE_HEIGHT)
    defw fire_current+(FIRE_WIDTH*FIRE_HEIGHT)

fire_destination_addr:
    defw fire_current+1
    defw fire_previous+1
    
fire_source_addr:
    defw fire_previous+FIRE_WIDTH
    defw fire_current+FIRE_WIDTH


_irq_vector:
    di

    push af
    push hl
    push bc
    push de
    push ix
    push iy
    exx
    push af
    push hl
    push bc
    push de
    push ix
    push iy
    
    ld hl, 0xe006
    ld a,1
    ld (hl), a
    xor a
    ld (hl), a
    
    call PLY_LW_Play        
    
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af
    exx
    pop iy
    pop ix
    pop de
    pop bc
    pop hl
    pop af

    ei
    reti


player: include "PlayerLightweight_SHARPMZ700.asm"

include "data/song_playerconfig.asm"
song: include "data/song.asm"

include "big_scroll.asm"

align 256
rand_table:
    defb   0,   8, 109, 220, 222, 241, 149, 107,  75, 248, 254, 140,  16,  66 , 74,  21
    defb 211,  47,  80, 242, 154,  27, 205, 128, 161,  89,  77,  36 , 95, 110,  85,  48
    defb 212, 140, 211, 249,  22,  79, 200,  50,  28, 188,  52, 140, 202, 120,  68, 145
    defb  62,  70, 184, 190,  91, 197, 152, 224, 149, 104,  25, 178, 252, 182, 202, 182
    defb 141, 197,   4,  81, 181, 242, 145,  42,  39, 227, 156, 198, 225, 193, 219,  93
    defb 122, 175, 249,   0, 175, 143,  70, 239,  46, 246, 163,  53, 163, 109, 168, 135
    defb   2, 235,  25,  92,  20, 145, 138,  77,  69, 166,  78, 176, 173, 212, 166, 113
    defb  94, 161,  41,  50, 239,  49, 111, 164,  70,  60,   2,  37, 171,  75, 136, 156
    defb  11,  56,  42, 146, 138, 229,  73, 146,  77,  61,  98, 196, 135, 106,  63, 197
    defb 195,  86,  96, 203, 113, 101, 170, 247, 181, 113,  80, 250, 108,   7, 255, 237
    defb 129, 226,  79, 107, 112, 166, 103, 241,  24, 223, 239, 120, 198,  58,  60,  82
    defb 128,   3, 184,  66, 143, 224, 145, 224,  81, 206, 163,  45,  63,  90, 168, 114
    defb  59,  33, 159,  95,  28, 139, 123,  98, 125, 196,  15,  70, 194, 253,  54,  14
    defb 109, 226 , 71,  17, 161,  93, 186,  87, 244, 138,  20,  52, 123, 251,  26,  36
    defb  17,  46,  52, 231, 232,  76,  31, 221,  84,  37, 216, 165, 212, 106, 197, 242
    defb  98,  43,  39, 175, 254, 145, 190,  84, 118, 222, 187, 136, 120, 163, 236, 249

gradient_char:
    defb 0x00,0x85,0x9f,0xa6,0xd0,0x00,0x85,0x9f,0xa6,0xd0,0x00,0x85,0x9f,0xa6,0xd0,0x00

gradient_attr:
    defb 0x00,0xa0,0xa0,0x20,0x20,0x22,0xe2,0xe2,0x62,0x62,0x66,0xf6,0xf6,0x76,0x76,0x77

border00:
    incbin "./_data/border00.bin"
border01:
    incbin "./_data/border01.bin"
border02:
    incbin "./_data/border02.bin"
border03:
    incbin "./_data/border03.bin"
border04:
    incbin "./_data/border04.bin"
border05:
    incbin "./_data/border05.bin"
border06:
    incbin "./_data/border06.bin"
border07:
    incbin "./_data/border07.bin"

border:
    defw border00, border01, border02, border03
    defw border04, border05, border06, border07

fire_previous: defs FIRE_WIDTH * (FIRE_HEIGHT+2)
fire_current:  defs FIRE_WIDTH * (FIRE_HEIGHT+2)
