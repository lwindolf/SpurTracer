<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>Host Overview</title>
	<meta http-equiv="refresh" content="10"/>
</head>
<body>
	<div class="header">
		<h3>List of Known Hosts</h3>
	</div>

	<table border="0" class="notifications">
		<tr>
			<th>Hostname</th>
			<th>Calls</th>
			<th>Errors</th>
			<th>Timeouts</th>
		</tr>
		<xsl:for-each select="Hosts/Host">
			<xsl:sort select="@time" order="descending" data-type="number"/>
			<xsl:call-template name="Host"/>
		</xsl:for-each>
	</table>
</body>
</html>
</xsl:template>

<xsl:template name="Host">
	<tr class="host">
		<td><a href="get?host={@name}"><xsl:value-of select="@name"/></a></td>
		<td><xsl:value-of select="@started"/></td>
		<td><xsl:value-of select="@error"/></td>
		<td><xsl:value-of select="@timeout"/></td>
	</tr>
</xsl:template>

</xsl:stylesheet>
