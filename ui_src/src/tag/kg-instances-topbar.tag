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
<kg-instances-topbar>
    <style scoped>
        :scope {
            background-color:#222;
        }

        h2 {
            margin-left: 20px;
        }

        button.close {
            position: absolute;
            top: 6px;
            right: 6px;
            width: 50px;
            height: 50px;
            border: 0;
            margin: 0;
            background-color: transparent;
            color: #93999f;
            font-size: 20px;
            text-align: center;
            transition: background-color 0.2s ease-in, color 0.2s ease-in, box-shadow 0.2s ease-in, color 0.2s ease-in, -webkit-box-shadow 0.2s ease-in;
            z-index: 500;
            cursor: pointer;
        }

        button.close:hover {
            box-shadow: 3px 3px 6px black;
            background-color: #292929;
            color: white;
        }

        button.close:after{
            display: none;
            content: "esc";
            position: absolute;
            transform: translate(-16px, 14px);
            font-size: 12px;
            color: #93999f;
        }

    </style>

    <h2 if={isActive} title={schema.id}>{schema.label}</h2>
    <button class="close" onclick={close}><i class="fa fa-close"></i></button>
    
    <script>
        this.schema = null;
        this.isActive = false;

        this.on("mount", function () {
            RiotPolice.requestStore("instances", this);
        });

        this.on("update", function () {
            this.isActive = this.stores.instances.is("ACTIVE");
            const isLoading = this.stores.instances.is("QUERY_LOADING");

            if (!isLoading || this.schema === null) {
                if (this.isActive)
                    this.schema = this.stores.instances.getQuerySchema();
                else
                    this.schema = null;
            }
        });

        this.close = e => RiotPolice.trigger("instances:close");

    </script>
</kg-instances-topbar>