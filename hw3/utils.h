#ifndef UTILS_H
#define UTILS_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_TABLE_SIZE 40
#define MAX_LOCAL_SIZE (40 * 4)

FILE* f_asm;

enum { T_FUNCTION = 0, T_INT = 1, T_POINTER = 2, T_ARRAY = 3 };

struct symbol_entry {
    char* name;
    int scope;
    int offset;
    int n_args;
    int n_locals;
    int type;
    int parent_func;
    int size;
} table[MAX_TABLE_SIZE];

void set_scope_and_offset_of_param(char* s);

void function_start(char* func);
void function_end();

void install_symbol(char* s);
int look_up_symbol(char* s);
void pop_up_symbol();

void push(char* reg);
void pop(char* reg);

void next_scope();
void var_declare(char* s, int size, int type);

#endif