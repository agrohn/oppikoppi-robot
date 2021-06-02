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

terminateAll() {


    curl -X POST -H "Authorization: Basic ${auth_oppikoppi}" \
         -H "Content-Type: application/json; charset=utf-8" \
         http://${server}/api/v2/batchdelete/terminate/all   

}


runquery() {

    type=$1
    queryvar=query_${type}
    #echo "data to send is: ${!queryvar}"
    curl -H "Authorization: Basic ${auth_oppikoppi}" \
         -H "Content-Type: application/json; charset=utf-8" \
         --data "${!queryvar}" \
         http://${server}/api/v2/batchdelete/initialise
   
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
courseid=""
course_url_list=""
show_finished_jobs=""
show_unfinished_jobs=""
query_delete=""
grade_delete=""
date_delete=""
terminate=""

if [ $# -eq 0 ]; then
    echo "Usage: "
    echo " --server <ip/name>                   Learning locker ip address or domain name  ."
    echo " --courseid <courseid>                      Moodle course id. "
    echo " --show-finished			Show finished jobs"
    echo " --show-unfinished			Show unfinished jobs"
    echo " --grades				Delete ALL grade entries for ALL courses"
    echo " --date				Delete all entries for given date YYYY-MM-DD"
    exit 0
fi

while [ $# -ge 1 ];do

    case $1 in
        --server)
            server="$2";
            shift
            shift
            ;;
        --courseid)
            courseid="$2";
            shift
            shift
	    ;;
	--date)
            date_delete="$2";
            shift
            shift
	    ;;
	--grades)
	    grade_delete=1;
	    shift
            ;;
	--terminate-all)
	    terminateAll
	    exit 0
	    shift
	    ;;
        --show-finished)
            show_finished_jobs=1;
            shift
	    ;;
        --show-unfinished)
            show_unfinished_jobs=1;
            shift
            ;;
        *)
            echo "Unknown argument: '$1', exiting."
            exit 1
            ;;
    esac

done
query_match=""

if [ "${courseid}" == "" ] && [ "${grade_delete}" == "" ] && [ "${show_finished_jobs}" == "" ] && [ "${show_unfinished_jobs}" == "" ] && [ "${date_delete}" == "" ]; then
    echo "You need course or grades or date.";
    exit 1
fi

if [ "${courseid}" != "" ]; then
    
    query_match='"statement.context.contextActivities.grouping.0.id" : "'${moodle_course_url_prefix}${courseid}'"'
elif [ "${grade_delete}" != "" ]; then
    
    query_match='"statement.object.id" : "http://www.karelia.fi/grade"'
elif [ "${date_delete}" != "" ]; then
    query_match='"$and": [ { "statement.timestamp": { "$gte": "'${date_delete}'T00:00Z"}}, { "statement.timestamp": { "$lte": "'${date_delete}'T23:59Z"}}]' 
fi

delete='{
  "filter": {
    '${query_match}'
  }
}'


jobs='{"done":true}'

if [ "${show_unfinished_jobs}" != "" ]; then
    jobs='{"$or":[{"processing":true},{"done":false}]}'
fi


sortq='{"createdAt": -1}'
first=1000
query_showjobs_filter=$(rawurlencode ${jobs})
query_showjobs_sort=$(rawurlencode ${sortq})
query_delete=$delete

if [ "${show_unfinished_jobs}" != "" ] || [ "${show_finished_jobs}" != "" ]; then


    curl -H "Authorization: Basic ${auth_oppikoppi}" \
         'http://'${server}'/api/connection/batchdelete?filter='${query_showjobs_filter}'&first=1000'|sed 's/,/\n/g'|grep -E '.*(processing|done|total|createdAt|filter).*'|awk 'BEGIN { print "processing\ndone\ntotal\ncourseid\ncreatedAt"; } {print $0;}'|sed -r 's/.*"(processing|done|total|createdAt|filter)"://g'|paste - - - - -|column -t

else
    echo $delete
    runquery delete
fi


