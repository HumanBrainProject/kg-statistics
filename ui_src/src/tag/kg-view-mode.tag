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
<kg-view-mode>
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
    <div className="kgs-theme_toggle">
          <button class="kgs-theme_toggle__button  {selected: !groupViewMode}" onClick={toggle}>
            <i class="fa fa-moon-o"></i>
          </button>
          <button class="kgs-theme_toggle__button  {selected: groupViewMode}" onClick={toggle}>
            <i class="fa fa-sun-o"></i>
          </button>
        ))}
      </div>

    <script>
        this.groupViewMode = false;

        this.on("mount", function () {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
        });
        this.on("update", function(){
            this.groupViewMode = this.stores.structure.is("GROUP_VIEW_MODE");
        });
        this.toggle = () => RiotPolice.trigger("structure:toggle_group_view_mode");
    </script>
</kg-view-mode>