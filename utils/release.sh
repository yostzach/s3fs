#!/bin/bash

DIST_ARCHIVES=$1

LAST_DIR=`/bin/pwd`

AUTH_FILE=`grep -l s3fs.googlecode.com $HOME/.subversion/auth/svn.simple/*`

if test -r ${AUTH_FILE}; then
   SVN_USERNAME=`grep -A 2 username ${AUTH_FILE} | tail -n 1 | sed -e 's/^/-u /'`
   SVN_PASSWD=`grep -A 2 password ${AUTH_FILE} | tail -n 1 | sed -e 's/^/-w /'`
else
   SVN_USERNAME=""
   SVN_PASSWD=""
fi

SVN_REV=`svnversion -n | sed -e 's/M//' -e 's/^/r/' -e 's/:.*//'`

if test ! -d "../tarballs"; then
   echo ../tarballs directory does not exist
   exit 1
fi

if test ! -f "../wiki/InstallationNotes.wiki"; then
   echo ../wiki/InstallationNotes.wiki does not exist
   exit 1
fi

INSTALL_WIKI="../wiki/InstallationNotes.wiki"

if test ! -w ${INSTALL_WIKI}; then
   echo ${INSTALL_WIKI} is not writeable 
   exit 1
fi

if test -e "../tarballs/${DIST_ARCHIVES}"; then
   echo ../tarballs/${DIST_ARCHIVES} all ready exists, update version in configure.ac ;
   exit 1
fi

python ../utils/googlecode_upload.py -s ${SVN_REV} -p s3fs \
                                     -l Featured ${SVN_USERNAME} ${SVN_PASSWD} \
                                     ${DIST_ARCHIVES}

cp ${DIST_ARCHIVES} ../tarballs

cd ../tarballs

svn add --force ${DIST_ARCHIVES}

ln -f -s  ${DIST_ARCHIVES} latest

cd ${LAST_DIR} 

sed -i -e "/Download:/s/s3fs-.*.gz /${DIST_ARCHIVES} /" ${INSTALL_WIKI}
sed -i -e "/ checksum:/s/ checksum:.* / checksum: `sha1sum ${DIST_ARCHIVES} | awk '{print $1}'` /" \
         ${INSTALL_WIKI}
sed -i -e "/ size:/s/ size:.* / size: `/bin/ls -l ${DIST_ARCHIVES} | awk '{print $5}'` /" \
         ${INSTALL_WIKI}
sed -i -e "/tar xvzf/s/s3fs-.*.gz/${DIST_ARCHIVES}/" ${INSTALL_WIKI}
sed -i -e "/cd s3fs/s/s3fs-.*/${DIST_ARCHIVES}/" ${INSTALL_WIKI}
sed -i -e "/cd s3fs/s/.tar.gz/\//" ${INSTALL_WIKI}

# cat ${INSTALL_WIKI}

cd ../

# pwd 


svn commit --non-interactive -m "Release of ${DIST_ARCHIVES}" ./tarballs/${DIST_ARCHIVES} \
   ./tarballs/latest ./wiki/InstallationNotes.wiki

exit 0



