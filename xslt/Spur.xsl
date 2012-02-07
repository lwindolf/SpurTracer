<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>Spur Trace</title>
	<xsl:if test="count(//Spur) != count(//Spur/Event[@status = 'finished' and @type = 'n'])">
		<!-- Only refresh if one Spur isn't finished -->
		<meta http-equiv="refresh" content="5"/>
	</xsl:if>

	<link rel="stylesheet" type="text/css" href="css/style.css"/>

	<script type="text/javascript" src="js/raphael-min.js"></script>
	<script type="text/javascript" src="js/dracula_graffle.js"></script>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"></script>
	<script type="text/javascript" src="js/dracula_graph.js"></script>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>
	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Recent'"/>
			<xsl:with-param name="filter" select="'1'"/>
		</xsl:call-template>

		<div class="info">

			<div id="mapCanvas"></div>

			<div class="legend">
				<table>
					<tr><th>Legend</th></tr>
					<tr><td class='started'>started</td></tr>
					<tr><td class='running'>running</td></tr>
					<tr><td class='error'>error</td></tr>
					<tr><td class='announced'>announced</td></tr>
					<tr><td class='finished'>finished</td></tr>
				</table>
			</div>
		</div>

		<div class="systemMap">
		<table border="0" class="notifications">
			<tr>
				<th>Host</th>
				<th>Time</th>
				<th>Status</th>
				<th>Description</th>
			</tr>
			<xsl:for-each select="Spur">
				<xsl:sort select="@started" order="descending" data-type="number"/>
				<xsl:call-template name="Spur"/>
			</xsl:for-each>
		</table>
		</div>

		<xsl:call-template name="SpurKarte"/>

		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

<xsl:template name="Spur">
	<xsl:element name="tr">
		<xsl:attribute name="class">
			source
			<xsl:choose>
				<xsl:when test="Event[@status = 'failed']">error</xsl:when>
				<xsl:when test="Event[@status = 'finished']">finished</xsl:when> 
				<xsl:when test="Event[@status = 'running']">running</xsl:when>
			</xsl:choose>
		</xsl:attribute>
		<td><a href="/getDetails?host={@host}"><xsl:value-of select="@host"/></a></td>
		<td colspan="3">
			<b><a href="/getDetails?component={@component}"><xsl:value-of select="@component"/></a></b>, ctxt
			<b><a href="/getSpur?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a></b>
		</td>
	</xsl:element>

	<xsl:for-each select="Event">
		<xsl:sort select="@time" order="ascending" data-type="number"/>
		<xsl:choose>
			<xsl:when test="@type = 'n'">
				<xsl:element name="tr">
					<xsl:attribute name="class">notification <xsl:if test="@status='failed'">error</xsl:if></xsl:attribute>
					<td/>
					<td><xsl:value-of select="@date"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><xsl:value-of select="@desc"/></td>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="tr">
					<xsl:attribute name="class">announcement <xsl:if test="@status!='finished'">announced</xsl:if></xsl:attribute>

					<td/>
					<td><xsl:value-of select="@date"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><a href="/getDetails?component={@newcomponent}"><xsl:value-of select="@newcomponent"/></a>, ctxt <a href="/getSpur?ctxt={@newctxt}"><xsl:value-of select="@newctxt"/></a></td>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
</xsl:template>

<xsl:template name="SpurKarte">

	<script type="text/javascript">	
		var redraw, g, renderer;

		function nice_duration(duration, alternativeText) {
			if(isNaN(duration)) {
				return alternativeText;
			}

			if(duration &lt; 1000) {
				duration += " ms";
			} else {
				duration = duration/1000 + " s";
			}

			return duration;
		}

		window.onload = function() {
			/* FIXME: use JQuery canvas dimensions */
			var width = 600;
			var height = 200;

			g = new Graph();

			<xsl:for-each select="//Spur">
				<xsl:sort select="@time" order="ascending" data-type="number"/>
				duration = <xsl:value-of select="Event[@status='finished']/@time - Event[@status='started']/@time"/>
				g.addNode("<xsl:value-of select="@component"/>",
					  { label:"<xsl:value-of select="@component"/> @ <xsl:value-of select='@host'/>\n "+nice_duration(duration, "pending")});
			</xsl:for-each>

			<xsl:for-each select="//Spur/Event[@type = 'c']">
				<xsl:variable name="component"><xsl:value-of select="@newcomponent"/></xsl:variable>
				duration = <xsl:value-of select="//Spur[@component=$component]/Event[@status='started']/@time - @time"/>
				g.addEdge("<xsl:value-of select="../@component"/>","<xsl:value-of select="@newcomponent"/>", 
				          { directed:true, stroke: (isNaN(duration)?"#CCC":"black"), label : nice_duration(duration, "announced") });
			</xsl:for-each>

			/* layout the graph using the Spring layout implementation */
			var layouter = new Graph.Layout.Spring(g);

			/* draw the graph using the RaphaelJS draw implementation */
			renderer = new Graph.Renderer.Raphael('mapCanvas', g, width, height);
		};
	</script>
</xsl:template>


</xsl:stylesheet>
