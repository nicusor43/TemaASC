# a nu se baga in seama romgleza variabilelor + etichetelor
.data
    matrix: .zero 1600
    copyMatrix: .zero 1600

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

    # in cadrul etichetei, se folosesc urm registri:
    # ecx - counter iteratii (+ rezervaEcx pt restaurare)
    # edi - load matrice 
    # ebx - index linii
    # ebp - index coloane
    # eax - celula curenta 
    # edx - op aritmetice
    # TODO 
    movl iterations, %ecx
et_modificare_matrice:
    cmp $0, %ecx
    je afisare_matrice
    # movl %ecx, rezervaEcx

    movl $1, %ebx
    lea matrix, %edi 
    et_modificare_linii: 
        cmp actualLines, %ebx 
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

afisare_matrice:
    mov $1, %ecx
    lea matrix, %edi

    afisare_linii:
        cmp actualLines, %ecx 
        jg et_exit 

        mov %ecx, rezervaEcx
        
        mov $1, %ebx
        afisare_coloane:
            cmp actualColumns, %ebx
            jg finish_coloane

            movl columns, %eax 
            mull rezervaEcx
            addl %ebx, %eax 

            movl (%edi, %eax, 4), %ebp

            pushl %ebp
            pushl $formatScanf
            call printf
            popl %ebp
            popl %ebp

            pushl $0 
            call fflush
            popl %ebp

            pushl $spaceChar
            call printf
            popl %ebp

            pushl $0    
            call fflush
            popl %ebp

            incl %ebx
            jmp afisare_coloane

        # se termina afisare coloana 
        finish_coloane: 
        
        pushl $newLine
        call printf
        popl %ebp

        pushl $0 
        call fflush
        popl %ebp

        movl rezervaEcx, %ecx 
        incl %ecx 
        jmp afisare_linii
            
et_exit: 
    mov $1, %eax 
    mov $0, %ebx 
    int $0x80
