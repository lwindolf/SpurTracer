<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="Alarms">
	<xsl:if test="count(Alarms/Alarm) > 0">
		<div class="systemMap">
		<div class="header">Current Alarms</div>
		<table class="alarms" cellspacing="2" cellpadding="0">
			<tr>
				<th>Type</th>
				<th>Name</th>
				<th>Severity</th>
				<th>Last Check</th>
				<th>Duration</th>
				<th>Status Information</th>
			</tr>
			<xsl:for-each select="Alarms/Alarm">
				<xsl:sort select="@severity"/>
				<xsl:element name="tr">
					<xsl:attribute name="class">
						<xsl:value-of select="@severity"/>
					</xsl:attribute>
				<td class="type"><xsl:value-of select="@type"/></td>
				<td class="name">
					<a href="get?{@type}={@name}&amp;status=failed"><xsl:value-of select="@name"/></a>
				</td>
				<td class="severity"><xsl:value-of select="@severity"/></td>
				<td class="lastchecked timeago" title="{@time * 1000}"><xsl:value-of select="@time * 1000"/></td>
				<td class="lastchecked since" title="{@since * 1000}"><xsl:value-of select="@since * 1000"/></td>
				<td class="message"><xsl:value-of select="@message"/></td>
				</xsl:element>
			</xsl:for-each>
		</table>
		</div>

		<div class="clear"/>
	</xsl:if>

	<!-- Unconditionally set timeago handler as it might be reused in other displays -->
	<script type="text/javascript">
		jQuery(document).ready(function() {
		 	jQuery(".timeago").timeago();

			jQuery.timeago.settings.strings.suffixAgo = null;

			jQuery(".since").timeago();
		});
	</script>
</xsl:template>

</xsl:stylesheet>
