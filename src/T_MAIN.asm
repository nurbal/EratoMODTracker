;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_main.a
; (programme principal)
;**************************************************************************

; d‚but du programme
;**************************************************************************
debut_programme:

; chargement de la configuration
call proc_charge_config

; activation de la palette vga
call proc_active_palette

; activation des variables SB
actualise_volume_mod
actualise_echantillonnage_mod

; initialisation des segments de donn‚es...
mov ax,cs
add ax,1000h
mov cs:segment_directory,ax
add ax,4F4h
mov cs:segment_patterns,ax
call proc_new_mod
mov ds,cs
mov es,cs
mov si,offset titre_nouveau_mod
mov di,offset titre_mod
mov cx,20
cld
rep movsb

; page de pr‚sentation
call page_presentation

; d‚finit le menu principal
mov b cs:options_menus[1],0FFh
menu1 menu_fichier,'FICHIER',2,8, menu_samples,'SAMPLES',11,17, menu_edition,'EDITION',20,26, menu_jouer,'JOUER',29,33, menu_options,'CONFIGURATION',36,48, infos_programme,'INFORMATIONS',66,77

affiche_menus

; appel du menu
b1:
souris_menus
jmp b1

; fin du programme
;**************************************************************************
fin_programme:
; arrˆt du module
stop_mod
; restauration du r‚pertoire original
mov dl,cs:dir_programme
sub dl,'A'
mov ah,0Eh
int 21h         ; s‚lectionne un nouveau disque
mov bx,0
b1:
inc bx
cmp cs:dir_programme[bx],0
jne b1
cmp bx,3
if a mov b cs:dir_programme[bx-1],0     ; correction du r‚peroire:enlŠve le '\'
mov ds,cs
mov dx,offset dir_programme
add dx,2
mov ah,3Bh
int 21h         ; changement de r‚pertoire
; retour au DOS
ret

; PAGE_PRESENTAION (P)
;**************************************************************************
data_sygle_titre        dw 2,70,13,89
                        dw 2,90,5,159
                        dw 6,110,11,129
                        dw 2,160,13,179 ; E
                        dw 18,70,29,89
                        dw 18,90,21,179
                        dw 26,90,29,109
                        dw 22,110,29,129
                        dw 25,130,28,179 ; R
                        dw 34,70,45,89
                        dw 34,90,37,179
                        dw 42,90,45,179
                        dw 38,110,41,129 ; A
                        dw 50,70,61,89
                        dw 54,90,57,179 ; T
                        dw 66,70,77,89
                        dw 66,90,69,159
                        dw 74,90,77,159
                        dw 66,160,77,179 ; O
                        dw -1
page_presentation:
; dessin de 'ERATO' en rectangles "flamboyants"
modifie_couleur_vga 2,0,0,0
mov si,offset data_sygle_titre
b1:
push si
mov ax,cs:[si]
mov bx,cs:[si+2]
mov cx,cs:[si+4]
mov dx,cs:[si+6]
rectangle_vga ax,bx,cx,dx,2
pop si
add si,8
cmp w cs:[si],-1
jne b1
mov cx,22
mov al,0
b1:
push ax,cx
modifie_couleur_vga 2,al,al,al
tempo_vga
pop cx,ax
add al,3
loop b1
mov cx,21
mov al,62
b1:
push ax,cx
modifie_couleur_vga 2,al,al,al
tempo_vga
pop cx,ax
dec al
loop b1
; dessin de 'ERATO' en blocs type 3
mov si,offset data_sygle_titre
b1:
push si
mov ax,cs:[si]
mov bx,cs:[si+2]
mov cx,cs:[si+4]
mov dx,cs:[si+6]
bloc1_vga ax,bx,cx,dx
pop si
add si,8
cmp w cs:[si],-1
jne b1
; infos compl‚mentaires
modifie_couleur_vga 2,0,0,0
rectangle_vga 2,185,77,225,2
mov cx,22
mov al,0
b1:
push ax,cx
modifie_couleur_vga 2,al,al,al
tempo_vga
pop cx,ax
add al,3
loop b1
mov cx,21
mov al,62
b1:
push ax,cx
modifie_couleur_vga 2,al,al,al
tempo_vga
pop cx,ax
dec al
loop b1
bloc1_vga 2,185,77,225
police_vga 0
gotoxy_vga 32,195
couleur_texte_vga 1
aff_chaine_vga 'v1.0 - á version'
police_vga 1
gotoxy_vga 26,205
aff_chaine_vga 'par Bruno Carrez - ao–t 1995'
police_vga 2
call proc_active_palette
couleur_texte_vga 12
bloc1_vga 15,310,64,405
bloc2_vga 16,318,63,397
gotoxy_vga 23,340
aff_chaine_vga 'Version provisoire non document‚e.'
gotoxy_vga 20,360
aff_chaine_vga '-> voir message … la fin du programme...'
ret

; NEANT (JMP)
; cul de sac du programme...
;**************************************************************************
neant:
;cls_menus
affiche_menus
bloc1_vga 25,200,54,299
police_vga 2
gotoxy_vga 28,224
couleur_texte_vga 4
aff_chaine_vga 'Pas encore programm‚ ...'
police_vga 0
gotoxy_vga 36,270
couleur_texte_vga 1
aff_chaine_vga '(d‚sol‚)'
; appel du menu
b1:
souris_menus
jmp b1

; variables systŠme
;**************************************************************************
debut_vars:
palette db 0,0,0        ; noir
        db 0,0,42       ; bleu
        db 0,42,0       ; vert
        db 0,42,42      ; cyan
        db 42,0,0       ; rouge
        db 42,0,42      ; magenta
        db 42,21,0      ; brun
        db 42,42,42     ; gris clair
        db 21,21,21     ; gris fonc‚
        db 21,21,63     ; bleu clair
        db 21,63,21     ; vert clair
        db 21,63,63     ; cyan clair
        db 63,21,21     ; rouge clair
        db 63,21,63     ; magenta clair
        db 63,63,21     ; jaune
        db 63,63,63     ; blanc
echantillonnage_mod     dw 16000
volume_mod      db 55h
note_samples    db 36
fin_vars:

; ACTIVE_PALETTE (M+P)
; programme la carte graphique en fonction de PALETTE
;**************************************************************************
active_palette macro
call proc_active_palette
#em
proc_active_palette:
mov si,offset palette
mov bx,0
mov cx,16
b1:
push bx,cx,si
mov cl,cs:table_traduction_palette[bx]
mov bh,cs:[si]
mov bl,cs:[si+1]
mov ch,cs:[si+2]
call proc_modifie_couleur_vga
pop si,cx,bx
add si,3
inc bx
loop b1
ret
table_traduction_palette db 0,1,2,3,4,5,20,7,56,57,58,59,60,61,62,63

; informations g‚n‚rales
;**************************************************************************
infos_programme:
menu2 infos_sb,'SOUND-BLASTER',2,14, infos_mem,'MEMOIRE',17,23, infos_module,'MODULE',26,31
rectangle_vga 0,0,79,479,0
call page_presentation
affiche_menus
b1:
souris_menus
jmp b1
; information Sound Blaster
infos_sb:
affiche_menus
rectangle_vga 0,241,79,479,0
bloc1_vga 29,310,50,339
bloc1_vga 29,340,50,416
gotoxy_vga 33,318
couleur_texte_vga 4
police_vga 2
aff_chaine_vga 'Sound Blaster:'
couleur_texte_vga 1
gotoxy_vga 31,350
aff_chaine_vga 'adresse:'
gotoxy_vga 31,370
aff_chaine_vga 'interruption:'
gotoxy_vga 31,390
aff_chaine_vga 'version DSP: '
; affiche donn‚es sound blaster
couleur_texte_vga 0
gotoxy_vga 46,350
mov ax,cs:port_sb
mov ah,0
mov cl,4
shr al,cl
call proc_aff_word_vga
gotoxy_vga 45,350
aff_chaine_vga '2 0h'
gotoxy_vga 45,370
mov al,cs:int_sb
mov ah,0
call proc_aff_word_vga
gotoxy_vga 45,390
mov al,cs:version_dsp_sb
mov ah,0
call proc_aff_word_vga
aff_chaine_vga '.'
mov al,cs:version_dsp_sb[1]
mov ah,0
call proc_aff_word_vga
b1:
souris_menus
jmp b1
; information m‚moire
infos_mem:
affiche_menus
police_vga 2
rectangle_vga 0,241,79,479,0
bloc1_vga 28,300,51,329
bloc1_vga 28,330,51,426
gotoxy_vga 36,308
couleur_texte_vga 4
aff_chaine_vga 'M‚moire:'
couleur_texte_vga 1
gotoxy_vga 30,340
aff_chaine_vga 'totale (DOS):'
gotoxy_vga 30,360
aff_chaine_vga 'utilis‚e:'
gotoxy_vga 30,380
aff_chaine_vga 'programme:'
gotoxy_vga 30,400
aff_chaine_vga 'libre (MOD):'
; affiche donn‚es m‚moire
couleur_texte_vga 0
gotoxy_vga 44,340
mov ax,640
mov dx,ax
mov cl,6
shr dx,cl
mov cl,10
shl ax,cl
push ax,dx
call proc_aff_dword_vga
gotoxy_vga 44,360
mov ax,cs
mov dx,ax
mov cl,12
shr dx,cl
mov cl,4
shl ax,cl
push ax,dx
call proc_aff_dword_vga
gotoxy_vga 44,380
mov dx,1
mov ax,37548
push ax,dx
call proc_aff_dword_vga
pop cx,bx
pop dx,ax
add bx,ax
adc cx,dx
pop dx,ax
sub ax,bx
sbb dx,cx
gotoxy_vga 44,400
call proc_aff_dword_vga
b1:
souris_menus
jmp b1
; information module
infos_module:
affiche_menus
rectangle_vga 0,241,79,479,0
bloc1_vga 29,310,50,339
bloc1_vga 29,340,50,416
gotoxy_vga 30,318
couleur_texte_vga 4
police_vga 2
mov ds,cs
mov si,offset titre_mod
call proc_aff_chaine_vga
couleur_texte_vga 1
gotoxy_vga 31,350
aff_chaine_vga 'longueur:'
gotoxy_vga 31,370
aff_chaine_vga 'patterns:'
gotoxy_vga 31,390
aff_chaine_vga 'm‚moire: '
; affiche donn‚es module
couleur_texte_vga 0
gotoxy_vga 42,350
mov al,cs:nb_positions
mov ah,0
call proc_aff_word_vga
gotoxy_vga 42,370
mov al,cs:nb_patterns
mov ah,0
call proc_aff_word_vga
gotoxy_vga 42,390
mov al,cs:nb_patterns
mov ah,0
mov dx,2048
mul dx
mov cx,31
mov bx,0
b1:
mov si,cs:longueurs_samples[bx]
add si,15
and si,0FFF0h
add ax,si
adc dx,0
add bx,2
loop b1
call proc_aff_dword_vga
b1:
souris_menus
jmp b1

; chargement de la configuration
;**************************************************************************
nom_fichier_charge_config db 'ERATO.CFG',0
dir_programme   db 65 dup 0
nom_fichier_config db 75 dup 0
proc_charge_config:
; d‚termination du nom complet du fichier ( avec chemin et drive... )
push cs
pop es
mov di,offset dir_programme
push es,di
mov ah,19h
int 21h
pop di,es
add al,'A'
cld
stosb   ; drive
mov al,':'
stosb
mov al,'\'
stosb   ; ":\"rajout‚s au nom du drive
mov ds,cs
mov si,di
mov ah,47h
mov dl,0        ; unit‚ par d‚faut
int 21h         ; demande le r‚pertoire courant
mov ax,cs
mov es,ax
mov ds,ax
mov di,offset nom_fichier_config
mov si,offset dir_programme
b1:
inc si
cmp b cs:[si],0
jne b1
dec si
cmp b cs:[si],'\'
if ne mov b cs:[si+1],'\'
mov si,offset dir_programme
b1:
cld
lodsb
stosb
cmp al,0
jne b1          ; chemin copi‚
dec di
mov si,offset nom_fichier_charge_config
b1:
cld
lodsb
stosb
cmp al,0
jne b1          ; nom fichier copi‚ en prime
; ouverture
mov ds,cs
mov dx,offset nom_fichier_config
mov ax,3D00h
int 21h
if c ret        ; retour si fichier inexistant
; lecture
push ax
mov bx,ax
mov dx,offset debut_vars
mov ah,3Fh
mov cx,offset fin_vars
sub cx,offset debut_vars
int 21h
; fermeture
pop bx
mov ah,3Eh
int 21h
ret
