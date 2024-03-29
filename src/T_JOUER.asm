; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_jouer.a
;**************************************************************************

menu_jouer:

; lance la musique
joue_mod

apres_menu_jouer:
tempo_vga

; d‚finit le menu principal
menu2 rew,'<<REW',2,6, play,'PLAY>',9,13, ff,'FF>>',16,19, stop,'STOPþ',22,26, pause,'PAUSEþþ',29,35
mov b cs:options_menus[1],1
cmp b cs:mod_status,0
if e mov b cs:options_menus[1],3
cmp b cs:mod_status,1
if e cmp b cs:deja_dans_int_mod,1
if e mov b cs:options_menus[1],4
affiche_menus

; affichage de l'‚cran principal:
bloc1_vga 0,50,79,479
bloc2_vga 1,100,32,243
bloc2_vga 34,100,65,243 ; samples
bloc2_vga 67,100,78,243 ; spectre
bloc2_vga 14,260,75,403 ; notes
bloc2_vga 6,415,73,466  ; "bonhomme"
plans_ecriture_vga 1
mov cx,8
mov es,0A000h
mov di,22015
b1:
push cx
mov cx,60
mov al,18h
cld
rep stosb
add di,20
mov cx,60
rep stosb
add di,1140
pop cx
loop b1
mov cx,8
mov es,0A000h
mov di,21935
b1:
push cx
mov cx,5
b2:
mov b es:[di],18h
mov b es:[di+80],3Ch
mov b es:[di+160],3Ch
mov b es:[di+240],18h
add di,12
loop b2
add di,1220
pop cx
loop b1
police_vga 2
couleur_texte_vga 1
gotoxy_vga 4,268
aff_chaine_vga 'voie 1 :'
gotoxy_vga 4,284
aff_chaine_vga 'voie 2 :'
gotoxy_vga 4,300
aff_chaine_vga 'voie 3 :'
gotoxy_vga 4,316
aff_chaine_vga 'voie 4 :'
gotoxy_vga 4,332
aff_chaine_vga 'voie 5 :'
gotoxy_vga 4,348
aff_chaine_vga 'voie 6 :'
gotoxy_vga 4,364
aff_chaine_vga 'voie 7 :'
gotoxy_vga 4,380
aff_chaine_vga 'voie 8 :'
gotoxy_vga 3,76
aff_chaine_vga 'position:    / '
mov al,cs:nb_positions
mov ah,0
call proc_aff_word_vga
gotoxy_vga 25,76
aff_chaine_vga 'pattern:    / '
mov al,cs:nb_patterns
mov ah,0
call proc_aff_word_vga
gotoxy_vga 47,76
aff_chaine_vga 'note:    / '
mov ax,64
call proc_aff_word_vga
gotoxy_vga 3,59
aff_chaine_vga 'Nom du module: '
couleur_texte_vga 4
mov ds,cs
mov si,offset titre_mod
call proc_aff_chaine_vga
couleur_texte_vga 1
gotoxy_vga 40,59
aff_chaine_vga 'Fichier: '
couleur_texte_vga 4
mov ds,cs
mov si,offset nom_fichier
call proc_aff_chaine_vga
; affichage des noms de samples1
police_vga 0
couleur_texte_vga 9
mov ds,cs
mov si,offset noms_samples
mov cx,16
gotoxy_vga 11,108
b1:
push cx,si,ds
call proc_aff_chaine_vga
pop ds,si,cx
add si,22
mov w cs:x_texte_vga,11
add w cs:y_texte_vga,8
loop b1
mov cx,15
gotoxy_vga 44,108
b1:
push cx,si,ds
call proc_aff_chaine_vga
pop ds,si,cx
add si,22
mov w cs:x_texte_vga,44
add w cs:y_texte_vga,8
loop b1

; initialisation des variables de notes:
mov es,cs
mov di,offset donnees_voix_menu_jouer
mov cx,8
b1:
push cx
mov ax,0
cld
stosw
stosw
mov ax,0FFFFh
stosw
pop cx
loop b1

; initialisation des variables d'instruments:
mov di,offset donnees_ins_menu_jouer
mov es,cs
mov cx,8
mov al,0FFh
cld
rep stosb

; on n'affiche que si il y a de la musique!
cmp b cs:mod_status,1
je >b2
b1:
souris_menus
jmp b1
b2:

boucle_menu_jouer:
mouse_on
b1:
mov al,cs:chrono_note_mod
cmp al,cs:chrono_menu_jouer
jne >l1
push ax
mouse_state
pop ax
cmp bx,0
jne >l1
cmp b cs:mod_status,0
jne b1
mouse_off
jmp apres_menu_jouer
l1:
mov cs:chrono_menu_jouer,al     ; chrono transf‚r‚

; surveillance de l'utilisateur:
mouse_state
cmp bx,0
je >l1
mouse_off
souris_menus_2    ; l'utilisateur se manifeste !
mouse_on
l1:

; on cache la souris
mouse_hide 1,76,78,472

; affichage des donn‚es note, patterns, position
cmp b cs:chrono_menu_jouer,0
if ne jmp apres_aff_note_menu_jouer
;mouse_hide 13,76,55,91
police_vga 2
couleur_texte_vga 4
rectangle_vga 13,76,15,91,7
gotoxy_vga 13,76
mov al,cs:num_position_mod
mov ah,0
push ax
call proc_aff_word_vga
rectangle_vga 34,76,36,91,7
gotoxy_vga 34,76
pop bx
mov al,cs:table_positions[bx]
mov ah,0
call proc_aff_word_vga
rectangle_vga 53,76,55,91,7
gotoxy_vga 53,76
mov al,cs:num_note_mod
mov ah,0
call proc_aff_word_vga
couleur_texte_vga 10
police_vga 1
; effacement de l'ancien petit bonhomme
plans_ecriture_vga 15
mov es,0A000h
mov ax,33687
mov bl,cs:num_note_menu_jouer
and bl,63
add al,bl
adc ah,0
mov di,ax
mov cx,36       ; 36 lignes … effacer
cld
b1:
push cx
mov al,0
mov cx,3
rep stosb
add di,77       ; ligne suivante
pop cx
loop b1
; affichage du petit bonhomme
mov al,cs:num_note_mod
mov cs:num_note_menu_jouer,al
mov ah,0
add al,7
gotoxy_vga ax,421       ; en position
mov al,cs:num_note_menu_jouer
;shr al,1
and al,0Fh
mov ah,9
mul ah
add ax,offset bonhomme_menu_jouer
mov si,ax       ; si pointe sur le bonhomme … afficher
mov ds,cs
mov cx,3
b1:
push cx
mov cx,3
b2:
cld
lodsb
push cx,si,ds
call proc_aff_carac_vga
pop ds,si,cx
loop b2
sub w cs:x_texte_vga,3
add w cs:y_texte_vga,12
pop cx
loop b1

; affichage des num‚ros de samples
police_vga 0
couleur_texte_vga 14    ; jaune: comme les notes
mov si,offset donnees_voix_mod
mov di,offset donnees_ins_menu_jouer
mov ah,0        ; num‚ro de la voix
mov cx,8
boucle_aff_ins_menu_jouer:
push ax,cx,si,di
cmp b cs:[si],0
je >l1
; il y a un instrument actif
mov al,cs:[si+1]
cmp al,cs:[di]
if e jmp fin_aff_ins_menu_jouer  ; ok: no problem (instrument d‚j… affich‚)
jmp >l3
; pas d'instrument actif
l1:
cmp b cs:[di],0FFh
;if e
jmp fin_aff_ins_menu_jouer ; ok, c'est comme pr‚vu
; affichage du num‚ro de voix … c“t‚ du sample
l3:

; effacement de l'ancien
push ax,di
mov bh,0
mov bl,ah       ; BX=num‚ro de la voix
mov al,cs:[di]
cmp al,0FFh
je >l2
mov di,2
cmp al,16
if ae mov di,35
add di,bx
and al,0Fh
mov ah,40
mul ah
add ax,540
add ax,0A000h
mov es,ax
plans_ecriture_vga 14
mov cx,8
b1:
mov b es:[di],0
add di,80
loop b1
l2:
pop di,ax
; ah = num‚ro voix

l1:
; affichage du nouveau
mov bl,ah
mov bh,0        ; bx = num‚ro voix
cmp b cs:[si],0
if e mov b cs:[di],0FFh ; voix d‚sactiv‚e!
if e jmp fin_aff_ins_menu_jouer ; ... donc on ne l'affiche pas
mov al,cs:[si+1]
mov cs:[di],al          ; num‚ro de l'instrument transmis
mov cx,2
cmp al,16
if ae mov cx,35
add cx,bx       ; cx = x
mov cs:x_texte_vga,cx
and al,0Fh
mov ah,8
mul ah
add ax,108      ; ax = y
mov cs:y_texte_vga,ax
mov ax,bx
inc ax
call proc_aff_word_vga  ; num‚ro affich‚!

; fin de l'affichage du num‚ro du sample:
fin_aff_ins_menu_jouer:
pop di,si,cx,ax
add si,16
inc di
inc ah
dec cx
jcxz >l1
jmp boucle_aff_ins_menu_jouer
l1:
apres_aff_note_menu_jouer:


; affichage du spectre
mov ax,9000h
mov ds,ax
mov si,cs:ofs_buffer_mod
plans_ecriture_vga 10
plan_lecture_vga 1
mov di,68
mov cx,10
b1:
push cx
mov es,0A21Ch
push di
mov cx,128
b3:
mov b es:[di],0
add di,80
loop b3
pop di
mov bl,80h      ; masque!
mov cx,8
b2:
push cx
mov al,ds:[si]  ; octet source!
inc si
shr al,1        ; divis‚ par 2
mov ah,5
mul ah
add ax,0A21Ch
mov es,ax       ; es=adresse seg ligne
or es:[di],bl
shr bl,1
pop cx
loop b2
inc di
pop cx
loop b1


; affichage des jolies petites notes
;mouse_hide 15,268,77,395
plans_ecriture_vga 14   ; couleur jaune (par d‚faut)
mov cx,8
mov si,offset donnees_voix_mod
mov di,offset donnees_voix_menu_jouer
mov dx,0        ; dx=num‚ro voix
b1:
push cx
push dx
cmp b cs:[si],0 ; inactivit‚?
je >l1
cmp b cs:[si+7],0
jne >l2
mov ax,cs:[di+4]
cmp ax,cs:[si+4]        ; nouvelle note ?
if a call nouvelle_note_menu_jouer
l2:
mov ax,cs:[si+4]
mov cs:[di+4],ax
mov ax,cs:[di+1]
cmp ax,cs:[si+2]        ; note modifi‚e ?
if ne call nouvelle_note_menu_jouer
;cmp b cs:[si+7],1
;if e mov b cs:[di],24
mov ax,cs:[si+2]
mov cs:[di+1],ax
l1:
call affiche_note_menu_jouer
add si,16
add di,6
pop dx
inc dx  ; voix suivante
pop cx
loop b1
;mouse_on

jmp boucle_menu_jouer
nouvelle_note_menu_jouer:
; effacement de l'ancienne note
mov es,0A53Ch
mov ax,1280
push dx
mul dx
pop dx
add ax,15
add al,cs:[di+3]
adc ah,0
mov bx,ax
mov cx,16
b1:
mov b es:[bx],0
add bx,80
loop b1
; d‚termination de la nouvelle note
mov ax,cs:[si+2]
mov bx,-2
mov cx,60
b1:
add bx,2
cmp ax,cs:table_notes_mod[bx]
if b loop b1
shr bx,1
mov cs:[di+3],bl        ; num‚ro note transf‚r‚
; mise … jour du chrono
mov b cs:[di],32
ret
affiche_note_menu_jouer:
; effacement de l'ancienne note
mov es,0A53Ch
mov ax,1280
push dx
mul dx
pop dx
add ax,15
add al,cs:[di+3]
adc ah,0
mov bx,ax
mov cx,16
b1:
mov b es:[bx],0
add bx,80
loop b1
; affichage de la note
sub bx,1280
mov al,cs:[di]  ; al=chrono
cmp b cs:[di],0
je >l1
cmp b cs:[di],16
ja >l2
cmp b cs:[si],1
je >l1
l2:
dec b cs:[di]   ; diminution du curseur
l1:
push dx
push cx
mov cx,2
shr al,cl       ; al=0 … 8
pop cx
push ax
mov ah,8
sub ah,al
mov al,80
mul ah
mov dx,ax       ; d‚callage
pop ax
mov cl,al
push cx
mov al,0FFh
shr cl,1
mov ch,0Fh
shr ch,cl
xor al,ch
mov ch,0F0h
shl ch,cl
xor al,ch
pop cx
shl cl,1
mov ch,0        ; r‚p‚tition
add bx,dx       ; d‚callage effectu‚
pop dx
cmp cx,0
if e ret
b1:
mov b es:[bx],al
add bx,80
loop b1
ret

; variable n‚cessaires … la repr‚sentation graphique de la musique:
chrono_menu_jouer       db ?
donnees_voix_menu_jouer db 48 dup ?
donnees_ins_menu_jouer  db 8 dup ?

; petit bonhomme:
num_note_menu_jouer     db ?
bonhomme_menu_jouer:
db '  O'
db '/( '
db ' >>'

db '  O'
db ' /Í'
db '/> '

db '\< '
db '  \'
db ' /O'

db '\ /'
db ' ³ '
db '<O>'

db '  >'
db ' ³Ù'
db 'O\\'

db 'O  '
db '>\>'
db ' <<'

db '³O³'
db ' ³ '
db '/ \'

db '<O>'
db ' ³ '
db '/ \'

db ' O '
db 'Ù³À'
db '/ \'

db ' O '
db '/³\'
db '/ \'

db ' O '
db '<³>'
db '/ \'

db ' O '
db '/³<'
db ' >\'

db ' O/'
db '/³ '
db ' >>'

db ' O³'
db 'Ù³ '
db '< >'

db ' O '
db 'Ù³À'
db '/ \'

db ' O/'
db '<³ '
db '/ >'


; PLAY (JMP)
; lance la musique
;*****************************************************************
play:
affiche_menus
joue_mod
cli
mov b cs:deja_dans_int_mod,0    ; interruption d‚masq‚e
sti
tempo_vga
jmp boucle_menu_jouer

; PAUSE (JMP)
; pause de la musique
;*****************************************************************
data_pause      db 2 dup ?
pause:
cli
mov b cs:deja_dans_int_mod,1    ; interruption masq‚e
sti
mov es,9000h
mov di,0BC90h
mov cx,440
mov ax,8080h
cld
rep stosw       ; buffers effac‚s
affiche_menus
jmp boucle_menu_jouer

; STOP (JMP)
; stoppe la musique
;*****************************************************************
stop:
affiche_menus
stop_mod
jmp boucle_menu_jouer

; REW (JMP)
; revient en arriŠre
;*****************************************************************
rew:
mov al,cs:num_position_mod
dec al
cmp al,0
if l mov al,0
mov cs:num_position_mod,al
mov b cs:num_note_mod,0
mov b cs:chrono_note_mod,0
mov b cs:options_menus[1],1
affiche_menus
police_vga 2
couleur_texte_vga 4
rectangle_vga 13,76,15,91,7
gotoxy_vga 13,76
mov al,cs:num_position_mod
xor ah,ah
call proc_aff_word_vga
jmp boucle_menu_jouer

; FF (JMP)
; avance rapide
;*****************************************************************
ff:
mov al,cs:num_position_mod
inc al
cmp al,cs:nb_positions
if ge mov al,cs:nb_positions
mov cs:num_position_mod,al
mov b cs:num_note_mod,0
mov b cs:chrono_note_mod,0
mov b cs:options_menus[1],1
affiche_menus
police_vga 2
couleur_texte_vga 4
rectangle_vga 13,76,15,91,7
gotoxy_vga 13,76
mov al,cs:num_position_mod
xor ah,ah
call proc_aff_word_vga
jmp boucle_menu_jouer

