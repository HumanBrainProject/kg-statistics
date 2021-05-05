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
<kg-type-details>
    <style scoped>
         :scope {
            display: block;
            position: relative;
            width: 100%;
            height: 100%;
            padding-bottom: 15px;
            background: #111;
            color:white;
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

        .selection {
            display: flex;
            flex-direction: column;
            height: 100%;
        }

        .selection hr {
            border-width: 0.3px;
            border-color: #444;
        }

        .selection > div {
            padding: 0 15px;
        }
        
        .selection .scroll {
            flex: 1;
            overflow-y: auto;
        }
        
        .no-selection {
            padding: 5px 20px;
            text-align: center;
        }
        
        .no-selection p i {
            font-style: italic;
            text-align: justify;
        }

        .no-selection p + p {
            margin-top: 50px;
        }

        .title{
            font-size:1.2em;
            line-height: 1.6em;
            margin: 15px 50px 12px 0;
            word-break: break-word;
        }

        .id{
            font-size:0.6em;
            line-height: 1em;
            margin-bottom:12px;
            word-break: break-word;
        }

        .spaces {
            margin-bottom:6px;
        }

        .warning {
            color: red;
        }
        
        .spaces ul {
            list-style-type: none;
            margin: 6px 0 12px 0;
            padding-left: 5px;
        }

        .spaces ul li {
            margin-right: 3px;
        }

        .spaces ul li i.fa:before {
            margin-right: 5px;
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

        .link-disabled {
            text-decoration: line-through;
            color: #9a9a9a;
        }

        .norelations{
            margin:12px 12px 16px 12px;
            font-size:0.8em;
            word-break: break-word;
        }

        .noproperties{
            margin:12px 12px 16px 12px;
            font-size:0.8em;
            word-break: break-word;
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

        ul ul {
            font-size: 1em;
        }

        ul.links {
            list-style-type: none;
            padding-left: 5px;
        }

        ul.links > li {
            margin-right: 3px;
        }

        ul.links > li .broken-link {
            color: red;
        }

        ul.links > li .broken-link .link-disabled {
            color: red;
        }

        ul.links > li > span > i.fa:before {
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
            top:1px;
            right:1px;
        }
        .actions button{
            display:block;
            width:40px;
            height:40px;
            line-height: 40px;
            background: transparent;
            appearance: none;
            -webkit-appearance: none;
            border: none;
            outline: none;
            font-size: 20px;
            color: #c9cccf;
            padding: 0;
            margin: 0;
            text-align:center;
            border-bottom:1px solid #111;
            transition: color 0.2s ease-in, box-shadow 0.2s ease-in;
        }
        .actions button:hover{
            background: transparent;
            color: white;
            box-shadow: 3px 3px 6px black;
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
        .properties > ul > li {
            margin-bottom: 4px;
            padding: 3px 3px;
            background: #222;
        }
    </style>

    <div class="selection" if={selectedType}>
        <div>
            <div class="actions">
                <button title={"Unselect type " + selectedType.name} class="close" onclick={unselectType}><i class="fa fa-close"></i></button>
            </div>
            <div class="title">{selectedType.name}</div>
            <div class="id">{selectedType.id}</div>
            <div class="instances">Number of instances: <span class="occurrences">{selectedType.occurrences}</span></div>
            <div class="spaces" if={selectedType.spaces.length}>Spaces:
                <ul>
                    <li each={space in selectedType.spaces}>
                        <i class="fa fa-cloud"></i>{space.name}<span class="occurrences">{space.occurrences}</span>
                    </li>
                </ul>
            </div>
            <div class="spaces warning" if={!selectedType.spaces.length}><i class="fa fa-long-arrow-right"></i> type {selectedType.name} is not associated with any space.</div>
            <hr/>
        </div>
        <div class="scroll">
            <div class="properties">Properties:
                <div class="noproperties" if={!selectedType.properties.length}>
                    type {selectedType.id} does not have any property.
                </div>
                <ul if={selectedType.properties.length}>
                    <li each={property in selectedType.properties} title={property.id}>
                        {property.name} <span class="occurrences">{property.occurrences}</span>
                        <div if={property.targetTypes.length}>
                            <ul class="links">
                                <li each={targetType in property.targetTypes} title={targetType.id}>
                                    <span if={property.excludeLinks} class={targetType.isUnknown?"broken-link":""} title={"links are not available in the graph for property " + property.name}><i class={"fa " + (targetType.isUnknown?"fa-unlink":"fa-ban")}></i>&nbsp;<span class="link-disabled">{targetType.name}</span></span>
                                    <span if={!property.excludeLinks && targetType.isExcluded} class={targetType.isUnknown?"broken-link":""} title={"type " + targetType.id + " is not available in the graph"}><i class={"fa " + (targetType.isUnknown?"fa-unlink":"fa-ban")}></i>&nbsp;<span class="link-disabled">{targetType.name}</span></span>
                                    <span if={!property.excludeLinks && !targetType.isExcluded && targetType.isUnknown} class={targetType.isUnknown?"broken-link":""} title={targetType.id + " is an unknown link"}><i class="fa fa-unlink"></i>{targetType.name}</span>
                                    <span if={!property.excludeLinks && !targetType.isExcluded && !targetType.isUnknown}><i class={"fa " + (property.isProvenance?"fa-flag":"fa-long-arrow-right")} title={property.isProvenance?"is a provenance link":""}></i><a href="#" onmouseover={highlightTarget} onmouseout={unhighlightTarget} onclick={selectTarget} title={targetType.id}>{targetType.name}</a></span>
                                </li>
                            </ul>
                        </div>
                    </li>
                </ul>
            </div>
            <div class="relations">Links To:
                <div class="norelations" if={!selectedType.linksTo.length}>
                    type {selectedType.id} is not linking to any type.
                </div>
                <ul class="links" if={selectedType.linksTo.length}>
                    <li each={linkTo in selectedType.linksTo} title={linkTo.targetId}>
                        <span if={linkTo.isUnknown} title={linkTo.targetId + " is an unknown link"}><i class="fa fa-unlink"></i>{linkTo.targetName}</span>
                        <span if={!linkTo.isUnknown && linkTo.isExcluded} class={linkTo.isUnknown?"broken-link":""} title={"type " + linkTo.targetId + " is not available in the graph"}><i class={"fa " + (linkTo.isUnknown?"fa-unlink":"fa-ban")}></i>&nbsp;<span class="link-disabled">{linkTo.targetName}</span></span>
                        <span if={!linkTo.isUnknown && !linkTo.isExcluded}><i class={"fa " + (linkTo.isProvenance?"fa-flag":"fa-long-arrow-right")} title={linkTo.isProvenance?"is a provenance link":""}></i><a href="#" onmouseover={highlightLinkTo} onmouseout={unhighlightLinkTo} onclick={selectLinkTo} title={linkTo.targetId}>{linkTo.targetName}</a><span class="occurrences">{linkTo.occurrences}</span></span>
                    </li>
                </ul>
            </div>
            <div class="relations">Links From:
                <div class="norelations" if={!selectedType.linksFrom.length}>
                    type {selectedType.id} is not linked by any type.
                </div>
                <ul class="links" if={selectedType.linksFrom.length}>
                    <li each={linkFrom in selectedType.linksFrom} title={linkFrom.sourceId}>
                        <span if={linkFrom.isUnknown} title={linkFrom.sourceId + " is an unknown link"}><i class="fa fa-unlink"></i>{linkFrom.sourceName}</span>
                        <span if={!linkFrom.isUnknown && linkFrom.isExcluded} class={linkFrom.isUnknown?"broken-link":""} title={"type " + linkFrom.sourceId + " is not available in the graph"}><i class={"fa " + (linkFrom.isUnknown?"fa-unlink":"fa-ban")}></i>&nbsp;<span class="link-disabled">{linkFrom.sourceName}</span></span>
                        <span if={!linkFrom.isUnknown && !linkFrom.isExcluded}><i class={"fa " + (linkFrom.isProvenance?"fa-flag":"fa-long-arrow-left")} title={linkFrom.isProvenance?"is a provenance link":""}></i><a href="#" onmouseover={highlightLinkFrom} onmouseout={unhighlightLinkFrom} onclick={selectLinkFrom} title={linkFrom.sourceId}>{linkFrom.sourceName}</a><span class="occurrences">{linkFrom.occurrences}</span></span>
                    </li>
                </ul>
            </div>
        </div>
    </div>
    <div class="no-selection" if={!selectedType}>
        <p>Select a type on the graph or on the search panel to display its properties</p>
    </div>

    <script>
        this.selectedType = undefined;

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

        this.unselectType = e => {
            RiotPolice.trigger("structure:type_select");
        }

        this.selectTarget = e => {
            RiotPolice.trigger("structure:type_select", e.item.targetType.id);
        }
        this.highlightTarget = e => {
            RiotPolice.trigger("structure:type_highlight", e.item.targetType.id);
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
</kg-type-details>