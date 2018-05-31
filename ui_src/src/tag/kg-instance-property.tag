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
<kg-instance-property>
    <style scoped>
        :scope {
        
        }

        pre {
            margin: 5px; 
            padding: 5px; 
            /*outline: 1px solid #ccc; */
        }
        .string { 
            /*display: inline-block;
            max-width: 300px;
            text-overflow: ellipsis;
            vertical-align: bottom;
            overflow: hidden; */
            color: white; 
            word-break: break-all;
            cursor: default;
        }
        .number { 
            color: red; 
            cursor: default;
        }
        .boolean { 
            color: darkorange;  
            cursor: default;
        }
        .null { 
            color: magenta;  
            cursor: default;
        }
        .key { 
            color: #548dde;  
            cursor: default;
        }
        .key a { 
            color: #548dde;  
        }
        .key a:hover { 
            color: #7eaae7;  
        }

    </style>

    <script>

         function syntaxHighlight(json) {
            json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
            return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
                var cls = 'number';
                if (/^"/.test(match)) {
                    if (/:$/.test(match)) {
                        cls = 'key';
                    } else {
                        cls = 'string';
                    }
                } else if (/true|false/.test(match)) {
                    cls = 'boolean';
                } else if (/null/.test(match)) {
                    cls = 'null';
                }
                let value = match;
                let m =  value.match(/".+#(.+":?)$/);
                if (m && m.length)
                    value = '"' + m[1];
                m = value.match(/".+\/v0\/data\/.+\/.+\/(.+)\/.+\/(.+":?)$/);
                if (m && m.length == 3)
                    value = '"' + m[1] + ':' + m[2];
                let l = match.match(/"(https?:\/\/.+)(":?)$/) 
                if (l && l.length == 3)
                    value = '"<a href="' + l[1] + '" target="_blank">' + value.replace(/":/g, "").replace(/"/g, "") + '</a>' + l[2];
                return '<span class="' + cls + '" title="' +  match.replace(/"/g,"") + '">' + value + '</span>';
            });
        }

        this.updateContent = () => {
            let value = this.opts.content;
            if (value != undefined) {
                if (typeof value === "object" || value instanceof Array) {
                    value = JSON.stringify(value, undefined, 2);
                    value = syntaxHighlight(value);
                    value = '<pre>' + value + '</pre>';
                }
                this.root.innerHTML = value;
            }
        };

        this.on("mount", function () {
           this.updateContent();
        });

        this.on('update', () => {
            this.updateContent();
        });

    </script>
</kg-instance-property>