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
<kg-all-spaces-toggle>
    <style scoped>
        :scope{
            display:inline-block;
            color: white;
        }
        
        .all-spaces__toggle {
            height: 24px;
            display: inline-grid;
            grid-template-columns: repeat(3, 24px);
            margin: 3px 0;
            border-radius: 20px;
            background: #333;
        }

        button.all-spaces__toggle__button {
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

        button.all-spaces__toggle__button[disabled] {
            cursor: default;
        }

        button.all-spaces__toggle__button i.fa-sort{
            transform: rotate(90deg);
        }

        button.all-spaces__toggle__button.selected {
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
    <div>
        <div class="all-spaces__toggle">
            <button class="all-spaces__toggle__button {selected: show === true}" onClick={showAll} >
                <i class="fa fa-check"></i>
            </button>
            <button class="all-spaces__toggle__button {selected: show === undefined}" disabled >
                <i class="fa fa-sort"></i>
            </button>
            <button class="all-spaces__toggle__button {selected: show === false}" onClick={showNone} >
                <i class="fa fa-close"></i>
            </button>
        </div>
    </div>

    <script>
        this.show = true;

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
            this.show = this.stores.structure.showAllSpaces();
        });

        this.showAll = () => RiotPolice.trigger("structure:spaces_all_toggle", true);
        this.showNone = () => RiotPolice.trigger("structure:spaces_all_toggle", false);
    </script>
</kg-all-spaces-toggle>