<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>System Map</title>
	<meta http-equiv="refresh" content="10"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<div class="menu">
			<span class="menuitem activemenu"><a href="getMap">System Map</a></span>
			<span class="menuitem"><a href="get">Recent Events</a></span>
			<span class="menuitem"><a href="getHosts">Hosts</a></span>
			<span class="menuitem"><a href="getComponents">Components</a></span>
			<span class="menuitem"><a href="getInterfaces">Interfaces</a></span>
			<span class="menuitem"><a href="getAnnouncements">Announcements</a></span>
		</div>

		<div class="header">
			<h3>System Map</h3>
		</div>

		<div class="systemMap">
			<xsl:for-each select="Hosts/Host">
				<xsl:sort select="@name" order="ascending"/>
				<xsl:call-template name="Host"/>
			</xsl:for-each>
		</div>
	</div>
</body>
</html>
</xsl:template>

<xsl:template name="Host">
	<div class="host">
		<a href="get?host={@name}"><xsl:value-of select="@name"/></a>
	</div>
</xsl:template>

</xsl:stylesheet>
