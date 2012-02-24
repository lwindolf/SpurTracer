<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>
<xsl:include href="Alarms.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>All Recent Events</title>
	<meta http-equiv="refresh" content="5"/>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"/>
	<script type="text/javascript" src="js/jquery.timeago.js"/>
	<script type="text/javascript" src="js/jquery.time.js"/>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Events'"/>
			<xsl:with-param name="filter" select="'1'"/>
		</xsl:call-template>

		<xsl:call-template name="Alarms"/>

		<div class="info">

			<p>Click on a context link to follow a spur/trace.</p>

			<p><a href="/getDetails">Show Details</a></p>
		</div>

		<div class="systemMap">
		<div class="header">List of Recent Notifications</div>
		<table border="0" class="notifications">
			<tr>
				<th>Host</th>
				<th>Component</th>
				<th>Time</th>
				<th colspan="2">Context</th>
			</tr>
			<xsl:for-each select="Spur">
				<xsl:sort select="@started" order="descending" data-type="number"/>
				<xsl:call-template name="Spur"/>
			</xsl:for-each>
		</table>
		</div>

		<xsl:call-template name="legend-spuren"/>

		<div class="clear"/>
	</div>

	<script type="text/javascript">
		jQuery(document).ready(function() {
		 	jQuery(".time").time();
		});
	</script>
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
		<td><b><a href="/getDetails?component={@component}"><xsl:value-of select="@component"/></a></b></td>
		<td class="time" title="{@started}"><xsl:value-of select="@started"/></td>
		<td colspan="2"><b><a href="/getSpur?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a></b></td>
	</xsl:element>

	<xsl:for-each select="Event">
		<xsl:sort select="@time" order="ascending" data-type="number"/>
		<xsl:choose>
			<xsl:when test="@type = 'n'">
				<xsl:if test="@status = 'failed'">
				<xsl:element name="tr">
					<xsl:attribute name="class">notification <xsl:if test="@status='failed'">error</xsl:if></xsl:attribute>
					<td/>
					<td/>
					<td class="time" title="{@time}"><xsl:value-of select="@time"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><xsl:value-of select="@desc"/></td>
				</xsl:element>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="@status != 'finished'">
				<xsl:element name="tr">
					<xsl:attribute name="class">announcement <xsl:if test="@status!='finished'">announced</xsl:if></xsl:attribute>
					<td/>
					<td/>
					<td class="time" title="{@time}"><xsl:value-of select="@time"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><a href="/getDetails?component={@newcomponent}"><xsl:value-of select="@newcomponent"/></a>, ctxt <a href="/getSpur?ctxt={@newctxt}"><xsl:value-of select="@newctxt"/></a></td>
				</xsl:element>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
