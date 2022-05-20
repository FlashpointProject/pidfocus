/* pidfocus
 * Focuses and brings to front the first window belonging to a PID.
 * A window "belongs" to a process if:
 *     - Quartz associates the window with the PID, OR
 *     - Quartz associates the window with any descendant
 *       (child, grandchild, etc.) of the process specified
 *       by the input PID.
 *
 * This tool performs a breadth-first search of the process tree for
 * any process associated with a Quartz window. If one is found, it is
 * brought to the front. The root of the search tree is the PID argument.
 */
#include <string.h>
#include <sys/queue.h>
#include "util.h"
#include "structs.h"

// We won't need more than 11 bytes to hold a PID and null terminator.
// Because: an int32_t has max value 2147483647, which has a character lenth of 10.
// TODO this will not be forward-compatible if pid_t becomes something other than int32_t!
#define PIDSZ 11
// "pgrep -P " has length 9.
#define BUFSZ PIDSZ+9

// The queue to hold the PIDs used in the breadth-first search for a PID with a window.
STAILQ_HEAD(stailhead, entry) head = STAILQ_HEAD_INITIALIZER(head);
struct entry {
	pid_t pid;
	STAILQ_ENTRY(entry) entries;
};

// Holds the command line for popen to use.
char* cmdbuf;
// Holds the file stream to pgrep's stdout.
FILE* pg;
// Holds the current PID entry.
struct entry* currentPID;
// Holds various status codes for checking.
int status;
// Pointer to the next line of output from pgrep's stdout.
char* line = NULL;
// The resulting window ID.
NSDictionary* found_window = NULL;
// The set of current windows.
struct WindowSet* window_set;

int main(int argc, char** argv) {
	if (argc != 2) {
		fprintf(stderr, "Must pass exactly one argument!\n");
		return 1;
	}

	currentPID = malloc(sizeof(struct entry));
	// pid_t is an int32_t for now.
	// TODO this will not be forward-compatible if the type changes!
	if (!parse_nneg_int(argv[1], &(currentPID->pid))) {
		// Error message will already be printed, just return.
		return 1;
	}

	// Some initialization: allocate the cmdbuf, and init the singly-linked tail queue.
	cmdbuf = malloc(BUFSZ * sizeof(char));
	STAILQ_INIT(&head);
	// Put currentPID at the end (also beginning) of the queue.
	STAILQ_INSERT_TAIL(&head, currentPID, entries);
	// Grab the current window set.
	window_set = get_window_array();

	// General-purpose iteration counter.
	int i;
	// Throwaway, length of line for getline() to use.
	size_t unused_len;
	// Temporary entry, used before we add it.
	struct entry* tempPID;
	// TODO: use fast singly-linked tail-queue iteration? See the man-page.
	while (!STAILQ_EMPTY(&head)) {
		currentPID = STAILQ_FIRST(&head);
		// Check: is the current pid associated with any of the windows?
		for (i = 0; i < window_set->len; i++) {
			if (currentPID->pid == window_set->windows[i].ownerPID) {
				found_window = window_set->windows[i].winInfo;
				break;
			}
		}
		if (found_window != NULL) {
			break;
		} else {
			status = snprintf(cmdbuf, BUFSZ, "pgrep -P %d", currentPID->pid);
			if (status >= BUFSZ) {
				fprintf(stderr, "Arguments too long! Should be impossible?\n");
				return 2;
			} if (status < 0) {
				fprintf(stderr, "snprintf failed\n");
				return 2;
			}
			if (NULL == (pg = popen(cmdbuf, "r"))) {
				fprintf(stderr, "popen failed\n");
				return 2;
			}

			while (getline(&line, &unused_len, pg) != -1) {
				tempPID = malloc(sizeof(struct entry));
				tempPID->pid = atoi(line);
				STAILQ_INSERT_TAIL(&head, tempPID, entries);
			}
			pclose(pg);
		}
		STAILQ_REMOVE_HEAD(&head, entries);
		free(currentPID);
	}
	if (found_window != NULL) {
		CGWindowID temp;
		CFShow(CFDictionaryGetValue((CFDictionaryRef)found_window, kCGWindowNumber));
		printf("PID: %d\n", currentPID->pid);
	}

	if (line != NULL) {
		free(line);
		line = NULL;
	}
	free(cmdbuf);
	cmdbuf = NULL;
	for (i = 0; i < window_set->len; i++) {
		CFRelease(window_set->windows[i].winInfo);
	}
	free(window_set->windows);
	free(window_set);
	while (!STAILQ_EMPTY(&head)) {
		currentPID = STAILQ_FIRST(&head);
		STAILQ_REMOVE_HEAD(&head, entries);
		free(currentPID);
	}
	return 0;
}

