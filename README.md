This project offers representation of the knowledge graph

The data represented in the UI are extracted from the structure.json file.

This files is generated at a regular interval by the scheduler in the /ui folder.


## Repo
https://github.com/HumanBrainProject/kg-statistics


## Build
To build the frontend run the following commands

```
npm install -g gulp-cli
cd ui_src
npm install
gulp build
```
This will create all the files needed in the /ui folder


## Run
In order to run locally the statistics project run the following commands inside ui_src

```
gulp
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
