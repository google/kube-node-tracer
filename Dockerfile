FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine                    
VOLUME ["/dump"]
RUN apk add --no-cache --update bash coreutils which curl tcpdump inotify-tools 

COPY ./kube_node_tracer.sh /
COPY ./rolling_tcpdump.sh /
COPY ./file_watcher.sh /

RUN mkdir -p /dump

RUN chmod +x /kube_node_tracer.sh
RUN chmod +x /rolling_tcpdump.sh 
RUN chmod +x /file_watcher.sh 

ENTRYPOINT ["bash", "/kube_node_tracer.sh"]
