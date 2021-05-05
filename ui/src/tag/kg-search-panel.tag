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
<kg-search-panel>
    <style scoped>
         :scope {
            display: block;
            position: relative;
            width: 100%;
            height: 100%;
            padding: 15px;
            background: #111;
            color:white;
        }

        .panel {
            display: flex;
            flex-direction: column;
            height: 100%;
            border: 1px solid #444;
            border-radius: 5px 5px 0 0;
        }

        .searchbox {
            padding: 15px;
        }

        .searchbox input {
            appearance: none;
            -webkit-appearance: none;
            width: 100%;
            padding: 0 8px 0 30px;
            background: #333;
            border: #ccc;
            outline: none;
            border-radius: 5px;
            height: 30px;
            line-height: 30px;
            color: white;
            font-size: 16px;
        }

        .searchbox i {
            position: absolute;
            top: 37px;
            left: 38px;
        }

        .results{
            flex: 1;
            padding: 15px;
            border-top: 1px solid #444;
        }

        .scroll {
            overflow-y: auto;
        }
        
        .scroll::-webkit-scrollbar-track{
            -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.3);
            background-color: #222;
        }

        .scroll::-webkit-scrollbar {
            width: 10px; /* 8px */
            background-color: #F5F5F5;
        }

        .scroll::-webkit-scrollbar-thumb {
            background-color: #000000;
            /* border: 1px solid #222; */
            border-radius: 5px;
        }

        ul {
            margin: 0;
            padding: 0;
            list-style: none;
            font-size: 0.8em;
        }

        li {
            padding: 3px 0;
            line-height: 1;
        }

        .occurrences {    
            display: inline-block;
            min-width: 21px;
            margin-left: 3px;
            padding: 3px 6px;
            border-radius: 12px;
            background-color: #444;
            font-size: 10px;
            text-align: center;
            font-weight: bold;
            line-height: 1.2;
        }

        .no-results{
            font-style:italic;
        }

        .disabled{
            text-decoration: line-through;
            color:#aaa;
        }
    </style>

    <div class="panel">
        <div class="searchbox">
            <input type="text" ref="query" onkeyup={doSearch}>
            <i class="fa fa-search" aria-hidden="true"></i>
        </div>
        <div class="results scroll">
            <ul if={results.length > 0}>
                <li each={type in results}>
                    <i class="fa fa-flag" if={type.isProvenance} title="is a provenance"></i>
                    <a href="#" onclick={selectType} onmouseover={highlightType} onmouseout={unhighlightType} title={type.id}>{type.name}</a>
                    <span class="occurrences">{type.occurrences}</span>
                </li>
            </ul>
            <div class="no-results" if={results.length <= 1 && !!refs.query.value.length}>
                No type matches your search!
            </div>
        </div>
    </div>

    <script>
        this.selectedType = undefined;
        this.lastUpdate = undefined;
        this.results = [];

        this.on("mount", () => {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
            this.update();
        });

        this.on("unmount", () => {
            RiotPolice.off("structure.changed", this.update);
            RiotPolice.releaseStore("structure", this);
        });

        this.on("update", () => {
            this.results = this.stores.structure.getSearchResults();
            const previousLastUpdate = this.lastUpdate;
            this.lastUpdate = this.stores.structure.getLastUpdate();
            const previousSelectedType = this.selectedType;
            this.selectedType = this.stores.structure.getSelectedType();

            if (this.lastUpdate !== previousLastUpdate || this.selectedType !== previousSelectedType) {
                this.refs.query.value = this.stores.structure.getSearchQuery();
            }

            if(!this.stores.structure.is("TYPE_DETAILS_SHOW")){
                this.refs.query.focus();
            }
        });

        this.doSearch = () => {
            RiotPolice.trigger("structure:search", this.refs.query.value);
        };

        this.selectType = e => {
            RiotPolice.trigger("structure:type_select", e.item.type.id);
        };

        this.highlightType = e => {
            RiotPolice.trigger("structure:type_highlight", e.item.type.id);
        };
        
        this.unhighlightType = e => {
            RiotPolice.trigger("structure:type_highlight");
        };
    </script>
</kg-search-panel>