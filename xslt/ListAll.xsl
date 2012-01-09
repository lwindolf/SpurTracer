<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>All Recent Notifications</title>
	<meta http-equiv="refresh" content="10"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
</head>
<body>
	<div class="header">
		<h3>List of All Recent Notifications</h3>
	</div>

	<p><a href="/getDetails">Show Details</a></p>

	<table border="0" class="notifications">
		<tr>
			<th>Source</th>
			<th>Time</th>
			<th>Status</th>
			<th>Description</th>
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
	<xsl:element name="tr">
		<xsl:attribute name="class">
			source
			<xsl:choose>
				<xsl:when test="Event[@status = 'failed']">error</xsl:when>
				<xsl:when test="Event[@status = 'finished']">finished</xsl:when> 
			</xsl:choose>
		</xsl:attribute>
		<td><a href="/getDetails?host={@host}"><xsl:value-of select="@host"/></a></td>
		<td colspan="100">
			<a href="/getDetails?component={@component}"><xsl:value-of select="@component"/></a>, ctxt
			<a href="/getDetails?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a>
		</td>
	</xsl:element>

	<xsl:for-each select="Event">
		<xsl:sort select="@time" order="ascending" data-type="number"/>
		<xsl:choose>
			<xsl:when test="@type = 'n'">
				<xsl:if test="@status = 'failed'">
				<xsl:element name="tr">
					<xsl:attribute name="class">notification <xsl:if test="@status='failed'">error</xsl:if></xsl:attribute>
					<td/>
					<td><xsl:value-of select="@date"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><xsl:value-of select="@desc"/></td>
				</xsl:element>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="@status != 'finished'">
				<tr class="announcement">
					<td/>
					<td><xsl:value-of select="@date"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td>Component <a href="/getDetails?component={@newcomponent}"><xsl:value-of select="@newcomponent"/></a> Context <a href="/getDetails?ctxt={@newctxt}"><xsl:value-of select="@newctxt"/></a></td>
				</tr>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
