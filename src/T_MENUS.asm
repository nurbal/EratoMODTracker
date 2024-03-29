;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_menus.a
;               - ensemble de proc‚dures et de variables relatives … la
;                       double barre de menus...
;**************************************************************************

; appel de la suite du programme
jmp apres_t_menus

; variables
;**************************************************************************
offsets_textes_menus    dw 32 dup ?
offsets_commandes_menus dw 32 dup ?
x_textes_menus          db 64 dup ?
options_menus           db 2 dup ?
nb_options_menus        db 2 dup ?

; proc‚dures et macros
;**************************************************************************

; AFFICHE_MENUS (M+P)
; affiche les 2 menus en mettant en surbrillance les options choisies
;**************************************************************************
affiche_menus macro
call proc_affiche_menus
#em
proc_affiche_menus:
bloc1_vga 0,0,79,49
;cmp b cs:nb_options_menus[1],0
;je >p1
;bloc1_vga 0,22,79,43,1
;p1:
couleur_texte_vga 1
police_vga 1
mov ds,cs
mov cl,nb_options_menus[0]
mov ch,0
jcxz >p2        ; saut si pas d'options … afficher
mov bx,0
p1:
push cx
push bx
mov al,x_textes_menus[bx]
mov ah,0
gotoxy_vga ax,8
mov si,offsets_textes_menus[bx]
push ds
call proc_aff_chaine_vga
pop ds
pop bx
add bx,2
pop cx
loop p1
; affichage en surbrillance de l'option active
mov bl,options_menus[0]
cmp bl,0FFh     ; pas d'option choisie?
je >p2
mov bh,0
shl bx,1
mov al,x_textes_menus[bx]
mov cl,x_textes_menus[bx+1]
mov ah,0
mov ch,0
gotoxy_vga ax,8
push bx
dec ax
inc cx
bloc2_vga ax,4,cx,24
pop bx
mov ds,cs
mov si,offsets_textes_menus[bx]
couleur_texte_vga 12
call proc_aff_chaine_vga
p2:
; affichage du second menu
mov ds,cs
cmp b nb_options_menus[1],0     ; menu 2 vide?
if e ret
; affichage du second menu
couleur_texte_vga 1
mov ds,cs
mov cl,nb_options_menus[1]
mov ch,0
mov bx,32
p1:
push cx
push bx
mov al,x_textes_menus[bx]
mov ah,0
gotoxy_vga ax,29
mov si,offsets_textes_menus[bx]
push ds
call proc_aff_chaine_vga
pop ds
pop bx
add bx,2
pop cx
loop p1
; affichage en surbrillance de l'option active
mov bl,options_menus[1]
cmp bl,0FFh     ; pas d'option choisie?
if e ret
mov bh,0
shl bx,1
add bx,32
mov al,x_textes_menus[bx]
mov cl,x_textes_menus[bx+1]
mov ah,0
mov ch,0
gotoxy_vga ax,29
push bx
dec ax
inc cx
bloc2_vga ax,25,cx,45
pop bx
mov ds,cs
mov si,offsets_textes_menus[bx]
couleur_texte_vga 12
call proc_aff_chaine_vga
ret

; MENU1 adresse,'option',x1,x2, ... (M)
; construit le menu 1
;**************************************************************************
menu1 macro
mov ds,cs
mov bx,0
#rx1l
mov w offsets_commandes_menus[bx],offset #x
jmp >m1
m2 db #ax,0
m1:
mov w offsets_textes_menus[bx],offset m2
mov b x_textes_menus[bx],#aax
mov b x_textes_menus[bx+1],#aaax
add bx,2
#e4
shr bx,1
mov nb_options_menus[0],bl
mov b options_menus[0],0FFh
#em

; MENU2 adresse,'option',x1,x2, ... (M)
; construit le menu 2
;**************************************************************************
menu2 macro
mov ds,cs
mov bx,32
#rx1l
mov w offsets_commandes_menus[bx],offset #x
jmp >m1
m3 db #ax,0
m1:
mov w offsets_textes_menus[bx],offset m3
mov b x_textes_menus[bx],#aax
mov b x_textes_menus[bx+1],#aaax
add bx,2
#e4
sub bx,32
shr bx,1
mov nb_options_menus[1],bl
mov b options_menus[1],0FFh
#em

; ANNULE_MENU2 (M) annule le menu 2
;**************************************************************************
annule_menu2 macro
mov b cs:nb_options_menus[1],0
#em

; SOURIS_MENUS (M+P) et SOURIS_MENUS_2 (M+P)
; utilise la souris et attend le choix de l'utilisateur; sinon, retour
;**************************************************************************
souris_menus macro
call proc_souris_menus
#em
proc_souris_menus:
mouse_on
mouse_clic
push cx,dx
mouse_off
pop dx,cx
jmp proc_souris_menus_2
souris_menus_2 macro
call proc_souris_menus_2
#em
proc_souris_menus_2:
cmp dx,50
if ae ret       ; retour si pas dans les menus
cmp dx,25
jb >p1
cmp b cs:nb_options_menus[1],0
je >p8          ; retour si dans le second menu vide, aprŠs avoir lach‚ la souris
p1:
mov ds,cs
mov ax,cx
shr ax,1
shr ax,1
shr ax,1        ; al= caractŠre point‚
mov cl,nb_options_menus[0]
cmp dx,25
if ae mov cl,nb_options_menus[1]
mov ch,0        ; cx = nombre d'options … tester
mov bx,0
cmp dx,25       ; second menu ?
if ae mov bx,32
; d‚but des tests
b1:
cmp al,x_textes_menus[bx]
jb >p8  ; aucune option n'est point‚e
cmp al,x_textes_menus[bx+1]
ja >b2
push bx
mov al,bl
and al,1Fh
cmp al,bl
pushf
shr al,1
popf
jne >l1
cmp al,options_menus[0]
if e pop bx
je >p8
mov options_menus[0],al
jmp >l2
l1:
cmp al,options_menus[1]
if e pop bx
je >p8
mov options_menus[1],al
jmp >l2
b2:
add bx,2
loop b1
;jmp >p9
p8:
lache_souris
p9:
ret
l2:
; affichage des options actives
police_vga 1
mov bl,options_menus[0]
cmp bl,0FFh     ; pas d'option choisie?
je >p2
mov bh,0
shl bx,1
mov al,x_textes_menus[bx]
mov cl,x_textes_menus[bx+1]
mov ah,0
mov ch,0
gotoxy_vga ax,8
push bx
dec ax
inc cx
bloc2_vga ax,4,cx,24
pop bx
mov ds,cs
mov si,offsets_textes_menus[bx]
couleur_texte_vga 12
call proc_aff_chaine_vga
p2:
mov bl,options_menus[1]
cmp bl,0FFh     ; pas d'option choisie?
je >p2
mov bh,0
shl bx,1
add bx,32
mov al,x_textes_menus[bx]
mov cl,x_textes_menus[bx+1]
mov ah,0
mov ch,0
gotoxy_vga ax,29
push bx
dec ax
inc cx
bloc2_vga ax,25,cx,45
pop bx
mov ds,cs
mov si,offsets_textes_menus[bx]
call proc_aff_chaine_vga
p2:
lache_souris
pop bx
pop ax
mov ax,offsets_commandes_menus[bx]
push ax
ret             ; saut … l'endroit sp‚cifi‚ par le menu

; CLS_MENUS (M+P)
; efface tout l'‚cran sauf les menus, et actualise ces menus
;**************************************************************************
cls_menus macro
call proc_cls_menus
#em
proc_cls_menus:
rectangle_vga 0,50,79,479,0
affiche_menus
ret



apres_t_menus:



