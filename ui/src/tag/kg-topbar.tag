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
        button.refresh {
            margin: 0;    
            padding: 8px 10px;
            border: 0;
            border-radius: 0;
            background-color: transparent;
            color: #c9cccf;
            font-size: 1em;
            text-align: center;
            transition: color 0.2s ease-in, color 0.2s ease-in, box-shadow 0.2s ease-in, color 0.2s ease-in, -webkit-box-shadow 0.2s ease-in;
            cursor: pointer;
        }
        button.refresh:hover{
            box-shadow: 3px 3px 6px black;
            background-color: transparent;
            color: white;
        }
    </style>
    <div class="header">
        <div class="header-left">
            <img src="img/ebrains.svg" alt="" height="40" />
            <div class="title">{AppConfig.title}</div>
        </div>
        <div class="header-right" if={isLoaded} >
            <div class="date" if={date}>KG State at : {date}</div>
            <button class="refresh" onClick={refresh} title="refresh"><i class="fa fa-refresh"></i></button>
        </div>
    </div>

    <script>
        this.date = "";
        this.isLoaded = false;

        this.on("mount", () => {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });

        this.on("unmount", () => {
            RiotPolice.off("structure.changed", this.update);
            RiotPolice.releaseStore("structure", this);
        });

        this.on("update", () => {
         this.isLoaded = this.stores.structure.is("STRUCTURE_LOADED")
         this.date = this.stores.structure.getLastUpdate();
        });

        this.refresh = () => RiotPolice.trigger("structure:load");
    </script>
</kg-topbar>