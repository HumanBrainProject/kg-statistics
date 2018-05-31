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
<kg-instances-body>
    <style scoped>
        :scope {
            background:#333;
            overflow-y: auto; 
        }

        table {
            margin: 10px;
            border-spacing: 0;
            border-collapse: separate;
            /*width: calc(100% - 20px);*/
        }

        table thead th {
            padding: 10px;
            border-bottom: 1px solid gray;
            border-right: 1px solid gray;
            text-align: right;
        }

        table thead th:first-child {
            white-space: nowrap;
        }

        table thead th:not(:first-child) {
            cursor: default;
            border-top: 1px solid gray;
            word-break: break-all;
            text-align: left;
        }
        table thead th:last-child {  
            text-align: left !important;
        }

        table tbody td {
            padding: 10px;
            border-bottom: 1px solid gray;
            border-right: 1px solid gray;    
            text-align: left;
        }
        table tbody td:last-child {  
            text-align: left !important;
        }
        table tbody td:first-child {
            cursor: default;   
            white-space: nowrap;
            text-align: right;
        }

        table tbody td:not(:first-child) {
            word-break: break-all;
            vertical-align: top;
        }

    </style>

    <table if={isComparison}>
        <cols>
            <col width="20%" />
            <col width="40%" />
            <col width="40%" />
        </cols>
        <thead>
            <tr>
                <th>Properties \ Instances</th>
                <th if={comparison.instance1} title={comparison.instance1.title}><a href={comparison.instance1.resultId} target="_blank">{comparison.instance1.name?comparison.instance1.name:comparison.instance1.resultId}</a></th>
                <th if={comparison.instance2} title={comparison.instance2.title}><a href={comparison.instance2.resultId} target="_blank">{comparison.instance2.name?comparison.instance2.name:comparison.instance2.resultId}</a></th>
            </tr>
        </thead>
        <tbody>
            <tr each={property in comparison.properties} >
                <td title={property.name}>{property.shortName}</td>
                <td if={comparison.instance1}><kg-instance-property if={property.instance1} content={property.instance1}></kg-instance-property></td>
                <td if={comparison.instance2}><kg-instance-property if={property.instance2} content={property.instance2}></kg-instance-property></td>
            </tr>
        </tbody>
    </table>
    
    <script>
        this.isComparison = false;
        this.comparison = null;

        this.on("mount", function () {
            RiotPolice.requestStore("instances", this);
        });

        this.on("update", function () {
            this.isComparison = this.stores.instances.is("COMPARISON");
            const isLoading = this.stores.instances.is("QUERY_LOADING");
            if (!isLoading || this.comparison === null) {
                if (this.isComparison) 
                    this.comparison = this.stores.instances.getComparison();
                else 
                    this.comparison = null;
            }
        });
    </script>
</kg-instances-body>