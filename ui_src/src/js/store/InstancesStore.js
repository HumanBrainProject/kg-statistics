/*
 * Copyright 2018 - 2021 Swiss Federal Institute of Technology Lausanne (EPFL)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This open source software code was developed in part or in whole in the
 * Human Brain Project, funded from the European Union's Horizon 2020
 * Framework Programme for Research and Innovation under
 * Specific Grant Agreements No. 720270, No. 785907, and No. 945539
 * (Human Brain Project SGA1, SGA2 and SGA3).
 *
 */

(function () {
    let querySchema = null;
    let queryResults = [];
    let total = 0;
    let comparison = null;

    const init = function () {
    
    }

    const reset = function () {

    }

    const instancesStore = new RiotStore("instances", 
                                        ["ACTIVE", "QUERY_LOADING", "QUERY_LOADED", "QUERY_ERROR", "COMPARISON"], 
                                        init, reset);

    const doQuery = (resource, requestUrl) => {
        $.get(requestUrl)
            .done((response, status, xhr) => {
                //console.log(xhr.getAllResponseHeaders());
                //console.log(xhr.getResponseHeader('location'));
                if (typeof response === "object") {
                    if (instancesStore.is("ACTIVE") && resource === querySchema.id) {
                        total = response.total;
                        response.results.forEach(i => {
                            const m = i.resultId && i.resultId.match(/.*\/v0\/data\/(.*\/.*\/.*)\/(.*)\/(.*)$/);
                            if (m && m.length === 4) {
                                i.schema = m[1];
                                i.version = m[2];
                                i.name = m[3];
                                i.title = i.schema + " (" + i.version + ")";
                            } else {
                                i.title = i.resultId;
                            }
                        });
                        queryResults.push(...response.results);
                        instancesStore.notifyChange();
        
                        const next = response 
                            && response.links 
                            && response.links.next
                            && response.links.next.href
                        const m = next && next.match(/.*(\/v0\/data\/.*)$/); // remove absolute path
                        const nextRequestUrl = m && m.length === 2 && m[1];
                        if (nextRequestUrl) {
                            doQuery(resource, nextRequestUrl);
                        } else {
                            instancesStore.toggleState("QUERY_LOADED", true);
                            instancesStore.toggleState("QUERY_LOADING", false);
                            instancesStore.notifyChange();
                        }
                    }
                } else {
                    if (false && typeof response === "string" && /.*<base href="https:\/\/services-dev\.humanbrainproject\.eu\/oidc\/">/.test(response)) {
                        window.location.replace("https://services-dev.humanbrainproject.eu/oidc/login");
                    } else {
                        instancesStore.toggleState("QUERY_ERROR", true);
                        instancesStore.toggleState("QUERY_LOADED", false);
                        instancesStore.toggleState("QUERY_LOADING", false);
                        instancesStore.notifyChange();
                    }
                }
            })
            .fail((e) => {
                instancesStore.toggleState("QUERY_ERROR", true);
                instancesStore.toggleState("QUERY_LOADED", false);
                instancesStore.toggleState("QUERY_LOADING", false);
                instancesStore.notifyChange();
            });
    };
      
    const startQuerying = () => {
        queryResults = [];
        total = 0;
        doResetComparison();

        if (instancesStore.is("QUERY_ERROR"))
            instancesStore.toggleState("QUERY_ERROR", false);
        if (!instancesStore.is("COMPARISON"))
            instancesStore.toggleState("COMPARISON", true);
        if (!instancesStore.is("ACTIVE"))
            instancesStore.toggleState("ACTIVE", true);
        instancesStore.notifyChange();

        if (!instancesStore.is("QUERY_LOADING"))
            instancesStore.toggleState("QUERY_LOADING", true);
        instancesStore.notifyChange();

        doQuery(querySchema.id, "/v0/data/" + querySchema.id + "?from=0&size=50&fields=all&deprecated=false&published=true");
    }

    const doResetComparison = () => {
        comparison = {
            instance1: null,
            instance2: null,
            properties: []
        };
        querySchema.properties.forEach(p => {
            comparison.properties.push({name: p.name, fullName: p.fullName, shortName: p.shortName});
        });
    };

    doClose = () => {
        instancesStore.toggleState("ACTIVE", false);
        instancesStore.toggleState("QUERY_ERROR", false);
        instancesStore.toggleState("QUERY_LOADING", false);
        instancesStore.toggleState("QUERY_LOADED", false);
        instancesStore.toggleState("COMPARISON", false);

        querySchema = null;
        queryResults = [];
        total = 0;
        comparison = null;
        instancesStore.notifyChange();
    };

    /**
     * Store trigerrable actions
     */

    instancesStore.addAction("instances:show", function (schema) {
        if (schema) {
            querySchema = schema;
            startQuerying();
        }
    });

    instancesStore.addAction("instances:retry", function () {
        if (querySchema)
            startQuerying();
        else
            doClose();
    });

    instancesStore.addAction("instances:close", function () {
        doClose();
    });

    instancesStore.addAction("instances:reset-comparison", function () {
        doResetComparison();
        instancesStore.toggleState("COMPARISON", true);
        instancesStore.notifyChange();
    });

    instancesStore.addAction("instances:select4comparison", function (instance) {
        if (!comparison.last)
            comparison.last = 2;
        const prev = comparison.last;
        comparison.last = ((comparison.last + 2) % 2) + 1;

        const movePrevious = !(comparison.last === 2 && comparison["instance2"] === null);

        if (movePrevious)
            comparison["instance" + prev] = comparison["instance" + comparison.last];
        comparison["instance" + comparison.last] = instance;

        comparison.properties.forEach(p => {
            if (movePrevious)
                p["instance" + prev] = p["instance" + comparison.last];
            let value = instance.source[p.name];
            p["instance" + comparison.last] = value;
        });

        instancesStore.toggleState("COMPARISON", true);
        instancesStore.notifyChange();
    });


    /**
     * Store public interfaces
     */

    instancesStore.addInterface("getQuerySchema", function () {
        return querySchema;
    });

    instancesStore.addInterface("getQueryResults", function () {
        return queryResults;
    });

    instancesStore.addInterface("getComparison", function () {
        return comparison;
    });

    instancesStore.addInterface("getLoadingStats", function () {
        if (total > 0) {
            if (queryResults && queryResults.length)
                return {
                    current: queryResults.length,
                    percentage: Math.floor(100 * queryResults.length/total),
                    total: total
                };
            return {
                current: 0,
                percentage: 0,
                total: total
            };
        }
        return {
            current: 0,
            percentage: 100,
            total: 0
        };
    });

    RiotPolice.registerStore(instancesStore);
})();