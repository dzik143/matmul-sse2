; ==============================================================================
; =                                                                            =
; = Author: Sylwester Wysocki <sw143@wp.pl>                                    =
; = Created on: 2008                                                           =
; =                                                                            =
; = This is free and unencumbered software released into the public domain.    =
; =                                                                            =
; = Anyone is free to copy, modify, publish, use, compile, sell, or            =
; = distribute this software, either in source code form or as a compiled      =
; = binary, for any purpose, commercial or non-commercial, and by any          =
; = means.                                                                     =
; =                                                                            =
; = In jurisdictions that recognize copyright laws, the author or authors      =
; = of this software dedicate any and all copyright interest in the            =
; = software to the public domain. We make this dedication for the benefit     =
; = of the public at large and to the detriment of our heirs and               =
; = successors. We intend this dedication to be an overt act of                =
; = relinquishment in perpetuity of all present and future rights to this      =
; = software under copyright law.                                              =
; =                                                                            =
; = THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,            =
; = EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF         =
; = MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.     =
; = IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR          =
; = OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,      =
; = ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR      =
; = OTHER DEALINGS IN THE SOFTWARE.                                            =
; =                                                                            =
; = For more information, please refer to <https://unlicense.org>              =
; =                                                                            =
; ==============================================================================

.686
.xmm
.model flat, stdcall

.data
            szer dd ?
     to_last_row dd ?

         szer_4w dd ?                     ; szerokosc 4 wierszy B w bajtach

.code

;
; SSE2 square NxN matrix multiplication.
;
; C <- A x B
;

ALIGN 16
mxmg PROC C, _C: DWORD, _A: DWORD, _B: DWORD, n: DWORD

      push         ebx
      push         ecx
      push         esi
      push         edi

      mov          ecx, [n]               ; ecx <- n
      mov          eax, ecx               ; eax <- n
      shl          eax, 2                 ; eax <- 4n
      mov          [szer], eax            ; szer. wier. w bajtach

;    -------------------
;    -      mnoz!      -
;    -------------------

      mov          edi, [_C]
      shr          eax, 4                 ; eax <- n/4
                                          ; zlicza czworki kolumn w C

; -----------------------------------------
;    petla po czworkach kol. w C (i) <-----------------------------------
; -----------------------------------------                             |
ALIGN 16                                  ;                             |
full_col:                                 ;                             |
      mov          esi, [_A]              ;                             |
      mov          edx, [n]               ; edx <- n                    |
      push         edi                    ; pozycja w C                 |
; -----------------------------------------                             |
;       petla po wierszach w C (j)  <--------------------------------|  |
; -----------------------------------------                          |  |
ALIGN 16                                  ;                          |  |
full_row:                                 ;  zlicza wiersze w A      |  |
                                          ;                          |  |
                                          ;                          |  |
      mov          ecx, [n]               ; ecx <- n                 |  |
      shr          ecx, 2                 ; ecx <- n/4 = zlicza      |  |
                                          ;   czworki kolumn w A     |  |
                                          ;                          |  |
      mov          ebx, [_B]              ; B na 0 wiersz            |  |
      xorps        xmm7, xmm7             ; xmm7 = suma <- 0         |  |
      movaps       [edi], xmm7
; ----------------------------------------                           |  |
; - 4 kolumny w i-tym wierszu       <------------------------------  |  |
; ----------------------------------------                        |  |  |
ALIGN 16                                  ;                       |  |  |
four_col:                                 ;                       |  |  |
                                          ;                       |  |  |
      movaps       xmm0, [esi]            ; xmm0 <- [1 2 3 4]     |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      movaps       xmm1, xmm0             ;                       |  |  |
      shufps       xmm1, xmm1, 0          ; xmm1 <- [1 1 1 1]     |  |  |
      mulps        xmm1, [ebx]            ; xmm1 <- 1x[A B C D]   |  |  |
      addps        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
      movaps       xmm1, xmm0             ;                       |  |  |
      shufps       xmm1, xmm1, 01010101b  ; xmm1 <-   [2 2 2 2]   |  |  |
      mulps        xmm1, [ebx]            ; xmm1 <- 2x[E F G H]   |  |  |
      addps        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      movaps       xmm1, xmm0             ;                       |  |  |
      shufps       xmm1, xmm1, 10101010b  ; xmm1 <-   [3 3 3 3]   |  |  |
      mulps        xmm1, [ebx]            ; xmm1 <- 3x[I J K L]   |  |  |
      addps        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      movaps       xmm1, xmm0             ;                       |  |  |
      shufps       xmm1, xmm1, 11111111b  ; xmm1 <-   [4 4 4 4]   |  |  |
      mulps        xmm1, [ebx]            ; xmm1 <- 4x[M N O P]   |  |  |
      addps        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      add          esi, 16                ; +4 kolumny w A        |  |  |
                                          ;                       |  |  |
;   <-------------------------------------------------------------|  |  |
      dec          ecx                    ; czy juz koniec        |  |  |
      jne          four_col               ; wiersza w A?          |  |  |
;   <-------------------------------------------------------------|  |  |
                                          ;                          |  |
      addps        xmm7, [edi]
      movntps      [edi], xmm7            ; C <- suma dla 4 kol.     |  |
      add          edi, [szer]            ; nastepny wiersz w C      |  |
                                          ;                          |  |
;             <------------------------------------------------------|  |
      dec          edx                    ; czy to ostatni wiersz?   |  |
      jne          full_row               ;                          |  |
;             <------------------------------------------------------|  |
                                          ;                             |
      pop          edi                    ;  nast. czworka kolumn w C   |
      add          dword ptr [_B], 16     ;  nast. czworka kolumn w B
      add          edi, 16                ;                             |
;                 <-----------------------------------------------------|
      dec          eax                    ;  czy ostatnia kolumna?      |
      jne          full_col               ;                             |
;                 <-----------------------------------------------------|
                                          ;
      pop          edi                    ;
      pop          esi                    ;
      pop          ecx                    ;
      pop          ebx                    ;

      ret


mxmg ENDP


ALIGN 16
dmxmg PROC C, _C: DWORD, _A: DWORD, _B: DWORD, n: DWORD

      push         ebx
      push         ecx
      push         esi
      push         edi

      mov          ecx, [n]               ; ecx <- n
      mov          eax, ecx               ; eax <- n
      shl          eax, 2                 ; eax <- 4n
      mov          [szer], eax            ; szer. wier. w bajtach

;    -------------------
;    -      mnoz!      -
;    -------------------

      mov          edi, [_C]
      shr          eax, 4                 ; eax <- n/4
                                          ; zlicza czworki kolumn w C

; -----------------------------------------
;    petla po czworkach kol. w C (i) <-----------------------------------
; -----------------------------------------                             |
ALIGN 16                                  ;                             |
full_col:                                 ;                             |
      mov          esi, [_A]              ;                             |
      mov          edx, [n]               ; edx <- n                    |
      push         edi                    ; pozycja w C                 |
; -----------------------------------------                             |
;       petla po wierszach w C (j)  <--------------------------------|  |
; -----------------------------------------                          |  |
ALIGN 16                                  ;                          |  |
full_row:                                 ;  zlicza wiersze w A      |  |
                                          ;                          |  |
                                          ;                          |  |
      mov          ecx, [n]               ; ecx <- n                 |  |
      shr          ecx, 2                 ; ecx <- n/4 = zlicza      |  |
                                          ;   czworki kolumn w A     |  |
                                          ;                          |  |
      mov          ebx, [_B]              ; B na 0 wiersz            |  |
      xorpd        xmm7, xmm7             ; xmm7 = suma <- 0         |  |
      movapd       [edi], xmm7
; ----------------------------------------                           |  |
; - 4 kolumny w i-tym wierszu       <------------------------------  |  |
; ----------------------------------------                        |  |  |
ALIGN 16                                  ;                       |  |  |
four_col:                                 ;                       |  |  |
                                          ;                       |  |  |
      movapd       xmm0, [esi]            ; xmm0 <- [1 2]         |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      movapd       xmm1, xmm0             ;                       |  |  |
      shufpd       xmm1, xmm1, 0          ; xmm1 <- [1 1]         |  |  |
      mulpd        xmm1, [ebx]            ; xmm1 <- 1x[A B]       |  |  |
      addpd        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
      movapd       xmm1, xmm0             ;                       |  |  |
      shufpd       xmm1, xmm1, 01010101b  ; xmm1 <-   [2 2]       |  |  |
      mulpd        xmm1, [ebx]            ; xmm1 <- 2x[E F]       |  |  |
      addpd        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      movapd       xmm1, xmm0             ;                       |  |  |
      shufpd       xmm1, xmm1, 10101010b  ; xmm1 <-   [3 3]       |  |  |
      mulpd        xmm1, [ebx]            ; xmm1 <- 3x[I J]       |  |  |
      addpd        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      movapd       xmm1, xmm0             ;                       |  |  |
      shufpd       xmm1, xmm1, 11111111b  ; xmm1 <-   [4 4]       |  |  |
      mulpd        xmm1, [ebx]            ; xmm1 <- 4x[M N]       |  |  |
      addpd        xmm7, xmm1             ; xmm7 <- suma          |  |  |
      add          ebx, [szer]            ;                       |  |  |
                                          ;                       |  |  |
                                          ;                       |  |  |
      add          esi, 16                ; +4 kolumny w A        |  |  |
                                          ;                       |  |  |
;   <-------------------------------------------------------------|  |  |
      dec          ecx                    ; czy juz koniec        |  |  |
      jne          four_col               ; wiersza w A?          |  |  |
;   <-------------------------------------------------------------|  |  |
                                          ;                          |  |
      addpd        xmm7, [edi]
      movntpd      [edi], xmm7            ; C <- suma dla 4 kol.     |  |
      add          edi, [szer]            ; nastepny wiersz w C      |  |
                                          ;                          |  |
;             <------------------------------------------------------|  |
      dec          edx                    ; czy to ostatni wiersz?   |  |
      jne          full_row               ;                          |  |
;             <------------------------------------------------------|  |
                                          ;                             |
      pop          edi                    ;  nast. czworka kolumn w C   |
      add          dword ptr [_B], 16     ;  nast. czworka kolumn w B
      add          edi, 16                ;                             |
;                 <-----------------------------------------------------|
      dec          eax                    ;  czy ostatnia kolumna?      |
      jne          full_col               ;                             |
;                 <-----------------------------------------------------|
                                          ;
      pop          edi                    ;
      pop          esi                    ;
      pop          ecx                    ;
      pop          ebx                    ;

      ret


dmxmg ENDP

END