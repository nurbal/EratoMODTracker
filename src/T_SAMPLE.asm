;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_sample.a
;**************************************************************************

; d‚but du menu
;**************************************************************************
menu_samples:
menu2 menu_editer_sample,'EDITER',2,7, menu_choix_sample,'CHOIX',10,14, menu_jouer_sample,'JOUER',17,21, charger_sample,'CHARGER',24,30, sauver_sample,'SAUVER',33,38, effacer_sample,'EFFACER',41,47
mov b options_menus[1],0
jmp menu_editer_sample

proc_affiche_sample:
affiche_menus
rectangle_vga 0,352,79,479,0
bloc1_vga 0,50,79,351
bloc2_vga 1,80,78,343
police_vga 2
couleur_texte_vga 4
gotoxy_vga 2,58
aff_chaine_vga 'Sample '
mov al,cs:sample_modifie
mov ah,0
inc ax
call proc_aff_word_vga          ; num‚ro du sample affich‚
dec ax
push ax
aff_chaine_vga '  -  '
pop ax
mov ah,22
mul ah
mov si,ax
add si,offset noms_samples
mov ds,cs
call proc_aff_chaine_vga        ; nom du sample affich‚
push ax
aff_chaine_vga '  -  '
pop ax
mov bl,cs:sample_modifie
mov bh,0
shl bx,1        ; bx pointe sur les tables
mov ax,cs:longueurs_samples[bx]
push bx
call proc_aff_word_vga
aff_chaine_vga ' octets'
plans_ecriture_vga 10
plan_lecture_vga 3
pop bx
cmp w cs:longueurs_samples[bx],0
jne >l1
couleur_texte_vga 9
police_vga 2
gotoxy_vga 38,205
aff_chaine_vga 'vide'
jmp apres_affiche_sample
l1:
mov cx,76       ; 608 points … afficher
mov di,2        ; premiŠre abscisse … utiliser
mov b cs:dernier_echantillon,80h
mov ds,cs:segments_samples[bx]
mov si,0
b1:
push cx
mov cx,8
mov al,80h
b2:
push cx
push ax
mov ax,cs:longueurs_samples[bx]
dec ax
mul si
mov cx,607
div cx
mov bp,ax       ; bp = adresse ‚chantillon
b3:
mov al,ds:[bp]
xor al,80h
cmp al,cs:dernier_echantillon
pushf
if a inc b cs:dernier_echantillon
popf
if b dec b cs:dernier_echantillon
mov al,cs:dernier_echantillon
mov ah,0
add ax,84
mov cx,5
mul cx
add ax,0A000h
mov es,ax       ; ES = adresse ligne
pop ax
or es:[di],al   ; point affich‚
push ax
mov al,ds:[bp]
xor al,80h
cmp al,cs:dernier_echantillon
jne b3
pop ax
pop cx
inc si
shr al,1
loop b2
pop cx
inc di
loop b1
apres_affiche_sample:
ret




sample_modifie  db 0
dernier_echantillon     db ?

; CHOIX_SAMPLE (M+P)
; affiche un menu pour choisir un sample (retour dans AL)
;**************************************************************************
choix_sample macro
mov b cs:mode_choix_sample,0    ; annulation possible
call proc_choix_sample
#em
choix_sample_2 macro
mov b cs:mode_choix_sample,1    ; annulation impossible
call proc_choix_sample
#em
data_proc_choix_sample  dw ?
mode_choix_sample       db ?
proc_choix_sample:
pop ax
mov cs:data_proc_choix_sample,ax
cmp b cs:mode_choix_sample,0
je >l1
bloc1_vga 23,93,56,435
jmp >l2
l1:
bloc1_vga 23,90,56,465
l2:
police_vga 1
gotoxy_vga 26,98
couleur_texte_vga 4
aff_chaine_vga 'SAMPLE:'
gotoxy_vga 48,98
aff_chaine_vga 'TAILLE:'
police_vga 0
couleur_texte_vga 1
mov cx,31       ; 31 samples … afficher
mov bx,0        ; index dans les tables
mov si,offset noms_samples      ; si point sur les noms
mov dx,115      ; ligne o— afficher
b1:
push bx,cx,dx,si
gotoxy_vga 26,dx
push bx,dx
mov ds,cs
call proc_aff_chaine_vga
pop dx,bx
gotoxy_vga 49,dx
mov ax,cs:longueurs_samples[bx]
call proc_aff_word_vga
pop si,dx,cx,bx
add si,22
add bx,2
add dx,10
loop b1
cmp b cs:mode_choix_sample,0
jne >b2                 ; pas de bouton annulation si pas n‚cessaire
init_bouton 0,26,425,53,455,35,433,'Annulation'
police_vga 0

b2:
mouse_on
b5:
mouse_state
cmp bx,0
je b5
push cx,dx,bx
mouse_off
cmp b cs:mod_status,2
if e stop_mod
pop bx,dx,cx
souris_menus_2
cmp cx,208
jb b2
cmp cx,431
ja b2
cmp dx,115
jb b2
mov ax,455
cmp b cs:mode_choix_sample,0
if ne mov ax,424        ; adaptation de la fenetre au mode (annulation...)
cmp dx,ax
ja b2
cmp bx,2
jne >l1
cmp dx,424
ja >l1
mov ax,dx
sub ax,115
mov bl,10
div bl  ; AL = num‚ro sample
mov ah,cs:note_samples
call proc_lance_sample
jmp b2

l1:
couleur_texte_vga 4
mov ax,dx
sub ax,115
mov bl,10
div bl
cmp al,31
jb >l1
mov al,31
push ax
bouton_on 0
jmp >b1
l1:
push ax
mov bl,al
mov bh,0
shl bx,1
mov ah,10
mul ah
add ax,115
gotoxy_vga 26,ax
push ax,bx
mov ds,cs
mov ax,11
mul bl
add ax,offset noms_samples
mov si,ax
call proc_aff_chaine_vga
pop bx,ax
gotoxy_vga 49,ax
mov ax,cs:longueurs_samples[bx]
call proc_aff_word_vga

b1:
lache_souris

;cmp b cs:mod_status,2
;if e stop_mod

pop ax
mov bx,cs:data_proc_choix_sample
push bx
ret

; PROC_EFFACE_SAMPLE (P)
; efface le sample "SAMPLE_MODIFIE" de la m‚moire
;**************************************************************************
proc_efface_sample:
; effacement de toutes les donn‚es concernant ce sample
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov b cs:fichier_modifie,1
mov w cs:longueurs_samples[bx],0
mov w cs:debuts_boucles_samples[bx],0
mov w cs:longueurs_boucles_samples[bx],2
mov w cs:volumes_samples[bx],40h
mov al,cs:sample_modifie
mov ah,22
mul ah
mov di,ax
add di,offset noms_samples
mov es,cs
mov al,0
mov cx,22
cld
rep stosb
; d‚callage en m‚moire de tous les samples suivants
mov bl,cs:sample_modifie
mov al,bl
inc al          ; AL = sample de d‚part
xor bh,bh
shl bx,1        ; BX = pointeur tables samples
mov cx,cs:segments_samples[bx+2]
sub cx,cs:segments_samples[bx]        ; DX = nb de paragraphes … d‚caller
call proc_decale_sample_2
ret

; MENU_CHOIX_SAMPLE (JMP)
; affiche un menu … droite de l'‚cran pour choisir un sample
;**************************************************************************
menu_choix_sample:
call proc_affiche_sample
choix_sample
cmp al,31
if b mov cs:sample_modifie,al
mov cs:options_menus[1],0FFh
jmp menu_samples

; EFFACER_SAMPLE (JMP)
; efface le sample actuellement ‚dit‚
;**************************************************************************
effacer_sample:
call proc_affiche_sample
gotoxy_vga 21,200
couleur_texte_vga 4
bloc1_vga 18,180,61,279
aff_chaine_vga 'EFFACER CE SAMPLE: Etes-vous certain ?'
init_bouton 0,25,230,54,259,35,238,'Absolument.'
b1:
souris_menus
test_souris_bouton 0,b1
call proc_efface_sample
jmp menu_samples


; LANCE_SAMPLE (M+P)
; lance un sample en m‚moire
;       AL = num‚ro, AH = note (0=C-0, 24=C-2)
;*************************************************************************************
lance_sample macro
call proc_lance_sample
#em
proc_lance_sample:
push ax
; arrˆt de toute sortie son
stop_mod
; "nettoyage" des buffers...
mov es,9000h
mov di,0BC90h
cld
mov ax,0A0A0h
mov cx,439
rep stosw

; initialisation des variables playback
mov b cs:deja_dans_int_mod,0
mov b cs:num_position_mod,0
mov b cs:num_note_mod,0
mov b cs:chrono_note_mod,0
mov b cs:vitesse_mod,6
mov b cs:num_buffer_mod,0
mov w cs:ofs_buffer_mod,0BC90h
mov es,cs
mov di,offset donnees_voix_mod
mov cx,128
mov al,0
cld
rep stosb

; mise … jour des donn‚es n‚cessaires
pop ax
mov cs:num_lance_sample,al
mov bl,ah
mov bh,0
shl bx,1
mov cx,cs:table_notes_mod[bx]
; calcul de l'incr‚ment: i=((00369E9Ah/p‚riode)*256)/echantillonnage
mov ax,9E9Ah
mov dx,36h
cmp cx,37h
if b mov cx,37h ; pas catholique mais ‚vite les overflows....
div cx
mov cx,256
mul cx
mov cx,cs:echantillonnage_mod
div cx
mov cs:inc_lance_sample,ax
mov w cs:ofs_lance_sample,0
mov b cs:b_lance_sample,0

; installation de l'interruption DSP
mov es,0
mov al,cs:int_sb
add al,8
mov ah,4
mul ah
mov si,ax       ; es:si = adresse du vecteur d'interruption
cli
mov ax,offset int_sample
mov es:[si],ax
mov ax,cs
mov es:[si+2],ax
sti
; lancement de la "r‚action en chaine":
mov al,40h
call proc_ecrit_dsp_sb
mov al,cs:time_constant_sb
call proc_ecrit_dsp_sb  ; ‚criture du "time constant"
mov al,80h
call proc_ecrit_dsp_sb
mov al,0
call proc_ecrit_dsp_sb
mov al,0
call proc_ecrit_dsp_sb  ; silence instantan‚ => va provoquer l'interruption
ret

; INT_SAMPLE (INT)
; joue le sample en m‚moire (lance le nouveau transfert DMA puis calcule le suivant)
;*************************************************************************************
num_lance_sample        db ?
ofs_lance_sample        dw ?
inc_lance_sample        dw ?
b_lance_sample          db ?
int_sample:
push ax,bx,cx,dx,si,di,ds,es,bp
sti

; "aknowledge interrupt"
mov dx,cs:port_sb
add dx,0Eh
in al,dx

; set time constant
mov al,40h
call proc_ecrit_dsp_sb
mov al,cs:time_constant_sb
call proc_ecrit_dsp_sb  ; ‚criture du "time constant"

; lancement du buffer
; program DMAC for output transfer (cf. appendice B-6 du SB developer kit)
mov al,5
out 0Ah,al      ; mask off
mov al,0
out 0Ch,al      ; ????
mov al,49h
out 0Bh,al      ; DAC: read transfer
mov ax,cs:ofs_buffer_mod
out 2,al
mov al,ah
out 2,al        ; offset
mov al,9
out 83h,al      ; page
mov ax,cs:longueur_buffers_mod
dec ax
out 3,al
mov al,ah
out 3,al        ; longueur
mov al,1
out 0Ah,al      ; mask on
; program DSP
mov al,14h
ecrit_dsp_sb    ; commande 14h: 8 bit DAC normal speed DMA transfer
mov ax,cs:longueur_buffers_mod
dec ax
push ax
ecrit_dsp_sb
pop ax
mov al,ah
ecrit_dsp_sb    ; longueur
; ‡a y est, le buffer est lanc‚

; ‚change des buffers:
xor b cs:num_buffer_mod,1
cmp b cs:num_buffer_mod,0
if e mov w cs:ofs_buffer_mod,0BC90h
if ne mov w cs:ofs_buffer_mod,0BE48h

; EOI
mov al,20h
out 20h,al

; actualisation MOD_STATUS (1: on est en train de jouer un sample)
mov b cs:mod_status,2

; sortie si en cours
cmp b cs:deja_dans_int_mod,0
if ne jmp fin_int_sample

; flag 'en cours' activ‚
mov b cs:deja_dans_int_mod,1

; calcul du buffer
mov bl,cs:num_lance_sample
mov bh,0
shl bx,1
mov ax,cs:segments_samples[bx]
mov ds,ax
mov es,9000h
mov di,cs:ofs_buffer_mod

; vidage du buffer:
mov cx,cs:longueur_buffers_mod
mov al,80h
cld
rep stosb

mov di,cs:ofs_buffer_mod
mov si,cs:ofs_lance_sample
mov bl,cs:num_lance_sample
mov bh,0
shl bx,1
mov bp,cs:debuts_boucles_samples[bx]
add bp,cs:longueurs_boucles_samples[bx]
cmp b cs:b_lance_sample,0
if e mov bp,cs:longueurs_samples[bx]
cmp w cs:longueurs_samples[bx],2
jbe >l3
mov bx,cs:inc_lance_sample
mov dh,bl
mov bl,bh
mov bh,0
mov dl,0
mov cx,cs:longueur_buffers_mod
b1:
mov al,ds:[si]
sar al,1
;sar al,1
xor al,80h
mov es:[di],al
inc di
add dl,dh
adc si,bx
cmp si,bp
jae >l1
loop b1
mov cs:ofs_lance_sample,si
jmp >l2
l1:
; boucle!
push bx
mov bl,cs:num_lance_sample
mov bh,0
shl bx,1
mov si,cs:debuts_boucles_samples[bx]
mov bp,cs:longueurs_boucles_samples[bx]
add bp,si
mov b cs:b_lance_sample,1
cmp w cs:longueurs_boucles_samples[bx],2
pop bx
jbe >l3
loop b1
mov cs:ofs_lance_sample,si
jmp >l2

l3:
; arrˆt du sample
stop_mod

l2:
; flag 'en cours' d‚sactiv‚
mov b cs:deja_dans_int_mod,0

fin_int_sample:
pop bp,es,ds,di,si,dx,cx,bx,ax
iret



; MENU_JOUER_SAMPLE (JMP)
; joue le sample en m‚moire (comme un piano)
;*************************************************************************************
octave_proc_joue_piano        db 2
note_menu_jouer_sample          db ?
menu_jouer_sample:
call proc_affiche_sample
stop_mod

; affichage du piano
call proc_aff_piano

; jouer du piano!
boucle_jouer_sample:
call proc_joue_piano
mov al,cs:sample_modifie
mov cs:note_samples,ah  ; note par d‚faut chang‚e!
lance_sample            ; et le son est lanc‚!
jmp boucle_jouer_sample


; PROC_AFF_PIANO (P)
; affiche en bas de l'‚cran le piano
;**************************************************************************
proc_aff_piano:
; affichage du piano
bloc1_vga 4,352,75,479
rectangle_vga 5,360,74,439,15
plans_ecriture_vga 15
mov es,0A708h
mov di,6
mov cx,40
b1:
push cx
mov cx,5
b2:
cld
mov ax,0FF0h
stosw
stosw
mov ax,7FFEh
stosw
mov ax,0FF0h
stosw
stosw
stosw
mov ax,7FFEh
cmp cx,1
if a stosw
loop b2
add di,12
pop cx
loop b1
mov cx,40
b1:
push cx
mov cx,34
cld
mov ax,7FFEh
rep stosw
add di,12
pop cx
loop b1
police_vga 0
couleur_texte_vga 1
gotoxy_vga 5,444
aff_chaine_vga 'ÀÄÄÄÄÄF1ÄÄÄÄÄÙÀÄÄÄÄÄF2ÄÄÄÄÄÙÀÄÄÄÄÄF3ÄÄÄÄÄÙÀÄÄÄÄÄF4ÄÄÄÄÄÙÀÄÄÄÄÄF5ÄÄÄÄÄÙ'
rectangle_vga 5,457,74,470,7
mov al,cs:octave_proc_joue_piano
mov ah,14
mul ah
add ax,5
push ax
couleur_texte_vga 4
gotoxy_vga ax,457
aff_chaine_vga ' A Z   R T Y'
pop ax
gotoxy_vga ax,461
aff_chaine_vga 'a z e r t y u'
ret


; PROC_JOUE_PIANO (P)
; permet … l'utilisateur de jouer du piano;
; retour: AH = note
;         AL = 0:essai, 1:d‚finitif
;**************************************************************************
data_proc_joue_piano    dw ?
note_proc_joue_piano    db 24   ; d‚faut: C-2
proc_joue_piano:
pop cs:data_proc_joue_piano

mouse_on

; boucle principale:
boucle_joue_piano:

mouse_state
cmp bx,0
if e jmp apres_souris_joue_piano
cmp dx,50
if b stop_mod
mouse_off
souris_menus_2
push bx,cx,dx
mouse_on
pop dx,cx,bx
cmp cx,600
jae boucle_joue_piano
cmp cx,40
jb boucle_joue_piano
cmp dx,360
jb boucle_joue_piano
cmp dx,440
jae boucle_joue_piano
sub cx,40
mov ax,cx
mov bh,112
div bh          ; al = octave, ah=offset
cmp dx,400
ja >l2
mov dl,0
cmp ah,12
if ae mov dl,1
cmp ah,20
if ae mov dl,2
cmp ah,28
if ae mov dl,3
cmp ah,36
if ae mov dl,4
cmp ah,48
if ae mov dl,5
cmp ah,60
if ae mov dl,6
cmp ah,68
if ae mov dl,7
cmp ah,76
if ae mov dl,8
cmp ah,84
if ae mov dl,9
cmp ah,92
if ae mov dl,10
cmp ah,100
if ae mov dl,11
jmp >l3
l2:
mov dl,0
cmp ah,16
if ae mov dl,2
cmp ah,32
if ae mov dl,4
cmp ah,48
if ae mov dl,5
cmp ah,64
if ae mov dl,7
cmp ah,80
if ae mov dl,9
cmp ah,96
if ae mov dl,11
l3:
mov ah,12
mul ah
add al,dl       ; al = note
mov cs:note_proc_joue_piano,al
mov al,0
shr bl,1
if c mov al,1   ; choix d‚finitif si bouton gauche
jmp fin_proc_joue_piano

apres_souris_joue_piano:
mov ah,1
int 22  ; y a-t-il une touche ?
if z jmp boucle_joue_piano
mov ah,0
int 22  ; lecture de cette touche
cmp ah,3Bh
if b jmp apres_change_octave_piano
cmp ah,3Fh
if a jmp apres_change_octave_piano
sub ah,3Bh
mov cs:octave_proc_joue_piano,ah
mouse_off
rectangle_vga 5,457,74,470,7
mov al,cs:octave_proc_joue_piano
mov ah,14
mul ah
add ax,5
push ax
couleur_texte_vga 4
gotoxy_vga ax,457
aff_chaine_vga ' A Z   R T Y'
pop ax
gotoxy_vga ax,461
aff_chaine_vga 'a z e r t y u'
mouse_on
jmp boucle_joue_piano
apres_change_octave_piano:

cmp al,13       ; enter?
jne >l2
mov al,1        ; choix d‚finitif
jmp fin_proc_joue_piano
l2:
mov ah,0FFh
cmp al,'a'
if e mov ah,0
cmp al,'A'
if e mov ah,1
cmp al,'z'
if e mov ah,2
cmp al,'Z'
if e mov ah,3
cmp al,'e'
if e mov ah,4
cmp al,'r'
if e mov ah,5
cmp al,'R'
if e mov ah,6
cmp al,'t'
if e mov ah,7
cmp al,'T'
if e mov ah,8
cmp al,'y'
if e mov ah,9
cmp al,'Y'
if e mov ah,10
cmp al,'u'
if e mov ah,11
cmp ah,11
if a jmp boucle_joue_piano
mov bl,ah
mov al,cs:octave_proc_joue_piano
mov ah,12
mul ah
add al,bl
mov cs:note_proc_joue_piano,al
mov al,0        ; essai


fin_proc_joue_piano:
push ax
mouse_off
pop ax
mov ah,cs:note_proc_joue_piano
push cs:data_proc_joue_piano
ret

; PROC_DECALE_SAMPLE_1 (P)
; d‚calle tous les samples … partir de AL, de CX paragraphes vers le haut.
;**************************************************************************
proc_decale_sample_1:
cmp al,30
if a ret        ; retour si sample inexistant
push cx
mov cl,31
sub cl,al
xor ch,ch       ; CX = nombre de samples … d‚caler
mov bl,30
xor bh,bh
shl bx,1        ; BX = pointeur dans les tables
pop dx          ; DX = d‚callage
b1:
push cx
mov ax,cs:segments_samples[bx]
mov ds,ax       ; DS = segment source
add ax,dx       ; AX = nouveau segment
mov es,ax       ; ES = segment destination
mov cs:segments_samples[bx],ax
mov cx,cs:longueurs_samples[bx]
mov si,cx
dec si
mov di,si
std
jcxz >l1
rep movsb
l1:
pop cx
sub bx,2
loop b1
ret

; PROC_DECALE_SAMPLE_2 (P)
; d‚calle tous les samples … partir de AL, de CX paragraphes vers le bas.
;**************************************************************************
proc_decale_sample_2:
cmp al,30
if a ret        ; retour si sample inexistant
push cx
mov cl,31
sub cl,al
xor ch,ch       ; CX = nombre de samples … d‚caler
mov bl,al
xor bh,bh
shl bx,1        ; BX = pointeur dans les tables
pop dx          ; DX = d‚callage
b1:
push cx
mov ax,cs:segments_samples[bx]
mov ds,ax       ; DS = segment source
sub ax,dx       ; AX = nouveau segment
mov es,ax       ; ES = segment destination
mov cs:segments_samples[bx],ax
mov cx,cs:longueurs_samples[bx]
xor si,si
xor di,di
cld
jcxz >l1
rep movsb
l1:
pop cx
add bx,2
loop b1
ret

; SAUVER_SAMPLE (JMP)
;**************************************************************************
format_fichier_sample   db 1      ; ESM par d‚faut
nom_fichier_sample      db 14 dup 0
handle_fichier_sample   dw ?
sauver_sample:
call proc_affiche_sample

; test: y a-t-il un sample … sauver?
mov bl,cs:sample_modifie
xor bh,bh
shl bx,1
cmp w cs:longueurs_samples[bx],0
if e jmp erreur_1_sauver_sample

; cr‚ation du nom de fichier par d‚faut (… partir du nom du sample)
mov al,cs:sample_modifie
mov ah,22
mul ah
add ax,offset noms_samples
mov si,ax
mov bx,0
mov ds,cs
b1:
lodsb
cmp al,0
je >l1  ; scanning fini!
cmp al,'a'
jb >l0
cmp al,'z'
ja b1
sub al,20h
l0:
; test de tous les caractŠres irrecevables: *,./:;?\^
cmp al,'!'
jb b1
cmp al,'_'
ja b1
cmp al,'*'
je b1
cmp al,','
je b1
cmp al,'/'
je b1
cmp al,':'
je b1
cmp al,';'
je b1
cmp al,'?'
je b1
cmp al,'\'
je b1
cmp al,'^'
je b1
l2:
; le caractŠre est recevable
mov cs:nom_fichier_sample[bx],al
inc bx
cmp bx,8
jb b1   ; caractŠre suivant
l1:
mov b cs:nom_fichier_sample[bx],'.'

; menu de sauvegarde:

; affichage du chemin actuel
bloc1_vga 12,390,67,444
police_vga 2
gotoxy_vga 14,400
couleur_texte_vga 1
aff_chaine_vga 'R‚pertoire actuel:'
gotoxy_vga 14,420
mov ah,19h
int 21h         ; AL = drive actuel
mov cs:current_drive,al
add al,'A'
call proc_aff_carac_vga
aff_chaine_vga ':\'
mov ax,cs:segment_directory
mov ds,ax
mov si,19200
push ds,si
mov ah,47h
mov dl,cs:current_drive
add dl,1        ; unit‚ par d‚faut
int 21h         ; demande le r‚pertoire courant
pop si,ds
call proc_aff_chaine_vga

; sauvegarde par d‚faut: ESM
mov b cs:format_fichier_sample,1

bloc1_vga 20,140,59,369
couleur_texte_vga 4
police_vga 2
bloc1_vga 25,160,54,209
gotoxy_vga 27,167
aff_chaine_vga 'Sauvegarde Du Sample nø'
mov al,cs:sample_modifie
xor ah,ah
inc ax
call proc_aff_word_vga
mov al,':'
call proc_aff_carac_vga
gotoxy_vga 28,187
mov al,'"'
call proc_aff_carac_vga
mov ds,cs
mov al,cs:sample_modifie
mov ah,22
mul ah
add ax,offset noms_samples
mov si,ax
call proc_aff_chaine_vga        ; nom du sample affich‚
gotoxy_vga 51,187
mov al,'"'
call proc_aff_carac_vga

init_bouton 0,43,290,54,319,44,297,'R‚pertoire'
init_bouton 1,43,320,54,349,48,327,'OK'
gotoxy_vga 25,297
aff_chaine_vga 'Nom du fichier:'
mov al,cs:format_fichier
mov ah,10
mul ah
add ax,25
gotoxy_vga 43,220
couleur_texte_vga 4
aff_chaine_vga 'conseill‚'
sub w cs:x_texte_vga,7
mov w cs:y_texte_vga,234
aff_chaine_vga 25,'   ',25

boucle_sauver_sample:
call proc_check_nom_fichier_sample
bloc2_vga 25,320,39,349
gotoxy_vga 26,327
couleur_texte_vga 15
mov ds,cs
mov si,offset nom_fichier_sample
call proc_aff_chaine_vga
bloc1_vga 25,250,39,279
bloc1_vga 40,250,54,279
couleur_texte_vga 1
gotoxy_vga 26,257
aff_chaine_vga 'Format  *.SPL  Format  *.ESM'
mov al,cs:format_fichier_sample
mov ah,15
mul ah
add ax,25
mov bx,ax
add bx,14
bloc3_vga ax,250,bx,279
couleur_texte_vga 4
cmp b cs:format_fichier_sample,0
jne >l1
gotoxy_vga 26,257
aff_chaine_vga 'Format  *.SPL'
jmp >l2
l1:
gotoxy_vga 41,257
aff_chaine_vga 'Format  *.ESM'
l2:
lache_souris

; boucle: on regarde ce que fait l'utilisateur (… la souris bien ‚videmment)
b1:
souris_menus
test_zone_souris 200,250,439,279,>l1    ; format du fichier ?
sub cx,200
mov ax,cx
mov cl,120
div cl
mov cs:format_fichier_sample,al
jmp boucle_sauver_sample
l1:
test_zone_souris 200,320,319,349,>l1    ; nom du fichier ?
jmp change_nom_fichier_sample
l1:
test_souris_bouton 0,>l1    ; r‚pertoire ?
call proc_choix_directory
jmp sauver_sample
l1:
test_souris_bouton 1,>l1    ; OK ?
jmp sauver_sample_2
l1:
jmp b1

; sauvegarde du sample...
sauver_sample_2:
mov b cs:directory_modifiee,0   ; on a chang‚ le contenu de SEGMENT_DIRECTORY
; cr‚ation du fichier
mov ds,cs
mov dx,offset nom_fichier_sample
mov ax,5B00h
mov cx,0
int 21h
if nc jmp creation_fichier_sample_ok    ; cr‚ation OK
mov ah,59h      ; erreur: laquelle?
int 21h
cmp ax,50h      ; fichier existant d‚j… ?
if ne jmp erreur_3_sauver_sample        ; erreur d'ouverture inconnue
; fichier existant: confirmation
bloc1_vga 24,200,55,309
couleur_texte_vga 4
gotoxy_vga 28,210
mov ds,cs
mov si,offset nom_fichier_sample
call proc_aff_chaine_vga
aff_chaine_vga ' existe d‚j…!'
init_bouton 0,33,240,46,269,35,247,'Remplacer!'
init_bouton 1,33,270,46,299,37,277,'Retour'
b1:
souris_menus
test_souris_bouton 1,>l1        ; Retour ?
jmp sauver_sample
l1:
test_souris_bouton 0,b1
; cr‚ation de force:
mov ds,cs
mov dx,offset nom_fichier_sample
mov ax,3C00h
mov cx,0
int 21h
if c jmp erreur_3_sauver_sample ; erreur … la cr‚ation du fichier
; cr‚ation OK
creation_fichier_sample_ok:
mov cs:handle_fichier_sample,ax

; sauvegarde de l'entete (ESM uniquement)
cmp b cs:format_fichier_sample,0
if e jmp apres_ecrit_entete_sample
mov al,cs:sample_modifie
xor ah,ah
shl ax,1
add ax,offset longueurs_samples
mov dx,ax
mov bx,cs:handle_fichier_sample
mov ds,cs
mov cx,2
mov ah,40h
int 21h                 ; ‚criture de la taille du sample
if c jmp erreur_2_sauver_sample
cmp ax,2
if ne jmp erreur_2_sauver_sample
mov al,cs:sample_modifie
xor ah,ah
shl ax,1
add ax,offset debuts_boucles_samples
mov dx,ax
mov bx,cs:handle_fichier_sample
mov ds,cs
mov cx,2
mov ah,40h
int 21h                 ; ‚criture du d‚but de boucle
if c jmp erreur_2_sauver_sample
cmp ax,2
if ne jmp erreur_2_sauver_sample
mov al,cs:sample_modifie
xor ah,ah
shl ax,1
add ax,offset longueurs_boucles_samples
mov dx,ax
mov bx,cs:handle_fichier_sample
mov ds,cs
mov cx,2
mov ah,40h
int 21h                 ; ‚criture de la longueur de boucle
if c jmp erreur_2_sauver_sample
cmp ax,2
if ne jmp erreur_2_sauver_sample
mov al,cs:sample_modifie
xor ah,ah
shl ax,1
add ax,offset volumes_samples
mov dx,ax
mov bx,cs:handle_fichier_sample
mov ds,cs
mov cx,2
mov ah,40h
int 21h                 ; ‚criture du volume
if c jmp erreur_2_sauver_sample
cmp ax,2
if ne jmp erreur_2_sauver_sample
mov al,cs:sample_modifie
xor ah,ah
shl ax,1
add ax,offset finetunes_samples
mov dx,ax
mov bx,cs:handle_fichier_sample
mov ds,cs
mov cx,2
mov ah,40h
int 21h                 ; ‚criture du finetune
if c jmp erreur_2_sauver_sample
cmp ax,2
if ne jmp erreur_2_sauver_sample
mov al,cs:sample_modifie
mov ah,22
mul ah
add ax,offset noms_samples
mov dx,ax
mov bx,cs:handle_fichier_sample
mov ds,cs
mov cx,22
mov ah,40h
int 21h                 ; ‚criture du nom
if c jmp erreur_2_sauver_sample
cmp ax,22
if ne jmp erreur_2_sauver_sample

apres_ecrit_entete_sample:
; sauvegarde des donn‚es sonores
mov bl,cs:sample_modifie
xor bh,bh
shl bx,1
mov cx,cs:longueurs_samples[bx]
mov ax,cs:segments_samples[bx]
mov ds,ax
xor dx,dx
mov bx,cs:handle_fichier_sample
push cx
mov ah,40h
int 21h                 ; ‚criture du nom
pop cx
if c jmp erreur_2_sauver_sample
cmp ax,cx
if ne jmp erreur_2_sauver_sample

; fermeture du fichier
mov bx,cs:handle_fichier_sample
mov ah,3Eh
int 21h
jmp menu_samples

; erreur 1: sample vide (insauvable)
erreur_1_sauver_sample:
affiche_menus
police_vga 2
couleur_texte_vga 4
bloc1_vga 25,190,54,239
gotoxy_vga 33,197
aff_chaine_vga 'Sauver sample:'
gotoxy_vga 30,217
aff_chaine_vga 'Ce sample est vide !'
souris_menus
lache_souris
jmp menu_samples        ; retour aprŠs clic si sample vide
; erreur 2: fichier ouvert mais pb … l'‚criture
erreur_2_sauver_sample:
; fermeture du fichier
mov bx,cs:handle_fichier_sample
mov ah,3Eh
int 21h
; erreur 3: pb … la cr‚ation
erreur_3_sauver_sample:
police_vga 2
couleur_texte_vga 4
bloc1_vga 18,180,61,314
gotoxy_vga 22,210
aff_chaine_vga 'Sauvegarde de fichier impossible !!!'
gotoxy_vga 24,250
aff_chaine_vga 'Disque plein ? Disque non-prˆt ?'
gotoxy_vga 28,270
aff_chaine_vga 'Disque/Fichier prot‚g‚ ?'
souris_menus
lache_souris
jmp menu_samples

; changement du nom du fichier
change_nom_fichier_sample:
; recherche du '.' (on efface l'extention)
mov bx,0
b1:
cmp b cs:nom_fichier_sample[bx],'.'
je >l1
cmp bx,8
je >l1
inc bx
jmp b1
l1:
mov b cs:nom_fichier_sample[bx],0
; modification du nom par l'utilisateur...
bloc2_vga 25,320,39,349
gotoxy_vga 26,327
couleur_texte_vga 14
mov ds,cs
mov si,offset nom_fichier_sample
call proc_aff_chaine_vga
mov al,219
call proc_aff_carac_vga
mov ah,0
int 22
cmp al,13       ; entree ?
if e jmp apres_change_nom_fichier_sample
cmp al,8        ; <-DEL ?
jne >l1
mov bx,0
b1:
cmp b cs:nom_fichier_sample[bx+1],0
if e mov b cs:nom_fichier_sample[bx],0
inc bx
cmp bx,12
jne b1
jmp change_nom_fichier_sample
l1:
cmp al,21h
jb >l1
cmp al,0A8h
ja >l1
mov bx,0
b1:
cmp b cs:nom_fichier_sample[bx],0
je >l2
inc bx
jmp b1
l2:
cmp bx,12
je >l1          ; nom trop long
cmp al,'a'
jb >l2
cmp al,'z'
ja >l2
sub al,20h      ; passage en majuscules
l2:
mov cs:nom_fichier_sample[bx],al
mov b cs:nom_fichier_sample[bx+1],0
l1:
jmp change_nom_fichier_sample
apres_change_nom_fichier_sample:
jmp boucle_sauver_sample


; PROC_CHECK_NOM_FICHIER_SAMPLE (P)
; met au fichier l'extention SPL ou ESM, au choix
;**************************************************************************
proc_check_nom_fichier_sample:
xor bx,bx
b1:
mov al,cs:nom_fichier_sample[bx]
cmp al,0
if ne cmp al,'.'
je >l1
inc bx
cmp bx,8
jb b1
l1:
cmp bx,0
pushf
add bx,offset nom_fichier_sample
popf
jne >l1
mov b cs:[bx],'S'
mov b cs:[bx+1],'A'
mov b cs:[bx+2],'M'
mov b cs:[bx+3],'P'
mov b cs:[bx+4],'L'
mov b cs:[bx+5],'E'
add bx,6
l1:
mov b cs:[bx],'.'
mov b cs:[bx+4],0
cmp b cs:format_fichier_sample,0
jne >l1
mov b cs:[bx+1],'S'
mov b cs:[bx+2],'P'
mov b cs:[bx+3],'L'
ret
l1:
mov b cs:[bx+1],'E'
mov b cs:[bx+2],'S'
mov b cs:[bx+3],'M'
ret


; CHARGER_SAMPLE (JMP)
;**************************************************************************
filtre_esm      db '*.ESM',0
nb_filtres_spl  equ 3
filtres_spl     db '*.SPL',0
                db '*.SAM',0
                db '*.SMP',0
nb_filtres_voc  equ 2
filtres_voc     db '*.VOC',0
                db '*.WAV',0
charger_sample:
affiche_menus
bloc1_vga 0,50,79,479
; lecture du drive courant et du nombre de drives
mov ah,19h
int 21h
mov cs:current_drive,al
mov cx,11
mov dl,3
mov bx,2
b1:
push bx,cx,dx
mov ah,1Ch
int 21h
pop dx,cx,bx
cmp al,0FFh
if e mov b cs:drive_present[bx],0
if ne mov b cs:drive_present[bx],1
inc bx
inc dl
loop b1
mov b cs:drive_present[0],1
mov b cs:drive_present[1],1

boucle_charge_fichier_sample:
; affichage du menu des drives
couleur_texte_vga 1
police_vga 2
mov cx,11
mov al,'A'
mov bx,1
mov dx,6
mov di,0
b1:
push ax,bx,cx,dx,di
cmp b cs:drive_present[di],0
je >l1
bloc1_vga bx,58,dx,81
add bx,2
gotoxy_vga bx,63
call proc_aff_carac_vga
mov al,':'
call proc_aff_carac_vga
l1:
pop di,dx,cx,bx,ax
inc di
inc al
add bx,7
add dx,7
loop b1
mov al,cs:current_drive
mov ah,7
mul ah
add ax,1
mov bx,ax
add bx,5
bloc3_vga ax,58,bx,81
add ax,2
couleur_texte_vga 4
gotoxy_vga ax,63
mov al,cs:current_drive
add al,'A'
call proc_aff_carac_vga
mov al,':'
call proc_aff_carac_vga

lache_souris

; affichage du chemin actuel
gotoxy_vga 3,94
couleur_texte_vga 1
aff_chaine_vga 'R‚pertoire actuel:'
bloc2_vga 2,110,77,133
gotoxy_vga 3,115
couleur_texte_vga 15
mov al,cs:current_drive
add al,'A'
call proc_aff_carac_vga
aff_chaine_vga ':\'
mov ax,cs:segment_directory
mov ds,ax
mov si,19200
push ds,si
mov ah,47h
mov dl,cs:current_drive
add dl,1        ; unit‚ par d‚faut
int 21h         ; demande le r‚pertoire courant
pop si,ds
call proc_aff_chaine_vga

; faut-il explorer … nouveau le r‚pertoire ou en avons-nous encore le contenu?
cmp b cs:directory_modifiee,2
if e jmp boucle_affiche_fichiers_samples        ; recherches inutiles

; message de recherche de fichiers
bloc1_vga 20,270,59,361
couleur_texte_vga 1
gotoxy_vga 26,299
aff_chaine_vga 'Exploration du r‚pertoire...'

; recherche des r‚pertoires
mov w cs:nb_fichiers,0     ; on commence … peine les recherches, oh!
mov ds,cs
mov dx,offset filtre_repertoires
mov cx,10h
mov ah,4Eh
int 21h
mov di,0
jc >l1
b1:
mov al,cs:[149]
and al,10h
jz >l2          ; ce n'est pas un r‚pertoire...
mov es,cs:segment_directory
mov b es:[di+13],1
mov ds,cs
mov si,158
cld
mov cx,13
push di
rep movsb       ; nom transf‚r‚
pop di
inc w cs:nb_fichiers
cmp w cs:nb_fichiers,300
if e jmp fin_recherche_charger_fichier
add di,64       ; avancement dans la table
l2:
push di
mov ah,4Fh
int 21h         ; on cherche le r‚pertoire suivant...
pop di
jnc b1  ; on continue tant qu'il y a des r‚pertoires … trouver!
l1:

; recherche des samples ESM
mov ds,cs
mov dx,offset filtre_esm
mov cx,0
mov ah,4Eh
int 21h
jc >l1
b1:
mov es,cs:segment_directory
mov b es:[di+13],0
mov ds,cs
mov si,158
cld
mov cx,13
push di
rep movsb       ; nom transf‚r‚
pop di
inc w cs:nb_fichiers
cmp w cs:nb_fichiers,300
if e jmp fin_recherche_charger_fichier_sample
add di,64       ; avancement dans la table
l2:
push di
mov ah,4Fh
int 21h         ; on cherche le module suivant...
pop di
jnc b1  ; on continue tant qu'il y a des modules … trouver!
l1:

; recherche des modules *.SPL, *.SMP, *.SAM
mov cx,nb_filtres_spl
mov dx,offset filtres_SPL
boucle_cherche_spl:
push cx,dx
mov ds,cs
mov cx,0
mov ah,4Eh
int 21h
jc >l1
b1:
mov es,cs:segment_directory
mov b es:[di+13],2      ; type SPL
mov ds,cs
mov si,158
cld
mov cx,13
push di
rep movsb       ; nom transf‚r‚
pop di
mov ax,cs:[154]
mov es:[di+14],ax       ; taille transf‚r‚e
mov ax,cs:[156]
cmp ax,0        ; taille correcte? (<64K)
jne >l2
inc w cs:nb_fichiers
cmp w cs:nb_fichiers,300
jne >l3
pop dx,cx
jmp fin_recherche_charger_fichier_sample
l3:
add di,64       ; avancement dans la table
l2:
push di
mov ah,4Fh
int 21h         ; on cherche le module suivant...
pop di
jnc b1  ; on continue tant qu'il y a des modules … trouver!
l1:
pop dx,cx
add dx,6
loop boucle_cherche_spl

; recherche des modules *.VOC, *.WAV
mov cx,nb_filtres_voc
mov dx,offset filtres_voc
boucle_cherche_voc:
push cx,dx
mov ds,cs
mov cx,0
mov ah,4Eh
int 21h
jc >l1
b1:
mov es,cs:segment_directory
mov b es:[di+13],3      ; type VOC
mov ds,cs
mov si,158
cld
mov cx,13
push di
rep movsb       ; nom transf‚r‚
pop di
sub w cs:[154],44
sbb w cs:[156],0        ; on ne compte pas l'entete!
mov ax,cs:[156]
cmp ax,0        ; taille correcte? (<64Ko)
jne >l2
mov ax,cs:[154]
cmp ax,0
je >l2
mov es:[di+14],ax       ; taille transf‚r‚e
inc w cs:nb_fichiers
cmp w cs:nb_fichiers,300
jne >l3
pop dx,cx
jmp fin_recherche_charger_fichier_sample
l3:
add di,64       ; avancement dans la table
l2:
push di
mov ah,4Fh
int 21h         ; on cherche le module suivant...
pop di
jnc b1  ; on continue tant qu'il y a des modules … trouver!
l1:
pop dx,cx
add dx,6
loop boucle_cherche_voc

fin_recherche_charger_fichier_sample:
; ouverture de tous les modules pour infos compl‚mentaires...
gotoxy_vga 40,319
aff_chaine_vga '/'
mov ax,cs:nb_fichiers
mov w cs:num_fichier,0
call proc_aff_word_vga
mov si,0
mov ax,cs:segment_directory
mov ds,ax
mov cx,cs:nb_fichiers
cmp cx,0
if e jmp apres_lit_entetes_fichiers_samples
b1:
push cx,si
cmp b [si+13],0
if ne jmp pas_un_esm
mov dx,si
mov ax,3D00h
push si
push ds
int 21h
pop ds
pop dx
add dx,14       ; positionn‚ sur l'endroit o— aura lieu la copie de l'entete
mov cx,32
mov bx,ax
mov ah,3Fh
push bx
int 21h
pop bx
mov ah,3Eh
int 21h         ; fermeture du fichier
pas_un_esm:
push ds
inc w cs:num_fichier
rectangle_vga 37,319,39,334,7
gotoxy_vga 37,319
mov ax,cs:num_fichier
call proc_aff_word_vga
pop ds
pop si,cx
add si,64
dec cx
jcxz apres_lit_entetes_fichiers_samples
jmp b1
apres_lit_entetes_fichiers_samples:

mov b cs:directory_modifiee,2   ; on vient de tout explorer!

fin_recherche_fichiers_samples:
mov w cs:num_fichier,0
boucle_affiche_fichiers_samples:
mov ax,cs:num_fichier
mov bl,18
div bl
mul bl
mov cs:num_fichier,ax   ; on replace la page comme il faut!
init_bouton 0,76,160,78,315,77,231,24   ; flŠche vers le haut
init_bouton 1,76,316,78,471,77,387,25   ; flŠche vers le bas
couleur_texte_vga 1
gotoxy_vga 3,144
rectangle_vga 3,144,77,159,7
mov ax,cs:nb_fichiers
call proc_aff_word_vga
aff_chaine_vga ' fichiers et r‚pertoires trouv‚s:  (ci-dessous: fichiers '
mov ax,cs:num_fichier
inc ax
push ax
call proc_aff_word_vga
aff_chaine_vga ' … '
pop ax
add ax,17
cmp ax,cs:nb_fichiers
if a mov ax,cs:nb_fichiers
call proc_aff_word_vga
mov al,')'
call proc_aff_carac_vga
bloc2_vga 2,160,74,471
gotoxy_vga 3,164
couleur_texte_vga 9
aff_chaine_vga 'FICHIER      TAILLE LOOPSTART LOOPLEN VOL FTUNE NOM_SAMPLE'

; affichage des noms des fichiers
mov ax,cs:num_fichier
mov cx,cs:nb_fichiers
sub cx,ax
cmp cx,18
if a mov cx,18
cmp cx,0
if e jmp fin_affiche_noms_fichiers_samples
push cx
mov cl,6
shl ax,cl
mov si,ax
pop cx
mov ax,cs:segment_directory
mov ds,ax       ; DS:SI=1ø nom de fichier
cmp cx,0
if e jmp fin_affiche_noms_fichiers_samples
mov ax,180
boucle_affiche_noms_fichiers_samples:
push cx,ax,si,ds
gotoxy_vga 3,ax
cmp b ds:[si+13],1
if e jmp affichage_repertoire_sample
cmp b ds:[si+13],2
if e jmp affichage_sample_spl
cmp b ds:[si+13],3
if e jmp affichage_sample_voc
; affichage d'un ESM
couleur_texte_vga 11
push ax,si
call proc_aff_chaine_vga
pop si,ax
gotoxy_vga 16,ax
push ax
mov ax,ds:[si+14]
push si,ds
call proc_aff_word_vga  ; taille
pop ds,si
pop ax
gotoxy_vga 23,ax
push ax,si,ds
mov ax,[si+16]
call proc_aff_word_vga  ; loopstart
pop ds,si,ax
gotoxy_vga 33,ax
push ax,si,ds
mov ax,[si+18]
call proc_aff_word_vga  ; looplen
pop ds,si,ax
gotoxy_vga 41,ax
push ax,si,ds
mov ax,[si+20]
call proc_aff_word_vga  ; vol
pop ds,si,ax
gotoxy_vga 45,ax
push ax,si,ds
mov ax,[si+22]
cmp ax,0
jb >z0
push ax
mov al,'+'
call proc_aff_carac_vga
pop ax
jmp >z1
z0:
push ax
mov al,'-'
call proc_aff_carac_vga
pop bx
xor ax,ax
sub ax,bx
z1:
call proc_aff_word_vga  ; ftune
pop ds,si,ax
gotoxy_vga 51,ax
add si,24
call proc_aff_chaine_vga        ; nom
jmp >l2
affichage_repertoire_sample:
; affichage d'un r‚pertoire
couleur_texte_vga 10
push ax
call proc_aff_chaine_vga
pop ax
gotoxy_vga 16,ax
aff_chaine_vga '(sous-r‚pertoire)'
jmp >l2
; affichage d'un SPL,SMP,SAM
; affichage d'un VOC,WAV
affichage_sample_voc:
couleur_texte_vga 7
jmp >l1
affichage_sample_spl:
couleur_texte_vga 3
l1:
push ax,si
call proc_aff_chaine_vga
pop si,ax
gotoxy_vga 16,ax
push ax
mov ax,ds:[si+14]
push si,ds
call proc_aff_word_vga  ; taille
pop ds,si
pop ax
l2:
pop ds,si,ax,cx
add ax,16
add si,64
dec cx
jcxz >l1
jmp boucle_affiche_noms_fichiers_samples
l1:
fin_affiche_noms_fichiers_samples:

boucle_souris_charge_fichier_sample:
souris_menus
cmp dx,81
if b jmp change_disque_sample
cmp cx,599
if a jmp change_num_fichier_sample
lache_souris
cmp dx,180
if a jmp choisit_fichier_sample
jmp boucle_souris_charge_fichier_sample
; changement de drive
change_disque_sample:
cmp dx,58
jb boucle_souris_charge_fichier_sample
cmp cx,8
jb boucle_souris_charge_fichier_sample
mov b cs:directory_modifiee,0   ; on vient de changer de disque!
sub cx,8
mov ax,cx
mov bl,56
div bl
mov bl,al
mov bh,0
cmp b cs:drive_present[bx],1
jne boucle_souris_charge_fichier_sample
mov cs:current_drive,bl
mov dl,bl
mov ah,0Eh
int 21h         ; s‚lectionne un nouveau disque
jmp boucle_charge_fichier_sample
; d‚filement du menu
change_num_fichier_sample:
test_souris_bouton 1,>l1
mov ax,cs:num_fichier
add ax,18
cmp ax,cs:nb_fichiers
if b mov cs:num_fichier,ax
jmp boucle_affiche_fichiers_samples
l1:
test_souris_bouton 0,boucle_souris_charge_fichier_sample
sub w cs:num_fichier,18
cmp w cs:num_fichier,0
if l mov w cs:num_fichier,0
jmp boucle_affiche_fichiers_samples
; choix du fichier...
choisit_fichier_sample:
cmp cx,24
if b jmp boucle_souris_charge_fichier_sample
cmp cx,599
if a jmp boucle_souris_charge_fichier_sample
cmp dx,467
if a jmp boucle_souris_charge_fichier_sample
sub dx,181
mov ax,dx
mov bl,16
div bl
mov ah,0
add ax,cs:num_fichier
cmp ax,cs:nb_fichiers
if ae jmp boucle_souris_charge_fichier_sample
mov cs:num_fichier,ax
mov cl,6
shl ax,cl
mov si,ax
mov es,cs:segment_directory   ; es:si pointe sur le fichier...
cmp b es:[si+13],1
jne >l1         ; c'est d'un fichier qu'il s'agit!
; changement de r‚pertoire...
push es
pop ds
mov dx,si
mov ah,3Bh
int 21h         ; changement de r‚pertoire
mov b cs:directory_modifiee,0   ; on a chang‚ de r‚pertoire
jmp boucle_charge_fichier_sample
; chargement d'un fichier...
l1:

; test m‚moire
mov ax,es:[si+14]
shr ax,1
add ax,7
mov cl,3
shr ax,cl
push ax                 ; taille du nouveau sample (en paragraphes) empil‚e

mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov ax,cs:segments_samples[bx+2]
sub ax,cs:segments_samples[bx]  ; ax = taille lib‚r‚e par l'actuel sample
add ax,segment_buffers_mod
sub ax,cs:segments_samples[60]
mov bx,cs:longueurs_samples[60]
shr bx,1
add bx,7
shr bx,1
shr bx,1
shr bx,1
sub ax,bx               ; AX = taille disponible
pop bx                  ; BX = taille n‚cessaire en paragraphes
cmp ax,bx
if b jmp fichier_sample_trop_gros

; sauvegarde de l'adresse du nom du fichier:
mov cs:data_load_file,si
mov ax,es
mov cs:data_load_file[2],ax

; n'y a-t-il pas de sample … l'emplacement d‚sir‚?
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
cmp w cs:longueurs_samples[bx],2
if be jmp ok_charger_fichier_sample
; message d'erreur
call proc_affiche_sample
gotoxy_vga 24,380
couleur_texte_vga 4
bloc1_vga 20,360,59,459
aff_chaine_vga 'Ce sample sera effac‚ du module!'
init_bouton 2,25,410,54,439,31,417,'Charger quand-mˆme.'
b1:
souris_menus
test_souris_bouton 2,b1

; ok pour charger quand mˆme:
ok_charger_fichier_sample:
stop_mod
mov b cs:fichier_modifie,1
mov si,cs:data_load_file
mov ax,cs:data_load_file[2]
mov ds,ax       ; ds:si = donn‚es du fichier
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov ax,ds:[si+14]
and ax,0FFFEh
mov cs:longueurs_samples[bx],ax ; taille transf‚r‚e
cmp b ds:[si+13],0      ; fichier ESM ? (la grande classe...)
jne >l1
; transfert des donn‚es ESM...
mov ax,ds:[si+16]
mov cs:debuts_boucles_samples[bx],ax
mov ax,ds:[si+18]
mov cs:longueurs_boucles_samples[bx],ax
mov ax,ds:[si+20]
mov cs:volumes_samples[bx],ax
mov ax,ds:[si+22]
mov cs:finetunes_samples[bx],ax
mov al,cs:sample_modifie
mov ah,22
mul ah
add ax,offset noms_samples
add si,24
mov di,ax
mov es,cs
mov cx,22
cld
rep movsb       ; nom transf‚r‚
jmp >l2
l1:
; cr‚ation des donnes pour le fichier SPL ou VOC...
mov w cs:debuts_boucles_samples[bx],0
mov w cs:longueurs_boucles_samples[bx],2
mov w cs:volumes_samples[bx],40h
mov w cs:finetunes_samples[bx],0
mov al,cs:sample_modifie
mov ah,22
mul ah
add ax,offset noms_samples
mov bp,ax
mov di,0
b1:     ; transfert du nom du fichier comme nom de sample
mov al,ds:[si]
cmp al,0
je >b2
mov cs:[bp+di],al
inc si,di
jmp b1
b2:     ; remplissage du nom de sample avec des octets nuls
mov b cs:[bp+di],0
inc di
cmp di,22
jb b2
l2:

; d‚callage des samples
mov bl,cs:sample_modifie
mov al,bl
inc al  ; premier sample … d‚caller vers le bas
mov bh,0
shl bx,1
mov cx,cs:segments_samples[bx+2]
sub cx,cs:segments_samples[bx]
call proc_decale_sample_2
mov bl,cs:sample_modifie
mov al,bl
inc al  ; premier sample … d‚caller vers le haut
mov bh,0
shl bx,1
mov cx,cs:longueurs_samples[bx]
shr cx,1
add cx,7
shr cx,1
shr cx,1
shr cx,1
call proc_decale_sample_1

; chargement du fichier
; ouverture du fichier
mov dx,cs:data_load_file
mov ax,cs:data_load_file[2]
mov ds,ax       ; ds:dx = nom du fichier
push ds,dx
mov ax,3D00h
int 21h
mov cs:handle_fichier_sample,ax
pop si,ds

; d‚callage ‚ventuel (*.ESM)
cmp b ds:[si+13],0      ; esm ?
jne >l1
mov ax,4200h
mov cx,0
mov dx,46
mov bx,cs:handle_fichier_sample
int 21h         ; d‚callage effectu‚
l1:

; d‚callage ‚ventuel (*.VOC, *.WAV)
cmp b ds:[si+13],3      ; voc ?
jne >l1
mov ax,4200h
mov cx,0
mov dx,44
mov bx,cs:handle_fichier_sample
int 21h         ; d‚callage effectu‚
l1:

; lecture des donn‚es sonores
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov cx,cs:longueurs_samples[bx]
mov ax,cs:segments_samples[bx]
mov ds,ax
push ds,cx
xor dx,dx
mov bx,cs:handle_fichier_sample
mov ax,3F00h
int 21h         ; lecture...
pop cx,es

; invertion du bit 7 (PC->Amiga) si n‚cessaire
mov si,cs:data_load_file
mov ax,cs:data_load_file[2]
mov ds,ax       ; ds:si = nom du fichier
cmp b ds:[si+13],3      ; voc ?
jne >l1
mov di,0
b1:
xor b es:[di],80h
inc di
loop b1
l1:

; fermeture du fichier
mov bx,cs:handle_fichier_sample
mov ah,3Eh
int 21h

; joue le sample!
call proc_affiche_sample
bloc1_vga 30,400,49,429
gotoxy_vga 33,407
police_vga 2
couleur_texte_vga 1
aff_chaine_vga 'Sample jou‚...'
mov ah,cs:note_samples
mov al,cs:sample_modifie
call proc_lance_sample
tempo_vga
b1:
mouse_state
cmp bx,0
if e cmp b cs:mod_status,2
je b1
stop_mod
lache_souris

; retour au menu des samples
jmp menu_samples


; fichier trop gros pour ˆtre contenu en m‚moire:
fichier_sample_trop_gros:
bloc1_vga 20,270,59,361
couleur_texte_vga 4
gotoxy_vga 28,299
aff_chaine_vga 'Ce fichier est trop gros'
gotoxy_vga 26,319
aff_chaine_vga 'pour ˆtre charg‚ en m‚moire.'
souris_menus
lache_souris
jmp boucle_affiche_fichiers_samples

; MENU_EDITER_SAMPLE (JMP)
; edition du sample (nom,boucle,vol,finetune,+ quelques effets (s‚lection)
;**************************************************************************
menu_editer_sample:
call proc_affiche_sample

police_vga 2

; affichage de la boucle
mov bl,cs:sample_modifie
xor bh,bh
shl bx,1
cmp w cs:longueurs_boucles_samples[bx],2
if be jmp apres_affiche_boucle_sample
cmp w cs:longueurs_samples[bx],0
if e jmp apres_affiche_boucle_sample    ; sample vide, eh, ducon!
push bx
plans_ecriture_vga 5    ; mauve (inverse de vert clair)
plan_lecture_vga 2      ; plan rouge (un des deux utilis‚s par le mauve)
pop bx
; Xecran=16+Xr‚el*608/Taillesample
mov ax,cs:debuts_boucles_samples[bx]
mov cx,607
mul cx
mov cx,cs:longueurs_samples[bx]
div cx
add ax,16
push ax
mov cl,3
shr ax,cl
mov si,ax
pop cx
and cl,7
mov al,80h
shr al,cl
mov es,0A1A4h
mov cx,256
push si
b1:
or es:[si],al
add si,80
loop b1
pop si
inc si
couleur_texte_vga 13
cmp si,65
if a mov si,65
gotoxy_vga si,90
aff_chaine_vga 27,'D‚but Boucle'
mov bl,cs:sample_modifie
xor bh,bh
shl bx,1
push bx
plans_ecriture_vga 5    ; mauve (inverse de vert clair)
plan_lecture_vga 2      ; plan rouge (un des deux utilis‚s par le mauve)
pop bx
; Xecran=16+Xr‚el*607/Taillesample
mov ax,cs:debuts_boucles_samples[bx]
add ax,cs:longueurs_boucles_samples[bx]
mov cx,607
mul cx
mov cx,cs:longueurs_samples[bx]
div cx
add ax,16
push ax
mov cl,3
shr ax,cl
mov si,ax
pop cx
and cl,7
mov al,80h
shr al,cl
mov es,0A1A4h
mov cx,256
push si
b1:
or es:[si],al
add si,80
loop b1
pop si
sub si,11
couleur_texte_vga 13
cmp si,2
if l mov si,2
gotoxy_vga si,313
aff_chaine_vga 'Fin Boucle',26


apres_affiche_boucle_sample:

bloc1_vga 0,352,79,479

couleur_texte_vga 1
gotoxy_vga 2,396
aff_chaine_vga 'Volume'
call proc_aff_volume_sample
couleur_texte_vga 1
gotoxy_vga 15,396
aff_chaine_vga 'Finetune'
call proc_aff_finetune_sample

couleur_texte_vga 1
gotoxy_vga 35,442
aff_chaine_vga 'Nom du sample:'
bloc2_vga 50,435,73,464
gotoxy_vga 51,442
couleur_texte_vga 15
mov ds,cs
mov al,cs:sample_modifie
mov ah,22
mul ah
add ax,offset noms_samples
mov si,ax
call proc_aff_chaine_vga

init_bouton 0,32,366,54,395,38,374,'Test Sample'
init_bouton 1,55,366,77,395,61,374,'SILENCE !!!'
init_bouton 2,32,396,54,425,35,404,'S‚lectionner Tout'
init_bouton 3,55,396,77,425,59,404,'Annuler Boucle'

boucle_editer_sample:
souris_menus
test_souris_bouton 0,>l1                ; test sample ?
mov ah,cs:note_samples
mov al,cs:sample_modifie
call proc_lance_sample
bouton_off 0
jmp boucle_editer_sample
l1:
test_souris_bouton 1,>l1                ; silence ?
bouton_off 1
stop_mod
jmp boucle_editer_sample
l1:
test_souris_bouton 2,>l1                ; selectionner tout ?
bouton_off 2
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov w cs:debut_select_sample,0
mov ax,cs:longueurs_samples[bx]
cmp ax,0
je >l1
dec ax
mov cs:fin_select_sample,ax
call proc_aff_select_sample
jmp traitement_select_sample
l1:
test_souris_bouton 3,>l1                ; annuler boucle ?
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov w cs:debuts_boucles_samples[bx],0
mov w cs:longueurs_boucles_samples[bx],2
jmp menu_editer_sample
l1:
test_zone_souris 72,376,104,455,>l1     ; modif volume?
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov ax,447
sub ax,dx
if s mov ax,0
cmp ax,64
if a mov ax,64
cmp ax,cs:volumes_samples[bx]
if e jmp boucle_editer_sample
mov b cs:fichier_modifie,1
mov cs:volumes_samples[bx],ax
call proc_aff_volume_sample
jmp boucle_editer_sample
l1:
test_zone_souris 192,374,224,457,>l1     ; modif finetune?
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov ax,413
sub ax,dx
mov dl,4
idiv dl
cmp al,7
if g mov al,7
cmp al,-8
if l mov al,-8
cbw
cmp ax,cs:finetunes_samples[bx]
if e jmp boucle_editer_sample
mov b cs:fichier_modifie,1
mov cs:finetunes_samples[bx],ax
call proc_aff_finetune_sample
jmp boucle_editer_sample
l1:
test_zone_souris 400,430,591,459,>l1    ; modifie nom ?
jmp change_nom_sample
l1:
test_zone_souris 0,84,623,339,boucle_editer_sample      ; selection?
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
cmp w cs:longueurs_samples[bx],0
if e jmp boucle_editer_sample

; on est en train de s‚lectionner un morceau du sample
cmp cx,16
if b mov cx,16
; offset = (cx-16)*(taillesample-1)/607
sub cx,16
mov ax,cs:longueurs_samples[bx]
dec ax
mul cx
mov cx,607
div cx          ; ax = offset
mov cs:debut_select_sample,ax
mov cs:fin_select_sample,ax
call proc_aff_select_sample
boucle_select_sample:
mouse_state
cmp bx,0
if e jmp apres_select_sample
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
cmp cx,16
if b mov cx,16
; offset = (cx-16)*(taillesample-1)/607
sub cx,16
mov ax,cs:longueurs_samples[bx]
dec ax
mul cx
mov cx,607
div cx          ; ax = offset
cmp cs:debut_select_sample,ax
if a mov ax,cs:debut_select_sample
inc ax
cmp ax,cs:longueurs_samples[bx]
if a mov ax,cs:longueurs_samples[bx]
dec ax
cmp ax,cs:fin_select_sample
je boucle_select_sample
push ax
call proc_aff_select_sample
pop ax
mov cs:fin_select_sample,ax
call proc_aff_select_sample
jmp boucle_select_sample
apres_select_sample:
mov ax,cs:debut_select_sample
cmp ax,cs:fin_select_sample
if e jmp boucle_editer_sample   ; rien de s‚lectionn‚!
jmp traitement_select_sample

data_change_nom_sample  dw ?
change_nom_sample:
lache_souris
mov al,cs:sample_modifie
mov ah,22
mul ah
add ax,offset noms_samples
mov cs:data_change_nom_sample,ax
bloc2_vga 50,435,73,464
gotoxy_vga 51,442
couleur_texte_vga 15
mov ds,cs
mov si,data_change_nom_sample
call proc_aff_chaine_vga
couleur_texte_vga 14
mov al,219
call proc_aff_carac_vga
mouse_on
b1:
mouse_state
cmp bx,0
je >l1
; on a cliqu‚!
mouse_off
souris_menus_2
jmp menu_editer_sample
l1:
mov ah,1
int 22
jz b1
; on a frapp‚ au clavier!
mov ah,0
int 22          ; al = caractŠre!
mov bx,-1
b0:
inc bx
mov si,cs:data_change_nom_sample
cmp b cs:[bx+si],0
jne b0
cmp al,8        ; <-DEL ?
jne >l1
cmp bx,0
je b1   ; pas de caractŠre … effacer
mov si,cs:data_change_nom_sample
mov b cs:[bx+si-1],0
mov b cs:fichier_modifie,1
mouse_off
jmp change_nom_sample
l1:
cmp al,13       ; ENTREE ?
jne >l1
mouse_off
jmp menu_editer_sample
l1:
; inscription du caractŠre
cmp bx,21
je b1
mov si,cs:data_change_nom_sample
mov cs:[bx+si],al
mov b cs:fichier_modifie,1
mouse_off
jmp change_nom_sample

proc_aff_volume_sample:
bloc2_vga 3,416,6,445
gotoxy_vga 4,424
couleur_texte_vga 12
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
push ax
call proc_aff_hex_vga
tempo_vga
rectangle_vga 9,376,9,455,7
rectangle_vga 12,376,12,455,7
bloc2_vga 10,372,11,459
mov ax,440
pop bx
sub ax,bx
mov bx,ax
add bx,15
bloc1_vga 9,ax,12,bx
ret
proc_aff_finetune_sample:
bloc2_vga 17,416,20,445
gotoxy_vga 18,424
couleur_texte_vga 12
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov ax,cs:finetunes_samples[bx]
push ax
cmp ax,0
jl >l1
push ax
mov al,'+'
call proc_aff_carac_vga
pop ax
jmp >l0
l1:
push ax
mov al,'-'
call proc_aff_carac_vga
pop bx
xor ax,ax
sub ax,bx
l0:
call proc_aff_word_vga
tempo_vga
rectangle_vga 24,374,24,457,7
rectangle_vga 27,374,27,457,7
rectangle_vga 23,413,28,414,1
bloc2_vga 25,374,26,457
mov ax,406
pop bx
sal bx,1
sal bx,1
sub ax,bx
mov bx,ax
add bx,15
bloc1_vga 24,ax,27,bx
ret


; PROC_AFF_SELECT_SAMPLE (P)
; proc‚dure affichant les limites de la zone s‚lectionn‚e
;**************************************************************************
debut_select_sample     dw ?
fin_select_sample       dw ?
proc_aff_select_sample:
tempo_vga
mov bl,cs:sample_modifie
xor bh,bh
shl bx,1
cmp w cs:longueurs_samples[bx],0
if e ret        ; sample vide, eh, ducon!
push bx
plans_ecriture_vga 1    ; Bleu fonc‚
plan_lecture_vga 0      ; plan bleu
pop bx
; Xecran=16+Xr‚el*608/Taillesample
mov ax,cs:debut_select_sample
mov cx,607
mul cx
mov cx,cs:longueurs_samples[bx]
div cx
add ax,16
push ax
mov cl,3
shr ax,cl
mov si,ax
pop cx
and cl,7
mov bl,80h
shr bl,cl
mov es,0A1A4h
mov cx,4                ; 4 plans … inverser
mov ax,1
b0:
push si,cx,ax,bx
push ax
plans_ecriture_vga al
pop ax
plan_lecture_vga ah
pop bx
mov cx,256
b1:
xor es:[si],bl
add si,80
loop b1
pop ax,cx,si
inc ah
shl al,1
loop b0
; Xecran=16+Xr‚el*607/Taillesample
mov ax,cs:fin_select_sample
mov cx,607
mul cx
mov bl,cs:sample_modifie
xor bh,bh
shl bx,1
mov cx,cs:longueurs_samples[bx]
dec cx
div cx
add ax,16
push ax
mov cl,3
shr ax,cl
mov si,ax
pop cx
and cl,7
mov bl,80h
shr bl,cl
mov es,0A1A4h
mov cx,4                ; 4 plans … inverser
mov ax,1
b0:
push si,cx,ax,bx
push ax
plans_ecriture_vga al
pop ax
plan_lecture_vga ah
pop bx
mov cx,256
b1:
xor es:[si],bl
add si,80
loop b1
pop ax,cx,si
inc ah
shl al,1
loop b0
ret

; TRAITEMENT_SELECT_SAMPLE (JMP)
;**************************************************************************
traitement_select_sample:
bloc1_vga 25,150,54,179
couleur_texte_vga 1
gotoxy_vga 32,158
aff_chaine_vga 'Bloc S‚lectionn‚'
bloc1_vga 25,180,54,320
init_bouton 0,30,190,49,219,37,198,'>Boucle'
init_bouton 1,30,220,49,249,37,228,'Effacer'
init_bouton 2,30,250,49,279,37,258,'Silence'
init_bouton 3,30,280,49,309,36,288,'Amplitude'
; init_bouton 4,30,310,49,339,38,318,'Echo'

boucle_traitement_select_sample:
souris_menus
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
test_souris_bouton 0,>l1        ; Boucle ?
mov ax,cs:debut_select_sample
and al,0FEh
mov cs:debuts_boucles_samples[bx],ax
mov ax,cs:fin_select_sample
sub ax,cs:debut_select_sample
and al,0FEh
mov cs:longueurs_boucles_samples[bx],ax
mov b cs:fichier_modifie,1
jmp menu_editer_sample
l1:
test_souris_bouton 1,>l1        ; Effacer ?
jmp effacer_select_sample
l1:
test_souris_bouton 2,>l1        ; Silence ?
mov es,cs:segments_samples[bx]
mov di,cs:debut_select_sample
mov cx,cs:fin_select_sample
sub cx,cs:debut_select_sample
xor al,al
cld
rep stosb
mov b cs:fichier_modifie,1
jmp menu_editer_sample
l1:
test_souris_bouton 3,>l1        ; Amplitude ?
jmp amplitude_select_sample
l1:
jmp boucle_traitement_select_sample

effacer_select_sample:
; effacement proprement dit (d‚callage)
mov es,cs:segments_samples[bx]
mov ds,es
mov di,cs:debut_select_sample
mov si,cs:fin_select_sample
mov cx,cs:longueurs_samples[bx]
sub cx,cs:fin_select_sample
and cl,0FEh
add cx,2
cmp cx,0
jle >l1
cld
rep movsb               ; donn‚es d‚call‚es
l1:
mov ax,cs:fin_select_sample
sub ax,cs:debut_select_sample
and al,0FEh
add ax,2
mov dx,cs:longueurs_samples[bx]
sub cs:longueurs_samples[bx],ax ; taille modifi‚e
mov cl,4
shr dx,cl
mov ax,cs:longueurs_samples[bx]
shr ax,cl
sub dx,ax
mov cx,dx
mov al,cs:sample_modifie
inc al
jcxz >l1
push bx
call proc_decale_sample_2      ; autres samples d‚call‚s
pop bx
l1:
; op‚ration d'actualisation de la boucle … pr‚sent...
mov ax,cs:fin_select_sample
cmp ax,cs:debuts_boucles_samples[bx]
jae >l1
; cas 1
mov ax,cs:fin_select_sample
sub ax,cs:debut_select_sample
and al,0FEh
sub cs:debuts_boucles_samples[bx],ax
jmp >l0
l1:
mov ax,cs:debuts_boucles_samples[bx]
add ax,cs:longueurs_boucles_samples[bx]
cmp ax,cs:debut_select_sample
ja >l1
; cas 2 (on s'en fout...)
jmp >l0
l1:
; autres cas: la boucle n'est pas intŠgre
; donc on l'annule
mov w cs:debuts_boucles_samples[bx],0
mov w cs:longueurs_boucles_samples[bx],2
l0:
mov b cs:fichier_modifie,1
jmp menu_editer_sample

data_amplitude_select_sample    db ?
amplitude_select_sample:
mov b cs:data_amplitude_select_sample,100
bloc1_vga 35,100,44,444
couleur_texte_vga 1
police_vga 2
gotoxy_vga 42,120
aff_chaine_vga '+'
gotoxy_vga 37,368
aff_chaine_vga '-'
call proc_aff_curseur_amplitude
init_bouton 0,37,400,42,429,39,408,'OK'
b1:
souris_menus
test_souris_bouton 0,>l1        ; OK?
jmp >l2
l1:
test_zone_souris 304,108,335,386,b1  ; Modif du coeff. d'amplitude?
cmp dx,120
if b mov dx,120
cmp dx,375
if a mov dx,375
mov ax,375
sub ax,dx
cmp al,cs:data_amplitude_select_sample
je b1
mov cs:data_amplitude_select_sample,al
call proc_aff_curseur_amplitude
jmp b1
l2:
; modification du volume
mov bl,cs:sample_modifie
mov bh,0
shl bx,1
mov es,cs:segments_samples[bx]
mov ds,es
mov si,cs:debut_select_sample
mov di,si
mov cx,cs:fin_select_sample
sub cx,si
inc cx
b1:
cld
lodsb
mov bl,cs:data_amplitude_select_sample
mov bh,0
cbw
imul bx
mov bx,100
idiv bx
cmp ax,-128
if l mov ax,-128
cmp ax,127
if g mov ax,127
cld
stosb
loop b1
mov b cs:fichier_modifie,1
jmp menu_editer_sample

proc_aff_curseur_amplitude:
tempo_vga
rectangle_vga 38,112,38,382,7
rectangle_vga 41,112,41,382,7
rectangle_vga 37,274,42,275,1
bloc2_vga 39,108,40,386
mov al,cs:data_amplitude_select_sample
not al
mov ah,0
add ax,112
mov bx,ax
add bx,15
bloc1_vga 38,ax,41,bx
ret
