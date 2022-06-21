;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_edit.a
; (‚dition : fonctions d'interrˆt g‚n‚ral)
;**************************************************************************

delai_select            equ 20
choix_menu_edition      db 0
pattern_modifie         db 0
note_modifiee           db ?
voix_note_modifiee      db ?
donnee_note_modifiee    db ?
premiere_note_modifiee  dw 0
table_noms_notes        db 'C-0',0,'C#0',0,'D-0',0,'D#0',0,'E-0',0,'F-0',0
                        db 'F#0',0,'G-0',0,'G#0',0,'A-0',0,'A#0',0,'B-0',0
                        db 'C-1',0,'C#1',0,'D-1',0,'D#1',0,'E-1',0,'F-1',0
                        db 'F#1',0,'G-1',0,'G#1',0,'A-1',0,'A#1',0,'B-1',0
                        db 'C-2',0,'C#2',0,'D-2',0,'D#2',0,'E-2',0,'F-2',0
                        db 'F#2',0,'G-2',0,'G#2',0,'A-2',0,'A#2',0,'B-2',0
                        db 'C-3',0,'C#3',0,'D-3',0,'D#3',0,'E-3',0,'F-3',0
                        db 'F#3',0,'G-3',0,'G#3',0,'A-3',0,'A#3',0,'B-3',0
                        db 'C-4',0,'C#4',0,'D-4',0,'D#4',0,'E-4',0,'F-4',0
                        db 'F#4',0,'G-4',0,'G#4',0,'A-4',0,'A#4',0,'B-4',0
table_noms_commandes    db '  P+P-P',26,'4?5?6?7?8?OfVSPJVlPBE?Sp'
table2_noms_commandes   db 'Rien / Arpeggio',0
                        db 'Portamento Up  ',0
                        db 'Portamento Down',0
                        db 'Note Portamento',0
                        db '4 = ?          ',0
                        db '5 = ?          ',0
                        db '6 = ?          ',0
                        db '7 = ?          ',0
                        db '8 = ?          ',0
                        db 'Sample Offset  ',0
                        db 'Volume Sliding ',0
                        db 'Position Jump  ',0
                        db 'Set Volume     ',0
                        db 'Pattern Break  ',0
                        db 'E = ?          ',0
                        db 'Set Music Speed',0
; variables relatives aux blocs et … la s‚lection...
bloc            db 2048 dup ?
nb_voix_bloc    db 1
nb_notes_bloc   db 1
masque_bloc     db 1,1
nb_voix_select  db 1
nb_notes_select db 1
masque_select   db 1,1

; LANCE_PATTERN (M+P)
; joue le pattern AL
;*************************************************************************************
lance_pattern macro
call proc_lance_pattern
#em
proc_lance_pattern:
; arrˆt de toute sortie son
push ax
stop_mod
pop ax
; initialisation du mode sp‚cial
mov b cs:mode_joue_mod,1
mov cs:pattern_joue_mod,al
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
; installation de l'interruption DSP
mov es,0
mov al,cs:int_sb
add al,8
mov ah,4
mul ah
mov si,ax       ; es:si = adresse du vecteur d'interruption
cli
mov ax,offset interruption_mod
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


; MENU_EDITION (JMP)
;**************************************************************************
menu_edition:
cmp b cs:mod_status,1
jne >l1
mov bl,cs:num_position_mod
mov bh,0
mov al,cs:table_positions[bx]
cmp al,cs:pattern_modifie
je >l1
mov cs:pattern_modifie,al
l1:
mov al,cs:pattern_modifie
cmp al,cs:nb_patterns
if ae mov b cs:pattern_modifie,0

cmp b cs:choix_menu_edition,0
if e jmp menu_soundtracker
cmp b cs:choix_menu_edition,1
if e jmp menu_sequenceur
jmp menu_arrangement

; CHOIX_PATTERN (JMP)
; donne le choix entre tous les patterns utilis‚s
;**************************************************************************
choix_pattern:
menu2 choix_pattern,'AUTRE PATTERN',25,37, neant,'SEQUENCEUR',55,64, neant,'ARRANGEMENT',67,77
mov b cs:options_menus[1],0
affiche_menus
stop_mod
bloc1_vga 0,50,79,127
bloc1_vga 25,60,54,89
couleur_texte_vga 4
police_vga 2
gotoxy_vga 27,68
aff_chaine_vga 'CHOIX DU PATTERN A EDITER:'
couleur_texte_vga 1
gotoxy_vga 17,101
aff_chaine_vga '(bouton gauche=choisir - bouton droit=‚couter)'
rectangle_vga 0,128,79,479,7
police_vga 1
mov cl,cs:nb_patterns
xor ch,ch
b1:
mov al,cs:nb_patterns
sub al,cl
call proc_aff_bloc_choix_pattern
loop b1

b1:
souris_menus
cmp dx,128
jb b1   ; trop haut!
push bx
sub dx,128
mov ax,cx
mov cl,3
shr ax,cl
mov bl,10
div bl
mov bl,al
mov ax,dx
mov bh,22
div bh
mov cl,3
shl al,cl
add al,bl       ; al = num‚ro du pattern s‚lectionn‚
pop bx          ; bx = bouton souris
cmp al,cs:nb_patterns
jae b1
shr bx,1        ; c=1 => bouton gauche
jc >l1
; lancement du pattern dont le num‚ro est dans AL
lance_pattern
jmp b1
l1:     ; un pattern a ‚t‚ choisi (dans AL)
xchg cs:pattern_modifie,al
call proc_aff_bloc_choix_pattern
mov al,cs:pattern_modifie
call proc_aff_bloc_choix_pattern
lache_souris
stop_mod        ; arrˆte les ‚ventuels patterns en route...
jmp menu_edition

data_choix_pattern      db ?
proc_aff_bloc_choix_pattern:
push ax,bx,cx,dx,es,ds,si,di
mov cs:data_choix_pattern,al
mov cl,3
shr al,cl
mov ah,22
mul ah
mov bx,ax
add bx,128
mov al,cs:data_choix_pattern
and al,7
mov ah,10
mul ah
mov cx,ax
add cx,9
mov dx,bx
add dx,21
push ax
mov al,cs:data_choix_pattern
cmp al,cs:pattern_modifie
pop ax
je >l1
bloc1_vga ax,bx,cx,dx
couleur_texte_vga 1
jmp >l2
l1:
bloc3_vga ax,bx,cx,dx
couleur_texte_vga 4
l2:
add bx,4
add ax,4
gotoxy_vga ax,bx
mov al,cs:data_choix_pattern
mov ah,0
call proc_aff_word_vga
pop di,si,ds,es,dx,cx,bx,ax
ret

; JOUER_PATTERN (JMP)
; lance le pattern PATTERN_MODIFIE
;**************************************************************************
jouer_pattern:
mov al,cs:pattern_modifie
lance_pattern
mov b cs:options_menus[1],0FFh
jmp menu_edition

; TRAITEMENT_SELECT (JMP)
; copier/couper/coller/annuler + options masque
;**************************************************************************
traitement_select:
police_vga 2
bloc1_vga 19,110,60,369
bloc1_vga 31,120,48,149
gotoxy_vga 32,127
couleur_texte_vga 4
aff_chaine_vga 'Bloc S‚lectionn‚'
init_bouton 0,34,230,45,259,37,237,'Copier'
init_bouton 1,34,260,45,289,37,267,'Couper'
init_bouton 2,34,290,45,319,36,297,'Effacer'
init_bouton 3,34,330,45,359,36,337,'Annuler'
gotoxy_vga 24,167
aff_chaine_vga 'Notes:'
gotoxy_vga 24,197
aff_chaine_vga 'Voies:'
bloc2_vga 32,160,35,189
bloc2_vga 32,190,35,219
couleur_texte_vga 12
gotoxy_vga 33,167
mov al,cs:nb_notes_select
xor ah,ah
call proc_aff_word_vga
gotoxy_vga 33,197
mov al,cs:nb_voix_select
xor ah,ah
call proc_aff_word_vga

boucle_traitement_select:
cmp b cs:masque_select[0],1
je >l1
bloc1_vga 40,160,58,189
couleur_texte_vga 1
jmp >l2
l1:
bloc3_vga 40,160,58,189
couleur_texte_vga 4
l2:
gotoxy_vga 41,167
aff_chaine_vga 'Notes/Instruments'
cmp b cs:masque_select[1],1
je >l1
bloc1_vga 40,190,58,219
couleur_texte_vga 1
jmp >l2
l1:
bloc3_vga 40,190,58,219
couleur_texte_vga 4
l2:
gotoxy_vga 45,197
aff_chaine_vga 'Commandes'
;tempo souris
lache_souris

b1:
souris_menus
test_zone_souris 320,160,471,189,>l1    ; notes/instruments ?
xor b cs:masque_select[0],1
jmp boucle_traitement_select
l1:
test_zone_souris 320,190,471,219,>l1    ; commandes ?
xor b cs:masque_select[1],1
jmp boucle_traitement_select
l1:
couleur_texte_vga 4
test_souris_bouton 0,>l1    ; copier ?
call proc_copier_select
jmp menu_edition
l1:
test_souris_bouton 1,>l1    ; couper ?
call proc_couper_select
jmp menu_edition
l1:
test_souris_bouton 2,>l1    ; effacer ?
call proc_effacer_select
jmp menu_edition
l1:
test_souris_bouton 3,>l1    ; annuler ?
jmp menu_edition
l1:

jmp b1


; ADRESSE_NOTE_MODIFIEE (M+P)
; retourne dans ES:SI l'adresse de la note modifiee
; (en fct de PATTERN_MODIFIE, NOTE_MODIFIEE et VOIX_NOTE_MODIFIEE)
;**************************************************************************
adresse_note_modifiee macro
call proc_adresse_note_modifiee
#em
proc_adresse_note_modifiee:
push ax,cx
mov ah,cs:pattern_modifie
mov al,0
shr ax,1
add ax,cs:segment_patterns
mov es,ax       ; es = segment du pattern consid‚r‚
mov al,cs:note_modifiee
mov ah,0
mov cl,3
shl ax,cl
add al,cs:voix_note_modifiee
adc ah,0
mov cl,2
shl ax,cl
mov si,ax       ; ES:SI = adresse exacte de la note modifiee
pop cx,ax
ret


; PROC_COPIER_SELECT (P)
; PROC_COUPER_SELECT (P)
; PROC_EFFACER_SELECT (P)
;**************************************************************************
proc_copier_select:
adresse_note_modifiee
mov ds,es
mov es,cs
mov di,offset bloc
mov cl,cs:nb_notes_select
mov ch,0
b1:
push cx,si
mov cl,cs:nb_voix_select
mov ch,0
shl cx,1
cld
rep movsw
pop si,cx
add si,32
loop b1
mov al,cs:nb_notes_select
mov cs:nb_notes_bloc,al
mov al,cs:nb_voix_select
mov cs:nb_voix_bloc,al
mov al,cs:masque_select[0]
mov cs:masque_bloc[0],al
mov al,cs:masque_select[1]
mov cs:masque_bloc[1],al
ret
proc_couper_select:
call proc_copier_select
call proc_effacer_select
ret
proc_effacer_select:
adresse_note_modifiee
mov cl,cs:nb_notes_select
mov ch,0
b1:
push cx,si
mov cl,cs:nb_voix_select
b2:
cmp b cs:masque_select[0],0
je >l1
mov w es:[si],0
and b es:[si+2],0Fh
l1:
cmp b cs:masque_select[1],0
je >l1
mov b es:[si+3],0
and b es:[si+2],0F0h
l1:
add si,4
loop b2
pop si,cx
add si,32
loop b1
mov b cs:fichier_modifie,1
ret


; PROC_JOUE_NOTE_MODIFIEE (JMP)
; joue la note ‚dit‚e (en essayant de d‚terminer le sample … utiliser)
;**************************************************************************
proc_joue_note_modifiee:
adresse_note_modifiee
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0        ; pas de note?
if e ret        ; dans ce cas, retour! non mais, on se fout de la gueule de qui?
mov bx,0
mov cx,60
b1:
cmp cs:table_notes_mod[bx],ax
jbe >l1
add bx,2
loop b1
sub bx,2
l1:
shr bx,1        ; BL = hauteur de la note
mov cl,cs:note_modifiee
inc cl
xor ch,ch
b1:
mov al,es:[si]
and al,10h
mov ah,es:[si+2]
shr ah,1
shr ah,1
shr ah,1
shr ah,1
or al,ah
sub si,32       ; ligne pr‚c‚dente
cmp al,0
if e loop b1
cmp al,0
if ne dec al    ; AL = num‚ro de l'instrument
mov ah,bl       ; AH = hauteur de note
lance_sample    ; sample lanc‚!
ret

; MODIFIE_COMMANDE (JMP)
; modif. de la commande et du patamŠtre
;**************************************************************************
com_modifie_commande    db ?
data_modifie_commande   db ?
modifie_commande:
; lecture et d‚codage de la commande et du paramŠtre dans la partition
adresse_note_modifiee
mov al,es:[si+2]
and al,0Fh
mov cs:com_modifie_commande,al  ; commande transf‚r‚e
mov al,es:[si+3]
mov cs:data_modifie_commande,al ; donn‚e transf‚r‚e

; affichage du menu
bloc1_vga 20,60,59,469

boucle_modifie_commande:
rectangle_vga 40,73,57,424,7
police_vga 1
mov cx,16
mov ax,73
mov bx,94
mov dl,0
mov si,offset table2_noms_commandes
b1:
push ax,bx,cx,dx,si
push ax,si
cmp dl,cs:com_modifie_commande
je >l2
bloc1_vga 22,ax,38,bx
couleur_texte_vga 1
jmp >l3
l2:
bloc3_vga 22,ax,38,bx
couleur_texte_vga 4
l3:
pop si,ax
add ax,4
gotoxy_vga 23,ax
mov ds,cs
call proc_aff_chaine_vga
pop si,dx,cx,bx,ax
inc dl
add ax,22
add bx,22
add si,16
loop b1
init_bouton 0,22,433,39,456,30,438,'OK'
init_bouton 1,40,433,57,456,44,438,'Annulation'
call proc_aff_curseur_commande
; attend que l'utilisateur lache le bouton...
lache_souris

boucle_souris_modifie_commande:
souris_menus
; test: nouvelle commande ?
test_zone_souris 176,73,311,424,>l1
mov ax,dx
sub ax,73
mov bl,22
div bl
cmp al,cs:com_modifie_commande
if e jmp boucle_souris_modifie_commande
mov cs:com_modifie_commande,al
mov b cs:data_modifie_commande,0
cmp al,0Ch      ; volume?
if e mov b cs:data_modifie_commande,40h
cmp al,0Fh      ; set speed?
if e mov b cs:data_modifie_commande,6
jmp boucle_modifie_commande
l1:     ; c'est pas un nouvelle commande !
test_zone_souris 320,73,463,424,>l1     ; modifie les paramŠtres?
call proc_modifie_curseur_commande
l1:
test_souris_bouton 0,>l3    ; OK ?
; stockage dans la partition des commande & paramŠtre
adresse_note_modifiee
mov al,cs:data_modifie_commande
mov es:[si+3],al        ; paramŠtre
and b es:[si+2],0F0h
mov al,cs:com_modifie_commande
or es:[si+2],al         ; commande
mov b cs:fichier_modifie,1      ; le fichier a ‚t‚ modifi‚
jmp menu_edition
l3:
test_souris_bouton 1,>l3    ; Annuler ?
jmp menu_edition
l3:
jmp boucle_souris_modifie_commande

; PROC_AFF_CURSEUR_COMMANDE (P)
; affiche le curseur de paramŠtre correspondant … la commande
; ==> actualise TYPE_CURSEUR_COMMANDE, corrige DATA_MODIFIE_COMMANDE
;**************************************************************************
type_curseur_commande   db ?
proc_aff_curseur_commande:
tempo_vga
mov b cs:type_curseur_commande,0        ; curseur par d‚faut
cmp b cs:com_modifie_commande,0         ; arpeggio ?
if e mov b cs:type_curseur_commande,1
if e jmp aff_curseur_commande_1
cmp b cs:com_modifie_commande,0Ah       ; Volume Sliding ?
if e mov b cs:type_curseur_commande,2
if e jmp aff_curseur_commande_2
cmp b cs:com_modifie_commande,0Bh       ; Position Jump ?
if e mov b cs:type_curseur_commande,3
if e jmp aff_curseur_commande_3
cmp b cs:com_modifie_commande,0Ch       ; Set Note Volume ?
if e mov b cs:type_curseur_commande,4
if e jmp aff_curseur_commande_4
cmp b cs:com_modifie_commande,0Dh       ; Pattern Break ?
if e mov b cs:type_curseur_commande,5
if e jmp aff_curseur_commande_5
cmp b cs:com_modifie_commande,0Fh       ; Set Speed ?
if e mov b cs:type_curseur_commande,6
if e jmp aff_curseur_commande_6
; curseur type 0
bloc2_vga 48,93,49,371
rectangle_vga 47,97,47,367,7
rectangle_vga 50,97,50,367,7
mov al,cs:data_modifie_commande
not al
xor ah,ah
add ax,97
mov bx,ax
add bx,15
bloc1_vga 47,ax,50,bx
bloc2_vga 47,380,50,403
gotoxy_vga 48,385
couleur_texte_vga 12
mov al,cs:data_modifie_commande
call proc_aff_hex_vga
ret
; curseur type 1 (Arpeggio)
aff_curseur_commande_1:
bloc2_vga 44,108,45,371
rectangle_vga 43,112,43,367,7
rectangle_vga 46,112,46,367,7
mov al,cs:data_modifie_commande
and al,0F0h
not al
xor ah,ah
add ax,97
mov bx,ax
add bx,15
bloc1_vga 43,ax,46,bx
bloc2_vga 42,380,47,403
gotoxy_vga 44,385
couleur_texte_vga 12
mov al,'+'
call proc_aff_carac_vga
mov al,cs:data_modifie_commande
mov cl,4
shr al,cl
xor ah,ah
call proc_aff_word_vga
bloc2_vga 52,108,53,371
rectangle_vga 51,112,51,367,7
rectangle_vga 54,112,54,367,7
mov al,cs:data_modifie_commande
mov cl,4
shl al,cl
not al
xor ah,ah
add ax,97
mov bx,ax
add bx,15
bloc1_vga 51,ax,54,bx
bloc2_vga 50,380,55,403
gotoxy_vga 52,385
couleur_texte_vga 12
mov al,'+'
call proc_aff_carac_vga
mov al,cs:data_modifie_commande
and al,0Fh
xor ah,ah
call proc_aff_word_vga
ret
; curseur type 2 (Volume Sliding)
aff_curseur_commande_2:
rectangle_vga 47,112,47,367,7
rectangle_vga 50,112,50,367,7
rectangle_vga 46,239,51,240,1   ; graduation centrale...
bloc2_vga 48,108,49,371
mov al,cs:data_modifie_commande
mov cl,4
shr al,cl
add al,15
cmp al,15
jne >l1
mov ah,cs:data_modifie_commande
mov al,15
sub al,ah
l1:
push ax
shl al,1
shl al,1
shl al,1
not al
xor ah,ah
add ax,97
mov bx,ax
add bx,15
bloc1_vga 47,ax,50,bx
bloc2_vga 46,380,51,403
gotoxy_vga 48,385
couleur_texte_vga 12
pop ax
push ax
cmp al,15
mov al,'+'
if b mov al,'-'
call proc_aff_carac_vga
pop ax
cmp al,15
jb >l1
sub al,15
jmp >l2
l1:
mov ah,15
sub ah,al
mov al,ah
l2:
mov ah,0
call proc_aff_word_vga
ret
; curseur type 3 (Position Jump)
aff_curseur_commande_3:
mov al,cs:data_modifie_commande
cmp al,cs:nb_positions
if ae mov al,cs:nb_positions
if ae dec al
mov cs:data_modifie_commande,al
bloc2_vga 48,94,49,371
rectangle_vga 47,98,47,367,7
rectangle_vga 50,98,50,367,7
mov al,cs:data_modifie_commande
shl al,1
not al
xor ah,ah
add ax,97
mov bx,ax
add bx,15
bloc1_vga 47,ax,50,bx
bloc2_vga 46,380,51,403
gotoxy_vga 48,385
couleur_texte_vga 12
mov al,cs:data_modifie_commande
xor ah,ah
call proc_aff_word_vga
ret
; curseur type 4 (Set Note Volume)
aff_curseur_commande_4:
cmp cs:data_modifie_commande,64
if a mov b cs:data_modifie_commande,64
bloc2_vga 48,92,49,371
rectangle_vga 47,96,47,367,7
rectangle_vga 50,96,50,367,7
mov bl,cs:data_modifie_commande
mov bh,0
shl bx,1
shl bx,1
mov ax,352
sub ax,bx
mov bx,ax
add bx,15
bloc1_vga 47,ax,50,bx
bloc2_vga 47,380,50,403
gotoxy_vga 48,385
couleur_texte_vga 12
mov al,cs:data_modifie_commande
call proc_aff_hex_vga
ret
; curseur type 5 (Pattern Break)
aff_curseur_commande_5:
mov b cs:data_modifie_commande,0        ; pas de paramŠtre pour cette commande !
ret
; curseur type 6 (Set Music Speed)
aff_curseur_commande_6:
cmp cs:data_modifie_commande,31
if a mov b cs:data_modifie_commande,31
cmp cs:data_modifie_commande,0
if e mov b cs:data_modifie_commande,1
bloc2_vga 48,108,49,371
rectangle_vga 47,112,47,367,7
rectangle_vga 50,112,50,367,7
mov al,cs:data_modifie_commande
dec al
mov cl,3
shl al,cl
not al
xor ah,ah
add ax,97
mov bx,ax
add bx,15
bloc1_vga 47,ax,50,bx
bloc2_vga 47,380,50,403
gotoxy_vga 48,385
couleur_texte_vga 12
mov al,cs:data_modifie_commande
call proc_aff_hex_vga
ret

; PROC_MODIFIE_CURSEUR_COMMANDE (P)
; teste la souris afin de d‚terminer si le cursue doit changer ou pas
;**************************************************************************
proc_modifie_curseur_commande:
cmp b cs:type_curseur_commande,1
if e jmp modifie_curseur_commande_1
cmp b cs:type_curseur_commande,2
if e jmp modifie_curseur_commande_2
cmp b cs:type_curseur_commande,3
if e jmp modifie_curseur_commande_3
cmp b cs:type_curseur_commande,4
if e jmp modifie_curseur_commande_4
cmp b cs:type_curseur_commande,5
if e jmp modifie_curseur_commande_5
cmp b cs:type_curseur_commande,6
if e jmp modifie_curseur_commande_6

; modification du curseur type 0
test_zone_souris 376,93,407,371,>l1
b1:
mov ax,359
sub ax,dx
cmp ax,0
if l mov ax,0
cmp ah,0
if ne mov al,0FFh
cmp al,cs:data_modifie_commande
je >l2
mov cs:data_modifie_commande,al
call proc_aff_curseur_commande
l2:
mouse_state
cmp bx,0
jne b1
l1:
ret

; modification du curseur type 1
modifie_curseur_commande_1:
test_zone_souris 344,108,375,371,>l1
b1:
mov ax,359
sub ax,dx
cmp ax,0
if l mov ax,0
cmp ah,0
if ne mov ax,0FFh
and al,0F0h
mov ah,cs:data_modifie_commande
and ah,0Fh
or al,ah
cmp al,cs:data_modifie_commande
je >l2
mov cs:data_modifie_commande,al
call proc_aff_curseur_commande
l2:
mouse_state
cmp bx,0
jne b1
l1:
test_zone_souris 408,108,439,371,>l1
b1:
mov ax,359
sub ax,dx
cmp ax,0
if l mov ax,0
cmp ah,0
if ne mov ax,0FFh
shr al,1
shr al,1
shr al,1
shr al,1
mov ah,cs:data_modifie_commande
and ah,0F0h
or al,ah
cmp al,cs:data_modifie_commande
je >l2
mov cs:data_modifie_commande,al
call proc_aff_curseur_commande
l2:
mouse_state
cmp bx,0
jne b1
l1:
ret

; modification du curseur type 2
modifie_curseur_commande_2:
test_zone_souris 376,92,407,371,>l1
b1:
mov ax,359
sub ax,dx
cmp ax,0
if l mov ax,0
cmp ah,0
if ne mov ax,100h
shr ax,1
shr ax,1
shr ax,1
cmp al,30
if a mov al,30
; traduction
cmp al,15
jb >l2
sub al,15
mov cl,4
shl al,cl
jmp >l3
l2:
xor al,0Fh
l3:
cmp al,cs:data_modifie_commande
je >l2
mov cs:data_modifie_commande,al
call proc_aff_curseur_commande
l2:
mouse_state
cmp bx,0
jne b1
l1:
ret

; modification du curseur type 3
modifie_curseur_commande_3:
test_zone_souris 376,94,407,371,>l1
b1:
mov ax,359
sub ax,dx
cmp ax,0
if l mov ax,0
cmp ah,0
if ne mov ax,0FFh
shr ax,1
cmp al,cs:data_modifie_commande
je >l2
mov cs:data_modifie_commande,al
call proc_aff_curseur_commande
l2:
mouse_state
cmp bx,0
jne b1
l1:
ret

; modification du curseur type 4
modifie_curseur_commande_4:
test_zone_souris 376,92,407,371,>l1
b1:
mov ax,359
sub ax,dx
cmp ax,0
if l mov ax,0
cmp ah,0
if ne mov ax,100h
shr ax,1
shr ax,1
cmp al,cs:data_modifie_commande
je >l2
mov cs:data_modifie_commande,al
call proc_aff_curseur_commande
l2:
mouse_state
cmp bx,0
jne b1
l1:
ret

; modification du curseur type 5
modifie_curseur_commande_5:
ret

; modification du curseur type 6
modifie_curseur_commande_6:
test_zone_souris 376,108,407,371,>l1
b1:
mov ax,359
sub ax,dx
cmp ax,0
if l mov ax,0
cmp ah,0
if ne mov ax,0FFh
shr ax,1
shr ax,1
shr ax,1
cmp al,30
if a mov al,30
inc al
cmp al,cs:data_modifie_commande
je >l2
mov cs:data_modifie_commande,al
call proc_aff_curseur_commande
l2:
mouse_state
cmp bx,0
jne b1
l1:
ret

; PROC_COLLER_BLOC (P)
; colle le bloc … NOTE_MODIFIEE et VOIX_NOTE_MODIFIEE
;**************************************************************************
proc_coller_bloc:
adresse_note_modifiee
mov di,si
mov ds,cs
mov si,offset bloc
mov cl,cs:nb_notes_bloc
mov ch,0
b1:
push cx,di
mov cl,cs:nb_voix_bloc
mov ch,0
b2:
cmp b cs:masque_bloc[0],1
jne >l1
mov ax,ds:[si]
mov es:[di],ax          ; note
mov al,ds:[si+2]
and al,0F0h
and b es:[di+2],0Fh
or es:[di+2],al         ; instrument
l1:
cmp b cs:masque_bloc[1],1
jne >l1
mov al,ds:[si+3]
mov es:[di+3],al        ; paramŠtre
mov al,ds:[si+2]
and al,0Fh
and b es:[di+2],0F0h
or es:[di+2],al         ; commande
l1:
add di,4
add si,4
loop b2
pop di,cx
add di,32
loop b1
mov b cs:fichier_modifie,1
ret

message_erreur_coller_bloc:
couleur_texte_vga 4
police_vga 2
bloc1_vga 20,200,59,269
gotoxy_vga 28,227
aff_chaine_vga 'Le bloc est trop gros!'
lache_souris
souris_menus
lache_souris
jmp menu_edition


