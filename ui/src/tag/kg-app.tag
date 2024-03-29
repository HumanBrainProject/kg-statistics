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
            display: block;
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

        kg-side-panel{
            position:absolute;
            width:var(--sidebar-width);
            height:calc(100vh - var(--topbar-height));
            top:var(--topbar-height);
            right:0;
            z-index:20;
        }

        .kg-app-container{
            position:relative;
            width:100vw;
            height:100vh;
            transition:transform 0.7s cubic-bezier(0.77, -0.46, 0.35, 1.66);
            z-index:2;
        }

        .loading-panel {
            position: absolute;
            height: 80px;
            margin-left: calc(50% - 180px);
            padding: 20px;
            border-radius: 4px;
            top:-200px;
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
            top: 33px;
        }

        .loading-panel .loading-label {
            display: inline-block;
            padding: 12px 0 0 30px;
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
        <kg-side-panel if={isLoaded}></kg-side-panel>
        <div class="loading-panel {show: isLoading}">
            <span class="loading-spinner">
              <i class="fa fa-circle-o-notch fa-spin" aria-hidden="true"></i>
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

        this.on("mount", () => {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
            this.update();
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
        });

        this.retry = e => RiotPolice.trigger("structure:load");
    </script>
</kg-app>