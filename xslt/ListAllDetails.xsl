<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>
<xsl:include href="Alarms.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>All Recent Events</title>
	<meta http-equiv="refresh" content="5"/>
	<link rel="stylesheet" type="text/css" href="css/visualize.css"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"/>
	<script type="text/javascript" src="js/visualize.jQuery.js"/>	
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Events'"/>
		</xsl:call-template>

		<xsl:call-template name="Alarms"/>

		<div class="info">
			<div class="header">
				<h3>List of Recent Notifications</h3>
			</div>

			<p>Click on a context link to follow a spur/trace.</p>

			<p><a href="/get">Hide Details</a></p>
		</div>

		<table border="0" class="notifications">
			<tr>
				<th>Host</th>
				<th>Time</th>
				<th>Status</th>
				<th>Description</th>
			</tr>
			<xsl:for-each select="Spur">
				<xsl:sort select="@started" order="descending" data-type="number"/>
				<xsl:call-template name="Spur"/>
			</xsl:for-each>
		</table>

		<xsl:for-each select="IntervalStatistics/Interval">
			<xsl:call-template name="Interval"/>
		</xsl:for-each>

		<div class="legend">
			<table>
				<tr><th>Legend</th></tr>
				<tr><td class='started'>started</td></tr>
				<tr><td class='running'>running</td></tr>
				<tr><td class='error'>error</td></tr>
				<tr><td class='announced'>announced</td></tr>
				<tr><td class='finished'>finished</td></tr>
			</table>
		</div>

		<div class="clear"/>
	</div>
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
				<xsl:when test="Event[@status = 'running']">running</xsl:when>
			</xsl:choose>
		</xsl:attribute>
		<td><a href="/getDetails?host={@host}"><xsl:value-of select="@host"/></a></td>
		<td colspan="100">
			<b><a href="/getDetails?component={@component}"><xsl:value-of select="@component"/></a></b>, ctxt
			<b><a href="/getSpur?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a></b>
		</td>
	</xsl:element>

	<xsl:for-each select="Event">
		<xsl:sort select="@time" order="ascending" data-type="number"/>
		<xsl:choose>
			<xsl:when test="@type = 'n'">
				<xsl:element name="tr">
					<xsl:attribute name="class">notification <xsl:if test="@status='failed'">error</xsl:if></xsl:attribute>
					<td/>
					<td><xsl:value-of select="@date"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><xsl:value-of select="@desc"/></td>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="tr">
					<xsl:attribute name="class">announcement <xsl:if test="@status!='finished'">announced</xsl:if></xsl:attribute>

					<td/>
					<td><xsl:value-of select="@date"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><a href="/getDetails?component={@newcomponent}"><xsl:value-of select="@newcomponent"/></a>, ctxt <a href="/getSpur?ctxt={@newctxt}"><xsl:value-of select="@newctxt"/></a></td>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
</xsl:template>

<xsl:template name="Interval">
	<xsl:for-each select="Object">
		<xsl:call-template name="Graph"/>
	</xsl:for-each>
</xsl:template>

<xsl:template name="Graph">
	<table class="graph" id="graph{@type}{../@name}">
		<caption>Last <xsl:value-of select="../@name"/></caption>
		<thead>
			<tr>
				<td></td>
				<xsl:for-each select="Value">
					<th scope='col'><xsl:value-of select="@slot"/></th>
				</xsl:for-each>
			</tr>
		</thead>
		<tbody>
			<tr>
			<th scope='row'>calls/min</th>
			<xsl:for-each select="Value">
				<td><xsl:value-of select="@value"/></td>
			</xsl:for-each>
			</tr>
		</tbody>
	</table>

	<script type="text/javascript">
		$(function(){
			var id = "#graph<xsl:value-of select="@type"/><xsl:value-of select="../@name"/>";
			$(id).visualize({type: 'line', width: '420px', height: '200px', lineWeight: '2', colors: ['#0F0', 'F77']});
			$(id).addClass('accessHide');
		});
	</script>
				
</xsl:template>

</xsl:stylesheet>
