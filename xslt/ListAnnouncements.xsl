<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>All Recent Announcements</title>
	<meta http-equiv="refresh" content="10"/>
</head>
<body>
	<div class="header">
		<h3>List of All Recent Announcements</h3>
	</div>

	<p>Each announcement does indicate an interface that was triggered by one
	component, while not yet being processed by the component implementation
	the interface.</p>

	<p>An overdue announcement usually indicates a component failure.</p>

	<table border="0" class="notifications">
		<tr>
			<th>Comp</th>
			<th>Ctxt</th>
		</tr>
		<xsl:for-each select="Announcements/Announcement">
			<xsl:sort select="@time" order="descending" data-type="number"/>
			<xsl:call-template name="Announcement"/>
		</xsl:for-each>
	</table>
</body>
</html>
</xsl:template>

<xsl:template name="Announcement">
	<tr class="announcement">
		<td><a href="get?component={@component}"><xsl:value-of select="@component"/></a></td>
		<td><a href="get?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a></td>
	</tr>
</xsl:template>

</xsl:stylesheet>
