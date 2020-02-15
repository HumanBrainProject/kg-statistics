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
<kg-search-panel>
    <style scoped>
         :scope.open {
            right: var(--sidebar-width);
            z-index:10;
        }

         :scope {
            padding: 15px 15px;
            color:white;
        }

        button.open-panel {
            position: absolute;
            top: 10px;
            left: -40px;
            width: 40px;
            height: 40px;
            line-height: 40px;
            background: #222;
            border-radius: 10px 0 0 10px;
            appearance: none;
            -webkit-appearance: none;
            border: none;
            outline: none;
            font-size: 20px;
            color: #ccc;
            padding: 0;
            margin: 0;
            text-align:center;
        }

        .searchbox {
            appearance: none;
            -webkit-appearance: none;
            width: 100%;
            padding: 0 8px;
            background: #333;
            border: #ccc;
            outline: none;
            border-radius: 5px;
            height: 30px;
            line-height: 30px;
            color: white;
            font-size: 16px;
        }

        .results{
            margin-top: 15px;
            max-height:calc(100% - 45px);
            overflow-y:auto;
        }

        ul {
            font-size: 0.8em;
            padding-left: 0;
            list-style: none;
        }

        li {
            padding: 3px 0;
            line-height: 1;
        }

        .occurrences {
            background-color: #444;
            display: inline-block;   
            min-width: 21px;
            margin-left: 3px;
            padding: 3px 6px;
            border-radius: 12px;
            font-size: 10px;
            text-align: center;
            font-weight:bold;
            line-height:1.2;
        }

        .no-results{
            font-size:1.1em;
            font-style:italic;
            margin-top:15px;
        }
        .disabled{
            text-decoration: line-through;
            color:#aaa;
        }
    </style>

    <button class="open-panel" onclick={togglePanel}>
        <i class="fa fa-search" aria-hidden="true"></i>
    </button>

    <input type="text" class="searchbox" ref="query" onkeyup={doSearch}>
    
    <div class="results" if={results.length > 0}>
        <div class="title">
            Results
        </div>
        <ul>
            <li each={result in results}>
                <a class={"disabled": hiddenTypes.indexOf(result.id) !== -1} href="#" onclick={selectResult} onmouseover={highlightType} onmouseout={unhighlightType}>{result.id}</a>
                <span class="occurrences">{result.occurrences}</span>
            </li>
        </ul>
    </div>

    <div class="no-results" if={!results.length && !!query}>
        Nothing found
    </div>

    <script>
        this.query = "";
        this.results = [];
        this.hiddenTypes = [];

        this.on("mount", function () {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });

        this.on("update", function () {
            this.results = _.orderBy(this.stores.structure.getSearchResults(), result => result.occurrences,'desc');
            this.query = this.stores.structure.getSearchQuery();
            this.hiddenTypes = this.stores.structure.getHiddenTypes();

            if(this.stores.structure.is("SEARCH_ACTIVE")){
                if(!$(this.root).hasClass("open")){
                    $(this.root).addClass("open");
                    $(this.refs.query).focus();
                }
            } else {
                if($(this.root).hasClass("open")){
                    $(this.root).removeClass("open");
                }
            }
        });

        this.togglePanel = () => {
            RiotPolice.trigger("structure:search_toggle");
        };

        this.doSearch = () => {
            RiotPolice.trigger("structure:search", this.refs.query.value);
        };

        this.selectResult = e => {
            RiotPolice.trigger("structure:type_select", e.item.result);
        };

        this.highlightType = e => {
            RiotPolice.trigger("structure:type_highlight", e.item.result);
        };
        
        this.unhighlightType = e => {
            RiotPolice.trigger("structure:type_unhighlight");
        };
    </script>
</kg-search-panel>