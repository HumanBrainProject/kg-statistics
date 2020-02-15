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
    let hiddenTypes = [];
    let hiddenSpaces = [];
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
    };

    const generateGroupViewData = (nodes, relations) => {

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
        
        hiddenTypes = _(nodes).filter(node => node.hidden).map(node => node.id).value();
    };

    const generateTypeViewData = (nodes, relations) => {

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

        hiddenTypes = _(nodes).filter(node => node.hidden).map(node => node.id).value();
    };

    const simplifyTypeSemantics = type => ({
        id: type["http://schema.org/identifier"],
        name: type["http://schema.org/name"],
        occurrences: type["https://kg.ebrains.eu/vocab/meta/occurrences"],
        properties: type["https://kg.ebrains.eu/vocab/meta/properties"].map(property => ({
            id: property["http://schema.org/identifier"],
            name: property["http://schema.org/name"],
            occurrences: property["https://kg.ebrains.eu/vocab/meta/occurrences"],
            targetTypes: property["https://kg.ebrains.eu/vocab/meta/targetTypes"].map(targetType => ({
                id: targetType["http://schema.org/name"],
                occurrences: targetType["https://kg.ebrains.eu/vocab/meta/occurrences"]
            }))
        }))
    });

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
                name: link["http://schema.org/name"],
                type: link["http://schema.org/target"],
                occurrences: link["https://kg.ebrains.eu/vocab/meta/occurrences"]
            }));
        }
        if(type["https://kg.ebrains.eu/vocab/meta/spaces"]) {
            result.spaces = type["https://kg.ebrains.eu/vocab/meta/spaces"].map(space => {
                const res = {
                    name: space["http://schema.org/name"],
                    occurrences: space["https://kg.ebrains.eu/vocab/meta/occurrences"],
                    links: []
                };
                if(space["https://kg.ebrains.eu/vocab/meta/links"]) {
                    res.links = space["https://kg.ebrains.eu/vocab/meta/links"].map(link => ({
                        id: link["http://schema.org/identifier"],
                        name: link["http://schema.org/name"],
                        type: link["http://schema.org/type"],
                        space: link["http://schema.org/space"]
                    }));
                }
                return res;
            });
        }
        return result;
    };

    const buildRelations = links => {
        const relations = {};
        links.forEach(link => {
            if (relations[link.source] === undefined) {
                relations[link.source] = [];
            }
            relations[link.source].push({
                relationId: link.id,
                relatedType: link.target,
                relatedTypeHash: link.targetHash,
                relationCount: link.value,
                relationName: link.name
            });
            if (relations[link.target] === undefined) {
                relations[link.target] = [];
            }
            if (link.source !== link.target) {
                relations[link.target].push({
                    relationId: link.id,
                    relatedType: link.source,
                    relatedTypeHash: link.sourceHash,
                    relationCount: link.value,
                    relationName: link.name
                });
            }
        });
        return relations;
    };

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
            const hash = md5(type.id);
            const node = {
                hash: hash,
                id: type.id,
                label: type.name,
                occurrences: type.occurrences,
                properties: [],
                isLoading: false,
                isLoaded: false,
                error: null,
            };
            node.parent = node;
            result.typesMode.nodes.push(node);
            result.typesMode.links = type.links.map(link => ({
                id: link.id,
                name: link.name,
                source: link.id,
                sourceHash: hash,
                target: link.type,
                targetHash: md5(link.type),
                provenance: link.name !== undefined && link.name.startsWith(AppConfig.structure.provenance),
                value: link.occurrences
            }));
            type.spaces.forEach(space => {
                result.groupsMode.nodes.push({
                    hash: md5(space.name + "/" + type.id),
                    id: type.id,
                    label: type.name,
                    occurrences: space.occurrences,
                    group: space.name,
                    parent: node
                });
                space.links.forEach(link => {
                    result.groupsMode.links.push({
                        id: link.id,
                        name: link.name,
                        source: type.id,
                        sourceGroup: space.name,
                        sourceHash: hash,
                        target: link.type,
                        targetGroup: link.space,
                        targetHash: md5(link.type),
                        provenance: link.name !== undefined && link.name.startsWith(AppConfig.structure.provenance)
                    });
                });
            });
        });
        result.groupsMode.relations = buildRelations(result.groupsMode.links);
        result.typesMode.relations = buildRelations(result.typesMode.links);
        return result;
      };

    const loadStructure = () => {
        if (!structureStore.is("STRUCTURE_LOADING")) {
            structureStore.toggleState("STRUCTURE_LOADING", true);
            structureStore.toggleState("STRUCTURE_ERROR", false);
            structureStore.notifyChange();
            fetch(`/api/types?stage=LIVE&withProperties=false`)
            .then(response => response.json())
            .then(data => {
                structure = buildStructure(data);
                generateViewData(groupViewMode);
                lastUpdate = new Date();
                structureStore.toggleState("STRUCTURE_LOADED", true);
                structureStore.toggleState("STRUCTURE_LOADING", false);
                structureStore.notifyChange();
            })
            .catch(e => {
                debugger;
                structureStore.toggleState("STRUCTURE_ERROR", true);
                structureStore.toggleState("STRUCTURE_LOADED", false);
                structureStore.toggleState("STRUCTURE_LOADING", false);
                structureStore.notifyChange();
            });
        }
    };

    const loadType = type => {
        if (!type.isLoaded && !type.isLoading) {
            if (!structureStore.is("TYPE_LOADING")) {
                type.error = null;
                type.isLoading = true;
                structureStore.toggleState("TYPE_LOADING", true);
                structureStore.toggleState("TYPE_ERROR", false);
                structureStore.notifyChange();
                fetch(`/api/typesByName?stage=LIVE&withProperties=true&name=${type.id}`)
                .then(response => response.json())
                .then(data => {
                    const definition = simplifyTypeSemantics(data.data);
                    type.properties = definition.properties.sort((a, b) => b.occurrences - a.occurrences);
                    type.isLoaded = true;
                    type.isLoading = false;
                    structureStore.toggleState("TYPE_LOADED", false);
                    structureStore.toggleState("TYPE_LOADING", false);
                    structureStore.notifyChange();
                })
                .catch(e => {
                    type.error = e;
                    type.isLoading = false;
                    structureStore.toggleState("TYPE_ERROR", true);
                    structureStore.toggleState("TYPE_LOADED", false);
                    structureStore.toggleState("TYPE_LOADING", false);
                    structureStore.notifyChange();
                });
            }
        }
    };

    const getNodes = () => structure ? (groupViewMode?structure.groupsMode.nodes:structure.typesMode.nodes):[];

    const getLinks = () => structure ? (groupViewMode?structure.groupsMode.links:structure.typesMode.links):[];

    const getRelations = () => structure ? (groupViewMode?structure.groupsMode.relations:structure.typesMode.relations):[];
    
    const getRelationsOf = id => {
        const rel = getRelations()[id];
        if (!rel) {
            return [];
        }
        return rel;
    };
    
    const init = () => {
        
    };

    const reset = () => {

    };

    const structureStore = new RiotStore("structure",
    [
        "STRUCTURE_LOADING", "STRUCTURE_ERROR",  "STRUCTURE_LOADED",
        "SELECTED_TYPE", "TYPE_HIGHLIGHTED", "TYPE_LOADING", "TYPE_LOADED", "TYPE_ERROR",
        "GROUP_VIEW_MODE", "SEARCH_ACTIVE", "HIDE_ACTIVE", "HIDE_SPACES_ACTIVE"
    ],
    init, reset);

    /**
     * Store trigerrable actions
     */

    structureStore.addAction("structure:load", loadStructure);


    structureStore.addAction("structure:toggle_group_view_mode", () => {
        generateViewData(!groupViewMode);
        structureStore.toggleState("GROUP_VIEW_MODE", groupViewMode);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_select", type => {
        if (typeof type === "string") {
            type = _.find(structure.nodes, node => node.id === type);
        }
        if (type !== selectedType || type === undefined) {
            structureStore.toggleState("TYPE_HIGHLIGHTED", false);
            highlightedType = undefined;
            structureStore.toggleState("SELECTED_TYPE", !!type);
            structureStore.toggleState("SEARCH_ACTIVE", false);
            loadType(type.parent);
            selectedType = type;
        } else {
            structureStore.toggleState("TYPE_HIGHLIGHTED", false);
            highlightedType = undefined;
            structureStore.toggleState("SELECTED_TYPE", false);
            selectedType = undefined;
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_highlight", type => {
        if (typeof type === "string") {
            type = _.find(structure.nodes, node => node.id === type);
        }
        structureStore.toggleState("TYPE_HIGHLIGHTED", !!type);
        highlightedType = type;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_unhighlight", () => {
        structureStore.toggleState("TYPE_HIGHLIGHTED", false);
        highlightedType = undefined;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search", query => {
        if (query) {
            searchQuery = query;
            searchResults = _.filter(structure.typesMode.nodes, node => node.id.match(new RegExp(query, "gi")));
        } else {
            searchQuery = query;
            searchResults = [];
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search_toggle", () => {
        structureStore.toggleState("SEARCH_ACTIVE");
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:hide_toggle", () => {
        structureStore.toggleState("HIDE_ACTIVE");
        structureStore.notifyChange();
    });
    structureStore.addAction("structure:hide_spaces_toggle", () => {
        structureStore.toggleState("HIDE_SPACES_ACTIVE");
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_toggle_hide", type => {
        if (typeof type === "string") {
            type = _.find(structure.nodes, node => node.id === type);
        }
        if (type !== undefined && type === selectedType) {
            structureStore.toggleState("TYPE_HIGHLIGHTED", false);
            highlightedType = undefined;
            structureStore.toggleState("SELECTED_TYPE", false);
            selectedType = undefined;
        }
        type.hidden = !type.hidden;
        hiddenTypes = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenTypes));
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:space_toggle_hide", space => {
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
        hiddenTypes = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenTypes));
        hiddenSpaces = hiddenArray;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:all_types_toggle_hide",  hide => {
        structureStore.toggleState("TYPE_HIGHLIGHTED", false);
        highlightedType = undefined;
        structureStore.toggleState("SELECTED_TYPE", false);
        selectedType = undefined;

        structure.nodes.forEach(node => { node.hidden = !!hide });
        hiddenTypes = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenTypes));
        if (!hide) {
            hiddenSpaces = [];
        } else {
            hiddenSpaces = Object.keys(getGroups(structure.nodes));
        }
        localStorage.setItem(hiddenSpacesLocalKey, JSON.stringify(hiddenSpaces));
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:all_spaces_show", () => {
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
        hiddenTypes = _(structure.nodes).filter(node => node.hidden).map(node => node.id).value();
        localStorage.removeItem(hiddenSpacesLocalKey);
        localStorage.setItem(hiddenNodesLocalKey, JSON.stringify(hiddenTypes));
        structureStore.notifyChange();
    });

    /**
     * Store public interfaces
     */

    structureStore.addInterface("getLastUpdate", () => lastUpdate);

    structureStore.addInterface("getSelectedType", () => selectedType);

    structureStore.addInterface("getHighlightedType", () => highlightedType);
    
    structureStore.addInterface("getNodes", getNodes);

    structureStore.addInterface("getLinks", getLinks);

    structureStore.addInterface("getHiddenTypes", () => hiddenTypes);

    structureStore.addInterface("getHiddenSpaces", () => hiddenSpaces);

    structureStore.addInterface("getRelationsOf", getRelationsOf);

    structureStore.addInterface("hasRelations", (id, filterHidden) => {
        if (filterHidden) {
            const relations = _(getRelationsOf(id)).filter(rel => hiddenTypes.indexOf(rel.relatedType) === -1).value();
            return !!relations.length;
        } else {
            return getRelationsOf(id).length;
        }
    });

    structureStore.addInterface("getSearchQuery", () => searchQuery);

    structureStore.addInterface("getSearchResults", () => searchResults);

    RiotPolice.registerStore(structureStore);
})();
