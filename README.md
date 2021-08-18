This project offers representation of the knowledge graph.

## Repo
https://github.com/HumanBrainProject/kg-statistics


## Build
To build the frontend run the following commands

```
npm install -g gulp-cli
cd ui
npm install
npm build
```
This will create all the files needed in the /ui folder


## Run
In order to run locally the statistics project run the following commands inside ui

```
npm start
```

This will start a local node server on the port 8000

## Build the docker

```
docker build . --tag kg-statistics:1.0.0
```

## Run the container

```
docker run -d --publish 80:80 kg-statistics:1.0.0
```
