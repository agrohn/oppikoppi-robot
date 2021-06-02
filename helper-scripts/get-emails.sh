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

# Script for retrieving email addresses and principal usernames of users
# within specific role on a course.
# Depends on credentials.robot for proper ldap user account.
#
function GetUserinfoByEmail()
{
    
    ldapUser=$(grep LdapUser ./credentials.robot|sed -r 's/\$\{LdapUser\}\s+//')
    ldapPass=$(grep LdapPassword ./credentials.robot|sed -r 's/\$\{LdapPassword\}\s+//')
    ldapServer=$(grep LdapServer ./credentials.robot|sed -r 's/\$\{LdapServer\}\s+//')
    ldapSearchDomain=$(grep LdapSearchDomain ./credentials.robot|sed -r 's/\$\{LdapSearchDomain\}\s+//')

    email=$1
    catch=$2
    if [ "${catch}" == "" ]; then
	catch=userPrincipalName
    fi
    # This ought to get rid of disabled accounts 
    uidstr=$(ldapsearch -x -h ${ldapServer} -D "${ldapUser}" -w "${ldapPass}" -b "${ldapSearchDomain}" "(&(mail=${email})(!(userAccountControl=514))(!(userAccountControl=66050)))" ${catch}|grep ^${catch})

    userNotFound=$?
    if [ ${userNotFound} -eq 1 ]; then
	return 1
    else
	tmp=$(echo ${uidstr}|awk -F: '{print $2;}')
	# get rid of whitespace
	echo ${tmp}
	return 0;    
    fi
}



datadir=/path/to/powerbi-data
seek=''
courseid=''

while [ $# -ge 1 ];do

    case $1 in
	--courseid)
	    courseid=$2
	    shift
	    shift
	    ;;
        --students)
	    needle="Student"
	    shift
	    ;;
        --teachers)
	    needle="Teacher"
	    shift
	    ;;
	--non-editing-teachers)
	    needle="Non-Editing Teacher"
	    shift
	    ;;
	--principal-user-names)
	    principalUserNames="ldap"
	    shift
	    ;;
	--account-user-names)
	    accountUserNames="ldap"
	    shift
	    ;;
	--account-states)
	    accountStates="ldap"
	    shift
	    ;;

	*)
	    echo "Unknown argument $1, exiting"
	    exit 2
	    ;;
    esac
done

if [ "${courseid}" == "" ]; then
    echo "You need courseid."
    exit 1
fi

if [ "${needle}" == "" ]; then
    echo "You need to specify one of --students, --teachers --non-editing-teachers"
    echo "Principal usernames can be retrieved with --principal-user-names"
    echo "Account usernames can be retrieved with --account-user-names"
    exit 1
fi


for i in $(cat ${datadir}/${courseid}_students.json| \
    sed -e 's/\},{/\n/g'| \
    sed 's/.*mailto:\(.*\)".*"Roles":\(.*\).*/\1 \2/'| \
    grep -E "\[.*\"${needle}\".*\]"|\
    sed -r 's/(.*)[[:space:]]\[.*\]/\1/'); do
    if [ "${principalUserNames}" == "ldap" ]; then
	GetUserinfoByEmail $i userPrincipalName
    elif [ "${accountUserNames}" == "ldap" ]; then
	GetUserinfoByEmail $i sAMAccountName
    elif [ "${accountStates}" == "ldap" ]; then
	GetUserinfoByEmail $i userAccountControl
    else
	echo $i
    fi
done

