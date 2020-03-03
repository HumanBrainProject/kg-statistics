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
<kg-tabs>
    <style scoped>
        :scope{
            position: relative;
            width: 100%;
            height:100%;
            display: flex;
            flex-direction: column;
            padding: 15px;
            background: #111;
            color:white;
        }

        .tabs {
            position: relative;
            width: 100%;
            display: flex;
            z-index: 1;
        }

        .tabs button.tab-btn {
            width: 40px;
            height: 40px;
            line-height: 40px;
            background: #111;
            border-radius: 10px 10px 0 0;
            appearance: none;
            -webkit-appearance: none;
            border: 1px solid #444;
            border-left: 0;
            transform: translateY(1px);
            outline: none;
            font-size: 20px;
            color: #ccc;
            padding: 0;
            margin: 0;
            text-align:center;
        }

        .tabs button.tab-btn:first-child {
            border-left: 1px solid #444;
            border-radius: 10px 0 0 0;
        }

        .tabs button.tab-btn:last-child {
            border-radius: 0 10px 0 0;
        }

        .tabs button.tab-btn.is-active {
            border-bottom-color: #111;
        }

        .content {
            position: relative;
            width: 100%;
            flex: 1;
            overflow: hidden;
            border: 1px solid #444;
        }

    </style>

    <div class="tabs">
        <button class={"tab-btn show-search-btn " + (isTypeDetailsVisible?"":"is-active")} onclick={showSearch}>
            <i class="fa fa-search" aria-hidden="true"></i>
        </button>
        <button class={"tab-btn show-type-details-btn " + (isTypeDetailsVisible?"is-active":"")} onclick={showTypeDetails}>
            <i class="fa fa-info" aria-hidden="true"></i>
        </button>
    </div>
    <div class="content">
        <kg-search-panel if={!isTypeDetailsVisible}></kg-search-panel>
        <kg-type-details if={isTypeDetailsVisible}></kg-type-details>
    </div>

     <script>
        this.isTypeDetailsVisible = false;

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
            this.isTypeDetailsVisible = this.stores.structure.is("TYPE_DETAILS_SHOW");
        });

        this.showSearch = () => {
            RiotPolice.trigger("structure:type_details_show", false);
        };

        this.showTypeDetails = () => {
            RiotPolice.trigger("structure:type_details_show", true);
        };

    </script>
</kg-tabs>