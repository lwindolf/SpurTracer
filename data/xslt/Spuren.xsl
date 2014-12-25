<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>
<xsl:include href="Alarms.xsl"/>
<xsl:include href="Graph.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>Spuren</title>
	<meta http-equiv="refresh" content="5"/>
	<link rel="stylesheet" type="text/css" href="css/visualize.css"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-2.1.1.min.js"/>
	<script type="text/javascript" src="js/visualize.jQuery.js"/>	
	<script type="text/javascript" src="js/jquery.timeago.js"/>
	<script type="text/javascript" src="js/jquery.time.js"/>
	<script type="text/javascript" src="js/d3.v3.js"></script>
	<script type="text/javascript" src="js/cola.v3.min.js"></script>
	<script type="text/javascript" src="js/spuren_view.js"></script>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Spuren'"/>
			<xsl:with-param name="filter" select="'1'"/>
		</xsl:call-template>

		<xsl:call-template name="Alarms"/>

		<div class="clear"/>

		<div class="systemMap" style="float:none">
		<div class="header">Component Path Map</div>
			<div class="map">
			</div>
		</div>

		<xsl:for-each select="Statistics/Object">
			<xsl:call-template name="Graph"/>
		</xsl:for-each>

		<xsl:call-template name="legend-spuren"/>

		<div class="clear"/>
	</div>

	<script type="text/javascript">
	<script type="text/javascript">
		var view = new SptSpurenView('.map');
		var reloadTimeout;

		function reloadTimer() {
			view.reload();

			clearTimeout(reloadTimeout);
			reloadTimeout = setTimeout("reloadTimer();", 5000);  // FIXME: hard-coded timeout
		}

		jQuery(document).ready(function() {
		 	jQuery(".time").time();

			//reloadTimer();
		});
	</script>);
	</script>
</body>
</html>
</xsl:template>

<xsl:template name="componentLabel">
	<xsl:param name="name"/>
	<xsl:param name="spurNr"/>
	<xsl:param name="interfaceNr"/>

	<xsl:choose>
		<xsl:when test="$name = //SpurType[@nr = ($spurNr - 1)]/Interface[@nr = $interfaceNr]/@from">
			<td class="leftSpurConnector"/>
			<td class="spurConnector"><span class="hidden">.</span></td>
		</xsl:when>
		<xsl:when test="//SpurType[@nr = $spurNr]/Interface[@nr = ($interfaceNr - 1)]/@to = //SpurType[@nr = ($spurNr - 1)]/Interface[@nr = ($interfaceNr - 1)]/@to">
			<td class="spurConnector"><span class="hidden">.</span></td>
			<td class="rightSpurConnector"/>
		</xsl:when>
		<xsl:otherwise>
			<td colspan="2">
			<div class="componentLabel">
				<strong><xsl:value-of select="$name"/></strong><br/>
				<xsl:call-template name="counterSet">
					<xsl:with-param name="this" select="/Spuren/Components/Component[@name=$name]"/>
					<xsl:with-param name="type">component</xsl:with-param>
				</xsl:call-template>
			</div>
			</td>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="SpurType">
	<tr class="path">
		<xsl:call-template name="componentLabel">
			<xsl:with-param name="spurNr"><xsl:value-of select="@nr"/></xsl:with-param>
			<xsl:with-param name="interfaceNr"><xsl:value-of select="'0'"/></xsl:with-param>
			<xsl:with-param name="name"><xsl:value-of select="Interface[1]/@from"/></xsl:with-param>
		</xsl:call-template>

		<xsl:for-each select="Interface">
			<xsl:variable name="from"><xsl:value-of select="@from"/></xsl:variable>
			<xsl:variable name="to"><xsl:value-of select="@to"/></xsl:variable>

			<td class="spurConnector" valign="top">
				<div class="interfaceMetrics">
					<xsl:call-template name="counterSet">
						<xsl:with-param name="this"  select="/Spuren/Interfaces/Interface[@to=$to and @from=$from]"/>
						<xsl:with-param name="type">interface</xsl:with-param>
					</xsl:call-template>
				</div>
			</td>

			<xsl:call-template name="componentLabel">
				<xsl:with-param name="spurNr"><xsl:value-of select="../@nr"/></xsl:with-param>
				<xsl:with-param name="interfaceNr"><xsl:value-of select="@nr + 1"/></xsl:with-param>
				<xsl:with-param name="name"><xsl:value-of select="$to"/></xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
	</tr>
</xsl:template>

<xsl:template name="counterSet">
	<xsl:param name="this"/>
	<xsl:param name="type"/>
	<small>
		<xsl:if test='$this/@started > 0'>
			<xsl:element name="span">
				<xsl:if test="$type = 'component'">
					<xsl:attribute name="title">Successful executions</xsl:attribute>
					<xsl:attribute name="class">interfaceLabel finished</xsl:attribute>
				</xsl:if>
				<xsl:if test="$type = 'interface'">
					<xsl:attribute name="title">Times Triggered</xsl:attribute>
					<xsl:attribute name="class">interfaceLabel started</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="$this/@started"/>
			</xsl:element> / 

			<xsl:element name="span">
				<xsl:if test="$type = 'interface'"><xsl:attribute name="title">pending announcements</xsl:attribute></xsl:if>
				<xsl:if test="$type = 'component'"><xsl:attribute name="title">running instances</xsl:attribute></xsl:if>			
				<xsl:attribute name="class">interfaceLabel
					<xsl:if test="$this/@announced > 0">
						<xsl:if test="$type = 'interface'"> announced</xsl:if>
						<xsl:if test="$type = 'component'"> running</xsl:if>
					</xsl:if>
				</xsl:attribute>
				<xsl:value-of select="$this/@announced"/>
			</xsl:element>

			<xsl:if test="$this/@timeout > 0">
				/ <span title="timeouts" class="interfaceLabel timeout"><xsl:value-of select="$this/@timeout"/></span>
			</xsl:if>
			<xsl:if test="$this/@failed > 0">
				/ <span title="failures" class="interfaceLabel error"><xsl:value-of select="$this/@failed"/></span>
			</xsl:if>
		</xsl:if>
	</small>
</xsl:template>

</xsl:stylesheet>
