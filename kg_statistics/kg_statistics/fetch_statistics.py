#
#  Copyright (c) 2018, EPFL/Human Brain Project PCO
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
import json
import os
import re

import time
import logging

from pyxus.utils.blazegraph import BlazegraphClient

from kg_statistics.config import Config
from kg_statistics.statistics_utils import StatisticsUtils


class StatisticsFetcher(object):
    """
    This class fetch data from the blazegraph API and extract statistics from it

    """

    blazegraph = BlazegraphClient()

    current_milli_time = lambda self: int(round(time.time() * 1000))

    def __init__(self):
        self.logger = logging.getLogger(__name__)

    def _fetch_typestatistics(self):
        """
        Fetch the types sparql query

        :return: A json object with the result from blazegraph
        """
        with open(os.path.join(os.path.dirname(__file__), "fetch_types.sparql"), "r") as query_file:
            type_query = query_file.read()
            type_query = re.sub(r'^(?=#).+\n', "", type_query, flags=re.MULTILINE)
            type_query = type_query.replace("$NEXUS_BASE", self.blazegraph.NEXUS_NAMESPACE)
        return self.blazegraph.query(type_query)

    def _format_typestatistics(self, type_result):
        """
        Format the result of the _fetch_typestatitics method.

        :param type_result: the result of the _fetch_typestatitics method
        :return: A dictionary of the formatted data
        """
        if type_result is not None:
            target_object = dict()
            target_object["nodes"] = list()
            for schema in type_result:
                name = self._remove_prefix(schema["schema"]["value"])
                structure = re.match(r"(?P<org>.*?)/.*?/(?P<schema>.*?)/(?P<version>.*?)(/.*)?$", name)
                label = "{} ({})".format(structure.group("schema").capitalize(),
                                         structure.group("version"))
                result = dict()
                result["id"] = name
                result["label"] = label
                result["group"] = structure.group("org").lower()
                result["numberOfInstances"] = int(schema["numberOfInstances"]["value"])
                result["schema"], result["version"] = extract_version(name)
                target_object["nodes"].append(result)
            return target_object
        return None

    def _fetch_typerelationstatistics(self):
        """
        Fetch statistics about the relations between entities

        :return: a list of object in the shape:

            .. code-block:: javascript

                {
                    source: source_schema_name,
                    target: target_schema_name,
                    value: number of links between entities with schema source
                    to entities with the schema target
                }
        """
        with open(os.path.join(os.path.dirname(__file__), "fetch_relations.sparql"), "r") as query_file:
            type_query = query_file.read()
            type_query = re.sub(r'^(?=#).+\n', "", type_query, flags=re.MULTILINE)
            type_query = type_query.replace("$NEXUS_BASE", self.blazegraph.NEXUS_NAMESPACE)

        type_result = self.blazegraph.query(type_query)
        target_objects = list()
        for schema in type_result:
            result = dict()
            result["source"] = self._remove_prefix(schema["originSchema"]["value"])
            result["target"] = self._remove_prefix(schema["targetSchema"]["value"])
            structure_source = re.match(r"(?P<org>.*?)/.*?/(?P<schema>.*?)/(?P<version>.*?)(/.*)?$", result["source"])
            structure_target = re.match(r"(?P<org>.*?)/.*?/(?P<schema>.*?)/(?P<version>.*?)(/.*)?$", result["target"])
            result["source_group"] = structure_source.group("org").lower()
            result["target_group"] = structure_target.group("org").lower()
            result["name"] = schema["rel"]["value"]
            result["value"] = int(schema["numberOfRelations"]["value"])
            result["id"] = result["source"]+"_"+result["target"]
            target_objects.append(result)
        return target_objects

    def _fetch_typeproperties(self, schemas):
        """
        Fetch properties of all entities

        :return: a dict in the shape:

            .. code-block:: javascript

                {
                    "schema_name": {
                        "schema_version": {
                            "properties": [
                                {
                                    "examples": [
                                        example1,
                                        example2,
                                        example3
                                    ],
                                    "isInSchema": true/false,
                                    "instancesWithoutProp": # of instances without this property,
                                    "name": fullname of the property,
                                    "numberOfInstances": # of times this property is encountered
                                }
                            ]
                        }
                    }
                }
        """

        with open(os.path.join(os.path.dirname(__file__), "fetch_properties.sparql"), "r") as query_file:
            main_query = query_file.read()
            main_query = re.sub(r'^(?=#).+\n', "", main_query, flags=re.MULTILINE)
            main_query = main_query.replace("$NEXUS_BASE", self.blazegraph.NEXUS_NAMESPACE)

        with open(os.path.join(os.path.dirname(__file__), "fetch_propertyless.sparql"),
                  "r") as query_file:
            property_less_query = query_file.read()
            property_less_query = re.sub(r'^(?=#).+\n', "", property_less_query, flags=re.MULTILINE)
            property_less_query = property_less_query.replace("$NEXUS_BASE", self.blazegraph.NEXUS_NAMESPACE)

        target_objects = dict()
        for schema in schemas:
            schema_name = self._remove_prefix(schema["schema"]["value"])
            schema_name, version = extract_version(schema_name)
            formatted_schema = "<{}>".format(schema["schema"]["value"])
            type_result = self.blazegraph.query(main_query.replace("$SCHEMA", formatted_schema))
            for property in type_result:
                prop = dict()
                prop["fullname"] = property["property"]["value"]
                name = property["property"]["value"].replace(
                    self.blazegraph.NEXUS_NAMESPACE+"/vocabs/nexus/core/terms/v0.1.0/", "")
                prop["name"] = name
                prop["numberOfInstances"] = int(property["count"]["value"])
                prop["isInSchema"] = False
                examples = property["example"]["value"].split(";")[:3]
                prop["examples"] = [x.strip() for x in examples]

                if schema_name not in target_objects:
                    target_objects[schema_name] = dict()
                if version not in target_objects[schema_name]:
                    target_objects[schema_name][version] = dict({"properties_dict": dict(),
                                                                 "properties": list()})
                target_objects[schema_name][version]["properties_dict"][name] = prop

        # Fetching properties that are not in instances


            property_less_result = self.blazegraph.query(property_less_query.replace("$SCHEMA", formatted_schema))

            #Combining data
            for property_not_bound in property_less_result:
                name = property_not_bound["property"]["value"].replace(
                    self.blazegraph.NEXUS_NAMESPACE+"/vocabs/nexus/core/terms/v0.1.0/", "")
                target_objects[schema_name][version]["properties_dict"][name][
                    "instancesWithoutProp"] = int(property_not_bound["count"]["value"])

        for schema_name in target_objects:
            for version in target_objects[schema_name]:
                for propkey in target_objects[schema_name][version]["properties_dict"]:
                    target_objects[schema_name][version]["properties"] \
                        .append(target_objects[schema_name][version]["properties_dict"][propkey])

        return target_objects

    def _remove_prefix(self, string):
        """
        Removes the prefix of a reference to an entity

        :param string: The reference to the entity
        :return: the reference whithout the name space and /schemas/

        """
        # pylint: disable=no-self-use
        return string.replace(self.blazegraph.NEXUS_NAMESPACE+"/v0/schemas/", "")

    def get_statistics(self, auth_client):
        """
        This method is the entry point of fetch_statistics
        It is called by the Scheduler

        This method gather all the statistics and print them in a single json object in a file
        Statistics contain details from sparql query and nexus list service

        :return: stats enhancement status or 2 if stats cannot be updated
                 0 -> success
                 1 -> stats enhancement counts discrepancy
                 2 -> stats cannot be updated
        """
        print("Start fetch types")
        type_results = self._fetch_typestatistics()
        nodes = self._format_typestatistics(type_results)
        if nodes is not None:
            self.logger.debug("output path: {}".format(Config.get_deploy_path()))
            self.logger.debug("Start fetch relations")
            nodes["links"] = self._fetch_typerelationstatistics()
            self.logger.debug("Start fetch properties")     
            nodes["schemas"] = self._fetch_typeproperties(type_results)
            nodes["lastUpdate"] = self.current_milli_time()

            # enhance statistics in place
            StatisticsUtils(auth_client).enhance_statistics_with_nexus_elastic_counts(nodes['nodes'])

            if not os.path.exists(Config.get_deploy_path()):
                os.makedirs(Config.get_deploy_path())
            with open(
                os.path.join(Config.get_deploy_path(), "structure.json"), "w"
            ) as json_file:
                json_file.write(json.dumps(nodes, indent=4))
                self.logger.debug("Statistics updated")
        else:
            self.logger.error("Statistics could not be updated")
            return 2
        return 0

def extract_version(string):
    """
    Extract the name and the version of a reference to an entity

    :param string: The reference to the entity
    :return: a tuple with the fully qualfied name and the version of the entity

    """
    version = re.search(".*/.*/.*/(.*)", string, re.IGNORECASE)
    name = re.search("(.*/.*/.*)/.*", string, re.IGNORECASE)
    return name.group(1), version.group(1)
