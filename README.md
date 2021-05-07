# Kube Node Tracer

This is not an officially supported Google product.

*Authored by:* Richard Balfour (RichardBalfour)

## Overview
Troubleshooting transient/ intermittent networking issues is a tedious process, oftentimes requiring packet trace collection and analysis to determine the root-cause. The container orchestration environment Kubernetes (K8s) poses another set of challenges due to its potential scale, ephemeral nature, and layers of abstraction. 

The `Kube Node Tracer` aims to provide K8s users a tool to perform rolling packet captures on the host network namespace for nodes within a cluster for use in troubleshooting transient networking issues. To limit the impact on cluster resources, `Kube Node Tracer` automatically offloads packet capture files to a sink (ex. Google Cloud Storage) for later analysis. 

## Usage

### Required fields
`Kube Node Tracer` requires Google Cloud Storage (GCS) bucket to act as a sink for the packet traces thus the following flag is required:
- -b - GCS Bucket Name 

_Note: If using GKE the GCE VMs must have write permissions (scope) to the GCS bucket._

If running the `Kube Node Tracer` as a stand-alone container (ex. Docker) then the node name will need to be specified (See `Deployment` below):
- -N - Node name            (Note: This should be automatically retrieved from the metadata specs in DaemonSet when using K8)

### Optional fields
This tool utilizes `tcpdump` to perform rotating packet captures on the node's primary interface thus the normal flags can be tuned based on requirements:

- -s - Snap length          (Default: 96 B)
- -B - Buffer Size          (Default: 1000 B)         
- -C - File Size            (Default: 100 MB)           
- -W - File Count           (Default: 100)                     

- -f - Filter               (Note: This is a wrapper around tcpdump filter)
- -i - Interface            (Default: Primary NIC)
- -G - Rotate Seconds  


## Deployment

To build `Kube Node Tracer` simply run the following `docker` command to build an image using the Dockerfile: 
```
docker build -t kube-node-tracer . 	
```

`Kube Node Tracer` should be deployed as priviled DaemonSet which operates in the host network namespace. See /examples for sample DaemonSet.

If runnung `Kube Node Tracer` as a stand-alone container using Docker the --network flag will neeed to be set to `host` as follows:
```
docker run -dt --network host --name <CONTAINER-NAME> kube-node-tracer -N <NODE-NAME> -b <GCS-BUCKET-NAME>
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for details.

## License

Apache 2.0; see [`LICENSE`](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by
Google and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
