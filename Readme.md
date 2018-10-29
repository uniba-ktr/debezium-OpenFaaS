# Change detection with Debezium

## Setup

### Prerequisites
Install Docker, docker-compose and OpenFaaS to get the examples running on a Linux OS within an Swarm enbabled Docker instance.
Forward the domain <code>docker.fun</code> and all of its subdomains <code>*.docker.fun</code> to the address of your Swarm manager node.

### Setup
Use <code>deploy.sh</code> to initialize all stacks:
 - First call <code>./deploy.sh all</code> to setup all stacks in a Docker Swarm
 - After all services are up and running, call <code>./deploy.sh connect</code> to interconnect the Debezium with the sample DB and start the functions.
 
## Access

Goto http://docker.fun to access all web based user interfaces.
