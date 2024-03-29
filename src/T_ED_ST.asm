;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_ed_st.a
; (‚dition partition sous forme de sound tracker)
;**************************************************************************

; MENU_SOUNDTRACKER (JMP)
;**************************************************************************
menu_soundtracker:
menu2 coller_soundtracker,'COLLER',2,7, jouer_pattern,'JOUER-PATTERN',10,22, choix_pattern,'AUTRE-PATTERN',25,37, menu_arrangement,'ARRANGEMENT',67,77
;menu_sequenceur,'SEQUENCEUR',55,64,
affiche_menus
rectangle_vga 0,50,68,127,0
mov b cs:choix_menu_edition,0

; dessin de l'en-tˆte
bloc1_vga 14,53,54,79
police_vga 2
couleur_texte_vga 4
gotoxy_vga 16,59
aff_chaine_vga 'EDITION (pr‚sentation "soundtracker")'
bloc1_vga 20,83,48,124
gotoxy_vga 22,96
couleur_texte_vga 1
aff_chaine_vga 'Pattern ‚dit‚:'
bloc2_vga 38,90,46,117
couleur_texte_vga 12
mov w cs:x_texte_vga,42
mov al,'/'
call proc_aff_carac_vga
mov al,cs:nb_patterns
xor ah,ah
call proc_aff_word_vga

; bloc ascenceur:
bloc1_vga 69,50,79,127
gotoxy_vga 72,56
police_vga 0
couleur_texte_vga 1
aff_chaine_vga 'Notes'
call proc_aff_curseur_soundtracker

; dessin de la partition (tableau)
bloc1_vga 0,128,79,479
police_vga 0
gotoxy_vga 5,135
couleur_texte_vga 1
aff_chaine_vga 'voie 1:  voie 2:  voie 3:  voie 4:  voie 5:  voie 6:  voie 7:  voie 8:'
gotoxy_vga 4,144
mov cx,8
b1:
push cx
couleur_texte_vga 0
aff_chaine_vga 'Not  Cm'
sub w cs:x_texte_vga,4
couleur_texte_vga 4
aff_chaine_vga 'In  Dt'
pop cx
loop b1
; c'est ici qu'on revient si le pattern change (musique en route)
actualise_soundtracker:
police_vga 2
rectangle_vga 39,94,41,113,0
couleur_texte_vga 12
gotoxy_vga 39,96
mov al,cs:pattern_modifie
xor ah,ah
call proc_aff_word_vga
; affichage de la partition
call proc_aff_soundtracker



; interpr‚tation des commandes de l'utilisateur
;**************************************************************************
retour_soundtracker:
mouse_on
b1:
cmp b cs:mod_status,1
jne >l1
mov bl,cs:num_position_mod
mov bh,0
mov al,cs:table_positions[bx]
cmp al,cs:pattern_modifie
je >l1
mov cs:pattern_modifie,al
mouse_off
jmp actualise_soundtracker
l1:
mouse_state
cmp bx,0
je b1
mouse_off
souris_menus_2
cmp cx,560
jb >l1
cmp cx,632
ja >l1
cmp dx,65
jb >l1
cmp dx,121
ja >l1
jmp ascenceur_soundtracker
l1:
cmp cx,32
jb >l1
cmp cx,607
ja >l1
cmp dx,152
jb >l1
cmp dx,471
ja >l1
; on clique dans le pattern, peuchŠre!
jmp clique_pattern
l1:
mouse_on
jmp b1

; PROC_AFF_SOUNDTRACKER (P)
; affiche toute la partition … partir de PREMIERE_NOTE_MODIFIEE
;**************************************************************************
proc_aff_soundtracker:
rectangle_vga 1,152,2,475,7
rectangle_vga 77,152,78,475,7
police_vga 0
mov cx,32
mov ax,152
mov bx,160
boucle_aff_soundtracker:
push cx
couleur_texte_vga 0
push ax
inc ax
gotoxy_vga 1,ax
mov ax,cs:premiere_note_modifiee
add ax,32
sub ax,cx
push ax
test ax,7
if z couleur_texte_vga 4
pop ax
push ax
cmp ax,10
if b inc w cs:x_texte_vga
call proc_aff_word_vga
push bx
mov al,'-'
call proc_aff_carac_vga
mov w cs:x_texte_vga,76
mov al,'-'
call proc_aff_carac_vga
pop bx
pop ax
push ax
call proc_aff_word_vga
pop si
pop ax
push si
rectangle_vga 4,ax,12,bx,8
rectangle_vga 13,ax,21,bx,0
rectangle_vga 22,ax,30,bx,8
rectangle_vga 31,ax,39,bx,0
rectangle_vga 40,ax,48,bx,8
rectangle_vga 49,ax,57,bx,0
rectangle_vga 58,ax,66,bx,8
rectangle_vga 67,ax,75,bx,0
pop si
; affichage de la partition
push ax,bx
mov cl,5
shl si,cl
mov w cs:x_texte_vga,4
mov ah,cs:pattern_modifie
mov al,0
shr ax,1
add ax,cs:segment_patterns
mov ds,ax       ; ds:si = ligne de partition … afficher
mov cx,8
b_aff_note_soundtracker:
push cx
; premiŠre donn‚e … afficher: note
mov ax,ds:[si]
xchg ah,al
and ah,0Fh
cmp ax,0
je >l1
mov bx,0
mov cx,60
b1:
cmp ax,cs:table_notes_mod[bx]
jb >l3
; affichage de la note
push si,ds
mov si,offset table_noms_notes
shl bx,1
add si,bx
mov ds,cs       ; ds:si = adresse du nom de la note (ex:C#3)
couleur_texte_vga 15
call proc_aff_chaine_vga
pop ds,si
jmp >l2
l3:
add bx,2
loop b1
l1:
add w cs:x_texte_vga,3
l2:
; seconde donn‚e … afficher: instrument
mov al,ds:[si]
mov ah,ds:[si+2]
mov cl,4
shr ah,cl
and al,0F0h
or al,ah
xor ah,ah       ; ax=num‚ro de l'instrument
cmp ax,0
if e inc w cs:x_texte_vga
cmp ax,10
if b inc w cs:x_texte_vga
cmp ax,0
je >l1
push si,ds
couleur_texte_vga 12
call proc_aff_word_vga
pop ds,si
l1:
; troisiŠme donn‚e … afficher: commande
mov al,ds:[si+2]
and al,0Fh      ; al=commande
xor ah,ah
shl ax,1
add ax,offset table_noms_commandes
mov bx,ax
push si,ds
mov al,cs:[bx]
couleur_texte_vga 15
push bx
call proc_aff_carac_vga
pop bx
mov al,cs:[bx+1]
call proc_aff_carac_vga
pop ds,si
; quatriŠme donn‚e … afficher: commande
mov ax,ds:[si]
and al,0Fh
mov bl,ds:[si+2]
mov cl,4
shl bl,cl
or al,bl
cmp ax,0        ; pas de commande ni de note?
if e cmp b ds:[si+3],0
je >l1
cmp bl,0
if e cmp b ds:[si+3],0
je >l1          ; pas d'arpŠge: on n'affiche rien
mov al,ds:[si+3]
push ds,si
couleur_texte_vga 12
call proc_aff_hex_vga
pop si,ds
jmp >l2
l1:     ; pas de donn‚e … afficher
add w cs:x_texte_vga,2
l2:
pop cx
add si,4
dec cx
jcxz >l1
jmp b_aff_note_soundtracker
l1:
pop bx,ax
add ax,10
add bx,10
pop cx
dec cx
jcxz >l1
jmp boucle_aff_soundtracker
l1:
ret

; ASCENCEUR_SOUNDTRACKER (JMP)
; change la variable PREMIERE_NOTE_MODIFIEE
;**************************************************************************
ascenceur_soundtracker:
mouse_state
cmp bx,0
jne >l1
jmp actualise_soundtracker
l1:
cmp dx,77
if b mov dx,77
cmp dx,109
if a mov dx,109
sub dx,77
cmp dx,cs:premiere_note_modifiee
je ascenceur_soundtracker
mov cs:premiere_note_modifiee,dx
call proc_aff_curseur_soundtracker
jmp ascenceur_soundtracker

; PROC_AFF_CURSEUR_SOUNDTRACKER (P)
; affiche l'ascenceuren haut … droite pour les notes affich‚es
;**************************************************************************
proc_aff_curseur_soundtracker:
bloc2_vga 73,65,75,121
rectangle_vga 70,69,72,117,7
rectangle_vga 76,69,78,117,7
mov ax,cs:premiere_note_modifiee
add ax,69
mov bx,ax
add bx,16
push ax
bloc1_vga 70,ax,78,bx
pop ax
add ax,5
gotoxy_vga 71,ax
police_vga 0
couleur_texte_vga 4
mov ax,cs:premiere_note_modifiee
push ax
call proc_aff_word_vga
mov w cs:x_texte_vga,74
aff_chaine_vga '… '
pop ax
add ax,31
call proc_aff_word_vga
ret

; CLIQUE_PATTERN (JMP)
; interprŠte les commandes lorsque l'utilisateur clique dans la partition...
;**************************************************************************
clique_pattern:
; arrˆt de la musique (si mode 1)
cmp b cs:mod_status,1
if e stop_mod
; d'abbord, calcul de NOTE_MODIFIEE, VOIX_NOTE_MODIFIEE et DONNEE_NOTE_MODIFIEE
sub cx,32
sub dx,152
mov ax,cx
mov cl,72
div cl
mov cs:voix_note_modifiee,al
mov b cs:donnee_note_modifiee,0
cmp ah,24
if ae mov b cs:donnee_note_modifiee,1
cmp ah,40
if ae mov b cs:donnee_note_modifiee,2
mov ax,dx
mov dl,10
div dl
xor ah,ah
add ax,cs:premiere_note_modifiee
mov cs:note_modifiee,al

cmp bx,2        ; bouton droit ?
jne >l1
; bouton droit: on joue la note (si elle existe...)
call proc_joue_note_modifiee
; tempo souris:
lache_souris
stop_mod
jmp retour_soundtracker

l1:
; bouton gauche
; boucle de temporisation:
mov cx,delai_select
b1:
push cx
tempo_vga
mouse_state
pop cx
cmp bx,0
if e jmp modifie_note_soundtracker      ; modification de la note
loop b1
; traitement de la cr‚ation du bloc:

; initialisation du bloc s‚lectionn‚
mov b cs:nb_voix_select,1
mov b cs:nb_notes_select,1
call proc_aff_select_soundtracker

boucle_select_soundtracker:
mouse_state
cmp bx,0
if e jmp traitement_select      ; un bloc a ‚t‚ s‚lectionn‚: on le traite!
mov ax,dx
sub ax,152
jns >l1
xor ax,ax
mov dl,cs:note_modifiee
mov dh,0
sub dx,cs:premiere_note_modifiee
jns >l1
; on passe … la partie sup‚rieure de la partition
mov w cs:premiere_note_modifiee,0
call proc_aff_soundtracker
mov b cs:flag_select_soundtracker,1
mouse_state
mov ax,4
mov dx,470
int 33h         ; curseur fix‚ en bas de l'‚cran
jmp boucle_select_soundtracker
l1:
mov dl,10
div dl
xor ah,ah
add ax,cs:premiere_note_modifiee
cmp al,63
if a mov al,63
mov ah,0
push ax
sub ax,cs:premiere_note_modifiee
cmp ax,32
pop ax
jb >l1
; on passe … le seconde page
mov w cs:premiere_note_modifiee,32
call proc_aff_soundtracker
mov b cs:flag_select_soundtracker,1
mov b cs:flag_select_soundtracker,1
mouse_state
mov ax,4
mov dx,156
int 33h         ; curseur fix‚ en haut de l'‚cran
jmp boucle_select_soundtracker
l1:
sub al,cs:note_modifiee
if s xor al,al
inc al
mov dl,al                       ; dl = nb_notes_select
mov ax,cx
mov cl,3
shr ax,cl
sub ax,4
if s xor ax,ax
mov cl,9
div cl
xor ah,ah
cmp al,7
if a mov al,7
sub al,cs:voix_note_modifiee
if s xor al,al
inc al
mov cl,al                       ; cl = nb_voix_select
cmp cl,cs:nb_voix_select
if e cmp dl,cs:nb_notes_select
if e jmp boucle_select_soundtracker   ; le bloc reste indentique!
call proc_aff_select_soundtracker
mov cs:nb_voix_select,cl
mov cs:nb_notes_select,dl
call proc_aff_select_soundtracker
jmp boucle_select_soundtracker

jmp menu_edition

; PROC_AFF_SELECT_SOUNDTRACKER (P)
; inverse le plan bleu au-dessus du bloc s‚lectionn‚
;**************************************************************************
flag_select_soundtracker        db 0
proc_aff_select_soundtracker:
cmp b cs:flag_select_soundtracker,0
mov b cs:flag_select_soundtracker,0
if ne ret
push ax,bx,cx,dx
; on fixe le plan bleu en lecture/‚criture
plans_ecriture_vga 1
plan_lecture_vga 0
; calcul du segment de la 1ø ligne … inverser
mov cl,cs:nb_notes_select
xor ch,ch               ; cx = nombre de lignes de partition … inverser
mov al,cs:note_modifiee
xor ah,ah
sub ax,cs:premiere_note_modifiee
jns >l1
mov ax,0   ; on commence … la premiŠre ligne si NOTE_MODIFIEE<PREMIERE_NOTE_MODIFIEE
add cl,cs:note_modifiee
sub cx,cs:premiere_note_modifiee        ; nombre de lignes r‚actualis‚
if s jmp fin_proc_aff_select_soundtracker       ; retour si bloc invisible
l1:
mov bx,50
mul bx
add ax,0A2F8h
mov es,ax               ; ES = premiŠre ligne … inverser
                        ; CX = nb de lignes de partition … inverser
b1:
push cx,es

mov cx,9        ; 9 lignes graphiques = 1 ligne de partition
b2:
push cx

mov al,cs:voix_note_modifiee
mov ah,9
mul ah
add ax,4
mov di,ax       ; DI point sur le premier octet … inverser
mov cl,cs:nb_voix_select
xor ch,ch
b3:
push cx

mov cx,9
b4:
not b es:[di]
inc di
loop b4

pop cx
loop b3

pop cx
mov ax,es
add ax,5        ; nouvelle ligne graphique
mov es,ax
loop b2

pop es,cx
mov ax,es
add ax,50       ; 10 lignes plus bas: nouvelle ligne de partition
mov es,ax
loop b1

fin_proc_aff_select_soundtracker:
pop dx,cx,bx,ax
ret

; MODIFIE_NOTE_SOUNDTRACKER (JMP)
; modification de la note
;**************************************************************************
modifie_note_soundtracker:

cmp b cs:donnee_note_modifiee,0
if ne jmp apres_modifie_note_soundtracker
; d‚termination du sample, ou bien demande … l'utilisateur
adresse_note_modifiee
mov cl,cs:note_modifiee
inc cl
xor ch,ch
b1:
mov al,es:[si]
and al,10h
mov ah,es:[si+2]
push cx
mov cl,4
shr ah,cl
pop cx
or al,ah
sub si,32       ; ligne pr‚c‚dente
cmp al,0
if e loop b1    ; ligne pr‚c‚dente si sample toujours pas d‚termin‚
dec al          ; AL = num‚ro de l'instrument (0FFh = pas d'instrument connu)
cmp al,0FFh
if e choix_sample_2     ; choix de l'instrument (sans annulation possible)
mov cs:ins_modifie_note_soundtracker,al
; affichage du piano
call proc_aff_piano
; d‚termination d'une note
b1:
call proc_joue_piano
cmp al,1        ; choix d‚finitif ?
je >l1
mov al,cs:ins_modifie_note_soundtracker
lance_sample
jmp b1
l1:
cmp b cs:mod_status,2
push ax
if e stop_mod   ; arrˆt des sons instrumentaux
pop ax
mov bl,ah
mov bh,0
shl bx,1
mov ax,cs:table_notes_mod[bx]           ; AX = note
mov bl,cs:ins_modifie_note_soundtracker
inc bl
and bl,0F0h
or ah,bl
adresse_note_modifiee
mov es:[si],ah
mov es:[si+1],al
and b es:[si+2],0Fh
mov al,cs:ins_modifie_note_soundtracker
inc al
mov cl,4
shl al,cl
or es:[si+2],al                 ; note et instrument stock‚s!
mov b cs:fichier_modifie,1      ; indique que le fichier est modifi‚
jmp menu_edition                ; modif. termin‚e, retour … l'‚dition.
ins_modifie_note_soundtracker   db ?
apres_modifie_note_soundtracker:

cmp b cs:donnee_note_modifiee,1
jne >l1
; modification de l'instrument
adresse_note_modifiee
;mov ah,es:[si]
;mov al,es:[si+1]
;and ah,0Fh
;cmp ax,0
;jne >l2
;mov b cs:donnee_note_modifiee,0
;jmp modifie_note_soundtracker   ; cr‚ation de la note n‚cessaire
;l2:
choix_sample
cmp al,31
if e jmp menu_edition           ; instrument pas modifi‚
adresse_note_modifiee
inc al
mov ah,al
and ah,0F0h
and b es:[si],0Fh
or es:[si],ah
mov cl,4
shl al,cl
and b es:[si+2],0Fh
or es:[si+2],al                 ; num‚ro de l'instrument ‚crit
mov b cs:fichier_modifie,1      ; indique que l'on a modifie le bestiaux
jmp menu_edition
l1:

; modif. de la commande
jmp modifie_commande

; COLLER_SOUNDTRACKER (JMP)
; proc‚dure pour coller le bloc dans la partition
;**************************************************************************
coller_soundtracker:
affiche_menus
rectangle_vga 69,50,79,127,0    ; on efface l'ascenceur
bloc1_vga 10,83,58,124
init_bouton 0,48,91,56,116,49,96,'Annuler'
gotoxy_vga 13,96
aff_chaine_vga 'Cliquez … l',27h,'endroit o— coller...'
b1:
souris_menus
test_zone_souris 32,152,607,471,>l1     ; coller ?
sub dx,152
mov ax,cx
sub ax,32
mov cl,72
div cl
mov cs:voix_note_modifiee,al
add al,cs:nb_voix_bloc
cmp al,8
if a jmp message_erreur_coller_bloc
mov ax,dx
mov dl,10
div dl
mov ah,0
add ax,cs:premiere_note_modifiee
mov cs:note_modifiee,al
add al,cs:nb_notes_bloc
cmp al,64
if a jmp message_erreur_coller_bloc
lache_souris
call proc_coller_bloc
jmp menu_edition
l1:
test_souris_bouton 0,>l1     ; annuler ?
jmp menu_edition
l1:
jmp b1

