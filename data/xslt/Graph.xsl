<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="Graph">
	<div class="systemMap">
		<div class="header">Last <xsl:value-of select="@interval"/>: <xsl:value-of select="@name"/></div>

	<table class="graph" id="graph{position()}">
		<thead>
			<tr>
				<xsl:for-each select="Counter[@name = 'started']/Value">
					<th><xsl:value-of select="@slot"/></th>
				</xsl:for-each>
			</tr>
		</thead>
		<tbody>
			<tr>
				<th scope='row'>started/min</th>
				<xsl:for-each select="Counter[@name = 'started']/Value">
					<td><xsl:value-of select="@value"/></td>
				</xsl:for-each>
			</tr>
			<tr>
				<th scope='row'>failed/min</th>
				<xsl:for-each select="Counter[@name = 'failed']/Value">
					<td><xsl:value-of select="@value"/></td>
				</xsl:for-each>
			</tr>
			<tr>
				<th scope='row'>announces/min</th>
				<xsl:for-each select="Counter[@name = 'announced']/Value">
					<td><xsl:value-of select="@value"/></td>
				</xsl:for-each>
			</tr>
			<tr>
				<th scope='row'>timeouts/min</th>
				<xsl:for-each select="Counter[@name = 'timeout']/Value">
					<td><xsl:value-of select="@value"/></td>
				</xsl:for-each>
			</tr>
		</tbody>
	</table>

	<script type="text/javascript">
		$(function(){
			var id = "#graph<xsl:value-of select="position()"/>";
			$(id).visualize({type: 'line', width: '420px', height: '200px', lineWeight: '1', colors: ['#0F0', '#F00', '#CC0', '#00F']});
			$(id).addClass('accessHide');
		});
	</script>
	</div>
</xsl:template>

</xsl:stylesheet>
