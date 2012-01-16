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
			<table class="hostMap">
				<tr>
					<th>Host / Component</th>
					<th>Calls</th>
					<th>Errors</th>
					<th>Timeouts</th>
				</tr>
				<xsl:for-each select="Hosts/Host">
					<xsl:sort select="@name" order="ascending"/>
					<xsl:call-template name="Host"/>
				</xsl:for-each>
			</table>
		</div>

		<div class="systemMap">
			<b>Interfaces</b>
			<br/>
			<br/>
			<table class="interfaceMap">
				<tr>
					<th>Interface / From</th>
					<th>Calls</th>
					<th>Errors</th>
					<th>Timeouts</th>
				</tr>
				<xsl:for-each select="Interfaces/Interface">
					<xsl:sort select="@from" order="ascending"/>
					<xsl:call-template name="Interface"/>
				</xsl:for-each>
			</table>
		</div>

		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

<xsl:template name="Host">
	<tr class="host">
		<td><a href="get?host={@name}"><xsl:value-of select="@name"/></a></td>
		<td class='calls'><a href="get?host={@name}&amp;status=started"><xsl:value-of select="@started"/></a></td>
		<td class='error'><a href="get?host={@name}&amp;status=error"><xsl:value-of select="@error"/></a></td>
		<td class='error'><a href="get?host={@name}&amp;status=timeout"><xsl:value-of select="@timeout"/></a></td>
	</tr>
	<xsl:variable name="host"><xsl:value-of select="@name"/></xsl:variable>
	<xsl:for-each select="/Spuren/ComponentInstances/Instance[@host = $host]">
		<xsl:sort select="@component" order="ascending"/>			
		<tr class="componentInstance">
			<td><a href="get?host={@host}&amp;component={@component}"><xsl:value-of select="@component"/></a></td>
			<td class='calls'><a href="get?host={@name}&amp;component={@component}&amp;status=started"><xsl:value-of select="@started"/></a></td>
			<td class='error'><a href="get?host={@name}&amp;component={@component}&amp;status=error"><xsl:value-of select="@error"/></a></td>
			<td class='error'><a href="get?host={@name}&amp;component={@component}&amp;status=timeout"><xsl:value-of select="@timeout"/></a></td>
		</tr>
	</xsl:for-each>
</xsl:template>

<xsl:template name="Interface">
	<tr class="interface">
		<td><xsl:value-of select="@from"/> -&gt; <xsl:value-of select="@to"/></td>
		<td class='calls'><xsl:value-of select="@started"/></td>
		<td class='error'><xsl:value-of select="@error"/></td>
		<td class='error'><xsl:value-of select="@timeout"/></td>

		<xsl:variable name="from"><xsl:value-of select="@from"/></xsl:variable>
		<xsl:variable name="to"><xsl:value-of select="@to"/></xsl:variable>
		<xsl:for-each select="/Spuren/InterfaceInstances/Instance[@component = $from and @newcomponent = $to]">
			<xsl:sort select="@host" order="ascending"/>			
			<tr class="interfaceInstance">
				<td><a href="get?host={@host}"><xsl:value-of select="@host"/></a> </td>
				<td class='calls'><xsl:value-of select="@started"/></td>
				<td class='error'><xsl:value-of select="@error"/></td>
				<td class='error'><xsl:value-of select="@timeout"/></td>
			</tr>
		</xsl:for-each>
	</tr>
</xsl:template>

</xsl:stylesheet>
