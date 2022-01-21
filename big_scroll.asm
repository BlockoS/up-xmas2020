big_scroll_init:
    ld a, 3
    ld (scroll_x), a

    ld a, 0xff
    ld (scroll_chr_index  ), a
    ld (scroll_chr_index+1), a

    ld a, 7
    ld (scroll_chr_px), a

    ld hl, scroll_buffer
    ld (hl), 0x00
    ld de, scroll_buffer+1
    ld bc, (SCREEN_WIDTH+1)*8-1
    ldir

    ld a, 0x3d
    ld (scroll_char+0x01), a 
    ld (scroll_char+0xfe), a

    ld a, 0x3f
    ld (scroll_char+0x03), a
    ld (scroll_char+0xfc), a

    ld a, 0x7f
    ld (scroll_char+0x07), a
    ld (scroll_char+0xf8), a
    
    ld a, 0x3b
    ld (scroll_char+0x0f), a
    ld (scroll_char+0xf0), a
    
    ld a, 0x7b
    ld (scroll_char+0x1f), a                ; :/
    ld (scroll_char+0xe0), a                ; :/

    ld a, 0x37
    ld (scroll_char+0x3f), a
    ld (scroll_char+0xc0), a

    ld a, 0x71
    ld (scroll_char+0x7f), a
    ld (scroll_char+0x80), a

    ld a, 0x43
    ld (scroll_char+0xff), a


    ld a, 0x70
    ld (scroll_attr+0x03), a
    ld (scroll_attr+0x07), a
    ld (scroll_attr+0x0f), a
    ld (scroll_attr+0x80), a
    ld (scroll_attr+0xc0), a
    ld (scroll_attr+0xe0), a
    ld (scroll_attr+0xff), a

    ld a, 0x07
    ld (scroll_attr+0x01), a
    ld (scroll_attr+0x1f), a
    ld (scroll_attr+0x3f), a
    ld (scroll_attr+0x7f), a
    ld (scroll_attr+0xf0), a
    ld (scroll_attr+0xf8), a
    ld (scroll_attr+0xfc), a
    ld (scroll_attr+0xfe), a

    ret

big_scroll_update:
    ld hl, scroll_x
    inc (hl)
    ld a, (hl)
    cp 4
    jp nz, .l0
        xor a
        ld (hl), a

        ld hl, scroll_chr_px
        inc (hl)
        ld a, (hl)
        cp 8
        jp nz, .l1
            xor a
            ld (hl), a

            ld bc, (scroll_chr_index)
            inc bc
            ld hl, scroll_txt
            add hl, bc
            ld a, (hl)
            or a
            jp nz, .l2
                ld bc, 0xffff
                ld a, 0x20
.l2:
            ld (scroll_chr_index), bc

            ld b, 0x00
            add a,a
            rl b
            add a,a
            rl b
            add a,a
            rl b
            ld c, a
            ld hl, font_8x8
            add hl, bc

repeat 8, j
            ld a, (hl)
            ld (scroll_bitmap+(j-1)), a
            inc hl
rend
.l1:

repeat 8, j
        xor a
        ld hl, scroll_bitmap+(j-1)
        sla (hl)
        sbc a, 0x00
        ld (scroll_buffer + (j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH), a
        inc hl
rend
.l0:

    ld b, hi(scroll_char)
    ld d, hi(scroll_attr)

repeat 8, j
       ld hl, scroll_buffer+(j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH
       sla (hl)
       dec hl
repeat SCREEN_WIDTH, i
            rl (hl)
            dec hl
rend

        ld hl, scroll_buffer+(j-1)*(SCREEN_WIDTH+1) + (SCREEN_WIDTH)
        sla (hl)
        dec hl
repeat SCREEN_WIDTH, i
            rl (hl)
            dec hl
rend
rend

    wait_vbl

repeat 8, j
        ld hl, scroll_buffer+(j-1)*(SCREEN_WIDTH+1) + SCREEN_WIDTH
repeat SCREEN_WIDTH, i
        dec hl
        ld c, (hl)
        ld e, c
        ld a,(bc)
        ld (0xd000+(SCREEN_WIDTH-i)+(12+j-1)*SCREEN_WIDTH), a
        ld a,(de)
        ld (0xd800+(SCREEN_WIDTH-i)+(12+j-1)*SCREEN_WIDTH), a
rend

rend
    
    ret

font_8x8:
    incbin "data/font.bin"

align 256

scroll_char: defs 256
scroll_attr: defs 256

scroll_buffer: defs (SCREEN_WIDTH+1)*8

scroll_bitmap: defs 8

scroll_x: defb 0
scroll_chr_index: defw 0
scroll_chr_px: defb 0

scroll_txt: defb "What? It was supposed to be a Christmas intro! Why the hell did it turn into an invit? ... Well, guess what! You are invited to the Shadow Party. From the 21st to the 23rd of May 2021 in a strange, uncanny and somehow weird place called ... the internet. More infos at www.shadow-party.org", 0

shadow: incbin "_data/shadow.bin"
