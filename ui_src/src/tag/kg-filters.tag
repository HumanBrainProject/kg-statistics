<!-- 
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
-->
<kg-filters>
    <style scoped>
         :scope {
            display: flex;
            flex-direction: column;
            position: relative;
            height: 100%;
            background: #111;
            color:white;
        }

        :scope > div {
          padding: 15px;
        }

        kg-search-panel {
            flex: 4;
            overflow: hidden;
            padding: 0 15px;
        }

        kg-spaces-toggles {
            flex: 1;
            overflow: hidden;
            padding: 15px 15px 0 15px;
        }

    </style>

        <div>
          <kg-view-mode></kg-view-mode>
        </div>
        <kg-search-panel></kg-search-panel>
        <kg-spaces-toggles></kg-spaces-toggles>
        <div>
        </div>

</kg-filters>