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
import os
from openid_http_client.auth_client.simple_refresh_token_client import SimpleRefreshTokenClient
from kg_statistics.fetch_statistics import StatisticsFetcher
from kg_statistics.config import Config
from logging.config import fileConfig
fileConfig(os.path.join(os.path.dirname(__file__), "logging.conf"))

# create auth_client
oidc_config = Config.get_oidc_configuration()
refresh_token_client = SimpleRefreshTokenClient(oidc_config["openid_host"], oidc_config["client_secret"],
                                                oidc_config["client_id"], oidc_config["refresh_token"])
StatisticsFetcher().get_statistics(refresh_token_client)
