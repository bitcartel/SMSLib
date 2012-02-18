/*
 * smsutil.m
 * smslib command line tool
 *
 * SMSLib Sudden Motion Sensor Access Library
 * Copyright (c) 2010 Suitable Systems
 * All rights reserved.
 * 
 * Developed by: Daniel Griscom
 *               Suitable Systems
 *               http://www.suitable.com
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal with the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimers.
 * 
 * - Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimers in the
 * documentation and/or other materials provided with the distribution.
 * 
 * - Neither the names of Suitable Systems nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this Software without specific prior written permission.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS WITH THE SOFTWARE.
 *
 * For more information about SMSLib, see
 *		<http://www.suitable.com/tools/smslib.html>
 * or contact
 *		Daniel Griscom
 *		Suitable Systems
 *		1 Centre Street, Suite 204
 *		Wakefield, MA 01880
 *		(781) 665-0053
 *
 */

#import <Foundation/Foundation.h>
#import "smslib.h"
#include <unistd.h>
#include <sysexits.h>

#define SMSUTIL_VERSION "1.2"

#define MAX_AXES_LENGTH (20)

// Prototypes
void SignalHandler(int sigraised);
long getUTime(void);
long getMTime(void);

static int running = YES;

int main (int argc, char ** argv) {
	// Configuration variables
	int count = 0;			// Number of samples; 0 means "go forever"
	float period = 1.0;		// Seconds between samples
	char axes[MAX_AXES_LENGTH + 1] = "xyz";
	BOOL calibrated = YES;
	BOOL help = NO;
	BOOL debugging = NO;
	int separator = ' ';
	
	// Other variables
	BOOL error = NO;		// Was there an argument error?
	long uPeriod;			// Microseconds between samples
	char *name;				// Base name of application (for messages)
	sms_acceleration accel;
	int c, x, result;
	NSAutoreleasePool *pool;
	long startMTime, lastUTime, thisUTime, waitUTime;
	
	// Get base name of application (for error messages)
	name = strrchr(argv[0], '/');
	name = (name) ? name + 1 : argv[0];
	
	// Parse command line options
	opterr = 0;	
	while ((c = getopt (argc, argv, ":a:c:i:s:uhd")) != -1) {
		switch (c) {
			case 'c':
				// Number of samples. Integer argument.
				if (sscanf(optarg, "%d", &count) != 1) {
					fprintf(stderr, "%s: bad argument to -c\n", name);
					error = YES;
				}
				break;
				
			case 'a':
				// Axes to be output. 
				if (strlen(optarg) > MAX_AXES_LENGTH) {
					// Arg too long
					fprintf(stderr, "%s: argument to -a limited to %d characters\n",
							name, MAX_AXES_LENGTH);
					error = YES;
				} else if (strspn(optarg, "xyzt") != strlen(optarg)) {
					// Arg not all "x", "y", "z" or "t"
					fprintf(stderr, "%s: argument to -a must only contain 'x's, 'y's, 'z's and 't's\n", name);
					error = YES;
				} else {
					strcpy(axes, optarg);
				}
				break;
				
			case 'i':
				// Seconds between samples. Can be floating point.
				if (sscanf(optarg, "%f", &period) != 1) {
					fprintf(stderr, "%s: bad argument to -i\n", name);
					error = YES;
				} else if (period < 0) {
					fprintf(stderr, "%s: argument to -i must be non-negative\n", name);
					error = YES;
				}
				break;
				
			case 'u':
				// Uncalibrated
				calibrated = NO;
				break;
				
			case 'd':
				// Debugging
				debugging = YES;
				break;
			
			case 'h':
				// Help
				help = YES;
				break;
			
			case ':':
				// Missing argument
				fprintf(stderr, "%s: option -%c requires an argument\n",
						name, optopt);
				error = YES;
				break;
			
			case 's':
				// Separator character
				if (sscanf(optarg, "%d", &separator) != 1) {
					fprintf(stderr, "%s: bad argument to -s\n", name);
					error = YES;
				} else if (separator > 255 || separator < 0) {
					fprintf(stderr, "%s: argument to -i must be 0-255\n", name);
					error = YES;
				}
				break;
				
			case '?':
				if (isprint (optopt))
					fprintf(stderr, "%s: unknown option `-%c'.\n", 
								name, optopt);
				else
					fprintf(stderr,
							 "%s: unknown option character `\\x%x'.\n",
							 name, optopt);
				error = YES;
				break;
				
			default:
				break;
		}
		
		// Was there a problem, or was help requested?
		if (help || error) {
			if (!error) {
				fprintf(stderr,
					"%s: prints values from Sudden Motion Sensor\n"
					"    version %s, SMSLib version %s\n"
					"    copyright (c) 2010 Daniel Griscom, Suitable Systems\n",
					name, SMSUTIL_VERSION, SMSLIB_VERSION);
			}
			fprintf(stderr,
				"usage: %s -[hud] [-i <period>] [-c <count>] [-a <axes>] [-s <char>]\n"
				"options:\n"
				"    -h          prints this message\n"
				"    -u          uncalibrated output\n"
				"    -d          debugging: hardware ignored, data are decaying sine waves\n"
				"    -i <period> seconds between samples (default: 1.0,\n"
				"                0 => sample as fast as possible)\n"
				"    -c <count>  number of samples (default: 0 => run forever)\n"
				"    -a <axes>   axes to be output (default: xyz,\n"
				"                can be in any order, use t for time in ms)\n"
				"    -s <char>   ASCII value of separator char (default: 32)\n",
				name);
			if (error) {
				return EX_USAGE;
			} else {
				return 0;
			}
		}
	}	// End parsing command line options
	
	// Set up signal handler for clean termination
    if (signal(SIGINT, SignalHandler) == SIG_ERR) {
        fprintf(stderr, "%s: could not establish new signal handler (err = %d)\n", name, errno);
		return EX_SOFTWARE;
	}
	
	// Now start doing the sampling!
	pool = [[NSAutoreleasePool alloc] init];
	if (debugging) {
		result = smsDebugStartup(nil, nil);
	} else {
		result = smsStartup(nil, nil);
	}
	if (result != SMS_SUCCESS) {
		fprintf(stderr, "Error: couldn't start SMS\n");
		[pool release];
		return EX_UNAVAILABLE;
	}
	
	if (calibrated) {
		smsLoadCalibration();
	}
	
	uPeriod = round(period * 1000000);
	lastUTime = getUTime();
	startMTime = getMTime();
	
	// Sample loop
	while (running) {
		if (calibrated) {
			smsGetData(&accel);
		} else {
			smsGetUncalibratedData(&accel);
		}
		// Field loop
		for (x = 0; x < strlen(axes); x++) {
			c = axes[x];
			if (x > 0) {
				printf("%c", separator);
			}
			switch (c) {
				case 'x':
					if (calibrated) {
						printf("%f", accel.x);
					} else {
						printf("%d", lrint(accel.x));
					}
					break;
					
				case 'y':
					if (calibrated) {
						printf("%f", accel.y);
					} else {
						printf("%d", lrint(accel.y));
					}
					break;
				
				case 'z':
					if (calibrated) {
						printf("%f", accel.z);
					} else {
						printf("%d", lrint(accel.z));
					}
					break;
					
				case 't':
					// Show milliseconds since program started
					printf("%d", getMTime() - startMTime);
					break;
			}
		}	// End field loop
		
		printf("\n");
		if (count > 0 && --count == 0) {
			// Time to stop sampling
			break;
		}
		
		// Yes, there's overflow all over the place here, but it doesn't
		// matter.
		thisUTime = getUTime();
		waitUTime = lastUTime + uPeriod - thisUTime;
		if (waitUTime > 0) {
			usleep(lastUTime + uPeriod - thisUTime);
		}
		lastUTime += uPeriod;
		// Make sure we don't get too far behind
		if (lastUTime < thisUTime) {
			lastUTime = thisUTime;
		}
	}	// End sample loop
	
	[pool release];
	
	return 0;
} // End main()

// Returns time in microseconds, clipped to a long
long getUTime() {
	struct timeval t;
	gettimeofday(&t, 0);
	return (t.tv_sec * 1000000 + t.tv_usec);
}

// Returns time in milliseconds, clipped to a long
long getMTime() {
	struct timeval t;
	gettimeofday(&t, 0);
	return (t.tv_sec * 1000 + t.tv_usec / 1000);
}

// Called on SIGINT (control-C)
void SignalHandler(int sigraised)
{
	// Stop runloop
    running = NO;    
}
