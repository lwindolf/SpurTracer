<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="Menu">
	<xsl:param name="active"/>
	<xsl:param name="filter"/>

	<div class="menu">
		<span id="Map"		class="menuitem"><a href="getMap">System Map</a></span>
		<span id="Events"	class="menuitem"><a href="get">Recent Events</a></span>
		<span id="Announcements" class="menuitem"><a href="getAnnouncements">Announcements</a></span>
		<span id="Settings"	class="menuitem"><a href="getSettings">Settings</a></span>
	</div>

	<script type="text/javascript">
		$('#<xsl:value-of select="$active"/>').addClass('activemenu');
	</script>

	<xsl:if test="$filter = 1">
	<div class="filter">
		Interval 
		<select id="interval" name="interval">
			<xsl:for-each select="Intervals/Interval/@name">
				<xsl:element name="option">
					<xsl:attribute name="value"><xsl:value-of select="."/></xsl:attribute>
					<xsl:if test=". = /Spuren/@interval"><xsl:attribute name="selected"/></xsl:if>
					Last <xsl:value-of select="."/>
				</xsl:element>
			</xsl:for-each>
		</select>

		<xsl:if test="count(Filter/Attribute) > 0">
			Filter:
			<xsl:for-each select="Filter/Attribute">
				<xsl:value-of select="@type"/> 
				<input type="text" size="15" value="{@value}"/>
			</xsl:for-each>
		</xsl:if>
	</div>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
