<cfcomponent implements="zcorerootmapping.interface.databaseVersion">
<cfoutput>
<cffunction name="getChangedTableArray" localmode="modern" access="public" returntype="array">
	<cfscript>
	arr1=[];
	return arr1;
	</cfscript>
</cffunction>

<cffunction name="executeUpgrade" localmode="modern" access="public" returntype="boolean">
	<cfargument name="dbUpgradeCom" type="component" required="yes">
	<cfscript>
	if(!arguments.dbUpgradeCom.executeQuery(this.datasource, "ALTER TABLE `site_option_group`   
  ADD COLUMN `site_option_group_enable_list_recurse` CHAR(1) DEFAULT '0'  NOT NULL AFTER `site_option_group_enable_meta`")){
		return false;
	}
	if(!arguments.dbUpgradeCom.executeQuery(this.datasource, "ALTER TABLE `listing_data`   
  DROP INDEX `NewIndex1`,
  ADD  FULLTEXT INDEX `NewIndex1` (`listing_data_remarks`(255))")){
		return false;
	}
	return true;
	</cfscript>
</cffunction>
</cfoutput>
</cfcomponent>