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
<kg-topbar>
    <style scoped>
        :scope{
            display:block;
        }
        .title {
            margin-left:10px;
            font-size: 20px;
            font-weight: 700;
            color: white;
        }

        .date{
            height:100%;
            margin-right:10px;
        }

        .btn{
            width:20px;
            height:20px;
        }

        .menu{
            transition: all 0.3s ease 0s;
            padding: 10px 10px 10px 10px;
        }

        .menu:hover{
            background-color: #3e3e3e;
            border-radius:2px;
            cursor: pointer;
            color:#3498db;
        }

        .header-left{
            display:flex;
            align-items:center;
            justify-content:left;
            margin-left:20px;
        }
        .header-right{
            color:white;
            display:flex;
            align-items:center;
            margin-right:20px;
        }
        .header{
            display:flex;
            align-items:center;
            justify-content: space-between;
            height:var(--topbar-height);
        }
    </style>
    <div class="header">
        <div class="header-left">
            <img src="img/ebrains.svg" alt="" width="40" height="40" />
            <div class="title">{AppConfig.title}</div>
        </div>    
        <div class="header-right" >
            <div class="date" if={date}>KG State at : {date}</div>
            <div class="menu"  onclick={toggleModal}><div class="menu-btn"><i class="fa fa-bars"></i></div></div>
        </div>
    </div>

    <script>
        this.date = "";
        this.showModal = false;

        this.on("mount", function () {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });
        this.toggleModal = function(){
            this.showModal = !this.showModal;
            RiotPolice.trigger("showmenu", this.showModal);
            
        }
        this.on("update", function(){
            if(this.stores.structure.is("DATAS_LOADED")){
                this.date = new Date(this.stores.structure.getDatas().lastUpdate);
            }
        });
    </script>
</kg-topbar>