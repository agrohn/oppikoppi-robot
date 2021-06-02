
# This file is part of oppikoppi.
# Copyright (C) 2018-2019 Anssi Gr<F6>hn

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# IMPORTANT: This script should be included after credentials.robot
  
*** Variables ***
${CourseUrlPrefix}              ${MoodleURL}/course/view.php?id=
${GradingBookSettingsPrefix}    ${MoodleURL}/grade/edit/tree/index.php?id=
${GraderReportPrefix}		${MoodleURL}/grade/report/grader/index.php?id=
${LogUrlPrefix}                 ${MoodleURL}/report/log/index.php?id=
${GradeHistoryUrlPrefix}        ${MoodleURL}/grade/report/history/index.php?id=
${StatsUrlPrefix}               ${MoodleURL}/report/stats/index.php?course=
${ParticipantUrlPrefix}		${MoodleURL}/user/index.php?id=
${ActivityCompletionUrlPrefix}        ${MoodleURL}/report/progress/index.php?course=
${ActivityReportUrlPrefix}        ${MoodleURL}/report/outline/index.php?id=
${AssignmentUrlPrefix}               ${MoodleURL}/mod/assign/view.php?id=

${DefaultGradeHistoryFile}      ${DownloadDirectory}/arvosana_historia.json
${GradeHistoryFilePrefix}       ${DownloadDirectory}/arvosana_historia_
${DefaultGradeHistoryFileEnglish}      ${DownloadDirectory}/grade_history.json
${GradeHistoryFilePrefixEnglish}       ${DownloadDirectory}/grade_history_
${LogFilePrefix}                ${DownloadDirectory}/logs_
${UserFilePrefix}                ${DownloadDirectory}/users_

*** Keywords ***
# --------------------------------------------------------------------------------
# Keywords without Moodle relation, mostly helper utililities for detecting
# presence of downloaded files and creating executable scripts. 
# --------------------------------------------------------------------------------
Does Grade History Exist
	[Arguments]	${Id}

	@{Files}=       List Files in Directory         ${DownloadDirectory}    arvosana_historia_${Id}.json         True
	${len}=		Get Length	${Files}

	[return]        ${len} > 0	

Does Users File Exist
	[Arguments]	${Id}

	@{Files}=       List Files in Directory         ${DownloadDirectory}    users_${Id}.json         True
	${len}=		Get Length	${Files}

	[return]        ${len} > 0	

Does Log File Exist
	[Arguments]	${Id}

	@{Files}=       List Files in Directory         ${DownloadDirectory}    logs_${Id}.json         True
	${len}=		Get Length	${Files}

	[return]        ${len} > 0	

Create XAPI Conversion Script
       [Arguments]   ${Id}    ${CourseName}	${DateIdentifier}
       
       ${cmd} =   Catenate  \#/bin/bash\n
       ...  ${XAPIConverterPath}
       ...  --config ${XAPIConverterConfig}
       ...  --output-dir ${DownloadDirectory}
       ...  --courseurl "${MoodleURL}/course/view.php?id=${Id}"
       ...  --coursename "${CourseName}"
       ...  --write --batch-prefix events_${DateIdentifier}_${Id}_
       ...  --errorlog errors_${Id}.log

       ${logOpt} =	Catenate	--log ${LogFilePrefix}${Id}.json
       ${hasLogFile} =			Does Log File Exist	${Id}

       ${gradeopt} =	Catenate	--grades ${GradeHistoryFilePrefix}${Id}.json
       ${hasGradeHistory} =		Does Grade History Exist	${Id}
       
       ${usersOpt} =	Catenate	--users ${UserFilePrefix}${Id}.json
       ${hasUsersFile} =	Does Users File Exist		${Id}
       
       ${authAssignments} =	Catenate	--authorize-assignments --course-start ${AuthorizeAssignmentsDate}
       ${hasAuthDate} =		Evaluate	'${AuthorizeAssignmentsDate}' != 'None'

       ${cmd} =		Set Variable If		${hasLogFile}		${cmd} ${logOpt}	${cmd}
       ${cmd} =		Set Variable If		${hasGradeHistory}	${cmd} ${gradeopt}	${cmd}
       ${cmd} =		Set Variable If		${hasUsersFile}		${cmd} ${usersOpt}	${cmd}
       ${cmd} =		Set Variable If		${hasAuthDate}		${cmd} ${authAssignments}	${cmd}
       
       Create File  ${DownloadDirectory}/xapi_etl_${Id}.sh  ${cmd}
       Run Process  chmod a+x ${DownloadDirectory}/xapi_etl_${Id}.sh  shell=yes

Create XAPI Send Script
       ${cmd} =   Catenate  \#!/bin/bash\n
       ...  if [ $(ls ${StagingDirectory}/events_*.json|wc -l) -eq 0 ]; then\n
       ...     exit 0\n
       ...  fi\n
       ...  mongo learninglocker_v2 ${MongoDropIndicesPath}\n
       ...  ${XAPIConverterPath}
       ...  --config ${XAPIConverterConfig}
       ...  --output-dir  ${StagingDirectory}
       ...  --load ${StagingDirectory}/events_*.json
       ...  --batch-send-delay 15
       ...  --batch-send-failure-delay 120
       ...  --delete-batch-after-send 
       ...  --send ${LearningLockerServerIP}\n
       ...  retval=$?\n
       ...  mongo learninglocker_v2 ${MongoCreateIndicesPath}\n
       ...  exit $retval\n
       Create File  ${StagingDirectory}/oppikoppi_send_all_events.sh  ${cmd}
       Run Process  chmod a+x ${StagingDirectory}/oppikoppi_send_all_events.sh  shell=yes


#
# At least following rules are applied in Moodle to filenames when generating file names
# 
# ? , * as _
# & as amp;
# ", :, /, \, ', | as ${EMPTY}
#
# And for them, we need a sanitizer

Sanitize File Name
	 [Arguments]	${str}
	 ${str}=	Replace String Using Regexp	${str}	("|'|:|/|\\\|\|)		${EMPTY}
	 ${str}=	Replace String Using Regexp	${str}	(\\?|\\*)	_
	 ${str}=	Replace String Using Regexp	${str}	&	amp;
	 [return]	${str}

Rename Log File
       [Arguments]      ${Id}   ${Filename}
       Move File        ${Filename}    ${LogFilePrefix}${Id}.json

Extract User Id From Url
	[Arguments]	${Url}
      	${right} =	Fetch From Right	${Url}	?id=
	${userid} =	Fetch From Left		${right}	&course
	[return]	${userid}

Make String Array
    [Arguments]   ${userRoles}


    @{userRoleList}=  Split String  ${userRoles}  ,
    ${arrayStr}=   Get From List  ${userRoleList}  0
    Remove From List   ${userRoleList}   0
    ${arrayStr}=  Catenate  "${arrayStr}"
    FOR  ${role}   IN  @{userRoleList}
       Log To Console  Role is ${role}
      ${arrayStr}=   Catenate  ${arrayStr}, "${role}"
    END
    
    ${arrayStr}=  Catenate  [   ${arrayStr}   ]
    [return]  ${arrayStr}

File Size Larger Than Zero
     [Arguments]      ${FileName}
     ${FileSize} =      Get File Size      ${FileName}
     Run Keyword Unless     ${FileSize} > 0     Fail    File size is zero.

Is First Fetch For Course
        [Arguments]    ${Id}
        ${firstTime}=   Run Keyword And Return Status  File Should Not Exist   ${PowerBIDataDir}/${Id}*.json
        [return]  ${firstTime}

Starts With
       [Arguments]      ${String}     ${Prefix}

       ${PrefixLen}=      Get Length      ${Prefix}     
       ${StringPrefix}=              Get Substring        ${String}  0       ${PrefixLen}  
       ${result}=     Evaluate        '${Prefix}'=='${StringPrefix}'
       
       [return]   ${result}
