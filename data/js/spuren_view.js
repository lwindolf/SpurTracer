/* Graph displaying all components and interfaces and their statistic counters */

function SptSpurenView(stage) {
	this.stage = stage;		/* parent <div> selector */
	this.selectedNode = null;
	this.graph = null;
	this.viewBoxX = 0;		/* panning coordinates */
	this.viewBoxY = 0;
	this.nodePositions = new Array();
	this.reload();
}

SptSpurenView.prototype.addNodeToColaNodeList = function(nodeList, nodeIndex, name, data) {
	var n = {};
	n['name'] = name;
	n['height'] = 55;

	/* We expect a node label font size of 10pt! */
	n['width'] = 6 * n['name'].length + 48;
	// FIXME: consider statistic numbers to max length!

	n['status'] = '';
	try {
		$.each(data.Alarms, function(index, data) {
			if(data['id'] == name && data['type'] == 'component') {
				n['status'] = data['severity'];
			}
		});
		$.each(data.Components, function(index, data) {
			if(data['name'] == name) {
				n['stats'] = data;
			}
		});
	}
	catch(e) { }

	if(this.nodePositions[n['name']]) {
		n.x = this.nodePositions[n['name']].x;
		n.y = this.nodePositions[n['name']].y;
	}

	nodeList.push(n);
	nodeIndex[n['name']] = Object.keys(nodeIndex).length;
};

SptSpurenView.prototype.setData = function(data) {
	var view = this;
	var width = $(this.stage).width(),
	    height = width * 3 / 4,
	    r = 9, margin = 0;

	var d3cola = cola.d3adaptor()
	    .convergenceThreshold(0.01)
	    .linkDistance(200)
	    .avoidOverlaps(true)
	    .size([width, height]);

	$(this.stage).html("");
	$(this.stage).css("overflow", "hidden");
	var svg = d3.select(this.stage).append("svg")
	    .attr("width", width)
	    .attr("height", height);

	// Allow panning as suggested in by dersinces (CC BY-SA 3.0) in
	// http://stackoverflow.com/questions/20099299/implement-panning-while-keeping-nodes-draggable-in-d3-force-layout
	var drag = d3.behavior.drag();
	drag.on('drag', function() {
	    view.viewBoxX -= d3.event.dx;
	    view.viewBoxY -= d3.event.dy;
	    svg.select('g.node-area').attr('transform', 'translate(' + (-view.viewBoxX) + ',' + (-view.viewBoxY) + ')');
	});
	svg.append('rect')
	  .classed('bg', true)
	  .attr('stroke', 'transparent')
	  .attr('fill', 'transparent')
	  .attr('x', 0)
	  .attr('y', 0)
	  .attr('width', width)
	  .attr('height', height)
	  .call(drag);

	var nodeArea = svg.append('g').classed('node-area', true);

	// Restore previous panning
	svg.select('g.node-area').attr('transform', 'translate(' + (-view.viewBoxX) + ',' + (-view.viewBoxY) + ')');
	
	// Map data 
	var i = 0;
	var nodeIndex = {};

	view.graph = new Array();
	view.graph["nodes"] = new Array();
	view.graph["links"] = new Array();

	$.each(data.Spuren.Components, function(index, nodeData) {
		view.addNodeToColaNodeList(view.graph['nodes'], nodeIndex, nodeData['name'], data.Spuren);
	});
	$.each(data.Spuren.Interfaces, function(index, connectionData) {
		// Node sources and target might not exist
		// in case of non-managed nodes we connect to/from
		if(nodeIndex[connectionData.from] == undefined)
			view.addNodeToColaNodeList(view.graph['nodes'], nodeIndex, connectionData.from, data.Spuren);
		if(nodeIndex[connectionData.to] == undefined)
			view.addNodeToColaNodeList(view.graph['nodes'], nodeIndex, connectionData.to, data.Spuren);
		var l = {};
		l['source'] = nodeIndex[connectionData.from];
		l['target'] = nodeIndex[connectionData.to];
		view.graph['links'].push(l);
	});

	var doLayout = function () {

	svg.append('svg:defs').append('svg:marker').attr('id', 'end-arrow').attr('viewBox', '0 -5 10 10').attr('refX', 5).attr('markerWidth', 9).attr('markerHeight', 3).attr('orient', 'auto').append('svg:path').attr('d', 'M0,-5L10,0L0,5L2,0').attr('stroke-width', '0px').attr('fill', '#555');

	var link = nodeArea.selectAll(".link")
	      .data(view.graph.links)
	      .enter().append("line")
	      .attr("class", "link")
	      .style("stroke-width", function(d) { return Math.sqrt(d.value); });
	
	var pad = 3;
	var node = nodeArea.selectAll(".node")
		.data(view.graph.nodes);

	node.enter().append("g")
		.attr("class", "node")
		.each(function(d) {
			d3.select(this)
			    .append("rect")
			    .attr("x", function (d) { return -d.width/2; })
			    .attr("y", function (d) { return -d.height/2; })
			    .attr("width", function (d) { return d.width - 2 * pad; })
			    .attr("height", function (d) { return d.height - 2 * pad; })
			    .attr("rx", r - 3).attr("ry", r - 3)
			    .attr("class", function (d) { return "node_rect node_" + d.name.replace('.',''); })
			    .style("fill", function (d) {
				if(d.status == 'critical')
					return '#f30';
				if(d.status == 'warning')
					return '#fea';
				if(d.status == 'UNKNOWN')
					return '#fca';
				if($.inArray(d.name, data.nodes) == -1)
					return '#ccc';

				return 'white';
			    })
			    .style("stroke-width", 1)
			    .style("stroke", "black");

			d3.select(this)
			    .append("text")
			    .attr("dy", function(d) { return pad + 18 - d.height/2 })
			    .attr("class", "label")
			    .text(function (d) { return d.name; })
			    .on("mouseover", function(d) {
				d3.select(".node_"+d.name.replace('.','')).style({'stroke-width':2,'stroke':'black'});
			    })
			    .on("mouseout", function(d) {
				if(d.name != view.selectedNode)
					d3.select(".node_"+d.name.replace('.','')).style({'stroke-width':1,'stroke':'gray'});
			    })
			    .on("click", function (d) {
				if (d3.event.defaultPrevented) return; // click suppressed
				if($.inArray(d.name, data.nodes) != -1) {
					d3.selectAll(".node_rect").style({'stroke-width':1,'stroke':'gray'});
					d3.select(".node_"+d.name.replace('.','')).style({'stroke-width':2,'stroke':'black'});
					view.selectedNode = d.name;
					loadNode(d.name);
				}
			    });

			// Build statistic number HTML
			var stats = "";
			try {
				stats += "<span class='started'>"+d.stats.started+"</span>";
				if(d.stats.announced > 0)
					stats += " / <span class='running'>"+d.stats.announced+"</span>";
				if(d.stats.timeout > 0)
					stats += " / <span class='timeout'>"+d.stats.timeout+"</span>";
				if(d.stats.failed > 0)
					stats += " / <span class='error'>"+d.stats.failed+"</span>";
			} catch(e) { }

			d3.select(this)
				.append("foreignObject")
				.attr("x", function (d) { return -(d.width - 2*pad)/2; })
				.attr("y", function (d) { return -d.height/2 + 20; })
				.attr("width", "100%")
				.attr("height", 30)
				.attr("class", "stats")
				.append("xhtml:body")
				.html(stats);
		})
	        .call(d3cola.drag);

	if(view.nodePositions.length == 0) {
		console.log("Calculating layout...");
		d3cola
			    .flowLayout("x", 250)
			    .symmetricDiffLinkLengths(6)
			.start(100,20,30);
	} else {
		/* Do only a few full constraint iterations */
		d3cola.start(0,0,5);
	}

	d3cola.on("tick", function() {
                node.each(function (d) {
                    d.bounds.setXCentre(d.x);
                    d.bounds.setYCentre(d.y);
                    d.innerBounds = d.bounds.inflate(-margin);
                });

		node.attr("transform", function (d) { return "translate(" + d.x + "," + d.y + ")"; });

                link.each(function (d) {
                    cola.vpsc.makeEdgeBetween(d, d.source.innerBounds, d.target.innerBounds, 5);
                });
		link.attr("x1", function (d) {
			return d.sourceIntersection.x;
		}).attr("y1", function (d) {
			return d.sourceIntersection.y;
		}).attr("x2", function (d) {
			return d.arrowStart.x;
		}).attr("y2", function (d) {
			return d.arrowStart.y;
		});
	  });
	};

	d3cola.nodes(view.graph.nodes)
	      .links(view.graph.links);
	doLayout();
};

SptSpurenView.prototype.reload = function() {
	var view = this;

	/* save old node positions */
	if(view.graph) {
		view.graph.nodes.forEach(function (e) {
			if(!view.nodePositions[e.name])
				view.nodePositions[e.name] = new Array();
			view.nodePositions[e.name].x = e.x;
			view.nodePositions[e.name].y = e.y;
		});
	}

	console.log('Updating...');
	$.getJSON("getSpuren?output=json", function (data) {
		view.setData(data);
	});
};
