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
    let structure = null;
    let lastUpdate = null;
    let groupViewMode = false;
    let hiddenSchemas = [];
    let hiddenSpaces = [];
    let types = {};
    let selectedType;
    let highlightedType;
    let searchQuery = "";
    let searchResults = [];
    let minNodeCounts = 6;
    let whitelist = [
        "minds/core/structureet/v0.0.4"
    ];
    const hiddenSpacesLocalKey = "hiddenSpaces";
    const hiddenNodesLocalKey = "hiddenNodes";

    const getGroups = nodes => nodes.reduce((acc, node) => {
        const group = acc[node.group] || {};
        const nodes = group.value || [];
        nodes.push(node);
        let storedHiddenSpaces = JSON.parse(localStorage.getItem(hiddenSpacesLocalKey)) || [];
        acc[node.group] = {
            value: nodes, 
            hidden: storedHiddenSpaces.includes(node.group)
        };
        return acc;
    }, {});

    const generateViewData = function(on) {
        groupViewMode = !!on;
        if (groupViewMode) {
            generateGroupViewData(structure.groupsMode.nodes, structure.groupsMode.relations);
        } else {
            generateTypeViewData(structure.typesMode.nodes, structure.typesMode.relations);
        }
    }

    const generateGroupViewData = function (nodes, relations) {

        const groups = getGroups(nodes);

        let toBeHidden;
        //First use
        if (!localStorage.getItem(hiddenNodesLocalKey)) {
            toBeHidden = [];
            //Hidding nodes with too many connections
            nodes.forEach(node => {
                node.hidden = false;
                if (relations[node.id] !== undefined &&
                    whitelist.indexOf(node.id) < 0 &&
                    groups[node.group].value.length > minNodeCounts &&
                    relations[node.id].length / groups[node.group].value.length > AppConfig.structure.autoHideThreshold
                ) {
                    toBeHidden.push(node.id);
                }
            });
            localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(toBeHidden));
        } else {
            toBeHidden = JSON.parse(localStorage.getItem(hiddenNodesLocalKey));
        }

        nodes.forEach(node => {
            node.hidden = false;
            if (relations[node.id] !== undefined &&
                whitelist.indexOf(node.id) < 0 &&
                groups[node.group].hidden ||
                toBeHidden.includes(node.id)
            ) {
                node.hidden = true;
            }
        });

        for (item in groups) {
            if (groups[item].hidden) {
                hiddenSpaces.push(item);
            }
        }

        hiddenSchemas = _(nodes).filter(node => node.hidden).map(node => node.id).value();
    }

    const generateTypeViewData = function (nodes, relations) {

        let toBeHidden;
        //First use
        if (!localStorage.getItem(hiddenNodesLocalKey)) {
            toBeHidden = [];
            //Hidding nodes with too many connections
            nodes.forEach(node => {
                node.hidden = false;
                if (relations[node.id] !== undefined &&
                    whitelist.indexOf(node.id) < 0 &&
                    relations[node.id].length / structure.nodes.length > AppConfig.structure.autoHideThreshold
                ) {
                    toBeHidden.push(node.id);
                }
            });
            localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(toBeHidden));
        } else {
            toBeHidden = JSON.parse(localStorage.getItem(hiddenNodesLocalKey));
        }

        nodes.forEach(node => {
            node.hidden = false;
            if (relations[node.id] !== undefined &&
                whitelist.indexOf(node.id) < 0 &&
                toBeHidden.includes(node.id)
            ) {
                node.hidden = true;
            }
        });

        hiddenSchemas = _(nodes).filter(node => node.hidden).map(node => node.id).value();
    }

    const simplifyTypesSemantics = data => {
        Object.entries(data.data).forEach(([name, schemas]) => {
            Object.entries(schemas).forEach(([version, schema]) => {
                schema.properties.forEach(p => {
                    const m1 = p.name && p.name.length && p.name.match(/.+#(.+)$/);
                    const m2 = p.name && p.name.length && p.name.match(/.+\/(.+)$/);
                    const m3 = p.name && p.name.length && p.name.match(/.+:(.+)$/);
                    p.shortName = (m1 && m1.length === 2) ? m1[1] : (m2 && m2.length === 2) ? m2[1] : (m3 && m3.length === 2) ? m3[1] : p.name;
                });
            });
        });
    };

    const simplifyStructureSemantics = type => {
        const result = {
            id: type["http://schema.org/identifier"],
            name: type["http://schema.org/name"],
            occurrences: type["https://kg.ebrains.eu/vocab/meta/occurrences"],
            links: [],
            spaces: []
        };
        if(type["https://kg.ebrains.eu/vocab/meta/links"]) {
            result.links = type["https://kg.ebrains.eu/vocab/meta/links"].map(link => ({
                id: link["http://schema.org/identifier"],
                name:  link["http://schema.org/name"],
                target: link["http://schema.org/target"],
                value: link["http://schema.org/value"]
            }));
        }
        if(type["https://kg.ebrains.eu/vocab/meta/spaces"]) {
            result.spaces = type["https://kg.ebrains.eu/vocab/meta/spaces"].map(space => {
                const res = {
                    name:  space["http://schema.org/name"],
                    occurrences: space["https://kg.ebrains.eu/vocab/meta/occurrences"],
                    links: []
                };
                if(space["https://kg.ebrains.eu/vocab/meta/links"]) {
                    res.links = space["https://kg.ebrains.eu/vocab/meta/links"].map(link => ({
                        id: link["http://schema.org/identifier"],
                        name:  link["http://schema.org/name"],
                        target: link["http://schema.org/target"],
                        target_group: link["http://schema.org/targetGroup"]
                    }));
                }
                return res;
            });
        }
        return result;
    }

    const buildRelations = function(links) {
        const relations = {};
        links.forEach(link => {
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
        return relations;
    }

    const buildStructure = data => {
        const result = {
            groupsMode: {
                nodes: [],
                links: [],
                relations: {}
            },
            typesMode: {
                nodes: [],
                links: [],
                relations: {}
            }
        };
        data.data.forEach(rawType => {
            const type = simplifyStructureSemantics(rawType);
            result.typesMode.nodes.push({
                hash: md5(type.id),
                id: type.id,
                schema: type.id, 
                label: type.name,
                numberOfInstances: type.occurrences
            });
            result.typesMode.links = type.links.map(link => ({
                id: link.id,
                name: link.name,
                source: link.id,
                target: link.target,
                provenance: link.name !== undefined && link.name.startsWith(AppConfig.structure.provenance),
                value: link.value
            }));
            type.spaces.forEach(space => {
                result.groupsMode.nodes.push({
                    hash: md5(space.name + "/" + type.id),
                    id: type.id,
                    schema: type.id, 
                    label: type.name,
                    numberOfInstances: space.occurrences,
                    group: space.name
                });
                space.links.forEach(link => {
                    result.groupsMode.links.push({
                        id: link.id,
                        name: link.name,
                        source: type.id,
                        source_group: space.name,
                        target: link.target,
                        target_group: link.target_group,
                        provenance: link.name !== undefined && link.name.startsWith(AppConfig.structure.provenance)
                    });
                });
            });
        });
        result.groupsMode.relations = buildRelations(result.groupsMode.links);
        result.typesMode.relations = buildRelations(result.typesMode.links);
        return result;
      };

    const loadStructure = function () {
        if (!structureStore.is("STRUCTURE_LOADING")) {
            structureStore.toggleState("STRUCTURE_LOADING", true);
            structureStore.toggleState("STRUCTURE_ERROR", false);
            structureStore.notifyChange();
            fetch(`/api/types?stage=LIVE&withProperties=false`)
            .then(response => response.json())
            .then(data => {
                structure = buildStructure(data);
                generateViewData(groupViewMode);
                types = {};
                lastUpdate = new Date();
                structureStore.toggleState("STRUCTURE_LOADED", true);
                structureStore.toggleState("STRUCTURE_LOADING", false);
                structureStore.notifyChange();
            })
            .catch(e => {
                structureStore.toggleState("STRUCTURE_ERROR", true);
                structureStore.toggleState("STRUCTURE_LOADED", false);
                structureStore.toggleState("STRUCTURE_LOADING", false);
                structureStore.notifyChange();
            });
        }
    }

    const loadType = function (name) {
        if (!structureStore.is("TYPE_LOADING")) {
            structureStore.toggleState("TYPE_LOADING", true);
            structureStore.toggleState("TYPE_ERROR", false);
            structureStore.notifyChange();
            fetch(`/api/typesByName?stage=LIVE&withProperties=true&name=${name}`)
            .then(response => response.json())
            .then(data => types = simplifyTypeSemantics(data))
            .catch(e => {
                structureStore.toggleState("TYPE_ERROR", true);
                structureStore.toggleState("TYPE_LOADED", false);
                structureStore.toggleState("TYPE_LOADING", false);
                structureStore.notifyChange();
            });
        }
    }

    const getNodes = () => structure ? (groupViewMode?structure.groupsMode.nodes:structure.typesMode.nodes):[];

    const getLinks = () => structure ? (groupViewMode?structure.groupsMode.links:structure.typesMode.links):[];

    const getRelations = () => structure ? (groupViewMode?structure.groupsMode.relations:structure.typesMode.relations):[];
    
    const getRelationsOf = id => {
        const rel = getRelations()[id];
        if (!rel) {
            return [];
        }
        return rel;
    }
    
    const init = function () {
        
    }

    const reset = function () {

    }

    const structureStore = new RiotStore("structure",
    [
        "STRUCTURE_LOADING", "STRUCTURE_ERROR",  "STRUCTURE_LOADED",
        "TYPE_SELECTED", "TYPE_HIGHLIGHTED", "TYPE_LOADING", "TYPE_LOADED", "TYPE_ERROR",
        "GROUP_VIEW_MODE", "SEARCH_ACTIVE", "HIDE_ACTIVE", "HIDE_SPACES_ACTIVE"
    ],
    init, reset);

    /**
     * Store trigerrable actions
     */

    structureStore.addAction("structure:load", function () {
        loadStructure();
    });


    structureStore.addAction("structure:toggle_group_view_mode", function () {
        generateViewData(!groupViewMode);
        structureStore.toggleState("GROUP_VIEW_MODE", groupViewMode);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:schema_select", function (schema) {
        if (typeof schema === "string") {
            schema = _.find(structure.nodes, node => node.id === schema);
        }
        if (schema !== selectedType || schema === undefined) {
            structureStore.toggleState("TYPE_HIGHLIGHTED", false);
            highlightedType = undefined;
            structureStore.toggleState("TYPE_SELECTED", true);
            structureStore.toggleState("SEARCH_ACTIVE", false);
            selectedType = schema;
        } else {
            structureStore.toggleState("TYPE_HIGHLIGHTED", false);
            highlightedType = undefined;
            structureStore.toggleState("TYPE_SELECTED", false);
            selectedType = undefined;
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:schema_highlight", function (schema) {
        if (typeof schema === "string") {
            schema = _.find(structure.nodes, node => node.id === schema);
        }
        structureStore.toggleState("TYPE_HIGHLIGHTED", true);
        highlightedType = schema;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:schema_unhighlight", function () {
        structureStore.toggleState("TYPE_HIGHLIGHTED", false);
        highlightedType = undefined;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search", function (query) {
        if (query) {
            searchQuery = query;
            searchResults = _.filter(structure.nodes, node => node.id.match(new RegExp(query, "g")));
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
    structureStore.addAction("structure:hide_spaces_toggle", function () {
        structureStore.toggleState("HIDE_SPACES_ACTIVE");
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:schema_toggle_hide", function (schema) {
        if (typeof schema === "string") {
            schema = _.find(structure.nodes, node => node.id === schema);
        }
        if (schema !== undefined && schema === selectedType) {
            structureStore.toggleState("TYPE_HIGHLIGHTED", false);
            highlightedType = undefined;
            structureStore.toggleState("TYPE_SELECTED", false);
            selectedType = undefined;
        }
        schema.hidden = !schema.hidden;
        hiddenSchemas = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenSchemas));
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:space_toggle_hide", function (space) {
        let spaceNodes = [];
        spaceNodes = _.filter(structure.nodes, node => node.group === space)
        let group = getGroups(structure.nodes);
        let hiddenArray = JSON.parse(localStorage.getItem(hiddenSpacesLocalKey)) || [];
        let previousHiddenState = group[space] && group[space].hidden;
        if (previousHiddenState) {
            hiddenArray = hiddenArray.slice(1, hiddenArray.indexOf(space));
        } else {
            hiddenArray.push(space);
        }
        spaceNodes.map((node) => {
            node.hidden = !previousHiddenState;
            return node;
        });
        localStorage.setItem(hiddenSpacesLocalKey, JSON.stringify(hiddenArray));
        hiddenSchemas = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenSchemas));
        hiddenSpaces = hiddenArray;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:all_schemas_toggle_hide", function (hide) {
        structureStore.toggleState("TYPE_HIGHLIGHTED", false);
        highlightedType = undefined;
        structureStore.toggleState("TYPE_SELECTED", false);
        selectedType = undefined;

        structure.nodes.forEach(node => { node.hidden = !!hide });
        hiddenSchemas = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenSchemas));
        if (!hide) {
            hiddenSpaces = [];
        } else {
            hiddenSpaces = Object.keys(getGroups(structure.nodes));
        }
        localStorage.setItem(hiddenSpacesLocalKey, JSON.stringify(hiddenSpaces));
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:all_spaces_show", function () {
        let group = getGroups(structure.nodes);
        let spacesToShow = [];
        for (let space in group) {
            if (group[space].hidden) {
                spacesToShow.push(space);
            }
        }
        structure.nodes.forEach(node => {
            if (spacesToShow.includes(node.group)) {
                node.hidden = false;
            }
        });
        hiddenSpaces = [];
        hiddenSchemas = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.removeItem(hiddenSpacesLocalKey);
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenSchemas));
        structureStore.notifyChange();
    });

    /**
     * Store public interfaces
     */

    structureStore.addInterface("getLastUpdate", function () {
        return lastUpdate;
    });

    structureStore.addInterface("getSelectedSchema", function () {
        return selectedType;
    });

    structureStore.addInterface("getHighlightedSchema", function () {
        return highlightedType;
    });
    
    structureStore.addInterface("getNodes", getNodes);

    structureStore.addInterface("getLinks", getLinks);

    structureStore.addInterface("getHiddenSchemas", function () {
        return hiddenSchemas;
    });

    structureStore.addInterface("getHiddenSpaces", function () {
        return hiddenSpaces;
    });

    structureStore.addInterface("getRelationsOf", getRelationsOf);

    structureStore.addInterface("hasRelations", function (id, filterHidden) {
        if (filterHidden) {
            let schemaRelations = _(getRelationsOf(id)).filter(rel => hiddenSchemas.indexOf(rel.relatedSchema) === -1).value();
            return !!schemaRelations.length;
        } else {
            return getRelationsOf(id).length;
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
