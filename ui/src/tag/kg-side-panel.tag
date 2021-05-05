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
<kg-side-panel>
    <style scoped>
        :scope{
            position: relative;
            width: 100%;
            height:100%;
            display: flex;
            flex-direction: column;
            padding: 15px;
            background: #111;
            color:white;
        }

        :scope > * + * {
            padding-top: 6px;
        }
        
        kg-tabs {
            flex: 3;
            overflow: hidden;
            padding: 15px 0 0 0;
        }

        kg-spaces-toggles {
            flex: 1;
            overflow: hidden;
            padding: 15px 0 9px 0;
        }

    </style>

    <kg-stage-toggle></kg-stage-toggle>
    <kg-tabs></kg-tabs>
    <kg-spaces-toggles></kg-spaces-toggles>
    <kg-provenance-toggle></kg-provenance-toggle>
    <kg-intra-space-links-toggle></kg-intra-space-links-toggle>
    <kg-extra-space-links-toggle></kg-extra-space-links-toggle>

</kg-side-panel>