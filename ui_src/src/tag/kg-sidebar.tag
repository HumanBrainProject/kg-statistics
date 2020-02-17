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
<kg-sidebar>
    <style scoped>
         :scope {
            display: block;
            color:white;
            padding:10px;
            overflow-y: auto;
        }

        .title{
            font-size:1.2em;
            line-height: 1.6em;
            margin-bottom:10px;
        }

        .version{
            font-size:1em;
            line-height: 1.4em;
        }

        .instances{
            font-size:0.8em;
            line-height: 1.2em;
            margin-bottom:12px;
        }

        .instances button {
            position: absolute;
            margin: -10px 0 0 8px;
            padding: 10px 20px;
            background: #3498db;
            border: 0;
            border-radius: 3px;
            background-color: #3498db;
            background-image: linear-gradient(to bottom, #3498db, #2980b9);
            color: #e6e6e6;     
            font-size: 18px;
            line-height: 20px;
            text-align: center;
            text-decoration: none;
            transition: background-color 0.3s ease-in, background-image 0.3s ease-in, color 0.3s ease-in;
            cursor: pointer;
        }
        .instances button:hover{
            background-color: #3cb0fd;
            background-image: linear-gradient(to bottom, #3cb0fd, #3498db);
            color: #ffffff;
            text-decoration: none;
        }

        .norelations{
            margin-top:12px;
            font-size:0.8em;
        }

        ul{
            font-size:0.8em;
            padding-left:18px;
        }
        li{
            padding: 3px 0;
            line-height:1;
            position:relative;
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
        .disabled{
            text-decoration: line-through;
            color:#aaa;
        }
        .separator {
            border-bottom: 1px solid white;
            margin-bottom: 20px;
            padding-bottom: 10px;
        }
        .actions{
            position:absolute;
            top:15px;
            right:15px;
        }
        .actions button{
            display:block;
            width:40px;
            height:40px;
            line-height: 40px;
            background: #222;
            appearance: none;
            -webkit-appearance: none;
            border: none;
            outline: none;
            font-size: 20px;
            color: #ccc;
            padding: 0;
            margin: 0;
            text-align:center;
            border-bottom:1px solid #111;
        }
        .actions button:hover{
            background: #333;
        }

        .actions button:first-child{
            border-top-left-radius: 5px;
            border-top-right-radius: 5px;
        }

        .actions button:last-child{
            border-bottom-left-radius: 5px;
            border-bottom-right-radius: 5px;
            border-bottom:none;
        }
        .bar-instances-wo-prop{
            position:absolute;
            top:2px;
            left:0;
            height:calc(100% - 4px);
            width:0%;
            background:#222;
            z-index:-1;
            transition:all 0.5s ease-out;
        }
        .number-instances-wo-prop{
            position:absolute;
            top:7px;
            right:6px;
            color:white;
            transition:all 0.5s ease-out;
            font-size:0.8em;
            opacity:0;
            transition:opacity 0.5s ease-out;
            font-weight: bold;
        }
        .properties li:hover .bar-instances-wo-prop{
            background:#2980b9;
        }
        .properties li:hover .number-instances-wo-prop{
            opacity:1;
        }
    </style>

    <div if={selectedType} class={separator: selectedType && typesWithoutRelations.length}>
        <div class="actions">
            <button title="Close this view" class="close" onclick={close}><i class="fa fa-close"></i></button>
            <button title="Hide the corresponding node" class="hide" onclick={toggleHide}><i class="fa {selectedType.hidden?'fa-eye':'fa-eye-slash'}"></i></button>
        </div>
        <div class="title">{selectedType.id}</div>
        <div class="instances">Number of instances: <span class="occurrences">{selectedType.occurrences}</span></div>
        <div class="properties">Properties:
            <ul>
                <li each={property in selectedType.properties} title={property.name}>
                    {property.name} <span class="occurrences">{property.occurrences}</span>
                    <div if={property.instancesWithoutProp} class="bar-instances-wo-prop" style="width:{100-property.instancesWithoutProp/selectedType.occurrences*100}%"></div>
                    <div if={property.instancesWithoutProp} class="number-instances-wo-prop">{Math.round(100-property.instancesWithoutProp/selectedType.occurrences*100)}% ({selectedType.occurrences-property.instancesWithoutProp})</div>
                    <div if={!property.instancesWithoutProp} class="bar-instances-wo-prop" style="width:100%"></div>
                    <div if={!property.instancesWithoutProp} class="number-instances-wo-prop">100%</div>
                </li>
            </ul>
        </div>
        <div class="relations">Relations:
            <div class="norelations" if={!sortedRelations.length}>
                No relations found
            </div>
            <ul>
                <li each={relation in sortedRelations}>
                    <a class={disabled:hiddenTypes.indexOf(relation.relationId) !== -1} href="#" onmouseover={highlightRelation} onmouseout={unhighlightNode} onclick={selectRelation}>{relation.relationId}</a><span class="occurrences">{relation.relationCount}</span>
                </li>
            </ul>
        </div>
    </div>
    <div class="types" if={typesWithoutRelations.length}>Type(s) without visible relation:
        <ul>
            <li each={type in typesWithoutRelations}>
                <a href="#" onmouseover={highlightNode} onmouseout={unhighlightNode} onclick={selectNode}>{type.data.id}</a>
            </li>
        </ul>
    </div>

    <script>
        this.selectedType = false;
        this.typesWithoutRelations = [];
        this.hiddenTypes = [];

        this.on("mount", function () {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });

        this.on("unmount", function(){
            RiotPolice.off("structure.changed", this.update);
            RiotPolice.releaseStore("structure", this);
        });

        this.on("update", function () {
            var self = this;
            this.nodes = this.stores.structure.getNodes();
            this.hiddenTypes = this.stores.structure.getHiddenTypes();

            this.typesWithoutRelations = [];
            this.nodes.forEach(n => {
                if (!n.hidden && !self.stores.structure.hasRelations(n.id, true)){
                    self.typesWithoutRelations.push(n);
                }
            });

            this.selectedType = this.stores.structure.getSelectedType();
            if(!this.selectedType){
                return;
            }
          
            this.sortedRelations = _.orderBy(this.stores.structure.getRelationsOf(this.selectedType.id), o => o.value, 'desc');
        });

        this.close = function(e){
            RiotPolice.trigger("structure:node_select", this.selectedType);
        }
        this.toggleHide = function(e){
            RiotPolice.trigger("structure:type_toggle_hide", this.selectedType);
        }
        this.selectNode = function(e){
            if (!this.selectedType || this.selectedType.id !==  e.item)
                RiotPolice.trigger("structure:node_select", e.item);
        }
        this.highlightNode = function(e){
            RiotPolice.trigger("structure:node_highlight", e.item);
        }
        this.unhighlightNode = function(e){
            RiotPolice.trigger("structure:node_unhighlight");
        }

        this.selectRelation = function(e){
            RiotPolice.trigger("structure:node_select", e.item.relation.relationId);
        }
        this.highlightRelation = function(e){
            RiotPolice.trigger("structure:node_highlight", e.item.relation.relationId);
        }

        this.unhighlightNode = function(e){
            RiotPolice.trigger("structure:node_unhighlight");
        }
    </script>
</kg-sidebar>