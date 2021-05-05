#!/bin/bash
#
# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Script arguments
##tcpdump arguments           
interface=' '   
filter=''                   #Generic tcpdump filter (Optional)
snaplen='96'                #Snap length (-s)
buffer_size='1000'          #Buffer size in Bytes (-B)
filesize_MB='100'           #File size in MegaBytes (Note: filesize_MB (-C) should be << volume storage )
filecount='100'             #File count (-W)  Note: This is what implements rolling.
rotate_seconds=''           #Pcap file rotation in Seconds (-G) (Optional) Note: This implements time slicing (Optional)
output_dir='./dump/'        #The mountPath directory for GKE DaemonSet. Note this is not file name as that is based on the node name.


###Note:    The rolling tcpdump depends on: filesize_MB (-C) AND filecount (-W) with rotate_seconds (-G) as an optional parameter
###         A tcpdump file will be created when  the file size reaches 'filesize_MB' for every 'rotate_seconds'  meaning each file will 
###         have an upper-bound size of 'filesize_MB'. The files wil be overwitten (ie. rolled) every 'filecount'. For example a 'filesize_MD' 
###         = 1000 and 'filecount' = 100 would require a MAXIMUM of 100GB of storage.

##GKE arguments
nodename="gke-node-test"    #Name of GKE worker node -- this is retreived from the cluster metadata

while getopts i:f:B:s:C:W:G:o:N: flag
do
    case "${flag}" in
        i) interface=${OPTARG};;
        f) filter=${OPTARG};;
        B) buffer_size=${OPTARG};;
        s) snaplen=${OPTARG};;
        C) filesize_MB=${OPTARG};;
        W) filecount=${OPTARG};;
        G) rotate_seconds=${OPTARG};;
        o) output_dir=${OPTARG};;
        N) nodename=${OPTARG};;
    esac
done

##Computed tcpdump arguments 
##Grep the primary network interface -- if no interface is provided in the arguments
if [ -z "$interface" ] || [ "$interface" = 'X' ]; then 
    interface="`tcpdump -D | awk -F"." '/1\./ { print $2}' | awk '{ print $1 }'`"                #Network interface -- GKE only uses a single interface for its nodes
    echo "Node interface not specified in arguments. Automatically capturing on node interface: ${interface}"
    echo ""
fi


##Computed GKE arguments
if [ -z "$filecount" ]; then                    #If the 'filecount' (-W) isn't specified then date-time format otherwise the file cannot be time formatted
    pcap_file="${nodename}-%Y%m%d%H%M%S.pcap"
else
    pcap_file="${nodename}.pcap"                #File counts are automatically appended to file name when 'filecount' (-W) is specified.
fi
pcap_file_path="${output_dir}${pcap_file}"

#If -W or -G is specified 
if [ -z "$rotate_seconds" ]; then                    #If the 'rotate_seconds' (-G) isn't specified then ommit the -G flag
    echo "File count    : ${filecount}"
    echo "Rotate time is not specified."
    echo "---------------------------------------"
    echo "Node name     : ${nodename}"
    echo "Node interface: ${interface}"
    echo "Buffer size   : ${buffer_size} B"
    echo "Snap length   : ${snaplen}"
    echo "File size     : ${filesize_MB} MB"
    echo "File count    : ${filecount}"
    echo ""

    tcpdump -i $interface $filter -s $snaplen -B $buffer_size -C $filesize_MB -W $filecount  -w $pcap_file_path 
else
    echo "File count    : ${filecount}"
    echo "Rotate time   : ${rotate_seconds} seconds"
    echo "---------------------------------------"
    echo "Node name     : ${nodename}"
    echo "Node interface: ${interface}"
    echo "Buffer size   : ${buffer_size} B"
    echo "Snap length   : ${snaplen}"
    echo "File size     : ${filesize_MB} MB"
    echo "File count    : ${filecount}"
    echo ""
    
    tcpdump -i $interface $filter -s $snaplen -B $buffer_size -C $filesize_MB -W $filecount -w $pcap_file_path -G $rotate_seconds
fi
