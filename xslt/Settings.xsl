<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:include href="Menu.xsl"/>

<xsl:template match="/Spuren">
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

		<form method="POST" action="addSetting">
			<input type="hidden" name="prefix" value="nagios"/>
			<input type="hidden" name="name" value="server"/>
			<table>
				<tr><td>Nagios (NSCA) Host</td><td><input type="input" name="NSCAHost"/></td></tr>
				<tr><td>Nagios (NSCA) Port</td><td><input type="input" name="NSCAPort" size="5"/></td></tr>	
				<tr><td>NSCA Client Path</td><td><input type="input" name="NSCAClientPath"/></td></tr>	
				<tr><td>NSCA Config File</td><td><input type="input" name="NSCAConfigFile"/></td></tr>	
			</table>
			<input type="submit" value="Save"/>
		</form>

		<h4>Nagios Service Checks</h4>

		<table class="checks">
			<tr>
				<th>Statistics Object</th>
				<th>Check Type</th>
				<th>Check Interval [min]</th>
				<th>Map to Host</th>
				<th>Map to Service</th>
				<th>Critical Threshold [%]</th>
				<th>Warning Threshold [%]</th>
			</tr>
			<xsl:for-each select="Settings/Setting[@prefix='nagios.serviceChecks']">
			<tr>
				<td><xsl:value-of select="@name"/></td>
				<td><xsl:value-of select="@checkType"/></td>
				<td><xsl:value-of select="@checkInterval"/></td>
				<td><xsl:value-of select="@mapHost"/></td>
				<td><xsl:value-of select="@mapService"/></td>
				<td><xsl:value-of select="@critical"/></td>
				<td><xsl:value-of select="@warning"/></td>
				<td>
					<form action="removeSetting" method="GET">
						<input type="hidden" name="prefix" value="{@prefix}"/>
						<input type="hidden" name="name" value="{@name}"/>
						<input type="submit" value="Remove"/>
					</form>
				</td>
			</tr>
			</xsl:for-each>
		</table>

		<xsl:if test="count(Settings/Setting[@prefix='nagios.serviceChecks']) = 0">
			<p>You have not defined any checks yet! Add one using the form below...</p>
		</xsl:if>
		<xsl:if test="count(Settings/Setting[@prefix='nagios.serviceChecks']) > 0">
			<p>Add further checks using the form below...</p>
		</xsl:if>

		<form method="GET" action="addSetting">
			<input type="hidden" name="prefix" value="nagios.serviceChecks"/>
			<table>
				<tr><td>Statistics Object</td>
				<td>
					<select name="name">
						<xsl:for-each select="Hosts/Host">
							<xsl:sort select="@name"/>
							<option value="h{@name}">[Host] <xsl:value-of select="@name"/></option>
						</xsl:for-each>
						<xsl:for-each select="Components/Component">
							<xsl:sort select="@name"/>
							<option value="h{@name}">[Component] <xsl:value-of select="@name"/></option>
						</xsl:for-each>
						<xsl:for-each select="Interfaces/Interface">
							<xsl:sort select="@from"/>
							<option value="n{@from}!n{@to}">[Interface] <xsl:value-of select="@from"/> -&gt; <xsl:value-of select="@to"/></option>
						</xsl:for-each>
						<xsl:for-each select="ComponentInstances/Instance">
							<xsl:sort select="@component"/>
							<option value="h{@host}!n{@component}">[Component Instance] <xsl:value-of select="@component"/> @ <xsl:value-of select="@host"/></option>
						</xsl:for-each>
						<xsl:for-each select="InterfaceInstances/Instance">
							<xsl:sort select="@component"/>
							<option value="h{@host}!n{@component}!n{@newcomponent}">[Interface Instance] <xsl:value-of select="@component"/> @ <xsl:value-of select="@host"/> -&gt; <xsl:value-of select="@newcomponent"/></option>
						</xsl:for-each>
					</select>
				</td></tr>
				<tr><td>Check Type</td><td>Error Rate<input type="hidden" name="checkType" value="Error Rate"/></td></tr>
				<tr><td>Check Interval [min]</td><td><input type="input" name="checkInterval" size="5"/></td></tr>
				<tr><td>Map To Host</td><td><input type="input" name="mapHost"/></td></tr>
				<tr><td>Map To Service</td><td><input type="input" name="mapService"/></td></tr>
				<tr><td>Critical Threshold [%]</td><td><input type="input" name="critical" size="5"/></td></tr>	
				<tr><td>Warning Threshold [%]</td><td><input type="input" name="warning" size="5"/></td></tr>	
			</table>
			<input type="submit" value="Add New Check"/>
		</form>


		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
