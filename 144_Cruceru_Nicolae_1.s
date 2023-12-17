# a nu se baga in seama romgleza variabilelor + etichetelor
.data
    matrix: .zero 1600
    copyMatrix: .zero 1600
    bitArray: .zero 1600
    decryptArray: .space 1600

    lines: .space 4
    columns: .space 4

    # cate linii si coloane neextinse, pt a se folosi mai tarziu la afisare (ff ineficient)
    actualLines: .space 4
    actualColumns: .space 4

    lineIndex: .space 4
    columnIndex: .space 4

    aliveCells: .space 4
    rezervaEcx: .space 4
    # valoareAfisata: .space 4

    iterations: .space 4

    # variabile folosite in timpul iteratiilor
    neighboursAlive: .space 4

    isDecryption: .space 4

    # mesajele au lungimea de maxim 10 char-uri + '\0'
    mesaj: .space 11
    numarMesaj: .space 4

    # variabile folosite la criptare
    currentChar: .space 1
    lengthMesaj: .space 4
    lengthCheie: .space 4
    rezervaEdx: .space 4
    nrLoopEncryption: .space 4
    charDeAfisat: .space 4

    charPrintf: .asciz "%c"
    hexaPrintf: .asciz "0x"
    hexaScanf: .asciz "%X"
    stringScanf: .asciz "%s"
    formatScanf: .asciz "%d"
    newLine: .asciz "\n"
    spaceChar: .asciz " "

.text

.global main

main:

    # citim nr de linii, coloane, celule vii
    pushl $lines
    pushl $formatScanf
    call scanf 
    popl %ebx
    popl %ebx

    pushl $columns
    pushl $formatScanf
    call scanf 
    popl  %ebx 
    popl  %ebx 

    # adaugam 2 nr de linii si coloane din cauza ca lucram cu matricea extinsa
    movl lines, %eax 
    movl %eax, actualLines

    movl columns, %eax 
    movl %eax, actualColumns

    addl $2, lines
    addl $2, columns

    pushl $aliveCells
    pushl $formatScanf
    call scanf 
    popl  %ebx 
    popl  %ebx 

    # folosim %ecx drept counter pt loop 
    mov aliveCells, %ecx

    # loop care citeste toate celulele vii
et_loop_citire:    
    cmp $0, %ecx
    je et_citire_iterations

    # ecx e modificat de apelurile lui scanf
    mov %ecx, rezervaEcx

    # citeste linia si coloana celulei vii
    pushl $lineIndex
    pushl $formatScanf
    call scanf 
    popl  %ebx 
    popl  %ebx 

    pushl $columnIndex
    pushl $formatScanf
    call scanf 
    popl  %ebx 
    popl  %ebx 

    # incrementam var pentru ca lucram cu matricea extinsa in memorie
    # mergem in "spatiul" din dreapta jos  
    incl lineIndex
    incl columnIndex

    # incarcam matricea in edi ca sa lucram cu ea
    lea matrix, %edi 

    # locul celulei vii in memorie este lineIndex * columns + columnIndex - 1 (-1 pt ca e indexat de la 0)
    movl columns, %eax 
    mull lineIndex
    addl columnIndex, %eax 

    # duh
    movl $1, (%edi, %eax, 4)

    # restauram ecx 
    movl rezervaEcx, %ecx
    decl %ecx 

    jmp et_loop_citire

et_citire_iterations:
    # dupa ce citim celulele vii trebuie sa citim nr de iteratii 
    pushl $iterations
    pushl $formatScanf
    call scanf 
    popl %ebx
    popl %ebx

    pushl $isDecryption
    pushl $formatScanf
    call scanf 
    popl %ebx
    popl %ebx 


    # daca mesaj == 0, facem CRIPTARE, else, facem DECRIPTARE
    movl isDecryption, %ebx
    cmpl $0, %ebx
    je et_citire_criptare

    pushl $decryptArray
    pushl $stringScanf
    call scanf 
    popl %ebx 
    popl %ebx

    jmp et_mov_iterations
    
    et_citire_criptare:
    pushl $mesaj
    pushl $stringScanf
    call scanf
    popl %ebx 
    popl %ebx

    et_mov_iterations:
    movl iterations, %ecx

    # in cadrul etichetei, se folosesc urm registri:
    # ecx - counter iteratii (+ rezervaEcx pt restaurare)
    # edi - load matrice 
    # ebx - index linii
    # ebp - index coloane
    # eax - celula curenta 
    # edx - op aritmetice
    # TODO 
et_modificare_matrice:
    cmpl $0, %ecx

    je et_continue_encryption
    # movl %ecx, rezervaEcx

    movl $1, %ebx
    lea matrix, %edi 
    et_modificare_linii: 
        cmpl actualLines, %ebx 
        jg et_modificare_matrice_final        

        movl $1, %ebp
        et_modificare_coloane: 
            # incarcam valoarea adresei lui matrix in edi deoarece mai jos o sa folosim tot edi pentru adresa lui copyMatrix
            lea matrix, %edi 

            # 000   
            # 0x0   Traversam vecinii celulei plecand din punctul din stanga sus, in ordinea acelor de ceasornic 
            # 000
            cmp actualColumns, %ebp
            jg et_modificare_linii_final

            # calculam pozitia din memorie a celulei curente 
            movl columns, %eax
            mull %ebx 
            addl %ebp, %eax 
            # decl %eax 

            # ca sa ajungem in coltul din stanga sus trebuie eax -= (columns) - 1
            subl columns, %eax 
            decl %eax

            # numarul de vecini trebuie sa fie 0
            movl $0, neighboursAlive 

            # comparam coltul din stanga sus cu unu, apoi in dreapta pe linia de sus, apoi in stanga si in dreapta celulei vii, apoi in jos,
            # adaugand mereu 1 la neighboursAlive daca vecinul e egal cu 1 
            cmpl $1, (%edi, %eax, 4)
            jne et_mijloc_sus
            incl neighboursAlive

            et_mijloc_sus:
            incl %eax
            cmpl $1, (%edi, %eax, 4)
            jne et_dreapta_sus
            incl neighboursAlive

            et_dreapta_sus:
            incl %eax
            cmpl $1, (%edi, %eax, 4)
            jne et_stanga
            incl neighboursAlive

            et_stanga:
            addl columns, %eax
            subl $2, %eax 
            cmpl $1, (%edi, %eax, 4)
            jne et_dreapta
            incl neighboursAlive

            et_dreapta:
            addl $2, %eax 
            cmpl $1, (%edi, %eax, 4)
            jne et_stanga_jos
            incl neighboursAlive

            et_stanga_jos:
            addl columns, %eax 
            subl $2, %eax 
            cmpl $1, (%edi, %eax, 4)
            jne et_mijloc_jos
            incl neighboursAlive

            et_mijloc_jos:
            incl %eax 
            cmpl $1, (%edi, %eax, 4)
            jne et_dreapta_jos
            incl neighboursAlive

            et_dreapta_jos:
            incl %eax
            cmpl $1, (%edi, %eax, 4)
            jne et_final_modif
            incl neighboursAlive

            et_final_modif:
            # readucem %eax la valoarea initiala 
            decl %eax 
            subl columns, %eax 

            # incarcam adresa lui copyMatrix in edi
            lea copyMatrix, %edi 

            # exista mai multe posibilitati
            # daca neighboursAlive == 3 => celula = 1 (orice ar fi)
            # daca neighboursAlive == 2 && celula == 1 => celula = 1 
            # altfel celula = 0 
            cmpl $3, neighboursAlive
            je et_cazul_trei

            cmpl $2, neighboursAlive
            je et_cazul_doi 

            # cazul in care celula devine 0 (cand nr de vecini != 2/3)
            movl $0, (%edi, %eax, 4)
            
            incl %ebp 
            jmp et_modificare_coloane

            et_cazul_trei:
            movl $1, (%edi, %eax, 4)

            incl %ebp
            jmp et_modificare_coloane

            et_cazul_doi:
            lea matrix, %edi
            cmpl $1, (%edi, %eax, 4)
            je et_cazul_doi_egal 

            lea copyMatrix, %edi
            movl $0, (%edi, %eax, 4)
            incl %ebp
            jmp et_modificare_coloane

            et_cazul_doi_egal:
            lea copyMatrix, %edi
            movl $1, (%edi, %eax, 4)
            incl %ebp
            jmp et_modificare_coloane

    et_modificare_linii_final:
        incl %ebx
        jmp et_modificare_linii

et_modificare_matrice_final:
    # trebuie ca tot continutul din copyMatrix sa fie COPIAT in matrix 
    # cum am terminat cu liniile si coloanele putem folosi %ebx si %ebp pt copierea asta 
    lea copyMatrix, %edi

    movl $1, %ebx
    copiere_linii:
        cmp actualLines, %ebx 
        jg terminare_copiere 

        mov $1, %ebp
        copiere_coloane:
            cmp actualColumns, %ebp
            jg finish_copiere_coloane

            movl columns, %eax 
            mull %ebx
            addl %ebp, %eax 

            movl (%edi, %eax, 4), %esi

            lea matrix, %edi 

            movl %esi, (%edi, %eax, 4)

            lea copyMatrix, %edi
            
            incl %ebp
            jmp copiere_coloane

        # se termina copiere coloana 
        finish_copiere_coloane: 

        incl %ebx 
        jmp copiere_linii
        


terminare_copiere: 
    # mov rezervaEcx, %ecx 
    decl %ecx 
    jmp et_modificare_matrice

# Continuam CRIPTAREA / DECRIPTAREA 

et_continue_encryption:
    movl isDecryption, %ebx 
    cmpl $0, %ebx 
    je et_encrypt

# Pentru decriptare facem exact inversul a ceea ce am facut pentru criptare. Vom citi valoarea hexadecimala intr-un string (!), 
# astfel fiecare valoare din hexa va fi un char si ne va fi relativ usor de transformat intr-un sir precum bitArray de la decriptare, 
# in care fiecare bit e de fapt reprezentat ca un byte (astfel facandu-se xor-area). 
et_decrypt:
    # Pt fiecare element din decryptArray (in afara de primele 2 "0x"), le vom transforma in bitArray in forma lor potrivita 
    lea decryptArray, %edi 
    # index decryptArray
    movl $2, %ebx
    # index bitArray
    movl $0, %edx
    et_hexa_to_bit_array:
    cmpl $0, (%edi, %ebx, 1)
    je et_hexa_to_bit_array_final

    lea decryptArray, %edi

    # DACA CIFRA DIN NUMAR E A..F scade drc 55 (transformare ASCII -> hexa)
    # Altfel scade 48 
    movb (%edi, %ebx, 1), %cl

    cmpb $57, %cl
    jl et_scade_sa_fie_numar

    subl $55, (%edi, %ebx, 1)
    movb (%edi, %ebx, 1), %al
    jmp et_gata_scaderea

    et_scade_sa_fie_numar:
    subl $48, (%edi, %ebx, 1)
    movb (%edi, %ebx, 1), %al


    et_gata_scaderea:
    # movb (%edi, %ebx, 1), %al
    movl $3, %ecx
    et_decrypt_char_to_bit:
    cmpl $0, %ecx 
    jl et_decrypt_char_to_bit_final 


    movb $1, %al 
    shl %ecx, %al
    and (%edi, %ebx, 1), %al 
    shr %ecx, %al

    lea bitArray, %edi
    movb %al, (%edi, %edx, 1)
    lea decryptArray, %edi
    
    decl %ecx
    incl %edx

    jmp et_decrypt_char_to_bit
    et_decrypt_char_to_bit_final:

    incl %ebx

    jmp et_hexa_to_bit_array

    et_hexa_to_bit_array_final:
    movl %edx, lengthMesaj

    # Impartim lungimea mesajului la lungimea cheii 
    # Calculam lungimea cheii
    movl columns, %eax
    movl lines, %ecx
    movl $0, %edx
    mull %ecx 
    movl %eax, lengthCheie

     # in ebx o sa fie indexul cheii 
    movl $0, %ecx
    movl $0, %ebx
    et_decriptare_mesaj:
    cmpl lengthMesaj, %ecx
    je et_decriptare_mesaj_final

    cmpl lengthCheie, %ebx
    jne et_decriptare_sari_cheie_zero
    movl $0, %ebx
    et_decriptare_sari_cheie_zero:

        # dl pt mesaj
        # al pt cheie 
        lea matrix, %edi 
        movb (%edi, %ebx, 4), %dl
        lea bitArray, %edi
        movb (%edi, %ecx, 1), %al
        xorb %al, %dl 
        movb %dl, (%edi, %ecx, 1)

        incl %ecx
        incl %ebx 
        jmp et_decriptare_mesaj

    et_decriptare_mesaj_final:

    lea bitArray, %edi
    movl $0, %ebx
    et_decriptare_transformare_afisare:
    cmpl lengthMesaj, %ebx 
    je et_decriptare_transformare_afisare_final

    movl $7, %ecx
    movl $0, charDeAfisat
    et_decriptare_bitul_urmator: 
    cmpl $0, %ecx
    jl et_decriptare_bitul_urmator_final

    movl $1, %eax
    and (%edi, %ebx, 1), %eax
    sal %ecx, %eax 
    addl %eax, charDeAfisat

    decl %ecx 
    incl %ebx 

    jmp et_decriptare_bitul_urmator

    et_decriptare_bitul_urmator_final:  

    push charDeAfisat
    call putchar
    popl %ebp

    pushl $0
    call fflush
    popl %ebp

    jmp et_decriptare_transformare_afisare

    et_decriptare_transformare_afisare_final:

    jmp et_exit
# Pentru criptare se va folosi cea mai wildly inefficient solutie posibila, copyMatrix va deveni reprezentarea binara 
# a mesajului, eg pentru mesajul "parola", p se va transforma in primii 8 bytes ai copyMatrix (am mai zis ca e ineficient, nu?)
et_encrypt:

    movl $0, %ecx
    lea mesaj, %edi 

    et_transform_bits:
    cmpb $0, (%edi, %ecx, 1)
    je et_transform_bits_terminat
    
    # folosim dl din %edx pentru a muta bytes
    movl $0, %edx
    movb (%edi, %ecx, 1), %dl
    movb %dl, currentChar

    # loop pentru a transforma un caracter din mesaj in biti si a-i adauga la copyMatrix 
    movl $0, %ebx 
    et_char_to_bit:
        cmpl $8, %ebx 
        je et_char_to_bit_terminat

        # mutam bitul de 1 pe pozitia a 8-a de la dreapta 
        movl $1, %eax 
        shl $7, %eax  


        and %dl, %al

        # mutam bitul de 1/0 inapoi pe prima pozitie 
        shr $7, %eax 
        
        # mutam eax pe pozitia potrivita din copyMatrix:
        # %ecx * 8 + %ebx 
        # folosim esi sa stocam bitul curent pt ca e liber 
        movl %eax, %esi
        movl %ecx, %eax
        movl %edx, rezervaEdx
        movl $8, %edx
        mull %edx
        addl %ebx, %eax
        

        lea bitArray, %edi
        movl %esi, (%edi, %eax, 1)
        movl rezervaEdx, %edx
        lea mesaj, %edi

        shl $1, %edx

        incl %ebx 
        jmp et_char_to_bit

        et_char_to_bit_terminat:
        incl %ecx 
        jmp et_transform_bits
    


    et_transform_bits_terminat:
    movl $8, %eax
    movl $0, %edx
    mull %ecx 
    movl %eax, lengthMesaj

    # Impartim lungimea mesajului la lungimea cheii 
    # Calculam lungimea cheii
    movl columns, %eax
    movl lines, %ecx
    movl $0, %edx
    mull %ecx 
    movl %eax, lengthCheie

    # in ebx o sa fie indexul cheii 
    movl $0, %ecx
    movl $0, %ebx
    et_criptare_mesaj:
    cmpl lengthMesaj, %ecx
    je et_criptare_mesaj_final

    cmpl lengthCheie, %ebx
    jne et_sari_cheie_zero
    movl $0, %ebx
    et_sari_cheie_zero:

        # eax pt mesaj
        # edx pt cheie 
        lea matrix, %edi 
        movb (%edi, %ebx, 4), %dl
        lea bitArray, %edi
        movb (%edi, %ecx, 1), %al
        xorb %al, %dl 
        movb %dl, (%edi, %ecx, 1)

        incl %ecx
        incl %ebx 
        jmp et_criptare_mesaj

    et_criptare_mesaj_final:

    pushl $hexaPrintf
    call printf
    popl %ebp

    pushl $0 
    call fflush
    popl %ebp

    lea bitArray, %edi
    movl $0, %ebx
    et_afisare_hexa:
    cmpl lengthMesaj, %ebx
    je et_afisare_hexa_final

    movl $3, %ecx 
    movb $0, charDeAfisat
    et_bytes_to_afisare:
    cmpl $0, %ecx  
    jl et_bytes_to_afisare_final 

    movb $1, %al
    and (%edi, %ebx, 1), %eax
    shl %ecx, %al 
    addl %eax, charDeAfisat

    decl %ecx 
    incl %ebx

    jmp et_bytes_to_afisare

    et_bytes_to_afisare_final:

    pushl charDeAfisat
    push $hexaScanf
    call printf
    pop %ebp
    pop %ebp 

    pushl $0
    call fflush
    popl %ebp

    jmp et_afisare_hexa

    et_afisare_hexa_final:
   
et_exit: 
    mov $1, %eax 
    mov $0, %ebx 
    int $0x80
