<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>
<xsl:include href="Alarms.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>All Recent Announcements</title>
	<meta http-equiv="refresh" content="10"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"/>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Announcements'"/>
		</xsl:call-template>

		<xsl:call-template name="Alarms"/>

		<div class="header">
			<h3>List of All Recent Announcements</h3>
		</div>

		<p>Each announcement does indicate an interface that was triggered by one
		component, while not yet being processed by the component implementation
		the interface.</p>
		<p> Overdue announcements will time out according to the 
		<a href="getSettings#timeouts">timeout settings</a>.</p>

		<table border="0" class="notifications">
			<tr>
				<th>Time</th>
				<th colspan="2">From</th>
				<th>To</th>
				<th>Source Context</th>
				<th>New Context</th>
				<th>Since</th>
			</tr>
			<xsl:for-each select="Announcements/Announcement">
				<xsl:sort select="@time" order="descending" data-type="number"/>
				<xsl:call-template name="Announcement"/>
			</xsl:for-each>
		</table>

		<div class="legend">
			<table>
				<tr><th>Legend</th></tr>
				<tr><td class='announced'>announced</td></tr>
				<tr><td class='error'>timeout</td></tr>
			</table>
		</div>


		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

<xsl:template name="Announcement">
	<xsl:element name="tr">
		<xsl:attribute name="class">announcement
			<xsl:if test="@timeout = 0">announced</xsl:if>
			<xsl:if test="@timeout = 1">error</xsl:if>
		</xsl:attribute>
		<td><xsl:value-of select="@date"/></td>
		<td><a href="/getDetails?host={@sourceHost}"><xsl:value-of select="@sourceHost"/></a></td>
		<td><a href="/getDetails?component={@sourceComponent}"><xsl:value-of select="@sourceComponent"/></a></td>
		<td><a href="/getDetails?component={@component}"><xsl:value-of select="@component"/></a></td>
		<td><a href="/getSpur?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a></td>
		<td><a href="/getSpur?ctxt={@sourceCtxt}"><xsl:value-of select="@sourceCtxt"/></a></td>
		<td><xsl:value-of select="/Spuren/@now - @time"/>s</td>
	</xsl:element>
</xsl:template>

</xsl:stylesheet>
