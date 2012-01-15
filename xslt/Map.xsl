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
			<span class="menuitem"><a href="getComponents">Components</a></span>
			<span class="menuitem"><a href="getAnnouncements">Announcements</a></span>
		</div>

		<div class="header">
			<h3>System Map</h3>
		</div>

		<div class="systemMap">
			<b>Hosts</b>
			<br/>
			<br/>
			<xsl:for-each select="Hosts/Host">
				<xsl:sort select="@name" order="ascending"/>
				<xsl:call-template name="Host"/>
			</xsl:for-each>
		</div>

		<div class="systemMap">
			<b>Interfaces</b>
			<br/>
			<br/>
			<xsl:for-each select="Interfaces/Interface">
				<xsl:sort select="@from" order="ascending"/>
				<xsl:call-template name="Interface"/>
			</xsl:for-each>
		</div>

		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

<xsl:template name="Host">
	<div class="host">
		Running on <a href="get?host={@name}"><xsl:value-of select="@name"/></a>
		(
			<xsl:value-of select="@started"/> calls
			<xsl:value-of select="@error"/> errors
			<xsl:value-of select="@timeout"/> timeouts
		)

		<xsl:variable name="host"><xsl:value-of select="@name"/></xsl:variable>
		<xsl:for-each select="/Spuren/ComponentInstances/Instance[@host = $host]">
			<xsl:sort select="@component" order="ascending"/>			
			<div class="componentInstance">
				<xsl:value-of select="@component"/> 
				(
					<xsl:value-of select="@started"/> calls
					<xsl:value-of select="@error"/> errors
					<xsl:value-of select="@timeout"/> timeouts
				)
			</div>
		</xsl:for-each>
	</div>
</xsl:template>

<xsl:template name="Interface">
	<div class="interface">
		<xsl:value-of select="@from"/> -&gt; <xsl:value-of select="@to"/> 
		(
			<xsl:value-of select="@started"/> calls
			<xsl:value-of select="@error"/> errors
			<xsl:value-of select="@timeout"/> timeouts
		)

		<xsl:variable name="from"><xsl:value-of select="@from"/></xsl:variable>
		<xsl:variable name="to"><xsl:value-of select="@to"/></xsl:variable>
		<xsl:for-each select="/Spuren/InterfaceInstances/Instance[@component = $from and @newcomponent = $to]">
			<xsl:sort select="@host" order="ascending"/>			
			<div class="componentInstance">
				Called from <a href="get?host={@host}"><xsl:value-of select="@host"/></a> 
				(
					<xsl:value-of select="@started"/> calls
					<xsl:value-of select="@error"/> errors
					<xsl:value-of select="@timeout"/> timeouts
				)
			</div>
		</xsl:for-each>
	</div>
</xsl:template>

</xsl:stylesheet>
