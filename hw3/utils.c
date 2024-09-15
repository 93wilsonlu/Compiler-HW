#include "utils.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int n_var = 0, cur_scope = 0;

void set_scope_and_offset_of_param(char* s) {
    int index = look_up_symbol(s);

    table[index].type = T_FUNCTION;
    table[index].n_args = n_var - index - 1;

    table[index].scope = cur_scope + 1;
    table[index].parent_func = index;

    for (int j = table[index].n_args - 1, i = n_var - 1; i > index; i--, j--) {
        table[i].scope = cur_scope + 1;
        table[i].parent_func = index;
        table[i].offset = j * 4;
    }
    table[index].n_locals = 0;
}

void function_start(char* func) {
    fprintf(f_asm, ".global %s\n", func);
    fprintf(f_asm, "%s:\n", func);
    // push bp
    // mov bp, sp
    fprintf(f_asm, "addi sp, sp, -52\n");
    fprintf(f_asm, "sw ra, 48(sp)\n");
    fprintf(f_asm, "sw s0, 44(sp)\n");
    fprintf(f_asm, "sw s1, 40(sp)\n");
    fprintf(f_asm, "sw s2, 36(sp)\n");
    fprintf(f_asm, "sw s3, 32(sp)\n");
    fprintf(f_asm, "sw s4, 28(sp)\n");
    fprintf(f_asm, "sw s5, 24(sp)\n");
    fprintf(f_asm, "sw s6, 20(sp)\n");
    fprintf(f_asm, "sw s7, 16(sp)\n");
    fprintf(f_asm, "sw s8, 12(sp)\n");
    fprintf(f_asm, "sw s9,  8(sp)\n");
    fprintf(f_asm, "sw s10, 4(sp)\n");
    fprintf(f_asm, "sw s11, 0(sp)\n");
    fprintf(f_asm, "mv s0, sp\n");

    fprintf(f_asm, "addi sp, sp, -%d\n", MAX_LOCAL_SIZE);
    int n_args = table[look_up_symbol(func)].n_args;
    for (int i = 0; i < n_args; i++) {
        fprintf(f_asm, "sw a%d, -%d(fp)\n", i, i * 4);
    }
    fprintf(f_asm, "\n");
}

void function_end() {
    // mov sp, bp
    // pop bp
    // ret
    fprintf(f_asm, "mv sp, s0\n");
    fprintf(f_asm, "lw ra, 48(sp)\n");
    fprintf(f_asm, "lw s0, 44(sp)\n");
    fprintf(f_asm, "lw s1, 40(sp)\n");
    fprintf(f_asm, "lw s2, 36(sp)\n");
    fprintf(f_asm, "lw s3, 32(sp)\n");
    fprintf(f_asm, "lw s4, 28(sp)\n");
    fprintf(f_asm, "lw s5, 24(sp)\n");
    fprintf(f_asm, "lw s6, 20(sp)\n");
    fprintf(f_asm, "lw s7, 16(sp)\n");
    fprintf(f_asm, "lw s8, 12(sp)\n");
    fprintf(f_asm, "lw s9,  8(sp)\n");
    fprintf(f_asm, "lw s10, 4(sp)\n");
    fprintf(f_asm, "lw s11, 0(sp)\n");
    fprintf(f_asm, "addi sp, sp, 52\n");
    fprintf(f_asm, "ret\n\n");
}

void install_symbol(char* s) {
    table[n_var].scope = cur_scope;
    table[n_var].name = strdup(s);
    table[n_var].parent_func = table[n_var - 1].parent_func;
    n_var++;
}

int look_up_symbol(char* s) {
    for (int i = n_var - 1; i >= 0; i--) {
        if (!strcmp(s, table[i].name)) {
            return i;
        }
    }
    return -1;
}

void pop_up_symbol_of_func() {
    int func = table[n_var - 1].parent_func;
    while (n_var && table[n_var - 1].parent_func == func) {
        pop_up_symbol();
    }
}

void pop_up_symbol() {
    int func;
    while (n_var && table[n_var - 1].scope == cur_scope) {
        func = table[n_var - 1].parent_func;
        table[func].n_locals -= table[n_var - 1].size;
        n_var--;
    }
    cur_scope--;
}

int find_offset(char* s) {
    int index = look_up_symbol(s);
    if (index == -1) {
        printf("No offset found for %s\n", s);
        exit(1);
    }
    return table[index].offset;
}

void var_declare(char* s, int size, int type) {
    install_symbol(s);
    int func = table[n_var - 1].parent_func;
    table[n_var - 1].size = size;
    table[func].n_locals += size;
    table[n_var - 1].offset =
        (table[func].n_args + table[func].n_locals - 1) * 4;
    table[n_var - 1].type = type;

    // printf("%d %s %d\n", func, s, table[n_var - 1].offset);
}

void push(char* reg) {
    fprintf(f_asm, "addi sp, sp, -4\n");
    fprintf(f_asm, "sw %s, 0(sp)\n", reg);
}

void pop(char* reg) {
    fprintf(f_asm, "lw %s, 0(sp)\n", reg);
    fprintf(f_asm, "addi sp, sp, 4\n");
}

void next_scope() {
    cur_scope++;
}