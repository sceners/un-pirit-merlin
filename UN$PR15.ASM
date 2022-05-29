; Un-$pirit v0.1 (c) MERLiN // Delirium Tremens 1998
.386p
cseg            segment         use16
                assume          cs:cseg,ds:cseg,es:cseg
                org             100h
begin           proc
                lea             dx,id
                call            view
                mov             si,81h
                lodsb
                cmp             al,13
                jz              bad_usage
_keep_scan:
                lodsb
                cmp             al,32
                jz              _keep_scan
                dec             si
                push            si si si si
                pop             di
                mov             al,13
                repne           scasb
                dec             di
                mov             ax,2400h
                stosw

                mov             seg01,cs

                mov             bh,10h
                mov             ah,4ah
                int             21h

                pop             dx
                mov             ax,3d02h
                int             21h
                jnc             c1
                lea             dx,not_found
view_n_exit:
                call            view
                mov             ah,4ch
                int             21h
c1:
                xchg            bx,ax

                mov             ah,3eh
                int             21h
                lea             dx,process
                call            view
                pop             dx
                call            view
                push            0
                pop             ds
                mov             word ptr ds:[1*4],offset int1
                mov             word ptr ds:[1*4+2],cs
                mov             eax,ds:[16h*4]
                mov             word ptr ds:[16h*4],offset int16
                mov             word ptr ds:[16h*4+2],cs
                push            cs
                pop             ds
                mov             old16,eax
                pop             dx
                mov             ax,4b00h
                lea             bx,params
                int             21h

                mov             eax,old16
                push            0
                pop             ds
                mov             dword ptr ds:[16h*4],eax
                push            cs
                pop             ds
un05:
                mov             ah,1
                int             16h
                jz              _done
                mov             ah,0
                int             16h
                jmp             un05
_done:
                lea             dx,done
                jmp             view_n_exit
int16:
                cmp             ah,1
                jnz             RunInt16
                push            bp ds si ax
                mov             bp,sp
                lds             si,[bp+8]
                mov             al,[si+46h]
                cmp             al,0bfh
                jz              ComFile
                cmp             al,0abh
                jnz             _NotSpirit
; EXE-file
                mov             byte ptr [si+(226h-1e0h)],90h
                mov             byte ptr [si+(27dh-1e0h)],20h
                push            eax
                mov             eax,[si+11fh]
                mov             dword ptr cs:sz,eax
                pop             eax
un01:
                mov             byte ptr [si],0ebh
                mov             cs:PrgSeg,ds
                mov             cs:PrgOfs,si
un04:
                pushf
                pop             ax
                or              ah,1
                push            ax
                popf
_NotSpirit:
                pop             ax si ds bp
RunInt16:
                db              0eah
old16           dd              ?
PrgOfs          dw              ?
PrgSeg          dw              ?
ComFile:
                mov             byte ptr [si+37h],90h
                mov             byte ptr [si+64h],20h
                mov             ax,[si+5dh]
                shl             ax,1
                mov             cs:sz,ax
                jmp             un01
int1:
                push            bp
                mov             bp,sp
                push            ds si eax
                lds             si,[bp+2]
                lodsd
                cmp             ax,0e6ffh
                jz              got_it
                cmp             eax,0683b78bh
                jz              GotAnExe
                pop             eax si ds
go_back:
                pop             bp
                iret
; Time to unpack
GotAnExe:
                push            cs
                pop             ds
                lea             dx,_out2
                xor             cx,cx
                mov             ah,3ch
                int             21h
                xchg            bx,ax

                lds             si,dword ptr cs:PrgOfs
                mov             cx,[si+127h]
                mov             word ptr cs:(hdr+6),cx
                mov             eax,dword ptr cs:sz
                add             eax,28
                shl             cx,2
                mov             dx,cx
                add             dx,28
                and             dl,15
                jz              un03
                mov             dh,16
                sub             dh,dl
                mov             cs:bytes2add,dh
                movzx           edx,dh
                add             word ptr cs:(hdr+8),dx
                add             eax,edx
un03:
                mov             edi,512
                xor             edx,edx
                div             edi
                inc             ax
                mov             word ptr cs:(hdr+2),dx  ; bytes in last page
                mov             word ptr cs:(hdr+4),ax  ; total pages
                add             word ptr cs:(hdr+8),cx
                movzx           ecx,cx
                sub             dword ptr cs:sz,ecx
                push            cx
                mov             eax,[si+129h]
                mov             dword ptr cs:(hdr+14h),eax
                mov             eax,[si+12dh]
                mov             dword ptr cs:(hdr+14),eax
                push            ds
                push            cs
                pop             ds
                shr             word ptr ds:(hdr+8),4
                mov             ah,40h
                lea             dx,hdr
                mov             cx,28
                int             21h
                pop             ds cx
                add             cx,word ptr cs:bytes2add
                lds             dx,[si+123h]
                mov             ah,40h
                int             21h
                push            bx
                mov             ah,62h
                int             21h
                add             bx,16
                mov             ds,bx
                xor             dx,dx
                pop             bx
                mov             esi,dword ptr cs:sz
                call            write
                jmp             un02
got_it:
                push            cs
                pop             ds
                lea             dx,_out
                xor             cx,cx
                mov             ah,3ch
                int             21h
                xchg            bx,ax
                mov             ah,40h
                mov             ds,[bp+4]
                mov             dx,256
                mov             cx,cs:sz
                int             21h
un02:
                mov             ah,3eh
                int             21h
                mov             ah,4ch
                int             21h
bad_usage:
                lea             dx,usage
                jmp             view_n_exit

write           proc 
                push           esi
                push           ds
wr3:
                cmp            esi,0ffffh
                ja short       wr1
                mov            ah,40h
                mov            cx,si   
                int            21h
                jmp short      wr_exit
wr1:
                mov            ah,40h
                mov            cx,0ffffh
                int            21h
                mov            dx,ax
                mov            ah,40h
                mov            cx,1
                int            21h
                sub            esi,010000h
                or             esi,esi
                jz             short wr_exit
wr2:
                mov            ax,ds
                add            ax,1000h
                mov            ds,ax
                xor            dx,dx
                jmp short      wr3
wr_exit:
                pop            ds
                pop            esi
                retn
write           endp
;
;
view:
                pusha
                mov             si,dx
                xor             bx,bx
                mov             ah,14
vw02:
                lodsb
                cmp             al,0
                jnz             vw01
                popa
                retn
vw01:
                int             10h
                jmp             vw02
;
;
_out            db              'CRACKED.COM',0
_out2           db              'CRACKED.EXE',0
id              db              'UN$pirit v0.1, Unpacks files crypted with [$pirit v1.5 by Night $pirit]',13,10
                db              'Copyright (c) 1998 by MERLiN // Delirium Tremens Group',13,10,0
usage           db              13,10,'Usage: UN$pirit crypted_file',13,10,0
not_found       db              'File not found',0
process         db              'Processing file: ',0
done            db              '... Done',0
bytes2add       db              0
                db              0
hdr             db              'MZ'       ; 00
                dd              ?          ; 02 reserved for pages
                dw              ?          ; 06 relocations
                dw              28         ; 08 header size
                dw              ?          ; 0a minimum memory to allocate
                dw              -1         ; 0c maximum memory
                dd              ?          ; 0e SS:SP
                dw              ?          ; 12 checksum
                dd              ?          ; 14 CS:IP
                dw              1ch        ; 18 offset of relocation table
                dw              0          ; 1a overlay number
params:
          dw            0
          dw            offset param01
seg01     dw            ?
          dd            ?
          dd            ?
          dd            ?
          dd            ?
param01   dd            ?
sz              dw              ?
area_4_reading:
begin           endp
cseg            ends
                end             begin