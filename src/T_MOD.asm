jmp initialisation_mod  ; saut au programme d'initialisation

; variables:
limite_portamento_up dw 39h
limite_portamento_down dw 6B0h

SEGMENT_BUFFERS_MOD     equ 9BC9h
PORT_SB dw 220h    ; … initialiser
INT_SB  db 5       ; idem
VERSION_DSP_SB db 2 dup ?
TABLE_NOTES_MOD dw 6B0h,650h,5F5h,5A0h,54Dh,501h,4B9h,475h,435h,3F9h,3C1h,38Bh
                dw 358h,328h,2FAh,2D0h,2A6h,280h,25Ch,23Ah,21Ah,1FCh,1E0h,1C5h
                dw 1ACh,194h,17Dh,168h,153h,140h,12Eh,11Dh,10Dh,0FEh,0F0h,0E2h
                dw 0D6h,0CAh,0BEh,0B4h,0AAh,0A0h,097h,08Fh,087h,07Fh,078h,071h
                dw 06Bh,065h,05Fh,05Ah,055h,050h,04Ch,047h,043h,040h,03Ch,039h
time_constant_sb        db ?
titre_mod               db 20 dup ?
longueur_buffers_mod    dw ?
segment_patterns        dw ?
segments_samples        dw 31 dup ?
longueurs_samples       dw 31 dup ?
debuts_boucles_samples  dw 31 dup ?
longueurs_boucles_samples    dw 31 dup ?
volumes_samples         dw 31 dup ?
finetunes_samples       dw 31 dup ?
noms_samples            db 682 dup ?
nb_positions            db ?
nb_patterns             db ?
table_positions         db 128 dup ?
handle_mod              dw ?
ofs_last_int_mod        dw ?
seg_last_int_mod        dw ?
deja_dans_int_mod       db ?
mode_joue_mod           db ?
pattern_joue_mod        db ?

; variable plus sp‚cifiques au playback:
num_position_mod db ?
num_note_mod    db ?
chrono_note_mod db ?
vitesse_mod     db 6
num_buffer_mod  db ?
ofs_buffer_mod  dw ?
mod_status      db ?
donnees_voix_mod db 128 dup ?

; initialisation de la Sound Blaster
initialisation_mod:
; recherche de la chaŒne 'BLASTER=' dans l'environnement
; et positionnement de DS:[SI] juste aprŠs...
mov ax,cs:[2Ch] ; ax = segment de l'environnement
mov ds,ax
mov si,0
test_chaine_blaster:     ; on est au d‚but d'une variable d'environnement
cld
lodsb
cmp al,0        ; fin d'environnement ?
je apres_test_blaster          ; alors fini.
cmp al,'B'
jne chaine_blaster_suivante
lodsb
cmp al,'L'
jne chaine_blaster_suivante
lodsb
cmp al,'A'
jne chaine_blaster_suivante
lodsb
cmp al,'S'
jne chaine_blaster_suivante
lodsb
cmp al,'T'
jne chaine_blaster_suivante
lodsb
cmp al,'E'
jne chaine_blaster_suivante
lodsb
cmp al,'R'
jne chaine_blaster_suivante
lodsb
cmp al,'='
jne chaine_blaster_suivante
; on y est: recherche des "x" dans "IX" et "A2X0"
b1:
cld
lodsb
cmp al,'i'
if ne cmp al,'I'
je blaster_i
cmp al,'a'
if ne cmp al,'A'
je blaster_a
cmp al,0
jne b1
jmp apres_test_blaster  ; le boulot est fini!
blaster_i:
lodsb
sub al,'0'
cmp al,1
if e mov al,10
mov cs:int_sb,al
jmp b1
blaster_a:
lodsb
lodsb
sub al,'0'
mov cl,4
shl al,cl
mov ah,2
mov cs:port_sb,ax
jmp b1
chaine_blaster_suivante:     ; pas la bonne chaine: recherche de la chaine suivante
cld
lodsb
cmp al,0
jne chaine_blaster_suivante
jmp test_chaine_blaster  ; test de cette nouvelle chaine!

; adresse et interruption initialis‚es
apres_test_blaster:
push cs
pop ds

; sauvegarde de l'ancienne adresse d'interruption DSP
mov es,0
mov al,cs:int_sb
add al,8
mov ah,4
mul ah
mov si,ax       ; es:si = adresse du vecteur d'interruption
mov ax,es:[si]
mov cs:ofs_last_int_mod,ax
mov ax,es:[si+2]
mov cs:seg_last_int_mod,ax

; initialisation dsp
mov ds,cs
mov dx,port_sb
add dx,6        ; dx="dsp reset port"
mov al,1
out dx,al
; on lui laisse le temps de respirer...
mov cx,1000
b1:
loop b1
mov al,0
out dx,al
mov cx,500
b1:
call proc_lit_dsp_sb
cmp al,0AAh
je >l1
loop b1
jmp erreur_dsp  ; le DSP ne s'est pas initialis‚ correctement
l1:

; test de l'interruption du DSP
call proc_stop_mod
mov ah,1
mov cl,cs:int_sb
shl ah,cl
not ah
in al,21h
and al,ah
out 21h,al              ; enable DSP interrupt
mov b cs:mod_status,1
mov al,40h
call proc_ecrit_dsp_sb
mov al,131
call proc_ecrit_dsp_sb  ; ‚criture du "time constant": 8000 Hz
mov al,80h
call proc_ecrit_dsp_sb
mov al,0
call proc_ecrit_dsp_sb
mov al,0
call proc_ecrit_dsp_sb  ; silence instantan‚ (1/8000 sec.)
mov cx,0FFFFh
b1:
cmp b cs:mod_status,0
je >l1  ; ok, l'interruption a eu lieu.
loop b1
; l'interruption n'a pas eu lieu...
mov al,20h
out 20h,al      ; EOI puisque ‡a n'a pas ‚t‚ fait par le programme...
jmp erreur_dsp
l1:

; lecture version DSP
mov al,0E1h
call proc_ecrit_dsp_sb
call proc_lit_dsp_sb
mov cs:version_dsp_sb[0],al
call proc_lit_dsp_sb
mov cs:version_dsp_sb[1],al

; turn on speakers:
mov al,0D1h
call proc_ecrit_dsp_sb

; appel du programme principal
call apres_mod

;turn off speakers:
mov al,0D3h
call proc_ecrit_dsp_sb

; restauration de l'ancienne adresse d'interruption DSP
mov es,0
mov al,cs:int_sb
add al,8
mov ah,4
mul ah
mov si,ax       ; es:si = adresse du vecteur d'interruption
cli
mov ax,cs:ofs_last_int_mod
mov es:[si],ax
mov ax,cs:seg_last_int_mod
mov es:[si+2],ax
sti
mov ah,1
mov cl,cs:int_sb
shl ah,cl
in al,21h
or al,ah
out 21h,al              ; disable DSP interrupt
ret

; sortie du programme et message en cas d'erreur DSP
erreur_dsp:
; restauration de l'ancienne adresse d'interruption DSP
mov es,0
mov al,cs:int_sb
add al,8
mov ah,4
mul ah
mov si,ax       ; es:si = adresse du vecteur d'interruption
cli
mov ax,cs:ofs_last_int_mod
mov es:[si],ax
mov ax,cs:seg_last_int_mod
mov es:[si+2],ax
sti
mov ah,1
mov cl,cs:int_sb
shl ah,cl
in al,21h
or al,ah
out 21h,al              ; disable DSP interrupt
; message d'erreur
mov ds,cs
mov dx,offset message_erreur_dsp
mov ah,9
int 21h
ret
message_erreur_dsp db 'Erreur d',27h,'initialisation de la Sound Blaster...',13,10
        db 'V‚rifiez votre variable d',27h,'environnement BLASTER.',13,10
        db '(ex: SET BLASTER=A220 I5 D1 T3 ==> port 220h, interruption 5)',13,10
        db '... ou achetez une Sound Blaster!',13,10,'$'

; LIT_DSP_SB (M+P)
; attend et lit un octet depuis le dsp, et le met dans AL
;*****************************************************************
lit_dsp_sb macro
call proc_lit_dsp_sb
#em
proc_lit_dsp_sb:
push cx,dx
mov dx,cs:port_sb
add dx,0Eh
mov cx,2000
b1:
in al,dx
shl al,1
if nc loop b1
sub dx,4
in al,dx
pop dx,cx
ret

; ECRIT_DSP_SB (M+P)
; envoie AL vers le DSP
;*****************************************************************
ecrit_dsp_sb macro
call proc_ecrit_dsp_sb
#em
proc_ecrit_dsp_sb:
push dx
push ax
mov dx,cs:port_sb
add dx,0Ch
b1:
in al,dx
shl al,1
jc b1
pop ax
out dx,al
pop dx
ret

; ACTUALISE_VOLUME_MOD (M+P)
; actualise la table de traduction qui se situe … 9000:C000
;*****************************************************************
actualise_volume_mod macro
call proc_actualise_volume_mod
#em
proc_actualise_volume_mod:
mov es,9C00h
mov di,0        ; ES:DI point sur le d‚but de la table
mov cx,64       ; 64 niveaux de volumes (vol 63 = vol 64 ...)
mov si,0        ; on commence au volume 0
b1:
push cx
mov cx,256      ; 256 ‚chantillons possibles!
mov bh,0        ; on commence … l'‚chantillon 0
b2:
push cx
mov cl,cs:volume_mod
mov ch,0
mov al,bh       ; al = ‚chantillon sign‚
cbw             ; ax = ‚chantillon sign‚ (mot)
imul cx         ; ah = ‚chantillon sign‚ aprŠs volume maŒtre
imul si         ; DL = ‚chantillon sign‚ aprŠs les 2 convertions de volume
mov al,dl
cld
stosb           ; ‚chantillon stock‚!
pop cx
inc bh          ; ‚chantillon suivant
loop b2
pop cx
add si,2        ; volume suivant
loop b1
ret

; ACTUALISE_ECHANTILLONNAGE_MOD (M+P)
; actualise TIME_CONSTANT_SB et LONGUEUR_BUFFERS_MOD
;*****************************************************************
actualise_echantillonnage_mod macro
call proc_actualise_echantillonnage_mod
#em
proc_actualise_echantillonnage_mod:
mov ax,cs:echantillonnage_mod
mov dx,0
mov bx,50
div bx
mov cs:longueur_buffers_mod,ax
mov dx,0Fh
mov ax,04240h
mov bx,cs:echantillonnage_mod
div bx
mov bx,256
sub bx,ax
mov cs:time_constant_sb,bl
ret

; PROC_NEW_MOD (P)
; efface le module en m‚moire et en cr‚e un nouveau, vierge (1 position)
;*****************************************************************
proc_new_mod:
; arrˆt du module actuellement jou‚...
call proc_stop_mod
; effacement des donn‚es en m‚moire...
mov ax,segment_buffers_mod
sub ax,cs:segment_patterns
mov cx,ax       ; cx=nb de paragraphes … zigouiller...
mov bx,cs:segment_patterns      ; bx=1ø paragraphe
mov ax,0
cld
b1:
push cx
mov es,bx
mov di,0
mov cx,8
rep stosw
pop cx
inc bx  ; paragraphe suivant!
loop b1
; initialisation des variables de contr“le du MOD...
mov es,cs
mov di,offset table_positions
mov cx,64
rep stosw       ; table des positions effac‚e
mov di,offset titre_mod
mov cx,10
rep stosw       ; titre effac‚
mov di,offset noms_samples
mov cx,341
rep stosw       ; noms des samples effac‚s
mov cx,31       ; 31 samples … effacer
mov ax,cs:segment_patterns
add ax,128      ; ax = adresse segment du premier sample
mov bx,0
b1:
mov cs:segments_samples[bx],ax  ; segment initialis‚
mov w cs:longueurs_samples[bx],0
mov w cs:debuts_boucles_samples[bx],0
mov w cs:longueurs_boucles_samples[bx],2
mov w cs:volumes_samples[bx],64
mov w cs:finetunes_samples[bx],0
add bx,2
loop b1
mov b cs:nb_positions,1
mov b cs:nb_patterns,1
; ‡a y est, on a tout r‚initialis‚...
ret

; PROC_CHARGE_MOD (P)
; charge un nouveau module en m‚moire, actualise toutes les variables.
; zone tampon de la m‚moire: RAM vid‚o non utilis‚e en mode VGA A000:FA00 … A000:FFFF
;                                                               (1536 octets)
;*************************************************************************************
proc_charge_mod:
; ‚crasement de l'ancien module
call proc_new_mod

; lecture de l'entete dans la zone tampon
mov ax,4200h
mov cx,0
mov dx,0
mov bx,cs:handle_mod
int 21h         ; on revient au d‚but du fichier
mov ax,cs:segment_patterns
mov ds,ax
mov dx,0
mov cx,1084
mov bx,cs:handle_mod
mov ah,3Fh
int 21h         ; entete lu

; lecture de l'entete comme si c'‚tait un 31 samples (on le fera autrement sinon)
; copie du titre
mov ax,cs:segment_patterns
mov ds,ax
mov es,cs
mov si,0
mov di,offset titre_mod
mov cx,20
cld
rep movsb
mov b es:[di-1],0
; copie des infos des samples (sauf les segments, on les calculera plus tard)
mov di,offset noms_samples
mov bx,0
mov cx,31
b1:
push cx
cld
mov cx,22
rep movsb               ; nom transf‚r‚
mov b es:[di-1],0       ; (en asciiz...)
lodsw
xchg ah,al
shl ax,1
mov cs:longueurs_samples[bx],ax ; taille transf‚r‚e
lodsb
test al,08h
if nz or al,0F0h        ; on r‚percute le signe dans le reste de l'octet
cbw
mov cs:finetunes_samples[bx],ax ; accord fin transf‚r‚
lodsb
mov ah,0
mov cs:volumes_samples[bx],ax   ; volume par d‚faut transf‚r‚
lodsw
xchg ah,al
shl ax,1
mov cs:debuts_boucles_samples[bx],ax    ; d‚but de boucle transf‚r‚
lodsw
xchg ah,al
shl ax,1
add ax,cs:debuts_boucles_samples[bx]
cmp ax,cs:longueurs_samples[bx]
if a mov ax,cs:longueurs_samples[bx]
sub ax,cs:debuts_boucles_samples[bx]
mov cs:longueurs_boucles_samples[bx],ax ; longueur de boucle transf‚r‚e
pop cx
add bx,2
loop b1
; copie de la longueur du morceau
mov al,ds:[950]
mov cs:nb_positions,al
; copie de la table des positions
mov ds,cs:segment_patterns
mov es,cs
mov si,952
mov di,offset table_positions
mov cx,128
cld
rep movsb
; calcul du nombre de patterns
mov bx,0
mov al,0
mov cx,128
b1:
cmp al,cs:table_positions[bx]
if b mov al,cs:table_positions[bx]
inc bx
loop b1
inc al
mov cs:nb_patterns,al
; calcul des segments des samples
mov al,cs:nb_patterns
mov ah,128
mul ah
add ax,cs:segment_patterns
mov dx,ax       ; dx=premier segment de sample!
mov cx,31
mov bx,0
b1:
mov cs:segments_samples[bx],dx
mov ax,cs:longueurs_samples[bx]
push cx
test ax,0Fh
pushf
mov cl,4
shr ax,cl
popf
if nz inc ax
pop cx
add dx,ax
add bx,2
loop b1

; d‚termination du type du module: 15 samples & 4voix, 31 samples & 4,6 ou 8 voix.
mov es,cs:segment_patterns
mov ax,es:[1080]
mov bx,es:[1082]
cmp al,'M'
if e cmp bl,'K'
if e jmp charge_patterns_4
cmp al,'4'
if ne cmp ah,'4'
if ne cmp bl,'4'
if ne cmp bh,'4'
if e jmp charge_patterns_4
cmp al,'6'
if ne cmp ah,'6'
if ne cmp bl,'6'
if ne cmp bh,'6'
if e jmp charge_patterns_6
cmp al,'8'
if ne cmp ah,'8'
if ne cmp bl,'8'
if ne cmp bh,'8'
if e jmp charge_patterns_8

; si le programme arrive ici, il s'agit d'un module 4 voix, 15 samples
; correction de l'entˆte:
; correction des infos samples ( sauf segments )
mov bx,30
mov cx,16
b1:
mov w cs:longueurs_samples[bx],0
mov w cs:debuts_boucles_samples[bx],0
mov w cs:longueurs_boucles_samples[bx],2
mov w cs:volumes_samples[bx],64
mov w cs:finetunes_samples[bx],0
add bx,2
loop b1
; correction des noms samples
mov es,cs
mov di,offset noms_samples
add di,330
cld
mov al,0
mov cx,352
rep stosb
; correction de la table des positions
mov ax,cs:segment_patterns
mov ds,ax
mov es,cs
mov si,472
mov di,offset table_positions
mov cx,128
cld
rep movsb
; correction du nombre de positions
mov al,ds:[1D6h]
mov cs:nb_positions,al
; calcul du nombre de patterns
mov bx,0
mov al,0
mov cx,128
b1:
cmp al,cs:table_positions[bx]
if b mov al,cs:table_positions[bx]
inc bx
loop b1
inc al
mov cs:nb_patterns,al
; calcul des segments des samples
mov al,cs:nb_patterns
mov ah,128
mul ah
add ax,cs:segment_patterns
mov dx,ax       ; dx=segment dont on cause
mov cx,31
mov bx,0
b1:
mov cs:segments_samples[bx],dx
mov ax,cs:longueurs_samples[bx]
push cx
test ax,0Fh
pushf
mov cl,4
shr ax,cl
popf
if nz inc ax
pop cx
add dx,ax
add bx,2
loop b1
; d‚placement du pointeur de lecture/‚criture
mov ax,4200h
mov bx,cs:handle_mod
mov cx,0
mov dx,258h
int 21h
; chargement de la suite comme un 4 voix normal...
jmp charge_patterns_4

; chargement d'un module … 4 voix
charge_patterns_4:
mov al,cs:nb_patterns
mov ah,0
mov cl,6
shl ax,cl
mov cx,ax       ; CX = nombre de lignes … charger
mov ax,cs:segment_patterns
mov ds,ax
b1:
push cx,ds
mov es,ds
mov di,16
mov cx,8
mov ax,0
cld
rep stosw       ; ligne effac‚e
mov cx,16
mov dx,0
mov bx,cs:handle_mod
mov ah,3Fh
int 21h         ; lecture de la ligne
pop ds,cx
mov ax,ds
add ax,2        ; lignes suivantes
mov ds,ax
loop b1
jmp charge_samples

; chargement d'un module … 6 voix
charge_patterns_6:
mov al,cs:nb_patterns
mov ah,0
mov cl,6
shl ax,cl
mov cx,ax       ; CX = nombre de lignes … charger
mov ax,cs:segment_patterns
mov ds,ax
b1:
push cx,ds
mov es,ds
mov di,24
mov cx,4
mov ax,0
cld
rep stosw       ; ligne effac‚e
mov cx,24       ; 1 ligne = 24 octets
mov dx,0
mov bx,cs:handle_mod
mov ah,3Fh
int 21h         ; lecture de la ligne
pop ds,cx
mov ax,ds
add ax,2
mov ds,ax       ; segment de ligne suivante
loop b1
jmp charge_samples

; chargement d'un module … 8 voix
charge_patterns_8:
mov al,cs:nb_patterns
mov ah,0
mov cl,6
shl ax,cl
mov cx,ax       ; cx = nb de lignes … charger
mov ds,cs:segment_patterns
b1:
push cx,ds
mov dx,0
mov cx,32
mov bx,cs:handle_mod
mov ah,3Fh
int 21h         ; lecture de la ligne
pop ds,cx
mov ax,ds
add ax,2
mov ds,ax       ; segment de ligne suivante
loop b1
jmp charge_samples

; chargement des samples
charge_samples:
mov cx,31
mov bx,0
b1:
push bx,cx
mov ax,cs:segments_samples[bx]
mov ds,ax
mov dx,0
mov cx,cs:longueurs_samples[bx]
cmp cx,0
je >l1
mov ah,3Fh
mov bx,cs:handle_mod
int 21h         ; lecture du sample
l1:
pop cx,bx
add bx,2
loop b1

; fermeture du fichier
mov bx,cs:handle_mod
mov ah,3Eh
int 21h
; retour au programme appelant
ret

; STOP_MOD (M+P)
; arrˆte le module en m‚moire (mˆme s'il est arr‚t‚, c'est pareil...)
;*************************************************************************************
stop_mod macro
call proc_stop_mod
#em
proc_stop_mod:
; installation de l'interruption d'arrˆt DSP
mov es,0
mov al,cs:int_sb
add al,8
mov ah,4
mul ah
mov si,ax       ; es:si = adresse du vecteur d'interruption
cli
mov ax,offset int_fin_mod
mov es:[si],ax
mov ax,cs
mov es:[si+2],ax
sti
; attend que le mod soit termin‚:
b1:
cmp b cs:mod_status,0
jne b1
ret

; INT_FIN_MOD (INT)
; arrˆte le module en m‚moire (‚vite de nouveaux transferts DMA)
;*************************************************************************************
int_fin_mod:
push ax,bx,cx,dx
sti
mov dx,cs:port_sb
add dx,0Eh
in al,dx        ; "aknowledge interrupt"
mov b cs:mod_status,0   ; dire que c'est termin‚!
mov al,20h
out 20h,al       ; EOI
pop dx,cx,bx,ax
iret

; JOUE_MOD (M+P)
; joue le en m‚moire (sauf s'il est d‚j… en route...)
;*************************************************************************************
joue_mod macro
call proc_joue_mod
#em
proc_joue_mod:
; retour si d‚j… en route
cmp b cs:mod_status,1
if e ret
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
mov b cs:mode_joue_mod,0
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

; INTERRUPTION_MOD (INT)
; joue le module en m‚moire (lance le nouveau transfert DMA puis calcule le suivant)
;*************************************************************************************
interruption_mod:
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

; actualisation MOD_STATUS (1: on est en train de jouer un module)
mov b cs:mod_status,1
cmp b cs:mode_joue_mod,1
if e mov b cs:mod_status,3      ; mode sp‚cial: un seul pattern

; sortie si en cours
cmp b cs:deja_dans_int_mod,0
if ne jmp fin_int_mod

; flag 'en cours' activ‚
mov b cs:deja_dans_int_mod,1

; chrono_note_mod=0?
cmp b cs:chrono_note_mod,0
if ne jmp op_50_sec

; num_note=0?
cmp b cs:num_note_mod,0
jne >l1
cmp cs:mode_joue_mod,1 ; au cas o— on est en mode sp‚cial
if e cmp b cs:num_position_mod,1
je >l2
mov al,cs:num_position_mod
cmp al,cs:nb_positions
jne >l1
l2:
; int dsp=int_fin_mod
; installation de l'interruption d'arrˆt DSP
mov es,0
mov al,cs:int_sb
add al,8
mov ah,4
mul ah
mov si,ax       ; es:si = adresse du vecteur d'interruption
cli
mov ax,offset int_fin_mod
mov es:[si],ax
mov ax,cs
mov es:[si+2],ax
sti
jmp fin_int_mod
l1:

; lecture de la note
jmp lecture_note
apres_lecture_note:

; note suivante
mov al,cs:num_note_mod
inc al
cmp al,64
jb >l1
mov al,0
inc b cs:num_position_mod
l1:
mov cs:num_note_mod,al

; calcul du buffer
calcul_buffer:
; vidage du buffer
mov di,cs:ofs_buffer_mod
mov cx,cs:longueur_buffers_mod
shr cx,1
mov ax,8080h
cld
mov es,9000h
rep stosw

; boucle sur les 8 voix
mov cx,8
mov bx,offset donnees_voix_mod

boucle1_calcule_buffer:
push cx
; on saute si voix inactive
cmp b cs:[bx],0
if e jmp fin_voix_calcul_buffer


push bx
; pr‚paration de la boucle d'‚criture
mov al,cs:[bx+1]
mov ah,0
shl ax,1
mov si,ax
mov es,cs:segments_samples[si]      ; es = segment du sample
mov bp,cs:longueurs_samples[si]
cmp b cs:[bx+7],1       ; en boucle?
jne >l0
mov bp,cs:debuts_boucles_samples[si]
add bp,cs:longueurs_boucles_samples[si]    ; BP = offset o— boucler
l0:
mov ax,9000h
mov ds,ax                       ; DS pointe sur le segment 9000h: buffers, table de traduction volume
mov si,cs:[bx+4]        ; si = offset sample
; calcul de l'incr‚ment: i=((00369E9Ah/p‚riode)*256)/echantillonnage
mov ax,9E9Ah
mov dx,36h
mov cx,cs:[bx+2]        ; cx=p‚riode
cmp cx,37h
if b mov cx,37h ; pas catholique mais ‚vite les overflows....
div cx
mov cx,256
mul cx
mov cx,cs:echantillonnage_mod
div cx
mov dl,al               ; dl=incr‚ment(d‚cimal)
mov al,ah
mov ah,0                ; ax=incr‚ment(entier)
mov dh,cs:[bx+6]        ; dh=offset sample(d‚cimal)
mov ch,cs:[bx+8]
cmp ch,63
if a mov ch,63
mov cl,0
mov bx,cx
add bx,0C000h   ; DS:BX pointe sur la table de volume appropri‚e
mov di,cs:ofs_buffer_mod        ; ds+di = adresse du buffer o— ‚crire
mov cx,cs:longueur_buffers_mod  ; cx = nb d'‚chantillons … ‚crire
b1:
cmp si,bp       ; boucle atteinte?
ja >l2          ; l2: boucle atteinte
l3:
mov ah,al       ; incr‚ment entier sauv‚ dans AH
mov al,es:[si]  ; ‚chantillon 'brut'
xlat            ; ‚chantillon traduit
add [di],al     ; ajout‚ … la voix en sortie
mov al,ah
xor ah,ah       ; AX=incr‚ment entier restaur‚
inc di          ; ‚chantillon en sortie suivant!
add dh,dl
adc si,ax       ; offset sample incr‚ment‚
loop b1
jmp >l4         ; L4=aprŠs calcul normal du buffer sur 1 voix
; traitement du cas o— on boucle
sauve_bx_mod    dw ?
sauve_si_mod    dw ?
sauve_ax_mod    dw ?
l2:
mov cs:sauve_bx_mod,bx  ; on pr‚serve BX
mov cs:sauve_ax_mod,ax  ; on pr‚serve AX
pop bx          ; bx = donnees_voix[???]
push bx
mov b cs:[bx+7],1       ; voix en boucle
mov al,cs:[bx+1]
mov ah,0
shl ax,1
mov si,ax       ; si=pointeur dans les tables d'instruments
cmp w cs:longueurs_boucles_samples[si],2
if na mov b cs:[bx],0   ; pas de boucle: voix d‚sactiv‚e
jna >l4                 ; pas de boucle: fin des calculs
mov bp,cs:debuts_boucles_samples[si]
push bp
add bp,cs:longueurs_boucles_samples[si]
                        ; bp = fin de la boucle
pop si                  ; si=d‚but de la boucle
mov bx,cs:sauve_bx_mod  ; on r‚cupŠre BX
mov ax,cs:sauve_ax_mod  ; on r‚cupŠre AX
jmp l3  ; on retourne au boulot!
l4:
pop bx
mov cs:[bx+4],si        ; offset sample actualis‚
mov cs:[bx+6],dh        ; idem mais partie d‚cimale

fin_voix_calcul_buffer:
pop cx
add bx,16       ; voix suivante
dec cx
jcxz >l1
jmp boucle1_calcule_buffer
l1:


; incr‚mentation de COMPTEUR_TEMPO
mov al,cs:chrono_note_mod
inc al
cmp al,cs:vitesse_mod
if e mov al,0
mov cs:chrono_note_mod,al

; flag 'en cours' d‚sactiv‚
mov b cs:deja_dans_int_mod,0

; fin de l'interruption:
fin_int_mod:
pop bp,es,ds,di,si,dx,cx,bx,ax
iret






; op‚rations … faire tous les 50ø de secondes
op_50_sec:
mov di,offset donnees_voix_mod  ; cs:di = donn‚es de voix
mov cx,8        ; 8 voix, Šh!
boucle_50_sec:
push cx

; arpeggio?
cmp b cs:[di+9],0
jne >l1
cmp b cs:[di+0Eh],3
jae >l1
inc b cs:[di+0Eh]
mov bx,cs:[di+2]
mov ax,cs:[di+0Ah]
mov cs:[di+2],ax
mov ax,cs:[di+0Ch]
mov cs:[di+0Ah],ax
mov cs:[di+0Ch],bx
l1:

; portamento up?
cmp b cs:[di+9],1
jne >l1
mov al,cs:[di+0Ah]
mov ah,0
sub cs:[di+2],ax
mov ax,cs:limite_portamento_up
cmp w cs:[di+2],ax
if l mov w cs:[di+2],ax
l1:

; portamento down?
cmp b cs:[di+9],2
jne >l1
mov al,cs:[di+0Ah]
mov ah,0
add cs:[di+2],ax
mov ax,cs:limite_portamento_down
cmp w cs:[di+2],ax
if g mov w cs:[di+2],ax
l1:

; portamento to note?
cmp b cs:[di+9],3
jne >l1
mov al,cs:[di+0Ah]
mov ah,0
cmp b cs:[di+0Bh],1
je >l2          ; sens positif
cmp b cs:[di+0Bh],2
je >l1          ; op‚ration d‚j… termin‚e
sub cs:[di+2],ax
mov ax,cs:[di+2]
cmp ax,cs:[di+0Ch]
ja >l1
mov ax,cs:[di+0Ch]
mov cs:[di+2],ax        ; note atteinte
mov b cs:[di+0Bh],2
l2:
add cs:[di+2],ax
mov ax,cs:[di+2]
cmp ax,cs:[di+0Ch]
jb >l1
mov ax,cs:[di+0Ch]
mov cs:[di+2],ax        ; note atteinte
mov b cs:[di+0Bh],2
l1:

; volume sliding?
cmp b cs:[di+9],0Ah
jne >l1
mov ah,cs:[di+0Ah]
mov al,cs:[di+8]
add al,ah
cmp al,0
if l mov al,0
cmp al,64
if a mov al,64
mov cs:[di+8],al
l1:

pop cx
add di,16
dec cx
jcxz >l1
jmp boucle_50_sec
l1:

jmp calcul_buffer






; lecture de la note:
lecture_note:
; calcul dans ES du segment de la note … lire (sur 8 voix)
mov bl,cs:num_position_mod
mov bh,0
mov ah,0
mov al,cs:table_positions[bx]           ; AX = num‚ro de pattern (si mode 0)
cmp b cs:mode_joue_mod,1
if e mov al,cs:pattern_joue_mod         ; AX = num‚ro de pattern (si mode 1)
mov cl,7
shl ax,cl
add ax,cs:segment_patterns              ; AX = segment du pattern
mov bl,cs:num_note_mod
mov bh,0
shl bx,1
add ax,bx                               ; AX = segment de la note
mov es,ax

mov si,0        ; es:si = note
mov di,offset donnees_voix_mod  ; cs:di = donn‚es de voix

mov cx,8        ; 8 voix, Šh!
boucle_lit_note:
push cx

mov al,es:[si]
mov ah,es:[si+2]
mov cl,4
shr ah,cl
and al,0F0h
or al,ah
cmp al,0
je >l9
dec al
mov cs:[di+1],al        ; instrument transmis
l9:

; lecture de la commande dans CL
mov cl,es:[si+2]
and cl,0Fh

; CL = commande
; traitement des diff‚rentes commandes:

; arpeggio
cmp cl,0
if ne jmp apres_arpeggio
mov cs:[di+9],cl
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l1
; nouvelle note:
mov bl,cs:[di+1]
mov bh,0
shl bx,1
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
l1:
cmp b cs:[di],0 ; voix inactive ?
if ne cmp b es:[si+3],0 ; pas de paramŠtre ?
jne >l1
; pas d'interpr‚tation d'arpeggio
mov b cs:[di+0Eh],3
jmp fin_boucle_lit_note
l1:
; interpr‚tation de l'arpeggio
mov bx,0
mov ax,cs:[di+2]
b1:
cmp cs:table_notes_mod[bx],ax
jbe >l2
add bx,2
jmp b1
l2:
shr bx,1
; bl = num‚ro de la 1ø note
push bx
mov al,es:[si+3]
mov cl,4
shr al,cl
add bl,al
cmp bl,59
if ae mov bl,59
shl bx,1
mov ax,cs:table_notes_mod[bx]
call proc_traduit_finetune
mov cs:[di+0Ah],ax
pop bx
; bl = num‚ro de la 2ø note
mov al,es:[si+3]
and al,0Fh
add bl,al
cmp bl,59
if ae mov bl,59
shl bx,1
mov ax,cs:table_notes_mod[bx]
call proc_traduit_finetune
mov cs:[di+0Ch],ax
mov b cs:[di+0Eh],0
jmp fin_boucle_lit_note
apres_arpeggio:

; portamento up
cmp cl,1
jne >l1
mov cs:[di+9],cl
mov al,es:[si+3]
mov cs:[di+0Ah],al
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
jmp fin_boucle_lit_note
l1:

; portamento down
cmp cl,2
jne >l1
mov cs:[di+9],cl
mov al,es:[si+3]
mov cs:[di+0Ah],al
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
jmp fin_boucle_lit_note
l1:

; portamento to note
cmp cl,3
jne >l1
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
jne >l3
cmp b cs:[di+9],3
jne >l2
l3:
mov al,es:[si+3]
cmp al,0
jne >l3
cmp b cs:[di+9],3
jne >l2
l3:
mov cs:[di+0Ah],al      ; vitesse transmise
mov cs:[di+9],cl
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+0Ch],ax ; note destination transmise
mov b cs:[di+0Bh],0
cmp ax,cs:[di+2]
if a mov b cs:[di+0Bh],1        ; sens transmis (0=-, 1=+)
l2:
jmp fin_boucle_lit_note
l1:

; fixe l'offset de l'‚chantillon
cmp cl,9
jne >l1
mov cs:[di+9],cl
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov al,es:[si+3]
mov b cs:[di+5],al
mov b cs:[di+4],0       ; on commence l… o— il faut
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
jmp fin_boucle_lit_note
l1:

; volume sliding
cmp cl,0Ah
jne >l1
mov cs:[di+9],cl
mov al,es:[si+3]
cmp al,10h
jb >l3
and al,0F0h
mov cl,4
shr al,cl
jmp >l4
l3:
and al,0Fh
mov ah,0
sub ah,al
mov al,ah
l4:
mov cs:[di+0Ah],al
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
mov al,es:[si]
mov ah,es:[si+2]
and ax,0F0F0h
cmp ax,0                ; y a-t-il par hasard un sample d‚sign‚ ici?
je >l2
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
jmp fin_boucle_lit_note
l1:

; position jump
cmp cl,0Bh
jne >l1
mov cs:[di+9],cl
mov al,es:[si+3]
dec al
cmp b cs:mode_joue_mod,0
if e mov cs:num_position_mod,al ; sauts autoris‚s seulement en mode normal!
mov b cs:num_note_mod,63   ; ordre transmis
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
jmp fin_boucle_lit_note
l1:

; set volume
cmp cl,0Ch
jne >l1
mov cs:[di+9],cl
mov al,es:[si+3]
mov cs:[di+8],al        ; volume transmis
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
l2:
jmp fin_boucle_lit_note
l1:

; pattern break
cmp cl,0Dh
jne >l1
mov cs:[di+9],cl
mov b cs:num_note_mod,63   ; ordre transmis
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
jmp fin_boucle_lit_note
l1:

; set speed
cmp cl,0Fh
jne >l1
mov cs:[di+9],cl
mov al,es:[si+3]
cmp al,1Fh
ja >l1          ; ignor‚ si pas valable
mov cs:vitesse_mod,al   ; vitesse transmise
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:
jmp fin_boucle_lit_note
l1:

; aucune commande reconnue: lancement de la note...
mov cs:[di+9],cl
mov ah,es:[si]
mov al,es:[si+1]
and ax,0FFFh
cmp ax,0
je >l2
call proc_traduit_finetune
mov cs:[di+2],ax        ; note transmise
mov w cs:[di+4],0       ; on commence au d‚but du sample
mov b cs:[di+7],0       ; premier passage (pas en boucle)
mov b cs:[di],1         ; voix activ‚e
mov bl,cs:[di+1]
mov bh,0
shl bx,1
mov ax,cs:volumes_samples[bx]
mov cs:[di+8],al        ; volume par d‚faut transmis
l2:

; voix suivante:
fin_boucle_lit_note:
pop cx
add si,4
add di,16
dec cx
jcxz >l1
jmp boucle_lit_note
l1:

jmp apres_lecture_note

; PROC_TRADUIT_FINETUNE (P)
; entr‚e:       AX = p‚riode amiga actuelle
;               BX = pointeur dans les tables XXXXX_SAMPLES (=spl*2)
; sortie:       AX = p‚riode amiga corrig‚e
;               autres registres sauvegard‚s
;**************************************************************************
proc_traduit_finetune:
push bx,cx,dx,di
mov bl,cs:[di+1]
xor bh,bh
shl bx,1
cmp w cs:finetunes_samples[bx],0
je >l2
mov cx,cs:finetunes_samples[bx]
mov dx,139
mov di,138
cmp cx,0
jg >l1
; correction: finetune n‚gatif
xor cx,cx
sub cx,cs:finetunes_samples[bx]
xchg dx,di
l1:
mov bx,dx
b1:
mul di
div bx
loop b1

l2:
pop di,dx,cx,bx
ret


apres_mod:

