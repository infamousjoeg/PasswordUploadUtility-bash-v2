#!/bin/bash
#Written by Kevin Ross (kmross)

#########################################################################
# Password Upload Utility v2 - Linux
# 
# Description:  Updated Password Upload Utility utilizing the REST API
#               instead of an outdated and restricted version of PACLI
#
# Created by:   Kevin Ross (kmross)
#
# 
################## WELCOME TO CYBERARK IMPACT 2017! #####################
#
# TODO:         Hire a real pl/py coder instead :-)
#               Get InfamousJoeG Drunk
#               Add Bulk Change Method
#               Add Additional Properties for non-Windows account
#               Safe Verification
#               Platform Verification
#               Error Handling Everywhere in the script
#               EParse logs from curl for error checking
#
#########################################################################

printf "\n            PUU2"
printf "\n\n"
printf "\n░░░░░░░░░▄░░░░░░░░░░░░░░▄░░░░"
printf "\n░░░░░░░░▌▒█░░░░░░░░░░░▄▀▒▌░░░"
printf "\n░░░░░░░░▌▒▒█░░░░░░░░▄▀▒▒▒▐░░░"
printf "\n░░░░░░░▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐░░░"
printf "\n░░░░░▄▄▀▒░▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐░░░"
printf "\n░░░▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌░░░"
printf "\n░░▐▒▒▒▄▄▒▒▒▒░░░▒▒▒▒▒▒▒▀▄▒▒▌░░"
printf "\n░░▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐░░"
printf "\n░▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄▌░"
printf "\n░▌░▒▄██▄▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▌░"
printf "\n▀▒▀▐▄█▄█▌▄░▀▒▒░░░░░░░░░░▒▒▒▐░"
printf "\n▐▒▒▐▀▐▀▒░▄▄▒▄▒▒▒▒▒▒░▒░▒░▒▒▒▒▌"
printf "\n▐▒▒▒▀▀▄▄▒▒▒▄▒▒▒▒▒▒▒▒░▒░▒░▒▒▐░"
printf "\n░▌▒▒▒▒▒▒▀▀▀▒▒▒▒▒▒░▒░▒░▒░▒▒▒▌░"
printf "\n░▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▄▒▒▐░░"
printf "\n░░▀▄▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▄▒▒▒▒▌░░"
printf "\n░░░░▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀░░░"
printf "\n░░░░░░▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀░░░░░"
printf "\n░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▀▀░░░░░░░░"
printf "\nMUCH PUU         VERY RESTFUL"
printf "\n\n"


read -p "Enter the CyberArk URL (ie: https://components.cyberark.local) : " CAURL
read -p "Enter Your Name: " CAUsername
read -s -p "Enter Password: " CAPass
read -p "Enter the path of the CSV file (ie: /home/user/cyberark.csv): " INPUT

printf "\n"
#login and get auth_key
curl --insecure -s -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"username":"'"$CAUsername"'", "password":"'"$CAPass"'"}' $CAURL/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon | sed -e ':a;N;$!ba;s/\n/ /g' | sed -e 's/.*\"\:\"\(.*\)\"}.*/\1/g' > auth.key

#add "authorization:" to head of file
sed -i '1s/^/authorization: /' ./auth.key

#set auth_key
AUTH=$(cat ./auth.key)
printf "\n--------------------------------------------------"
printf "\n\nYour CyberArk RestAPI Auth Token:\n\n"
echo "$AUTH"
printf "\n--------------------------------------------------\n\n"

#Process the file
OLDIFS=$IFS
IFS=,
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }

while read CYBRObjectName CYBRSafe CYBRAddress CYBRUsername CYBRPassword CYBRPlatformID CYBRDisableAutoMgmt CYBRDisableAutoMgmtReason
do
	echo "ObjectName : $CYBRObjectName"
	echo "Safe : $CYBRSafe"
	echo "Address : $CYBRAddress"
	echo "Username : $CYBRUsername"
	echo "Password : $CYBRPassword"
	echo "PlatformID : $CYBRPlatformID"
	echo "DisableAutoMgmt : $CYBRDisableAutoMgmt"
	echo "DisableAutoMgmtReason : $CYBRDisableAutoMgmtReason"

printf "\n--------------------------------------------------\n\n"
printf "Attempting to create your account.  Logs below:\n"
printf "\n--------------------------------------------------\n\n"

curl --insecure -s -i -H "$AUTH" -H "Content-Type:application/json" -X POST --data '{"account" : {"safe":"'"$CYBRSafe"'","platformID": "'"$CYBRPlatformID"'","address": "'"$CYBRAddress"'","accountName": "'"$CYBRObjectName"'","password": "'"CYBRPassword"'","username": "'"$CYBRUsername"'",}}' $CAURL/PasswordVault/WebServices/PIMServices.svc/Account | grep HTTP/1.1


done < $INPUT
IFS=$OLDIFS

#logoff_from_safe
curl --insecure -s -i -H "$AUTH" -d -H "Content-Type:application/json" -X POST $CAURL/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logoff| grep HTTP/1.1
printf "\nLogged off\n"

# A little cleanup is needed
rm -rf ./auth.key