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
Library	  Collections
Suite Teardown	Close Browser

Resource	credentials.robot
Resource        login.robot

*** Variables ***
${CourseId}		${None}
${CourseName}     	${None}

*** Keywords ***

Log in to Power BI
    ${loginAddress}=	Fetch From Right	${PowerBIReportServerBrowseURL}		https://
    ${trustedURL}=	Set Variable	https://${PowerBIUsername}:${PowerBIPassword}@${loginAddress}
    Open Browser   ${trustedURL}       firefox         ff_profile_dir=${FirefoxProfileDirectory}
    ${titleStr}=   Get Title
    
    Wait Until Location Contains  ${PowerBIReportServerBrowseURL}
    Wait Until Page Contains  Oppimisanalytiikka

Create Schedule

    Click Element   //a/*[contains(text(),"New scheduled refresh plan")]
    Wait Until Page Contains	  	 Create scheduled refresh plan

    # Give it a descriptive name
    Input Text 	    id=cachingDescription	 DailyRefresh4AM
    Click Element			 //a[contains(text(),"Edit schedule")]
    Wait Until Page Contains		 Schedule details

    # Make it run on every weekday
    Select Radio Button			 dayTypeSelector	OnDays
    Select Checkbox			 //span[contains(text(),"Sun")]/parent::label/input
    Select Checkbox			 //span[contains(text(),"Mon")]/parent::label/input
    Select Checkbox			 //span[contains(text(),"Tue")]/parent::label/input
    Select Checkbox			 //span[contains(text(),"Wed")]/parent::label/input
    Select Checkbox			 //span[contains(text(),"Thu")]/parent::label/input
    Select Checkbox			 //span[contains(text(),"Fri")]/parent::label/input
    Select Checkbox			 //span[contains(text(),"Sat")]/parent::label/input

    # Set time 
    Input Text 	    //label[contains(text(),"Start time:")]/parent::td/following-sibling::td/div/table/tbody/tr[2]/td/input	04

    # Apply changes
    Click Element   //button[contains(text(),"Apply")]
    Click Element   //button[contains(text(),"Create scheduled refresh plan")]
    # wait until we are done
    Wait Until Page Contains 			     New scheduled refresh plan

Confirm Role Assignment
    # Try couple of times in case we get unknown error.
    ${okButtonDisappeared}=  	  Set Variable	 False

    FOR   ${i}		IN RANGE	0	2
   	  ${okButtonDisappeared}=	Run Keyword And Return Status	Wait Until Element Is Not Visible	//button[contains(text(),"OK")]		timeout=5.0
    	  ${hasErrorOccurred}=		Run Keyword And Return Status	Page Should Contain	An error has occurred.
	  Run Keyword If		${hasErrorOccurred}    Click Element 	    //button[contains(text(),"OK")]
	  Exit For Loop If		${hasErrorOccurred} == False
	  Click Element			//button[contains(text(),"OK")]
    END
    [Return]	${okButtonDisappeared}
	

Add Users To Role
      [Arguments]   ${roleName}         ${userEmailList}
      Go To   ${PowerBIReportServerRowLevelSecurityURL}${CourseId}

      FOR  ${userEmail}   IN  @{userEmailList}
	    Wait Until Page Contains	Add Member	timeout=10.0
	    
            Wait Until Element Is Visible	//span[contains(text(),"Add Member")]/parent::a
	    Wait Until Element Is Not Visible	//div[@id="preloader"]
	    Wait Until Element Is Not Visible	//div[@class="rs-disabled"]
	    Click Element	  		//span[contains(text(),"Add Member")]/parent::a

      	    Wait Until Page Contains			    Select one or more roles to assign to the group or user.
	    Wait Until Element Is Enabled		    //span[contains(text(),"${roleName}")]/parent::td/parent::tr/td/div/label
	    Wait Until Element Is Visible		    //span[contains(text(),"${roleName}")]/parent::td/parent::tr/td/div/label
	    # Select role checkbox
      	    Click Element             //span[contains(text(),"${roleName}")]/parent::td/parent::tr/td/div/label

            Input Text   //input[@id="username"]	${userEmail}
	    Click Element				//button[contains(text(),"OK")]
	    ${okButtonDisappeared}=			Confirm Role Assignment
	    
	    Run Keyword If	${okButtonDisappeared} == False		Click Element	//button[contains(text(),"Cancel")]
	 
      END

Share Report With Users
      [Arguments]   ${userEmailList}
      Go To	${PowerBIReportServerSecurityURL}${CourseId}
      Wait Until Page Contains	BUILTIN\\Administrators
      Sleep	1 second
      # Enable security customization if needed 
      ${needCustomizing}=	Run Keyword And Return Status	Element Should Be Visible	//span[contains(text(),"Customize security")]//parent::a

      Log to console	Customization needed ${needCustomizing}
      Run Keyword If	${needCustomizing}	Click Element	     	    	//span[contains(text(),"Customize security")]//parent::a
      Run Keyword If	${needCustomizing}	Wait Until Element Is Visible   //button[contains(text(),"OK")]
      Run Keyword If	${needCustomizing}	Click Element		    	//button[contains(text(),"OK")]
      

      Sleep	2 seconds
      
      # Process all users
      FOR  ${userEmail}   IN  @{userEmailList}

      	    Wait Until Element Is Visible	//fieldset[@class="rs-disabled-fieldset"]//input[@placeholder="Search..."]	timeout=7 seconds
      	    Wait Until Element Is Enabled	//fieldset[@class="rs-disabled-fieldset"]//input[@placeholder="Search..."]	timeout=7 seconds
	    Input Text    //fieldset[@class="rs-disabled-fieldset"]//input[@placeholder="Search..."]	${userEmail}
	    
	    Sleep 				1 second
	    ${permissionExists}=	Run Keyword And Return Status 	Page Should Not Contain			No results match your search criteria. Please refine your search.
	    Continue For Loop If	${permissionExists}

	    Click Element	//span[contains(text(),"Add group or user")]
	    Wait Until Page Contains	Report Builder
	    Wait Until Page Contains 	Cancel
	    
	    Click Element	//span[contains(text(),"Browser")]/parent::td/preceding-sibling::td/div/label/input
	    Input Text		//input[@id="username"]		${userEmail}
	    
	    Wait Until Element Is Enabled	//button[contains(text(),"OK")]
	    Click Element	  		//button[contains(text(),"OK")]
	    Wait Until Page Contains 		Add group or user

      END      
      

Configure Dataset Credentials
   Go To         ${PowerBIReportServerDataSourcesURL}${CourseId}
   Wait Until Page Contains	 Manage ${CourseId}	timeout=15 seconds

   ${NumAuthenticationSelects}=  Get Element Count   xpath://select[contains(@id, 'auth-type-select-')]

   FOR	${x}    IN RANGE	 ${NumAuthenticationSelects}
   	${index}=  Evaluate	 ${x} + 1
   	Select From List By Value	//select[contains(@id, "auth-type-select-${x}")]		UsernamePassword
	Input Text  //input[@id="basic-username-input-${x}"]   ${DatasetWebUser}
	Input Password  //input[@id="basic-password-input-${x}"]   ${DatasetWebPassword}
   END

   # Save all
   Wait Until Element Is Visible	id=datasource-update-button	timeout=10 seconds
   Click Element	id=datasource-update-button

Configure Scheduled Refresh

    Go To 	    ${PowerBIReportServerScheduleURL}${CourseId}

    Wait Until Element Is Visible	//span[contains(text(),"New scheduled refresh plan")]/parent::a
    Wait Until Element Is Enabled	//span[contains(text(),"New scheduled refresh plan")]/parent::a
    
    ${HasSchedule}=	Run Keyword And Return Status	Wait Until Page Contains	DailyRefresh4AM		timeout=7 seconds

    Run Keyword If	${HasSchedule} == 0     Create Schedule

Remove All Users 
      Sleep	 2 seconds
      Wait Until Element Is Enabled	//input[@aria-label="Select all"]
      Select Checkbox			//input[@aria-label="Select all"]

      Wait Until Element Is Enabled  	//span[contains(text(),"Delete")]/parent::a
      Click Element	  		//span[contains(text(),"Delete")]/parent::a
      Wait Until Page Contains		Confirm
      Click Element			//button[contains(text(),"OK")]
      
Remove All Access
      Go To   ${PowerBIReportServerRowLevelSecurityURL}${CourseId}

      Wait Until Page Contains			Add Member
      Wait until Page Contains Element       	//input[@aria-label="Select all"]
      
      ${shouldRemoveAllFirst}=	Run Keyword And Return Status	Element Should Be Enabled	//input[@aria-label="Select all"]
      Run Keyword If		${shouldRemoveAllFirst}		Remove All Users
      Wait Until Page Contains	Add Member
      Sleep	 2 seconds
      
Get Student Email Addresses

    ${result}	 ${stdout}=	Run And Return RC And Output	${GetEmailCmd} --students --courseid ${CourseId} --principal-user-names
    @{addresses}=	Split String	${stdout}
    [return]	${addresses}    

Get Teacher Email Addresses

    ${result}	 ${stdout}=	Run And Return RC And Output	${GetEmailCmd} --teachers --courseid ${CourseId} --principal-user-names
    @{addresses}=	Split String	${stdout}
    [return]	${addresses}    

Get Teacher Account Usernames

    ${result}	 ${stdout}=	Run And Return RC And Output	${GetEmailCmd} --teachers --courseid ${CourseId} --account-user-names
    @{addresses}=	Split String	${stdout}
    [return]	${addresses}    

Get Student Account Usernames

    ${result}	 ${stdout}=	Run And Return RC And Output	${GetEmailCmd} --students --courseid ${CourseId} --account-user-names
    @{addresses}=	Split String	${stdout}
    [return]	${addresses}    


Get Active Courses

    ${result}	 ${stdout}=	Run And Return RC And Output	${GetCourseListCmd} --with-pipe 2>/dev/null
    @{courses}=	Split To Lines	${stdout}	
    [return]	${courses}    

Get Active Course
    [Arguments]		${Id}
    ${result}	 ${stdout}=	Run And Return RC And Output	${GetCourseNameCmd} ${Id} 2>/dev/null
    ${tmp}=	Catenate	SEPARATOR=	${Id}	|	${stdout}    
    @{out}    Create List	${tmp}
    [return]	${out}

Embed PowerBI Report 
    [Arguments]     ${Id}   ${Name}
    ${ReportURL}=   Set Variable	    	${PowerBIReportServerViewURL}/${CourseId}?rs:embed=true
    ${content}=     Catenate    <html>\n
    ...     <head>\n\t<title>${Name}</title>\n</head>\n
    ...     <body>\n
    ...     \t<iframe src="${ReportURL}" allowfullscreen="true" width="1280" height="720" frameborder="0"></iframe>\n
    ...     </body>\n
    ...     </html>\n
    Create File     ${PublishPath}/${Id}.html   ${content}

*** Test Cases ***
Login
    [Tags]	Init
    Log in to Power BI

Check That Visualization Exists
    [Tags]	Init
    Go To         ${PowerBIReportServerDataSourcesURL}${CourseId}

    FOR    ${i}    IN RANGE        10
        ${published}=	Run Keyword And Return Status	Page Should Contain		Manage ${CourseId}
    	${missing}=	Run Keyword And Return Status 	Page Should Contain		does not exist
        Exit For Loop If        ${published} or ${missing}

	Sleep   1 second
    END
    Run Keyword If     ${missing} == True or ${published} == False	Fail    Visualization for ${CourseId} does not exist.


Get Courses To Be Processed
    [Tags]	Init
    # If course is specified, use it - otherwise get active list 
    @{Courses}=		Run Keyword If	"${CourseId}" == "${None}"	Get Active Courses	ELSE	Get Active Course	${CourseId}
    Set Global Variable		${Courses}

Set Roles and Access Permissions
    [Tags]	Permissions
    FOR	${Course}	IN	@{Courses}
    	@{courseSplit}=		Split String	${Course}	|
    	${CourseId}=		Get From List	${courseSplit}	0
    	${CourseName}=	Get From List	${courseSplit}	1
    	Set Global Variable	${CourseId}
    	Set Global Variable	${CourseName}
    	Configure Dataset Credentials
        Configure Scheduled Refresh
#    	@{studentEmails}=   Get Student Email Addresses
	@{studentEmails}=   Create List	      STUDENT_GROUP_NAME
    	@{teacherEmails}=   Get Teacher Email Addresses

	# These are needed for actual viewing permissions
#   	@{studentUsernames}=   Get Student Account Usernames
   	@{studentUsernames}=   Create List	STUDENT_GROUP_NAME
	@{teacherUsernames}=   Get Teacher Account Usernames
	
    	${combinedUsernames}=	Combine Lists	${teacherUsernames}	${studentUsernames}
    	Remove All Access
	Add Users To Role  Students         ${studentEmails}
    	Add Users To Role  Teachers         ${teacherEmails}
	Share Report With Users		    ${teacherUsernames}
    END
    
Publish Course Analytics
    [Tags]	Publish
    FOR	${Course}	IN	@{Courses}
      	@{courseSplit}=		Split String	${Course}	|
    	${CourseId}=		Get From List	${courseSplit}	0
    	${CourseName}=	Get From List	${courseSplit}	1
    	Set Global Variable	${CourseId}
    	Set Global Variable	${CourseName}
    	Embed Power BI Report   ${CourseId}	${CourseName}
    END
