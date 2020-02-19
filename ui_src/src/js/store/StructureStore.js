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
    let typesList = [];
    let typesGraphData = {
        nodes: [],
        links: []
    };
    let linksGraphData = {
        nodesMap: {},
        nodes: [],
        links: []
    };
    let selectedType = null;
    let lastUpdate = null;
    let selectedNode;
    let highlightedNode;
    let searchQuery = "";
    let searchResults = [];
    
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

    const buildTypes = data => {

        const enrichTypeLinksTo = type => {
            type.properties = type.properties.filter(property => property.name !== "extends" && property.name !== "wasDerivedFrom").sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0));
            const linksTo = type.properties.reduce((acc, property) => {
                const provenance = property.id.startsWith(AppConfig.structure.provenance);
                property.targetTypes.forEach(targetType => {
                    const target = types[targetType.id];
                    targetType.name = target?target.name:targetType.id;
                    if (!acc[targetType.id]) {
                        acc[targetType.id] = {
                            occurrences: 0,
                            targetId: targetType.id,
                            targetName: targetType.name,
                            provenance: provenance
                        }
                    }
                    acc[targetType.id].occurrences += targetType.occurrences;
                });
                property.targetTypes = property.targetTypes.sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0));
                return acc;
            }, {});
            type.linksTo = Object.values(linksTo).sort((a, b) => (a.targetName > b.targetName)?1:((a.targetName < b.targetName)?-1:0));
        }
    
        const enrichTypesLinks = () => {
    
            const linksFrom = {};
            typesList.forEach(type => {
                enrichTypeLinksTo(type);
                type.linksTo.forEach(linkTo => {
                    if (!linksFrom[linkTo.targetId]) {
                        linksFrom[linkTo.targetId] = {};
                    }
                    if (!linksFrom[linkTo.targetId][type.id]) {
                        linksFrom[linkTo.targetId][type.id] = {
                            occurrences: 0,
                            sourceId: type.id,
                            sourceName: type.name
                        }
    
                    }
                    linksFrom[linkTo.targetId][type.id].occurrences += linkTo.occurrences;
                });
            });
            Object.entries(linksFrom).forEach(([target, sources]) => {
                const type = types[target];
                if (type) {
                    type.linksFrom = Object.values(sources).sort((a, b) => (a.sourceName > b.sourceName)?1:((a.sourceName < b.sourceName)?-1:0));
                }
            });
        };
    
        types = data.data.reduce((acc, rawType) => {
            const type = simplifySemantics(rawType);
            if (type.name !== "string") {
             acc[type.id] = type;
            }
            return acc;
        }, {});

        typesList = Object.values(types);

        enrichTypesLinks();
    };

    const getLinkedTypes = type => type.linksTo.reduce((acc, linkTo) => {
        if (types[linkTo.targetId]) {
            acc.push(types[linkTo.targetId]);
        }
        return acc;
    }, []);

    const removeDupplicateTypes = list => {
        const uniqueTypes = {};
        list.forEach(type => {
            if (!uniqueTypes[type.id]) {
                uniqueTypes[type.id] = type;
            }
        });
        return Object.values(uniqueTypes);
    };

    const buildLinksGraphData = () => {
        const directLinkedTypes = getLinkedTypes(selectedType);
        const nextLinkedTypes = directLinkedTypes.reduce((acc, type) => {
            acc.push(...getLinkedTypes(type));
            return acc;
        }, []);
        
        //TODO: get from links

        const typesList = removeDupplicateTypes([selectedType, ...directLinkedTypes, ...nextLinkedTypes]);

        const nodes = typesList.reduce((acc, type) => {
            const hash = hashCode(type.id);
            acc[type.id] = {
                hash: hash,
                typeHash: hash,
                name: type.name,
                occurrences: type.occurrences,
                type: type,
                linksTo: []
            };
            return acc
        }, {});

        typesList.forEach(type => {
            const node = nodes[type.id];
            node.linksTo = type.linksTo.reduce((acc, relation) => {
                if (nodes[relation.targetId]) {
                    acc.push(nodes[relation.targetId]);
                }
                return acc;
            }, []);
        });

        const links = typesList.reduce((acc, type) => {
            const sourceNode = nodes[type.id];
            type.linksTo
                .forEach(relation => {
                    if (relation.target !== type.id) {
                        const targetNode = nodes[relation.targetId];
                        if (targetNode) {// && (type.id === selectedType.id || relation.targetId === selectedType.id)) {
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
                    }
                });
            return acc;
        }, {});

        linksGraphData = {
            nodesMap: nodes,
            nodes: Object.values(nodes),
            links: Object.values(links)
        };
    }

    const buildTypesGraphData = () => {

        const nodes = typesList.reduce((acc, type) => {
            type.spaces.forEach(space => {
                acc.push({
                    hash: hashCode(space.name + "/" + type.id),
                    typeHash: hashCode(type.id),
                    name: type.name,
                    occurrences: space.occurrences,
                    group: space.name,
                    type: type,
                    linksTo: []
                });
            });
            return acc;
        }, []);

        typesGraphData = {
            nodes: nodes,
            links: []
        };
    };

    const search = query => {
        if (query) {
            searchQuery = query;
            searchResults = typesList.filter(type => type.name.match(new RegExp(query, "gi"))).sort((a, b) => b.occurrences - a.occurrences);
        } else {
            searchQuery = "";
            searchResults = typesList.sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0));
        }
    };

    const init = () => {

    };

    const reset = () => {

    };

    const structureStore = new RiotStore("structure",
        [
            "STRUCTURE_LOADING", "STRUCTURE_ERROR", "STRUCTURE_LOADED",
            "NODE_SELECTED", "NODE_HIGHLIGHTED",
            "SHOW_SEARCH_PANEL"
        ],
        init, reset);

    /**
     * Store trigerrable actions
     */

    structureStore.addAction("structure:load", () => {
        if (!structureStore.is("STRUCTURE_LOADING")) {
            structureStore.toggleState("STRUCTURE_LOADING", true);
            structureStore.toggleState("STRUCTURE_ERROR", false);
            structureStore.notifyChange();
            fetch(`/api/types?stage=LIVE&withProperties=true`)
                .then(response => response.json())
                .then(data => {
                    lastUpdate = new Date();
                    selectedType = null;
                    buildTypes(data);
                    search();
                    buildTypesGraphData();
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
    });

    structureStore.addAction("structure:node_select", node => {
        if (node) {
            if (node !== selectedNode) {
                search();
                highlightedNode = undefined;
                selectedType = node.type;
                selectedNode = node;
                buildLinksGraphData();
                structureStore.toggleState("NODE_HIGHLIGHTED", false);
                structureStore.toggleState("NODE_SELECTED", !!node);
                structureStore.toggleState("SHOW_SEARCH_PANEL", false);
            }
        } else if (selectedNode) {
            search();
            highlightedNode = undefined;
            selectedNode = undefined;
            selectedType = undefined;
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            structureStore.toggleState("NODE_SELECTED", false);
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:node_highlight", node => {
        highlightedNode = node;
        structureStore.toggleState("NODE_HIGHLIGHTED", !!node);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_select", id => {
        const type = types[id];
        if (type) {
            if (type !== selectedType) {
                search();
                highlightedNode = undefined;
                selectedType = type;
                buildLinksGraphData();
                selectedNode = linksGraphData.nodesMap[id];
                structureStore.toggleState("NODE_HIGHLIGHTED", false);
                structureStore.toggleState("NODE_SELECTED", !!type);
                structureStore.toggleState("SHOW_SEARCH_PANEL", false);
            }
        } else if (selectedType) {
            search();
            highlightedNode = undefined;
            selectedNode = undefined;
            selectedType = undefined;
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            structureStore.toggleState("NODE_SELECTED", false);
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_highlight", id => {
        if (selectedType) {
            highlightedNode = linksGraphData.nodesMap[id];
        } else {
            highlightedNode = undefined; //TODO: find a node
        }
        structureStore.toggleState("NODE_HIGHLIGHTED", !!highlightedNode);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search", query => {
        search(query);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search_panel_toggle", () => {
        structureStore.toggleState("SHOW_SEARCH_PANEL");
        structureStore.notifyChange();
    });

    /**
     * Store public interfaces
     */

    structureStore.addInterface("getLastUpdate", () => lastUpdate);
    
    structureStore.addInterface("getSelectedType", () => selectedType);

    structureStore.addInterface("getTypes", types);

    structureStore.addInterface("getTypesList", typesList);

    structureStore.addInterface("getSearchQuery", () => searchQuery);

    structureStore.addInterface("getSearchResults", () => searchResults);

    structureStore.addInterface("getSelectedNode", () => selectedNode);

    structureStore.addInterface("getHighlightedNode", () => highlightedNode);

    structureStore.addInterface("getGraphData", () => selectedType?linksGraphData:typesGraphData);

    RiotPolice.registerStore(structureStore);
})();
