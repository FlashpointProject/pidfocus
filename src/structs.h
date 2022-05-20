#ifndef PIDFOCUS_STRUCTS_H
#define PIDFOCUS_STRUCTS_H

#include <stdlib.h>
#include <ApplicationServices/ApplicationServices.h>

struct WindowInfo {
	pid_t ownerPID;
	NSDictionary* winInfo;
};

struct WindowSet {
	size_t len;
	struct WindowInfo* windows;
};

#endif // PIDFOCUS_STRUCTS_H
