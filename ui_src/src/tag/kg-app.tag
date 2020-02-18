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
        kg-types-panel,
        kg-spaces-panel{
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

        .loading-panel {
            position: absolute;
            width: 380px;
            height: 80px;
            top: -200px;
            margin-left: calc(50% - 180px);
            padding: 20px;
            border-radius: 4px;
            box-sizing: border-box;
            background-color: #404040;
            transition: margin-top 0.25s ease-in;
            -webkit-box-shadow: 3px 3px 6px #8f8a8a;
            box-shadow: 3px 3px 6px black;
        }

        .loading-panel.show {
            top: calc(40% - 40px);
        }


       .loading-panel .loading-spinner {
            position: absolute;
            display: inline-block;
            width: 40px;
            height: 40px;
        }

        .loading-panel .loading-spinner img {
            -webkit-animation: loading-spinner-rotate 0.5s infinite linear;
            animation: loading-spinner-rotate 0.5s infinite linear;
        }

        .loading-panel .loading-label {
            display: inline-block;
            padding: 12px 0 0 55px;
        }

        @-webkit-keyframes loading-spinner-rotate {
            0% {
                -webkit-transform: rotateZ(0deg)
            }
            100% {
                -webkit-transform: rotateZ(360deg)
            }
        }

        @keyframes loading-spinner-rotate {
            0% {
                transform: rotateZ(0deg);
                -webkit-transform: rotateZ(0deg);
            }
            100% {
                transform: rotateZ(0deg);
                -webkit-transform: rotateZ(360deg);
            }
        }

        .error-panel {
            position: absolute;
            width: 360px;
            top: -200px;
            margin-left: calc(50% - 180px);
            padding: 20px;
            border-radius: 4px;
            box-sizing: border-box;
            background-color: #404040;
            transition: margin-top 0.25s ease-in;
            box-shadow: 3px 3px 6px black;
        }

        .error-panel.show {
            top: calc(40% - 60px);
        }

        .error-panel .error-message {
            display: inline-block;
            font-size: 1em;
            line-height: 1.5em;
            text-align: center;
        }

        .error-panel .error-navigation {
            display: flex;
            justify-content: space-evenly;
            padding-top: 15px;
        }

        .error-panel button {
            margin: 0;
            padding: 11px 28px;
            border: 0;
            border-radius: 3px;
            background-color: #1f1f1f;
            color: #c9cccf;
            font-size: 1em;
            text-align: center;
            transition: background-color 0.2s ease-in, color 0.2s ease-in, box-shadow 0.2s ease-in, color 0.2s ease-in, -webkit-box-shadow 0.2s ease-in;
            cursor: pointer;
        }

        .error-panel button:hover {
            box-shadow: 3px 3px 6px black;
            background-color: #292929;
            color: white;
        }

    </style>
    <div class="kg-app-container ">
        <kg-topbar></kg-topbar>
        <kg-body if={isLoaded}></kg-body>
        <kg-types-panel if={isLoaded}></kg-types-panel>
        <kg-spaces-panel if={isLoaded && groupViewMode}></kg-spaces-panel>
        <kg-search-panel if={isLoaded}></kg-search-panel>
        <kg-sidebar if={isLoaded}></kg-sidebar>
        <div class="loading-panel {show: isLoading}">
            <span class="loading-spinner">
                <img src="img/ebrains.svg" alt="loading..." />
            </span>
            <span class="loading-label">Loading structure</span>
        </div>
        <div class="error-panel {show: hasError}">
            <span class="error-message">The service is temporary unavailable. Please retry in a moment.</span>
            <div class="error-navigation">
                <button onClick={retry}>Retry</button>
        </div>
    </div>
    </div>

     <script>
        this.hasError = false;
        this.isLoading = false;
        this.isLoaded = false;
        this.groupViewMode = false;

        this.on("mount", () => {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
            RiotPolice.trigger("structure:load");
        });

        this.on("unmount", () => {
            RiotPolice.off("structure.changed", this.update);
            RiotPolice.releaseStore("structure", this);
        });

        this.on("update", () => {
            this.hasError = this.stores.structure.is("STRUCTURE_ERROR");
            this.isLoading = this.stores.structure.is("STRUCTURE_LOADING");
            this.isLoaded = this.stores.structure.is("STRUCTURE_LOADED");
            this.groupViewMode = this.stores.structure.is("GROUP_VIEW_MODE");
        });

        this.retry = e => RiotPolice.trigger("structure:load");
    </script>
</kg-app>