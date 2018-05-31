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
<kg-app>
    <style scoped>
        :scope{
            display:block;
            width:100vw;
            height:100vh;
            --topbar-height: 80px;
            --sidebar-width: 400px;
            --search-panel-width: 300px;
            position:absolute;
            top:0;
            left:0;
            text-rendering: optimizeLegibility;
            -webkit-font-smoothing: antialiased;
        }

        input,
        button {
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            -khtml-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
        }

        button * {
            cursor: pointer;
        }

        button[disabled] * {
            cursor: default;
        }

        a {
            color:white;
        }
        a:hover {
            color:#aaa;
        }

        kg-topbar{
            position:absolute;
            top:0;
            left:0;
            width:100vw;
            height:var(--topbar-height);
            width:100vw;
            background-color:#222;
        }

        kg-body{
            position:absolute;
            width:calc(100vw - var(--sidebar-width));
            height:calc(100vh - var(--topbar-height));
            background:#333;
            top:var(--topbar-height);
            left:0;
        }

        kg-sidebar{
            position:absolute;
            width:var(--sidebar-width);
            height:calc(100vh - var(--topbar-height));
            background:#111;
            top:var(--topbar-height);
            right:0;
            overflow-y: auto;
            z-index:20;
        }

        kg-search-panel,
        kg-hide-panel{
            position:absolute;
            width:var(--search-panel-width);
            height:calc(100vh - var(--topbar-height) - 50px);
            background:#222;
            top:calc(var(--topbar-height) + 25px);
            right:calc(var(--sidebar-width) - var(--search-panel-width));
            overflow:visible;
            border-radius: 10px 0 0 10px;
            transition:right 0.5s cubic-bezier(.34,1.06,.63,.93);
        }

        .menu-open{
            transform:translateX(-200px);
        }

        .kg-app-container{
            position:relative;
            width:100vw;
            height:100vh;
            transition:transform 0.7s cubic-bezier(0.77, -0.46, 0.35, 1.66);
            z-index:2;
        }

        kg-menu-popup{
            position:absolute;
            z-index:1;
            top:0;
            right:0;
            height:100vh;
            width:200px;
        }
    </style>
    <script>
        this.showMenu = false;

        this.on("mount", function () {
            RiotPolice.on("showmenu", this.update);
        });

        this.on("update", function(){
            this.showMenu = !this.showMenu;
        })
    </script>
    <div class="kg-app-container {menu-open:showMenu}">
        <kg-topbar></kg-topbar>
        <kg-body></kg-body>
        <kg-hide-panel></kg-hide-panel>
        <kg-search-panel></kg-search-panel>
        <kg-sidebar></kg-sidebar>
        <kg-instances></kg-instances>
        <kg-api-test></kg-api-test>
        <kg-status-report></kg-status-report>
    </div>
    <kg-menu-popup></kg-menu-popup>
</kg-app>