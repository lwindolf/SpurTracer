<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>

<xsl:template match="/">
<html>
<head>
	<title>Settings</title>
	<link rel="stylesheet" type="text/css" href="css/style.css"/>
	<script type="text/javascript" src="js/jquery-1.4.2.min.js"/>
</head>
<body>
	<span class="title"><a href="http://spurtracer.sf.net"><b>Spur</b>Tracer</a></span>

	<div class="content config">
		<xsl:call-template name="Menu">
			<xsl:with-param name="active" select="'Settings'"/>
		</xsl:call-template>

		<h3>Nagios Connection</h3>

		<p>
			You can configure SpurTracer to send Nagios alerts based 
			on the definitions below. For this to work you need the
			Nagios <a href="http://nagios.sourceforge.net/docs/3_0/addons.html">NSCA addon</a> installed.
		</p>

		<h4>Nagios Server</h4>

		<form method="POST" action="setOption">
			<table>
				<tr><td>Nagios (NSCA) Host</td><td><input type="input" name="nagios.NSCAHost"/></td></tr>
				<tr><td>Nagios (NSCA) Port</td><td><input type="input" name="nagios.NSCAPort" size="5"/></td></tr>	
			</table>
			<input type="submit" value="Save"/>
		</form>

		<h4>Configured Checks</h4>

		<xsl:if test="count(NagiosChecks/Check) = 0">
			<p>You have not defined any checks yet! Add one using the form below...</p>
		</xsl:if>

		<table class="checks">
		</table>

		<form method="POST" action="addNagiosCheck">
			<table>
				<tr><td>Object</td>
				<td>
					<select name="check.object">
					</select>
				</td></tr>
				<tr><td>Check Type</td><td>Error Rate</td></tr>
				<tr><td>Check Interval</td><td><input type="input" name="check.interval"/></td></tr>
				<tr><td>Critical Threshold</td><td><input type="input" name="nagios.NSCAPort" size="5"/></td></tr>	
				<tr><td>Warning Threshold</td><td><input type="input" name="nagios.NSCAPort" size="5"/></td></tr>	
			</table>
			<input type="submit" value="Add New Check"/>
		</form>


		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
