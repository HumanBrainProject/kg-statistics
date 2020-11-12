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
    let spaces = {};
    let spacesList = [];
    let overviewGraphData = {
        hash: Date.now(),
        spaces: [],
        nodes: [],
        links: []
    };
    let typeGraphData = {
        hash: Date.now(),
        spaces: [],
        nodes: [],
        links: []
    };
    let selectedType = undefined;
    let lastUpdate = undefined;
    let releasedStage = false;
    let highlightedType = undefined;
    let searchQuery = "";
    let searchResults = [];
    let showProvenanceLinks = true;
    let showIntraSpaceLinks = true;
    let showExtraSpaceLinks = true;
    
    const excludedTypes = ["http://www.w3.org/2001/XMLSchema#string", "https://schema.hbp.eu/minds/Softwareagent"];
    const excludedProperties = [];
    const excludedPropertiesForLinks = ["extends", "wasDerivedFrom", "wasRevisionOf", "subclassof"];

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


        const simplifyPropertiesSemeantics = properties => {

            const getName = (id, name) => { 
                if (typeof name === "string") {
                    return name;
                }
                if (typeof id === "string") {
                    const m = id.match(/^.*\/([a-z0-9_\-]+#)?([a-z0-9_\-]+)$/i);
                    if (m && m.length >= 2) {
                        return m[2];
                    }
                    return id;
                }
                return undefined;
            };

            if (!Array.isArray(properties)) {
                return [];
            }
            return properties.map(property => ({
                id: property["http://schema.org/identifier"],
                name: getName(property["http://schema.org/identifier"], property["http://schema.org/name"]),
                occurrences: property["https://core.kg.ebrains.eu/vocab/meta/occurrences"],
                targetTypes: property["https://core.kg.ebrains.eu/vocab/meta/targetTypes"].map(targetType => {
                    const type = {
                        id: targetType["https://core.kg.ebrains.eu/vocab/meta/type"],
                        occurrences: targetType["https://core.kg.ebrains.eu/vocab/meta/occurrences"],
                        spaces: []
                    };
                    if (Array.isArray(targetType["https://core.kg.ebrains.eu/vocab/meta/spaces"])) {
                        type.spaces = targetType["https://core.kg.ebrains.eu/vocab/meta/spaces"].map(space => ({
                            //type: space["https://core.kg.ebrains.eu/vocab/meta/type"],
                            name: space["https://core.kg.ebrains.eu/vocab/meta/space"],
                            occurrences: space["https://core.kg.ebrains.eu/vocab/meta/occurrences"]
                        }));
                    }
                    return type;
                })
            }));
        };

        const type = {
            id: rawtype["http://schema.org/identifier"],
            name: rawtype["http://schema.org/name"],
            occurrences: rawtype["https://core.kg.ebrains.eu/vocab/meta/occurrences"],
            properties: simplifyPropertiesSemeantics(rawtype["https://core.kg.ebrains.eu/vocab/meta/properties"]),
            spaces: []
        };
        if (Array.isArray(rawtype["https://core.kg.ebrains.eu/vocab/meta/spaces"])) {
            type.spaces = rawtype["https://core.kg.ebrains.eu/vocab/meta/spaces"].map(space => ({
                name: space["https://core.kg.ebrains.eu/vocab/meta/space"],
                occurrences: space["https://core.kg.ebrains.eu/vocab/meta/occurrences"],
                properties: simplifyPropertiesSemeantics(space["https://core.kg.ebrains.eu/vocab/meta/properties"])
            }));
        }
        return type;
    };

    const buildTypes = data => {

        const enrichTypeLinksTo = type => {
            if (excludedProperties.length) {
                type.properties = type.properties.filter(property => !excludedProperties.includes(property.name));
            }
            type.properties = type.properties.sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0));
            const linksTo = type.properties.reduce((acc, property) => {
                const isProvenance = property.id.startsWith(AppConfig.structure.provenance);
                if (isProvenance) {
                    property.isProvenance = isProvenance;
                }
                if (excludedPropertiesForLinks.includes(property.name)) {
                    property.excludeLinks = true;
                }
                property.targetTypes.forEach(targetType => {
                    const target = types[targetType.id];
                    if (target) {
                        targetType.name = target.name;
                    } else {
                        targetType.name = targetType.id;
                        targetType.isUnknown = true;
                    }
                    if (excludedTypes.includes(targetType.id)) {
                        targetType.isExcluded = true;
                    }
                    if (!property.excludeLinks) {
                        if (!acc[targetType.id]) {
                            acc[targetType.id] = {
                                occurrences: 0,
                                targetId: targetType.id,
                                targetName: targetType.name,
                                isProvenance: isProvenance
                            }
                            if (targetType.isExcluded) {
                                acc[targetType.id].isExcluded = true;
                            }
                            if (targetType.isUnknown) {
                                acc[targetType.id].isUnknown = true;
                            }
                        }
                        acc[targetType.id].occurrences += targetType.occurrences;
                        acc[targetType.id].isProvenance = isProvenance && acc[targetType.id].isProvenance;
                    }
                });
                property.targetTypes = property.targetTypes.sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0));
                return acc;
            }, {});
            return Object.values(linksTo).sort((a, b) => (a.targetName > b.targetName)?1:((a.targetName < b.targetName)?-1:0));
        };
    
        const enrichTypeSpacesLinksTo = type => {
            const links = [];
            type.spaces.forEach(spaceFrom => {
                if (excludedProperties.length) {
                    spaceFrom.properties = spaceFrom.properties.filter(property => !excludedProperties.includes(property.name));
                }
                spaceFrom.properties.forEach(property => {
                    const isProvenance = property.id.startsWith(AppConfig.structure.provenance);
                    if (isProvenance) {
                        property.isProvenance = isProvenance;
                    }
                    if (excludedPropertiesForLinks.includes(property.name)) {
                        property.excludeLinks = true;
                    }
                    property.targetTypes.forEach(targetType => {
                        const target = types[targetType.id];
                        if (target) {
                            targetType.name = target.name;
                        } else {
                            targetType.name = targetType.id;
                            targetType.isUnknown = true;
                        }
                        if (excludedTypes.includes(targetType.id)) {
                            targetType.isExcluded = true;
                        }
                        if (!property.excludeLinks) {
                            targetType.spaces.forEach(spaceTo => {
                                const link = {
                                    occurrences: spaceTo.occurrences,
                                    sourceSpace: spaceFrom.name,
                                    targetSpace: spaceTo.name,
                                    targetId: targetType.id,
                                    targetName: targetType.name,
                                    isProvenance: isProvenance
                                };
                                if (targetType.isExcluded) {
                                    link.isExcluded = true;
                                }
                                if (targetType.isUnknown) {
                                    link.isUnknown = true;
                                }
                                links.push(link);
                            });
                        }
                    });
                });
            });
            return links;
        };
    
        const enrichTypesLinks = () => {
    
            const linksFrom = {};
            typesList.forEach(type => {
                type.linksTo = enrichTypeLinksTo(type);

                type.linksFrom = [];
                type.linksTo.forEach(linkTo => {
                    if (!linksFrom[linkTo.targetId]) {
                        linksFrom[linkTo.targetId] = {};
                    }
                    if (!linksFrom[linkTo.targetId][type.id]) {
                        linksFrom[linkTo.targetId][type.id] = {
                            occurrences: 0,
                            sourceId: type.id,
                            sourceName: type.name,
                            isProvenance: linkTo.isProvenance
                        };
                        if (type.isExcluded) {
                            linksFrom[linkTo.targetId][type.id].isExcluded = true;
                        }
                    }
                    linksFrom[linkTo.targetId][type.id].occurrences += linkTo.occurrences;
                });

                type.spacesLinksTo = enrichTypeSpacesLinksTo(type);
            });
            Object.entries(linksFrom).forEach(([target, sources]) => {
                const type = types[target];
                if (type) {
                    type.linksFrom = Object.values(sources).sort((a, b) => (a.sourceName > b.sourceName)?1:((a.sourceName < b.sourceName)?-1:0));
                }
            });
        };

        spaces = {};
        types = data.data.reduce((acc, rawType) => {
            const type = simplifySemantics(rawType);
            type.hash = hashCode(type.id);
            type.isProvenance = type.id.startsWith(AppConfig.structure.provenance);
            if (excludedTypes.includes(type.id)) {
                type.isExcluded = true;
            }
            acc[type.id] = type;

            type.spaces.forEach(space => spaces[space.name] = {name: space.name, enabled: true});
            return acc;
        }, {});

        typesList = Object.values(types);
        spacesList = Object.values(spaces).sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0));

        enrichTypesLinks();
    };

    const isSpaceEnabled = name => !!spaces[name] && spaces[name].enabled;

    const typeBelongsToEnabledSpace = type => !!type.spaces.filter(space => isSpaceEnabled(space.name)).length;

    const getLinkedToTypes = type => type.linksTo.reduce((acc, linkTo) => {
        const target = types[linkTo.targetId];
        if (target && !target.isExcluded) {
            acc.push(target);
        }
        return acc;
    }, []);

    const getLinkedFromTypes = type => type.linksFrom.reduce((acc, linkFrom) => {
        const source = types[linkFrom.sourceId];
        if (source && !source.isExcluded) {
            acc.push(source);
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


    const buildGraphData = (typesList, forOverview) => {

        const availableSpaces = {};
        const enabledNodes = {};

        const addRelation = (sourceSpace, sourceId, targetSpace, targetId, isProvenance) => {
            if (selectedType && (selectedType.id === sourceId || selectedType.id === targetId) &&
                ((showIntraSpaceLinks && sourceSpace === targetSpace) || (showExtraSpaceLinks && sourceSpace !== targetSpace)) &&
                (showProvenanceLinks || !isProvenance)) {
                availableSpaces[sourceSpace] = spaces[sourceSpace];
                availableSpaces[targetSpace] = spaces[targetSpace];
                enabledNodes[sourceSpace + "/" + sourceId] =  true;
                enabledNodes[targetSpace + "/" + targetId] =  true;
            }
        };

        const isNodeEnabled = (space, id) => !selectedType || selectedType.id === id || !!enabledNodes[space + "/" + id];

        if (!forOverview && selectedType) {
            typesList.forEach(type => type.spacesLinksTo.forEach(relation => addRelation(relation.sourceSpace, type.id, relation.targetSpace, relation.targetId, relation.isProvenance)));
        }

        const nodes = typesList.reduce((acc, type) => {
            if (typeBelongsToEnabledSpace(type)) {
                type.spaces.forEach(space => {
                    if (isSpaceEnabled(space.name) && (forOverview || isNodeEnabled(space.name, type.id))) {
                        acc[space.name + "/" + type.id] = {
                            hash: hashCode(space.name + "/" + type.id),
                            id: type.id,
                            name: type.name,
                            occurrences: space.occurrences,
                            group: space.name,
                            type: type,
                            linksTo: [],
                            linksFrom: []
                        };
                    }
                });
            }
            return acc;
        }, {});

        const links = Object.values(nodes).reduce((acc, sourceNode) => {
            const type = sourceNode.type;
            type.spacesLinksTo
                .forEach(link => {
                    if (link.sourceSpace === sourceNode.group &&
                        link.targetId !== type.id && !excludedTypes.includes(link.targetId) && (showProvenanceLinks || !link.isProvenance)) {
                        const targetNode = nodes[link.targetSpace + "/" + link.targetId];
                        if (targetNode && 
                            isSpaceEnabled(targetNode.group) && 
                            !targetNode.isExcluded &&
                            ((showIntraSpaceLinks && sourceNode.group === targetNode.group) || (showExtraSpaceLinks && sourceNode.group !== targetNode.group))) {
                            sourceNode.linksTo.push(targetNode);
                            targetNode.linksFrom.push(sourceNode);
                            acc.push({
                                occurrences: link.occurrences,
                                source: sourceNode,
                                target: targetNode,
                                isProvenance: link.isProvenance
                            });
                        }
                    }
                });
            return acc;
        }, []);

        return {
            hash: Date.now(),
            availableSpaces: forOverview?spacesList:Object.values(availableSpaces).sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0)),
            nodes: Object.values(nodes),
            links: links,
        };
    };


    const buildTypeGraphData = () => {

        const directLinkedToTypes = getLinkedToTypes(selectedType);
        const directLinkedFromTypes = getLinkedFromTypes(selectedType);

        const filteredTypesList = removeDupplicateTypes([selectedType, ...directLinkedToTypes, ...directLinkedFromTypes]);

        typeGraphData = buildGraphData(filteredTypesList, false);
    };

    const buildOverviewGraphData = () => {

        const filteredTypesList = typesList.filter(type  =>  !type.isExcluded);

        overviewGraphData = buildGraphData(filteredTypesList, true);
    };

    const search = query => {
        if (query) {
            searchQuery = query;
            searchResults = typesList.filter(type => !excludedTypes.includes(type.id) && type.name.match(new RegExp(query, "gi"))).sort((a, b) => b.occurrences - a.occurrences);
        } else {
            searchQuery = "";
            searchResults = typesList.filter(type => !excludedTypes.includes(type.id)).sort((a, b) => (a.name > b.name)?1:((a.name < b.name)?-1:0));
        }
    };

    const showAllSpaces = () => {
        if (spacesList.reduce((acc, space) => acc && space.enabled, true)) {
            return true;
        }
        if (spacesList.reduce((acc, space) => acc && !space.enabled, true)) {
            return false;
        }
        return undefined;
    };

    const init = () => {
        structureStore.toggleState("PROVENANCE_LINKS_SHOW", showProvenanceLinks);
        structureStore.toggleState("INTRA_SPACE_LINKS_SHOW", showIntraSpaceLinks);
        structureStore.toggleState("EXTRA_SPACE_LINKS_SHOW", showExtraSpaceLinks);
    };

    const reset = () => {
        selectedType = undefined;
        lastUpdate = undefined;
        releasedStage = false;
        highlightedType = undefined;
        showProvenanceLinks = true;
        showIntraSpaceLinks = true;
        showExtraSpaceLinks = true;
        spacesList.forEach(space => space.enabled = true);
        structureStore.toggleState("TYPE_SELECTED", !!selectedType);
        structureStore.toggleState("TYPE_HIGHLIGHTED", !!highlightedType);
        structureStore.toggleState("TYPE_DETAILS_SHOW", !!selectedType);
        structureStore.toggleState("PROVENANCE_LINKS_SHOW", showProvenanceLinks);
        structureStore.toggleState("INTRA_SPACE_LINKS_SHOW", showIntraSpaceLinks);
        structureStore.toggleState("EXTRA_SPACE_LINKS_SHOW", showExtraSpaceLinks);
    };

    const structureStore = new RiotStore("structure",
        [
            "STRUCTURE_LOADING", "STRUCTURE_ERROR", "STRUCTURE_LOADED",
            "TYPE_SELECTED", "TYPE_HIGHLIGHTED",
            "TYPE_DETAILS_SHOW", "STAGE_RELEASED", "INTRA_SPACE_LINKS_SHOW", "EXTRA_SPACE_LINKS_SHOW", "PROVENANCE_LINKS_SHOW"
        ],
        init, reset);

    /**
     * Store trigerrable actions
     */

    structureStore.addAction("structure:stage_toggle", () => {
        releasedStage  = !releasedStage;
        structureStore.toggleState("STAGE_RELEASED", releasedStage);
        structureStore.notifyChange();
        RiotPolice.trigger("structure:load");
    });

    structureStore.addAction("structure:load", () => {
        if (!structureStore.is("STRUCTURE_LOADING")) {
            structureStore.toggleState("STRUCTURE_LOADING", true);
            structureStore.toggleState("STRUCTURE_ERROR", false);
            structureStore.notifyChange();
            fetch(`/api/v3-beta/types?stage=${releasedStage ? "RELEASED" : "IN_PROGRESS"}&withProperties=true`)
                .then(response => response.json())
                .then(data => {
                    lastUpdate = new Date();
                    selectedType = undefined;
                    highlightedType = undefined;
                    buildTypes(data);
                    search();
                    structureStore.toggleState("TYPE_SELECTED", !!selectedType);
                    structureStore.toggleState("TYPE_HIGHLIGHTED", !!highlightedType);
                    structureStore.toggleState("TYPE_DETAILS_SHOW", !!selectedType);
                    buildOverviewGraphData();
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

    structureStore.addAction("structure:type_select", id => {
        const type = types[id];
        if (type) {
            if (type !== selectedType) {
                search();
                highlightedType = undefined;
                selectedType = type;
                buildTypeGraphData();
                structureStore.toggleState("TYPE_HIGHLIGHTED", false);
                structureStore.toggleState("TYPE_SELECTED", !!type);
                structureStore.toggleState("TYPE_DETAILS_SHOW", true);
            }
        } else if (selectedType) {
            search();
            highlightedType = undefined;
            selectedType = undefined;
            structureStore.toggleState("TYPE_HIGHLIGHTED", false);
            structureStore.toggleState("TYPE_SELECTED", false);
            structureStore.toggleState("TYPE_DETAILS_SHOW", false);
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_highlight", id => {
        const type = types[id];
        if (type) {
            highlightedType = type;
        } else {
            highlightedType = undefined;
        }
        structureStore.toggleState("TYPE_HIGHLIGHTED", !!highlightedType);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:search", query => {
        search(query);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:type_details_show", show => {
        structureStore.toggleState("TYPE_DETAILS_SHOW", !!show);
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:space_toggle", name => {
        if (spaces[name]) {
            spaces[name].enabled = !spaces[name].enabled;
            buildOverviewGraphData();
            if (selectedType) {
                buildTypeGraphData();
            }
            structureStore.notifyChange();
        }
    });

    structureStore.addAction("structure:spaces_all_toggle", enabled => {
        if ((enabled === true || enabled === false) && enabled !== showAllSpaces()) {
            const list = selectedType?typeGraphData.availableSpaces:overviewGraphData.availableSpaces;
            list.forEach(space => space.enabled = enabled);
            buildOverviewGraphData();
            if (selectedType) {
                buildTypeGraphData();
            }
            structureStore.notifyChange();
        }
    });

    structureStore.addAction("structure:provenance_links_toggle", () => {
        showProvenanceLinks = !showProvenanceLinks;
        structureStore.toggleState("PROVENANCE_LINKS_SHOW", showProvenanceLinks);
        buildOverviewGraphData();
        if (selectedType) {
            buildTypeGraphData();
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:space_intra_links_toggle", () => {
        showIntraSpaceLinks = !showIntraSpaceLinks;
        structureStore.toggleState("INTRA_SPACE_LINKS_SHOW", showIntraSpaceLinks);
        buildOverviewGraphData();
        if (selectedType) {
            buildTypeGraphData();
        }
        structureStore.notifyChange();
    });

    structureStore.addAction("structure:space_extra_links_toggle", () => {
        showExtraSpaceLinks = !showExtraSpaceLinks;
        structureStore.toggleState("EXTRA_SPACE_LINKS_SHOW", showExtraSpaceLinks);
        buildOverviewGraphData();
        if (selectedType) {
            buildTypeGraphData();
        }
        structureStore.notifyChange();
    });

    /**
     * Store public interfaces
     */

    structureStore.addInterface("getLastUpdate", () => lastUpdate);
    
    structureStore.addInterface("getSelectedType", () => selectedType);

    structureStore.addInterface("getTypes", () => types);

    structureStore.addInterface("getTypesList", () => typesList);

    structureStore.addInterface("getAvailableSpacesList", () => selectedType?typeGraphData.availableSpaces:overviewGraphData.availableSpaces);

    structureStore.addInterface("showAllSpaces", showAllSpaces);

    structureStore.addInterface("getSearchQuery", () => searchQuery);

    structureStore.addInterface("getSearchResults", () => searchResults);

    structureStore.addInterface("getHighlightedType", () => highlightedType);

    structureStore.addInterface("getGraphData", () => selectedType?typeGraphData:overviewGraphData);

    RiotPolice.registerStore(structureStore);
})();
