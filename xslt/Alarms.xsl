<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="Alarms">
	<xsl:if test="count(Alarms/Alarm) > 0">
		<div class="systemMap">
		<div class="header">Current Alarms</div>
		<table class="alarms" cellspacing="2" cellpadding="0">
			<xsl:for-each select="Alarms/Alarm">
				<xsl:sort select="@severity"/>
				<xsl:element name="tr">
					<xsl:attribute name="class">
						<xsl:value-of select="@severity"/>
					</xsl:attribute>
				<td class="type"><xsl:value-of select="@type"/></td>
				<td class="name"><xsl:value-of select="@name"/></td>
				<td class="severity"><xsl:value-of select="@severity"/></td>
				<td class="message"><xsl:value-of select="@message"/></td>
				</xsl:element>
			</xsl:for-each>
		</table>
		</div>

		<div class="clear"/>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
