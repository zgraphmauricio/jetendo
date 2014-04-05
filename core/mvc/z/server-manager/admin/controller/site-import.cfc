<cfcomponent>
<cfoutput>
<cffunction name="index" localmode="modern" access="remote" roles="serveradministrator">
	<cfscript>
	var db=request.zos.queryObject;
	var selectStruct=0;
	application.zcore.functions.zSetPageHelpId("8.1.2");
	application.zcore.functions.zStatusHandler(request.zsid);
	</cfscript>
	
	<form action="/z/server-manager/admin/site-import/process" method="post" enctype="multipart/form-data">
		<table style="width:100%; border-spacing:0px;" class="table-white">
			<tr>
				<td colspan="2" style="padding:10px; padding-bottom:0px;"><span class="large"><h2>Site Import</h2></span>
				</td>
			</tr>
			<tr>
				<td colspan="2" style="padding-left:10px;">
				<p>Choosing an existing site or click "Add Site" to create one.  The site id columns will be automatically updated as needed.</p>
				<p><strong>WARNING: If the import process fails, there may be permanent data loss.</strong>  Make sure you have made backups before updating an existing site.</p></td>
			</tr>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Site Tar File:</td>
				<td class="table-white"><input type="file" name="tarFile" /> (Required | This file must be generated by a Site Backup task in the Jetendo Server Manager).
				</td>
			</tr>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Site Uploads Tar File:</td>
				<td class="table-white"><input type="file" name="theUploadFile" /> (Optional | A simple 7-zip file contain the files in /zupload directory.  If not specified, an existing zupload folder will be retained.)
				</td>
			</tr>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Select Parent Site: </td>
				<td class="table-white">
				<cfscript>
				ipStruct=application.zcore.functions.getSystemIpStruct();

				if(application.zcore.functions.zso(form,'ipAddress') EQ ""){
					form.ipAddress=ipStruct.defaultIp;
				}
				selectStruct = StructNew();
				selectStruct.name = "ipAddress";
				selectStruct.listvalues=arraytolist(ipStruct.arrIp,",");
				application.zcore.functions.zInputSelectBox(selectStruct);
				</cfscript>
				</td>
			</tr>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Select Parent Site: </td>
				<td class="table-white">
				<cfscript>
				db.sql="SELECT site_id, replace(replace(site_short_domain, #db.param('.#request.zos.testDomain#')#, #db.param('')#), 
					#db.param('www.')#, #db.param('')#) site_short_domain 
				FROM #db.table("site", request.zos.zcoreDatasource)# site 
				WHERE site_id <> #db.param(-1)#
				ORDER BY site_short_domain ASC";
				qSites=db.execute("qSites");
				selectStruct = StructNew();
				selectStruct.name = "sidParent";
				selectStruct.query = qSites;
				selectStruct.queryLabelField = "site_short_domain";
				selectStruct.queryValueField = "site_id";
				application.zcore.functions.zInputSelectBox(selectStruct);
				</cfscript> (Leave unselected if this site is not connected to another site).
				</td>
			</tr>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Import Type:</td>
				<td class="table-white">
				<input type="radio" name="importType" value="update" /> Update Existing Site 
				<input type="radio" name="importType" value="insert" /> Add New Site
				</td>
			</tr>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Select Site To Overwrite:</td>
				<td class="table-white">
				<cfscript>
				selectStruct = StructNew();
				selectStruct.name = "sid";
				selectStruct.query = qSites;
				selectStruct.queryLabelField = "site_short_domain";
				selectStruct.queryValueField = "site_id";
				application.zcore.functions.zInputSelectBox(selectStruct);
				</cfscript> (Only applies when you select "Update Existing Site" above)
				</td>
			</tr>
			<cfif not request.zos.istestserver>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Linux Username:</td>
				<td class="table-white"><input type="text" name="linuxUser" value="" /> (Optional, only needed when there is a conflict with existing user)
				</td>
			</tr>
			</cfif>
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Ignore Database Structure Errors?</td>
				<td class="table-white"><input type="checkbox" name="ignoreDBErrors" value="1" />
				</td>
			</tr>
			<!--- <tr>
				<td class="table-list" style="vertical-align:top; width:140px;">Backup Site Before Import?</td>
				<td class="table-white"><input type="checkbox" name="backupSite" value="1" />
				</td>
			</tr> --->
			<tr>
				<td class="table-list" style="vertical-align:top; width:140px;">&nbsp;</td>
				<td class="table-white">
				<input type="submit" name="submit1" value="Import Site" />
				</td>
			</tr>
		</table>
		
	</form>
</cffunction>
	

<cffunction name="writeLogEntry" localmode="modern" access="private" roles="serveradministrator">
	<cfargument name="message" type="string" required="yes">
	<cfscript>
	f=fileopen(request.zos.backupDirectory&"import/site-import.txt", "append", "utf-8");
	filewriteline(f, arguments.message);
	fileclose(f);
	</cfscript>
</cffunction>


<cffunction name="process" localmode="modern" access="remote" roles="serveradministrator">
	<cfscript>
	var db=request.zos.queryObject;
	var dbNoVerify=request.zos.noVerifyQueryObject;
	var i=0;
	var n=0;
	var cfcatch=0;
	var g=0;
	var row=0;
	var debug=false;
	setting requesttimeout="3600";
	form.sid=application.zcore.functions.zso(form, 'sid');
	form.ipAddress=application.zcore.functions.zso(form, 'ipAddress');
	form.importType=application.zcore.functions.zso(form, 'importType');
	form.sidParent=application.zcore.functions.zso(form, 'sidParent');
	form.ignoreDBErrors=application.zcore.functions.zso(form,'ignoreDBErrors', false, false);
	
	//debug=true;

	if(form.importType EQ ""){
		application.zcore.status.setStatus(request.zsid, "Import type is required.", form, true);
		application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
	}
	
	application.zcore.functions.zCreateDirectory(request.zos.backupDirectory&"import/");
	curDate=dateformat(now(), "yyyymmdd")&"-"&timeformat(now(),"HHmmss");
	writeLogEntry("---------------#chr(10)#Begin import: "&curDate);
	curImportPath=request.zos.backupDirectory&"import/"&curDate&"/";
	curMYSQLImportPath=request.zos.mysqlBackupDirectory&"import/"&curDate&"/";
	
	// create new directories
	application.zcore.functions.zCreateDirectory(curImportPath);
	application.zcore.functions.zCreateDirectory(curImportPath&"upload/");
	application.zcore.functions.zCreateDirectory(curImportPath&"temp/");
	
	writeLogEntry("Upload tarFile");
	filePath=application.zcore.functions.zUploadFile("tarFile", "#curImportPath#upload/");
	if(filePath EQ false){
		application.zcore.status.setStatus(request.zsid, "The site backup file failed to upload. Please try again", form, true);
		application.zcore.functions.zdeletedirectory(curImportPath);
		application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
	}
	fileName=filePath;
	filePath="#curImportPath#upload/"&filePath;
	fileUploadName="";
	if(right(filePath, 7) NEQ ".tar.gz"){
		application.zcore.status.setStatus(request.zsid, "A site backup file must end with "".tar.gz"".  Only files generated by the site backup task are compatible with site import.  Don't try to package your own backup file.", form, true);
		application.zcore.functions.zdeletedirectory(curImportPath);
		application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
	}
	writeLogEntry("untarZipSiteImportPath: "&fileName);
	result=application.zcore.functions.zSecureCommand("untarZipSiteImportPath"&chr(9)&fileName&chr(9)&curDate, 3600);
	writeLogEntry("untarZipSiteImportPath result: "&result);
	if(structkeyexists(form, 'theUploadFile') and form.theUploadFile NEQ ""){
		fileUploadPath=application.zcore.functions.zUploadFile("theUploadFile", "#curImportPath#upload/");
		if(fileUploadPath EQ false){
			application.zcore.status.setStatus(request.zsid, "The site uploads backup file failed to upload. Please try again", form, true);
			application.zcore.functions.zdeletedirectory(curImportPath);
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
		fileUploadName=fileUploadPath;
		fileUploadPath="#curImportPath#upload/"&fileUploadPath;
		writeLogEntry("Uploaded theUploadFile: "&fileUploadPath);
		if(right(fileUploadPath, 7) NEQ ".tar.gz"){
			application.zcore.status.setStatus(request.zsid, "A site upload backup file must end with "".tar.gz"".  Only files generated by the site backup task are compatible with site import.  Don't try to package your own backup file.", form, true);
			application.zcore.functions.zdeletedirectory(curImportPath);
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
		//application.zcore.functions.zSecureCommand("untarZipSiteUploadPath"&chr(9)&fileUploadName&chr(9)&curDate, 3600);
	}

	
	globals=deserializeJson(application.zcore.functions.zreadfile(curImportPath&"temp/globals.json"));

	if(form.sid NEQ "" and form.importType EQ "update"){
		db.sql="select * from #db.table("site", request.zos.zcoreDatasource)# WHERE 
		site_id = #db.param(form.sid)# ";
		qSite=db.execute("qSite");
		for(row in qSite){
			globals.site_domain=row.site_domain;
			globals.site_id=row.site_id;
			globals.site_securedomain=row.site_securedomain;
			globals.site_short_domain=row.site_short_domain;
			globals.site_domain=row.site_domain;
			globals.site_sitename=row.site_sitename;
			globals.site_domainaliases=row.site_domainaliases;
			globals.site_admin_email=row.site_admin_email;
			globals.site_email_campaign_from=row.site_email_campaign_from;
		}
	}

	// update the globals
	ts=structnew();
	ts.struct=globals;
	ts.struct.site_active=1;
	ts.struct.site_ip_address=form.ipAddress;
	if(request.zos.isTestServer){
		ts.struct.site_live=0;
		ts.struct.site_require_login=0;
		if(ts.struct.site_domain DOES NOT CONTAIN "."&request.zos.testDomain){
			ts.struct.site_domain=replace(ts.struct.site_domain&"."&request.zos.testDomain, "https://", "http://");
		}
		if(ts.struct.site_securedomain NEQ "" and ts.struct.site_securedomain DOES NOT CONTAIN "."&request.zos.testDomain){
			ts.struct.site_securedomain=replace(ts.struct.site_securedomain&"."&request.zos.testDomain, "https://", "http://");
		}
		if(ts.struct.site_short_domain DOES NOT CONTAIN "."&request.zos.testDomain){
			ts.struct.site_short_domain=replace(ts.struct.site_short_domain&"."&request.zos.testDomain, "https://", "http://");
		}
		ts.struct.site_username='';
		ts.struct.site_password='';
		ts.struct.site_admin_email=request.zOS.developerEmailTo;
		ts.struct.site_email_campaign_from=request.zOS.developerEmailTo;
	}else{
		if(ts.struct.site_domain CONTAINS "."&request.zos.testDomain){
			ts.struct.site_domain=replace(ts.struct.site_domain, "."&request.zos.testDomain, "");
		}
		if(ts.struct.site_securedomain NEQ "" and ts.struct.site_securedomain CONTAINS "."&request.zos.testDomain){
			ts.struct.site_securedomain=replace(ts.struct.site_securedomain, "."&request.zos.testDomain, "");
		}
		if(ts.struct.site_short_domain CONTAINS "."&request.zos.testDomain){
			ts.struct.site_short_domain=replace(ts.struct.site_short_domain, "."&request.zos.testDomain, "");
		}
		if(application.zcore.functions.zso(form, 'linuxUser', false,'') NEQ ""){
			ts.struct.site_username=form.linuxUser;
		}
		if(application.zcore.functions.zso(form, 'linuxPassword', false,'') NEQ ""){
			ts.struct.site_password=form.linuxPassword;
		}
	}

	installPath=application.zcore.functions.zGetDomainInstallPath(globals.site_short_domain);
	installWritablePath=application.zcore.functions.zGetDomainWritableInstallPath(globals.site_short_domain);

	domainPath=replace(installPath, request.zos.sitesPath, "");
	domainPath=left(domainPath, len(domainPath)-1);

	if(form.sidParent NEQ ""){
		ts.struct.site_parent_id=form.sidParent;
	}else{
		// force parent site to be removed for enhanced security
		ts.struct.site_parent_id=0;
	}
	ts.table="site";
	ts.datasource=request.zos.zcoredatasource;
	if(form.importType EQ "update"){
		if(form.sid NEQ ""){
			ts.struct.site_id=form.sid;
		}
		db.sql="select * from #db.table("site", request.zos.zcoreDatasource)#
		where site_id =#db.param(ts.struct.site_id)# ";
		qCheck=db.execute("qCheck");
		if(qCheck.recordcount EQ 0){
			application.zcore.status.setStatus(request.zsid, "Domain, #globals.site_short_domain#, doesn't exist in site table yet.  Please import with the ""Add Site"" option or select an existing site from the drop down menu.", form, true);
			application.zcore.functions.zdeletedirectory(curImportPath);
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
		if(not directoryexists(installPath)){
			application.zcore.status.setStatus(request.zsid, "Domain doesn't exist on the file system, but it is in the site table.  Please run the ""Verify Sites"" task from the Jetendo CMS Server Manager to repair the installation.", form, true);
			application.zcore.functions.zdeletedirectory(curImportPath);
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
	}else if(form.importType EQ "insert"){
		// verify domain doesn't exist in site table or on filesystem
		db.sql="select * from #db.table("site", request.zos.zcoreDatasource)#
		where site_short_domain = #db.param(globals.site_short_domain)# ";
		qCheck=db.execute("qCheck");
		if(qCheck.recordcount NEQ 0){
			application.zcore.status.setStatus(request.zsid, "Domain already exists in site table.  You must delete the existing domain and files before importing.", form, true);
			application.zcore.functions.zdeletedirectory(curImportPath);
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
		if(not request.zos.istestserver){
			if(globals.site_username NEQ ""){
				// linux user must be unique
				db.sql="select * from #db.table("site", request.zos.zcoreDatasource)#
				where site_username = #db.param(globals.site_username)# ";
				qCheck=db.execute("qCheck");
				if(qCheck.recordcount NEQ 0){
					application.zcore.status.setStatus(request.zsid, "Linux user, #globals.site_username#, already exists for domain, #qCheck.site_short_domain#.  You must specify a different linux user before importing again.", form, true);
					application.zcore.functions.zdeletedirectory(curImportPath);
					application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
				}
			}
		}
		if(directoryexists(installPath) or directoryexists(installWritablePath)){
			if(directoryexists(installPath)){
				application.zcore.status.setStatus(request.zsid, "Domain already exists on file system: #installPath#", form, true);
			}
			if(directoryexists(installWritablePath)){
				application.zcore.status.setStatus(request.zsid, "Domain already exists on file system: #installWritablePath#", form, true);
			}
			application.zcore.functions.zdeletedirectory(curImportPath);
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
		
	}else{
		application.zcore.functions.z404("Invalid request");
	}
	
	// process database restore
	restoreData=application.zcore.functions.zreadfile(curImportPath&"temp/restore-site-database.sql");
	arrRestore=listToArray(replace(restoreData, "/ZIMPORTPATH/", curMYSQLImportPath&"temp/", "ALL"), chr(10));
	
	// verify column list is compatible with current database structure before deleting
	directory action="list" directory="#curImportPath#temp/database-schema/" name="qDir" recurse="yes";
	arrError=[];
	
	skipDBStruct={};
	fixDBStruct={};
	for(row in qDir){
		if(right(row.name, 5) EQ ".json"){
			dsStruct=deserializeJson(application.zcore.functions.zreadfile(row.directory&"/"&row.name));
			for(n in dsStruct.fieldStruct){
				arrTable=listtoarray(replace(n, "`","", "all"), ".");
				if(form.ignoreDBErrors){
					// determine which columns be removed from the query and insert them into a struct
					dbNoVerify.sql="show fields from #dbNoVerify.table(arrTable[2], arrTable[1])#";
					try{
						qFields=dbNoVerify.execute("qFields");
					}catch(Any e){
						skipDBStruct[n]=true;
						continue;
					}
					fixDBStruct[n]={};
					for(row2 in qFields){
						found=false;
						for(g in dsStruct.fieldStruct[n]){
							if(row2.field EQ g){
								found=true;
							}
						}
						if(not found){
							fixDBStruct[n][row2.field]="@dummy";
						}
					}
					// loop the new struct when running the load data infile statements.  Will have to match the `db`.`table` first, then replace `#field#` with @dummy
				}else{
					columnList=structkeylist(dsStruct.fieldStruct[n], ", ");
					db.sql="select #columnList# from #db.table(arrTable[2], arrTable[1])# ";
					if(structkeyexists(dsStruct.fieldStruct[n], "site_id")){
						db.sql&=" where site_id = #db.param(-1)#";
					}
					db.sql&=" LIMIT #db.param(0)#, #db.param(1)#";
					try{
						db.execute("qCheck");
					}catch(Any e){
						arrayAppend(arrError, "Database structure exception when verifying #n#: "&e.message);
					}
				}
			}
		}
	}
	if(arraylen(arrError)){
		application.zcore.status.setStatus(request.zsid, arrayToList(arrError, "<br />")&"<br /><br />There are a few ways to correct these errors and re-import this site:<br />A) Create the missing column(s) or table(s) in the database.<br />B) Import again with ""ignore database structure errors"" and the missing column data will not be imported.<br />C) Manually update the restore-site-database.sql file in the tar file, re-tar and re-import the file.", form, true);
		application.zcore.functions.zdeletedirectory(curImportPath);
		application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
	}
	dsStruct={};
	for(i=1;i LTE arraylen(application.zcore.arrGlobalDatasources);i++){
		dsStruct[application.zcore.arrGlobalDatasources[i]]=[];
	}
	dsStruct[globals.site_datasource]=[];
	for(i=1;i LTE arrayLen(arrRestore);i++){
		skipTable=false;
		for(f in skipDBStruct){
			n="`"&replace(replace(f, "`","", "all"), ".", "`.`")&"`";
			if(arrRestore[i] CONTAINS n){
				skipTable=true;
				break;
			}
		}
		if(skipTable){
			continue;
		}
		for(f in fixDBStruct){
			n="`"&replace(replace(f, "`","", "all"), ".", "`.`")&"`";
			if(arrRestore[i] CONTAINS n){
				for(g IN fixDBStruct[f]){
					arrRestore[i]=replace(arrRestore[i], g, "@dummy");
				}
				break;
			}
		}
		curDatasource="";
		for(n in dsStruct){
			if(arrRestore[i] CONTAINS "`"&n&"`."){
				curDatasource=n;
				break;
			}
		}
		if(curDatasource EQ ""){
			application.zcore.status.setStatus(request.zsid, "Datasource in query didn't match a datasource on this installation.  You must create a matching datasource name or manually update the restore-site-database.sql file in the tar file and re-tar and re-import the file. - SQL: #arrRestore[i]#", form, true);
			application.zcore.functions.zdeletedirectory(curImportPath);
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
		arrayAppend(dsStruct[curDatasource], arrRestore[i]);
	}
	// all validation is done, do the actual changes now

	result=application.zcore.functions.zSecureCommand("importSite"&chr(9)&domainPath&chr(9)&curDate&chr(9)&fileName&chr(9)&fileUploadName, 3600);
	if(result EQ "0"){
		application.zcore.status.setStatus(request.zsid, "Failed to import the site. importSite"&chr(9)&globals.site_short_domain&chr(9)&curDate&chr(9)&fileName&chr(9)&fileUploadName, form, true);
		application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
	}
	if(form.importType EQ "update"){
		application.zcore.functions.zUpdate(ts);
		form.sid=globals.site_id;
		writeLogEntry("site table: updated #form.sid#");
	}else{
		ts.debug=true;
		form.sid=application.zcore.functions.zInsert(ts);
		if(form.sid EQ false){
			throw("Failed to insert site.");
		}
		globals.site_id=form.sid;
		writeLogEntry("site table: inserted #form.sid#");
	}
	directory action="list" directory="#curImportPath#temp/database/" name="qDir" recurse="yes";
	for(row in qDir){
		if(row.directory NEQ "#curImportPath#temp/database" and row.name NEQ "." and row.name NEQ ".."){
			database=replace(replace(row.directory,"\","/","all"), "#curImportPath#temp/database/", "");
			curTable=left(row.name, len(row.name)-4);
			db.sql="delete from #db.table(curTable, database)# 
			where site_id = #db.param(globals.site_id)# ";
			if(debug) writeoutput("delete from `#database#`.`#curTable#` where site_id = #globals.site_id#;<br />");
			writeLogEntry("delete from `#database#`.`#curTable#` where site_id = #globals.site_id#;");
			result=db.execute("qDelete");
			writeLogEntry("Result: #result#");
		}
	}
	for(n in dsStruct){
		// manually set datasource because the set variable queries don't use tables
		c=application.zcore.db.getConfig();
		c.autoReset=false;
		c.datasource=n;
		c.verifyQueriesEnabled=false;
		dbNoVerify=application.zcore.db.newQuery(c);
		dbNoVerify.sql="set @zDisableTriggers=1";
		dbNoVerify.execute("qDisableTrigger");
		for(i=1;i LTE arrayLen(dsStruct[n]);i++){
			dbNoVerify.sql=dsStruct[n][i];
			if(dbNoVerify.sql CONTAINS "`site_id`"){
				dbNoVerify.sql=replace(dbNoVerify.sql, ";", "")&" SET `site_id` = '"&form.sid&"'";
			}
			if(debug) writeoutput(dbNoVerify.sql&";<br />");
			writeLogEntry(";#dbNoVerify.sql#;");
			result=dbNoVerify.execute("qLoad");
			writeLogEntry("load result: #result#");
		}
		dbNoVerify.sql="set @zDisableTriggers=NULL";
		dbNoVerify.execute("qEnableTrigger");
	}
	
	// force system to self-heal
	db.sql="UPDATE #db.table("site", request.zos.zcoreDatasource)# 
	SET site_system_user_created=#db.param(0)#, 
	site_system_user_modified=#db.param(1)# 
	WHERE site_id=#db.param(globals.site_id)# ";
	db.execute("qUpdate");
	application.zcore.functions.zdeletedirectory(curImportPath);
	
	application.zcore.functions.zOS_cacheSitePaths();
	application.zcore.functions.zOS_cacheSiteAndUserGroups(globals.site_id);
	writeLogEntry("site cache updated");
	
	
	try{
		// might need to do this always - don't know yet
		application.zcore.app.appUpdateCache(globals.site_id);
	}catch(Any e){
		if(debug){
			writeoutput('done, but cache hasn''t updated yet.<a href="#globals.site_domain#/?zreset=site">Click here</a> to force it to update.');
		}else{
			application.zcore.status.setStatus(request.zsid, 'Site import complete, but app cache hasn''t updated yet.  <a href="#globals.site_domain#/?zreset=site">Click here</a> to force it to update.');
			application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
		}
	}
	
	
	if(debug){
		writeoutput('done');
	}else{
		application.zcore.status.setStatus(request.zsid, "Site import complete");
		application.zcore.functions.zRedirect("/z/server-manager/admin/site-import/index?zsid=#request.zsid#");
	}
	 </cfscript>
</cffunction>
</cfoutput>
	<!--- 
site-backup.cfm notes:
	// all existing table relationships in the exact order they should be exported.
	a1=arraynew(1);
	arrayappend(a1, {source="database.table.table_id", destination:"database2.table2.table_id"});
	/backup-database-test.cfm
	
	import new id for all rows so that all primary keys are available.   then go back and update the foreign keys within the table.
	all the tables with multi-field primary key must be inserted after the others are done.
	
	must retain compatibility with old export versions.   If it was stored as insert statement, it would be harder to modify.  I need to be using array objects that can be filtered later by a script that will upgrade them to the new version.
		i.e.
		fs["database.table"]=["field1","field2","etc"];
		// put all table structures in a single the export file name table-index.tsv
		#table-export-id	datasource-variable-name	table-name	field-name	field-name2	etc
		1	"zcoreDatasource"	"table"	"field1"	"field2"	"etc"
		
		// put each table in a separate table-name.tsv
		"data1"	"data2"	"etc"
		
		
	TODO: more thorough db structure verification and ALTER SQL generation
		
	show databases
	
	SHOW TABLES IN `zcore`
	
	SHOW TABLE STATUS FROM `zcore` WHERE ENGINE IS NOT NULL; 
	SELECT CCSA.character_set_name FROM information_schema.`TABLES` T, information_schema.`COLLATION_CHARACTER_SET_APPLICABILITY` CCSA WHERE CCSA.collation_name = T.table_collation  AND T.table_schema = "zcore"  AND T.table_name = "site";
	#table struct
	tableStruct=structnew();
	tableStruct["zcoreDatasource"]=structnew();
	tableStruct["zcoreDatasource"]["tablename"]={engine="",version="",create_options="",collation="",charset=""};
	
	
	show FIELDS from #request.zos.queryObject.table("site", request.zos.zcoreDatasource)# 
	#table field struct:
	fieldStruct["zcoreDatasource.name"]=structnew();
	fieldStruct["zcoreDatasource.name"]["fieldname"]={type="",null="",key="", default="",extra=""};
	
	show KEYS from #request.zos.queryObject.table("site", request.zos.zcoreDatasource)# site
	#keys struct
	keyStruct["zcoreDatasource.name"]=structnew();
	keyStruct["zcoreDatasource.name"]["keyname"]={non_unique="",key_name="",seq_in_index="",column_name="",index_type=""};
	
	non_unique=1 is NOT UNIQUE
	non_unique=0 is UNIQUE
	
	uniqueStruct=structnew();
	// tableStruct2 is the NEW structure
	for(i in tableStruct){
		for(n in tableStruct[i]){
			if(structkeyexists(tableStruct2, n) and structkeyexists(tableStruct2, i)){
				uniqueStruct[n&"."&i]=true;
				if(tableStruct[i][n].engine NEQ tableStruct2[i][n].engine){
					// add alter engine sql
				}
				if(tableStruct[i][n].version NEQ tableStruct2[i][n].version){
					// not sure about this one
				}
				if(tableStruct[i][n].create_options NEQ tableStruct2[i][n].create_options){
					// can this be altered?
				}
				if(tableStruct[i][n].collation NEQ tableStruct2[i][n].collation){
					// add alter collation sql
					// CONVERT TO CHARACTER SET `#tableStruct2[i][n].charset#` COLLATE `#tableStruct2[i][n].collation#
				}
			}
		}
	}
	for(i in tableStruct2){
		for(n in tableStruct2[i]){
			if(structkeyexists(uniqueStruct, n&"."&i) EQ false){
				// must create table from scratch
				tableStruct2[i][n];
			}
		}
	}
	
	SHOW CREATE TABLE #request.zos.queryObject.table("site", request.zos.zcoreDatasource)# site;
 --->
 </cfcomponent>