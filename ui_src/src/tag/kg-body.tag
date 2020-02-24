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
<kg-body>
    <style scoped>
         :scope {
            display: block;
        }

        .nodegraph {
            width: calc(100vw - var(--sidebar-width));
            height: calc(100vh - var(--topbar-height));

            cursor: all-scroll;
            font-size: 10px;
        }

        .nodegraph text {
            pointer-events: none;
        }

        .link-line {
            fill: none;
            stroke: #3498db;
            transition: stroke 0.5s ease-out, fill-opacity 0.5s ease-out, stroke-opacity 0.5s ease-out;
        }

        .link-line.provenance{
            stroke-dasharray: 3;
            stroke: rgba(255, 245, 162, 0.5);
        }

        .link-node__text {
            font-size: 9px;
            fill: #333;
            transition: fill-opacity 0.5s ease-out;
        }

        .link-node__circle {
            fill: #ecf0f1;
            stroke: #bdc3c7;
            transition: fill-opacity 0.5s ease-out, stroke-opacity 0.5s ease-out;
        }

         .link-node__circle.provenance{
            fill: #fff5a2;
         }

        .node__circle {
            stroke: #5ab1eb;
            fill: #1d6392;
            stroke-width: 1.5px;
            cursor: pointer;
            transition: stroke 0.5s ease-out, fill 0.5s ease-out, fill-opacity 0.5s ease-out, stroke-opacity 0.5s ease-out;
        }

        .node__occurrences {
            font-size: 12px;
            fill: white;
            font-weight: bold;
            transition: fill-opacity 0.5s ease-out;
        }

        .node__label {
            fill: #fff;
            font-size: 7px;
            transition: fill-opacity 0.5s ease-out;
        }

        .dephased {
            stroke-opacity: 0.1;
            fill-opacity: 0.1;
        }

        .selectedRelation {
            stroke: #2ecc71;
        }

        .selectedRelation circle {
            stroke: #2ecc71;
        }

        .selectedRelation line {
            stroke: #2ecc71;
        }

        .selectedNode circle {
            fill: #27ae60;
            stroke: #2ecc71;
        }

        .searchResult circle {
            stroke: #8e44ad;
            fill: #9b59b6;
        }

        .highlightedRelation {
            stroke: #f1c40f;
        }

        .highlightedRelation circle {
            stroke: #f1c40f;
        }

        .highlightedRelation line {
            stroke: #f1c40f;
        }

        .highlightedNode circle {
            fill: #f39c12;
            stroke: #f1c40f;
        }

        text {
            stroke: none !important;
            font-family: "Montserrat", sans-serif;
        }

        .actions {
            position: absolute;
            left: 20px;
            bottom: 20px;
        }

        .actions button {
            display: block;
            width: 40px;
            height: 40px;
            line-height: 40px;
            background: rgba(16, 16, 16, 0.5);
            appearance: none;
            -webkit-appearance: none;
            border: none;
            outline: none;
            font-size: 20px;
            color: #ccc;
            padding: 0;
            margin: 0;
            transition: all 0.5s ease-out;
            cursor: pointer;
            border-bottom: 1px solid #333;
        }

        .actions button:hover {
            color: white;
            background: #111;
        }

        .actions button:first-child {
            border-top-left-radius: 5px;
            border-top-right-radius: 5px;
        }

        .actions button:last-child {
            border-bottom-left-radius: 5px;
            border-bottom-right-radius: 5px;
            border-bottom: none;
        }

        .hull {
            fill: steelblue;
            stroke: steelblue;
            fill-opacity: 0.3;
            stroke-opacity: 0.3;
            stroke-width: 10px;
            stroke-linejoin: round;
        }
        .hull_container {
            width:100%;
            height:100%;
        }
        .info{
            position: absolute;
            top: 20px;
            left: 20px;
            color: white;
        }
        .details{
            position: absolute;
            top: 40px;
            left: 20px;
            color: white;
            font-size: 0.6em;
        }

        .stage {
            position: absolute;
            top: 20px;
            right: 60px;
            color: white;   
        }
    </style>
    <div class="info">{info}</div>
    <div class="details">{details}</div>
    <svg class="nodegraph" ref="svg"></svg>
    <div class="stage">Stage: {releasedStage ? "RELEASED" : "LIVE"}</div>
    
    <div class="actions">
        <button class="control-button zoom-in" onclick={zoomIn}>
            <i class="fa fa-plus" aria-hidden="true"></i>
        </button>
        <button class="control-button zoom-out" onclick={zoomOut}>
            <i class="fa fa-minus" aria-hidden="true"></i>
        </button>
        <button class="control-button reset-view" onclick={resetView}>
            <i class="fa fa-dot-circle-o" aria-hidden="true"></i>
        </button>
        <button class="control-button regroup" onclick={regroup}>
            <i class="fa fa-compress" aria-hidden="true"></i>
        </button>
        <button class="control-button degroup" onclick={degroup}>
            <i class="fa fa-expand" aria-hidden="true"></i>
        </button>
        <button class="control-button capture" onclick={capture}>
            <i class="fa fa-camera" aria-hidden="true"></i>
        </button>
    </div>

    <script>
        let self = this;

        const maxLinkSize = 40;
        const maxNodeSize = 60;

        this.selectedType = null;
        this.lastUpdate = null;
        this.simulation;
        this.nodes = [];
        this.links = [];
        this.info = "";
        this.details = "";
        this.color = d3.scaleOrdinal(d3.schemeCategory20);

        var polygon;
        var centroid;
        var scaleFactor = 1.4;
        var links, nodes, linknodes;
        var circleOpts = {
            minRadius: 20,
            maxRadius: 50
        }

        var nodeRscale;
        var linkRscale;

        this.initialZoom = 0.5;

        this.on("mount", () => {
            RiotPolice.requestStore("structure", this);
            RiotPolice.on("structure.changed", this.update);
            this.update();
        });

        this.on("unmount", () => {
            RiotPolice.off("structure.changed", this.update);
            RiotPolice.releaseStore("structure", this);
        });

        this.on("update", () => {
            if (!this.stores.structure.is("STRUCTURE_LOADED")) {
                return;
            }
            this.releasedStage = this.stores.structure.is("STAGE_RELEASED");
            var self = this;
            const previousLastUpdate = this.lastUpdate;
            this.lastUpdate = this.stores.structure.getLastUpdate();
            const previousSelectedType = this.selectedType;
            this.selectedType = this.stores.structure.getSelectedType();
            var data = this.stores.structure.getGraphData();
            var nodes = data.nodes;
            var links = data.links;

            //Calculating the max numberof instance and link values
            //to prepare a scale for the node radius and link width
            var nodesNumOfInstances = nodes.map(o => o.occurrences);
            var linkValues = links.map(o => o.occurrences);
            nodeRscale = d3.scaleLog()
                .domain([1,d3.max(nodesNumOfInstances)])
                .range([3,maxNodeSize])
            linkRscale = d3.scaleLog()
                .domain([1,d3.max(linkValues)])
                .range([3,maxLinkSize])

            if (!this.svg || this.lastUpdate !== previousLastUpdate || this.selectedType !== previousSelectedType) {
                this.info = "";
                this.details = "";
                this.nodes = nodes;
                this.links = links;

                $(this.refs.svg).empty().css({
                    opacity: 0
                });
                this.firstDraw();
                $(this.refs.svg).animate({
                    opacity: 1
                });
            }

            const newSelectedNode = this.stores.structure.getSelectedNode();
            if (newSelectedNode) {
                this.selectedNode = newSelectedNode;
                this.svg.selectAll(".selectedNode").classed("selectedNode", false);
                this.svg.selectAll(".selectedRelation").classed("selectedRelation", false);
                this.svg.selectAll(".related-to_" + this.selectedNode.hash).classed("selectedRelation", true);
                this.svg.select(".is_" + this.selectedNode.hash).classed("selectedNode", true);
            } else {
                if (this.selectedNode !== undefined) {
                    this.resetView();
                }
                this.selectedNode = undefined;
                this.svg.selectAll(".selectedNode").classed("selectedNode", false);
                this.svg.selectAll(".selectedRelation").classed("selectedRelation", false);
            }

            const newHighlightedNode = this.stores.structure.is("NODE_HIGHLIGHTED") && this.stores.structure.getHighlightedNode();
            if (newHighlightedNode) {
                this.highlightedNode = newHighlightedNode;
                this.svg.selectAll(".highlightedNode").classed("highlightedNode", false);
                this.svg.selectAll(".highlightedRelation").classed("highlightedRelation", false);
                this.svg.selectAll(".related-to_" + this.highlightedNode.hash).classed("highlightedRelation", true);
                this.svg.select(".is-type_" + this.highlightedNode.typeHash).classed("highlightedNode", true);
            } else {
                this.highlightedNode = undefined;
                this.svg.selectAll(".highlightedNode").classed("highlightedNode", false);
                this.svg.selectAll(".highlightedRelation").classed("highlightedRelation", false);
            }

            this.svg.selectAll(".searchResult").classed("searchResult", false);
            if (this.stores.structure.is("SHOW_SEARCH_PANEL")) {
                this.searchResults = this.stores.structure.getSearchResults();
                this.searchResults.forEach(node => {
                    this.svg.selectAll(".is-type_" + node.typeHash).classed("searchResult", true);
                });
            } else {
                this.searchResults = [];
            }
        });

        this.resetView = () => {
            let width = this.svg.node().getBoundingClientRect().width;
            let height = this.svg.node().getBoundingClientRect().height;
            const zoom = this.initialZoom;
            let zoomScaleTo = zoom;
            this.svg.transition().duration(500)
                .call(this.zoom.transform, d3.zoomIdentity.translate(width / 2 * zoom, height / 2 *
                    zoom).scale(zoomScaleTo));
        }

        $(document).on("keydown", e => {
            if (e.shiftKey && e.ctrlKey && e.keyCode == 67) {
                if (!this.blockDownload) {
                    this.blockDownload = true;
                    self.capture();
                }
            } else {
                this.blockDownload = false;
            }
        });

        this.capture = () => {            
            let date = new Date();
            let displayText = this.view.selectAll(".node__label").attr("display");
            this.view.selectAll(".node__label").attr("display", "");
            saveSvgAsPng(this.refs.svg, "HBP_KG_" + moment(date).format("YYYY-MM-DD_kk-mm-ss") + ".png", {
                selectorRemap: (s) => {
                    return s.replace('kg-body', '')
                },
                scale: 4
            });
            this.view.selectAll(".node__label").attr("display", displayText);
        }

        this.zoomIn = () => {
            this.svg.transition().duration(250).call(this.zoom.scaleBy, 1.25);
        }

        this.zoomOut = () => {
            this.svg.transition().duration(250).call(this.zoom.scaleBy, 0.75);
        }

        this.regroup = () => {
            var self = this;
            this.simulation.force("groupXAxis", d3.forceX().strength(0.03))
                .force("groupOnYAxis", d3.forceY().strength(0.03));
            this.simulation.on("end", () => {
                self.simulation.force("groupXAxis", d3.forceX().strength(0))
                    .force("groupOnYAxis", d3.forceY().strength(0));
            });
            this.simulation.alpha(1).restart();
        }
        this.degroup = () => {
            var self = this;
            this.simulation.force("groupOnXAxis", d3.forceX().strength(-0.005))
                .force("groupOnYAxis", d3.forceY().strength(-0.005));
            this.simulation.on("end", () => {
                self.simulation.force("groupOnXAxis", d3.forceX().strength(0))
                    .force("groupOnYAxis", d3.forceY().strength(0));
            });
            this.simulation.alpha(1).restart();
        }

        this.firstDraw = () => {
            var self = this;
            if (self.simulation) {
                self.simulation.stop();
            }
            this.svg = d3.select(this.refs.svg);
            
            var width = this.svg.node().getBoundingClientRect().width;
            var height = this.svg.node().getBoundingClientRect().height;
            
            // Create a container for the hulls
            // in order to draw the hulls (SVG) before/under the nodes
            var hull = this.svg.append("g").attr("class", "hull_container");

            this.view = this.svg.append("g").attr("class", "view");

            var linksg = this.view.append("g")
                .attr("class", "links")
            var linknodesg = this.view.append("g")
                .attr("class", "link-nodes")
            var nodesg = this.view.append("g")
                .attr("class", "nodes")

            var groupIds = [];
            if (!this.selectedType) {
                // Grouping nodes by organization
                groupIds = d3.nest().key(n => n.group ).entries(this.nodes);
            }

            self.simulation = d3.forceSimulation(nodes)
                .force('link', d3.forceLink()
                    .id(d => d.id)
                    .distance(d => 40)
                )
                .force('charge', d3.forceManyBody()
                    .distanceMin(10)
                    .distanceMax(height / 2)
                    .strength(-100)
                )
                .force('collide', d3.forceCollide()
                    .radius(d => !this.selectedType ? nodeRscale(d.occurrences) + 8:30)
                )
                .force('center', d3.forceCenter(width / 2, height / 2));


            // SVG path for hulls
            if (!this.selectedType) {
                paths = hull.selectAll('.hull')
                    .data(groupIds, d => d )
                    .enter()
                    .append('g')
                    .attr('class', 'hull')
                    .append('path')
                    .style( 'fill-opacity', 0.3)
                    .style('stroke-width', 3)
                    .style('stroke', d => self.color(d.key))
                    .style('fill', d => self.color(d.key))
                    .style('opacity', 0)

                paths
                    .transition()
                    .duration(2000)
                    .style('opacity', 1)

                // add interaction to the groups
                hull.selectAll('.hull')
                    .call(d3.drag()
                        .on('start', groupDragStarted)
                        .on('drag', group_dragged)
                        .on('end', groupDragEnded)
                    ).on("mouseover", d => {
                        self.info = d.key;
                        self.details = "";
                        self.update()
                    })
                    .on("mouseout", d => {
                        self.info = "";
                        self.details = "";
                        self.update()
                    });
            }
        
            restart();
            
            this.zoom = d3.zoom()
                .scaleExtent([0.1, 40])
                .translateExtent([
                    [-5000, -5000],
                    [width + 5000, height + 5000]
                ])
                .on("zoom", zoomed);

            this.svg.call(this.zoom);

            //Initial scale
            var previousZoom = this.initialZoom;
            this.svg.call(this.zoom.scaleTo, previousZoom);
            hull.call(this.zoom.scaleTo, previousZoom);
            
            nodes.select('.node__label').attr("display", previousZoom >= 1 ? "" : "none");

            // Assigning data and behaviour to the different SVG elements
            function restart() {

                links = linksg
                .selectAll(".link-line")
                .data(self.links)
                .enter().append("line")
                .attr("class", "link-line")
                .each(function(d) {
                    d3.select(this).classed("related-to_" + d.source.hash, true);
                    d3.select(this).classed("related-to_" + d.target.hash, true);
                    d3.select(this).classed("related-to-type_" + d.source.typeHash, true);
                    d3.select(this).classed("related-to-type_" + d.target.typeHash, true);
                    d3.select(this).classed("provenance", d.provenance)
                })
                .attr("stroke-width", d => linkRscale(d.occurrences))
                .on("mouseover", d => {
                    if (!self.selectedType) {
                        if (d.target.group == d.source.group){
                            self.info = d.source.group;
                        } else {
                            self.info = "from " + d.source.group + " to " + d.target.group;
                        }
                    } else {
                        self.info = "from " + d.source.name + " to " + d.target.name;
                    }
                    self.details = "";
                    self.update();
                })
                .on("mouseout", d => {
                    self.info = "";
                    self.details = "";
                    self.update()
                })

                linknodes = linknodesg
                    .selectAll(".link-node")
                    .data(self.links)
                    .enter().append("g")
                    .attr("class", "link-node")
                    .each(function(d) {
                        let $this = d3.select(this);

                        $this.append("circle")
                            .attr("class", "link-node__circle")
                            .attr("r", 10)
                            .classed("provenance", d.provenance);

                        $this.append("text")
                            .attr("class", "link-node__text")
                            .attr("text-anchor", "middle")
                            .text(d.occurrences);
                        $this.append("title").text(d.name);

                        d3.select(this).classed("related-to_" + d.source.hash, true);
                        d3.select(this).classed("related-to_" + d.target.hash, true);
                        d3.select(this).classed("related-to-type_" + d.source.typeHash, true);
                        d3.select(this).classed("related-to-type_" + d.target.typeHash, true);

                    })
                    .on("mouseover", d => {
                        if (!self.selectedType) {
                            if (d.target.group == d.source.group){
                                self.info = d.source.group;
                            } else {
                                self.info = d.source.group + " <-> " + d.target.group;
                            }
                        } else {
                            self.info = "from " + d.source.name + " to " + d.target.name;
                        }
                        self.details = "";
                        self.update()
                    })
                    .on("mouseout", d => {
                        self.info = "";
                        self.update();
                    })


                nodes = nodesg
                    .selectAll(".node")
                    .data(self.nodes)
                    .enter().append("g")
                    .attr("class", "node")
                    .each(function(d) {
                        let $this = d3.select(this);
                        $this.append("circle")
                            .attr("class", "node__circle")
                            .attr("r", d => nodeRscale(d.occurrences))
                            .append('title').text(d.id);

                        $this.append("text")
                            .attr("class", "node__label")
                            .attr("text-anchor", "middle")
                            .text(d.name);

                        $this.append("text")
                            .attr("class", "node__occurrences")
                            .attr("text-anchor", "middle")
                            .text(d.occurrences);

                        d3.select(this).classed("is_" + d.hash, true);
                        d3.select(this).classed("is-type_" + d.typeHash, true);
                        d3.select(this).classed("related-to_" + d.hash, true);
                        d3.select(this).classed("related-to-type_" + d.typeHash, true);
                        d.linksTo.forEach(linkTo => {
                            d3.select(this).classed("related-to_" + linkTo.hash, true);
                            d3.select(this).classed("related-to-type_" + linkTo.typeHash, true);
                        });

                    })
                    .call(d3.drag()
                        .on("start", dragstarted)
                        .on("drag", dragged)
                        .on("end", dragended))
                    .on("mouseover", d => {
                        self.view
                            .selectAll(".node:not(.related-to-type_" + d.typeHash + "), .link-node:not(.related-to-type_" + d.typeHash + "), .link-line:not(.related-to-type_" + d.typeHash + ")")
                            .classed("dephased", true);
                        if (!self.selectedType) {
                            self.info = d.group + "/" + d.name;
                        } else {
                            self.info = d.name;
                        }
                        self.details = d.id;
                        self.update();
                    })
                    .on("mouseout", d => {
                        self.view.selectAll(".dephased").classed("dephased", false);
                        self.info = "";
                        self.details = "";
                        self.update();
                    })
                    .on("click", d => {
                        RiotPolice.trigger("structure:node_select", d);
                    })

                //Start force simulation    
                self.simulation
                    .nodes(self.nodes.concat(self.links))
                    .on("tick", ticked);

                self.simulation.force("link")
                    .links(self.links);
            }
            
            function ticked() {
                
                links
                    .attr("x1", d => d.source.x)
                    .attr("y1", d => d.source.y)
                    .attr("x2", d => d.target.x)
                    .attr("y2", d => d.target.y);

                linknodes.select('.link-node__circle')
                    .attr("cx", d => d.x = (d.source.x + d.target.x) * 0.5)
                    .attr("cy", d => d.y = (d.source.y + d.target.y) * 0.5);

                linknodes.select('.link-node__text')
                    .attr("x", d => d.x)
                    .attr("y", d => d.y + 4);

                nodes.select('.node__circle')
                    .attr("cx", d => d.x)
                    .attr("cy", d => d.y)

                nodes.select('.node__label')
                    .attr("x", d => d.x)
                    .attr("y", d => d.y + 12);

                nodes.select('.node__occurrences')
                    .attr("x", d => d.x)
                    .attr("y", d => d.y + 4);
                
                if (!self.selectedType) {
                    //Regrouping nodes by private spaces
                    var coordMap = new Map();
                    nodes.each(node => {
                        const coord = {x: node.x, y: node.y, occurrences: node.occurrences};
                        (coordMap[node.group] = coordMap[node.group] || []).push(coord)
                    });

                    // get the centroid of each group:
                    var centroids = new Map();

                    for (var group in coordMap) {
                        var groupNodes = coordMap[group];
                        var n = groupNodes.length;
                        var cx = 0;
                        var tx = 0;
                        var cy = 0;
                        var ty = 0;
                        var totalNumOfInstances = 0;
                        groupNodes.forEach(d => {
                            tx += d.x;
                            ty += d.y;
                            totalNumOfInstances += d.occurrences;
                        })

                        cx = tx/n;
                        cy = ty/n;

                        centroids[group] = {x: cx, y: cy, totalNumOfInstances: totalNumOfInstances} ;  
                    }

                    //Make the x-position equal to the x-position specified in the module positioning object or, if not in
                    //the hash, then set it to 250
                    var forceX = d3.forceX(d => centroids[d.group] ? centroids[d.group].x : width / 2)
                        .strength(0.3);

                    //Same for forceY--these act as a gravity parameter so the different strength determines how closely
                    //the individual nodes are pulled to the center of their module position
                    var forceY = d3.forceY(d => centroids[d.group] ? centroids[d.group].y : height / 2)
                        .strength(0.3);

                    self.simulation
                        .force("x", forceX)
                        .force("y", forceY);
                }

                if (!self.selectedType) {
                    updateGroups();
                }
            }

            function dragstarted(d) {
                if (!d3.event.active) self.simulation.alphaTarget(0.01).restart();
                d.fx = d.x;
                d.fy = d.y;
            }

            function dragged(d) {
                d.fx = d3.event.x;
                d.fy = d3.event.y;
            }

            function dragended(d) {
                if (!d3.event.active) self.simulation.alphaTarget(0);
                d.fx = null;
                d.fy = null;
            }
            
            function zoomed() {
                var currentZoom = d3.event.transform.k;
                if (previousZoom < 1 && currentZoom >= 1) {
                    nodes.select('.node__label').attr("display", "");
                } else if (previousZoom >= 1 && currentZoom < 1) {
                    nodes.select('.node__label').attr("display", "none");
                }
                self.view.attr("transform", d3.event.transform);
                hull.attr("transform", d3.event.transform);
                previousZoom = currentZoom;
            }
            
            function updateGroups() {
                groupIds.forEach(n => {
                    var path = paths.filter(d => d.key == n.key)
                    .attr('transform', 'scale(1) translate(0,0)')
                    .attr('d', d => {
                        var node_coords = nodes
                            .filter(d => d.group == n.key)

                        // to scale the shape properly around its points:
                        // move the 'g' element to the centroid point, translate
                        // all the path around the center of the 'g' and then
                        // all the path around the center of the 'g' and then
                        // we can scale the 'g' element properly

                        
                        if (node_coords.nodes().length == 1){
                            //If there is only one node we draw a circle around it
                            polygon = node_coords.data().map(i => { return [i.x, i.y]})      
                            centroid = polygon[0]
                            return circle(n.values[0].occurrences)

                        } else if (node_coords.nodes().length == 2){
                            //If there are two nodes we extrapolate two other points in order to create a polygon
                            const arr = node_coords.data().map(i => [i.x, i.y]);
                            arr.push([arr[0][0], arr[1][1]])
                            arr.push([arr[1][0], arr[0][1]])
                            polygon = d3.polygonHull(arr);
                            centroid = [(polygon[0][0] + polygon[1][0])/2,(polygon[0][1]+ polygon[1][1])/2]
                            return valueline(
                                polygon.map(point => [  point[0] - centroid[0], point[1] - centroid[1] ])
                            );
                        } else {
                            node_coords = node_coords.data().map(d => [d.x, d.y]);
                            polygon = d3.polygonHull(node_coords);         
                            centroid = d3.polygonCentroid(polygon);
                            return valueline(
                                polygon.map(point => [ point[0] - centroid[0], point[1] - centroid[1] ])
                            );
                        }

                    });
                    
                    d3.select(path.node().parentNode).attr('transform', 'translate('  + centroid[0] + ',' + centroid[1] + ') scale(' + scaleFactor + ')');
                });
            }

            //Return the svg path for a circle
            //We only specify a m (moveTo) relative, because the absolute position of the circle will be set in the updateGroups function
            const circle = size => {
                const radius = getRadius(size);
                var path =  "m " + (-radius) + ",0 a " + radius+","+radius+" 0 1, 0 " +(radius*2)+",0" +" a " + radius+","+radius+" 0 1 ,0 " +(-radius*2)+",0";
                return path;
            };

            const getRadius = size => {
                if (size < circleOpts.minRadius){
                    return circleOpts.minRadius
                } else if (size > circleOpts.maxRadius){
                    return circleOpts.maxRadius
                }
                return size;
            };

            // drag groups
            function groupDragStarted(groupId) {
                if (!d3.event.active) self.simulation.alphaTarget(0.3).restart();
                d3.select(this).select('path').style('stroke-width', 3);
            }

            function group_dragged(groupId) {
                nodes
                    .filter(d => d.group == groupId.key)
                    .each(d => {
                        d.x += d3.event.dx;
                        d.y += d3.event.dy;
                    })
            }

            function groupDragEnded(groupId) {
                if (!d3.event.active) self.simulation.alphaTarget(0.3).restart();
                d3.select(this).select('path').style('stroke-width', 1);
            }

            //Returns an svg path for the hull 
            var valueline = d3.line()
                .x(d => d[0])
                .y(d => d[1])
                .curve(d3.curveCatmullRomClosed);
       
        };
    </script>
</kg-body>