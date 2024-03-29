;**************************************************************************
; programme TRACKER (nom provisoire)
;**************************************************************************
; fichier t_procs.a
;               - ensemble de proc‚dures d'interrˆt g‚n‚ral...
;**************************************************************************

; test souris
;**************************************************************************
mov ax,0
int 33h
cmp ax,0
ja >l1
mov ah,9
push cs
pop ds
mov dx,offset message_erreur_souris_absente
int 21h
ret
message_erreur_souris_absente db 'Souris absente...',13,10,'$'
graphe_souris   dw 1111000011111111xb
                dw 1111000000111111xb
                dw 1111000000011111xb
                dw 1111000000001111xb
                dw 1111000100000111xb
                dw 1111000111000001xb
                dw 1111000111111111xb
                dw 1111000111111111xb
                dw 1111100011111111xb
                dw 1111100011111111xb
                dw 1100000011111111xb
                dw 1000000011111111xb
                dw 0000000011111111xb
                dw 0000000011111111xb
                dw 1000000111111111xb
                dw 1100001111111111xb

                dw 0000111100000000xb
                dw 0000100011000000xb
                dw 0000100000100000xb
                dw 0000101100010000xb
                dw 0000101011001000xb
                dw 0000101000111110xb
                dw 0000101000000000xb
                dw 0000101000000000xb
                dw 0000010100000000xb
                dw 0000010100000000xb
                dw 0011110100000000xb
                dw 0100000100000000xb
                dw 1000000100000000xb
                dw 1000000100000000xb
                dw 0100001000000000xb
                dw 0011110000000000xb
l1:

; test m‚moire (640k)
;**************************************************************************
int 18
cmp ax,640
jae >l1
mov ah,9
push cs
pop ds
mov dx,offset message_erreur_memoire
int 21h
ret
message_erreur_memoire db 'Pas assez de m‚moire: il faut 640 Ko au moins...',13,10,'$'
l1:

; traitement des erreurs disque (disque non prˆt, par exemple)
;**************************************************************************
; remplacement du vecteur d'interruption 24h
cli
mov es,0
mov ax,es:[144]
mov cs:ofs_int_24h,ax
mov ax,es:[146]
mov cs:seg_int_24h,ax
mov w es:[144],offset int_24h
mov ax,cs
mov es:[146],ax
sti
jmp >l1
; fausse interruption des erreurs critiques
int_24h:
mov al,0
iret
ofs_int_24h dw ?
seg_int_24h dw ?
l1:

; passage en mode graphique 640*480 16 couleurs:
;**************************************************************************
call proc_init_vga
; nouveau curseur souris
mov ax,9
mov bx,3        ; point de r‚f‚rence...
mov cx,13       ; ... = "boule" de la croche
mov dx,offset graphe_souris
mov es,cs
int 33h         ; graphe souris
mov ax,7
mov cx,0
mov dx,639
int 33h         ; positions X maxi/mini
mov ax,8
mov cx,0
mov dx,479
int 33h         ; positions Y maxi/mini

; appel du bloc suivant
;**************************************************************************
call fin_t_procs

; traitement des erreurs disque (disque non prˆt, par exemple)
;**************************************************************************
; replacement du vecteur d'interruption 24h
cli
mov es,0
mov ax,cs:ofs_int_24h
mov es:[144],ax
mov ax,cs:seg_int_24h
mov es:[146],ax
sti

; message d'au-revoir
;**************************************************************************
mov ax,3
int 16          ; mode texte 80 colonnes

mov ah,11h
mov al,12h
mov bl,0
int 16          ; mode 50 lignes

mov ax,0
mov es,0B800h
mov di,0
mov cx,3520
cld
rep stosw

mov ah,9
push cs
pop ds
mov dx,offset message_fin_tracker
int 21h


mov cx,80
mov di,1
b0:
push cx,di
call proc_tempo_vga
mov cx,44
mov es,0B800h
b1:
mov b es:[di],9
cmp di,158
ja >l1
mov b es:[di+2],3
cmp di,156
ja >l1
mov b es:[di+4],11
cmp di,154
ja >l1
mov b es:[di+6],15
cmp di,152
ja >l1
mov b es:[di+8],11
cmp di,150
ja >l1
mov b es:[di+10],3
cmp di,148
ja >l1
mov b es:[di+12],9
cmp di,146
ja >l1
mov b es:[di+14],1
cmp di,144
ja >l1
mov b es:[di+16],8
l1:
mov ax,es
add ax,10
mov es,ax
loop b1
pop di,cx
add di,2
loop b0

ret
message_fin_tracker:
db '                         ÛÛÛÛÛ ÛÛÛÛ   ÛÛÛ  ÛÛÛÛÛ  ÛÛÛ',13,10
db '                         Û     Û   Û Û   Û   Û   Û   Û',13,10
db '                         Û     Û   Û Û   Û   Û   Û   Û',13,10
db '                         ÛÛÛÛ  ÛÛÛÛ  ÛÛÛÛÛ   Û   Û   Û',13,10
db '                         Û     Û   Û Û   Û   Û   Û   Û',13,10
db '                         Û     Û   Û Û   Û   Û   Û   Û',13,10
db '                         Û     Û   Û Û   Û   Û   Û   Û',13,10
db '                         ÛÛÛÛÛ Û   Û Û   Û   Û    ÛÛÛ',13,10,10

db '                         ÛÛÛÛÛÛ v1.0 - á version ÛÛÛÛÛ',13,10
db '                         ÛÛÛÛÛÛÛÛ 24 ao–t 1995 ÛÛÛÛÛÛÛ',13,10,10,10



db '              Ceci est une version PROVISOIRE et NON DOCUMENTEE!!',13,10
db '                                   ----------    --------------',13,10,10

db '     Il  y manque pas mal de chose, comme par  exemple  des  commandes MOD.',13,10
db '    (il  y en a 30 en tout; 10 seulement sont pr‚sentes dans cette version !)',13,10
db '          Il manque ‚galement un mode d',27h,'‚dition du style "s‚quenceur":',13,10
db '        adieu les fastidieuses et illisibles colonnes des soundtrackers!',13,10,10

db '            Il est ‚galement possible que vous rencontriez des bugs',13,10
db '               qui m',27h,'auraient ‚chapp‚. Merci de me les signaler!',13,10,10

db '                                  Bruno Carrez',13,10
db '                            50 rue du Moulin L',27h,'Avou‚',13,10
db '                                62136 Richebourg',13,10
db '                                    (France)',13,10,10

db '    Une version plus approfondie sera bient“t disponible (‡a d‚pend surtout',13,10
db '                    de mes ‚tudes... je rentre en math sp‚!)',13,10,10

db '    Diffusez ce programme, copiez-le, donnez-le, offrez-le, t‚l‚chargez-le,',13,10
db '                  faxez-le, envoyez-le, dupliquez-le, mais...',13,10
db '                              NE LE MODIFIEZ PAS!',13,10

db '       Je suis dispos‚ … recevoir tous les conseils, remarques, insultes.',13,10
db '                   (je r‚pondrai dans la mesure du possible).',13,10
db '         ... et comme l',27h,'union fait la force, dingues de programmation,',13,10
db '                         prenez contact! (j',27h,'ai 19 ans)',13,10,10

db '                     ... et encore merci … Freddy V‚tel‚ !',13,10,10

db '    (note: tapez "MODE 80" si vous d‚sirez retrouver un ‚cran … 25 lignes.)',13,10,'$'




;**************************************************************************
; MACROS/PROCEDURES
;**************************************************************************

;**************************************************************************
; SOURIS
;**************************************************************************

; MOUSE_ON (M+P): affiche le curseur souris
;**************************************************************************
mouse_on macro
call proc_mouse_on
#em
proc_mouse_on:
push ax,bx,cx,dx
mov ax,1
int 33h
pop dx,cx,bx,ax
ret

; MOUSE_OFF (M+P): efface le curseur souris
;**************************************************************************
mouse_off macro
call proc_mouse_off
#em
proc_mouse_off:
push ax,bx,cx,dx
mov ax,2
int 33h
pop dx,cx,bx,ax
ret

; MOUSE_HIDE (M): cache le curseur souris sur une zone sp‚cifique de l'‚cran
;**************************************************************************
mouse_hide macro
mov cx,#1
mov dx,#2
mov si,#3
mov di,#3
call proc_mouse_hide
#em
proc_mouse_hide:
mov ax,2
shl cx,1
shl cx,1
shl cx,1
shl si,1
shl si,1
shl si,1
add si,7
int 33h
ret

; MOUSE_CLIC (M+P): attend un clic de la souris
;       retour: BX=boutons
;               CX=x
;               DX=y
;**************************************************************************
mouse_clic macro
call proc_mouse_clic
#em
proc_mouse_clic:
mov ax,3
int 33h
cmp bx,0
je proc_mouse_clic
ret

; MOUSE_STATE (M+P): retourne l'‚tat de la souris
;       retour: BX=boutons
;               CX=x
;               DX=y
;**************************************************************************
mouse_state macro
call proc_mouse_state
#em
proc_mouse_state:
mov ax,3
int 33h
ret

;**************************************************************************
; VGA (640*480*16c)
;**************************************************************************

; VARIABLES VGA
;**************************************************************************
seg_police_vga          dw ?
ofs_police_vga          dw ?
taille_police_vga       dw ?
var_couleur_texte_vga   db ?
x_texte_vga             dw ?
y_texte_vga             dw ?

; INIT_VGA (M+P): initialise le mode 640*480*16c
;**************************************************************************
init_vga macro
call proc_init_vga
#em
proc_init_vga:
mov ax,18
int 16
mov al,2
call proc_police_vga
mov b cs:var_couleur_texte_vga,15
ret

; PLANS_ECRITURE_VGA (M+P)
; modifie le registre de plans en ‚criture
;**************************************************************************
plans_ecriture_vga macro
push ax
mov al,#1
call proc_plans_ecriture_vga
pop ax
#em
proc_plans_ecriture_vga:
push ax,dx
mov ah,al
mov dx,3C4h
mov al,2
out dx,al
mov al,ah
and al,0Fh
inc dx
out dx,al
pop dx,ax
ret

; PLAN_LECTURE_VGA (M+P)
; modifie le registre de plan de lecture
;**************************************************************************
plan_lecture_vga macro
push ax
mov al,#1
call proc_plan_lecture_vga
pop ax
#em
proc_plan_lecture_vga:
push ax,dx
mov ah,al
mov dx,3CEh
mov al,4
out dx,al
mov al,ah
and al,03h
inc dx
out dx,al
pop dx,ax
ret

; COULEUR_TEXTE_VGA c (M): change la couleur courante du texte
;**************************************************************************
couleur_texte_vga macro
mov b cs:var_couleur_texte_vga,#1
#em

; POLICE_VGA p (M+P): change la police active
;               p=0: police 8*8
;               p=1: police 8*14
;               p=2: police 8*16
;**************************************************************************
police_vga macro
mov al,#1
call proc_police_vga
#em
proc_police_vga:
cmp al,2
if a ret
mov ah,11h
mov w cs:taille_police_vga,16
mov bh,6        ; police 8*16
cmp al,0
if e mov w cs:taille_police_vga,8
if e mov bh,3   ; police 8*8
cmp al,1
if e mov w cs:taille_police_vga,14
if e mov bh,2   ; police 8*14
mov al,30h
int 16
mov ax,es
mov cs:seg_police_vga,ax
mov ax,bp
mov cs:ofs_police_vga,ax
ret

; AFF_CARAC_VGA (P): affiche le caractŠre contenu dans AL
;**************************************************************************
proc_aff_carac_vga:
mov cx,cs:taille_police_vga
mul cl
add ax,cs:ofs_police_vga
mov si,ax
mov ax,cs:seg_police_vga
mov ds,ax       ; DS:SI pointe sur le caractŠre dans la table
mov es,0A000h
mov ax,cs:y_texte_vga
mov bx,80
mul bx
add ax,cs:x_texte_vga
mov di,ax       ; ES:DI pointe sur la destination du caractŠre
cld
mov cx,cs:taille_police_vga
mov dx,3C4h
mov al,2
out dx,al
mov dx,3CEh
mov al,4
out dx,al
b1:
push cx
mov bl,cs:var_couleur_texte_vga
mov ax,100h     ; ah=plans en ‚criture
                ; al=plan en lecture
mov cx,4
mov bh,ds:[si]  ; bh=ligne de 8 pixels … traiter dans les differents plans
b2:
push ax
mov dx,3CFh
out dx,al       ; plans en ‚criture
mov al,ah
mov dx,3C5h
out dx,al       ; plans en lecture
mov al,bh
shr bl,1        ; bit de couleur?
jnc >l1
; affichage:
or es:[di],al
jmp >l2
l1:
not al
and es:[di],al
l2:
pop ax
inc al          ; plan suivant
shl ah,1        ; plan suivant
loop b2
inc si
add di,80
pop cx
loop b1
mov ax,cs:x_texte_vga
inc ax
cmp ax,80
jb >l1
mov w cs:x_texte_vga,0
mov ax,cs:taille_police_vga
add cs:y_texte_vga,ax
ret
l1:
mov cs:x_texte_vga,ax
ret

; GOTOXY_VGA (M): va … la position sp‚cifi‚e
;**************************************************************************
gotoxy_vga macro
mov w cs:x_texte_vga,#1
mov w cs:y_texte_vga,#2
#em

; AFF_CHAINE_VGA (M+P): affiche une chaine de caractŠres
;**************************************************************************
aff_chaine_vga macro
jmp >m1
m2:
#rx1l
db #x
#er
db 0
m1:
push cs
pop ds
mov si,offset m2
call proc_aff_chaine_vga
#em
proc_aff_chaine_vga:
cld
p1:
cld
lodsb
cmp al,0
je >p2
push ds
push si
pushf
call proc_aff_carac_vga
popf
pop si
pop ds
jmp p1
p2:
ret

; RECTANGLE_VGA x1,y1,x2,y2,c (M+P)
; x1,y1,x2,y2: word
;**************************************************************************
rectangle_vga macro
mov w cs:data_rectangle_vga[0],#1
mov w cs:data_rectangle_vga[2],#2
mov w cs:data_rectangle_vga[4],#3
mov w cs:data_rectangle_vga[6],#4
mov b cs:couleur_rectangle_vga,#5
call proc_rectangle_vga
#em
data_rectangle_vga dw 4 dup ?
couleur_rectangle_vga db ?
proc_rectangle_vga:
push ax,bx,cx,dx,ds,es,di
push cs
pop ds
mov cx,data_rectangle_vga[6]
inc cx
mov ax,data_rectangle_vga[2]
sub cx,ax       ; cx=nombre de lignes
mov bx,5
mul bx
add ax,0A000h
mov es,ax       ; es=segment vid‚o de la 1ø ligne … modifier
b1:
push cx
plans_ecriture_vga 0Fh
out dx,al       ; ‚criture sur tous les plans
mov cx,data_rectangle_vga[4]
inc cx
mov di,data_rectangle_vga[0]
sub cx,di       ; cx=largeur (en octets)
cld
push cx,di
mov al,0
rep stosb
pop di,cx
plans_ecriture_vga couleur_rectangle_vga
mov al,0FFh
rep stosb
pop cx
mov ax,es
add ax,5
mov es,ax       ; ligne suivante!
loop b1
pop di,es,ds,dx,cx,bx,ax
ret

; BLOC1_VGA x1,y1,x2,y2 (M+P)
; x1,y1,x2,y2: word
;**************************************************************************
bloc1_vga macro
mov w cs:data_bloc_vga[0],#1
mov w cs:data_bloc_vga[2],#2
mov w cs:data_bloc_vga[4],#3
mov w cs:data_bloc_vga[6],#4
call proc_bloc1_vga
#em
data_bloc_vga dw 4 dup ?
proc_bloc1_vga:
push ax,bx,cx,dx,ds,es,di
mov ds,cs
; fond:
rectangle_vga data_bloc_vga[0],data_bloc_vga[2],data_bloc_vga[4],data_bloc_vga[6],7
; bord haut:
mov ax,data_bloc_vga[2]
add ax,3
rectangle_vga data_bloc_vga[0],data_bloc_vga[2],data_bloc_vga[4],ax,15
; bord bas:
mov ax,data_bloc_vga[6]
sub ax,3
rectangle_vga data_bloc_vga[0],ax,data_bloc_vga[4],data_bloc_vga[6],8
; bord gauche:
plans_ecriture_vga 8
mov ds,cs
mov cx,data_bloc_vga[6]
sub cx,data_bloc_vga[2]
sub cx,7
mov es,0A000h
mov ax,data_bloc_vga[2]
add ax,4
mov bx,80
mul bx
add ax,data_bloc_vga[0]
mov di,ax
b1:
mov b es:[di],0F0h
add di,80
loop b1
plans_ecriture_vga 7
mov b es:[di],0E0h
add di,80
mov b es:[di],0C0h
add di,80
mov b es:[di],080h
; bord droit:
plans_ecriture_vga 8
mov ds,cs
mov cx,data_bloc_vga[6]
sub cx,data_bloc_vga[2]
sub cx,7
mov es,0A000h
mov ax,data_bloc_vga[2]
add ax,4
mov bx,80
mul bx
add ax,data_bloc_vga[4]
mov di,ax
push di,cx
b1:
mov b es:[di],0Fh
add di,80
loop b1
plans_ecriture_vga 7
pop cx,di
push di
b1:
mov b es:[di],0F0h
add di,80
loop b1
pop di
sub di,320
mov b es:[di],0FEh
add di,80
mov b es:[di],0FCh
add di,80
mov b es:[di],0F8h
add di,80
mov b es:[di],0F0h
pop di,es,ds,dx,cx,bx,ax
ret

; BLOC2_VGA x1,y1,x2,y2 (M+P)
; x1,y1,x2,y2: word
;**************************************************************************
bloc2_vga macro
mov w cs:data_bloc_vga[0],#1
mov w cs:data_bloc_vga[2],#2
mov w cs:data_bloc_vga[4],#3
mov w cs:data_bloc_vga[6],#4
call proc_bloc2_vga
#em
proc_bloc2_vga:
push ax,bx,cx,dx,ds,es,di
mov ds,cs
; fond:
rectangle_vga data_bloc_vga[0],data_bloc_vga[2],data_bloc_vga[4],data_bloc_vga[6],0
; bord haut:
mov ax,data_bloc_vga[2]
add ax,3
rectangle_vga data_bloc_vga[0],data_bloc_vga[2],data_bloc_vga[4],ax,8
; bord bas:
mov ax,data_bloc_vga[6]
sub ax,3
rectangle_vga data_bloc_vga[0],ax,data_bloc_vga[4],data_bloc_vga[6],15
; bord gauche:
plans_ecriture_vga 8
mov ds,cs
mov cx,data_bloc_vga[6]
sub cx,data_bloc_vga[2]
sub cx,7
mov es,0A000h
mov ax,data_bloc_vga[2]
add ax,4
mov bx,80
mul bx
add ax,data_bloc_vga[0]
mov di,ax
b1:
mov b es:[di],0F0h
add di,80
loop b1
plans_ecriture_vga 7
mov b es:[di],0Fh
add di,80
mov b es:[di],01Fh
add di,80
mov b es:[di],03Fh
add di,80
mov b es:[di],07Fh
; bord droit:
plans_ecriture_vga 15
mov ds,cs
mov cx,data_bloc_vga[6]
sub cx,data_bloc_vga[2]
sub cx,7
mov es,0A000h
mov ax,data_bloc_vga[2]
add ax,4
mov bx,80
mul bx
add ax,data_bloc_vga[4]
mov di,ax
push di
b1:
mov b es:[di],0Fh
add di,80
loop b1
plans_ecriture_vga 7
pop di
sub di,240
mov b es:[di],01h
add di,80
mov b es:[di],03h
add di,80
mov b es:[di],07h
pop di,es,ds,dx,cx,bx,ax
ret

; BLOC3_VGA x1,y1,x2,y2 (M+P)
; x1,y1,x2,y2: word
;**************************************************************************
bloc3_vga macro
mov w cs:data_bloc_vga[0],#1
mov w cs:data_bloc_vga[2],#2
mov w cs:data_bloc_vga[4],#3
mov w cs:data_bloc_vga[6],#4
call proc_bloc3_vga
#em
proc_bloc3_vga:
push ax,bx,cx,dx,ds,es,di
mov ds,cs
; fond:
rectangle_vga data_bloc_vga[0],data_bloc_vga[2],data_bloc_vga[4],data_bloc_vga[6],7
; bord haut:
mov ax,data_bloc_vga[2]
add ax,3
rectangle_vga data_bloc_vga[0],data_bloc_vga[2],data_bloc_vga[4],ax,8
; bord bas:
mov ax,data_bloc_vga[6]
sub ax,3
rectangle_vga data_bloc_vga[0],ax,data_bloc_vga[4],data_bloc_vga[6],15
; bord gauche:
mov ds,cs
mov cx,data_bloc_vga[6]
sub cx,data_bloc_vga[2]
sub cx,7
mov es,0A000h
mov ax,data_bloc_vga[2]
add ax,4
mov bx,80
mul bx
add ax,data_bloc_vga[0]
mov di,ax
b1:
plans_ecriture_vga 8
mov b es:[di],0F0h
plans_ecriture_vga 7
mov b es:[di],0Fh
add di,80
loop b1
plans_ecriture_vga 7
mov b es:[di],0Fh
add di,80
mov b es:[di],01Fh
add di,80
mov b es:[di],03Fh
add di,80
mov b es:[di],07Fh
; bord droit:
mov ds,cs
mov cx,data_bloc_vga[6]
sub cx,data_bloc_vga[2]
sub cx,7
mov es,0A000h
mov ax,data_bloc_vga[2]
add ax,4
mov bx,80
mul bx
add ax,data_bloc_vga[4]
mov di,ax
push di
plans_ecriture_vga 8
b1:
mov b es:[di],0Fh
add di,80
loop b1
plans_ecriture_vga 7
pop di
sub di,240
mov b es:[di],01h
add di,80
mov b es:[di],03h
add di,80
mov b es:[di],07h
pop di,es,ds,dx,cx,bx,ax
ret

; TEMPO_VGA (M+P)
; temporisation balayage ‚cran
;**************************************************************************
tempo_vga     macro
call proc_tempo_vga
#em
proc_tempo_vga:
push ax,dx
mov dx,3DAh
l1:
in al,dx
and al,8        ; le bit "d‚lai retour faisceau" est isol‚
cmp al,0
jne l1
l1:
in al,dx
and al,8        ; le bit "d‚lai retour faisceau" est isol‚
cmp al,0
je l1
pop dx,ax
ret

; MODIFIE_COULEUR_VGA c,r,v,b (M+P)
;**************************************************************************
modifie_couleur_vga macro
mov cl,#1
mov bh,#2
mov bl,#3
mov ch,#4
call proc_modifie_couleur_vga
#em
proc_modifie_couleur_vga:
mov dx,3C6h
mov al,0FFh
out dx,al
mov al,cl
add dx,2
out dx,al
inc dx
mov al,bh
out dx,al
mov al,bl
out dx,al
mov al,ch
out dx,al
;mov bh,0
;mov ax,1010h
;int 16
ret

; PROC_AFF_WORD_VGA (P)
; affiche le contenu de AX en d‚cimal
;**************************************************************************
proc_aff_word_vga:
; affiche le nombre contenu dans AX (en d‚cimal)
push ax,bx,cx,dx
mov bx,10
mov cx,0
p_affwordvga_decompose:
mov dx,0
div bx
push dx
inc cx
cmp ax,0
jnz p_affwordvga_decompose
p_affwordvga_affichage:
pop ax
add al,'0'
push cx
call proc_aff_carac_vga
pop cx
loop p_affwordvga_affichage
pop dx,cx,bx,ax
ret

; PROC_AFF_DWORD_VGA (P)
; affiche le contenu de AX:DX en d‚cimal
;**************************************************************************
proc_aff_dword_vga:
; proc‚dure affichant le nombre contenu dans ax:dx, en d‚cimal
push ax,bx,cx,dx,si
mov bx,ax
mov w cs:data_proc_affdwordvga,0
or dx,dx
jnz dasc0
cmp bx,1
ja dasc0
dasc0:
std
mov ah,10
mov cx,32
xor si,si
or si,bx
or si,dx
jz dasc3
xor al,al
dasc1:
add bx,bx
adc dx,dx
adc al,al
cmp al,ah
jb dasc2
sub al,ah
add bx,1
dasc2:
loop dasc1
or al,30h
push ax
inc w cs:data_proc_affdwordvga
jmp dasc0
dasc3:  ; affichage du nombre!
mov cx,cs:data_proc_affdwordvga
cmp cx,0
je dasc4
dasc3_l1:
pop ax
push cx
call proc_aff_carac_vga
pop cx
loop dasc3_l1
pop si,dx,cx,bx,ax
ret
dasc4:
mov al,'0'
call proc_aff_carac_vga
pop si,dx,cx,bx,ax
ret
data_proc_affdwordvga      dw ?

; PROC_AFF_HEX_VGA (P)
; affiche le contenu de AL en hexad‚cimal (sans le suffixe "h")
;**************************************************************************
proc_aff_hex_vga:
push ax,bx,cx,dx,si
push ax
mov cl,4
shr al,cl
add al,'0'
cmp al,'9'
if a add al,7
call proc_aff_carac_vga
pop ax
and al,0Fh
add al,'0'
cmp al,'9'
if a add al,7
call proc_aff_carac_vga
pop si,dx,cx,bx,ax
ret

; TEST_ZONE_SOURIS x1,y1,x2,y2,label
; saut … label si on n'a pas x1<=cx<=x2 et y1<=dx<=y2
;**************************************************************************
test_zone_souris macro
cmp cx,#1
jb >m1
cmp cx,#3
ja >m1
cmp dx,#2
jb >m1
cmp dx,#4
ja >m1
jmp >m2
m1:
jmp #5
m2:
#em

; LACHE_SOURIS (M+P)
; attend que l'utilisateur lache les boutons de la souris...
;**************************************************************************
lache_souris macro
call proc_lache_souris
#em
proc_lache_souris:
mouse_state
cmp bx,0
jne proc_lache_souris
ret

; INIT_BOUTON b,x1,y1,x2,y2,xt,yt,'texte' (M)
; initialise dans la table DATA_BOUTON les donn‚es relatives au bouton nø b
; BOUTON_OFF (M+P)
; BOUTON_ON (M+P)
;**************************************************************************
data_bouton     db 128 dup ?
init_bouton macro
jmp >m1
m2 db #8,0
m1:
mov bl,#1
xor bh,bh
mov cl,4
shl bx,cl
add bx,offset data_bouton
mov w cs:[bx],#2
mov w cs:[bx+2],#3
mov w cs:[bx+4],#4
mov w cs:[bx+6],#5
mov w cs:[bx+8],#6
mov w cs:[bx+10],#7
mov w cs:[bx+12],offset m2
mov bl,#1
call proc_bouton_off
#em
bouton_off macro
mov bl,#1
call proc_bouton_off
#em
bouton_on macro
mov bl,#1
call proc_bouton_on
#em
proc_bouton_off:
xor bh,bh
mov cl,4
shl bx,cl
add bx,offset data_bouton
push bx
mov di,offset data_bloc_vga
mov si,bx
mov ds,cs
mov es,cs
mov cx,4
cld
rep movsw
call proc_bloc1_vga
pop bx
push bx
mov ax,cs:[bx+8]
mov cs:x_texte_vga,ax
mov ax,cs:[bx+10]
mov cs:y_texte_vga,ax
police_vga 2
couleur_texte_vga 1
pop bx
mov ds,cs
mov si,[bx+12]
call proc_aff_chaine_vga
ret
proc_bouton_on:
xor bh,bh
mov cl,4
shl bx,cl
add bx,offset data_bouton
push bx
mov di,offset data_bloc_vga
mov si,bx
mov ds,cs
mov es,cs
mov cx,4
cld
rep movsw
call proc_bloc3_vga
pop bx
push bx
mov ax,cs:[bx+8]
mov cs:x_texte_vga,ax
mov ax,cs:[bx+10]
mov cs:y_texte_vga,ax
police_vga 2
couleur_texte_vga 4
pop bx
mov ds,cs
mov si,[bx+12]
call proc_aff_chaine_vga
ret

; TEST_SOURIS_BOUTON b,l (M+P+S)
; saut … l si pas sur le bouton...
; si sur le bouton: bouton enfonc‚ et attend que la souris soit lach‚e
;**************************************************************************
data_souris_bouton_1    db ?
data_souris_bouton_2    dw ?
test_souris_bouton macro
mov b cs:data_souris_bouton_1,#1
mov w cs:data_souris_bouton_2,#2
call proc_test_souris_bouton
#em
proc_test_souris_bouton:
push bx,cx,dx
shr cx,1
shr cx,1
shr cx,1
mov bl,cs:data_souris_bouton_1
xor bh,bh
shl bx,1
shl bx,1
shl bx,1
shl bx,1
add bx,offset data_bouton
cmp cx,cs:[bx]
jb >l1
cmp dx,cs:[bx+2]
jb >l1
cmp cx,cs:[bx+4]
ja >l1
cmp dx,cs:[bx+6]
ja >l1
; on a cliqu‚ sur le bouton!
mov bl,cs:data_souris_bouton_1
call proc_bouton_on
lache_souris
; retour vers l'endroit d'appel
pop dx,cx,bx
ret
l1:
; sortie normale
pop dx,cx,bx
pop ax
mov ax,cs:data_souris_bouton_2
push ax         ; modif. de l'adresse de retour
ret

fin_t_procs:

