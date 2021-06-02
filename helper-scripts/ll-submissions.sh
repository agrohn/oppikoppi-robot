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
    if [ "${!filename}" != "" ]; then
        if [ -e ${!filename} ] && [ $force -eq 0 ]; then
            echo "${!filename} exists, --force required for overwriting."
            exit 1
        fi
        curl --fail -H "Authorization: Basic ${auth_oppikoppi}" \
             http://${server}/api/statements/aggregate?pipeline=${!queryvar} > ${!filename}
	# exit with failure when a single runquery fails
	if [ $? -ne 0 ]; then
	    exit 1;
	fi
    fi
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
submissions_by_date_file=""
students_file=""
activity_file=""
sessions_file=""
scores_file=""
force=0
id=""
course_url_list=""

if [ $# -eq 0 ]; then
    echo "Usage: "
    echo " --server <ip/name>                   Learning locker ip address or domain name  ."
    echo " --id <courseid>                      Moodle course id. "
    echo " --allow-all-courses                  Allows queries to run without course id list. "
    echo " --force                              Overwrite existing files."
    echo " --assignments <filename>             Retrieve assignments json."
    echo " --submissions <filename>             Retrieve submissions json with sum."
    echo " --submissions-by-date <filename>     Retrieve submissions json with date."
    echo " --students <filename>                Retrieve students json."
    echo " --usercache <filename>               Retrieve usercache json."
    echo " --scores <filename>                  Retrieve scores json."
    echo " --activity <filename>                Retrieve activity json with sum of events by dates."
    echo " --firstactivity <filename>                Retrieve activity json for first event dates."
    echo " --sessions <filename>                Retrieve studying sessions json."
    echo " --credits <filename>                 Retrieve credit marks (passed and failed) json."
fi

while [ $# -ge 1 ];do

    case $1 in
        --assignments)
            assignments_file="$2";
            shift
            shift
            ;;
        --students)
            students_file="$2";
            shift
            shift
            ;;
        --usercache)
            usercache_file="$2";
            shift
            shift
            ;;
        --scores)
            scores_file="$2";
            shift
            shift
            ;;
        --activity)
            activity_file="$2";
            shift
            shift
            ;;
        --sessions)
            sessions_file="$2";
            shift;
            shift;
            ;;
        --submissions)
            submissions_file="$2";
            shift
            shift
            ;;
        --submissions-by-date)
            submissions_by_date_file="$2";
            shift
            shift
            ;;
	--firstactivity)
            firstactivity_file="$2";
            shift
            shift
            ;;

        --credits)
            credits_file="$2";
            shift
            shift
            ;;
        --prefix)
            prefix="$2";
            shift
            shift
            ;;
        --server)
            server="$2";
            shift
            shift
            ;;
        --id)
            id="$2";
            shift
            shift
            ;;
        --allow-all-courses)
            allow_all_courses=1;
            shift
            ;;
        --force)
            force=1;
            shift
            ;;
        *)
            echo "Unknown argument: '$1', exiting."
            exit 1
            ;;
    esac

done
course_match=""

if [ "$id" != "" ]; then
    course_url_list=`convert_ids_into_courseurls $id`
    course_match='"statement.context.contextActivities.grouping.0.id" : { "$in": [ '${course_url_list}'] }'
fi

scores='
{
        "$match": {
                  "$and": [
                          { "statement.verb.id": "http://adlnet.gov/expapi/verbs/scored" },
                          {'${course_match}'}
                  ]
        }
},
{
        "$project": {
                   "_id":0,
                   "Pisteet": "$statement.result.score.raw",
                   "Timestamp": "$statement.timestamp",
                   "Opiskelija": "$statement.actor.name",
                   "Email": "$statement.actor.mbox",
                   "Tehtava": "$statement.object.definition.name.en-GB",
                   "coursename":{ "$arrayElemAt": [ "$statement.context.contextActivities.grouping.definition.description.en-GB",0]}
        }
}'


# These are primarily for task difficulty review depending on user limit
submissions='
{
        "$match": {
                  "$and": [
                          { "statement.verb.id" : "http://activitystrea.ms/schema/1.0/submit" },
                          { '${course_match}' }
                          ]
        }
},
{
        "$group": {
                  "_id": {
                         "task": "$statement.object.definition.name.en-GB",
                         "student": "$statement.actor.name",
                         "email": "$statement.actor.mbox"
                  },
                  "hits": { "$sum":1}
        }
}'



# This lists submissions by date for councellor review
submissions_by_date='
{
        "$match": {
                  "$and": [
                          { "statement.verb.id" : "http://activitystrea.ms/schema/1.0/submit" },
                          { '${course_match}' }
                          ]
        }
},
{
        "$group": {
                  "_id": {
                         "task": "$statement.object.definition.name.en-GB",
                         "student": "$statement.actor.name",
                         "email": "$statement.actor.mbox",
                         "date": "$statement.timestamp"
                  },
                  "hits": { "$sum":1}
        }
}'

# Lists marked credits and grades (also failed and incomplete) 
credits='
{
        "$match": {
                  "$and": [
                          { "statement.verb.id" : "http://activitystrea.ms/schema/1.0/receive" },
                          { "statement.object.id" : "http://www.karelia.fi/grade" }
                          ]
        }
},
{
        "$project": {
                  "_id": 0,
                  "courseid": { "$substr": [{ "$arrayElemAt": [ "$statement.context.contextActivities.grouping.id",0]},33,-1]},
                  "grade": "$statement.result.extensions.http://www&46;tincanapi&46;co&46;uk/extensions/result/classification",
                  "passed": "$statement.result.success",
                  "student": "$statement.actor.mbox"
        }
},
{
        "$group": {
                  "_id": "$student",
                  "courses": {
                             "$push": {
                                      "courseid": "$courseid",
                                      "grade": "$grade",
                                      "passed": "$passed"
                             }
                  }
        }
}'

usercache='{
        "$match":  {
                  "$and": [
                          { "statement.verb.id": "http://activitystrea.ms/schema/1.0/join" },
                          { '${course_match}' }
                          ]
        }
},
{
        "$group": {
                 "_id": {
                        "name": "$statement.actor.name",
                        "email": "$statement.actor.mbox",
                        "userid": "$statement.context.extensions.https://moodle-server/user/profile&46;php?id=",
                        "roles": []
                  }
        }
},
{
        "$project": {
              "_id": 0,
              "name": "$_id.name",
              "email": "$_id.email",
              "id": "$_id.userid",
              "roles": "$_id.roles"
        }
}'

students='
{
        "$match":  {
                  "$and": [
                          { "statement.verb.id": "http://activitystrea.ms/schema/1.0/assign" },
                          { '${course_match}' },
			  { "statement.context.extensions.http://id&46;tincanapi&46;com/extension/target.mbox": { "$ne": "mailto:user.unknown@unknownaddress.net"}},
			  { "statement.context.extensions.http://id&46;tincanapi&46;com/extension/target.name": { "$ne": "-"}}
                          ]
        }
},
{
        "$group": {
                 "_id": {
                        "Opiskelija": "$statement.context.extensions.http://id&46;tincanapi&46;com/extension/target.name",
                        "Email": "$statement.context.extensions.http://id&46;tincanapi&46;com/extension/target.mbox",
                        "Role": "$statement.object.definition.name.en-GB"
                  },
                  "assigned": { "$sum": { "$cond": ["$statement.context.extensions.http://id&46;tincanapi&46;com/extension/starting-point", 1, 0 ] }},
                  "unassigned": { "$sum": { "$cond": ["$statement.context.extensions.http://id&46;tincanapi&46;com/extension/ending-point", 1, 0 ] }}
        }
},
{
      "$group": {
                "_id": {
                       "Opiskelija": "$_id.Opiskelija",
                       "Email": "$_id.Email"
                },
                "Roles": {
                       "$push": {
                                "$cond": [ { "$gt": [ "$assigned", "$unassigned" ] }, "$_id.Role", "$null" ]
                        }
                }
      }
}'
# this requires authorize events for all assignments
assignments='
{
        "$match":  {
                  "$and": [
                          { "statement.object.definition.type" : "http://id.tincanapi.com/activitytype/school-assignment" }, 
                          {'${course_match}'}
                  ]
        }
},
{
        "$group": {
                 "_id": {
                        "task": "$statement.object.definition.name.en-GB",
                        "id":"$statement.object.id",
                        "coursename":{ "$arrayElemAt": [ "$statement.context.contextActivities.grouping.definition.description.en-GB",0]}
                 }
        }
}'



activity='
{
        "$match":  {'${course_match}'}
},
{
        "$project": {
                    "_id":0,
                    "timestamp": { "$substr": ["$statement.timestamp",0,10]},
                    "Opiskelija": "$statement.actor.name",
                    "email": "$statement.actor.mbox",
                    "verb_id": "$statement.verb.id",
                    "verb_name": "$statement.verb.display.en-GB",
                    "Tehtava":"$statement.object.definition.name.en-GB",
                    "Tyyppi": "$statement.object.definition.type",
                    "tunniste": "$statement.object.id",
                    "coursename":{ "$arrayElemAt": [ "$statement.context.contextActivities.grouping.definition.description.en-GB",0]}
        }
},
{
        "$group": {
                  "_id": {
                          "opiskelija": "$Opiskelija",
                          "email": "$email",
                          "verb_id":"$verb_id",
                          "verb_name":"$verb_name",
                          "tehtava":"$Tehtava",
                          "aika":"$timestamp"
                  },
                  "count": { "$sum":1}
        }
}'


firstactivity='
{
        "$match":  {'${course_match}'}
},
{
        "$project": {
                    "_id":0,
                    "timestamp": "$statement.timestamp",
                    "Opiskelija": "$statement.actor.name",
                    "email": "$statement.actor.mbox",
                    "verb_id": "$statement.verb.id",
                    "verb_name": "$statement.verb.display.en-GB",
                    "Tehtava":"$statement.object.definition.name.en-GB",
                    "tunniste": "$statement.object.id"
        }
},
{
        "$group": {
                  "_id": {
                          "opiskelija": "$Opiskelija",
                          "email": "$email",
                          "verb_id":"$verb_id",
                          "verb_name":"$verb_name",
                          "tehtava":"$Tehtava"
                  },
                  "aika": { "$min": "$timestamp" }
        }
}'


sessions='
{
        "$match":  {'${course_match}'}
},
{
        "$project": {
                    "_id":0,
                    "timestamp": { "$substr": ["$statement.timestamp",0,10]},
                    "thour": { "$substr": ["$statement.timestamp", 11, 2 ] },
                    "tmin": { "$convert": { "input": { "$substr": ["$statement.timestamp", 14, 2 ] },"to": "int"}},
                    "Opiskelija": "$statement.actor.name",
                    "email": "$statement.actor.mbox",
                    "Tehtava":"$statement.object.definition.name.en-GB",
                    "Tyyppi": "$statement.object.definition.type",
                    "tunniste": "$statement.object.id",
                    "coursename":{ "$arrayElemAt": [ "$statement.context.contextActivities.grouping.definition.description.en-GB",0]}
        }
},
{
        "$project": {
                    "timestamp" : "$timestamp",
                    "thour": "$thour",
                    "Opiskelija": "$Opiskelija",
                    "email" : "$email",
                    "Tehtava" : "$Tehtava",
                    "Tyyppi" : "$Tyyppi",
                    "tunniste": "$tunniste",
                    "coursename":"$coursename",
                    "time": { "$concat": ["$thour", ".", { "$switch" : {
                              "branches" : [
                                         {
                                                "case": { "$lt" : [ "$tmin", 15] },
                                                "then": "0"
                                         },
                                         {
                                                "case": { "$lt" : [ "$tmin", 30] },
                                                "then": "25"
                                         },
                                         {
                                                "case": { "$lt" : [ "$tmin", 45] },
                                                "then": "5"
                                         },
                                         {
                                                "case": { "$gte" : [ "$tmin", 45] },
                                                "then": "75"
                                         }
                              ]


                            }
                    }]}
          }
},
{
        "$group": {
                  "_id": {
                  "Opiskelija": "$Opiskelija",
                  "email": "$email",
                  "coursename": "$coursename",
                  "timestamp": "$timestamp",
                  "Tehtava":"$Tehtava"
                  },
                  "hours": { "$addToSet" : "$time" }
        }
},
{
        "$unwind": { "path": "$hours" }

},
{
        "$sort": { "hours" : 1}
},
{
        "$group": {
            "_id": "$_id",
           "hours": { "$push" : { "$convert": { "input": "$hours", "to": "double"}} }
        }
},
{
        "$unwind": { "path": "$hours", "includeArrayIndex": "arrayindex" }
},
{
        "$group": {
            "_id": "$_id",
           "hours": { "$push" : { "startTime":"$hours", "arrayindex" : "$arrayindex"}},
           "hoursHelp": { "$push" : "$hours"}
        }
},
{
        "$addFields":
        {
                "startPoints":
                {
                        "$map":
                        {
                                "input": "$hours",
                                "as": "h",
                                "in":
                                {
                                  "$subtract" : [
                                              {"$arrayElemAt": [ "$hoursHelp", "$$h.arrayindex"]},
                                              {"$arrayElemAt": [ "$hoursHelp", { "$max": [{ "$subtract": ["$$h.arrayindex",1] },0 ]}]}
                                   ]
                                }
                        }
                }
        }
},
{
        "$unwind": "$startPoints"
},
{
        "$group": {
            "_id": {
                   "Opiskelija": "$_id.Opiskelija",
                   "coursename": "$_id.coursename",
                   "email": "$_id.email",
                   "timestamp": "$_id.timestamp",
                   "hours": "$hours",
                   "hoursHelp": "$hoursHelp",
                   "Tehtava":"$_id.Tehtava"

           },
           "startPoints":
           {
             "$push":
             {
                "$cond":
                [
                  { "$or":
                    [
                      { "$gt": ["$startPoints",0.25]},
                      { "$eq": ["$startPoints", 0  ]}
                    ]
                  },
                  true,
                  false
                ]
           }
        }
     }
},
{
        "$project":
        {
            "actualStartTimes":  {
                "$map": {
                                "input": "$_id.hours",
                                "as": "h",
                                "in":
                                {
                                  "$cond":
                                  [
                                       {"$eq": [{ "$arrayElemAt": [ "$startPoints", "$$h.arrayindex" ] }, true]},
                                       "$$h.startTime",
                                       null
                                  ]
                                }


                        }
                }

        }
},
{
        "$project":
        {
                "actualStartTimes":
                {
                        "$filter":
                        {
                                "input": "$actualStartTimes",
                                "as": "st",
                                "cond": { "$ne": ["$$st", null]}
                        }
                }
        }
},
{
        "$unwind": {
                   "path": "$actualStartTimes",
                   "includeArrayIndex": "arrayindex"
        }
},
{
        "$group":
        {
                "_id": "$_id",
                "actualStartTimes":
                {
                        "$push": {
                             "time": "$actualStartTimes",
                             "index": "$arrayindex"
                        }
                }
        }
},
{
        "$project":
        {
                "actualStartTimes": "$actualStartTimes",
                "sessions":
                {
                        "$map": {
                                "input": "$actualStartTimes",
                                "as": "st",
                                "in":
                                {
                                   "$switch":
                                   {
                                        "branches" :
                                        [
                                               {
                                                        "case":
                                                        {
                                                                "$eq":
                                                                   [
                                                                          {"$arrayElemAt": [ "$actualStartTimes", 0 ]},
                                                                          {"$arrayElemAt": [ "$actualStartTimes", -1]}
                                                                   ]
                                                        },
                                                        "then":
                                                        {
                                                               "start": "$$st.time",
                                                               "end": { "$add": [{ "$multiply": [ { "$size": "$_id.hoursHelp" }, 0.25 ]}, "$$st.time"]}
                                                        }
                                               },
                                               {
                                                        "case":
                                                        {
                                                               "$eq": [ "$$st.index", { "$subtract": [{ "$size" : "$actualStartTimes"},1]}]
                                                        },
                                                        "then":
                                                        {
                                                                "start": "$$st.time",
                                                                "end": {
                                                                       "$add":
                                                                       [
                                                                               {
                                                                               "$multiply":
                                                                                 [
                                                                                        {
                                                                                        "$size":
                                                                                                 {
                                                                                                   "$filter":
                                                                                                   {
                                                                                                              "input": "$_id.hoursHelp",
                                                                                                              "as": "tmptime",
                                                                                                              "cond": { "$gte": ["$$tmptime", {"$toDouble": "$$st.time"}] }
                                                                                                   }
                                                                                                 }
                                                                                        },
                                                                                        0.25
                                                                                 ]
                                                                               },
                                                                               "$$st.time"
                                                                       ]
                                                                 }
                                                        }
                                               }

                                        ],
                                        "default":
                                        {
                                          "start": "$$st.time",
                                           "end": {
                                                   "$add":
                                                   [
                                                           {
                                                                "$multiply":
                                                                [
                                                                        {
                                                                          "$size":
                                                                          {
                                                                                   "$filter":
                                                                                   {
                                                                                     "input": "$_id.hoursHelp",
                                                                                     "as": "tmptime",
                                                                                     "cond":
                                                                                     {
                                                                                             "$and":
                                                                                             [
                                                                                               { "$gte": [ { "$toDouble": "$$tmptime"}, { "$toDouble":"$$st.time"}]},
                                                                                               { "$lt":
                                                                                                 [
                                                                                                   { "$toDouble": "$$tmptime"},
                                                                                                   { "$toDouble": {"$arrayElemAt": [ "$actualStartTimes.time",  {"$add": [ "$$st.index", 1 ]}]}}
                                                                                                 ]
                                                                                               }
                                                                                             ]
                                                                                     }
                                                                                   }
                                                                          }
                                                                        },
                                                                        0.25
                                                                ]
                                                           },
                                                           "$$st.time"
                                                   ]
                                          }



                                        }
                                   }
                                }
                         }
                }
        }
},
{
        "$project":
        {
                "sessions":
                {
                        "$map": 
                        {
                                "input": "$sessions",
                                "as": "s",
                                "in": {
                                      "starthour": { "$trunc": "$$s.start"},
                                      "endhour": { "$trunc": "$$s.end"},
                                      "startmin": { "$multiply": [{ "$subtract": [ "$$s.start", { "$trunc": "$$s.start"}]},60 ]},
                                      "endmin":  { "$multiply": [{ "$subtract": [ "$$s.end", { "$trunc": "$$s.end"}]},60]}
                                }
                        }
                }
        }

},
{
        "$project": 
        {
                   "sessions": 
                   {
                        "$map": 
                        {
                                "input": "$sessions",
                                "as": "s",
                                "in": 
                                {
                                        "starthour": 
                                        { "$cond": 
                                          [
                                                { "$lt": [ "$$s.starthour", 10] }, 
                                                { "$concat": [ "0",{"$toString": "$$s.starthour"}]},
                                                { "$toString": "$$s.starthour"}
                                          ]
                                        },
                                        "startmin": 
                                        { "$cond": 
                                        [
                                                { "$lt": [ "$$s.startmin", 1] }, 
                                                "00",
                                                { "$toString": "$$s.startmin"}
                                          ]
                                        },
                                        "endhour": 
                                        { "$cond": 
                                          [
                                                { "$lt": [ "$$s.endhour", 10] }, 
                                                { "$concat": [ "0",{"$toString": "$$s.endhour"}]},
                                                { "$toString": "$$s.endhour"}
                                          ]
                                        },
                                        "endmin": 
                                        { "$cond": 
                                        [
                                                { "$lt": [ "$$s.endmin", 1] }, 
                                                "00",
                                                { "$toString": "$$s.endmin"}
                                          ]
                                        }
                                }
                        }
                   }

        }
},
{
        "$project": 
        {
                   "_id": 0,
                   "Opiskelija": "$_id.Opiskelija",
                   "coursename": "$_id.coursename",
                   "email": "$_id.email",
                   "tehtava": "$_id.Tehtava",
                   "sessions": 
                   {
                        "$map": 
                        {
                                "input": "$sessions",
                                "as": "s",
                                "in": 
                                {
                                        "start": { 
                                                 "$concat":  [ "$_id.timestamp", "T", "$$s.starthour", ":", "$$s.startmin", "Z"]
                                                 },
                                        "end":   { 

                                                     "$cond": 
                                                     [ 
                                                              { "$eq": ["$$s.endhour","24"] },
                                                              { "$concat":  [ "$_id.timestamp", "T23:59Z"]},
                                                              { "$concat": [ "$_id.timestamp", "T", "$$s.endhour", ":", "$$s.endmin", "Z"] }

                                                      ]


                                                     
                                                 }
                                }
                        }
                   }

        }
}'



if [ "$id" == "" ] && [ "${allow_all_courses}" == "" ]; then
    echo "You need to specify --id OR specify explicitly ---allow-all-courses"
    exit 1
elif [ "$id" != "" ] && [ "${allow_all_courses}" != "" ]; then
    echo "You need to specify --id OR  ---allow-all-courses, you cannot have both."
    exit 1
fi

query_assignments=$(rawurlencode "[$assignments]")
query_submissions=$(rawurlencode "[$submissions]")
query_submissions_by_date=$(rawurlencode "[$submissions_by_date]")
query_students=$(rawurlencode "[$students]")
query_scores=$(rawurlencode "[$scores]")
query_activity=$(rawurlencode "[$activity]")
query_sessions=$(rawurlencode "[$sessions]")
query_credits=$(rawurlencode "[$credits]")
query_usercache=$(rawurlencode "[$usercache]")
query_firstactivity=$(rawurlencode "[$firstactivity]")

runquery assignments
runquery submissions
runquery submissions_by_date
runquery students
runquery scores
runquery activity
runquery sessions
runquery credits
runquery usercache
runquery firstactivity
