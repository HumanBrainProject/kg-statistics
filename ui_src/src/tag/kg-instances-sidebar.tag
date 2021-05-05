<!--
    ~ Copyright 2018 - 2021 Swiss Federal Institute of Technology Lausanne (EPFL)
    ~
    ~ Licensed under the Apache License, Version 2.0 (the "License");
    ~ you may not use this file except in compliance with the License.
    ~ You may obtain a copy of the License at
    ~
    ~ http://www.apache.org/licenses/LICENSE-2.0.
    ~
    ~ Unless required by applicable law or agreed to in writing, software
    ~ distributed under the License is distributed on an "AS IS" BASIS,
    ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    ~ See the License for the specific language governing permissions and
    ~ limitations under the License.
    ~
    ~ This open source software code was developed in part or in whole in the
    ~ Human Brain Project, funded from the European Union's Horizon 2020
    ~ Framework Programme for Research and Innovation under
    ~ Specific Grant Agreements No. 720270, No. 785907, and No. 945539
    ~ (Human Brain Project SGA1, SGA2 and SGA3).
    ~
    -->
<kg-instances-sidebar>
    <style scoped>
        :scope {
            background:#111;
            overflow-y: auto;
        }

        li {
            padding: 4px 0;
        }

        button {
            margin: 0;
            padding: 0;
            border: 0;
            background-color: transparent;
            font-size: 0.9em;
            text-decoration: underline;
            color: #d9d9d9;
            cursor: pointer;
            word-break: break-all;
        }

        button:hover {
            color: white;
        }
    </style>

    <ul>
        <li each={instance in instances} title={instance.title}><button onClick={selectInstance}>{instance.name}</button</li>
    </ul>
    
    <script>
        this.instances = [];
        this.isActive = false;
        this.isLoaded = false;

        this.on("mount", function () {
            RiotPolice.requestStore("instances", this);
        });

        this.on("update", function () {

            this.isActive = this.stores.instances.is("ACTIVE");
            this.isLoaded = this.stores.instances.is("QUERY_LOADED");
            const isLoading = this.stores.instances.is("QUERY_LOADING");

            if (!isLoading) {
                if (this.isActive && this.isLoaded)
                    this.instances = this.stores.instances.getQueryResults();
                else
                    this.instances = [];
            }
        });

        this.selectInstance = e => {
            RiotPolice.trigger("instances:select4comparison", e.item.instance);
        }
    </script>
</kg-instances-sidebar>