;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_option.a
; (menu des options)
;**************************************************************************

; d‚but du programme
;**************************************************************************
menu_options:

; d‚finit le menu des options
menu2 option_affichage,'COULEURS',2,9, option_sb,'SOUND-BLASTER',12,24, sauve_config,'SAUVER',72,77
cls_menus

b1:
souris_menus
jmp b1

; sch‚mas de couleurs pr‚d‚finis:
palettes_couleurs:
; standard:
db 0,0,0, 0,0,42, 0,42,0, 0,42,42, 42,0,0, 42,0,42, 42,21,0, 42,42,42
db 21,21,21, 21,21,63, 21,63,21, 21,63,63, 63,21,21, 63,21,63, 63,63,21, 63,63,63
; monochrome:
db 0,0,0, 14,14,14, 14,14,14, 28,28,28, 14,14,14, 28,28,28, 21,21,21, 42,42,42
db 21,21,21, 35,35,35, 35,35,35, 49,49,49, 35,35,35, 49,49,49, 49,49,49, 63,63,63
; sable:
db 0,0,17, 0,0,42, 0,42,0, 0,42,42, 42,0,0, 42,0,42, 42,21,0, 49,42,37
db 28,21,16, 21,21,63, 21,63,21, 21,63,63, 63,21,21, 63,21,63, 63,63,21, 63,60,57
; bleu:
db 0,0,22, 0,0,42, 0,42,0, 0,42,42, 42,0,0, 42,0,42, 42,21,0, 37,41,53
db 21,21,36, 21,21,63, 21,63,21, 21,63,63, 63,21,21, 63,21,63, 63,63,21, 48,55,63
; oc‚an:
db 0,0,0, 0,28,42, 0,42,0, 0,42,42, 42,0,28, 42,0,42, 42,21,0, 33,50,49
db 21,28,30, 21,21,63, 21,55,48, 21,63,63, 63,9,38, 63,21,63, 63,63,21, 49,63,63
; invers‚:
db 63,63,63, 63,63,21, 63,21,63, 63,21,21, 21,63,63, 21,63,21, 21,42,63, 21,21,21
db 42,42,42, 42,42,0, 42,0,42, 42,0,0, 0,42,42, 0,42,0, 0,0,42, 0,0,0
noms_palettes_couleurs  db ' Standard ',0
                        db 'Monochrome',0
                        db '  Sable   ',0
                        db '   Bleu   ',0
                        db '  Oc‚an   ',0
                        db ' Invers‚  ',0

; config des couleurs
;**************************************************************************
couleur_modifiee        db 1
option_affichage:
cls_menus
; affichage de l'‚cran de controle des couleurs
bloc1_vga 4,90,75,439
bloc1_vga 22,110,57,139
police_vga 2
gotoxy_vga 27,118
couleur_texte_vga 4
aff_chaine_vga 'Configuration des Couleurs'
couleur_texte_vga 1
option_affichage_2:
; affichage des blocs (palette)
mov cx,4
mov ax,8
b1:
push cx
mov cx,4
mov bx,160
b2:
push cx
mov cx,ax
add cx,6
mov dx,bx
add dx,55
push ax,bx
bloc1_vga ax,bx,cx,dx
pop bx,ax
pop cx
add bx,64
loop b2
pop cx
add ax,8
loop b1
; affichage du bloc de couleur modifiee
mov al,cs:couleur_modifiee
mov ah,0
mov bx,ax
and ax,12
and bx,3
shl ax,1
add ax,8
mov cl,6
shl bx,cl
add bx,160
mov cx,ax
add cx,6
mov dx,bx
add dx,55
bloc3_vga ax,bx,cx,dx
; affichage des couleurs (palette)
mov cx,4
mov ax,9
mov dl,0
b1:
push cx
mov cx,4
mov bx,168
b2:
push cx
mov cx,ax
add cx,4
mov si,bx
add si,39
push ax,bx,dx
rectangle_vga ax,bx,cx,si,dl
pop dx,bx,ax
pop cx
add bx,64
inc dl
loop b2
pop cx
add ax,8
loop b1
; affichage de la partie droite de l'‚cran: curseurs et t‚moin
bloc2_vga 46,160,65,269
mov al,cs:couleur_modifiee
rectangle_vga 47,168,64,261,al
bloc1_vga 46,280,49,309
bloc1_vga 54,280,57,309
bloc1_vga 62,280,65,309
gotoxy_vga 47,287
aff_chaine_vga 'R:'
gotoxy_vga 55,287
aff_chaine_vga 'V:'
gotoxy_vga 63,287
aff_chaine_vga 'B:'
call proc_affiche_curseur_r
call proc_affiche_curseur_v
call proc_affiche_curseur_b
; affichage des 6 palettes pr‚d‚finies en bas
couleur_texte_vga 1
police_vga 2
mov cx,6
mov si,offset noms_palettes_couleurs
mov ax,4
mov dx,5
mov bx,15
b1:
push ax,bx,cx,dx,si
gotoxy_vga dx,457
push si
bloc1_vga ax,450,bx,479
pop si
mov ds,cs
call proc_aff_chaine_vga
pop si,dx,cx,bx,ax
add ax,12
add bx,12
add dx,12
add si,11
loop b1
; appel du menu
b1:
souris_menus
; tests de zone ‚cran
cmp dx,450
jb >l1
cmp cx,32
jb b1
cmp cx,607
ja b1
; choix d'une palette pr‚d‚finie
call proc_choix_palette
jmp b1
l1:
cmp cx,64
jb b1
cmp cx,528
jae b1
cmp dx,408
jae b1
cmp dx,160
jb b1
cmp cx,312
jb >l1          ; changement de couleur
cmp cx,368
jb b1
cmp dx,320
jb b1
cmp dx,407
ja b1
cmp dx,396
if a mov dx,396
cmp dx,333
if b mov dx,333
cmp cx,400
jb >l2          ; R
cmp cx,432
jb b1
cmp cx,464
jb >l3          ; V
cmp cx,496
jb b1
jmp l4_modif_couleur
; changement de couleur
l1:
mov ax,cx
mov cl,6
sub dx,160
sub ax,64
shr ax,cl
shr dx,cl
shl ax,1
shl ax,1
add al,dl
mov cs:couleur_modifiee,al
lache_souris
jmp option_affichage_2
; modif. R
l2:
mov ax,396
sub ax,dx       ; al=r
mov bl,cs:couleur_modifiee
shl bl,1
add bl,cs:couleur_modifiee
mov bh,0
cmp b cs:palette[bx],al
if e jmp b1
mov cs:palette[bx],al
tempo_vga
active_palette
call proc_affiche_curseur_r
jmp b1
; modif. V
l3:
mov ax,396
sub ax,dx       ; al=v
mov bl,cs:couleur_modifiee
shl bl,1
add bl,cs:couleur_modifiee
mov bh,0
cmp b cs:palette[bx+1],al
if e jmp b1
mov cs:palette[bx+1],al
tempo_vga
active_palette
call proc_affiche_curseur_v
jmp b1
; modif. B
l4_modif_couleur:
mov ax,396
sub ax,dx       ; al=b
mov bl,cs:couleur_modifiee
shl bl,1
add bl,cs:couleur_modifiee
mov bh,0
cmp b cs:palette[bx+2],al
if e jmp b1
mov cs:palette[bx+2],al
tempo_vga
active_palette
call proc_affiche_curseur_b
jmp b1


proc_affiche_curseur_r:
rectangle_vga 46,325,49,403,7
bloc2_vga 47,321,48,407
mov al,cs:couleur_modifiee
mov bl,al
shl al,1
add bl,al
mov bh,0
mov ax,63
sub al,cs:palette[bx]
add ax,325
mov bx,ax
add bx,15
bloc1_vga 46,ax,49,bx
ret
proc_affiche_curseur_v:
rectangle_vga 54,325,57,403,7
bloc2_vga 55,321,56,407
mov al,cs:couleur_modifiee
mov bl,al
shl al,1
add bl,al
mov bh,0
mov ax,63
sub al,cs:palette[bx+1]
add ax,325
mov bx,ax
add bx,15
bloc1_vga 54,ax,57,bx
ret
proc_affiche_curseur_b:
rectangle_vga 62,325,65,403,7
bloc2_vga 63,321,64,407
mov al,cs:couleur_modifiee
mov bl,al
shl al,1
add bl,al
mov bh,0
mov ax,63
sub al,cs:palette[bx+2]
add ax,325
mov bx,ax
add bx,15
bloc1_vga 62,ax,65,bx
ret

; PROC_CHOIX_PALETTE (P)
;**************************************************************************
num_palette     db ?
proc_choix_palette:
sub cx,32
mov ax,cx
mov bl,96
div bl
mov cs:num_palette,al
; affichage du bouton enfonc‚
mov al,cs:num_palette
mov ah,12
mul ah
add ax,4
mov bx,ax
add bx,11
push ax
bloc3_vga ax,450,bx,479
pop ax
inc ax
gotoxy_vga ax,457
police_vga 2
couleur_texte_vga 4
mov al,cs:num_palette
mov ah,11
mul ah
add ax,offset noms_palettes_couleurs
mov si,ax
mov ds,cs
call proc_aff_chaine_vga
; activation de la palette concern‚e
mov es,cs
mov ds,cs
mov al,cs:num_palette
mov ah,48
mul ah
add ax,offset palettes_couleurs
mov si,ax
mov di,offset palette
mov cx,48
cld
rep movsb
active_palette
call proc_affiche_curseur_r
call proc_affiche_curseur_v
call proc_affiche_curseur_b
; attend que l'utilisateur relache le bouton
lache_souris
; affichage du bouton relach‚
mov al,cs:num_palette
mov ah,12
mul ah
add ax,4
mov bx,ax
add bx,11
push ax
bloc1_vga ax,450,bx,479
pop ax
inc ax
gotoxy_vga ax,457
police_vga 2
couleur_texte_vga 1
mov al,cs:num_palette
mov ah,11
mul ah
add ax,offset noms_palettes_couleurs
mov si,ax
mov ds,cs
call proc_aff_chaine_vga

ret

; sauvegarde de la configuration
;**************************************************************************
sauve_config:
cls_menus
police_vga 2
gotoxy_vga 28,180
couleur_texte_vga 4
bloc1_vga 20,160,59,279
aff_chaine_vga 'SAUVER LA CONFIGURATION:'
gotoxy_vga 31,200
aff_chaine_vga 'Etes-vous certain?'
init_bouton 0,25,230,54,259,35,238,'Absolument.'
b1:
souris_menus
test_souris_bouton 0,b1
; sauvegarde config. :
mov ds,cs
; nom de fichier complet: cr‚ation
mov ah,3Ch
mov ds,cs
mov dx,offset nom_fichier_config
mov cx,0
int 21h
push ax
; ‚criture
mov ds,cs
mov dx,offset debut_vars
mov cx,offset fin_vars
sub cx,offset debut_vars
mov bx,ax
mov ah,40h
int 21h
; fermeture
pop bx
mov ah,3Eh
int 21h
rectangle_vga 21,230,58,259,7
couleur_texte_vga 1
gotoxy_vga 27,238
aff_chaine_vga 'Configuration sauvegard‚e.'
b2:
souris_menus
jmp b2

; config de la Sound Blaster (volume et ‚chantillonnage)
;**************************************************************************
option_sb:
cls_menus
bloc1_vga 20,80,59,450
bloc1_vga 24,100,55,129
police_vga 2
couleur_texte_vga 4
gotoxy_vga 26,108
aff_chaine_vga 'Configuration  Sound Blaster'
couleur_texte_vga 1
bloc1_vga 22,336,31,359
bloc1_vga 48,336,57,359
gotoxy_vga 24,341
aff_chaine_vga 'Volume'
gotoxy_vga 51,341
aff_chaine_vga 'Fr‚q.'
call proc_aff_ech_mod
call proc_aff_vol_mod
b1:
souris_menus
cmp dx,420
ja b1   ; trop bas
cmp cx,272
jb b1   ; trop … gauche
cmp cx,367
ja b1   ; trop … doite
cmp cx,304
jb >l1  ; modif volume
cmp cx,335
ja >l2  ; modif fr‚quence
jmp b1
; modif. volume
l1:
cmp dx,143
jb b1   ; trop haut
cmp dx,408
if a mov dx,408
cmp dx,153
if b mov dx,153
mov ax,408
sub ax,dx
cmp al,cs:volume_mod
je b1
mov cs:volume_mod,al
tempo_vga
call proc_aff_vol_mod
actualise_volume_mod
jmp b1
; modif. fr‚quence
l2:
cmp dx,218
jb b1   ; trop haut
cmp dx,408
if a mov dx,408
cmp dx,228
if b mov dx,228
mov ax,408
sub ax,dx
mov ah,100
mul ah
add ax,4000
cmp ax,cs:echantillonnage_mod
if e jmp b1
mov cs:echantillonnage_mod,ax
tempo_vga
call proc_aff_ech_mod
actualise_echantillonnage_mod
jmp b1
; affichage de l'‚chantillonnage
proc_aff_ech_mod:
rectangle_vga 42,220,45,416,7
bloc2_vga 43,216,44,420
mov ax,cs:echantillonnage_mod
sub ax,4000
mov bl,100
div bl
mov ah,0
mov bx,416
sub bx,ax
mov ax,bx
sub ax,16
bloc1_vga 42,ax,45,bx
bloc2_vga 48,376,57,399
gotoxy_vga 49,381
couleur_texte_vga 12
mov ax,cs:echantillonnage_mod
call proc_aff_word_vga
aff_chaine_vga ' Hz'
ret
; affichage du volume
proc_aff_vol_mod:
tempo_vga
rectangle_vga 34,145,37,416,7
bloc2_vga 35,141,36,420
mov al,cs:volume_mod
mov ah,0
mov bx,416
sub bx,ax
mov ax,bx
sub ax,16
bloc1_vga 34,ax,37,bx
bloc2_vga 22,376,31,399
gotoxy_vga 24,381
couleur_texte_vga 12
mov al,cs:volume_mod
mov ah,100
mul ah
mov bl,255
div bl
push ax
mov ah,0
call proc_aff_word_vga
mov al,'.'
call proc_aff_carac_vga
pop ax
mov al,10
mul ah
mov bl,255
div bl
mov ah,0
call proc_aff_word_vga
aff_chaine_vga ' %'
ret
