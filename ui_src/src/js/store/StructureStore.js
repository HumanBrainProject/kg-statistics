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
    let selectedType = null;
    let defaultViewModeNodes = [];
    let defaultViewModeLinks = [];
    let defaultViewModeRelations = [];
    let groupViewModeNodes = [];
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

        const nodes = groupViewModeNodes;
        const relations = groupViewModeRelations;

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

    const generateDefaultViewData = () => {

        const nodes = defaultViewModeNodes;
        const relations = defaultViewModeRelations;

        let toBeHidden;
        //First use
        if (!localStorage.getItem(hiddenNodesLocalKey)) {
            toBeHidden = [];
            //Hidding nodes with too many connections
            nodes.forEach(node => {
                node.hidden = false;
                if (relations[node.id] !== undefined &&
                    whitelist.indexOf(node.id) < 0 &&
                    relations[node.id].length / defaultViewModeNodes.length > AppConfig.structure.autoHideThreshold
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

    const simplifySemantics = type => {
        const result = {
            id: type["http://schema.org/identifier"],
            name: type["http://schema.org/name"],
            occurrences: type["https://kg.ebrains.eu/vocab/meta/occurrences"],
            properties: [],
            links: [],
            spaces: []
        };
        if (type["https://kg.ebrains.eu/vocab/meta/properties"]) {
            result.properties = type["https://kg.ebrains.eu/vocab/meta/properties"].map(property => ({
                id: property["http://schema.org/identifier"],
                name: property["http://schema.org/name"],
                occurrences: property["https://kg.ebrains.eu/vocab/meta/occurrences"],
                targetTypes: property["https://kg.ebrains.eu/vocab/meta/targetTypes"].map(targetType => ({
                    id: targetType["http://schema.org/name"],
                    occurrences: targetType["https://kg.ebrains.eu/vocab/meta/occurrences"]
                }))
            }));
        }
        if (type["https://kg.ebrains.eu/vocab/meta/links"]) {
            result.links = type["https://kg.ebrains.eu/vocab/meta/links"].map(link => ({
                id: link["http://schema.org/identifier"],
                name: link["http://schema.org/name"],
                targetType: link["https://kg.ebrains.eu/vocab/meta/targetType"],
                occurrences: link["https://kg.ebrains.eu/vocab/meta/occurrences"]
            }));
        }
        if (type["https://kg.ebrains.eu/vocab/meta/spaces"]) {
            result.spaces = type["https://kg.ebrains.eu/vocab/meta/spaces"].map(space => {
                const res = {
                    name: space["http://schema.org/name"],
                    occurrences: space["https://kg.ebrains.eu/vocab/meta/occurrences"],
                    links: []
                };
                if (space["https://kg.ebrains.eu/vocab/meta/links"]) {
                    res.links = space["https://kg.ebrains.eu/vocab/meta/links"].map(link => ({
                        id: link["http://schema.org/identifier"],
                        name: link["http://schema.org/name"],
                        targetType: link["https://kg.ebrains.eu/vocab/meta/targetType"],
                        targetSpace: link["https://kg.ebrains.eu/vocab/meta/targetSpace"]
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
            if (relations[link.source.id] === undefined) {
                relations[link.source.id] = [];
            }
            relations[link.source.id].push({
                ...link,
                related: link.target
            });
            if (relations[link.target.id] === undefined) {
                relations[link.target.id] = [];
            }
            if (link.source !== link.target) {
                relations[link.target.id].push({
                    ...link,
                    related: link.source
                });
            }
        });
        return relations;
    };


  const buildStructure = data => {
    types = {};
    defaultViewModeNodes = [];
    defaultViewModeLinks = [];
    defaultViewModeRelations = {};
    groupViewModeNodes = [];
    groupViewModeLinks = [];
    groupViewModeRelations = {};
    data.data.forEach(rawType => {
      const type = {
        ...simplifySemantics(rawType),
        isLoading: false,
        isLoaded: false,
        error: null
      };
      types[type.id] = type;
      const typeHash = hashCode(type.id);
      const hash = typeHash;
      const node = {
        hash: hash,
        typeHash: typeHash,
        data: {
          id: type.id,
          name: type.name,
          occurrences: type.occurrences
        }
      };
      defaultViewModeNodes.push(node);
      defaultViewModeLinks = type.links.map(link => {
        const targetHash = hashCode(link.targetType);
        return {
          id: link.id,
          name: link.name,
          provenance: link.name !== undefined && link.name.startsWith(PROVENENCE_SEMANTIC),
          value: link.occurrences,
          source: {
            id: link.id,
            hash: hash,
            typeHash: typeHash
          },
          target: {
            id: link.type,
            hash: targetHash,
            typeHash: targetHash
          }
        };
      });
      type.spaces.forEach(space => {
        const groupViewModeNode = {
          hash: hashCode(space.name + "/" + type.id),
          typeHash: typeHash,
          data: {
            id: type.id,
            name: type.name,
            occurrences: space.occurrences,
            group: space.name
          }
        };
        groupViewModeNodes.push(groupViewModeNode);
        space.links.forEach(link => {
          const targetTypeHash = hashCode(link.targetType);
          const groupViewModeLink = {
            id: link.id,
            name: link.name,
            provenance: link.name !== undefined && link.name.startsWith(PROVENENCE_SEMANTIC),
            source: {
              id: type.id,
              group: space.name,
              hash: hash,
              typeHash: typeHash
            },
            target: {
              id: link.targetType,
              group: link.targetGroup,
              hash: hashCode(space.name + "/" + link.targetType),
              typeHash: targetTypeHash
            }
          };
          groupViewModeLinks.push(groupViewModeLink);
        });
      });
    });
    groupViewModeRelations = buildRelations(groupViewModeLinks);
    defaultViewModeRelations = buildRelations(defaultViewModeLinks);
  };

    const loadStructure = () => {
        if (!structureStore.is("STRUCTURE_LOADING")) {
            structureStore.toggleState("STRUCTURE_LOADING", true);
            structureStore.toggleState("STRUCTURE_ERROR", false);
            structureStore.notifyChange();
            fetch(`/api/types?stage=LIVE&withProperties=false`)
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
                        const definition = simplifySemantics(data.data);
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

    const getTypes = () => Object.values(types);

    const getNodes = () => groupViewMode ? groupViewModeNodes : defaultViewModeNodes;

    const getLinks = () => groupViewMode ? groupViewModeLinks : defaultViewModeLinks;

    const getRelations = () => groupViewMode ? groupViewModeRelations : defaultViewModeRelations;

    const getRelationsOf = id => {
        const relations = getRelations();
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
            "STRUCTURE_LOADING", "STRUCTURE_ERROR", "STRUCTURE_LOADED",
            "TYPE_LOADING", "TYPE_LOADED", "TYPE_ERROR",
            "SELECTED_NODE", "NODE_HIGHLIGHTED",
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

    structureStore.addAction("structure:node_select", node => {
        if (node !== selectedNode || node === undefined) {
            structureStore.toggleState("NODE_HIGHLIGHTED", false);
            highlightedNode = undefined;
            structureStore.toggleState("SELECTED_NODE", !!node);
            structureStore.toggleState("SEARCH_ACTIVE", false);
            selectedType = types[node.data.id];
            loadType(selectedType);
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
            searchResults = _.filter(defaultViewModeNodes, node => node.data.id.match(new RegExp(query, "gi")));
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
