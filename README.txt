SMSLib Sudden Motion Sensor Access Library Copyright (C) 2010 Daniel
Griscom, Suitable Systems

SMSLib is being distributed under the terms of the University of Illinois/
NCSA Open Source License: for more details see LICENSE.txt


About SMSLib:

SMSLib is an Objective C library giving access to the Sudden Motion
Sensor on recent Macintosh laptops. It includes default calibrations for
all such laptops, and includes a facility for storing customized
calibrations when desired.

Although SMSLib is written using Objective C, it is mostly vanilla C,
with Objective C used for logging support. It is not object-oriented;
there's little use in creating multiple instances of it, since they'd
all connect to the same single hardware device, and would have the same
state.


Using SMSLib:

1 - Call smsStartup() to initialize access to the SMS

2 - Call smsLoadCalibration() to load any stored calibration values

3 - Call smsGetData() to fetch calibrated SMS data. This can be done as
many times as you like; it takes 1ms to 2.5ms to return (on a MacBook Pro).
The acceleration record is a floating point value per axis, with 1.0
representing one gravity of acceleration.

4 - Call smsShutdown() when you have finished with SMSLib.

See smslib.m and SMSTester.m for an example of this.


Calibration:

Although SMSLib includes default calibrations for all flavors of the
SMS, each individual sensor will have slightly different zero and gain
values. To handle this, SMSLib allows you to store calibration values in
the system preferences, under the tag com.suitable.SeisMacLib.
SeisMaCalibrate is one application which uses this facility. Once
calibration values are saved, any application using SMSLib will
automatically use them.


Hardware:

SMSLib works on any Sudden Motion Sensor-equipped laptop, including the
most recent Core 2 Duo-equipped machines.

Although SMSLib was designed to hide the difference between different
hardware implementations of the SMS, there are still some visible
differences. The major ones are between the G4-based laptops and the
Intel-based laptops.

G4-based laptops all use SMSs which resolve 50 or so counts per gravity.
Many of them have a failure mode where SMSLib stops being able to access
the SMS until the next reboot. This seems to happen on the PowerBook5,6,
PowerBook5,7, PowerBook6,7 and PowerBook6,8 models; the PowerBook5,8 and
PowerBook5,9 models seem to be reliable.

Each of the G4-based models has different polarities for their axis
sensors; SMSLib corrects for this.

Intel-based laptops all use SMSs which resolve 250 or so counts per
gravity, and all have the same axis zeros and polarities. SMSLib access
is reliable on all Intel-based laptops.


Operating systems:

SMSLib works on any version of OS X that supports the host machine. It
has been tested on OS X 10.3.9 through 10.4.8, and I have a report that
it functions under early versions of 10.5.


About smsutil

smsutil is a command-line tool that uses SMSLib to output a series of
acceleration values. Its command-line arguments select which axes are
displayed, how often the values are fetched, and how many values should
be displayd. For example:

./smsutil -i0.005 -s09 -c1000

will output 1000 lines of data, with each line having tab-separated X, Y
and Z values, sampling every 5ms, covering 5 seconds of real time.

For further information on the command line options, type

./smsutil -h


About smslibtest

smslibtest is a command-line tool that tests SMSLib. It outputs a
detailed log of SMSLib's functions.


Further information:

For more information about SMSLib, see
<http://www.suitable.com/tools/smslib.html>

To calibrate your Sudden Motion Sensor, use SeisMaCalibrate:
<http://www.suitable.com/tools/seismacalibrate.html>

Or, you may enjoy the seismographic program SeisMac:
<http://www.suitable.com/tools/seismac.html>

To contact the author:
Daniel Griscom
Suitable Systems
1 Centre Street, Suite 204
Wakefield, MA 01880
(781) 665-0053
griscom@suitable.com