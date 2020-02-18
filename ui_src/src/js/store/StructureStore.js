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
    let types = {};
    let structure = {
        nodes: [],
        groupedNodes: [],
        links: []
    };
    let selectedType = null;
    let groupViewModeLinks = [];
    let groupViewModeRelations = [];
    let lastUpdate = null;
    let groupViewMode = false;
    let hiddenTypes = [];
    let hiddenSpaces = [];
    let selectedNode;
    let highlightedNode;
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

    const generateViewData = function (on) {
        groupViewMode = !!on;
        if (groupViewMode) {
            generateGroupViewData();
        } else {
            generateDefaultViewData();
        }
    };

    const generateGroupViewData = () => {

        const nodes = structure.groupedNodes;

        const groups = getGroups(nodes);

        let toBeHidden;
        //First use
        if (!localStorage.getItem(hiddenNodesLocalKey)) {
            toBeHidden = [];
            //Hidding nodes with too many connections
            nodes.forEach(node => {
                node.hidden = false;
                if (node.relations.length &&
                    whitelist.indexOf(node.id) < 0 &&
                    groups[node.group].value.length > minNodeCounts &&
                    node.relations.length / groups[node.group].value.length > AppConfig.structure.autoHideThreshold
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
            if (node.relations.length &&
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

    const generateDefaultViewData = () => {

        const nodes = structure.nodes;

        let toBeHidden;
        //First use
        if (!localStorage.getItem(hiddenNodesLocalKey)) {
            toBeHidden = [];
            //Hidding nodes with too many connections
            nodes.forEach(node => {
                node.hidden = false;
                if (node.relations.length &&
                    whitelist.indexOf(node.id) < 0 &&
                    node.relations.length / structure.nodes.length > AppConfig.structure.autoHideThreshold
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
            if (node.relations.length &&
                whitelist.indexOf(node.type.id) < 0 &&
                toBeHidden.includes(node.type.id)
            ) {
                node.hidden = true;
            }
        });

        hiddenTypes = _(nodes).filter(node => node.hidden).map(node => node.type.id).value();
    };


    const hashCode = text => {
        let hash = 0;
        if (typeof text !== "string" || text.length === 0) {
            return hash;
        }
        for (let i = 0; i < text.length; i++) {
            const char = text.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        return hash;
    };

    const simplifySemantics = rawtype => {
        const type = {
            id: rawtype["http://schema.org/identifier"],
            name: rawtype["http://schema.org/name"],
            occurrences: rawtype["https://kg.ebrains.eu/vocab/meta/occurrences"],
            properties: [],
            spaces: []
        };
        if (rawtype["https://kg.ebrains.eu/vocab/meta/properties"]) {
            type.properties = rawtype["https://kg.ebrains.eu/vocab/meta/properties"].map(property => ({
                id: property["http://schema.org/identifier"],
                name: property["http://schema.org/name"],
                occurrences: property["https://kg.ebrains.eu/vocab/meta/occurrences"],
                targetTypes: property["https://kg.ebrains.eu/vocab/meta/targetTypes"].map(targetType => ({
                    id: targetType["http://schema.org/name"],
                    occurrences: targetType["https://kg.ebrains.eu/vocab/meta/occurrences"]
                }))
            }));
        }
        if (rawtype["https://kg.ebrains.eu/vocab/meta/spaces"]) {
            type.spaces = rawtype["https://kg.ebrains.eu/vocab/meta/spaces"].map(space => ({
                name: space["http://schema.org/name"],
                occurrences: space["https://kg.ebrains.eu/vocab/meta/occurrences"]
            }));
        }
        return type;
    };

    const addRelations = type => {
        const relations = type.properties.reduce((acc, property) => {
            const provenance = property.id.startsWith(AppConfig.structure.provenance);
            property.targetTypes.forEach(targetType => {
                if (!acc[targetType.id]) {
                    const target = types[targetType.id];
                    targetType.name = target?target.name:targetType.id;
                    acc[targetType.id] = {
                        occurrences: 0,
                        targetId: targetType.id,
                        targetName: targetType.name,
                        provenance: provenance
                    }
                }
                acc[targetType.id].occurrences += targetType.occurrences;
            });
            return acc;
        }, {});
        type.relations = Object.values(relations);
    }

    const buildStructure = data => {
    
        types = data.data.reduce((acc, rawType) => {
            const type = simplifySemantics(rawType);
            acc[type.id] = type;
            return acc;
        }, {});

        const typesList = Object.values(types);

        typesList.forEach(type => addRelations(type));
        
        const nodes = typesList.reduce((acc, type) => {
            const hash = hashCode(type.id);
            acc[type.id] = {
                hash: hash,
                typeHash: hash,
                name: type.name,
                occurrences: type.occurrences,
                type: type,
                relations: []
            };
            return acc
        }, {});

        typesList.forEach(type => {
            const node = nodes[type.id];
            node.relations = type.relations.map(relation => nodes[relation.targetId]);
        });
        
        const links = typesList.reduce((acc, type) => {
            const sourceNode = nodes[type.id];
            type.relations
                .forEach(relation => {
                    if (relation.target !== type.id) {
                        const targetNode = nodes[relation.targetId];
                        const key = type.id + "-" + relation.targetId;
                        if (!acc[key]) {
                            acc[key] = {
                                occurrences: 0,
                                source: sourceNode,
                                target: targetNode,
                                provenance: relation.provenance
                            }
                        }
                        acc[key].occurrences += relation.occurrences;
                    }
                });
            return acc;
        }, {});

        const groupedNodes = typesList.reduce((acc, type) => {
            type.spaces.forEach(space => {
                acc.push({
                    hash: hashCode(space.name + "/" + type.id),
                    typeHash: hashCode(type.id),
                    name: type.name,
                    occurrences: space.occurrences,
                    group: space.name,
                    type: type,
                    relations: []
                });
            });
            return acc;
        }, []);

        structure = {
            nodes: Object.values(nodes),
            groupedNodes: groupedNodes,
            links: Object.values(links)
        };
    };

    const loadStructure = () => {
        if (!structureStore.is("STRUCTURE_LOADING")) {
            structureStore.toggleState("STRUCTURE_LOADING", true);
            structureStore.toggleState("STRUCTURE_ERROR", false);
            structureStore.notifyChange();
            fetch(`/api/types?stage=LIVE&withProperties=true`)
                .then(response => response.json())
                .then(data => {
                    buildStructure(data);
                    generateViewData(groupViewMode);
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
    };

    const getTypes = () => Object.values(types);

    const getStructure = () => groupViewMode ? {nodes: structure.groupedNodes, links: []} : {nodes: structure.nodes, links: structure.links};

    const getNodes = () => groupViewMode ? structure.groupedNodes : structure.nodes;

    const getLinks = () => groupViewMode ? groupViewModeLinks : structure.links;

    const getRelations2 = () => ({});

    const getRelations2Of = id => {
        const relations = getRelations2();
        const rel = getRelations2()[id];
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
            "STRUCTURE_LOADING", "STRUCTURE_ERROR", "STRUCTURE_LOADED",
            "SELECTED_NODE", "NODE_HIGHLIGHTED",
            "GROUP_VIEW_MODE", "SHOW_SEARCH_PANEL", "SHOW_TYPES_PANEL", "SHOW_SPACES_PANEL"
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

    structureStore.addAction("structure:node_select", node => {
        if (node !== selectedNode || node === undefined) {
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            highlightedNode = undefined;
            structureStore.toggleState("SELECTED_NODE", !!node);
            structureStore.toggleState("SHOW_SEARCH_PANEL", false);
            selectedType = node.type;
            selectedNode = node;
        } else {
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            highlightedNode = undefined;
            structureStore.toggleState("SELECTED_NODE", false);
            selectedNode = undefined;
            selectedType = undefined;
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:node_highlight", node => {
        structureStore.toggleState("NODE_HIGHLIGHTED", !!node);
        highlightedNode = node;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:node_unhighlight", () => {
        structureStore.toggleState("NODE_HIGHLIGHTED", false);
        highlightedNode = undefined;
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search", query => {
        if (query) {
            searchQuery = query;
            searchResults = _.filter(structure.nodes, node => node.type.id.match(new RegExp(query, "gi")));
        } else {
            searchQuery = query;
            searchResults = [];
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search_panel_toggle", () => {
        structureStore.toggleState("SHOW_SEARCH_PANEL");
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:types_panel_toggle", () => {
        structureStore.toggleState("SHOW_TYPES_PANEL");
        structureStore.notifyChange();
    });
    structureStore.addAction("structure:spaces_panel_toggle", () => {
        structureStore.toggleState("SHOW_SPACES_PANEL");
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_toggle_hide", type => {
        if (typeof type === "string") {
            type = _.find(structure.nodes, node => node.id === type);
        }
        if (type !== undefined && type === selectedNode) {
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            highlightedNode = undefined;
            structureStore.toggleState("SELECTED_NODE", false);
            selectedNode = undefined;
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

    structureStore.addAction("structure:all_types_toggle_hide", hide => {
        structureStore.toggleState("NODE_HIGHLIGHTED", false);
        highlightedNode = undefined;
        structureStore.toggleState("SELECTED_NODE", false);
        selectedNode = undefined;
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

    structureStore.addInterface("getSelectedNode", () => selectedNode);

    structureStore.addInterface("getHighlightedNode", () => highlightedNode);

    structureStore.addInterface("getTypes", getTypes);

    structureStore.addInterface("getStructure", getStructure);

    structureStore.addInterface("getNodes", getNodes);

    structureStore.addInterface("getLinks", getLinks);

    structureStore.addInterface("getHiddenTypes", () => hiddenTypes);

    structureStore.addInterface("getHiddenSpaces", () => hiddenSpaces);

    structureStore.addInterface("getRelations2Of", getRelations2Of);

    structureStore.addInterface("hasRelations", (id, filterHidden) => {
        if (filterHidden) {
            const relations = _(getRelations2Of(id)).filter(rel => hiddenTypes.indexOf(rel.relatedType) === -1).value();
            return !!relations.length;
        } else {
            return getRelations2Of(id).length;
        }
    });

    structureStore.addInterface("getSearchQuery", () => searchQuery);

    structureStore.addInterface("getSearchResults", () => searchResults);

    RiotPolice.registerStore(structureStore);
})();
