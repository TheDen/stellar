# Stellar Graph Analytics

Stellar is a graph analytics platform designed for running algorithms on large scale graph data. It supports data integration, entity resolution, machine learning on graphs and visualisation.

## Features

* Data Integration
* Node Embedding for Machine Learning (Node2Vec)
* Graph Convolutional Networks (GCN)
* Entity Resolution
* Graphs searchable through ElasticSearch
* Dockerized containers for orchestration
* Apache Nifi for coordination
* Web UI for Data Integration
* Python Client

## Overview

Stellar is designed to:

* Merge data into a graph
* Run search, machine learning, and entity resolution across the graph
* Visualise results

This repository is the prototype release for the Stellar platform. The current limitations are as follows:

* Single User
* Single Machine
* 50,000 nodes
* CSV data only
* Numeric values for machine learning
* No missing values for machine learning
* Fixed datasets for entity resolution
* Web UI focused only on integration
* Data Visualisation in Gephi

## Running

Stellar is a collection of Docker containers coordinated with Apache Nifi. The collection of docker containers are built from the following repositories:

* [Coordinator](https://github.com/data61/stellar-coordinator)
* [Data Integration](https://github.com/data61/stellar-ingest)
* [Search](https://github.com/data61/stellar-search)
* [Entity Resolution](https://github.com/data61/stellar-ERBaseline)
* [Machine Learning](https://github.com/data61/stellar-evaluation-plugins)
* [Web UI](https://github.com/data61/stellar-config)
* [Python Client](https://github.com/data61/stellar-py)

This GitHub repository uses Docker Compose to download and launch the Docker containers. The containers are downloaded from DockerHub in the [Data61 repository](https://hub.docker.com/r/data61).

### Server Install

To install Stellar, first install the backend server as described [here](./doc/server.md). To run Stellar locally on the server machine, you can then use Stellar through the Python client or Web UI as described [here](./doc/client.md). Alternatively you can connect remotely to the machine and use a local client, as described [here](./doc/remote.md)

### AWS
A reference server exists on AWS with a pre-configured Stellar installation. Documentation for the reference AWS install is available
[here](./doc/aws.md)

## License

Copyright (c) 2017-2018 [CSIRO Data61](http://data61.csiro.au/)

Licensed under the Apache License, Version 2.0 (the "License"); you may not
use the files included in this repository except in compliance with the
License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
License for the specific language governing permissions and limitations under
the License.
