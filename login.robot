
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

# IMPORTANT: This script should be included after credentials.robot

*** Keywords ***
# Logs user into browser session according to defined credentials
Log in to Moodle


        Open Browser	${MoodleURL}       firefox         ff_profile_dir=${FirefoxProfileDirectory}
	Title Should Be   Your-Moodle
	Click Element	link=Log in
        Wait Until Element Is Visible   link=Haka-kirjautuminen		15 seconds
        Click Element	partial link=Haka-kirjautuminen

        Select From List By Label   id=userIdPSelection   Your University of Applied Sciences
        Click Button    name=Select
        Input Text		id=username	${Username}
	Input Password	id=password	${Password}
        Click Button   name=_eventId_proceed
	Wait Until Element Is Enabled  link=Omat kurssini	15 seconds


Log in to Moodle Local

        Open Browser	${MoodleURL}       firefox         ff_profile_dir=${FirefoxProfileDirectory}
	Title Should Be   Your-Moodle
	Click Element	link=Log in
        Wait Until Element Is Visible   link=Moodle-tunnus	15 seconds
        Click Element	partial link=Moodle-tunnus

        Wait Until Element Is Visible   id=username	15 seconds
        Input Text		id=username	${Username}
	Input Password	id=password	${Password}
        Click Button   //input[@class="login-button"]
	Wait Until Element Is Enabled  link=Omat kurssini	15 seconds


