#!/bin/bash -x

NEWSPEC_FILE=$RPM_BUILD_DIR/$NEWSPEC_PATH/$NEWSPEC_FILE
APP_DIR=$APP_DIR
TEMP_FILES='install_dirs files'
URL=$URL
DELETE_DIRS=../delete_dirs
SOURCE_DIR=$RPM_BUILD_DIR/$NEWSPEC_SOURCE
SUMMARY=$SUMMARY
LICENSE=$LICENSE

function CreateValue()
{
  MyVal=$1
  if [ $(echo $MyVal | sed 's/[a-z-]*$//g' |sed 's/-[[:digit:]].*//g') = "atlassian-jira-software" ]
  then
    export VALUE=`echo $MyVal |sed 's/^[a-z-]*//'|sed 's/^[0-9.-]*//'`
  else
    export VALUE=`echo $MyVal |sed 's/^[a-z-]*//'`
  fi
}

function CreateSpec()
{
  mkdir -p "$DELETE_DIRS"
  echo "Creating spec file $NEWSPEC_FILE"
  touch "$NEWSPEC_FILE"
}

function CleanUp()
{
  MyCleanup=$1
  rm "$NEWSPEC_FILE" 2> /dev/null
  rm "$MyCleanup" 2> /dev/null
  rm "$TEMP_FILES" 2>/dev/null
}

function CreateSource()
{
  MySource=$1
  export SOURCE="$MySource".tar
}

function CreateSetup()
{
  MySetUp=$1
  if [ $(echo $MyVal | sed 's/[a-z-]*$//g' |sed 's/-[[:digit:]].*//g') = "atlassian-jira-software" ]
  then
    echo %setup -n %{name}-%{version}-"${VALUE}" >> $NEWSPEC_FILE
  else
    echo %setup -n %{name}-%{version} >> $NEWSPEC_FILE
  fi
}

function Extract()
{
  for z in $(ls -1)
  do
    echo "$z"
    if [ -f "$z" ] && [ "${z: -4}" = ".tar" ] || [ "${z: -7}" = ".tar.gz" ]
    then
      echo "Un-tarring file $z in $(pwd)"
      tar -xvf "$z"
      rm "$z"
    elif [ -f "$z" ] && [ "${z: -4}" = ".zip" ]
    then
      echo "Un-zipping file $z in $(pwd)"
      unzip "$z"
      rm "$z"
    else
      echo "$z is not a file that can be unpacked.."
    fi
  done
}

function CreateTar()
{
  TAR_CREATE=$1
  echo "Tarring up file $TAR_CREATE"
  tar -cf $TAR_CREATE.tar $TAR_CREATE
  echo "Moving $TAR_CREATE.tar to $SOURCE_DIR"
  mv -f $TAR_CREATE.tar $SOURCE_DIR

}

function CreateName()
{
  MyName=$1
  if [ ${MyName:0:3} = "jre" ]
  then
    echo "Name:           " ${MyName:0:3} >> $NEWSPEC_FILE
    echo "AutoReqProv:     no" >> $NEWSPEC_FILE
  else
    echo "Name:           " $(echo $i |grep -o "^\S*[[:digit:]]" |awk -F '-[[:digit:]]' '{print $1}') >> $NEWSPEC_FILE
  fi
}

function CreateVersion()
{
  MyVersion=$1
  if [ ${MyVersion:0:3} = "jre" ]
  then
    #this regex will get version number
    echo "Version:        " $(echo "$MyVersion"|sed 's/^[a-z-]*//') >> $NEWSPEC_FILE
  else
    echo "Version:        " $(echo "$MyVersion" |egrep -o "([0-9]{1,}\.)+[0-9]{1,}") >> $NEWSPEC_FILE
  fi
}

function CreatePost()
{
 POST=$1
 if [ ${POST:0:3} = "jre" ]
 then 
   STANDARD_NAME=${POST:0:3} 
 else
   STANDARD_NAME=$(echo "$POST"| sed 's/\W//g')
 fi
 
 if [ $(echo $POST | awk -F '-' '{print NF}') -eq 2 ]
 then
   export USER=$(echo $POST | sed 's/[a-z-]*$//g' |sed 's/-[[:digit:]].*//g')
 else
   export USER=$(echo $POST | sed 's/[a-z-]*$//g' |sed 's/-[[:digit:]].*//g' | awk -F '-' '{print $2}')
 fi
 
 echo '%post'  >> $NEWSPEC_FILE
 echo case '"$1"' in  >> $NEWSPEC_FILE
 echo '  1)'            >> $NEWSPEC_FILE
 echo '      echo "This is from post value 1: $1"' >> $NEWSPEC_FILE
 echo "      echo Creating user for $USER" >> $NEWSPEC_FILE
 echo '      ln -s '"$APP_DIR/$USER/$POST" "$APP_DIR/$USER/current"  >> $NEWSPEC_FILE
 echo '   ;;' >> $NEWSPEC_FILE
 echo '  2)'  >> $NEWSPEC_FILE
 echo '      echo "This is from post value 2: $1"' >> $NEWSPEC_FILE
 echo '      ln -s '"$APP_DIR/$USER/$POST" "$APP_DIR/$USER/current"  >> $NEWSPEC_FILE
 echo '   ;;'  >> $NEWSPEC_FILE
 echo esac >> $NEWSPEC_FILE
}


function CreatePostUn()
{
 POSTUN=$1
 if [ ${POSTUN:0:3} = "jre" ]
 then 
   STANDARD_NAME=${POSTUN:0:3} 
 else
   STANDARD_NAME=$(echo "$POSTUN"| sed 's/\W//g')
 fi
 echo '%postun'  >> $NEWSPEC_FILE
 echo case '"$1"' in  >> $NEWSPEC_FILE
 echo '  1)'            >> $NEWSPEC_FILE
 echo '      echo "This is postun value 1: $1"' >> $NEWSPEC_FILE
 echo '   ;;' >> $NEWSPEC_FILE
 echo '  2)'  >> $NEWSPEC_FILE
 echo '      echo "This is postun value 2: $1"' >> $NEWSPEC_FILE
 echo '   ;;'  >> $NEWSPEC_FILE
 echo esac >> $NEWSPEC_FILE
}


function CreatePreUn()
{
 PREUN=$1
 if [ ${PREUN:0:3} = "jre" ]
 then  
   STANDARD_NAME=${PREUN:0:3}
 else
   STANDARD_NAME=$(echo "$PREUN"| sed 's/\W//g')
   echo $STANDARD_NAME
 fi
 echo '%preun'  >> $NEWSPEC_FILE
 echo case '"$1"' in  >> $NEWSPEC_FILE
 echo '  0)'            >> $NEWSPEC_FILE
 echo '      echo "This is from preun value 0: $1"' >> $NEWSPEC_FILE
 echo '   ;;' >> $NEWSPEC_FILE
 echo '  1)'  >> $NEWSPEC_FILE
 echo '      echo "This is from preun value 1: $1"' >> $NEWSPEC_FILE
 echo '   ;;'  >> $NEWSPEC_FILE
 echo esac >> $NEWSPEC_FILE
}

function CreatePre()
{
 PRE=$1
 if [ ${PRE:0:3} = "jre" ]
 then  
   STANDARD_NAME=${PRE:0:3}
 else
   STANDARD_NAME=$(echo "$PRE"| sed 's/\W//g')
   echo $STANDARD_NAME
 fi
 
 if [ $(echo $PRE | awk -F '-' '{print NF}') -eq 2 ]
 then
   export USER=$(echo $PRE | sed 's/[a-z-]*$//g' |sed 's/-[[:digit:]].*//g')
 else
   export USER=$(echo $PRE | sed 's/[a-z-]*$//g' |sed 's/-[[:digit:]].*//g' | awk -F '-' '{print $2}')
 fi
 
 echo '%pre'  >> $NEWSPEC_FILE
 echo case '"$1"' in  >> $NEWSPEC_FILE
 echo '  1)'            >> $NEWSPEC_FILE
 echo '      echo "This is from pre value 1: $1"' >> $NEWSPEC_FILE
 if [ ${PRE:0:3} = "jre" ]
 then
   continue
 else
 echo "      echo Creating user account $USER.." >> $NEWSPEC_FILE
 echo "      useradd -m -r -d /home/$USER -s /bin/false $USER" >> $NEWSPEC_FILE 
 fi
 echo '   ;;' >> $NEWSPEC_FILE
 echo '  2)'  >> $NEWSPEC_FILE
 echo '      echo "This is from pre value 2: $1"' >> $NEWSPEC_FILE
 echo "      echo Shutting down $USER server.." >> $NEWSPEC_FILE
 echo "      $APP_DIR/$USER/current/bin/shutdown.sh" >> $NEWSPEC_FILE
 echo '      sleep 10' >> $NEWSPEC_FILE
 echo '      rm ' "$APP_DIR/$USER/current"  >> $NEWSPEC_FILE
 echo '   ;;'  >> $NEWSPEC_FILE
 echo esac >> $NEWSPEC_FILE
}

Extract
echo "This is IFS before the changes $IFS"
export IFS=$'\n'

for i in $(ls -1)
do 
  if [[ -d "$i" ]]; then 
    CleanUp "$i"
    CreateSpec
    CreateSource "$i"
    CreateValue "$i"
    echo '%install' > install_dirs;for g in $(find "$i" -type d);do echo 'install -d -m 0755 $RPM_BUILD_ROOT'"$APP_DIR"'/'"$g" >> install_dirs;done
    for h in $(find "$i" -type f);do echo "install -m 0755 "'$RPM_BUILD_DIR/'"'$h'" '$RPM_BUILD_ROOT'"$APP_DIR"'/'"'$h'" >> install_dirs;done
    echo "%files" > files;for j in $(find "$i" -type d);do echo "$APP_DIR/$j" >> files;done
    echo                   >> $NEWSPEC_FILE
    CreateName "$i"
    CreateVersion "$i"
    echo 'Release:         1%{?dist}' >> $NEWSPEC_FILE
    echo "Summary:         $SUMMARY" >> $NEWSPEC_FILE
    echo "License:         $LICENSE"  >> $NEWSPEC_FILE
    echo "URL:             $URL"   >> $NEWSPEC_FILE
    echo "Source0:         $SOURCE" >> $NEWSPEC_FILE
    echo '%description'    >> $NEWSPEC_FILE
    echo "$DESCRIPTION"    >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    echo '%clean'          >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    echo '%prep'           >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    CreateSetup "$i"
    echo                   >> $NEWSPEC_FILE
    cat install_dirs       >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    cat files              >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    CreatePre "$i"
    echo                   >> $NEWSPEC_FILE
    CreatePreUn "$i"
    echo                   >> $NEWSPEC_FILE
    CreatePost "$i"
    echo                   >> $NEWSPEC_FILE
    CreatePostUn "$i"
    CreateTar "$i"
  else 
    continue
  fi
done
