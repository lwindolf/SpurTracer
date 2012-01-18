<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="Menu">
	<xsl:param name="active"/>

	<div class="menu">
		<span id="Map"		class="menuitem"><a href="getMap">System Map</a></span>
		<span id="Events"	class="menuitem"><a href="get">Recent Events</a></span>
		<span id="Components"	class="menuitem"><a href="getComponents">Components</a></span>
		<span id="Announcements" class="menuitem"><a href="getAnnouncements">Announcements</a></span>
		<span id="Settings"	class="menuitem"><a href="getSettings">Settings</a></span>
	</div>

	<script type="text/javascript">
		$('#<xsl:value-of select="$active"/>').addClass('activemenu');
	</script>
</xsl:template>

</xsl:stylesheet>
