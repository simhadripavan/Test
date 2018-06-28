#!/bin/bash

set -x -e

ls -l /bin/sh

#  this is a script that will run during the official build process.
#  it detects if the release version number changed from last time.
#  if yes, it generates the SQL update scripts.
#
#  Details:
#  ---
#  when a new release is detected:
#   - set "previous" schema version to "current" schema version
#   - increment "current" schema minor version by 1
#   - update "last_seen_release_version" to current release version
#   - create SQL update files from "previous" to "current"
#   - check in changed/new files to P4
#
#  How:
#  ---
#  we detect at build time that a new release happened by keeping
#    track of "last known release version", the first three components
#    from version.txt file. e.g. 10.3.9
#-   at build time, we check current "version.txt" file and see if the
#    first three components have moved on.
#    if yes, we are now on a new release.
#
#  we keep track of a "current" schema version, which represents the
#    schema version for the current build.
#
#  we keep track of "last_seen_release_version", which represents the
#    software release version seen when this script last ran (at build time)
#
#- TODO: supported updates definitions (currently in Defines.java part of
#  the SFTU service code), and new things we need to keep track of,
#  will be moved to a properties file, for ease of development and testing.
#
#- TODO: need to make proper updates to said properties file


export UPGRADE_SUPPORT_PROPERTIES_FILE=upgrade_support.properties
export VERSION_FILE=version.txt

export PROPERTY_VERSION_SCHEMA_MAJOR="version_schema_major"
export PROPERTY_VERSION_SCHEMA_MINOR="version_schema_minor"
export PROPERTY_VERSION_BUILD_LAST_SEEN="version_build_last_seen"

BRANCH_NAME="DummyBuild"

SCHEMA_VERSION_CURRENT_MAJOR=$(grep ${PROPERTY_VERSION_SCHEMA_MAJOR} ${UPGRADE_SUPPORT_PROPERTIES_FILE}| tr -d "\r\n"| awk -F "=" '{print $2}')
SCHEMA_VERSION_CURRENT_MINOR=$(grep ${PROPERTY_VERSION_SCHEMA_MINOR} ${UPGRADE_SUPPORT_PROPERTIES_FILE}| tr -d "\r\n"| awk -F "=" '{print $2}')
SCHEMA_VERSION_CURRENT=${SCHEMA_VERSION_CURRENT_MAJOR}"."${SCHEMA_VERSION_CURRENT_MINOR}
# keeps track of previous version, as we need it for some processing
# initialized to be the same as current version
SCHEMA_VERSION_PREVIOUS=${SCHEMA_VERSION_CURRENT}

RELEASE_VERSION_LAST_SEEN=$(grep ${PROPERTY_VERSION_BUILD_LAST_SEEN} ${UPGRADE_SUPPORT_PROPERTIES_FILE}| tr -d "\r\n"| awk -F "=" '{print $2}')
RELEASE_VERSION_CURRENT=$(grep "XMS_VER" ${VERSION_FILE}| tr -d "\r\n"| awk -F "=" '{print $2}')
# strip build number out
RELEASE_VERSION_LAST_SEEN=$(echo ${RELEASE_VERSION_LAST_SEEN}| awk -F "." '{print $1 "." $2 "." $3}')
RELEASE_VERSION_CURRENT=$(echo ${RELEASE_VERSION_CURRENT}| awk -F "." '{print $1 "." $2 "." $3}')

SQL_FILE_FRESH_BUILD_MSSQL="../../SAC/sql_files/xam/mssql/mam_mssql.sql"
SQL_FILE_FRESH_BUILD_MYSQL="../../SAC/sql_files/xam/mysql/mam_mysql.sql"
SQL_FILE_FRESH_BUILD_POSTGRES="../../SAC/sql_files/xam/postgres/mam_postgres.sql"

check_if_release_version_changed() {

    echo "checking '${RELEASE_VERSION_LAST_SEEN}' == '${RELEASE_VERSION_CURRENT}' ..."
    if [ "${RELEASE_VERSION_LAST_SEEN}" == "${RELEASE_VERSION_CURRENT}" ]; then
        # yes. returning out of this function
        echo "Release version did not change for Tenant. No action taken."
		read -p "This script is about to run build_system."
		sh ./build_system.sh
		read -p "This script has just run build_system."
        exit 0
    else
        # no. exiting shell script
        return 0
    fi
}

update_tracked_versions() {
read -p "update_tracked_versions"
    if [[ ${BRANCH_NAME} != "PULL_REQUEST"} ]]; then
      git config --global user.email "simhadri.pavans@gmail.com"
      git config --global user.name "Pavan Ofc Lap"
read -p "Before GIT"
      if [[ `git branch | grep ${BRANCH_NAME}` ]]; then
        # Remove existing branch, to prevent conflicts when getting latest
        git branch -D ${BRANCH_NAME}
      fi
     git checkout -b ${BRANCH_NAME} 
    fi
read -p "After GIT"
    # increment minor schema version
    SCHEMA_VERSION_CURRENT_MINOR=$(echo ${SCHEMA_VERSION_CURRENT_MINOR}| awk '{print $0+1}')
    sed -i "s/${PROPERTY_VERSION_SCHEMA_MAJOR}=.*/${PROPERTY_VERSION_SCHEMA_MAJOR}=${SCHEMA_VERSION_CURRENT_MAJOR}/g" ${UPGRADE_SUPPORT_PROPERTIES_FILE}
    sed -i "s/${PROPERTY_VERSION_SCHEMA_MINOR}=.*/${PROPERTY_VERSION_SCHEMA_MINOR}=${SCHEMA_VERSION_CURRENT_MINOR}/g" ${UPGRADE_SUPPORT_PROPERTIES_FILE}
    SCHEMA_VERSION_CURRENT=${SCHEMA_VERSION_CURRENT_MAJOR}"."${SCHEMA_VERSION_CURRENT_MINOR}

    # update "last_seen_release_version" to current release version
    sed -i "s/${PROPERTY_VERSION_BUILD_LAST_SEEN}=.*/${PROPERTY_VERSION_BUILD_LAST_SEEN}=${RELEASE_VERSION_CURRENT}/g" ${UPGRADE_SUPPORT_PROPERTIES_FILE}

    # find "supported_versions=" line
    # add ",{SCHEMA_VERSION_CURRENT}" to end
    sed -i "/^supported_versions=/ s/$/,${SCHEMA_VERSION_PREVIOUS}/" ${UPGRADE_SUPPORT_PROPERTIES_FILE}

    # find "sql_upgrade_scripts_from_*=" lines
    # add ",{SCHEMA_VERSION_CURRENT}" to end
    sed -i "/^sql_upgrade_scripts_from.*=/ s/$/, v${SCHEMA_VERSION_PREVIOUS}_v${SCHEMA_VERSION_CURRENT}/" ${UPGRADE_SUPPORT_PROPERTIES_FILE}

    # add "sql_upgrade_scripts_from_PREVIOUS_VERSION=v{PREVIOUS_VERSIO}_v{CURRENT_VERSION}" line
    NL=`tail -c 1 ${UPGRADE_SUPPORT_PROPERTIES_FILE}`
    if [ "$NL" != "" ]; then
        echo "No newline found at end of ${UPGRADE_SUPPORT_PROPERTIES_FILE}";
        echo "Adding a newline"
        echo >> ${UPGRADE_SUPPORT_PROPERTIES_FILE}
    fi
    echo "sql_upgrade_scripts_from_${SCHEMA_VERSION_PREVIOUS}=v${SCHEMA_VERSION_PREVIOUS}_v${SCHEMA_VERSION_CURRENT}" >> ${UPGRADE_SUPPORT_PROPERTIES_FILE}
    return 0
}

generate_new_sql_update_scripts() {
    # update "minor=" line in template SQL scripts, copy to sql_files directory
read -p "generate_new_sql_update_scripts"
    sed -i "s/minor=.*/minor=${SCHEMA_VERSION_CURRENT_MINOR};/g" template_mssql.sql
    cp template_mssql.sql ../../SAC/sql_files/upgrade_scripts/mssql_v${SCHEMA_VERSION_PREVIOUS}_v${SCHEMA_VERSION_CURRENT}.sql

    sed -i "s/minor=.*/minor=${SCHEMA_VERSION_CURRENT_MINOR};/g" template_mysql.sql
    cp template_mysql.sql ../../SAC/sql_files/upgrade_scripts/mysql_v${SCHEMA_VERSION_PREVIOUS}_v${SCHEMA_VERSION_CURRENT}.sql

    sed -i "s/minor=.*/minor=${SCHEMA_VERSION_CURRENT_MINOR};/g" template_pgsql.sql
    cp template_pgsql.sql ../../SAC/sql_files/upgrade_scripts/pgsql_v${SCHEMA_VERSION_PREVIOUS}_v${SCHEMA_VERSION_CURRENT}.sql

    return 0
}

modify_new_installation_scripts() {
read -p "modify_new_installation_scripts"
    sed -i "s/INSERT INTO database_schema_version VALUES(.*/INSERT INTO database_schema_version VALUES(${SCHEMA_VERSION_CURRENT_MAJOR}\, ${SCHEMA_VERSION_CURRENT_MINOR});/g" ${SQL_FILE_FRESH_BUILD_MSSQL}
    sed -i "s/INSERT INTO database_schema_version VALUES(.*/INSERT INTO database_schema_version VALUES(${SCHEMA_VERSION_CURRENT_MAJOR}\, ${SCHEMA_VERSION_CURRENT_MINOR});/g" ${SQL_FILE_FRESH_BUILD_MYSQL}
    sed -i "s/INSERT INTO database_schema_version VALUES(.*/INSERT INTO database_schema_version VALUES(${SCHEMA_VERSION_CURRENT_MAJOR}\, ${SCHEMA_VERSION_CURRENT_MINOR});/g" ${SQL_FILE_FRESH_BUILD_POSTGRES}
}

check_in_changed_files() {
    # this is for local testing.
    # comment out for official build machine. it has proper environment variables already.
    #. ./dot_this.sh
#    SRC_TOP=../..

#    if [[ ${BRANCH_NAME} != "PULL_REQUEST"} ]]; then
      git add ${UPGRADE_SUPPORT_PROPERTIES_FILE}
      git add ${SQL_FILE_FRESH_BUILD_MSSQL}
      git add ${SQL_FILE_FRESH_BUILD_MYSQL}
      git add ${SQL_FILE_FRESH_BUILD_POSTGRES}
      git add ../../SAC/sql_files/upgrade_scripts/*v${SCHEMA_VERSION_PREVIOUS}_v${SCHEMA_VERSION_CURRENT}.sql

      git commit -m "\
Schema versioning related update.\
Automated submit by build script."
      git push origin ${BRANCH_NAME}
#    fi
    return 0
}

check_if_release_version_changed
update_tracked_versions
generate_new_sql_update_scripts
modify_new_installation_scripts
check_in_changed_files
read -p "This script is about to run build_system."
sh ./build_system.sh
read -p "This script has just run build_system."