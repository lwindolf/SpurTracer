<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>
<xsl:include href="Alarms.xsl"/>
<xsl:include href="Graph.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>SpurTracer - System Map</title>
	<meta http-equiv="refresh" content="5"/>
	<link rel="stylesheet" type="text/css" href="css/visualize.css"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"/>
	<script type="text/javascript" src="js/visualize.jQuery.js"/>	
	<script type="text/javascript" src="js/jquery.timeago.js"/>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Map'"/>
			<xsl:with-param name="filter" select="'1'"/>
		</xsl:call-template>

		<xsl:call-template name="Alarms"/>

		<xsl:apply-templates select="Hosts"/>
		<xsl:apply-templates select="Components"/>
		<xsl:apply-templates select="Interfaces"/>

		<xsl:for-each select="Statistics/Object">
			<xsl:call-template name="Graph"/>
		</xsl:for-each>

		<div class="clear"/>

		<script type="text/javascript">
			$('td').filter(function() {
				return $(this).text() == '0';
			}).addClass('zero');
		</script>
	</div>
</body>
</html>
</xsl:template>

<!-- print a cell with call error or not depending on wether the value is > 0 -->
<xsl:template name="ErrorCell">
	<xsl:param name="url"/>
	<xsl:param name="value"/>

	<xsl:element name="td">
		<xsl:if test="$value > 0"><xsl:attribute name="class">error</xsl:attribute></xsl:if>
		<a href="{$url}"><xsl:value-of select="$value"/></a>
	</xsl:element>	
</xsl:template>

<!-- print a cell with call timeout or not depending on wether the value is > 0 -->
<xsl:template name="TimeoutCell">
	<xsl:param name="url"/>
	<xsl:param name="value"/>

	<xsl:element name="td">
		<xsl:if test="$value > 0"><xsl:attribute name="class">timeout</xsl:attribute></xsl:if>
		<a href="{$url}"><xsl:value-of select="$value"/></a>
	</xsl:element>	
</xsl:template>

<xsl:template match="Hosts">
	<div class="systemMap">
		<div class="header"><a href="?type=host">Hosts</a></div>
		<table class="hostMap">
			<tr>
				<th>Host / Component</th>
				<th>Calls</th>
				<th>Pending</th>
				<th>Errors</th>
				<th>Timeouts</th>
			</tr>
			<xsl:for-each select="Host">
				<xsl:sort select="@name" order="ascending"/>
				<xsl:call-template name="Host"/>
			</xsl:for-each>
		</table>
	</div>
</xsl:template>

<xsl:template name="Host">
	<tr class="host">
		<xsl:element name="td">
			<xsl:variable name="host"><xsl:value-of select="@name"/></xsl:variable>
			<xsl:attribute name="class">
				<xsl:value-of select="//Alarms/Alarm[@type='host' and @name=$host]/@severity"/>
			</xsl:attribute>
			<a href="get?host={@name}"><xsl:value-of select="$host"/></a>
		</xsl:element>
		<td class='calls'><a href="get?host={@name}&amp;status=started"><xsl:value-of select="@started"/></a></td>
		<td><xsl:value-of select="@announced"/></td>
		<xsl:call-template name="ErrorCell">
			<xsl:with-param name="url">get?host=<xsl:value-of select="@name"/>&amp;status=failed</xsl:with-param>
			<xsl:with-param name="value" select="@failed"/>
		</xsl:call-template>
		<xsl:call-template name="TimeoutCell">
			<xsl:with-param name="url">get?host=<xsl:value-of select="@name"/>&amp;status=timeout</xsl:with-param>
			<xsl:with-param name="value" select="@timeout"/>
		</xsl:call-template>
	</tr>
	<xsl:variable name="host"><xsl:value-of select="@name"/></xsl:variable>
	<xsl:for-each select="/Spuren/ComponentInstances/Instance[@host = $host]">
		<xsl:sort select="@component" order="ascending"/>			
		<tr class="componentInstance">
			<td><a href="get?host={@host}&amp;component={@component}"><xsl:value-of select="@component"/></a></td>
			<td class='calls'><a href="get?host={@host}&amp;component={@component}&amp;status=started"><xsl:value-of select="@started"/></a></td>
			<td><xsl:value-of select="@announced"/></td>
			<xsl:call-template name="ErrorCell">
				<xsl:with-param name="url">get?host=<xsl:value-of select="@host"/>&amp;component=<xsl:value-of select="@component"/>&amp;status=failed</xsl:with-param>
				<xsl:with-param name="value" select="@failed"/>
			</xsl:call-template>
			<xsl:call-template name="TimeoutCell">
				<xsl:with-param name="url">get?host=<xsl:value-of select="@name"/>&amp;component=<xsl:value-of select="@component"/>&amp;status=timeout</xsl:with-param>
				<xsl:with-param name="value" select="@timeout"/>
			</xsl:call-template>
		</tr>
	</xsl:for-each>
</xsl:template>

<xsl:template match="Components">
	<div class="systemMap">
		<div class="header"><a href="?type=component">Components</a></div>
		<table class="componentMap">
			<tr>
				<th>Component / From</th>
				<th>Calls</th>
				<th>Pending</th>
				<th>Errors</th>
				<th>Timeouts</th>
			</tr>
			<xsl:for-each select="Component">
				<xsl:sort select="@name" order="ascending"/>
				<xsl:call-template name="Component"/>
			</xsl:for-each>
		</table>
	</div>
</xsl:template>

<xsl:template name="Component">
	<tr class="component">
		<xsl:element name="td">
			<xsl:variable name="component"><xsl:value-of select="@name"/></xsl:variable>
			<xsl:attribute name="class">
				<xsl:value-of select="//Alarms/Alarm[@type='component' and @name=$component]/@severity"/>
			</xsl:attribute>
			<a href="get?component={@name}"><xsl:value-of select="$component"/></a>
		</xsl:element>
		<td class='calls'><xsl:value-of select="@started"/></td>
		<td><xsl:value-of select="@announced"/></td>
		<xsl:call-template name="ErrorCell">
			<xsl:with-param name="url">get?host=<xsl:value-of select="@name"/>&amp;status=failed</xsl:with-param>
			<xsl:with-param name="value" select="@failed"/>
		</xsl:call-template>
		<xsl:call-template name="TimeoutCell">
			<xsl:with-param name="value" select="@timeout"/>
		</xsl:call-template>
	</tr>
	<xsl:variable name="name"><xsl:value-of select="@name"/></xsl:variable>
	<xsl:for-each select="/Spuren/ComponentInstances/Instance[@component = $name]">
		<xsl:sort select="@host" order="ascending"/>			
		<tr class="componentInstance">
			<td><a href="get?host={@host}"><xsl:value-of select="@host"/></a></td>
			<td class='calls'><xsl:value-of select="@started"/></td>
			<td><xsl:value-of select="@announced"/></td>
			<xsl:call-template name="ErrorCell">
				<xsl:with-param name="url">get?host=<xsl:value-of select="@host"/>&amp;component=<xsl:value-of select="@component"/>&amp;status=failed</xsl:with-param>
				<xsl:with-param name="value" select="@failed"/>
			</xsl:call-template>
			<xsl:call-template name="TimeoutCell">
				<xsl:with-param name="url">get?host=<xsl:value-of select="@host"/>&amp;status=timeout</xsl:with-param>
				<xsl:with-param name="value" select="@timeout"/>
			</xsl:call-template>
		</tr>
	</xsl:for-each>
</xsl:template>

<xsl:template match="Interfaces">
	<div class="systemMap">
		<div class="header"><a href="?type=interface">Interfaces</a></div>
		<table class="interfaceMap">
			<tr>
				<th>Interface / From</th>
				<th>Calls</th>
				<th>Pending</th>
				<th>Timeouts</th>
			</tr>
			<xsl:for-each select="Interface">
				<xsl:sort select="@from" order="ascending"/>
				<xsl:call-template name="Interface"/>
			</xsl:for-each>
		</table>
	</div>
</xsl:template>

<xsl:template name="Interface">
	<tr class="interface">
		<td><xsl:value-of select="@from"/> -&gt; <xsl:value-of select="@to"/></td>
		<td class='calls'><xsl:value-of select="@started"/></td>
		<td><xsl:value-of select="@announced"/></td>
		<xsl:call-template name="TimeoutCell">
			<xsl:with-param name="value" select="@timeout"/>
		</xsl:call-template>
	</tr>
	<xsl:variable name="from"><xsl:value-of select="@from"/></xsl:variable>
	<xsl:variable name="to"><xsl:value-of select="@to"/></xsl:variable>
	<xsl:for-each select="/Spuren/InterfaceInstances/Instance[@component = $from and @newcomponent = $to]">
		<xsl:sort select="@host" order="ascending"/>			
		<tr class="interfaceInstance">
			<td><a href="get?host={@host}"><xsl:value-of select="@host"/></a></td>
			<td class='calls'><xsl:value-of select="@started"/></td>
			<td><xsl:value-of select="@announced"/></td>
			<xsl:call-template name="TimeoutCell">
				<xsl:with-param name="url">get?host=<xsl:value-of select="@host"/>&amp;status=timeout</xsl:with-param>
				<xsl:with-param name="value" select="@timeout"/>
			</xsl:call-template>
		</tr>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
