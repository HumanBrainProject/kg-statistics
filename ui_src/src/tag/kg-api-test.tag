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
<kg-api-test class={ show: isActive}>
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
            display:flex;
            flex-flow:column;
            position: relative;
            width: 100%;
            height: 100%;
            --header-height: 65px;
            --sidebar-width: 400px;
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

        .iframe{
            flex: 1 1 auto;

        }
        .header{
            height:50px;
            color:white;
            display:flex;
            align-items:center;
            justify-content:space-between;
        }

        .close-btn{
            margin-right:10px;
        }

        .file-list{
            display:flex;
            align-items:center;
            margin-left:10px;
        }
        .file-list>div{
            width:50px;
            height:20px;
            background-color:#3e3e3e;
            border-radius:2px;
            margin-right:10px;
            text-align:center;
            cursor:pointer;
        }

        .file-list>div:hover{
            background-color:#9898ad;
        }
        .file-list>div.active{
            background-color:#6969dc;
        }


    </style>

    <div class="panel" if={isActive}>
        <div class="container">
            <div class="header">
                <div class="file-list" id="tab-list">
                    <div class='{active:currentTab===1}' onClick={setFile.bind(this, "newman/0001.html", 1)}>1</div>
                    <div class='{active:currentTab===2}' onClick={setFile.bind(this, "newman/0002.html", 2)}>2</div>
                </div>
                <div class="close-btn" onClick={close}><i class="fa fa-times"></i></div>
            </div>
            <iframe class="iframe" frameborder="0" src={fileName} />
        </div>
    </div>
    
    <script>
        this.isActive = false;
        this.fileName = "newman/0001.html";
        this.currentTab = 1;
        this.on("mount", function () {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });

        this.setFile = function(name,currentTab, event){
            this.fileName = name;
            this.currentTab = currentTab;
        }

        this.on("update", function () {
            this.isActive = this.stores.structure.is("SHOW_MODAL")
        });
        this.close = function(){
            RiotPolice.trigger("modal:show_postman_tests", false)
        }
        this.cancel = e => RiotPolice.trigger("api-test:close");


    </script>
</kg-api-test>