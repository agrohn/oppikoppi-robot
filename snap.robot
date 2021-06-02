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
  
*** Keywords ***
# --------------------------------------------------------------------------------
# Moodle-related keywords, with theme called Snap.
# These keywords parse HTML content for specific strings using xpath queries. 
# --------------------------------------------------------------------------------

Do You Have Permission To View Assignments
        ${AssignmentItemCount}		Get Element Count	xpath=//a[@class="gradeitemheader"]
        [return]        ${AssignmentItemCount} > 0

        
View Assignments
        ${AssignmentItems}=		Get Webelements		xpath=//a[@class="gradeitemheader"]
        ${AssignmentUrls}=         Create List
       	FOR	${x}	IN	@{AssignmentItems}
	       ${Url}=	Set Variable	
	       Append To List	${AssignmentUrls}		${x.get_attribute('href')}
	END	
        FOR	${AssignmentUrl}	IN	@{AssignmentUrls}
               Go To   ${AssignmentUrl}
	END
	
View All Course Assignments
        [Arguments]   ${Id}
       	Go To   ${GradingBookSettingsPrefix}${Id}
        ${HasPermission}=    Do You Have Permission To View Assignments
        Run Keyword If  ${HasPermission}      View Assignments

Get Short Name
        [Arguments]      ${Id}
        Go To   ${StatsUrlPrefix}${Id}
        ${ShortName}=   Get Text        xpath=//select[@id="menucourse"]/option[@value=${Id}]
        [return]        ${ShortName}


Open Activity Completion Page
     [Arguments]        ${Id}
     Go To              ${ActivityCompletionUrlPrefix}${Id}

Open Activity Report Page
     [Arguments]        ${Id}
     Go To              ${ActivityReportUrlPrefix}${Id}

Open Log Page
        [Arguments]      ${Id}
        Go To   ${LogUrlPrefix}${Id}

Check Permission To View Logs
        ${FetchLogButtonCount} =		Get Element Count	//input[@value="Hae lokit"]
        ${FetchLogButtonCountEnglish} =		Get Element Count	//input[@value="Get these logs"]
        [return]        ${FetchLogButtonCount} > 0  or   ${FetchLogButtonCountEnglish} > 0 

Click Fetch Logs
        ${FetchLogButtonCount} =		Get Element Count	//input[@value="Hae lokit"]
        ${FetchLogButtonCountEnglish} =		Get Element Count	//input[@value="Get these logs"]

        Run Keyword If  ${FetchLogButtonCount} > 0  Click Element    //input[@value="Hae lokit"]
        Run Keyword If  ${FetchLogButtonCountEnglish} > 0  Click Element    //input[@value="Get these logs"]

Click Download
        ${DownloadButtonCount} =		Get Element Count	//button[contains(., 'Lataa')]
        ${DownloadButtonCountEnglish} =		Get Element Count	//button[contains(., 'Download')]
        Run Keyword If  ${DownloadButtonCount} > 0  Click Element   //button[contains(., 'Lataa')]
        Run Keyword If  ${DownloadButtonCountEnglish} > 0  Click Element   //button[contains(., 'Download')]
        
Check Permission To View Grade History
        ${FetchLogButtonCount} =		Get Element Count	//input[@id="id_submitbutton"]
        [return]        ${FetchLogButtonCount} > 0

Select Log Date
        [Arguments]      ${Id}  ${Date}
        # This is a little silly, but first into decimal epoch, then to integer to get rid of decimal,
        # and finally back to string so Selenium gets its way.

        # now this kinda sucks, Summer/Winter time wreaks havoc when computing epoch as it is dynamically generated to
        # moodle server, which at some point did  NOT use winter/summer time change, and server timezone may change
	# when updated. 
        ${epoch_date}=        Convert Date    ${Date}   epoch
        ${epoch_date}=        Convert To Integer        ${epoch_date}
        ${epoch_date_local}=        Convert To String         ${epoch_date}

	# Offset 1hr (time difference + daylight savings on server)
	${epoch_date_minus1h}=		Evaluate  ${epoch_date} - 3600
	${epoch_date_minus1h}=		Convert To String	${epoch_date_minus1h}
	
        # 7200 offsets epoch by two hours (timedifference to GMT)
        ${epoch_date_minus2h}=         Evaluate  ${epoch_date} - 7200
        ${epoch_date_minus2h}=         Convert To String         ${epoch_date_minus2h}

        # 10800 offsets epoch by three hours (timedifference to GMT + no daylight savings on server?)
        ${epoch_date_minus3h}=         Evaluate  ${epoch_date} - 10800
        ${epoch_date_minus3h}=         Convert To String         ${epoch_date_minus3h}

	# Next we need to make sure we actually have such a date available
	@{ListDates}=		Get List Items 	  id=menudate	True

        # Check what epoch value sticks...
	${dateFound}=	Run Keyword And Return Status	Should Contain	${ListDates}	${epoch_date_local}
	Run Keyword If	${dateFound}	Select From List By Value       id=menudate     ${epoch_date_local}


        ${dateFoundMinus1h}=	Run Keyword And Return Status	Should Contain	${ListDates}	${epoch_date_minus1h}
	Run Keyword If	${dateFoundMinus1h}	Select From List By Value       id=menudate     ${epoch_date_minus1h}

        ${dateFoundMinus2h}=	Run Keyword And Return Status	Should Contain	${ListDates}	${epoch_date_minus2h}
	Run Keyword If	${dateFoundMinus2h}	Select From List By Value       id=menudate     ${epoch_date_minus2h}

        ${dateFoundMinus3h}=	Run Keyword And Return Status	Should Contain	${ListDates}	${epoch_date_minus3h}
	Run Keyword If	${dateFoundMinus3h}	Select From List By Value       id=menudate     ${epoch_date_minus3h}

	${dateReallyFound}=     Evaluate        ${dateFound} or ${dateFoundMinus1h} or ${dateFoundMinus2h} or ${dateFoundMinus3h}

        [return]	${dateReallyFound}
	


Extract Participant Json
       [Arguments]	${CourseId}
       Go To	${ParticipantUrlPrefix}${CourseId}
       Wait Until Element Is Visible   //input[@id="select-all-participants"]	15 seconds
       ${showall_link}=	  Run Keyword And Return Status				Element Should Be Visible	//div[@id="showall"]/a
       Run Keyword If	  ${showall_link} 	 Click Element    //div[@id="showall"]/a
       Wait Until Element Is Not Visible	 //input[@id="checkall"]	10 seconds
       
       ${userTable}=		Get Webelement		xpath=//table[@id="participants"]
       ${userElems}=		Set Variable            ${userTable.find_elements_by_xpath('.//tbody/tr[not(contains(@class,"emptyrow"))]/th/a')}
       ${userEmails}=		Set Variable            ${userTable.find_elements_by_xpath('.//tbody/tr[not(contains(@class,"emptyrow"))]/td[2]')}
       ${userRoles}=		Set Variable            ${userTable.find_elements_by_xpath('.//tbody/tr[not(contains(@class,"emptyrow"))]/td[3]')}

       ${Participants}=         Create List
       ${tmpIndex}		Set Variable	0
       Append To List	${Participants}		[

       FOR	${userElem}	IN	@{userElems}
       		${UserId} =		Extract User Id From Url	${userElem.get_attribute('href')}
       		${UserName} =		Fetch From Right	${userElem.get_attribute('innerHTML')}  >
       		${emailElem} =		Get From List   ${userEmails}   ${tmpIndex}
        	${userRole} =   Get From List   ${userRoles}  ${tmpIndex}
        	${roleArray}=   Make String Array   ${userRole.get_attribute('innerHTML')}
       		${UserEmail}=		Set Variable	${emailElem.get_attribute('innerHTML')}
       		Append To List		${Participants}		{ "name": "${UserName}", "id": "${UserId}", "email": "${UserEmail}", "roles": ${roleArray} }
       		Append To List		${Participants}		,
       		${tmpIndex} =		Evaluate	${tmpIndex} + 1
       END
       # replace last , with ] to make array complete.
       Set List Value	${Participants}		-1	]

       [return]		${Participants}


Complete Event Log Download
        [Arguments]      ${Id}  ${Date}   ${ShortName}
	Wait Until Element Is Visible	id=downloadtype_download	15 seconds

	# Workaround for big footers - for some reason Scroll Element To View fails.
	${scrollheight}=	Execute Javascript	return document.body.scrollHeight
	${footerheight}=	Execute Javascript	return document.getElementById('moodle-footer').getBoundingClientRect().height
	${scrollToHeight}=	Evaluate	${scrollHeight} - (${footerheight} * 1.5)
	Execute Javascript      window.scrollTo(0, ${scrollToHeight})

	Select From List By Value	id=downloadtype_download	json
        Click Download
	
        # Wait until download is complete
	${saneFileName}=	Sanitize File Name	${ShortName}
	Wait Until Keyword Succeeds     10 minutes      1 second       File Should Exist    ${LogFilePrefix}${saneFileName}*.json
	
        @{Files}=       List Files in Directory         ${DownloadDirectory}    logs_${saneFileName}*.json         True
        ${LogFileName}=         Get From List   ${Files}        0
        Wait Until Keyword Succeeds     10 minutes      1 second       File Size Larger Than Zero       ${LogFileName}
        Rename Log File         ${Id}   ${LogFileName}

Download Event Logs
        [Arguments]      ${Id}  ${Date}

        # Seek short name to match log file name later
        ${ShortName}=   Get Short Name  ${Id}

        # Initiate download        
        Open Log Page   ${Id}
	# Check if we are downloading logs for a single date 
	${HasDate}	Run Keyword And Return Status	Should Not Be Equal		${Date}		${None}

	# Check if desired date was found / not even set
	${canGetLogs}=       Run Keyword If	${HasDate}	Select Log Date	${Id}	${Date}	ELSE	Set Variable	True

	# Check has epoch computation worked 
	Run Keyword Unless	${canGetLogs}	Fail	Could not select date ${Date}
	
	# Click if get can get logs
        Run Keyword If	${canGetLogs}	Click Fetch Logs

	# Check returned data and complete download if necessary
	${HasLogInfo}=	Run Keyword If	${canGetLogs}	Are There Grades Or Logs
	Run Keyword If	${HasLogInfo}	Complete Event Log Download	${Id}	${Date}		${ShortName}

Open Grade History Page
        [Arguments]      ${Id}
        Go To   ${GradeHistoryUrlPrefix}${Id}
        Wait Until Element Is Visible   //*[@id="page-footer"]	15 seconds

Select Grade History Date
        [Arguments]      ${DateStr}
        ${Date}         Convert Date    ${DateStr}      datetime
        ${Day}          Convert To String       ${Date.day}
        ${Month}        Convert To String       ${Date.month}
        ${Year}         Convert To String       ${Date.year}

        Click Element    //input[@id="id_datefrom_enabled"]
        Select From List By Value	id=id_datefrom_day      ${Day}
        Select From List By Value	id=id_datefrom_month	${Month}
        Select From List By Value	id=id_datefrom_year	${Year}

        Click Element    //input[@id="id_datetill_enabled"]
        Select From List By Value	id=id_datetill_day      ${Day}
        Select From List By Value	id=id_datetill_month	${Month}
        Select From List By Value	id=id_datetill_year	${Year}

Fetch Grade History
        [Arguments]      ${Date}
        ${HasDate}	Run Keyword And Return Status	Should Not Be Equal		${Date}		${None}
        Run Keyword If  ${HasDate}	Select Grade History Date        ${Date}
        Wait Until Element Is Visible	//*[@id="page-footer"]	15 seconds
        Click Element    //input[@id="id_submitbutton"]
        
Are There Grades Or Logs
        FOR    ${i}    IN RANGE        600
               ${GotGradeHistory} =		Get Element Count	//table
               ${NoGradeHistory} =		Get Element Count	//*[contains(text(),"Ei näytettävää")]
               ${NoGradeHistoryEnglish} =		Get Element Count	//*[contains(text(),"Nothing to display")]
               Exit For Loop If        ${GotGradeHistory} or ${NoGradeHistory} or ${NoGradeHistoryEnglish}
               Sleep   1 second
        END
        [return]        ${GotGradeHistory} > 0



Download Grade History
	Wait Until Element Is Visible	id=downloadtype_download	30 seconds
        ${FinnishTitleCount} =		Get Element Count	//*[contains(text(),"Arvosanahistoria")]
        ${EnglishTitleCount} =		Get Element Count	//*[contains(text(),"Grade history")]
        Run Keyword If  ${FinnishTitleCount} > 0  Download Grade History Finnish
        Run Keyword If  ${EnglishTitleCount} > 0  Download Grade History English
        
Download Grade History Finnish
        Select From List By Value	id=downloadtype_download	json
        Click Download
        Wait Until Keyword Succeeds     10 minutes      1 second       File Should Exist    ${DefaultGradeHistoryFile}
        Wait Until Keyword Succeeds     10 minutes      1 second       File Size Larger Than Zero       ${DefaultGradeHistoryFile}

Download Grade History English

        Select From List By Value	id=downloadtype_download	json
        Click Download

        Wait Until Keyword Succeeds     10 minutes      1 second       File Should Exist    ${DefaultGradeHistoryFileEnglish}
        Wait Until Keyword Succeeds     10 minutes      1 second       File Size Larger Than Zero       ${DefaultGradeHistoryFileEnglish}

Rename Grade History File
       [Arguments]      ${Id}
       ${FinnishTitleCount} =		Get Element Count	//*[contains(text(),"Arvosanahistoria")]
       ${EnglishTitleCount} =		Get Element Count	//*[contains(text(),"Grade history")]

       Run Keyword If  ${FinnishTitleCount} > 0  Move File        ${DefaultGradeHistoryFile}    ${GradeHistoryFilePrefix}${Id}.json
       # Even if file name would be in english, we rename it to Finnish version        
       Run Keyword If  ${EnglishTitleCount} > 0  Move File        ${DefaultGradeHistoryFileEnglish}    ${GradeHistoryFilePrefix}${Id}.json
       

Open My Courses View

         # These are needed in order to get clicks through, apparently css plays tricks to robot.
        Execute Javascript      document.getElementById('mr-nav').classList.remove('clearfix');
        Execute Javascript      document.getElementById('mr-nav').classList.remove('moodle-has-zindex');
        Execute Javascript      document.getElementById('snap-pm-trigger').style.zIndex = 2000;
        # Wait slightly for the changes to be applied by browser
        Sleep   1 second
       
	Click Link  link=Omat kurssini
        # And get all back so our stuff works normally
        Execute Javascript      document.getElementById('mr-nav').classList.add('clearfix');
        Execute Javascript      document.getElementById('mr-nav').classList.add('moodle-has-zindex');
        Execute Javascript      document.getElementById('snap-pm-trigger').style.zIndex = '';
        Sleep   1 second

# Webelement documentation: https://selenium-python.readthedocs.io/api.html

Get Taught Course Url And Name
        [Arguments]     ${Id}

        Go To   ${CourseUrlPrefix}${Id}
        Wait Until Element Is Visible   //*[@id="page-mast"]/h1/a	15 seconds
        

	${Urls}=	Create List
	${Names}=	Create List
	${UrlsAndNames}=	Create List

        ${Name}=		Get Text		xpath=//div[@id="page-mast"]/h1/a
	${Url}=         Set Variable	${CourseUrlPrefix}${Id}

	Append To List	${Urls}		${Url}
       	Append To List	${Names}	${Name}

	Append To List	${UrlsAndNames}		${Urls}		${Names}
        [return]        @{UrlsAndNames}


Get Taught Course Urls And Names
        @{Courses}=		Get Webelements		xpath=//a[@class="coursecard-coursename"]
	${Urls}=	Create List
	${Names}=	Create List
	${UrlsAndNames}=	Create List	

	FOR	${x}	IN	@{Courses}
	       ${Url}=	Set Variable	${x.get_attribute('href')}
	       ${Name}=	Set Variable	${x.get_attribute('innerHTML')}
		Append To List	${Urls}		${Url}
       		Append To List	${Names}	${Name}
	END
	Append To List	${UrlsAndNames}		${Urls}		${Names}
        [return]        @{UrlsAndNames}

    
Get Taught Course Names
        @{Courses}=		Get Webelements		xpath=.//a[@class="coursecard-coursename"]


	FOR	${x}	IN	@{Courses}
	       ${Name}=	Set Variable	${x.get_attribute('innerHTML')}
		Should Not Be Empty		${Name}
		Append To List	${Names}		${Name}
	END
        [return]        @{Names}
