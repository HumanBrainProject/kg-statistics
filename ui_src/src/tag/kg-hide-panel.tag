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
<kg-hide-panel>
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
            top: 60px;
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

        .types{
            margin-top: 15px;
            max-height:calc(100% - 51px);
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

        .nodelist{
            margin-top: 0;
            max-height:calc(100% - 45px);
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
            border-radius: 5px 0 0 5px;
            transition:background-color 0.25s ease-out;
            cursor:pointer;
            outline:none;
        }
        .actions button:hover{
            background:#333;
        }
        .actions button:last-child{
            border-radius: 0 5px 5px 0;
            border-left:1px solid #222;
        }
    </style>

    <button class="open-panel" onclick={togglePanel}>
        <i class="fa fa-eye-slash" aria-hidden="true"></i>
        <span class="bubble">{hiddenTypes.length}</span>
    </button>
    
    <div class="title">
        Nodes visibility
        <div class="actions">
            <button class="hide-all" onclick={hideAll}>Hide all</button>
            <button class="show-all" onclick={showAll}>Show all</button>
        </div>
    </div>

    <div class="nodelist">
        <ul>
            <li each={node in nodes}>
                <a class={"disabled": node.hidden} href="#" onclick={toggleHide} onmouseover={highlightNode} onmouseout={unhighlightNode}>
                    {node.id}
                </a>
                <span class="occurrences">{node.occurrences}</span>
            </li>
        </ul>
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
            this.nodes = _.orderBy(this.stores.structure.getNodes(), 'occurrences', 'desc');
            this.hiddenTypes = this.stores.structure.getHiddenTypes();

            if(this.stores.structure.is("HIDE_ACTIVE")){
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
            RiotPolice.trigger("structure:hide_toggle");
        }
        this.toggleHide = function(e){
            RiotPolice.trigger("structure:type_toggle_hide", e.item.node);
        }
        this.hideAll = function(){
            RiotPolice.trigger("structure:all_types_toggle_hide", true);
        }
        this.showAll = function(){
            RiotPolice.trigger("structure:all_types_toggle_hide", false);
        }
        this.highlightNode = function(e){
            RiotPolice.trigger("structure:node_highlight", e.item.node);
        }
        this.unhighlightNode = function(e){
            RiotPolice.trigger("structure:node_unhighlight");
        }
    </script>
</kg-hide-panel>