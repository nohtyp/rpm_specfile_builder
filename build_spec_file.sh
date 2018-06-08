#!/bin/bash -x

NEWSPEC_FILE=~/rpmbuild/SPECS/jira.spec
APP_DIR="/opt/nsauto/nstools/local/share"
TEMP_FILES='install_dirs files'
URL='https://atlassian.com'
DELETE_DIRS=../delete_dirs
SUMMARY='This is a test package'
LICENSE='This is a test license'

function CreateValue()
{
  MyVal=$1
  export VALUE=`echo $MyVal|sed 's/^[a-z-]*//'|sed 's/^[0-9.-]*//'`
}

function CreateSpec()
{
  mkdir -p "$DELETE_DIRS"
  touch "$NEWSPEC_FILE"
}

function CleanUp()
{
  rm "$NEWSPEC_FILE" 2>/dev/null
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
  if [ ${MySetUp:0:3} == "jre" ]
  then
    echo "This is a jre package"
    echo %setup -n %{name}%{version} >> $NEWSPEC_FILE
  else
    echo %setup -n %{name}-%{version}-"${VALUE}" >> $NEWSPEC_FILE
  fi
}

function Extract()
{
  for z in $(ls -1)
  do
    if [ -d "$z" ]
    then
      echo "Removing directory $DELETE_DIRS/$z"
      rm -rf "$DELETE_DIRS/$z"
      mv "$z" "$DELETE_DIRS"
    elif [ -f "$z" ] && [ ${z: -4} == ".tar" ]
    then
      echo "Un-tarring file $z in $(pwd)"
      tar -xf "$z"
      rm "$z"
    fi
  done
}

function CreateTar()
{
  TAR_CREATE=$1
  echo "Tarring up file $TAR_CREATE"
  tar -cf $TAR_CREATE.tar $TAR_CREATE
}

function CreateName()
{
  MyName=$1
  if [ ${MyName:0:3} == "jre" ]
  then
    echo "This is a jre package with shorter name."
    echo "Name:           " ${MyName:0:3} >> $NEWSPEC_FILE
    echo "AutoReqProv:     no" >> $NEWSPEC_FILE
  else
    echo "Name:           " $(echo $i |grep -o "^\S*[[:digit:]]" |awk -F '-[[:digit:]]' '{print $1}') >> $NEWSPEC_FILE
  fi
}

function CreateVersion()
{
  MyVersion=$1
  if [ ${MyVersion:0:3} == "jre" ]
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
 if [ ${POST:0:3} == "jre" ]
 then 
   STANDARD_NAME=${POST:0:3} 
 else
   STANDARD_NAME=$(echo "$POST"|sed 's/[[:digit:]].//g')
 fi
 echo '%post'  >> $NEWSPEC_FILE
 echo case '"$1"' in  >> $NEWSPEC_FILE
 echo '  1)'            >> $NEWSPEC_FILE
 echo '      # This is an initial install.' >> $NEWSPEC_FILE
 echo '      ln -s '"$APP_DIR/$POST" "$APP_DIR/$STANDARD_NAME-current"  >> $NEWSPEC_FILE
 echo '   ;;' >> $NEWSPEC_FILE
 echo '  2)'  >> $NEWSPEC_FILE
 echo   '    # This is an upgrade.'  >> $NEWSPEC_FILE
 echo   '    # First remove current link.'  >> $NEWSPEC_FILE
 echo '      rm' "$APP_DIR/$STANDARD_NAME-current"  >> $NEWSPEC_FILE
 echo '   ;;'  >> $NEWSPEC_FILE
 echo esac >> $NEWSPEC_FILE
}

function CreatePreUn()
{
 PREUN=$1
 if [ ${PREUN:0:3} == "jre" ]
 then  
   STANDARD_NAME=${PREUN:0:3}
 else
   STANDARD_NAME=$(echo "$PREUN"|sed 's/[[:digit:]].//g')
 fi
 echo '%preun'  >> $NEWSPEC_FILE
 echo case '"$1"' in  >> $NEWSPEC_FILE
 echo '  0)'            >> $NEWSPEC_FILE
 echo '      # This is an un-install.' >> $NEWSPEC_FILE
 echo '      rm' "$APP_DIR/$STANDARD_NAME-current"  >> $NEWSPEC_FILE
 echo '   ;;' >> $NEWSPEC_FILE
 echo '  1)'  >> $NEWSPEC_FILE
 echo   '    # This is an upgrade.'  >> $NEWSPEC_FILE
 echo   '    # First stop service.'  >> $NEWSPEC_FILE
 echo '   ;;'  >> $NEWSPEC_FILE
 echo esac >> $NEWSPEC_FILE
}


Extract

for i in $(ls -1)
do 
  if [[ -d "$i" ]]; then 
    CleanUp
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
    #echo %setup -n %{name}-%{version}-"${VALUE}" >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    cat install_dirs       >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    cat files              >> $NEWSPEC_FILE
    echo                   >> $NEWSPEC_FILE
    CreatePreUn "$i"
    echo                   >> $NEWSPEC_FILE
    CreatePost "$i"
    CreateTar "$i"
  else 
    continue;
  fi
done
