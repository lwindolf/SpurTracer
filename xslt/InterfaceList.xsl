<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>Interface Overview</title>
	<meta http-equiv="refresh" content="10"/>
</head>
<body>
	<div class="header">
		<h3>List of Known Interfaces</h3>
	</div>

	<table border="0" class="notifications">
		<tr>
			<th>Interface</th>
			<th>Calls</th>
			<th>Errors</th>
			<th>Timeouts</th>
		</tr>
		<xsl:for-each select="Interfaces/Interface">
			<xsl:sort select="@time" order="descending" data-type="number"/>
			<xsl:call-template name="Interface"/>
		</xsl:for-each>
	</table>
</body>
</html>
</xsl:template>

<xsl:template name="Interface">
	<tr class="interface">
		<td><xsl:value-of select="@name"/></td>
		<td><xsl:value-of select="@started"/></td>
		<td><xsl:value-of select="@error"/></td>
		<td><xsl:value-of select="@timeout"/></td>
	</tr>
</xsl:template>

</xsl:stylesheet>
