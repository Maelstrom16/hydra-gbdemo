; Adapted from https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "src/inc/hardware.inc"

SECTION "Header", ROM0[$100]

  jp EntryPoint

  ds $150 - @, 0 ; Make room for the header

EntryPoint:
  ; Shut down audio circuitry
  xor a
  ldh [rAUDENA], a

  ; Clear WRAM
  ld d, $00
  ld hl, STARTOF(WRAM0)
  ld bc, SIZEOF(WRAM0)
  call Fill

  ; Do not turn the LCD off outside of VBlank
.wait_vblank
  ldh a, [rLY]
  cp LY_VBLANK
  jr c, .wait_vblank

  ; Turn the LCD off
  ld a, LCDC_OFF
  ldh [rLCDC], a
  
  ; Copy object data
  ld de, Objects
  ld hl, STARTOF(VRAM)
  ld bc, Objects.end - Objects
  call Copy
  
  ; Copy OAM default data
  ld de, OamDefaults
  ld hl, wOAMStagingArea
  ld bc, OamDefaults.end - OamDefaults
  call Copy
  
  ; Copy OAM routine to HRAM
  ld de, InitiateDma
  ld hl, hInitiateDMA
  ld bc, InitiateDma.end - InitiateDma
  call Copy
  
  ; Call OAM DMA routine
  call hInitiateDMA

  ; CGB palette initialization
  ld hl, PaletteData
  ld bc, PaletteData.end - PaletteData
  call InitializePalettes

  ; Turn the LCD on
  ld a, LCDC_ON | LCDC_OBJ_ON | LCDC_BG_ON
  ldh [rLCDC], a

  ; During the first (blank) frame, initialize display registers
  ; DMG
  ld a, %11_10_01_00
  ldh [rBGP], a
  ldh [rOBP0], a

.done
  jr .done

; Subroutine to copy bc bytes from de to hl
Copy:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ld a, b
  or a, c
  jr nz, Copy
  ret

; Subroutine to fill bc bytes at hl with d
Fill:
  ld a, d
  ld [hli], a
  dec bc
  ld a, b
  or a, c
  jr nz, Fill
  ret
  
; Subroutine to copy object palettes to CRAM
InitializePalettes:
  ld a, OBPI_AUTOINC
  ldh [rOBPI], a
  
  .loop
  ld a, [hli]
  ldh [rOBPD], a
  dec bc
  ld a, b
  or a, c
  jr nz, InitializePalettes.loop
  ret
  
; DMA Subroutine, to be copied to HRAM
InitiateDma:
    ld a, HIGH(wOAMStagingArea)
    ldh [rDMA], a  ; start DMA transfer (starts right after instruction)
    ld a, 40        ; delay for a total of 4×40 = 160 M-cycles
.wait
    dec a           ; 1 M-cycle
    jr nz, .wait    ; 3 M-cycles
    ret
.end

SECTION "Object data", ROM0

Objects:
  INCBIN "src/gfx/player.2bpp"
.end

PaletteData:
  INCBIN "src/gfx/player.pal"
.end

SECTION "OAM default", ROM0

OamDefaults:
  db 24, 16, $00, $04
  db 23, 19, $01, $01
  db 26, 17, $02, $03
  db 25, 19, $03, $02
  db 33, 17, $04, $05
  db 33, 20, $05, $05
  db 30, 18, $06, $00
.end