#!/bin/bash
# https://www.mypdns.org/
# Copyright: Content: https://gitlab.com/spirillen
# Source:Content:
#
# Original attributes and credit
# The credit for the original bash scripts goes to Mitchell Krogza

# You are free to copy and distribute this file for non-commercial uses,
# as long the original URL and attribution is included.

# Please forward any additions, corrections or comments by logging an issue at
# https://gitlab.com/my-privacy-dns/support/issues

# ******************
# Set Some Variables
# ******************

now=$(date '+%F %T %z (%Z)')
my_git_tag=V.${TRAVIS_BUILD_NUMBER}
bad_referrers=$(wc -l < ${TRAVIS_BUILD_DIR}/PULL_REQUESTS/domains.txt)
hosts="${TRAVIS_BUILD_DIR}/0.0.0.0/hosts"
sshosts="${TRAVIS_BUILD_DIR}/SafeSearch/hosts"
hosts127="${TRAVIS_BUILD_DIR}/127.0.0.1/hosts"
mobile="${TRAVIS_BUILD_DIR}/Mobile/hosts"
#safesearch=$"{TRAVIS_BUILD_DIR}/0.0.0.0 + SafeSearch (beta)/hosts"

hostsTemplate=${TRAVIS_BUILD_DIR}/dev-tools/hosts.template
sshostsTemplate=${TRAVIS_BUILD_DIR}/dev-tools/sshosts.template
MobileTemplate=${TRAVIS_BUILD_DIR}/dev-tools/mobile.template
SafeSearchTemplate=${TRAVIS_BUILD_DIR}/dev-tools/safesearchhosts.template

dnsmasq=${TRAVIS_BUILD_DIR}/dnsmasq
dnsmasqTemplate=${TRAVIS_BUILD_DIR}/dev-tools/ddwrt-dnsmasq.template
tmphostsA=tmphostsA
tmphostsB=tmphostsB
tmphostsC=tmphostsC

# **********************************
# Temporary database files we create
# **********************************

inputdbA=/tmp/lastupdated.db
inputdb1=/tmp/hosts.db

# **********************************
echo Setup input bots and referer lists
# **********************************

input1=${TRAVIS_BUILD_DIR}/PULL_REQUESTS/domains.txt
input2=${TRAVIS_BUILD_DIR}/dev-tools/domains_tmp.txt

# **************************************************************************
# Sort lists alphabetically and remove duplicates before cleaning Dead Hosts
# **************************************************************************

sort -u ${input1} -o ${input1}

# *****************
# Activate Dos2Unix
# *****************

dos2unix ${input1}

# ******************************************
# Trim Empty Line at Beginning of Input File
# ******************************************

grep '[^[:blank:]]' < ${input1} > ${input2}
sudo mv ${input2} ${input1}

# ********************************************************
# Clean the list of any lines not containing a . character
# ********************************************************

cat ${input1} | sed '/\./!d' > ${input2} && mv ${input2} ${input1}

# **************************************************************************************
# Strip out our Dead Domains / Whitelisted Domains and False Positives from CENTRAL REPO
# **************************************************************************************


# *******************************
# Activate Dos2Unix One Last Time
# *******************************

dos2unix ${input1}

# *******************************
echo Generate hosts 0.0.0.0
# *******************************

cat ${hostsTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${hosts}

# *******************************
echo Generate hosts 0.0.0.0
# *******************************

cat ${sshostsTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${sshosts}

# *******************************
echo Generate hosts 127.0.0.1
# *******************************

cat ${hostsTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("127.0.0.1\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${hosts127}

# *******************************
# Generate Mobile hosts
# *******************************

cat ${MobileTemplate} > ${tmphostsA}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
mv ${tmphostsA} ${mobile}

# *******************************
# Generate hosts + SafeSearch
# *******************************

#cat ${SafeSearchTemplate} > ${tmphostsA}
#printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsA}
#cat "${input1}" | awk '/^#/{ next }; {  printf("0.0.0.0\t%s\n",tolower($1)) }' >> ${tmphostsA}
#cp ${tmphostsA} ${safesearch}

# ********************************************************
# PRINT DATE AND TIME OF LAST UPDATE INTO DNSMASQ TEMPLATE
# ********************************************************

cat ${dnsmasqTemplate} > ${tmphostsB}
printf "### Updated: ${now} Build: ${my_git_tag}\n### Porn Hosts Count: ${bad_referrers}\n" >> ${tmphostsB}
cat "${input1}" | awk '/^#/{ next }; {  printf("address=/%s/\n",tolower($1)) }' >> ${tmphostsB}
mv ${tmphostsB} ${dnsmasq}

# ************************************
echo Make Bind format RPZ 
# ************************************
RPZ="$(mktemp)"

printf "localhost.\t3600\tIN\tSOA\tneed.to.know.only. hostmaster.mypdns.org. `date +%s` 3600 60 604800 60;\nlocalhost.\t3600\tIN\tNS\tlocalhost\n" > "${RPZ}"
cat "${input1}" | awk '/^#/{ next }; {  printf("%s\tCNAME\t.\n*.%s\tCNAME\t.\n",tolower($1),tolower($1)) }' >> "${RPZ}"
mv "${RPZ}" "${TRAVIS_BUILD_DIR}/mypdns.cloud.rpz"

# ***********************************
echo Unbound zone file always_nxdomain
# ***********************************
UNBOUND="$(mktemp)"

cat "${input1}" | awk '/^#/{ next }; {  printf("local-zone: \"%s\" always_nxdomain\n",tolower($1)) }' >> "${UNBOUND}"
mv "${UNBOUND}" "${TRAVIS_BUILD_DIR}/unbound.nxdomain.zone"




exit ${?}
