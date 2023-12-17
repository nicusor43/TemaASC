#include <stdio.h>

int linii; 

int main(){
    int numar;
    FILE* fin = fopen("in.txt", "r");
    FILE* fout = fopen("out.txt", "w");

    fscanf(fin, "%d", &linii);
    fprintf(fout, "%d", linii);
    
    fclose(fin);
}