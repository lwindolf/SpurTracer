<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>Component Overview</title>
	<meta http-equiv="refresh" content="10"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<div class="menu">
			<span class="menuitem"><a href="getMap">System Map</a></span>
			<span class="menuitem"><a href="get">Recent Events</a></span>
			<span class="menuitem activemenu"><a href="getComponents">Components</a></span>
			<span class="menuitem"><a href="getAnnouncements">Announcements</a></span>
		</div>

		<div class="header">
			<h3>List of Known Components</h3>
		</div>

		<table border="0" class="notifications">
			<tr>
				<th>Component</th>
				<th>Calls</th>
				<th>Errors</th>
				<th>Timeouts</th>
			</tr>
			<xsl:for-each select="Components/Component">
				<xsl:sort select="@time" order="descending" data-type="number"/>
				<xsl:call-template name="Component"/>
			</xsl:for-each>
		</table>

		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

<xsl:template name="Component">
	<tr class="component">
		<td><a href="get?component={@name}"><xsl:value-of select="@name"/></a></td>
		<td><xsl:value-of select="@started"/></td>
		<td><xsl:value-of select="@error"/></td>
		<td><xsl:value-of select="@timeout"/></td>
	</tr>
</xsl:template>

</xsl:stylesheet>
