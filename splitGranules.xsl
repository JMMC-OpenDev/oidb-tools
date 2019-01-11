<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
 xmlns:exslt="http://exslt.org/common" xmlns:math="http://exslt.org/math" xmlns:date="http://exslt.org/dates-and-times" xmlns:func="http://exslt.org/functions" xmlns:set="http://exslt.org/sets" xmlns:str="http://exslt.org/strings" xmlns:dyn="http://exslt.org/dynamic" xmlns:saxon="http://icl.com/saxon" xmlns:xalanredirect="org.apache.xalan.xslt.extensions.Redirect" xmlns:xt="http://www.jclark.com/xt" xmlns:libxslt="http://xmlsoft.org/XSLT/namespace" xmlns:test="http://xmlsoft.org/XSLT/" extension-element-prefixes= "exslt math date func set str dyn saxon xalanredirect xt libxslt test" >
<!-- 
  _______________________________________________________________________________________________________

  Create in the current directory a granule document per granule (that is not part of PIONIER collection)
  a shell file is also assocaited so it can be sourced
  
  _______________________________________________________________________________________________________
-->
<xsl:template match="/">
<xsl:for-each select="//granule[not(obs_collection='PIONIER')]">
<!-- XML fragment -->
<exslt:document href="granule_{id}.xml">
<xsl:copy-of select="."/>
</exslt:document>

<exslt:document href="granule_{id}.env" method="text">
<xsl:for-each select="*">
<xsl:text>META_</xsl:text>
<xsl:value-of select="translate(name(), 'abcdefghijklmnopqrstuvwxyz',
'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
<xsl:text>='</xsl:text>
<xsl:value-of select="."/>
<xsl:text>'</xsl:text>
<xsl:value-of select="'&#10;'"/>
</xsl:for-each>
</exslt:document>


</xsl:for-each>
</xsl:template>
</xsl:stylesheet>