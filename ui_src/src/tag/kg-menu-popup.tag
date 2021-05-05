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
<kg-menu-popup>
    <style scoped>
        :scope{
            display:block;
        }
        .grid{
            display:flex;
        }
        .col{
            flex:1;
        }

        .col>div{
            color:white;
            width:50px;
            height:50px;
            border-radius:2px;
            display:flex;
            align-items: center;
            justify-content: center;
            background-color:#4b4b4d;
            margin: 5px;
        }

        .col>div:hover{
            color:#3498db;
            background-color:#5c5c5c;
        }

        .container{
            position: absolute;
            padding: 50px 10px 10px 20px;
            right: 0px;
            width:200px;
            background-color: #3e3e3e;
            cursor: pointer;
            height: 100%;
            
        }
    </style>
    <div class="container">
        <div class="grid">
            <div class="col">
                <div onclick={toggleModal.bind(this, "modal:show_postman_tests", showPostman)}><i class="fa fa-rocket"></i></div>
                <div onclick={toggleModal.bind(this, "modal:show_status_report", showStatus)}><i class="fa fa-bolt"></i></div>
            </div>
        </div>
    </div>

    <script>
        this.showPostman = false;
        this.showStatus = false;

        this.on("mount", function () {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });

        this.toggleModal = function(action, showModal){
            showModal = !showModal;
            RiotPolice.trigger(action, showModal);
            RiotPolice.trigger("showmenu", false);
        }

        this.on("update", function () {
            this.isActive = this.stores.structure.is("SHOW_MENU");
        });
    </script>
</kg-menu-popup>