<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>

<xsl:template match="/Spuren">
<html>
<head>
	<title>Spur Tracer - Spur</title>
	<xsl:if test="count(//Spur) != count(//Spur/Event[@status = 'finished' and @type = 'n'])">
		<!-- Only refresh if one Spur isn't finished -->
		<meta http-equiv="refresh" content="5"/>
	</xsl:if>

	<link rel="stylesheet" type="text/css" href="css/style.css"/>

	<script type="text/javascript" src="js/jquery-2.1.1.min.js"></script>
	<script type="text/javascript" src="js/jquery.time.js"></script>
	<script type="text/javascript" src="js/d3.v3.js"></script>
	<script type="text/javascript" src="js/cola.v3.min.js"></script>
	<script type="text/javascript" src="js/spuren_view.js"></script>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>
	<div class="content">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Recent'"/>
			<xsl:with-param name="filter" select="'1'"/>
		</xsl:call-template>



		<div class="info">

			<div class="map" width="400px" height="200px">
			</div>

			<xsl:call-template name="legend-spuren"/>
		</div>

		<div class="systemMap">
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
		</div>

		<div class="clear"/>
	</div>

	<script type="text/javascript">
		var view = new SptSpurenView('.map');
		var reloadTimeout;

		function reloadTimer() {
			view.reload();

			clearTimeout(reloadTimeout);
			reloadTimeout = setTimeout("reloadTimer();", 5000);  // FIXME: hard-coded timeout
		}

		jQuery(document).ready(function() {
		 	jQuery(".time").time();

			//reloadTimer();
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
				<xsl:when test="Event[@status = 'timeout']">timeout</xsl:when> 
				<xsl:when test="Event[@status = 'running']">running</xsl:when>
			</xsl:choose>
		</xsl:attribute>
		<td><a href="/getDetails?host={@host}"><xsl:value-of select="@host"/></a></td>
		<td colspan="3">
			<b><a href="/getDetails?component={@component}"><xsl:value-of select="@component"/></a></b>, ctxt
			<b><a href="/getSpur?ctxt={@ctxt}"><xsl:value-of select="@ctxt"/></a></b>
		</td>
	</xsl:element>

	<xsl:for-each select="Event">
		<xsl:sort select="@time" order="ascending" data-type="number"/>
		<xsl:choose>
			<xsl:when test="@type = 'n'">
				<xsl:element name="tr">
					<xsl:attribute name="class">notification 
						<xsl:if test="@status='failed'">error</xsl:if>
						<xsl:if test="@status='timeout'">timeout</xsl:if>
					</xsl:attribute>
					<td/>
					<td class="time" title="{@time}"><xsl:value-of select="@time"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><xsl:value-of select="@desc"/></td>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="tr">
					<xsl:attribute name="class">announcement <xsl:if test="@status!='finished'">announced</xsl:if></xsl:attribute>

					<td/>
					<td class="time" title="{@time}"><xsl:value-of select="@time"/></td>
					<td><xsl:value-of select="@status"/></td>
					<td><a href="/getDetails?component={@newcomponent}"><xsl:value-of select="@newcomponent"/></a>, ctxt <a href="/getSpur?ctxt={@newctxt}"><xsl:value-of select="@newctxt"/></a></td>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
