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

# rawurlencode/rawurldecode source: https://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done

  echo "${encoded}"   #+or echo the result (EASIER)... or both... :p
}

rawurldecode() {

  # This is perhaps a risky gambit, but since all escape characters must be
  # encoded, we can replace %NN with \xNN and pass the lot to printf -b, which
  # will decode hex for us

  printf -v REPLY '%b' "${1//%/\\x}" # You can either set a return variable (FASTER)

  return "${REPLY}"  #+or echo the result (EASIER)... or both... :p
}


runquery() {
    type=$1
    filename=${type}_file
    queryvar=query_${type}
    curl -H "Authorization: Basic ${auth_oppikoppi}" \
	 http://${server}/api/statements/aggregate?pipeline=${!queryvar}|/path/to/xapi_converter/build/common/json_parser 0._id.course.0.0

}

moodle_course_url_prefix="https://moodle-server/course/view.php?id="

convert_ids_into_courseurls()
{

    ids=`echo $1|sed 's/,/\\n/g'|awk "{ print\"${moodle_course_url_prefix}\"\\$0;}"`
    query_string=""
    for i in $ids; do
        query_string+="\"$i\","
    done
    echo ${query_string::-1}   
}


auth_oppikoppi=""
server=
prefix=""
assignments_file=""
submissions_file=""
students_file=""
activity_file=""
force=0
id=""


course_id=""
if [ $# -ge 1 ];then
    course_id=$1
fi


courses='
{ 
  "$match":  { "statement.context.contextActivities.grouping.0.id" : "https://moodle-server/course/view.php?id='${course_id}'"}
}, 
{ 
  "$project": { 
  	      "_id": 0,
  	      "statement.context.contextActivities.grouping": 1
  } 
}, 
{
   "$group": { 
   	     "_id": { 
		    "course": "$statement.context.contextActivities.grouping.definition.description.en-GB"
	     }
   }
}'
query_courses=$(rawurlencode "[$courses]")

if [ "${course_id}" != "" ]; then
    runquery courses
else
    echo You need to provide course id.
    exit 2
fi


