#include "util.h"
#include "structs.h"

// Modified from https://stackoverflow.com/a/60873655, because I didn't feel like figuring out input validation myself.
// Only handles non-negative ints.
bool parse_nneg_int(const char* s, int32_t *int_result) {
	char* endptr;
	errno = 0;
	long n = strtol(s, &endptr, 10);
	if (errno == ERANGE) {
		fprintf(stderr, "Argument outside range!\n");
		return false;
	}
#if LONG_MAX > INT_MAX
	if (n > INT_MAX) {
		fprintf(stderr, "Argument outside int range!\n");
		return false;
	}
#endif
	if (n < 0) {
		fprintf(stderr, "Argument must be nonnegative!\n");
		return false;
	}
	if (s == endptr) {
		fprintf(stderr, "Argument could not be converted to a base-10 number!\n");
		return false;
	}
	// deref endptr and check that it's a null byte.
	if (*endptr != '\0') {
		fprintf(stderr, "Argument has unusable junk at the end!\n");
		return false;
	}
	// Yay, we made it to the end. Victory!
	*int_result = (int32_t) n;
	return true;
}

struct WindowSet* get_window_array() {
	struct WindowSet* result = malloc(sizeof(struct WindowSet));
	size_t i = 0;
	CFArrayRef windows;
	NSDictionary* window;

	windows = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
	result->len = CFArrayGetCount(windows);
	result->windows = malloc(result->len * sizeof(struct WindowInfo));

	for (window in (NSArray*)windows) {
		if (!CFNumberGetValue(CFDictionaryGetValue((CFDictionaryRef)window, kCGWindowOwnerPID), kCFNumberIntType, &(result->windows[i].ownerPID))) {
			fprintf(stderr, "CFNumber -> pid_t conversion failed!\n");
			exit(2);
		}
#if DEBUG
		result->windows[i].winInfo = window;
		CFRetain(window);
#endif
		i++;
	}
	CFRelease(windows);
	return result;
}
