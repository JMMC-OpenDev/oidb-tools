<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
 xmlns:exslt="http://exslt.org/common" xmlns:math="http://exslt.org/math" xmlns:date="http://exslt.org/dates-and-times" xmlns:func="http://exslt.org/functions" xmlns:set="http://exslt.org/sets" xmlns:str="http://exslt.org/strings" xmlns:dyn="http://exslt.org/dynamic" xmlns:saxon="http://icl.com/saxon" xmlns:xalanredirect="org.apache.xalan.xslt.extensions.Redirect" xmlns:xt="http://www.jclark.com/xt" xmlns:libxslt="http://xmlsoft.org/XSLT/namespace" xmlns:test="http://xmlsoft.org/XSLT/" extension-element-prefixes= "exslt math date func set str dyn saxon xalanredirect xt libxslt test" >
<!-- 
  _______________________________________________________________________________________________________

  Create in the current directory a granule document per granule
  a shell file is also associated so it can be sourced

  a granule
  _______________________________________________________________________________________________________
-->
<xsl:template match="/">

<exslt:document href="../granules_ids.txt" method="text">
<xsl:text># auto generated --</xsl:text>
<xsl:for-each select="//granule">
<xsl:value-of select="id"/>
<xsl:text>&#10;</xsl:text>
</xsl:for-each>
</exslt:document>

<exslt:document href="../granules.env" method="text">
<xsl:text># common env vars&#10;</xsl:text>
<xsl:text># auto generated&#10;</xsl:text>
<xsl:text>SECURED_COLLECTIONS="</xsl:text>
<xsl:for-each select="set:distinct(//granule[data_rights='secure']/obs_collection)">
<xsl:value-of select="."/>
<xsl:text> </xsl:text>
</xsl:for-each>
<xsl:text>"</xsl:text>
</exslt:document>


<xsl:for-each select="//granule">
<!-- XML fragment -->
<exslt:document href="{data_rights}/granule_{id}.xml">
<xsl:copy-of select="."/>
</exslt:document>

<exslt:document href="{data_rights}/granule_{id}.env" method="text">
<xsl:comment># Please find associate xml granule in <xsl:value-of select="data_rights"/> directory</xsl:comment>
<xsl:for-each select="*">
<xsl:text>META_</xsl:text>
<xsl:value-of select="translate(name(), 'abcdefghijklmnopqrstuvwxyz',
'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
<xsl:text>="</xsl:text>
<xsl:value-of select="."/>
<xsl:text>"&#10;</xsl:text>
</xsl:for-each>

<!-- Add some extra computed METADATA -->

<xsl:text>METAX_NIGHTID="</xsl:text>
<xsl:value-of select="round(./t_min)"/>
<xsl:text>"&#10;</xsl:text>

</exslt:document>
</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
