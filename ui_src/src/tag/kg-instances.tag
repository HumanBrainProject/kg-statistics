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
<kg-instances class={ show: isActive}>
    <style scoped>
        :scope {
            z-index: -1;
            display: block;
            position: fixed;
            top: 0;  
            left: 0;  
            width: 100%;
            height: 100%;
            margin: 0;
            box-sizing: border-box;
            box-sizing: border-box;
            background-color: rgba(255,255,255,0);
            transition: background-color 0.75s ease-in;
        }

        :scope.show {
            z-index: 200;
            background-color: rgba(255,255,255,0.25);
        }

        .panel {
            display: block;
            position: relative;
            width: calc(100% - 20px);
            height: calc(100% - 20px);
            margin-top: -100%;
            margin-left: 10px;
            border: 1px solid lightgray;
            background-color: #333;
            color: white;
            transition: margin-top 0.5s ease-in;
        }

        :scope.show .panel {
            margin-top: 10px;
        }

        .container {
            position: relative;
            width: 100%;
            height: 100%;
            --header-height: 65px;
            --sidebar-width: 400px;
        }

        kg-instances-topbar {
            position:absolute;
            top:0;
            left:0;
            width:100%;
            height:var(--header-height);
        }

        kg-instances-sidebar {
            position:absolute;
            top:var(--header-height);
            left:0;
            width:var(--sidebar-width);
            height:calc(100% - var(--header-height));
        }

        kg-instances-body {
            position:absolute;
            top:var(--header-height);
            left:var(--sidebar-width);
            width:calc(100% - var(--sidebar-width));
            height:calc(100% - var(--header-height));
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

    <div class="panel">
        <div class="container" if={isActive}>
            <kg-instances-topbar></kg-instances-topbar>
            <kg-instances-sidebar></kg-instances-sidebar>
            <kg-instances-body></kg-instances-body>
        </div>
        <div class="loading-panel {show: isLoading}">
            <span class="loading-spinner">
                <img src="img/ebrains.svg" alt="loading..." />
            </span>
            <span class="loading-label">Loading instances ( {loadingStats.current} / {loadingStats.total} )</span>
        </div>
        <div class="error-panel {show: hasError}">
            <span class="error-message">The search engine is temporary unavailable. Please retry in a moment.</span>
            <div class="error-navigation">
                <button onClick={retry}>Retry</button>
                <button onClick={cancel}>Cancel</button>
            </div>
        </div>
    </div>
    
    <script>
        this.isActive = false;
        this.hasError = false;
        this.isLoading = false;
        this.isLoaded = false;
        this.loadingStats = { current: 0, percentage: 100, total: 0 };

        this.on("mount", function () {
            RiotPolice.requestStore("instances", this);
            RiotPolice.on("instances.changed", this.update);
        });

        this.on("update", function () {
            this.isActive = this.stores.instances.is("ACTIVE");
            this.hasError = this.stores.instances.is("QUERY_ERROR");
            this.isLoading = this.stores.instances.is("QUERY_LOADING");
            this.isLoaded = this.stores.instances.is("QUERY_LOADED");

            if (this.isLoading)
                this.loadingStats = this.stores.instances.getLoadingStats();
        });

        this.retry = e => RiotPolice.trigger("instances:retry");
        this.cancel = e => RiotPolice.trigger("instances:close");


    </script>
</kg-instances>