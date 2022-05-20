#ifndef PIDFOCUS_UTIL_H
#define PIDFOCUS_UTIL_H 1

#include <stdio.h>

#include "structs.h"

bool parse_nneg_int(const char* s, int32_t *int_result);
struct WindowSet* get_window_array();

#endif // PIDFOCUS_UTIL_H
