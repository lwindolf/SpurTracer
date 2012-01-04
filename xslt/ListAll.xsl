<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>All Recent Notifications</title>
	<meta http-equiv="refresh" content="10"/>
</head>
<body>
	<div class="header">
		<h3>List of All Recent Notifications</h3>
	</div>

	<table border="0" class="notifications">
		<tr>
			<th>Host</th>
			<th>Comp</th>
			<th>Ctxt</th>
			<th>Type</th>
			<th>Time</th>
			<th>Status</th>
		</tr>
		<xsl:for-each select="Spur">
			<xsl:sort select="@time" order="descending" data-type="number"/>
			<xsl:call-template name="Spur"/>
		</xsl:for-each>
	</table>
</body>
</html>
</xsl:template>

<xsl:template name="Spur">
	<xsl:for-each select="Event">
		<xsl:sort select="@time" order="ascending" data-type="number"/>
		<tr class="spur">
			<xsl:choose>
				<xsl:when test="position() = 1">
					<td><a href="/get?host={../@host}"><xsl:value-of select="../@host"/></a></td>
					<td><a href="/get?component={../@component}"><xsl:value-of select="../@component"/></a></td>
					<td><a href="/get?ctxt={../@ctxt}"><xsl:value-of select="../@ctxt"/></a></td>
				</xsl:when>
				<xsl:otherwise>
					<td colspan="3"/>
				</xsl:otherwise>
			</xsl:choose>
			<td><xsl:value-of select="@type"/></td>
			<td><xsl:value-of select="@time"/></td>
			<td><xsl:value-of select="@status"/></td>
		</tr>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
