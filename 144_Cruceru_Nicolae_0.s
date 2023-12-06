.data
    matrix: .zero 1600
    lines: .space 4
    columns: .space 4
    lineIndex: .space 4
    columnIndex: .space 4
    aliveCells: .space 4
    formatScanf: .asciz "%d"

.text

.global main

main:

    # citeste nr de linii, coloane, celule vii

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

    pushl $aliveCells
    pushl $formatScanf
    call scanf 
    popl  %ebx 
    popl  %ebx 

    # folosim %ecx drept counter pt loop de loop
    mov aliveCells, %ecx

    # loop care citeste toate celulele vii
et_loop: 
    cmp $0, %ecx
    je et_exit

    


et_exit: 
    mov $0, %eax 
    mov $1, %ebx 
    int $0x80
