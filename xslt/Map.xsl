<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/Spuren">
<html>
<head>
	<title>System Map</title>
	<meta http-equiv="refresh" content="5"/>
	<link rel="stylesheet" type="text/css" href="css/visualize.css"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"/>
	<script type="text/javascript" src="js/visualize.jQuery.js"/>	
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
					<th>Timeouts</th>
				</tr>
				<xsl:for-each select="Interfaces/Interface">
					<xsl:sort select="@from" order="ascending"/>
					<xsl:call-template name="Interface"/>
				</xsl:for-each>
			</table>
		</div>

		<xsl:for-each select="IntervalStatistics/Interval">
			<xsl:call-template name="Interval"/>
		</xsl:for-each>

		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

<xsl:template name="Host">
	<tr class="host">
		<td><a href="get?host={@name}"><xsl:value-of select="@name"/></a></td>
		<td class='calls'><a href="get?host={@name}&amp;status=started"><xsl:value-of select="@started"/></a></td>
		<td class='error'><a href="get?host={@name}&amp;status=failed"><xsl:value-of select="@failed"/></a></td>
		<td class='error'><a href="get?host={@name}&amp;status=timeout"><xsl:value-of select="@timeout"/></a></td>
	</tr>
	<xsl:variable name="host"><xsl:value-of select="@name"/></xsl:variable>
	<xsl:for-each select="/Spuren/ComponentInstances/Instance[@host = $host]">
		<xsl:sort select="@component" order="ascending"/>			
		<tr class="componentInstance">
			<td><a href="get?host={@host}&amp;component={@component}"><xsl:value-of select="@component"/></a></td>
			<td class='calls'><a href="get?host={@host}&amp;component={@component}&amp;status=started"><xsl:value-of select="@started"/></a></td>
			<td class='error'><a href="get?host={@host}&amp;component={@component}&amp;status=failed"><xsl:value-of select="@failed"/></a></td>
			<td class='error'><a href="get?host={@host}&amp;component={@component}&amp;status=timeout"><xsl:value-of select="@timeout"/></a></td>
		</tr>
	</xsl:for-each>
</xsl:template>

<xsl:template name="Interface">
	<tr class="interface">
		<td><xsl:value-of select="@from"/> -&gt; <xsl:value-of select="@to"/></td>
		<td class='calls'><xsl:value-of select="@started"/></td>
		<td class='error'><xsl:value-of select="@timeout"/></td>
	</tr>
	<xsl:variable name="from"><xsl:value-of select="@from"/></xsl:variable>
	<xsl:variable name="to"><xsl:value-of select="@to"/></xsl:variable>
	<xsl:for-each select="/Spuren/InterfaceInstances/Instance[@component = $from and @newcomponent = $to]">
		<xsl:sort select="@host" order="ascending"/>			
		<tr class="interfaceInstance">
			<td><a href="get?host={@host}"><xsl:value-of select="@host"/></a></td>
			<td class='calls'><xsl:value-of select="@started"/></td>
			<td class='error'><xsl:value-of select="@timeout"/></td>
		</tr>
	</xsl:for-each>
</xsl:template>

<xsl:template name="Interval">
	<div class="systemMap">
		<b>Last <xsl:value-of select="@name"/></b>
		<br/>
		<br/>

	<table class="graph" id="graph{@name}">
		<thead>

			<xsl:for-each select="Object[@type = 'started']/Value">
				<th scope='col'><xsl:value-of select="@slot"/></th>
			</xsl:for-each>
		</thead>
		<tbody>
			<tr>
				<th scope='row'>started/min</th>
				<xsl:for-each select="Object[@type = 'started']/Value">
					<td><xsl:value-of select="@value"/></td>
				</xsl:for-each>
			</tr>
			<tr>
				<th scope='row'>failed/min</th>
				<xsl:for-each select="Object[@type = 'failed']/Value">
					<td><xsl:value-of select="@value"/></td>
				</xsl:for-each>
			</tr>
			<tr>
				<th scope='row'>announces/min</th>
				<xsl:for-each select="Object[@type = 'announced']/Value">
					<td><xsl:value-of select="@value"/></td>
				</xsl:for-each>
			</tr>
		</tbody>
	</table>

	<script type="text/javascript">
		$(function(){
			var id = "#graph<xsl:value-of select="@name"/>";
			$(id).visualize({type: 'line', width: '420px', height: '200px', lineWeight: '2', colors: ['#0F0', '#F00', '#CC0']});
			$(id).addClass('accessHide');
		});
	</script>
	</div>
</xsl:template>

</xsl:stylesheet>
