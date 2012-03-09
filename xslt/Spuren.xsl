<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>
<xsl:include href="Alarms.xsl"/>
<xsl:include href="Graph.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>All Recent Events</title>
	<meta http-equiv="refresh" content="5"/>
	<link rel="stylesheet" type="text/css" href="css/visualize.css"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"/>
	<script type="text/javascript" src="js/visualize.jQuery.js"/>	
	<script type="text/javascript" src="js/jquery.timeago.js"/>
	<script type="text/javascript" src="js/jquery.time.js"/>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Spuren'"/>
			<xsl:with-param name="filter" select="'1'"/>
		</xsl:call-template>

		<xsl:call-template name="Alarms"/>

		<div class="systemMap">
		<div class="header">Component Path Map</div>
			<table cellspacing="0" class="spurtypes">
				<xsl:for-each select="SpurTypes/SpurType">
					<xsl:call-template name="SpurType"/>
				</xsl:for-each>
			</table>
		</div>

		<xsl:for-each select="Statistics/Object">
			<xsl:call-template name="Graph"/>
		</xsl:for-each>

		<xsl:call-template name="legend-spuren"/>

		<div class="clear"/>
	</div>

	<script type="text/javascript">
		jQuery(document).ready(function() {
		 	jQuery(".time").time();
		});
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
				<small>
					<span class="interfaceLabel finished"><xsl:value-of select="/Spuren/Components/Component[@name=$name]/@started"/></span> /
					<span class="interfaceLabel announced"><xsl:value-of select="/Spuren/Components/Component[@name=$name]/@announced"/></span> /
					<span class="interfaceLabel error"><xsl:value-of select="/Spuren/Components/Component[@name=$name]/@failed"/></span>
				</small>
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
				<small>
					<span class="interfaceLabel finished"><xsl:value-of select="/Spuren/Interfaces/Interface[@to=$to and @from=$from]/@started"/></span> /
					<span class="interfaceLabel announced"><xsl:value-of select="/Spuren/Interfaces/Interface[@to=$to and @from=$from]/@announced"/></span> /
					<span class="interfaceLabel error"><xsl:value-of select="/Spuren/Interfaces/Interface[@to=$to and @from=$from]/@timeout"/></span>
				</small>
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

</xsl:stylesheet>
