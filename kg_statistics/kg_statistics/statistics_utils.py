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
import logging

from pyxus.client import NexusClient


class StatisticsUtils(object):
    """
    This class provides statistics data utilities (enhancement for example)

    """

    def __init__(self, auth_client):
        """
            Sets variable from env

        """
        self.logger = logging.getLogger(__name__)
        self.nexus = NexusClient(auth_client=auth_client)

    def enhance_statistics_with_nexus_elastic_counts(self, stats_elements):
        """
            This method query nexus in a way to get total from ES
            This method fill dict provided with retrieved information

            :return: 0 if counts from ES match input counts, 1 otherwise
        """
        self.logger.info("Started enhancing statistics with counts from nexus elastic")
        matched_number = 0
        mismatched_number = 0

        for stats_element in stats_elements:
            nexus_element = self.nexus.instances.list_by_full_subpath(stats_element['id'])
            stats_element['numberOfInstancesFromNexusElastic'] = nexus_element.total
            # count matched / mismatched for report
            if stats_element['numberOfInstances'] != nexus_element.total:
                mismatched_number += 1
                self.logger.info("Mismatch of number of instances for schema {}: {} in blazegraph, {} in elasticsearch".format(stats_element['id'], stats_element['numberOfInstances'], nexus_element.total))
            else:
                matched_number += 1
        enhance_report = "Comparison results:  total: {}  matched: {}  mismatched: {}".format(
            str(matched_number + mismatched_number),
            str(matched_number),
            str(mismatched_number))
        self.logger.debug(enhance_report)