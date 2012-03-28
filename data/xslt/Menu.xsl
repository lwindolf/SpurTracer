<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="Menu">
	<xsl:param name="active"/>
	<xsl:param name="filter"/>
	<xsl:param name="nointerval"/>

	<div class="menu">
		<span id="Map"		class="menuitem"><a href="getMap">System Map</a></span>
		<span id="Events"	class="menuitem"><a href="get">Recent Events</a></span>
		<span id="Spuren"	class="menuitem"><a href="getSpuren">Spuren</a></span>
		<span id="Announcements" class="menuitem"><a href="getAnnouncements">Announcements</a></span>
		<span id="Settings"	class="menuitem"><a href="getSettings">Settings</a></span>
	</div>

	<script type="text/javascript">
		$('#<xsl:value-of select="$active"/>').addClass('activemenu');
	</script>

	<xsl:if test="$filter = 1">
	<div class="filter">
		<form action="" method="GET">
		<xsl:if test="$nointerval != 1">
		Interval 
		<select id="interval" name="interval" onChange="this.form.submit()">
			<xsl:for-each select="Intervals/Interval/@name">
				<xsl:element name="option">
					<xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
					<xsl:if test=". = /Spuren/@interval"><xsl:attribute name="selected"/></xsl:if>
					Last <xsl:value-of select="."/>
				</xsl:element>
			</xsl:for-each>
		</select>
		</xsl:if>

		<xsl:if test="count(Filter/Attribute[@type != 'type']) > 0">
			Filter:
		</xsl:if>

		<xsl:for-each select="Filter/Attribute">
			<xsl:sort select='@type'/>
			<xsl:choose>
				<xsl:when test="@type = 'type'">
					<input type="hidden" name="{@type}" value="{@value}"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@type"/> 
					<input type="text" size="15" name="{@type}" value="{@value}"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		</form>
	</div>
	</xsl:if>
</xsl:template>

<xsl:template name="legend-spuren">
	<div class="legend systemMap">
		<div class="header">Legend</div>
		<table>
			<tr><td class='started'>started</td></tr>
			<tr><td class='running'>running</td></tr>
			<tr><td class='error'>error</td></tr>
			<tr><td class='timeout'>timeout</td></tr>
			<tr><td class='announced'>announced</td></tr>
			<tr><td class='finished'>finished</td></tr>
		</table>
	</div>
</xsl:template>

</xsl:stylesheet>
