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

		<h3>Settings</h3>

		<ol>
			<li><a href="#retention">Data Retention Time (TTL)</a></li>
			<li><a href="#alarms">Alarm Thresholds</a></li>
			<li><a href="#timeouts">Timeouts</a></li>
			<li><a href="#nagios">Nagios Integration</a></li>
		</ol>

		<hr/>

		<a name="alarms"/>
		<h3>1. Data Retention Time (TTL)</h3>

		<p>
			Configure how long you want to keep events details.
			Note that this will directly influence the disk space
			needed. SpurTracer will only enable you to drill down
			into events not older than this period.
		</p>

		<form method="GET" action="addSetting">
			<input type="hidden" name="prefix" value="spuren"/>
			<input type="hidden" name="name" value="global"/>
			<table>
				<tr>
					<td>TTL [s]</td>
					<td><input type="input"  name="ttl" value="{Settings/Setting[@prefix='spuren' and @name='global']/@ttl}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='spuren' and @name='global']/@ttl"/></td>
				</tr>
			</table>
			<input type="submit" value="Save"/>
		</form>

		<hr/>

		<a name="alarms"/>
		<h3>2. Alarm Thresholds</h3>

		<p>
			Configure error rate thresholds so that SpurTracer
			can raise a warning or an error for a host, component, 
			interface, component instance or interface instance.
		</p>

		<b>Global Default</b>

		<form method="GET" action="addSetting">
			<input type="hidden" name="prefix" value="alarms"/>
			<input type="hidden" name="name" value="global"/>
			<table>
				<tr>
					<td>Warning Threshold [%]</td>
					<td><input type="input"  name="warning" value="{Settings/Setting[@prefix='alarms' and @name='global']/@warning}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='alarms' and @name='global']/@warning"/></td>
				</tr>
				<tr>
					<td>Critical Threshold [%]</td>
					<td><input type="input" name="critical" value="{Settings/Setting[@prefix='alarms' and @name='global']/@critical}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='alarms' and @name='global']/@critical"/></td>
				</tr>
			</table>
			<input type="submit" value="Save"/>
		</form>

		<hr/>

		<a name="timeouts"/>
		<h3>3. Timeouts</h3>

		<p>
			Configure timeouts to control when SpurTracer considers
			a component or interface as not responding. 
			<ul>
				<li>For components this is the maximum duration that SpurTracer should wait for	the 'finished' event. </li>
				<li>For interfaces this is the maximum duration that SpurTracer should wait after the interface invocation was announced.</li>
			</ul>
		</p>

		<b>Global Default</b>

		<form method="GET" action="addSetting">
			<input type="hidden" name="prefix" value="timeouts"/>
			<input type="hidden" name="name" value="global"/>
			<table>
				<tr>
					<td>Component Timeout [s]</td>
					<td><input type="input"  name="component" value="{Settings/Setting[@prefix='timeouts' and @name='global']/@component}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='timeouts' and @name='global']/@component"/></td>
				</tr>
				<tr>
					<td>Interface Timeout [s]</td>
					<td><input type="input" name="interface" value="{Settings/Setting[@prefix='timeouts' and @name='global']/@interface}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='timeouts' and @name='global']/@interface"/></td>
				</tr>
			</table>
			<input type="submit" value="Save"/>
		</form>

		<hr/>

		<a name="nagios"/>
		<h3>4. Nagios Integration</h3>

		<p>
			You can configure SpurTracer to send Nagios alerts based 
			on the definitions below. For this to work you need the
			Nagios <a href="http://nagios.sourceforge.net/docs/3_0/addons.html">NSCA addon</a> 
			installed on your Nagios server and the NSCA client on
			the SpurTracer server.
		</p>

		<h4>Nagios Server</h4>

		<form method="GET" action="addSetting">
			<input type="hidden" name="prefix" value="nagios"/>
			<input type="hidden" name="name" value="server"/>
			<table>
				<tr>
					<td>Nagios (NSCA) Host</td>
					<td><input type="input" name="NSCAHost" value="{Settings/Setting[@prefix='nagios' and @name='server']/@NSCAHost}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='nagios' and @name='server']/@NSCAHost"/></td>
				</tr>
				<tr>
					<td>Nagios (NSCA) Port</td>
					<td><input type="input" name="NSCAPort" value="{Settings/Setting[@prefix='nagios' and @name='server']/@NSCAPort}" size="5"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='nagios' and @name='server']/@NSCAPort"/></td>
				</tr>
				<tr>
					<td>NSCA Client Path</td>
					<td><input type="input" name="NSCAClientPath" value="{Settings/Setting[@prefix='nagios' and @name='server']/@NSCAClientPath}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='nagios' and @name='server']/@NSCAClientPath"/></td>
				</tr>
				<tr>
					<td>NSCA Config File</td>
					<td><input type="input" name="NSCAConfigFile" value="{Settings/Setting[@prefix='nagios' and @name='server']/@NSCAConfigFile}"/></td>
					<td>default: <xsl:value-of select="DefaultSettings/Setting[@prefix='nagios' and @name='server']/@NSCAConfigFile"/></td>
				</tr>	
			</table>
			<input type="submit" value="Save"/>
		</form>

		<h4>Nagios Service Checks</h4>

		<p>Note: Nagios service checks use the alarm thresholds as configured
		in the <a href='#alarms'>Alarm Thresholds</a> section.</p>

		<a name="checks"/>
		<table class="checks">
			<tr>
				<th>Statistics Object</th>
				<th>Check Type</th>
				<th>Check Interval [min]</th>
				<th>Map to Host</th>
				<th>Map to Service</th>
			</tr>
			<xsl:for-each select="Settings/Setting[@prefix='nagios.serviceChecks']">
			<tr>
				<td><xsl:value-of select="@name"/></td>
				<td><xsl:value-of select="@checkType"/></td>
				<td><xsl:value-of select="@checkInterval"/></td>
				<td><xsl:value-of select="@mapHost"/></td>
				<td><xsl:value-of select="@mapService"/></td>
				<td>
					<form action="removeSetting#checks" method="GET">
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
					<xsl:call-template name="statistics-object-selector"/>
				</td></tr>
				<tr><td>Check Type</td><td>Error Rate<input type="hidden" name="checkType" value="Error Rate"/></td></tr>
				<tr><td>Check Interval [min]</td><td><input type="input" name="checkInterval" size="5"/></td></tr>
				<tr><td>Map To Host</td><td><input type="input" name="mapHost"/></td></tr>
				<tr><td>Map To Service</td><td><input type="input" name="mapService"/></td></tr>
			</table>
			<input type="submit" value="Add New Check"/>
		</form>


		<div class="clear"/>
	</div>
</body>
</html>
</xsl:template>

<!-- Produces <select> form element with a list of all available objects -->
<xsl:template name="statistics-object-selector">
	<select name="name">
		<xsl:for-each select="Hosts/Host">
			<xsl:sort select="@name"/>
			<option value="object!host!{@name}">[Host] <xsl:value-of select="@name"/></option>
		</xsl:for-each>
		<xsl:for-each select="Components/Component">
			<xsl:sort select="@name"/>
			<option value="object!component!{@name}">[Component] <xsl:value-of select="@name"/></option>
		</xsl:for-each>
		<xsl:for-each select="Interfaces/Interface">
			<xsl:sort select="@from"/>
			<option value="object!interface!{@from}!{@to}">[Interface] <xsl:value-of select="@from"/> -&gt; <xsl:value-of select="@to"/></option>
		</xsl:for-each>
		<xsl:for-each select="ComponentInstances/Instance">
			<xsl:sort select="@component"/>
			<option value="instance!component!{@host}!{@component}">[Component Instance] <xsl:value-of select="@component"/> @ <xsl:value-of select="@host"/></option>
		</xsl:for-each>
		<xsl:for-each select="InterfaceInstances/Instance">
			<xsl:sort select="@component"/>
			<option value="instance!interface!{@host}!{@component}!{@newcomponent}">[Interface Instance] <xsl:value-of select="@component"/> @ <xsl:value-of select="@host"/> -&gt; <xsl:value-of select="@newcomponent"/></option>
		</xsl:for-each>
	</select>
</xsl:template>

</xsl:stylesheet>
