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
#
# Description: Main bash entry point for Kube Node Tracer 

#Script arguments
mountPath='./dump/'                             #Intermediary output path for pcap files which should be mounted to a Kubernetes persistent storage volume as to not consume cluster resources
gcsbucket=''                                    #Google Cloud Storage bucket 
nodename=''                                     #Kubernetes node name (ex. kube-node-test)
compress='true'                                 #Optional cpression using Gzip

##tcpdump arguments  
interface='X'                                   #Network interface -- Kubernetes only uses a single interface for its nodes
filter=''                                       #Generic tcpdump filter (Optional)
snaplen='96'                                    #Snap length (-s)
buffer_size='1000'                              #Buffer size in Bytes (-B)
filesize_MB='100'                               #File size in MegaBytes (Note: filesize_MD (-C) should be << volume storage )
filecount='100'                                 #File count (-W) Note: This is what implements rolling.
rotate_seconds=''                               #Pcap file rotation in Seconds (-G) (Optional) Note: This implements time slicing 

while getopts b:c:o:N:i:f:B:s:C:W:G: flag 
do
  case "${flag}" in
    b) gcsbucket=${OPTARG};;
    c) compress=${OPTARG};;
    o) output_dir=${OPTARG};;
    N) nodename=${OPTARG};;

    i) interface=${OPTARG};;
    f) filter=${OPTARG};;
    B) buffer_size=${OPTARG};;
    s) snaplen=${OPTARG};;
    C) filesize_MB=${OPTARG};;
    W) filecount=${OPTARG};;
    G) rotate_seconds=${OPTARG};;
  esac
done

#Check if the required arguments have been provided (ie. nodename and gcsbucket)
function err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

if [ -z "$nodename" ]; then 
  err 'A Kubernetes node name must be supplied. Killing process.' 
  exit 1
fi

if [ -z "$gcsbucket" ]; then 
  err 'A Google Cloud Storage bucket must be avaliable to store pcap files. Killing process.'
  exit 1
fi

# TODO: Test if the GCS bucket exists and if the VM has write privledges. If not kill the process. 

#Start the file watcher script and run as a background process
bash ./file_watcher.sh -o $mountPath -N $nodename -b $gcsbucket -c $compress &

#Start the rolling tcpdump script
if [ -z "$rotate_seconds" ]; then 
  bash ./rolling_tcpdump.sh -o $mountPath -N $nodename -i $interface -s $snaplen -B $buffer_size -C $filesize_MB -W $filecount -f $filter 
else
  bash ./rolling_tcpdump.sh -o $mountPath -N $nodename -i $interface -s $snaplen -B $buffer_size -C $filesize_MB -W $filecount -G $rotate_seconds -f $filter 
fi