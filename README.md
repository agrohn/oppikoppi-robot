# Oppikoppi

Solution for downloading learning analytics data from Moodle and other sources, and storing it to a learing record store.
It much relies on open source version of [Learing Locker](https://github.com/LearningLocker/learninglocker) and
[xapi_converter](https://github.com/agrohn/xapi_converter) utility. Actual retrieval code is written
using [Robot Framework](https://robotframework.org) and especially its quite wonderful
[Selenium Library](https://github.com/robotframework/SeleniumLibrary/). 

This project has been developed as part of [APOA project](https://apoa.tamk.fi) in [Karelia University of Applied Sciences](https://www.karelia.fi). 

Anssi Gröhn (c) 2018-2021.

## Prerequisities

You need to have appropriate drivers for browsers (chrome, firefox),
depending what you want to use.

* Geckodriver: https://github.com/mozilla/geckodriver/releases
* Chromedriver: https://sites.google.com/chromium.org/driver/

## Configuring

You need to configure `credentials.robot` file prior to running any scripts. This file
is used in obtaining account information and server details where data is sent.
Please see `credentials.robot.example` for details.

Additionally, all bash scripts require tweaking since all paths to executables and directories
must be set accordingly. 

For further setup information, please see ASENNA.md (instructions only in finnish for the time being).

# Downloading data

This is the default action and easiest to perform manually. It dowloads all logs, user files
and grade histories from all courses on all dates available in Moodle, and sets them up in
Staging directory (defined in `credentials.robot`) to be sent to learning locker.
When oppikoppi is set up completely, data retrieval is performed daily without user intervention.

```bash
$ DISPLAY=:0.0 robot fetch-moodle-data.robot
```

## Download all logs from specified date

Date parameter uses format YYYY-MM-DD, below is a script that
downloads everything from 30th of January, 2019.

```bash
DISPLAY=:0.0 robot --variable Date:2019-01-30 fetch-moodle-data.robot
```

## Download all logs from specified course

Example below downloads logs from all dates from a single moodle course with id 101.

```bash
DISPLAY=:0.0 robot --variable CourseId:101 fetch-moodle-data.robot
```

## Combining course id and dates

Two examples above combined would be expressed as

```bash
DISPLAY=:0.0 robot --variable CourseId:101 --variable Date:2019-01-30 fetch-moodle-data.robot
```

# Invoking Power BI Desktop Robot

Power BI Desktop for Report Server is automatically run using command

```
robot powerbi-desktop-rs.robot
```

Robot script relies on custom python library called `UIAutomationlibrary.py`. It uses template (one available in powerbi-templates directory)
to construct Power BI visualization using server address and course id.


