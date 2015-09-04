#!/bin/bash
function menu
{
    CHOICE=$(whiptail --title "MENU" --menu "Please choose an option:" 15 40 5 \
    1 "Server Info" \
    2 "Apache Restart" \
    3 "MySQL Restart" \
    4 "Server Restart"  3>&1 1>&2 2>&3)
    case $CHOICE in
        1)    htop
              menu
        ;;
        2)    sudo apache2ctl restart;
              if [ $? == 0 ]; then
                  for i in `seq 0 100`;  do
                    echo $i; sleep 0.1; done | whiptail --gauge "Restarting..." 10 50 0;
              fi
              menu
        ;;
        3)    sudo /etc/init.d/mysql restart;
              if [ $? == 0 ]; then
                  for i in `seq 0 100`;  do
                    echo $i; sleep 0.1; done | whiptail --gauge "Restarting..." 10 50 0;
              fi
              menu
        ;;
        4)    whiptail --yesno "Are you sure you want to restart?" 10 60 --title "Server Restart" --defaultno;
              if [ $? == 0 ]; then
                reboot;
                echo "Restarting Server...";
              else
                menu
              fi
        ;;
          *)  echo "Exit." ;;
    esac
}
menu
echo "Login out...";
exit;
