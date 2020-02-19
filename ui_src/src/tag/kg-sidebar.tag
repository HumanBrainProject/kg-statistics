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

        .no-selection {
            text-align: center;
            margin: 35px 0;
        }

        .title{
            font-size:1.2em;
            line-height: 1.6em;
        }

        .id{
            font-size:0.6em;
            line-height: 1em;
            margin-bottom:12px;
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

        ul ul {
            font-size: 1em;
        }

        ul.links {
            list-style-type: none;
            padding-left: 5px;
        }

        li{
            padding: 3px 0;
            line-height:1;
            position:relative;
        }
        ul.links > li {
            margin-right: 3px;
        }
        ul.links > li > i.fa:before {
            margin-right: 5px;
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

    <div if={selectedType}>
        <div class="actions">
            <button title="Close this view" class="close" onclick={close}><i class="fa fa-close"></i></button>
        </div>
        <div class="title">{selectedType.name}</div>
        <div class="id">{selectedType.id}</div>
        <div class="instances">Number of instances: <span class="occurrences">{selectedType.occurrences}</span></div>
        <div class="properties">Properties:
            <ul if={selectedType.properties.length}>
                <li each={property in selectedType.properties} title={property.name}>
                    {property.name} <span class="occurrences">{property.occurrences}</span>
                    <div if={property.instancesWithoutProp} class="bar-instances-wo-prop" style="width:{100-property.instancesWithoutProp/selectedType.occurrences*100}%"></div>
                    <div if={property.instancesWithoutProp} class="number-instances-wo-prop">{Math.round(100-property.instancesWithoutProp/selectedType.occurrences*100)}% ({selectedType.occurrences-property.instancesWithoutProp})</div>
                    <div if={!property.instancesWithoutProp} class="bar-instances-wo-prop" style="width:100%"></div>
                    <div if={!property.instancesWithoutProp} class="number-instances-wo-prop">100%</div>
                    <div if={property.targetTypes.length}>
                        <ul class="links">
                            <li each={targetType in property.targetTypes} title={targetType.id}>
                                <i class="fa fa-long-arrow-right"></i><a href="#" onmouseover={highlightTarget} onmouseout={unhighlighTarget} onclick={selectTarget} title={targetType.id}>{targetType.name}</a>
                            </li>
                        </ul>
                    </div>
                </li>
            </ul>
            <div if={!selectedType.properties.length}>
                type {selectedType.id} does not have any property.
            </div>
        </div>
        <div class="relations">Links To:
            <div class="norelations" if={!selectedType.linksTo.length}>
                type {selectedType.id} is not linking to any type.
            </div>
            <ul class="links" if={selectedType.linksTo.length}>
                <li each={linkTo in selectedType.linksTo} title={linkTo.targetId}>
                    <i class="fa fa-long-arrow-right"></i><a href="#" onmouseover={highlightLinkTo} onmouseout={unhighlightLinkTo} onclick={selectLinkTo} title={linkTo.targetId}>{linkTo.targetName}</a><span class="occurrences">{linkTo.occurrences}</span>
                </li>
            </ul>
        </div>
        <div class="relations">Links From:
            <ul class="links" if={selectedType.linksFrom.length}>
                <li each={linkFrom in selectedType.linksFrom} title={linkFrom.sourceId}>
                    <i class="fa fa-long-arrow-left"></i><a href="#" onmouseover={highlightLinkFrom} onmouseout={unhighlightLinkFrom} onclick={selectLinkFrom} title={linkFrom.sourceId}>{linkFrom.sourceName}</a><span class="occurrences">{linkFrom.occurrences}</span>
                </li>
            </ul>
        </div>
    </div>
    <div class="no-selection" if={!selectedType}>
        Select a type on the graph or on the search panel to display its properties
    </div>

    <script>
        this.selectedType = false;

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
            this.selectedType = this.stores.structure.getSelectedType();
        });

        this.close = e => {
            RiotPolice.trigger("structure:type_select");
        }

        this.selectTarget = e => {
            RiotPolice.trigger("structure:type_select", e.item.targetType.targetId);
        }
        this.highlightTarget = e => {
            RiotPolice.trigger("structure:type_highlight", e.item.targetType.targetId);
        }
        this.unhighlightTarget = e => {
            RiotPolice.trigger("structure:type_highlight");
        }

        this.selectLinkTo = e => {
            RiotPolice.trigger("structure:type_select", e.item.linkTo.targetId);
        }
        this.highlightLinkTo = e => {
            RiotPolice.trigger("structure:type_highlight", e.item.linkTo.targetId);
        }
        this.unhighlightLinkTo = e => {
            RiotPolice.trigger("structure:type_highlight");
        }

        this.selectLinkFrom = e => {
            RiotPolice.trigger("structure:type_select", e.item.linkFrom.sourceId);
        }
        this.highlightLinkFrom = e => {
            RiotPolice.trigger("structure:type_highlight", e.item.linkFrom.sourceId);
        }
        this.unhighlightLinkFrom = e => {
            RiotPolice.trigger("structure:type_highlight");
        }
    
    </script>
</kg-sidebar>