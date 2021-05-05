#  Copyright 2018 - 2021 Swiss Federal Institute of Technology Lausanne (EPFL)
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0.
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  This open source software code was developed in part or in whole in the
#  Human Brain Project, funded from the European Union's Horizon 2020
#  Framework Programme for Research and Innovation under
#  Specific Grant Agreements No. 720270, No. 785907, and No. 945539
#  (Human Brain Project SGA1, SGA2 and SGA3).
#

import os
import json


class Config(object):
    @staticmethod
    def get_deploy_path():
        return os.getenv("STATISTICS_DEPLOYPATH", "ui")

    @staticmethod
    def get_configuration():
        with open(os.path.join(os.path.dirname(__file__), "configuration.json")) as global_config_file:
            config = json.load(global_config_file)
        return config

    @staticmethod
    def get_oidc_configuration():
        with open(Config.get_configuration()["oidc_config"]) as oidc_conf_file:
            oidc_config = json.load(oidc_conf_file)
        return oidc_config
