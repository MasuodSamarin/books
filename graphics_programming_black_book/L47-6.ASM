; Mode X (320x240, 256 colors) rectangle fill routine. Works on all
; VGAs. Uses fast approach that fans data out to up to four planes at
; once to draw up to four pixels at once. Fills up to but not
; including the column at EndX and the row at EndY. No clipping is
; performed.
; C near-callable as:
;    void FillRectangleX(int StartX, int StartY, int EndX, int EndY,
;       unsigned int PageBase, int Color);

SC_INDEX        equ     03c4h   ;Sequence Controller Index
MAP_MASK        equ     02h     ;index in SC of Map Mask register
SCREEN_SEG      equ     0a000h  ;segment of display memory in mode X
SCREEN_WIDTH    equ     80      ;width of screen in bytes from one scan line
                                ; to the next
parms   struc
        dw      2 dup (?)       ;pushed BP and return address
StartX  dw      ?               ;X coordinate of upper left corner of rect
StartY  dw      ?               ;Y coordinate of upper left corner of rect
EndX    dw      ?               ;X coordinate of lower right corner of rect
                                ; (the row at EndX is not filled)
EndY    dw      ?               ;Y coordinate of lower right corner of rect
                                ; (the column at EndY is not filled)
PageBase dw     ?               ;base offset in display memory of page in
                                ; which to fill rectangle
Color   dw      ?               ;color in which to draw pixel
parms   ends

        .model  small
        .data
; Plane masks for clipping left and right edges of rectangle.
LeftClipPlaneMask       db      00fh,00eh,00ch,008h
RightClipPlaneMask      db      00fh,001h,003h,007h
        .code
        public  _FillRectangleX
_FillRectangleX proc    near
        push    bp              ;preserve caller's stack frame
        mov     bp,sp           ;point to local stack frame
        push    si              ;preserve caller's register variables
        push    di

        cld
        mov     ax,SCREEN_WIDTH
        mul     [bp+StartY]     ;offset in page of top rectangle scan line
        mov     di,[bp+StartX]
        shr     di,1            ;X/4 = offset of first rectangle pixel in scan
        shr     di,1            ; line
        add     di,ax           ;offset of first rectangle pixel in page
        add     di,[bp+PageBase] ;offset of first rectangle pixel in
                                ; display memory
        mov     ax,SCREEN_SEG   ;point ES:DI to the first rectangle
        mov     es,ax           ; pixel's address
        mov     dx,SC_INDEX     ;set the Sequence Controller Index to
        mov     al,MAP_MASK     ; point to the Map Mask register
        out     dx,al
        inc     dx              ;point DX to the SC Data register
        mov     si,[bp+StartX]
        and     si,0003h        ;look up left edge plane mask
        mov     bh,LeftClipPlaneMask[si] ; to clip & put in BH
        mov     si,[bp+EndX]
        and     si,0003h        ;look up right edge plane
        mov     bl,RightClipPlaneMask[si] ; mask to clip & put in BL

        mov     cx,[bp+EndX]    ;calculate # of addresses across rect
        mov     si,[bp+StartX]
        cmp     cx,si
        jle     FillDone        ;skip if 0 or negative width
        dec     cx
        and     si,not 011b
        sub     cx,si
        shr     cx,1
        shr     cx,1            ;# of addresses across rectangle to fill - 1
        jnz     MasksSet        ;there's more than one byte to draw
        and     bh,bl           ;there's only one byte, so combine the left
                                ; and right edge clip masks
MasksSet:
        mov     si,[bp+EndY]
        sub     si,[bp+StartY]  ;BX = height of rectangle
        jle     FillDone        ;skip if 0 or negative height
        mov     ah,byte ptr [bp+Color] ;color with which to fill
        mov     bp,SCREEN_WIDTH ;stack frame isn't needed any more
        sub     bp,cx           ;distance from end of one scan line to start
        dec     bp              ; of next
FillRowsLoop:
        push    cx              ;remember width in addresses - 1
        mov     al,bh           ;put left-edge clip mask in AL
        out     dx,al           ;set the left-edge plane (clip) mask
        mov     al,ah           ;put color in AL
        stosb                   ;draw the left edge
        dec     cx              ;count off left edge byte
        js      FillLoopBottom  ;that's the only byte
        jz      DoRightEdge     ;there are only two bytes
        mov     al,00fh         ;middle addresses are drawn 4 pixels at a pop
        out     dx,al           ;set the middle pixel mask to no clip
        mov     al,ah           ;put color in AL
        rep     stosb           ;draw the middle addresses four pixels apiece
DoRightEdge:
        mov     al,bl           ;put right-edge clip mask in AL
        out     dx,al           ;set the right-edge plane (clip) mask
        mov     al,ah           ;put color in AL
        stosb                   ;draw the right edge
FillLoopBottom:
        add     di,bp           ;point to the start of the next scan line of
                                ; the rectangle
        pop     cx              ;retrieve width in addresses - 1
        dec     si              ;count down scan lines
        jnz     FillRowsLoop
FillDone:
        pop     di              ;restore caller's register variables
        pop     si
        pop     bp              ;restore caller's stack frame
        ret
_FillRectangleX endp
        end
