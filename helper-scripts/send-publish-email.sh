#!/bin/bash
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

courseID=$1

function GetTeacherEmails()
{
    # combine newline-separated emails into a single comma-separated line
    tmp=$(/path/to/oppikoppi-robot/helper-scripts/get-emails.sh --courseid ${courseID} --teachers|paste -sd',')
    echo ${tmp}
}

function GetCourseName()
{
    name=`/path/to/oppikoppi-robot/helper-scripts/ll-coursename.sh ${courseID}`
    # Check that we have list of teachers to send our message
    echo $name
}

function CreateMessage()
{
    embedURL="https://visualisoinnin-url-${courseID}"
    msg="muokattu viesti tänne"
    echo -e $msg
}
teacherEmails=`GetTeacherEmails`
if [ "$teacherEmails" != "" ]; then
    courseName=`GetCourseName`
    message=`CreateMessage`
    echo -e "$message" | msmtp -C /path/to/.msmtprc ${teacherEmails}
    logger Sending message for ${courseID} to ${teacherEmails} SUCCESS
else
    
    logger Sending email for ${courseID}, no teacher list FAIL
fi
