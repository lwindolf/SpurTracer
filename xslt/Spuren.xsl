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
			<xsl:with-param name="nointerval" select="'1'"/>
		</xsl:call-template>

		<xsl:call-template name="Alarms"/>

		<div class="systemMap">
		<div class="header">Known Spur Types</div>
			<table class="spuren">
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

<xsl:template name="SpurType">
	<tr>
		<td><xsl:value-of select="Interface[1]/@from"/></td>
		<xsl:for-each select="Interface">
			<td><xsl:value-of select="@to"/></td>
		</xsl:for-each>
	</tr>
</xsl:template>

</xsl:stylesheet>
