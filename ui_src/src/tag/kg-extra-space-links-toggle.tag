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
<kg-extra-space-links-toggle>
    <style scoped>
        :scope{
            display:block;
            color: white;
        }
        
        .group-view__toggle {
            height: 24px;
            display: inline-grid;
            grid-template-columns: repeat(2, 24px);
            margin: 3px 0;
            border-radius: 20px;
            background: #333;
        }

        button.group-view__toggle__button {
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

        button.group-view__toggle__button.selected {
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
        <div class="group-view__toggle">
            <button class="group-view__toggle__button {selected: showExtraSpaceLinks}" onClick={toggle} >
                <i class="fa fa-check"></i>
            </button>
            <button class="group-view__toggle__button {selected: !showExtraSpaceLinks}" onClick={toggle} >
                <i class="fa fa-close"></i>
            </button>
        </div>
        <span>show links between spaces</span>
    </div>

    <script>
        this.showExtraSpaceLinks = true;

        this.on("mount", () => {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });

        this.on("unmount", () => {
            RiotPolice.off("structure.changed", this.update);
            RiotPolice.releaseStore("structure", this);
            this.update();
        });

        this.on("update", () => {
            this.showExtraSpaceLinks = this.stores.structure.is("EXTRA_SPACE_LINKS_SHOW");
        });

        this.toggle = () => RiotPolice.trigger("structure:space_extra_links_toggle");
    </script>
</kg-extra-space-links-toggle>