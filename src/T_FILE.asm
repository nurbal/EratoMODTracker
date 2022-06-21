;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_file.a
; (menu fichier)
;**************************************************************************

; d‚but du menu
;**************************************************************************
menu_fichier:

; d‚finit le menu des options
menu2 nouveau_fichier,'NOUVEAU',2,8, charger_fichier,'CHARGER',11,17, sauver_fichier,'SAUVER',20,25, changer_titre,'CHANGER-TITRE',28,40, quitter_programme,'QUITTER',71,77
cls_menus

b1:
souris_menus
jmp b1

; nouveau fichier
;**************************************************************************
nouveau_fichier:
cmp b cs:fichier_modifie,0
if e jmp ok_nouveau_fichier
cls_menus
call proc_message_pas_sauve
gotoxy_vga 26,200
couleur_texte_vga 4
bloc1_vga 20,180,59,279
aff_chaine_vga 'NOUVEAU: Etes-vous certain ?'
init_bouton 0,25,230,54,259,35,238,'Absolument.'
b1:
souris_menus
test_souris_bouton 0,b1
; nouveau_fichier:
ok_nouveau_fichier:
call proc_new_mod
mov b cs:fichier_modifie,0
mov ds,cs
mov es,cs
mov si,offset nom_nouveau_fichier
mov di,offset nom_fichier
mov cx,13
cld
rep movsb
mov si,offset titre_nouveau_mod
mov di,offset titre_mod
mov cx,20
cld
rep movsb
cls_menus
police_vga 2
gotoxy_vga 30,223
couleur_texte_vga 1
bloc1_vga 20,180,59,279
aff_chaine_vga 'Nouveau module cr‚‚.'
b1:
souris_menus
jmp b1
nom_nouveau_fichier     db 'ERATO_10.MOD',0
titre_nouveau_mod       db 'Erato Tracker v1.0',0,0

; message: "XXXXX.MOD n'est pas sauv‚!"
;**************************************************************************
proc_message_pas_sauve:
bloc1_vga 20,100,59,149
police_vga 2
couleur_texte_vga 4
gotoxy_vga 26,118
mov ds,cs
mov si,offset nom_fichier
call proc_aff_chaine_vga
aff_chaine_vga ' n',27h,'est pas sauv‚!'
ret

; quitter le programme
;**************************************************************************
quitter_programme:
cls_menus
cmp b cs:fichier_modifie,1
if e call proc_message_pas_sauve
gotoxy_vga 26,200
couleur_texte_vga 4
bloc1_vga 20,180,59,279
aff_chaine_vga 'QUITTER: Etes-vous certain ?'
init_bouton 0,25,230,54,259,35,238,'Absolument.'
b1:
souris_menus
test_souris_bouton 0,b1
; fin du programme:
jmp fin_programme

; charger un fichier
;**************************************************************************
segment_directory       dw ?
charger_fichier:
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

boucle_charge_fichier:
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
cmp b cs:directory_modifiee,1
if e jmp boucle_affiche_fichiers        ; recherches inutiles

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
; recherche des modules
mov ds,cs
mov dx,offset filtre_modules
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
mov ax,cs:[154]
mov es:[di+14],ax
mov ax,cs:[156]
mov es:[di+16],ax       ; taille transf‚r‚e
inc w cs:nb_fichiers
cmp w cs:nb_fichiers,300
if e jmp fin_recherche_charger_fichier
add di,64       ; avancement dans la table
l2:
push di
mov ah,4Fh
int 21h         ; on cherche le module suivant...
pop di
jnc b1  ; on continue tant qu'il y a des modules … trouver!
l1:
; recherche des modules *.NST
mov ds,cs
mov dx,offset filtre_nst
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
mov ax,cs:[154]
mov es:[di+14],ax
mov ax,cs:[156]
mov es:[di+16],ax       ; taille transf‚r‚e
inc w cs:nb_fichiers
cmp w cs:nb_fichiers,300
if e jmp fin_recherche_charger_fichier
add di,64       ; avancement dans la table
l2:
push di
mov ah,4Fh
int 21h         ; on cherche le module suivant...
pop di
jnc b1  ; on continue tant qu'il y a des modules … trouver!
l1:
fin_recherche_charger_fichier:
; ouverture de tous les modules pour infos compl‚mentaires...
;cmp b cs:current_drive,2
;if b jmp apres_lit_entetes_fichiers
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
if e jmp apres_lit_entetes_fichiers
b1:
push cx,si
cmp b [si+13],1
if e jmp pas_un_module
mov dx,si
mov ax,3D00h
push si
push ds
int 21h
pop ds
mov dx,19200
mov cx,1084
mov bx,ax
mov ah,3Fh
push bx
int 21h
pop bx
mov ah,3Eh
int 21h
pop si
push si
mov di,si
add di,18
mov es,cs:segment_directory
push es
pop ds
mov si,19200
mov cx,19
cld
rep movsb
mov al,0
stosb           ; titre transf‚r‚
pop si
mov ax,[20280]
mov bx,[20282]
mov b [si+38],4
mov b [si+41],15
cmp bh,'6'
if ne cmp bh,'8'
jne >l3
sub bh,'0'
mov [si+38],bh  ; nb de voies transf‚r‚
mov b [si+41],31
jmp >l2
l3:
cmp bl,'6'
if ne cmp bl,'8'
jne >l3
sub bl,'0'
mov [si+38],bl  ; nb de voies transf‚r‚
mov b [si+41],31
jmp >l2
l3:
cmp ah,'6'
if ne cmp ah,'8'
jne >l3
sub ah,'0'
mov [si+38],ah  ; nb de voies transf‚r‚
mov b [si+41],31
jmp >l2
l3:
cmp al,'6'
if ne cmp al,'8'
jne >l2
sub al,'0'
mov [si+38],al  ; nb de voies transf‚r‚
mov b [si+41],31
l2:
cmp al,'M'
if e cmp bl,'K'
if e mov b [si+41],31   ; nb maxi d'instruments transf‚r‚
cmp b [si+41],31
if e mov al,[20150]
if ne mov al,[19670]
mov [si+39],al          ; song length transf‚r‚
if e mov di,20152
if ne mov di,19672
mov cx,128
mov al,0
b2:
cmp al,[di]
if b mov al,[di]
inc di
loop b2
inc al
mov [si+40],al          ; nb patterns transf‚r‚
mov ah,0
mov dx,0
cmp b [si+38],4
if e mov dx,1024
cmp b [si+38],6
if e mov dx,512
mul dx
add [si+14],ax
adc [si+16],dx          ; correction de la taille en pr‚vision du chargement
                        ; en 8 pistes au lieu de 4 ou 6
pas_un_module:
push ds
inc w cs:num_fichier
;tempo_vga
rectangle_vga 37,319,39,334,7
gotoxy_vga 37,319
mov ax,cs:num_fichier
call proc_aff_word_vga
pop ds
pop si,cx
add si,64
dec cx
jcxz apres_lit_entetes_fichiers
jmp b1
apres_lit_entetes_fichiers:

mov b cs:directory_modifiee,1   ; on vient de tout explorer!

fin_recherche_fichiers:
mov w cs:num_fichier,0
boucle_affiche_fichiers:
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
aff_chaine_vga 'FICHIER      TAILLE  TITRE                VOIES LONG. PATTERNS SAMPLES'

; affichage des noms des fichiers
mov ax,cs:num_fichier
mov cx,cs:nb_fichiers
sub cx,ax
cmp cx,18
if a mov cx,18
cmp cx,0
if e jmp fin_affiche_noms_fichiers
push cx
mov cl,6
shl ax,cl
mov si,ax
pop cx
mov ax,cs:segment_directory
mov ds,ax       ; DS:SI=1ø nom de fichier
cmp cx,0
if e jmp fin_affiche_noms_fichiers
mov ax,180
boucle_affiche_noms_fichiers:
push cx,ax,si,ds
gotoxy_vga 3,ax
cmp b ds:[si+13],1
if e jmp affichage_repertoire
; affichage d'un module
couleur_texte_vga 11
push ax,si
call proc_aff_chaine_vga
pop si,ax
gotoxy_vga 16,ax
push ax
mov ax,ds:[si+14]
mov dx,ds:[si+16]
push si,ds
call proc_aff_dword_vga
pop ds,si
pop ax
;cmp b cs:current_drive,2
;if b jmp apres_affiche_details_fichiers
gotoxy_vga 45,ax
push ax,si,ds
mov al,[si+38]
mov ah,0
call proc_aff_word_vga
pop ds,si,ax
gotoxy_vga 66,ax
push ax,si,ds
mov al,[si+41]
mov ah,0
call proc_aff_word_vga
pop ds,si,ax
gotoxy_vga 51,ax
push ax,si,ds
mov al,[si+39]
mov ah,0
call proc_aff_word_vga
pop ds,si,ax
gotoxy_vga 57,ax
push ax,si,ds
mov al,[si+40]
mov ah,0
call proc_aff_word_vga
pop ds,si,ax
gotoxy_vga 24,ax
add si,18
call proc_aff_chaine_vga
apres_affiche_details_fichiers:
jmp >l2
affichage_repertoire:
; affichage d'un r‚pertoire
couleur_texte_vga 10
push ax
call proc_aff_chaine_vga
pop ax
gotoxy_vga 16,ax
aff_chaine_vga '(sous-r‚pertoire)'
l2:
pop ds,si,ax,cx
add ax,16
add si,64
dec cx
jcxz >l1
jmp boucle_affiche_noms_fichiers
l1:
fin_affiche_noms_fichiers:

boucle_souris_charge_fichier:
souris_menus
cmp dx,81
if b jmp change_disque
cmp cx,599
if a jmp change_num_fichier
lache_souris
cmp dx,180
if a jmp choisit_fichier
jmp boucle_souris_charge_fichier
; changement de drive
change_disque:
cmp dx,58
jb boucle_souris_charge_fichier
cmp cx,8
jb boucle_souris_charge_fichier
mov b cs:directory_modifiee,0   ; on vient de changer de disque!
sub cx,8
mov ax,cx
mov bl,56
div bl
;add al,2
mov bl,al
mov bh,0
cmp b cs:drive_present[bx],1
jne boucle_souris_charge_fichier
mov cs:current_drive,bl
mov dl,bl
mov ah,0Eh
int 21h         ; s‚lectionne un nouveau disque
jmp boucle_charge_fichier
; d‚filement du menu
change_num_fichier:
test_souris_bouton 1,>l1
mov ax,cs:num_fichier
add ax,18
cmp ax,cs:nb_fichiers
if b mov cs:num_fichier,ax
jmp boucle_affiche_fichiers
l1:
test_souris_bouton 0,boucle_souris_charge_fichier
sub w cs:num_fichier,18
cmp w cs:num_fichier,0
if l mov w cs:num_fichier,0
jmp boucle_affiche_fichiers
; choix du fichier...
choisit_fichier:
cmp cx,24
if b jmp boucle_souris_charge_fichier
cmp cx,599
if a jmp boucle_souris_charge_fichier
cmp dx,467
if a jmp boucle_souris_charge_fichier
sub dx,181
mov ax,dx
mov bl,16
div bl
mov ah,0
add ax,cs:num_fichier
cmp ax,cs:nb_fichiers
if ae jmp boucle_souris_charge_fichier
mov cs:num_fichier,ax
mov cl,6
shl ax,cl
mov si,ax
mov es,cs:segment_directory   ; es:si pointe sur le fichier...
cmp b es:[si+13],0
je >l1          ; c'est d'un fichier qu'il s'agit!
; changement de r‚pertoire...
push es
pop ds
mov dx,si
mov ah,3Bh
int 21h         ; changement de r‚pertoire
mov b cs:directory_modifiee,0   ; on a chang‚ de r‚pertoire
jmp boucle_charge_fichier
; chargement d'un fichier...
l1:
; test m‚moire
mov ax,es:[si+14]
mov dx,es:[si+16]
add ax,15
adc dx,0
mov bx,16
div bx
mov bx,ax       ; BX = taille (en paragraphes)
mov ax,segment_buffers_mod
sub ax,cs:segment_patterns
;sub ax,31       ; AX = taille maxi (en paragraphes)
cmp ax,bx
if b jmp fichier_trop_gros
; sauvegarde de l'adresse du nom du fichier:
mov cs:data_load_file,si
mov ax,es
mov cs:data_load_file[2],ax
; n'y a-t-il pas un fichier … sauvegarder d'abbord?
cmp b cs:fichier_modifie,0
if e jmp ok_charger_fichier
cls_menus
call proc_message_pas_sauve
gotoxy_vga 26,200
couleur_texte_vga 4
bloc1_vga 20,180,59,279
aff_chaine_vga 'CHARGER: Etes-vous certain ?'
init_bouton 2,25,230,54,259,35,238,'Absolument.'
b1:
souris_menus
test_souris_bouton 2,b1
; ok pour charger quand mˆme:
ok_charger_fichier:
mov b cs:fichier_modifie,0
; tranfert du nom
mov si,cs:data_load_file
mov ax,cs:data_load_file[2]
mov ds,ax       ; ds:si = nom du fichier
mov es,cs
mov di,offset nom_fichier
cld
mov cx,13
rep movsb       ; nom du fichier transf‚r‚ dans NOM_FICHIER
; ouverture du fichier
mov ax,3D00h
mov ds,cs
mov dx,offset nom_fichier
int 21h
mov cs:handle_mod,ax    ; handle pass‚ … la partie T_MOD.A
call proc_charge_mod
jmp menu_fichier
data_load_file  dw 2 dup ?

; fichier trop gros pour ˆtre contenu en m‚moire:
fichier_trop_gros:
bloc1_vga 20,270,59,361
couleur_texte_vga 4
gotoxy_vga 28,299
aff_chaine_vga 'Ce fichier est trop gros'
gotoxy_vga 26,319
aff_chaine_vga 'pour ˆtre charg‚ en m‚moire.'
souris_menus
lache_souris
; mov w cs:num_fichier,0
jmp boucle_affiche_fichiers

current_drive   db ?
drive_present   db 13 dup ? ; (1=pr‚sent, 0=inexistant)
nb_fichiers     dw ?
filtre_repertoires db '*.*',0
filtre_modules  db '*.MOD',0
filtre_nst      db '*.NST',0
num_fichier     dw ?
nom_fichier     db 'ERATO_10.MOD',0
fichier_modifie db 0
directory_modifiee      db 0

; SAUVER_FICHIER (JMP)
; proc‚dure de sauvegarde de fichier
;**************************************************************************
format_fichier  db 0
sauver_fichier:
cls_menus

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

; exploration du fichier (patterns): 4, 6 ou 8 voies?
mov b cs:format_fichier,0
mov al,cs:nb_patterns
mov ah,0
mov cl,6
shl ax,cl
mov cx,ax       ; cx = nb de lignes … explorer
mov es,cs:segment_patterns
mov si,16
b1:
cmp w es:[si],0
if e cmp w es:[si+2],0
if e cmp w es:[si+4],0
if e cmp w es:[si+6],0
if ne mov b cs:format_fichier,1
cmp w es:[si+8],0
if e cmp w es:[si+10],0
if e cmp w es:[si+12],0
if e cmp w es:[si+14],0
je >l1
mov b cs:format_fichier,2
jmp >l2
l1:
add si,32
loop b1
l2:

bloc1_vga 20,160,59,369
couleur_texte_vga 4
police_vga 2
bloc1_vga 28,180,51,209
gotoxy_vga 30,187
aff_chaine_vga 'Sauvegarde Du Module'
init_bouton 0,43,290,54,319,44,297,'R‚pertoire'
init_bouton 1,43,320,54,349,48,327,'OK'
gotoxy_vga 25,297
aff_chaine_vga 'Nom du fichier:'
mov al,cs:format_fichier
mov ah,10
mul ah
add ax,25
gotoxy_vga ax,220
couleur_texte_vga 4
aff_chaine_vga 'conseill‚:'
sub w cs:x_texte_vga,7
mov w cs:y_texte_vga,234
aff_chaine_vga 25,'  ',25

boucle_sauver_fichier:
bloc2_vga 25,320,39,349
gotoxy_vga 26,327
couleur_texte_vga 15
mov ds,cs
mov si,offset nom_fichier
call proc_aff_chaine_vga
bloc1_vga 25,250,34,279
bloc1_vga 35,250,44,279
bloc1_vga 45,250,54,279
couleur_texte_vga 1
gotoxy_vga 26,257
aff_chaine_vga '4 voies   6 voies   8 voies'
mov al,cs:format_fichier
mov ah,10
mul ah
add ax,25
mov bx,ax
add bx,9
bloc3_vga ax,250,bx,279
couleur_texte_vga 4
cmp b cs:format_fichier,0
jne >l1
gotoxy_vga 26,257
mov al,'4'
call proc_aff_carac_vga
l1:
cmp b cs:format_fichier,1
jne >l1
gotoxy_vga 36,257
mov al,'6'
call proc_aff_carac_vga
l1:
cmp b cs:format_fichier,2
jne >l1
gotoxy_vga 46,257
mov al,'8'
call proc_aff_carac_vga
l1:
aff_chaine_vga ' voies'
lache_souris

; boucle: on regarde ce que fait l'utilisateur (… la souris bien ‚videmment)
b1:
souris_menus
test_zone_souris 200,250,439,279,>l1    ; format du fichier ?
sub cx,200
mov ax,cx
mov cl,80
div cl
mov cs:format_fichier,al
jmp boucle_sauver_fichier
l1:
test_zone_souris 200,320,319,349,>l1    ; nom du fichier ?
jmp change_nom_fichier_mod
l1:
test_souris_bouton 0,>l1    ; r‚pertoire ?
call proc_choix_directory
jmp sauver_fichier
l1:
test_souris_bouton 1,>l1    ; OK ?
jmp sauver_fichier_2
l1:
jmp b1

jmp menu_fichier

; SAUVER_FICHIER_2 (JMP)
; sauve le fichier pour de bon, en utilisant le format FORMAT_FICHIER
; (0=4 voies, 1=6 voies, 2=8 voies)
;**************************************************************************
ciaa_sauver     db 78h
id_sauver       db 'M.K.','6CHN','8CHN'
ins_data_sauver db 8 dup ?
sauver_fichier_2:
mov b cs:directory_modifiee,0   ; on a chang‚ le contenu de SEGMENT_DIRECTORY
; cr‚ation du fichier
mov ds,cs
mov dx,offset nom_fichier
mov ax,5B00h
mov cx,0
int 21h
if nc jmp creation_fichier_ok   ; cr‚ation OK
mov ah,59h      ; erreur: laquelle?
int 21h
cmp ax,50h      ; fichier existant d‚j… ?
if ne jmp erreur2_fichier_sauver        ; erreur d'ouverture inconnue
; fichier existant: confirmation
bloc1_vga 25,200,54,309
couleur_texte_vga 4
gotoxy_vga 28,210
mov ds,cs
mov si,offset nom_fichier
call proc_aff_chaine_vga
aff_chaine_vga ' existe d‚j…!'
init_bouton 0,33,240,46,269,35,247,'Remplacer!'
init_bouton 1,33,270,46,299,37,277,'Retour'
b1:
souris_menus
test_souris_bouton 1,>l1        ; Retour ?
jmp sauver_fichier
l1:
test_souris_bouton 0,b1
; cr‚ation de force:
mov ds,cs
mov dx,offset nom_fichier
mov ax,3C00h
mov cx,0
int 21h
if c jmp erreur2_fichier_sauver ; erreur … la cr‚ation du fichier
; cr‚ation OK
creation_fichier_ok:
mov cs:handle_mod,ax
; ‚criture de l'entete
mov bx,cs:handle_mod
mov ds,cs
mov dx,offset titre_mod
mov cx,20
mov ah,40h
int 21h                 ; ‚criture du titre
if c jmp erreur_fichier_sauver
cmp ax,20
if ne jmp erreur_fichier_sauver
mov cx,31               ; 31 samples … sauver
mov dx,0                ; num‚ro du sample
boucle_sauve_sample_fichier:
push cx,dx
mov bx,dx
shl bx,1
mov ax,cs:longueurs_samples[bx]
shr ax,1
mov cs:ins_data_sauver[0],ah
mov cs:ins_data_sauver[1],al    ; longueurs en mots
mov ax,cs:finetunes_samples[bx]
mov b cs:ins_data_sauver[2],al  ; accord fin
mov ax,cs:volumes_samples[bx]
mov cs:ins_data_sauver[3],al    ; volume        (0 … 64)
mov ax,cs:debuts_boucles_samples[bx]
shr ax,1
mov cs:ins_data_sauver[4],ah
mov cs:ins_data_sauver[5],al    ; d‚but de boucle en mots
mov ax,cs:longueurs_boucles_samples[bx]
shr ax,1
mov cs:ins_data_sauver[6],ah
mov cs:ins_data_sauver[7],al    ; longueur de boucle en mots
mov al,22
mul dl
add ax,offset noms_samples
mov dx,ax
mov bx,cs:handle_mod
mov ds,cs
mov cx,22
mov ah,40h
int 21h                 ; ‚criture du nom du sample
jc >l0
cmp ax,22
je >l1
l0:
pop dx,cx
jmp erreur_fichier_sauver
l1:
mov dx,offset ins_data_sauver
mov bx,cs:handle_mod
mov ds,cs
mov cx,8
mov ah,40h
int 21h                 ; ‚criture des donn‚es du sample
pop dx,cx
if c jmp erreur_fichier_sauver
cmp ax,8
if ne jmp erreur_fichier_sauver
inc dx                  ; num‚ro de sample+1
dec cx
jcxz >l1
jmp boucle_sauve_sample_fichier ; sample suivant
l1:
mov dx,offset nb_positions
mov bx,cs:handle_mod
mov ds,cs
mov cx,1
mov ah,40h
int 21h                 ; ‚criture de la longueur en positions
if c jmp erreur_fichier_sauver
cmp ax,1
if ne jmp erreur_fichier_sauver
mov dx,offset ciaa_sauver
mov bx,cs:handle_mod
mov ds,cs
mov cx,1
mov ah,40h
int 21h                 ; ‚criture de l'octet CIAA (aucune signification...)
if c jmp erreur_fichier_sauver
cmp ax,1
if ne jmp erreur_fichier_sauver
mov dx,offset table_positions
mov bx,cs:handle_mod
mov ds,cs
mov cx,128
mov ah,40h
int 21h                 ; ‚criture de l'arrangement
if c jmp erreur_fichier_sauver
cmp ax,128
if ne jmp erreur_fichier_sauver
mov al,cs:format_fichier
shl al,1
shl al,1
mov ah,0
add ax,offset id_sauver
mov dx,ax
mov bx,cs:handle_mod
mov ds,cs
mov cx,4
mov ah,40h
int 21h                 ; ‚criture de l'identificateur (4,6 ou 8 voix)
if c jmp erreur_fichier_sauver
cmp ax,4
if ne jmp erreur_fichier_sauver
; sauvegarde des patterns
mov ah,0
mov al,cs:nb_patterns
mov cl,6
shl ax,cl
mov cx,ax               ; CX = nb de lignes … sauvegarder
mov ax,cs:segment_patterns      ; AX = segment
b1:
push ax,cx
mov dx,0
mov bx,cs:handle_mod
mov ds,ax
mov cx,16
cmp b cs:format_fichier,1
if e mov cx,24
cmp b cs:format_fichier,2
if e mov cx,32
push cx
mov ah,40h
int 21h                 ; ‚criture de la ligne
pop cx
pushf
cmp ax,cx
je >l1
popf
pop cx,ax
jmp erreur_fichier_sauver
l1:
popf
pop cx,ax
if c jmp erreur_fichier_sauver
add ax,2        ; ligne suivante
loop b1
; sauvegarde des samples
mov cx,31       ; 31 sample … sauvegarder
mov bx,0        ; pointeur dans les tables
b1:
cmp w cs:longueurs_samples[bx],1
jbe >l1
push bx,cx
mov ax,cs:segments_samples[bx]
mov ds,ax
mov dx,0
mov cx,cs:longueurs_samples[bx]
and cx,0FFFEh
mov ah,40h
mov bx,cs:handle_mod
int 21h                 ; ‚criture du sample
pop cx,bx
if c jmp erreur_fichier_sauver
mov dx,cs:longueurs_samples[bx]
and dx,0FFFEh
cmp ax,dx
if ne jmp erreur_fichier_sauver
l1:
add bx,2
loop b1         ; sample suivant
; fermeture du fichier
mov bx,cs:handle_mod
mov ah,3Eh
int 21h
; accus‚ r‚ception de la sauvegarde
mov b cs:fichier_modifie,0
jmp menu_fichier

erreur_fichier_sauver:
; fermeture du fichier
mov bx,cs:handle_mod
mov ah,3Eh
int 21h
erreur2_fichier_sauver:
police_vga 2
couleur_texte_vga 4
bloc1_vga 18,180,61,314
gotoxy_vga 22,210
aff_chaine_vga 'Sauvegarde de fichier impossible !!!'
gotoxy_vga 24,250
aff_chaine_vga 'Disque plein ? Disque non-prˆt ?'
gotoxy_vga 28,270
aff_chaine_vga 'Disque/Fichier prot‚g‚ ?'
b1:
souris_menus
jmp b1

change_nom_fichier_mod:
bloc2_vga 25,320,39,349
gotoxy_vga 26,327
couleur_texte_vga 14
mov ds,cs
mov si,offset nom_fichier
call proc_aff_chaine_vga
mov al,219
call proc_aff_carac_vga
mov ah,0
int 22
cmp al,13       ; entree ?
if e jmp apres_change_nom_fichier_mod
cmp al,8        ; <-DEL ?
jne >l1
mov bx,0
b1:
cmp b cs:nom_fichier[bx+1],0
if e mov b cs:nom_fichier[bx],0
inc bx
cmp bx,12
jne b1
jmp change_nom_fichier_mod
l1:
cmp al,21h
jb >l1
cmp al,0A8h
ja >l1
mov bx,0
b1:
cmp b cs:nom_fichier[bx],0
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
mov cs:nom_fichier[bx],al
l1:
jmp change_nom_fichier_mod
apres_change_nom_fichier_mod:
; correction du nom du fichier
; recherche du '.' (on ne sauve que des . mod!)
mov bx,0
b1:
cmp b cs:nom_fichier[bx],0
je >l1
cmp b cs:nom_fichier[bx],'.'
je >l2
cmp bx,8
je >l1
inc bx
jmp b1
l1:
mov b cs:nom_fichier[bx],'.'
mov b cs:nom_fichier[bx+1],'M'
mov b cs:nom_fichier[bx+2],'O'
mov b cs:nom_fichier[bx+3],'D'
l2:
mov b cs:nom_fichier[bx+4],0
jmp boucle_sauver_fichier

; PROC_CHOIX_DIRECTORY (P)
; affiche un menu pour changer de directory
;**************************************************************************
data_proc_choix_directory       dw ?
proc_choix_directory:
pop ax
mov cs:data_proc_choix_directory,ax

mov b cs:directory_modifiee,0   ; on a chang‚ le contenu de SEGMENT_DIRECTORY

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

boucle_change_directory:
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
mov si,0
push ds,si
mov ah,47h
mov dl,cs:current_drive
add dl,1        ; unit‚ par d‚faut
int 21h         ; demande le r‚pertoire courant
pop si,ds
call proc_aff_chaine_vga

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
mov ds,cs
mov si,158
cld
mov cx,13
push di
rep movsb       ; nom transf‚r‚
pop di
inc w cs:nb_fichiers
cmp w cs:nb_fichiers,133
je >l1
add di,16       ; avancement dans la table
l2:
push di
mov ah,4Fh
int 21h         ; on cherche le r‚pertoire suivant...
pop di
jnc b1  ; on continue tant qu'il y a des r‚pertoires … trouver!

; fin de la recherche des r‚pertoires
l1:

couleur_texte_vga 1
rectangle_vga 3,144,70,159,7
gotoxy_vga 3,144
mov ax,cs:nb_fichiers
call proc_aff_word_vga
aff_chaine_vga ' r‚pertoires trouv‚s:'
bloc2_vga 1,160,64,473
; bouton OK:
init_bouton 0,66,160,77,473,71,309,'OK'

; affichage des noms de r‚pertoires
couleur_texte_vga 10
mov cx,cs:nb_fichiers
cmp cx,0
if e jmp apres_affiche_noms_reprtoires
mov ax,0
mov ds,cs:segment_directory
mov si,0
b1:
push si,ax,cx
mov bl,19
div bl
mov bh,al       ; bh = colonne
mov al,16
mul ah
add ax,165
mov cs:y_texte_vga,ax
mov al,9
mul bh
add ax,2
mov cs:x_texte_vga,ax
call proc_aff_chaine_vga
pop cx,ax,si
inc ax
add si,16
loop b1
apres_affiche_noms_reprtoires:
; boucle principale
b1:
souris_menus
test_souris_bouton 0,>l1    ; OK ?
jmp >l2
l1:
test_zone_souris 8,58,639,81,>l1        ; changement de drive ?
jmp change_disque_choix_directory
l1:
test_zone_souris 16,165,511,468,b1      ; un r‚pertoire est choisi ?
jmp >l3

; sortie de la proc‚dure:
l2:
mov ax,cs:data_proc_choix_directory
push ax
ret

; un r‚pertoire a ‚t‚ choisi:
l3:
sub cx,16
sub dx,165
mov ax,dx
mov bl,16
div bl
mov ah,0
mov dx,ax       ; dx = ligne
mov ax,cx
mov cl,72
div cl
mov ah,19
mul ah
add dx,ax       ; dx = num‚ro du r‚pertoire choisi
cmp dx,cs:nb_fichiers
if ae jmp boucle_change_directory
mov cl,4
shl dx,cl
mov ds,cs:segment_directory   ; es:si pointe sur le fichier...
; changement de r‚pertoire...
mov ah,3Bh
int 21h         ; changement de r‚pertoire
lache_souris
jmp boucle_change_directory

change_disque_choix_directory:
sub cx,8
mov ax,cx
mov bl,56
div bl
mov bl,al
mov bh,0
cmp b cs:drive_present[bx],1
if ne jmp boucle_change_directory
mov cs:current_drive,bl
mov dl,bl
mov ah,0Eh
int 21h         ; s‚lectionne un nouveau disque
jmp boucle_change_directory


; CHANGER_TITRE (JMP)
; change le titre du module
;**************************************************************************
changer_titre:
cls_menus
bloc1_vga 25,205,54,290
police_vga 2
couleur_texte_vga 1
gotoxy_vga 32,220
aff_chaine_vga 'Titre du module:'

boucle_changer_titre:
bloc2_vga 29,240,50,275
gotoxy_vga 30,250
couleur_texte_vga 15
mov ds,cs
mov si,offset titre_mod
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
mouse_on
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
cmp b cs:titre_mod[bx],0
jne b0
cmp al,8        ; <-DEL ?
jne >l1
cmp bx,0
je b1   ; pas de caractŠre … effacer
mov b cs:titre_mod[bx-1],0
mov b cs:fichier_modifie,1
mouse_off
jmp boucle_changer_titre
l1:
cmp al,13       ; ENTREE ?
jne >l1
mouse_off
jmp menu_fichier
l1:
; inscription du caractŠre
cmp bx,19
je b1
mov cs:titre_mod[bx],al
mov b cs:fichier_modifie,1
mouse_off
jmp boucle_changer_titre
