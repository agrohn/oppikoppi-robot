
#  This file is part of oppikoppi.
#  Copyright (C) 2021 Anssi Gröhn

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.

*** Settings ***
Library		SeleniumLibrary
Library		Collections
Library   String
Library   OperatingSystem
Library   DateTime
Library   Process
Suite Teardown  Close Browser
Resource	credentials.robot
Resource	common.robot
Resource	snap.robot
Resource        login.robot
Resource	assignment-duedates.robot
*** Variables ***
${Date}   ${None}
${Index}  ${0}
${CourseId}     ${None}
${AuthorizeAssignmentsDate}	${None}
${FirstTimeDownloadAll}   ${False}
*** Keywords ***

*** Test Cases ***
Clear Conversion Directory
      [Tags]	Clear
	# Clearing up scripts and logs
	${Result} =	Run Process	rm -f ${DownloadDirectory}/*.json	shell=true
	Should Be Equal As Integers   ${Result.rc}  0
	${Result} =	Run Process	rm -f ${DownloadDirectory}/*.sh		shell=true
	Should Be Equal As Integers   ${Result.rc}  0
	${Result} =	Run Process	rm -f ${DownloadDirectory}/*.log	shell=true
	Should Be Equal As Integers   ${Result.rc}  0
Login
	[Tags]	Init
	Set Screenshot Directory	/var/log/oppikoppi
        Log in to Moodle Local

Get Course Urls
    	[Tags]	Init
        Run Keyword If  ${CourseId} == ${None}  Open My Courses View
	Sleep	    0.5 seconds
        @{Temp}=		Run Keyword If          ${CourseId} != ${None}    	Get Taught Course Url And Name  ${CourseId}     ELSE        Get Taught Course Urls And Names
        @{CourseUrls}=		Get From List	${Temp}		0     
        @{CourseNames}=		Get From List	${Temp}		1
        Set Global Variable     @{CourseUrls}
        Set Global Variable     @{CourseNames}

Store Active Courses
      [Tags]	Init
      ${activeCourses}	Set Variable	${Empty}
        FOR	${CourseUrl}	IN	@{CourseUrls}
               ${Name} =       Get From List   ${CourseNames}  ${Index}
               ${Index} =     Evaluate   ${Index} + 1
               ${Id} =         Fetch From Right        ${CourseUrl}  =
	       ${activeCourses}=	Catenate	${activeCourses}	${Id}${\n}
	END
        Run Keyword If  ${CourseId} == ${None}	Create File  ${PowerBIDataDir}/active-courses.txt  ${activeCourses}
        Run Keyword If  ${CourseId} != ${None}  Log   "Skipping creation of active-courses.txt, since only a single course selected."  WARN

Download Course Logs
	 [Tags]		Download
        FOR	${CourseUrl}	IN	@{CourseUrls}
               ${Name} =       Get From List   ${CourseNames}  ${Index}
               ${Index} =     Evaluate   ${Index} + 1
               ${Id} =         Fetch From Right        ${CourseUrl}  =
               @{Participants}=		Extract Participant Json		${Id}
               ${contents}=	   Catenate	SEPARATOR=${EMPTY}	@{Participants}
               # Check should we download everything after all (for first run)
               ${firstFetch}=    Is First Fetch For Course   ${Id}
               ${tmpDate}=   Set Variable If   ${firstFetch} and ${FirstTimeDownloadAll}  ${None}   ${Date}
               Run Keyword If  ${firstFetch} and ${FirstTimeDownloadAll}  Log   "Found new course ${Id}, downloading everything to this date."  WARN
               Create File	${UserFilePrefix}${Id}.json		${contents}
               Open Grade History Page         ${Id}
               ${HasPermissionToGrades} =		Check Permission To View Grade History
               Run Keyword If  ${HasPermissionToGrades}  Fetch Grade History   ${tmpDate}
               ${HasGradeInfo} =       Are There Grades Or Logs
               Run Keyword If  ${HasGradeInfo}      Download Grade History
               Run Keyword If  ${HasGradeInfo}      Rename Grade History File       ${Id}

	       Open Log Page   ${Id}
       	       ${HasPermissionToLogs}=		Check Permission To View Logs
               Run Keyword If  ${HasPermissionToLogs}  Download Event Logs         ${Id}   ${tmpDate}
	       
	       ${duedateJson}=	       Get Assignments With Due Dates	${Id}
	       Create File	${PowerBIDataDir}/${Id}${AssignmentDueDateSuffix}      ${duedateJson}
	       
	       ${now}=	Get Current Date	       result_format=%Y-%m-%d
	       ${tmpDateIsNone}		Run Keyword And Return Status	Should Be Equal	${tmpDate}	${None}
	       ${DateIdentifier}=	Set Variable If		${tmpDateIsNone}	   ${now}-full	${tmpDate}
               Create XAPI Conversion Script   ${Id}   ${Name}	${DateIdentifier}
        END

Convert From ASCII To UTF-8
	[Tags]	Conversion
	FOR	${CourseUrl}	IN	@{CourseUrls}
               ${Name} =       Get From List   ${CourseNames}  ${Index}
               ${Index} =      Evaluate   ${Index} + 1
               ${Id} =         Fetch From Right        ${CourseUrl}  =

	       ${hasLogFile} =			Does Log File Exist	${Id}
	       ${hasGradeHistory} =		Does Grade History Exist	${Id}

	       # utf8ascii_fix_sed.sh script itself takes care of whether files exist or not.
	       ${Result} =  Run Process  ${Utf8AsciiFixPath} ${LogFilePrefix}${Id}.json   shell=true   stdout=/dev/null  stderr=/dev/null
	       Should Be Equal As Integers   ${Result.rc}  0

	       ${Result} =  Run Process  ${Utf8AsciiFixPath} ${GradeHistoryFilePrefix}${Id}.json   shell=true   stdout=/dev/null  stderr=/dev/null
	       Should Be Equal As Integers   ${Result.rc}  0
       	       
        END
	
Invoke Conversion Scripts
       [Tags]	ETL
        @{Scripts}=       List Files in Directory         ${DownloadDirectory}    xapi_etl_*.sh         True

        # since xapi_converter spawns threads, Run Process needs stdout and stderr
        # redirected for some reason. Otherwise Run Process will never return upon proper program exit.
        # See: https://github.com/robotframework/robotframework/issues/2085
        
        FOR	${Script}	IN	@{Scripts}
           ${Result} =  Run Process   ${Script}  shell=true   stdout=/dev/null  stderr=/dev/null
           Should Be Equal As Integers   ${Result.rc}  0
	END

Move Statement Batches To Staging Area
     [Tags]    ETL
     Move Files		${DownloadDirectory}/events_*.json	${StagingDirectory}
     Create XAPI Send Script
