<!-- 
#
#  Copyright (c) 2020, EPFL/Human Brain Project PCO
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
<kg-spaces-toggles>
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
        }

        .title {
            padding: 5px 0;
        }

        .scroll {
            flex: 1;
            overflow-y: auto;
            padding: 5px 15px;
            border: 1px solid #444;
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
            list-style: none;
            margin: 0;
            padding: 0;
        }

        li {
            margin: 5px 0;
        }

        .space-toggle {
            height: 24px;
            display: inline-grid;
            grid-template-columns: repeat(2, 24px);
            margin: 3px 0;
            border-radius: 20px;
            background: #333;
        }

        button.space-toggle_button {
            -webkit-appearance: none;
            display: inline-block;
            height: 24px;
            margin: 0;
            padding: 0;
            border: 0;
            cursor: pointer;
            font-size: 0.66em;
            text-align: center;
            transition: all .2s ease;
            background: none;
            line-height: 24px;
            color: white;
            outline: none;
        }

        button.space-toggle_button.selected {
            transform: scale(1.12);
            font-size: 0.8em;
            background: #4f5658;
            color: white;
            border-radius: 50%;
        }

        span {
            padding-left: 3px;
        }
    </style>
    <div class="panel">
        <div class="title">Spaces:</div>
        <div class="scroll">
            <ul>
                <li each={ spaces }>
                    <div class="space-toggle">
                        <button class="space-toggle_button {selected: enabled}" onClick={parent.toggle} >
                            <i class="fa fa-check"></i>
                        </button>
                        <button class="space-toggle_button {selected: !enabled}" onClick={parent.toggle} >
                            <i class="fa fa-close"></i>
                        </button>
                    </div>
                    <span>{name}</span>
                </li>
            </ul>
        </div>
    </div>

    <script>
        this.spaces = [];

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
            this.spaces = this.stores.structure.getSpacesList();
        });

        this.toggle = e =>  RiotPolice.trigger("structure:space_toggle", e.item.name);
    </script>
</kg-spaces-toggles>