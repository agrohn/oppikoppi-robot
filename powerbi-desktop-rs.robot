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
Library		Process
Library		UIAutomationLibrary
Library		OperatingSystem
Library		String
Resource	credentials.robot

*** Variables ***
${handle}	${None}


*** Keywords ***
Update Course Listing
	# determine should we use SSL and https
	${certStr}=		Set Variable If		"${LearningLockerServerCertPath}"=="${Empty}"		${Empty}	--cacert ${LearningLockerServerCertPath}
	${serverURL}=	Set Variable If		"${LearningLockerServerCertPath}"=="${Empty}"		http://${LearningLockerServerIP}/powerbi/active-courses.txt		https://${LearningLockerServerIP}/powerbi/active-courses.txt
	# use curl to make query
	${result}	 ${stdout}	Run And Return RC And Output	curl.exe ${certStr} -u ${DatasetWebUser}:${DatasetWebPassword} ${serverURL} 2>nul
	# Split into list
	@{CourseIds}	Split String	${stdout}
	[return]	${CourseIds}

Make New Power BI File
	[Arguments]		${Id}
	${fileName}=	Set Variable	${OppikoppiBaseDir}/${Id}.pbix
	${template}=	Set Variable	${OppikoppiBaseDir}/powerbi-templates/oppikoppi_template-rs.pbix
	Copy File	${template}		${fileName}
	[return]	${fileName}

Start Power BI
	[Arguments]		${Id}
	${fileName}=	Set Variable	${OppikoppiBaseDir}\\${Id}.pbix
	Start Process	${PowerBI}	${fileName}	
	${title}=	Set Variable	${id} - ${PowerBIWindowVersionSuffix}
	# wait so processes get visible 
	Sleep	1 seconds
	Wait For Active Window	${title}
	Sleep	5 seconds
	Log To Console 	Done Waiting for active widnow
	
Close Failed Power BI
	[Arguments]		${Id}
	Click Query Change Close
	Close PowerBI Dont Save
	Sleep	5 seconds
	Remove File		${OppikoppiBaseDir}\\${Id}.pbix
	Wait Until Removed	${OppikoppiBaseDir}\\${Id}.pbix
	Log		Could not update data for ${Id}		ERROR

Shutdown
	Save Report
	Send Close Shortcut
	Terminate Process 	${handle}

Make Power BI and Publish
	[Arguments]		${Id}
	
	Make New Power BI File	${Id}
	
	Start Power BI	${Id}
	
	Set Template Parameters	${Id}	https://${LearningLockerServerIP} 
	
	${FinalState}=	Set Variable	${None}
	:FOR	${i}	IN RANGE	600
	\	${FinalState}=	Get Applying Query Changes State
	\	Exit For Loop If	'${FinalState}'!='Processing'
	\	Sleep	1 second
	
	#Log to console	State was ${FinalState}
	Run Keyword If	'${FinalState}'=='Failed'	Close Failed Power BI	${Id}
	Return From Keyword If 	'${FinalState}'=='Failed'
	Save Report

	${PublishState}=	Set Variable 	""
	
	Publish Visualization To PowerBI Service RS	${PowerBIReportServerURL}
	
	:FOR	${i}	IN RANGE	600
	\	${PublishState}=	Get Publishing State RS
	\	Exit For Loop If	'${PublishState}'!='Processing'
	\	Sleep	1 second
	Run Keyword If	'${PublishState}'=='Failed'	Fail	Could not publish ${Id}
	Run Keyword If	'${PublishState}'=='Done' 	Close Publishing
	Shutdown


*** Test Cases ***
Generate Visualization
	
	@{CourseIds}=	Update Course Listing
	:FOR	${Id}	IN	@{CourseIds}
	\	Log To console	Creating Visualization for Course ${Id}
	\	${needsDoing}=	Run Keyword and Return Status	File Should Not Exist	${OppikoppiBaseDir}/${Id}.pbix
	\	Run Keyword If	${needsDoing}	Make Power BI and Publish	${Id}	ELSE	Log 	Skipping already completed ${Id}
