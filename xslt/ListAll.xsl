<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
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
		</tr>
		<xsl:apply-templates/>
	</table>
</body>
</html>
</xsl:template>

<xsl:template match="Notification">
	<tr class="notification">
		<td><a href="/get?host={@host}"><xsl:value-of select="@host"/></a></td>
		<td><a href="/get?component={@component}"><xsl:value-of select="@component"/></a></td>
		<td><a href="/get?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a></td>
		<td><xsl:value-of select="@type"/></td>
		<td><xsl:value-of select="@time"/></td>
	</tr>
</xsl:template>

</xsl:stylesheet>
