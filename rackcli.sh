
#!/bin/bash
####################
#
# Wrapper script to manage virtual machines in rackspace cli

####################

#rackConfig="$HOME/.rack/config"
#if [ -e ${rackConfig} ]
#then
#    echo "ok"
#else
#    echo "rack cli not yet configured "
#fi

RACKCLI=/home/centos/rack

#
function usage () {
script=$0
cat << USAGE
Manage Virtual Machines in Rackspace environment
Syntax
`basename $script` -i -l -f -C {hostname} -W {hostname} -M [{ centosHost } {ubuntuHost}]

-i: list available images
-l: list all running virtual machines
-f: list all flavors
-C: create new centos virutual machine
-U: create new ubuntu virtual machine
-W: create new windows virtual machine
-M: create multiple servers based on user input
-h: show help

USAGE
exit 1
}

#check if rack client is installed or not
function check_rack () {
type -P $RACKCLI &> /dev/null || ( echo "rack client is not installed."
    echo "Follow this link to install and configure rack client"
    echo "https://developer.rackspace.com/docs/rack-cli/configuration/"
    exit )
}

function auth_rack () {
    #Verify if the auth is sucessful
    check_rack
    $RACKCLI  servers instance list &> /dev/null && echo "Successfully authenticated with Rackspace" || ( echo "Problem authenticating with Rackspace, please check the global variables in the script"; exit 1 )
}

function create_single_centos () {
    #create centos server

    if [ $? -eq 0 ]; then
        echo "Creating CentOS 6.3 VM with 2GB MEM and 80GB Storage, this may take some time"
        $RACKCLI servers instance create --name ${SERVERNAME} --image-name "CentOS 7 (PVHVM)" --flavor-id  "general1-4"
        [ $? -eq 0 ] && echo "CentOS 7 (PVHVM) VM created successfully"
    fi
}

function create_single_windows() {
    auth_rack
    if [ $? -eq 0 ]; then
        echo "Creating windows VM, this may take some time"
        $RACKCLI servers instance create --name ${SERVERNAME} --image-name "Windows Server 2012 R2 " --flavor-id  "general1-4"
        [ $? -eq 0 ] && echo "Windows Server 2012 R2 VM created successfully"
    fi
}

function create_single_ubuntu() {
    auth_rack
    if [ $? -eq 0 ]; then
        echo "Creating Ubuntu VM, this may take some time"
        $RACKCLI servers instance create --name ${SERVERNAME} --image-name "Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)" --flavor-id "general1-4"
        [ $? -eq 0 ] && echo "Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM) VM created successfully"
    fi
}
function create_multiple_vms () {
    #evaluate regular expression

    arg="${multi[@]}"

    IFS=' ' read -r -a serverlist <<< "${arg[@]}"

    echo "Building Multiple VMs"

    for server in "${serverlist[@]}" ;do

       echo "Building VM '$server'"
       read -p "Enter the type of operating system to build (centos|ubuntu|windows): " ostype

       if echo $ostype |grep -i "^ubuntu" > /dev/null ;
       then
            imgname="Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)"
       elif echo $ostype |grep -i "^centos" > /dev/null ;
       then
            imgname="CentOS 7 (PVHVM)"
       else echo $ostype |grep -i "^windows" > /dev/null ;
            imgname="Windows Server 2012 R2"

       fi

       read -p "Flavor type (general1-1,general1-2,general1-4,general1-8,compute1-4,compute1-8,compute1-15,compute1-30,compute1-60,io1-15,io1-30,io1-60,io1-90,io1-120) : " flavor

       $RACKCLI  servers instance create --name "${server}" --image-name "${imgname}" --flavor-id "${flavor}"
       #echo " servers instance create --name ${server} --image-name \"${imgname}\" --flavor-id \"${flavor}\""
        [ $? -eq 0 ] && echo "VM ${server} having imagename $imgname created successfully"
       echo ""
   done

}


#Parse options
[ $# -eq 0 ] && usage
while getopts C:U:D:W:M:S:P:ilfh opts
do
    case $opts in
        i)
            auth_rack && ./rack servers image list
            ;;
        l)
            auth_rack && ./rack servers instance list
            ;;
        f)
            auth_rack && ./rack servers flavor list
            ;;
        C)
            #create centos server
            SERVERNAME=${OPTARG}
            create_single_centos
            ;;
        W)
            #create windows server
            SERVERNAME=${OPTARG}
            create_single_windows
            ;;
        U)
            #create ubuntu server
            SERVERNAME=${OPTARG}
            create_single_ubuntu
            ;;
        M)
            #create multiple servers
            multi+=("$OPTARG")
            create_multiple_vms "${multi[@]}"
            ;;
        D)
            #delete existing vm
            SERVERNAME=${OPTARG}
            delete_vm
            ;;

        h)
            usage
            ;;
        \?)
            usage
            ;;
    esac
done

shift $((OPTIND -1))
