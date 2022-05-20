#ifndef DEBUG
#define DEBUG 0
#endif

#ifndef PIDFOCUS_STRUCTS_H
#define PIDFOCUS_STRUCTS_H

#include <stdlib.h>
#include <ApplicationServices/ApplicationServices.h>

// TODO turn this into a typedef for pid_t on non-debug?
struct WindowInfo {
	pid_t ownerPID;
#if DEBUG
	NSDictionary* winInfo;
#endif
};

struct WindowSet {
	size_t len;
	struct WindowInfo* windows;
};

#endif // PIDFOCUS_STRUCTS_H
