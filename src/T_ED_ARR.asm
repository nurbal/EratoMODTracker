;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_ed_arr.a
; (‚dition de l'arrangement)
;**************************************************************************

; MENU_ARRANGEMENT (JMP)
;**************************************************************************
position_modifiee       db ?
bloc_arrangement        db 128 dup 0
taille_bloc_arrangement db 1
taille_select_arrangement       db 1

menu_arrangement:
menu2 coller_arrangement,'COLLER',2,7, derniere_position_arrangement,'DERNIERE-POSITION',10,26, menu_soundtracker,'SOUNDTACKER',67,77
;menu_sequenceur,'SEQUENCEUR',68,77
cls_menus
mov b cs:choix_menu_edition,2
lache_souris

; correction de POSITION_MODIFIEE et PATTERN_MODIFIE
mov bl,cs:position_modifiee
;cmp bl,cs:nb_positions
;if ae mov bl,0
xor bh,bh
mov al,cs:table_positions[bx]
mov cs:position_modifiee,bl
mov cs:pattern_modifie,al

couleur_texte_vga 4
police_vga 2
bloc1_vga 28,52,51,79
gotoxy_vga 29,58
aff_chaine_vga 'EDITION  (Arrangement)'

bloc1_vga 24,84,55,109
couleur_texte_vga 1
gotoxy_vga 25,89
aff_chaine_vga 'Ordre des Patterns (Positions)'
bloc1_vga 30,244,49,269
gotoxy_vga 31,249
aff_chaine_vga 'Table des Patterns'

; affichage des commentaires (patterns ou positions) et du menu sp‚cifique
bloc1_vga 0,404,79,479
police_vga 2
couleur_texte_vga 1
gotoxy_vga 2,414
aff_chaine_vga 'Bouton Gauche = choisir / modifier une position'
gotoxy_vga 2,434
aff_chaine_vga 'Bouton Droit = jouer un pattern ou une position'
gotoxy_vga 2,454
aff_chaine_vga 'Boutons Gauche (maintenu) = effacer un pattern / s‚lectionner des positions'


; affichage de tous les blocs
mov cx,128
mov al,0
b1:
push cx
call proc_aff_pos_arrangement
call proc_aff_pat_arrangement
pop cx
inc al
loop b1

mouse_on
boucle_souris_arrangement:
; mise … jour de l'affichage si module en marche
cmp b cs:mod_status,1
jne apres_actualise_arrangement
mov bl,cs:num_position_mod
mov bh,0
mov al,cs:table_positions[bx]
cmp al,cs:pattern_modifie       ; bon pattern ?
jne >l2
cmp bl,cs:position_modifiee     ; bonne position ?
jne >l2
je apres_actualise_arrangement
l2:
mov al,cs:num_position_mod
call proc_change_pos_arrangement
mov bl,cs:num_position_mod
mov bh,0
mov al,cs:table_positions[bx]
call proc_change_pat_arrangement
apres_actualise_arrangement:
mouse_state
cmp bx,0
je boucle_souris_arrangement
test_zone_souris 0,110,639,237,>l2
stop_mod
jmp >l3
l2:
test_zone_souris 0,270,639,397,>l3
stop_mod
l3:
mouse_off
souris_menus_2
mouse_on

cmp bx,2
if ae jmp joue_pattern_arrangement

test_zone_souris 0,110,639,237,test_zone_patterns       ; positions?
; calcul nouvelle position
sub dx,110
and dl,70h
mov ax,cx
mov bl,40
div bl
or al,dl        ; al = nouvelle position
push ax
call proc_change_pos_arrangement
pop bx
xor bh,bh
mov al,cs:table_positions[bx]
call proc_change_pat_arrangement
; bouton gauche: test d‚lai
mov cx,delai_select
b1:
push cx
tempo_vga
mouse_state
pop cx
cmp bx,0
if e jmp boucle_souris_arrangement
loop b1
; bloc de positions
mouse_off
mov b cs:taille_select_arrangement,1
call proc_aff_select_arrangement
mouse_on
b1:
mouse_state
cmp bx,0
jne >l1
mouse_off
jmp traitement_select_arrangement
l1:
test_zone_souris 0,110,639,237,b1
; calcul de la nouvelle position
sub dx,110
and dl,70h
mov ax,cx
mov bl,40
div bl
or al,dl        ; al = num‚ro position
cmp al,cs:position_modifiee
jae >l2
mov al,1        ; taille s‚lect = 1
jmp >l3
l2:
sub al,cs:position_modifiee
inc al
l3:
cmp al,cs:taille_select_arrangement
je b1
; modif du bloc s‚lectionn‚:
mouse_off
push ax
call proc_aff_select_arrangement
pop ax
mov cs:taille_select_arrangement,al
call proc_aff_select_arrangement
mouse_on
jmp b1

test_zone_patterns:
test_zone_souris 0,270,639,397,>l1      ; patterns?
; calcul nouveau pattern
sub dx,270
and dl,70h
mov ax,cx
mov bl,40
div bl
or al,dl        ; al = nouveau pattern
call proc_change_pat_arrangement
; bouton gauche: test d‚lai
mov cx,delai_select
b1:
push cx
tempo_vga
mouse_state
pop cx
cmp bx,0
if e jmp change_pattern_arrangement
loop b1
; s‚lection d'un pattern pour effacement
jmp efface_pattern_arrangement
l1:
jmp boucle_souris_arrangement

; on a choisi un autre pattern : modif, et v‚rifications.
change_pattern_arrangement:
mouse_off
call proc_sauve_arrangement     ; sauvegarde en vue d'une ‚ventuelle annulation
mov al,cs:pattern_modifie
mov bl,cs:position_modifiee
xor bh,bh
mov cs:table_positions[bx],al   ; modification effectuee
mov al,cs:position_modifiee
call proc_change_pos_arrangement
mov cl,cs:nb_patterns
xor ch,ch
xor al,al
b1:
push cx
call proc_aff_pat_arrangement
pop cx
inc al
loop b1
call proc_controle_arrangement
mouse_on
jmp boucle_souris_arrangement

; effacement d'un pattern
efface_pattern_arrangement:
mouse_off
bloc1_vga 19,170,60,309
bloc1_vga 21,180,58,209
gotoxy_vga 28,187
police_vga 2
couleur_texte_vga 4
aff_chaine_vga 'EFFACEMENT D',27h,'UN PATTERN'
lache_souris
; affichage du num‚ro du pattern concern‚
gotoxy_vga 31,217
couleur_texte_vga 1
aff_chaine_vga 'Pattern num‚ro: '
mov al,cs:pattern_modifie
xor ah,ah
call proc_aff_word_vga
; bouton 'annuler'
init_bouton 0,34,270,45,299,36,277,'Annuler.'
mov al,cs:pattern_modifie
cmp al,cs:nb_patterns
if ae jmp erreur1_eff_pattern_arrangement
mov cx,128
mov bx,0
b1:
cmp cs:table_positions[bx],al
if e jmp erreur2_eff_pattern_arrangement
inc bx
loop b1
; c'est OK, on peut effacer ce putain de pattern!
init_bouton 1,34,240,45,269,36,247,'Effacer.'
b1:
souris_menus
test_souris_bouton 0,>l1        ; annuler?
jmp menu_edition
l1:
test_souris_bouton 1,b1         ; effacer?
; effacement de ce pattern, et pour de bon!
; correction de la table de positions:
mov cx,128
mov bx,0
mov al,cs:pattern_modifie
b1:
cmp cs:table_positions[bx],al
if a dec b cs:table_positions[bx]
inc bx
loop b1
; d‚callage des autres patterns:
mov cl,cs:nb_patterns
sub cl,cs:pattern_modifie
dec cl
xor ch,ch       ; cx = nb de patterns … modifier
mov al,cs:pattern_modifie
mov ah,128
mul ah
add ax,cs:segment_patterns
mov es,ax       ; ES = segment destination
b1:
push cx
mov ax,es
add ax,128
mov ds,ax
xor si,si
xor di,di
mov cx,1024
cld
rep movsw
mov es,ds       ; segment suivant
pop cx
loop b1
; correction du nombre de patterns:
dec b cs:nb_patterns
; d‚callage des samples:
mov al,0
mov cx,128
call proc_decale_sample_2
jmp menu_edition
erreur1_eff_pattern_arrangement:        ; pattern d‚j… inexistant...
gotoxy_vga 24,240
couleur_texte_vga 4
aff_chaine_vga 'Impossible: pattern inexistant...'
b1:
souris_menus
test_souris_bouton 0,b1 ; annuler?
jmp menu_edition
erreur2_eff_pattern_arrangement:        ; pattern utilis‚...
gotoxy_vga 25,240
couleur_texte_vga 4
aff_chaine_vga 'Impossible: pattern utilis‚...'
b1:
souris_menus
test_souris_bouton 0,b1 ; annuler?
jmp menu_edition

; DERNIERE_POSITION_ARRANGEMENT (JMP)
; modifie NB_POSITIONS
;**************************************************************************
derniere_position_arrangement:
affiche_menus
mov cx,128
mov al,0
b1:
push cx
call proc_aff_pos_arrangement
inc al
pop cx
loop b1
rectangle_vga 0,237,79,397,0
bloc1_vga 12,270,67,299
gotoxy_vga 14,277
police_vga 2
couleur_texte_vga 1
aff_chaine_vga 'Choisissez ci-dessus la derniŠre position … jouer...'
b1:
souris_menus
test_zone_souris 0,110,639,237,b1
sub dx,110
mov ax,cx
mov bl,40
div bl
and dl,70h
or al,dl
inc al
mov cs:nb_positions,al
mov b cs:fichier_modifie,1
jmp menu_edition

; COLLER_ARRANGEMENT (JMP)
; insŠre dans la table des positions le bloc
;**************************************************************************
coller_arrangement:
affiche_menus
mov cx,128
mov al,0
b1:
push cx
call proc_aff_pos_arrangement
inc al
pop cx
loop b1
rectangle_vga 0,237,79,397,0
bloc1_vga 10,270,69,319
gotoxy_vga 13,277
police_vga 2
couleur_texte_vga 1
aff_chaine_vga 'Choisissez ci-dessus la position o— ins‚rer le bloc...'
gotoxy_vga 23,297
aff_chaine_vga '( taille du bloc: '
mov al,cs:taille_bloc_arrangement
xor ah,ah
call proc_aff_word_vga
aff_chaine_vga ' position(s) )'
b1:
souris_menus
test_zone_souris 0,110,639,237,b1
sub dx,110
mov ax,cx
mov bl,40
div bl
and dl,70h
or al,dl
push ax
call proc_change_pos_arrangement
lache_souris
pop ax
add al,cs:taille_bloc_arrangement
cmp al,128
jbe >l1
; erreur!
jmp message_erreur_coller_bloc
l1:
; tout est OK
; sauvegarde de l'ancien arrangement
call proc_sauve_arrangement
; d‚callage des positions existantes
mov es,cs
mov ds,cs
mov cl,128
sub cl,cs:taille_bloc_arrangement
sub cl,cs:position_modifiee
xor ch,ch       ; CX = nombre de positions … modifier
jcxz >l1        ; d‚callage inutile
mov ax,127+offset table_positions
mov di,ax
sub al,cs:taille_bloc_arrangement
sbb ah,0
mov si,ax
std
rep movsb
l1:
; copie du bloc
mov al,cs:position_modifiee
xor ah,ah
add ax,offset table_positions
mov di,ax
mov si,offset bloc_arrangement
mov cl,cs:taille_bloc_arrangement
xor ch,ch
cld
rep movsb
; modif. de la taille de la chanson
mov al,cs:nb_positions
cmp al,cs:position_modifiee
jbe >l1 ; modif pas n‚cessaire
mov al,cs:taille_bloc_arrangement
add cs:nb_positions,al
if s mov b cs:nb_positions,128
l1:
; indique une modif.
mov b cs:fichier_modifie,1
; controle
call proc_controle_arrangement
jmp menu_edition

joue_pattern_arrangement:
test_zone_souris 0,110,639,237,>l1      ; dans la liste des positions?
sub dx,110
mov ax,cx
mov bl,40
div bl
and dl,70h
or al,dl
mov bl,al
xor bh,bh
mov al,cs:table_positions[bx]
lance_pattern
jmp boucle_souris_arrangement
l1:
test_zone_souris 0,270,639,397,>l1      ; dans la liste des patterns?
sub dx,270
mov ax,cx
mov bl,40
div bl
and dl,70h
or al,dl
cmp al,cs:nb_patterns
if b lance_pattern
jmp boucle_souris_arrangement
l1:
jmp boucle_souris_arrangement

; PROC_AFF_PAT_ARRANGEMENT (P)
; affiche le bloc correspondant au pattern AL
;**************************************************************************
data_proc_aff_pat_arrangement   db ?
proc_aff_pat_arrangement:
mov cs:data_proc_aff_pat_arrangement,al
police_vga 0
mov al,cs:data_proc_aff_pat_arrangement
mov ah,0
and al,70h
add ax,270
mov bx,ax
mov al,cs:data_proc_aff_pat_arrangement
and al,0Fh
mov ah,5
mul ah
mov cx,ax
add cx,4
mov dx,bx
add dx,15
push ax
mov al,cs:data_proc_aff_pat_arrangement
cmp al,cs:nb_patterns
pop ax
jb >l1
; affichage d'un bloc vide: bˆte rectangle
rectangle_vga ax,bx,cx,dx,7
couleur_texte_vga 8
jmp aff_num_pat_arrangement
l1:
; affichage d'un vrai bloc
push ax,bx,cx
mov al,cs:data_proc_aff_pat_arrangement
cmp al,cs:pattern_modifie
je >l1
mov bx,0
mov cl,cs:nb_positions
xor ch,ch
b1:
cmp cs:table_positions[bx],al
je >l2
inc bx
loop b1
jmp >l3
; affichage du pattern modifi‚
l1:
pop cx,bx,ax
bloc3_vga ax,bx,cx,dx
couleur_texte_vga 4
jmp aff_num_pat_arrangement
; affichage d'un autre pattern, pr‚sent dans la table
l2:
pop cx,bx,ax
bloc1_vga ax,bx,cx,dx
couleur_texte_vga 1
jmp aff_num_pat_arrangement
; affichage d'un autre pattern, absent dans la table
l3:
pop cx,bx,ax
bloc1_vga ax,bx,cx,dx
couleur_texte_vga 8
; affichage du num‚ro du pattern
aff_num_pat_arrangement:
inc ax
add bx,4
gotoxy_vga ax,bx
mov al,cs:data_proc_aff_pat_arrangement
mov ah,0
call proc_aff_word_vga
mov al,cs:data_proc_aff_pat_arrangement
ret


; PROC_AFF_POS_ARRANGEMENT (P)
; affiche le bloc correspondant … la position AL
;**************************************************************************
proc_aff_pos_arrangement:
mov cs:data_proc_aff_pat_arrangement,al
police_vga 0
mov al,cs:data_proc_aff_pat_arrangement
mov ah,0
and al,70h
add ax,110
mov bx,ax
mov al,cs:data_proc_aff_pat_arrangement
and al,0Fh
mov ah,5
mul ah
mov cx,ax
add cx,4
mov dx,bx
add dx,15
push ax
mov al,cs:data_proc_aff_pat_arrangement
cmp al,cs:position_modifiee
pop ax
je >l1
push ax
mov al,cs:data_proc_aff_pat_arrangement
cmp al,cs:nb_positions
pop ax
jb >l2
jmp >l3
; affichage de la position s‚lectionn‚e
l1:
push ax
mov al,cs:position_modifiee
cmp al,cs:nb_positions
pop ax
jb >l5
bloc2_vga ax,bx,cx,dx
couleur_texte_vga 12
jmp >l4
l5:
bloc3_vga ax,bx,cx,dx
couleur_texte_vga 4
jmp >l4
; affichage d'une position utilis‚e
l2:
bloc1_vga ax,bx,cx,dx
couleur_texte_vga 1
jmp >l4
; affichage d'une position inutilis‚e
l3:
rectangle_vga ax,bx,cx,dx,7
couleur_texte_vga 8
; affichage du num‚ro du pattern
l4:
inc ax
add bx,4
gotoxy_vga ax,bx
mov bl,cs:data_proc_aff_pat_arrangement
xor bh,bh
mov al,cs:table_positions[bx]
mov ah,0
call proc_aff_word_vga
mov al,cs:data_proc_aff_pat_arrangement
ret

; PROC_CHANGE_POS_ARRANGEMENT (P)
; met AL dans POSITION_MODIFIEE et actualise l'affichage arrangement...
;**************************************************************************
proc_change_pos_arrangement:
mouse_off
mov ah,cs:position_modifiee
mov cs:position_modifiee,al
push ax
mov al,ah
call proc_aff_pos_arrangement
pop ax
call proc_aff_pos_arrangement
mouse_on
ret

; PROC_CHANGE_PAT_ARRANGEMENT (P)
; met AL dans PATTERN_MODIFIE et actualise l'affichage arrangement...
;**************************************************************************
proc_change_pat_arrangement:
mouse_off
mov ah,cs:pattern_modifie
mov cs:pattern_modifie,al
push ax
mov al,ah
call proc_aff_pat_arrangement
pop ax
call proc_aff_pat_arrangement
mouse_on
ret

; PROC_SAUVE_ARRANGEMENT (P)
; sauve la table des positions
;**************************************************************************
data_annul_arrangement  db 129 dup ?
proc_sauve_arrangement:
mov ds,cs
mov es,cs
mov si,offset table_positions
mov di,offset data_annul_arrangement
mov cx,64
cld
rep movsw
mov al,cs:nb_positions
mov cs:data_annul_arrangement[128],al
ret
; PROC_ANNUL_ARRANGEMENT (P)
; restaure la table des positions telle qu'elle a ‚t‚ sauv‚e
;**************************************************************************
proc_annul_arrangement:
mov ds,cs
mov es,cs
mov di,offset table_positions
mov si,offset data_annul_arrangement
mov cx,64
cld
rep movsw
mov al,cs:data_annul_arrangement[128]
mov cs:nb_positions,al
ret

; PROC_CONTROLE_ARRANGEMENT (P)
; controle la validit‚ du nombre de patterns
;       - si OK, RET
;       - sinon, cr‚e/efface des patterns, ou bien annulation,
;                               puis JMP MENU_EDITION
;**************************************************************************
data_controle_arrangement       db ?
proc_controle_arrangement:
; controle du nombre de patterns:
mov al,0
mov bx,0
mov cx,128
b1:
cmp al,cs:table_positions[bx]
if b mov al,cs:table_positions[bx]
inc bx
loop b1
inc al  ; al = nombre l‚gal de patterns...
cmp al,cs:nb_patterns   ; est-ce correct?
jne >l0
mov b cs:fichier_modifie,1
ret
l0:
pop bx  ; pour le ret
push ax
bloc1_vga 19,170,60,309
bloc1_vga 21,180,58,209
gotoxy_vga 23,187
police_vga 2
couleur_texte_vga 4
aff_chaine_vga 'MODIFICATION DU NOMBRE DE PATTERNS'
; bouton 'annuler'
init_bouton 0,34,270,45,299,36,277,'Annuler.'
pop ax
cmp al,cs:nb_patterns
if b jmp eff_controle_arrangement
if a jmp cree_controle_arrangement
eff_controle_arrangement:
; calcul du nombre de patterns … effacer
mov ah,cs:nb_patterns
sub ah,al
mov al,ah
mov cs:data_controle_arrangement,al
; message d'effacement
gotoxy_vga 24,217
aff_chaine_vga 'Il faut effacer '
mov al,cs:data_controle_arrangement
xor ah,ah
call proc_aff_word_vga
aff_chaine_vga ' pattern(s)...'
; bouton 'effacer'
init_bouton 1,34,240,45,269,36,247,'Effacer.'
b1:
mouse_on
b0:
mouse_state
cmp bx,0
je b0
push bx,cx,dx
mouse_off
pop dx,cx,bx
test_souris_bouton 0,>l1    ; annuler ?
jmp annul_controle_arrangement
l1:
test_souris_bouton 1,b1     ; effacer ?
mov al,cs:data_controle_arrangement
sub cs:nb_patterns,al           ; nombre de patterns modifi‚...
mov ah,128
mul ah
mov cx,ax
mov al,0
call proc_decale_sample_2      ; ... et samples d‚call‚s vers le bas !
mov b cs:fichier_modifie,1
jmp menu_edition
cree_controle_arrangement:
; calcul du nombre de patterns … cr‚er
sub al,cs:nb_patterns
mov cs:data_controle_arrangement,al
; message de cr‚ation
gotoxy_vga 25,217
aff_chaine_vga 'Il faut cr‚er '
mov al,cs:data_controle_arrangement
xor ah,ah
call proc_aff_word_vga
aff_chaine_vga ' pattern(s)...'
; y a-t-il assez de m‚moire?
mov al,cs:data_controle_arrangement
mov ah,128
mul ah
add ax,cs:segments_samples[60]
mov bx,cs:longueurs_samples[60]
test bx,0Fh
mov cl,4
pushf
shr bx,cl
popf
if nz inc bx
add ax,bx       ; ax = dernier segment qu'aurait le module...
cmp ax,segment_buffers_mod
if a jmp memoire_controle_arrangement
; bouton 'cr‚er'
init_bouton 1,34,240,45,269,37,247,'Cr‚er.'
b1:
mouse_on
b0:
mouse_state
cmp bx,0
je b0
push bx,cx,dx
mouse_off
pop dx,cx,bx
test_souris_bouton 0,>l1    ; annuler ?
jmp annul_controle_arrangement
l1:
test_souris_bouton 1,b1     ; cr‚er ?
mov al,cs:nb_patterns
mov ah,128
mul ah
add ax,cs:segment_patterns
push ax         ; segment du premier pattern rajout‚ empil‚
mov al,cs:data_controle_arrangement
add cs:nb_patterns,al           ; nombre de patterns modifi‚...
mov ah,128
mul ah
mov cx,ax
mov al,0
call proc_decale_sample_1      ; ... samples d‚call‚s vers le haut ...
pop es
mov cl,cs:data_controle_arrangement
xor ch,ch
b1:
push cx
mov cx,1024
xor ax,ax
mov di,0
cld
rep stosw                       ; ... et pattern vid‚ des anciens samples.
pop cx
mov ax,es
add ax,128
mov es,ax
loop b1
mov b cs:fichier_modifie,1
jmp menu_edition
memoire_controle_arrangement:
gotoxy_vga 26,240
couleur_texte_vga 4
aff_chaine_vga '*** MEMOIRE INSUFFISANTE ***'
b1:
mouse_on
b0:
mouse_state
cmp bx,0
je b0
push bx,cx,dx
mouse_off
pop dx,cx,bx
test_souris_bouton 0,b1    ; annuler ?
annul_controle_arrangement:
; annulation de la modification:
call proc_annul_arrangement
jmp menu_edition

; PROC_AFF_SELECT_ARRANGEMENT (P)
; inverse tous les plans des blocs s‚lectionn‚s
;**************************************************************************
proc_aff_select_arrangement:
mov al,0
mov ah,1
mov cx,4
b0:
push ax,cx
push ax
plans_ecriture_vga ah
pop ax
plan_lecture_vga al      ; on se place dans le plan bleu!
mov al,cs:position_modifiee
and al,70h
xor ah,ah
add ax,110
mov bx,5
mul bx
add ax,0A000h
mov es,ax       ; ES = paragraphe de la premiŠre ligne … modifier
mov al,cs:position_modifiee
and al,0Fh
mov ah,5
mul ah
mov di,ax       ; DI = offset premier bloc
mov cl,cs:taille_select_arrangement
xor ch,ch       ; cx = nb de blocs … inverser
b1:
push cx,es,di
mov cx,16       ; un bloc = 16 lignes vid‚o
b2:
push cx
mov cx,5
b3:
not b es:[di]
inc di
loop b3         ; octet suivant
add di,75
pop cx
loop b2         ; ligne vid‚o suivante
pop di,es,cx
add di,5
cmp di,80
jb >l1
mov di,0
mov ax,es
add ax,80
mov es,ax
l1:
loop b1         ; bloc suivant
pop cx,ax
inc al
shl ah,1
loop b0
ret

; TRAITEMENT_SELECT_ARRANGEMENT (JMP)
;**************************************************************************
traitement_select_arrangement:
police_vga 2
bloc1_vga 27,110,52,369
bloc1_vga 31,120,48,149
gotoxy_vga 32,127
couleur_texte_vga 4
aff_chaine_vga 'Bloc S‚lectionn‚'
init_bouton 0,34,230,45,259,37,237,'Copier'
init_bouton 1,34,260,45,289,37,267,'Couper'
init_bouton 2,34,290,45,319,36,297,'Effacer'
init_bouton 3,34,330,45,359,36,337,'Annuler'
couleur_texte_vga 1
gotoxy_vga 30,167
aff_chaine_vga 'De la position'
gotoxy_vga 31,197
aff_chaine_vga 'A la position'
bloc2_vga 45,160,49,189
bloc2_vga 45,190,49,219
couleur_texte_vga 12
gotoxy_vga 46,167
mov al,cs:position_modifiee
xor ah,ah
call proc_aff_word_vga
gotoxy_vga 46,197
mov al,cs:position_modifiee
add al,cs:taille_select_arrangement
dec al
xor ah,ah
call proc_aff_word_vga

b1:
souris_menus
test_souris_bouton 0,>l1        ; copier?
call proc_copier_select_arrangement
jmp menu_edition
l1:
test_souris_bouton 1,>l1        ; couper?
; sauvegarde de l'ancien arrangement:
call proc_sauve_arrangement
call proc_copier_select_arrangement
call proc_effacer_select_arrangement
; controle du nouvel arrangement
call proc_controle_arrangement
jmp menu_edition
l1:
test_souris_bouton 2,>l1        ; effacer?
; sauvegarde de l'ancien arrangement:
call proc_sauve_arrangement
call proc_effacer_select_arrangement
; controle du nouvel arrangement
call proc_controle_arrangement
jmp menu_edition
l1:
test_souris_bouton 3,b1         ; annuler?
jmp menu_edition

; PROC_COPIER_SELECT_ARRANGEMENT (P)
; PROC_EFFACER_SELECT_ARRANGEMENT (P)
;**************************************************************************
proc_copier_select_arrangement:
mov di,offset bloc_arrangement
mov al,cs:position_modifiee
xor ah,ah
add ax,offset table_positions
mov si,ax
mov es,cs
mov ds,cs
mov cl,cs:taille_select_arrangement
mov cs:taille_bloc_arrangement,cl
xor ch,ch
cld
rep movsb
ret
proc_effacer_select_arrangement:
; d‚callage des positions sup‚rieures ( si n‚cessaires )
mov cl,128
sub cl,cs:position_modifiee
sub cl,cs:taille_select_arrangement
xor ch,ch
jcxz >l1
mov al,cs:position_modifiee
xor ah,ah
add ax,offset table_positions
mov di,ax
add al,cs:taille_select_arrangement
adc ah,0
mov si,ax
cld
rep movsb
l1:
; effacement des positions lib‚r‚es … la fin de la table
mov di,127+offset table_positions
mov cl,cs:taille_select_arrangement
xor ch,ch
xor al,al
std
rep stosb
; drapeau: on a modifi‚ le machin
mov b cs:fichier_modifie,1
; modif (‚ventuelle) de la derniŠre position
mov al,cs:nb_positions
cmp al,cs:position_modifiee
if be ret       ; pas besoin de modification: bloc aprŠs derniŠre position
mov al,cs:position_modifiee
add al,cs:taille_select_arrangement
cmp al,cs:nb_positions
jb >l1
mov al,cs:position_modifiee
cmp al,0
if e mov al,1
mov cs:nb_positions,al
ret
l1:
mov al,cs:taille_select_arrangement
sub b cs:nb_positions,al
ret

