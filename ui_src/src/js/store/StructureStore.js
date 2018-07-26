/*
*   Copyright (c) 2018, EPFL/Human Brain Project PCO
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*/

(function () {
    let datas;
    let hiddenSchemas = [];
    let relations;
    let selectedSchema;
    let highlightedSchema;
    let searchQuery = "";
    let searchResults = [];
    let minNodeCounts = 6;
    let whitelist = [
        "minds/core/dataset/v0.0.4"
    ];

    window.testdatas = function () {
        return datas;
    }

    const loadData = function (datas) {
        relations = {};
        datas.links.forEach(link => {
            link.provenance = link.name !== undefined && link.name.startsWith(AppConfig.structure.provenance)
            if (relations[link.source] === undefined) {
                relations[link.source] = [];
            }
            relations[link.source].push({
                relationId: link.id,
                relatedSchema: link.target,
                relationCount: link.value,
                relationName: link.name
            });
            if (relations[link.target] === undefined) {
                relations[link.target] = [];
            }
            if (link.source !== link.target) {
                relations[link.target].push({
                    relationId: link.id,
                    relatedSchema: link.source,
                    relationCount: link.value,
                    relationName: link.name
                });
            }
        });
        let group = datas.nodes.reduce((map, node) => {
            let i = map[node.group] || []
            i.push(node)
            map[node.group] = i
            return map
        }, {})
        
        //Hidding nodes with too many connections
        datas.nodes.forEach(node => {
            node.hash = md5(node.id);
            node.hidden = false;
            if (relations[node.id] !== undefined && 
                whitelist.indexOf(node.id) < 0 &&
                group[node.group].length > minNodeCounts &&
                relations[node.id].length / group[node.group].length > AppConfig.structure.autoHideThreshold) {
                node.hidden = true;
            }
        });

        hiddenSchemas = _(datas.nodes).filter(node => node.hidden).map(node => node.id).value();

        Object.entries(datas.schemas).forEach(([name, schemas]) => {
            Object.entries(schemas).forEach(([version, schema]) => {
                schema.properties.forEach(p => {
                    const m1 = p.name && p.name.length && p.name.match(/.+#(.+)$/);
                    const m2 = p.name && p.name.length && p.name.match(/.+\/(.+)$/);
                    const m3 = p.name && p.name.length && p.name.match(/.+:(.+)$/);
                    p.shortName = (m1 && m1.length===2)?m1[1]:(m2 && m2.length===2)?m2[1]:(m3 && m3.length===2)?m3[1]:p.name;
                });
            });
        });
        structureStore.toggleState("DATAS_LOADED", true);
        structureStore.toggleState("DATAS_LOADING", false);
        structureStore.notifyChange();
    }
    var retrigger = true;
    const init = function () {
        if (!datas && !structureStore.is("DATAS_LOADING")) {
            structureStore.toggleState("DATAS_LOADING", true);
            $.get("structure.json", function (response) {
                console.log(response);
                datas = response;
                if(datas){
                    loadData(datas);
                }else{
                    structureStore.toggleState("DATAS_LOADING", false);
                    if(retrigger){
                        retrigger = false;
                        init();
                    }
                }
            });
        }
    }

    const reset = function () {

    }

    const structureStore = new RiotStore("structure",
        ["DATAS_LOADING", "DATAS_LOADED", "SCHEMA_SELECTED", "SCHEMA_HIGHLIGHTED", "SEARCH_ACTIVE", "HIDE_ACTIVE", "SHOW_MODAL", "SHOW_MENU", "SHOW_STATUS_REPORT"],
        init, reset);

    /**
     * Store trigerrable actions
     */

    structureStore.addAction("structure:schema_select", function (schema) {
        if (typeof schema === "string") {
            schema = _.find(datas.nodes, node => node.id === schema);
        }
        if (schema !== selectedSchema || schema === undefined) {
            structureStore.toggleState("SCHEMA_HIGHLIGHTED", false);
            highlightedSchema = undefined;
            structureStore.toggleState("SCHEMA_SELECTED", true);
            structureStore.toggleState("SEARCH_ACTIVE", false);
            selectedSchema = schema;
        } else {
            structureStore.toggleState("SCHEMA_HIGHLIGHTED", false);
            highlightedSchema = undefined;
            structureStore.toggleState("SCHEMA_SELECTED", false);
            selectedSchema = undefined;
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:schema_highlight", function (schema) {
        if (typeof schema === "string") {
            schema = _.find(datas.nodes, node => node.id === schema);
        }
        structureStore.toggleState("SCHEMA_HIGHLIGHTED", true);
        highlightedSchema = schema;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:schema_unhighlight", function () {
        structureStore.toggleState("SCHEMA_HIGHLIGHTED", false);
        highlightedSchema = undefined;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search", function (query) {
        if (query) {
            searchQuery = query;
            searchResults = _.filter(datas.nodes, node => node.id.match(new RegExp(query, "g")));
        } else {
            searchQuery = query;
            searchResults = [];
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search_toggle", function () {
        structureStore.toggleState("SEARCH_ACTIVE");
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:hide_toggle", function () {
        structureStore.toggleState("HIDE_ACTIVE");
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:schema_toggle_hide", function (schema) {
        if (typeof schema === "string") {
            schema = _.find(datas.nodes, node => node.id === schema);
        }
        if (schema !== undefined && schema === selectedSchema) {
            structureStore.toggleState("SCHEMA_HIGHLIGHTED", false);
            highlightedSchema = undefined;
            structureStore.toggleState("SCHEMA_SELECTED", false);
            selectedSchema = undefined;
        }
        schema.hidden = !schema.hidden;
        hiddenSchemas = _(datas.nodes).filter(node => node.hidden).map(node => node.id).value();
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:all_schemas_toggle_hide", function (hide) {
        structureStore.toggleState("SCHEMA_HIGHLIGHTED", false);
        highlightedSchema = undefined;
        structureStore.toggleState("SCHEMA_SELECTED", false);
        selectedSchema = undefined;

        datas.nodes.forEach(node => { node.hidden = !!hide });
        hiddenSchemas = _(datas.nodes).filter(node => node.hidden).map(node => node.id).value();
        structureStore.notifyChange();
    });

    structureStore.addAction("modal:show_postman_tests", function (show) {
        structureStore.toggleState("SHOW_MODAL", show);
        structureStore.notifyChange();
    })

    structureStore.addAction("modal:show_status_report", function (show) {
        structureStore.toggleState("SHOW_STATUS_REPORT", show);
        structureStore.notifyChange();
    })
    structureStore.addAction("modal:show_menu", function (show) {
        structureStore.toggleState("SHOW_MENU", show);
        structureStore.notifyChange();
    })
    /**
     * Store public interfaces
     */

    structureStore.addInterface("getSelectedSchema", function () {
        return selectedSchema;
    });

    structureStore.addInterface("getHighlightedSchema", function () {
        return highlightedSchema;
    });

    structureStore.addInterface("getDatas", function () {
        return datas;
    });

    structureStore.addInterface("getHiddenSchemas", function () {
        return hiddenSchemas;
    });

    structureStore.addInterface("getRelationsOf", function (id) {
        return relations[id] || [];
    });

    structureStore.addInterface("hasRelations", function (id, filterHidden) {
        if(filterHidden){
            let schemaRelations = _(relations[id] || []).filter(rel => hiddenSchemas.indexOf(rel.relatedSchema) === -1).value();
            return !!schemaRelations.length; 
        } else {
            return (relations[id] || []).length;
        }
    });

    structureStore.addInterface("getSearchQuery", function () {
        return searchQuery;
    });

    structureStore.addInterface("getSearchResults", function () {
        return searchResults;
    })

    RiotPolice.registerStore(structureStore);
})();
