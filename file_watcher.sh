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
# Description: Filesystem monitoring mechanism which compresses pcap files and exports to a sink for archival (ex. Google Cloud Storage).

#Script arguments
gcsbucket=''                                    #Google Cloud Storage bucket 
nodename=''                                     #Kubernetes node name 
compress='true'                                 #Optional cpression using Gzip
output_dir='./dump/'                            #Intermediary output path for pcap files which should be mounted to a Kubernetes persistent storage volume as to not consume cluster resources

while getopts b:c:o:N: flag 
do
  case "${flag}" in
    b) gcsbucket=${OPTARG};;
    c) compress=${OPTARG};;
    o) output_dir=${OPTARG};;
    N) nodename=${OPTARG};;
  esac
done

#Console output messages
echo "Listening for new pcap files in directory ${output_dir}..."
if [ $compress == 'true' ]; then
  echo "Files will be compressed using gzip."
fi
echo ""

#Start listening for new files
inotifywait -m -e close_write \
$output_dir |
  while read path action file dir; do
    if [[ "$file" =~ .*pcap[0-9]*$ ]]; then     #Only perform actions on .pcap files 
      echo "Packet capture file: ${file}" 

      if [ $compress == 'true' ];             #Compress the file if specifed 
      then
        echo "Compressing packet capture file: ${file}"
        gzip ${path}${file}

        echo "Copying file ${file}.gz to GCS bucket"
        gsutil cp ${path}${file}.gz gs://$gcsbucket/$nodename/

        echo "Deleting file ${file}.gz from ${path}"
        rm ${path}${file}.gz
      else
        echo "Copying file ${file} to GCS bucket"
        gsutil cp ${path}${file} gs://$gcsbucket/$nodename/

        echo "Deleting file ${file} from ${path}"
        rm ${path}${file}
      fi      
    fi
  done