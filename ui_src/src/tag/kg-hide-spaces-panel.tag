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
<kg-hide-spaces-panel>
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
            top: 110px;
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

        .open-panel .bubble{
            position:absolute;
            display:block;
            background-color:#444;
            border-radius:10px;
            height:15px;
            line-height:15px;
            font-size:10px;
            font-weight:bold;
            top:5px;
            right:5px;
            padding:0 4px;
        }

        .schemas{
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

        .numberOfInstances {
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

        .spacelist{
            margin-top: 0;
            max-height:calc(100% - 51px);
            overflow-y:auto;
        }

        .disabled{
            text-decoration: line-through;
            color:#aaa;
        }

        .actions {
            overflow:hidden;
            margin-top:15px;
        }
        .actions button{
            width:50%;
            height:30px;
            line-height:30px;
            padding:0;
            font-size:14px;
            display:block;
            float:left;
            -webkit-appearance:none;
            appearance:none;
            background:#111;
            color:white;
            border:0;
            border-radius: 5px;
            transition:background-color 0.25s ease-out;
            cursor:pointer;
            outline:none;
        }
        .actions button:hover{
            background:#333;
        }

        .reverse{
            transform: rotate(180deg);
        }
    </style>

    <button class="open-panel" onclick={togglePanel}>
        <i class="fa fa-share-alt reverse" aria-hidden="true"></i>
        <span class="bubble">{hiddenSpaces.length}</span>
    </button>
    
    <div class="title">
        Spaces visibility
        <div class="actions">
            <button class="show-all" onclick={showAll}>Show all</button>
        </div>
    </div>

    <div class="spacelist">
        <ul>
            <li each={space in Array.from(spaces)}>
                <a class={"disabled": space.hidden} href="#" onclick={toggleHide} onmouseover={highlightSpace} onmouseout={unhighlightSpace}>
                    {space.name}
                </a>
                <span class="numberOfInstances">{space.length}</span>
            </li>
        </ul>
    </div>

    <script>
        this.query = "";
        this.results = [];
        this.hiddenSpaces = [];
        this.spaces = [];

        function groupBy(list, keyGetter) {
            const map = new Map();
            list.forEach((item) => {
                const key = keyGetter(item);
                const collection = map.get(key);
                if (!collection) {
                    map.set(key, [item]);
                } else {
                    collection.push(item);
                }
            });
            return map;
        }
        

        this.on("mount", function () {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });

        this.on("update", function () {
            let spacesMap = groupBy(this.stores.structure.getDatas().nodes, (node) => {return node.group});
            this.hiddenSpaces = this.stores.structure.getHiddenSpaces();
            let mapIt = spacesMap[Symbol.iterator]();
            this.spaces = [];
            for(let item of mapIt){
                let hidden = this.hiddenSpaces.includes(item[0])
                this.spaces.push({name: item[0], length: item[1].length, hidden: hidden})
            }
            if(this.stores.structure.is("HIDE_SPACES_ACTIVE")){
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

        this.togglePanel = function(){
            RiotPolice.trigger("structure:hide_spaces_toggle");
        }
        this.toggleHide = function(e){
            RiotPolice.trigger("structure:space_toggle_hide", e.item.space.name);
        }
        this.showAll = function(){
            RiotPolice.trigger("structure:all_spaces_show");
        }

    </script>
</kg-hide-spaces-panel>