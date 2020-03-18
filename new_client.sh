#!/bin/bash

   echo "Please select what tipe of account you are creating : "
   echo "1 : - SFTP SUBMIT ACCOUNT"
   echo "2 : - AWS S3API Integration "
   echo "3 : - Azure Integration  "

   read account_type;

   case $account_type in


  1) echo "You have selected to create an SFTP SUBMIT ACCOUNT "

  function determine_viability()
{
        while true
        do
        export num=1
             echo -ne "\nInput the new user Account : "; read USER_ACCOUNT
          if ! id $USER_ACCOUNT > /dev/null 2>&1 ;
                  then
          echo -en "\n\t\tConfirming this is a new account ! Let's create it !\n"
                  else
                  echo -en "This user account : $USER_ACCOUNT already exists! Stopping process !"
                  exit 0
 fi

 echo -ne "\nInput Client's Company Name :"; read COMPANY
 company_key_name=$(awk 'BEGIN{OFS="_"} {for (i=1; i<NF; i++) printf "%s%s",$i,OFS; printf "%s\n", $NF}' <<< "$COMPANY")
 echo -ne "\nDo you wish to install iiNET public key [yes|no] ? : "; read iinetpub
 echo -ne "\nDo you wish to install MFT public key  [yes|no] ? : "; read mftpub
 echo -ne "\nDo you wish to install a customer public key [yes|no] ? : ";read cust_pub
     if [ $cust_pub == yes ]; then
         echo -ne "\nProvide customer key :"; read PUB_KEY

         else
         echo -ne "\nA customer key will not be installed"
                 echo
         fi

        if [ $cust_pub == yes ];then
       echo -ne "\nInstall a second customer ssh key ? [yes|no] ? : "; read PUB_KEY_NEXT
       else
           echo
        fi

 if [ $PUB_KEY_NEXT == yes ]; then
     echo -ne "\nInput customer public key_2 : "; read PUB_KEY_2
         else
         echo
 fi

 echo -en "\n${COL_RED}Creating account:$USER_ACCOUNT for company :$COMPANY${COL_RESET}"
 echo
 echo -en "\nPress\"${COL_GREEN}Enter${COL_RESET}\" to continue,any other key to reset ! "; read z
             if [[ $z == '' ]];then
               break
             fi
    done
}

   determine_viability
     USER_DIR_max=`/bin/ls -1 /ftpserver/ | grep -x [0-9][0-9][0-9][0-9] | grep -vx 99[0-9][0-9] | uniq | sort | tail -n 1`
     USER_DIR=$[$USER_DIR_max+1]
     CLIENT_PUB_KEY_FOLDER=/home/svc_iinet/stf_pub_key/
     CLIENT_PUB_KEY=id_rsa_${company_key_name}.pub
         CLIENT_PUB_KEY_2=id_rsa_${company_key_name}_2.pub

     echo "$PUB_KEY" > $CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY
         echo "$PUB_KEY_2" > $CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY_2

 #Creating User Account and generating propagation commands
 echo
 echo "[*] Begining creation of submit user account ($USER_ACCOUNT)under directory /ftpserver/($USER_DIR)"
 /usr/sbin/useradd  -c  'SFTP Submit User'  -s  /bin/false  -d  /ftpserver/$USER_DIR  -g ftpusers -G sftpusers  $USER_ACCOUNT
 create_user_cmd1="/usr/sbin/useradd  -c  'SFTP Submit User'  -s  /bin/false  -d  /ftpserver/$USER_DIR  -g ftpusers -G sftpusers  $USER_ACCOUNT"
 create_user_cmd4="/usr/bin/chown -R ${USER_ACCOUNT}.sftpadmins /ftpserver/$USER_DIR"
 sleep 2s

 #Modified by Alex Vieriu on 09/09/2019 - Expiration Date set to NEVER.
 #disable account password, unlock account, updating expiration date to NEVER and generating propagation commands
 echo "[*] disabling user($USER_ACCOUNT) password"
        passwd -d  $USER_ACCOUNT
        passwd -f -u $USER_ACCOUNT
        chage -M 99999 $USER_ACCOUNT

        create_user_cmd2="passwd -d $USER_ACCOUNT"
        create_user_cmd3="passwd -f -u $USER_ACCOUNT"
        create_user_cmd5="chage -M 99999 $USER_ACCOUNT"
        sleep 2s

        # Set up folder permissions
        cd /ftpserver
        chmod 770 $USER_DIR
        cd $USER_DIR
        touch .notar
        chown root:root .notar
        chmod 444 .notar

        # Install Public Keys
        cd /ftpserver
        cd $USER_DIR
        /bin/mkdir .ssh2
        chmod 770 .ssh2
        cd .ssh2
        touch authorization

        if [ $iinetpub == yes ];then
        echo -n "[*] Installing iiNET public key"
        cp /home/svc_iinet/.ssh/id_rsa_iiNET_New_Prod.pub /ftpserver/$USER_DIR/.ssh2/id_rsa_iiNET_New_Prod.pub
        echo "[*] Authorizing iiNET public key"
        echo "key       id_rsa_iiNET_New_Prod.pub"  >> authorization
        else
        echo
       # cd /ftpserver/$USER_DIR
       # touch authorization
        fi
        sleep 1s

       if [ $mftpub == yes ];then
        echo -n "[*] Installing iiNET public key"
        cp /home/svc_iinet/.ssh/svc_mft_prod.pub /ftpserver/$USER_DIR/.ssh2/svc_mft_prod.pub
        echo "[*] Authorizing MFT public key"
        echo "key       svc_mft_prod.pub"  >> authorization
        else
        echo
        fi
        sleep 1s


                #first key
    if [ -f "$CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY" ]; then
                echo -ne "[*] \"$CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY\" confirmed!\n"
                echo -n "[*] Installing customer's ssh key "
                cp -v $CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY /ftpserver/$USER_DIR/.ssh2/
                echo "[*] Authorizing \"$CLIENT_PUB_KEY\""
                echo "key       $CLIENT_PUB_KEY"  >> authorization
        else
                echo "Customer public key \"$CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY\" has not been requested!"
                echo
                exit
    fi

    #second key
        if [ -f "$CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY_2" ] && [ $PUB_KEY_NEXT == yes ] ; then
                echo -ne "[*] \"$CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY_2\" confirmed!\n"
                echo -n "[*] Copying customer key_2 to user folder "
                cp -v $CLIENT_PUB_KEY_FOLDER$CLIENT_PUB_KEY_2 /ftpserver/$USER_DIR/.ssh2/
                echo "[*] Authorizing \"$CLIENT_PUB_KEY_2\""
                echo "key     $CLIENT_PUB_KEY_2"  >> authorization
        else
                echo -ne "\nSecondary client shh key has not been requested!"
                echo

        fi




        sleep 3s

        # Folder owner & File rights Control
        cd /ftpserver
        cd $USER_DIR
        echo "[*] modifying \".ssh2\" user:group under \"$USER_ACCOUNT:sftpadmins\""
        chown -R $USER_ACCOUNT:sftpadmins .ssh2
        cd .ssh2

                if [ -f "id_rsa_iiNET_New_Prod.pub" ]; then
                echo "[*] modifying \"id_rsa_iiNET_New_Prod.pub\" mod to 644"
                chmod  644  id_rsa_iiNET_New_Prod.pub
                echo "[*] modifying \"id_rsa_iiNET_New_Prod.pub\" user:group under \"$USER_ACCOUNT:sftpadmins\""
                chown  $USER_ACCOUNT:sftpadmins  id_rsa_iiNET_New_Prod.pub
                fi

                if [ -f "svc_mft_prod.pub" ]; then
                echo "[*] modifying \"svc_mft_prod.pub\" mod to 644"
                chmod  644  svc_mft_prod.pub
                echo "[*] modifying \"svc_mft_prod.pub\" user:group under \"$USER_ACCOUNT:sftpadmins\""
                chown  $USER_ACCOUNT:sftpadmins  svc_mft_prod.pub
            fi


        if [ -f "authorization" ]; then
                echo "[*] modifying \"authorization\" mod to 644"
                chmod  644  authorization
                echo "[*] modifying \"authorization\" user:group under \"$USER_ACCOUNT:sftpadmins\""
                chown  $USER_ACCOUNT:sftpadmins  authorization
        fi

        if [ -f "$CLIENT_PUB_KEY" ]; then
                echo "[*] modifying \"$CLIENT_PUB_KEY\" mod to 644"
                chmod  644  $CLIENT_PUB_KEY
                echo "[*] modifying \"$CLIENT_PUB_KEY\" user:group under \"$USER_ACCOUNT:sftpadmins\""
                chown  $USER_ACCOUNT:sftpadmins  $CLIENT_PUB_KEY
        fi

                if [ -f "$CLIENT_PUB_KEY_2" ]; then
                echo "[*] modifying \"$CLIENT_PUB_KEY_2\" mod to 644"
                chmod  644  $CLIENT_PUB_KEY_2
                echo "[*] modifying \"$CLIENT_PUB_KEY_2\" user:group under \"$USER_ACCOUNT:sftpadmins\""
                chown  $USER_ACCOUNT:sftpadmins  $CLIENT_PUB_KEY_2
        fi


        sleep 2s

        # Remove Bash Profile
        echo "[*] cleanup folder \"$USER_DIR\""
        cd /ftpserver/$USER_DIR
        echo -n "[*] "
        rm -vf .bash_logout
        echo -n "[*] "
        rm -vf .bash_profile
        echo -n "[*] "
        rm -vf .bashrc


        #Printing Propagation Commands
        echo "[*] script run successfully"
        echo

        echo "************************************"
        echo
        echo "*Run the following commands on iiNET-App08, Tectia02 and Tectia03"
        echo
        echo $create_user_cmd1
        echo
        echo $create_user_cmd2
        echo
        echo $create_user_cmd3
        echo
        echo $create_user_cmd4
        echo
        echo $create_user_cmd5
        echo
        echo "************************************"
        ;;



      2) echo "You have selected to create an AWS S3API Integration -- coming soon";;
      3) echo "You have selected to create an Azure Integration Account -- coming soon";;
      *) echo "You have selected an invalid option ";;
  esac
  exit