<cfcomponent>
<cfoutput>
<!--- 
ts=structnew();
ts.inquiries_id=inquiries_id;
ts.subject="New Lead";
application.zcore.functions.zAssignAndEmailLead(ts);
 --->
<cffunction name="zAssignAndEmailLead" localmode="modern" output="no" returntype="any">
	<cfargument name="ss" type="struct" required="yes">
    <cfscript>
	var rs=structnew();
	var iemailcom=0;
	var db=request.zos.queryObject;
	var rs2=structnew();
	var inquiries_id=arguments.ss.inquiries_id;
	rs.inquiries_id=arguments.ss.inquiries_id;
	if(structkeyexists(arguments.ss, 'forceAssign') and arguments.ss.forceAssign){
		rs.assignEmail=arguments.ss.assignEmail;
		rs.leadEmail=arguments.ss.leadEmail;
		rs.user_id=0;
		rs.cc="";
	}else{
		rs=application.zcore.functions.zFindLeadRouteForInquiryId(rs);
		if(rs.success EQ false){
			rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
			rs.user_id=0;
			rs.user_id_siteIDType=0;
			if(rs.assignEmail EQ ""){
				rs.assignEmail=request.zos.developerEmailTo;
			}
			//writeoutput(rs.errorMessage);
		}else{
			rs=application.zcore.functions.zProcessLeadRoute(rs);
		}
	}
	if(not structkeyexists(rs, 'cc')){
		rs.cc="";
	}
	if(rs.user_id EQ 0){
		 db.sql="UPDATE #db.table("inquiries", request.zos.zcoreDatasource)# inquiries 
		SET inquiries_assign_email=#db.param(rs.assignemail)# 
		WHERE inquiries_id=#db.param(arguments.ss.inquiries_id)# and 
		site_id = #db.param(request.zos.globals.id)#";
		db.execute("q");
	}else{
		db.sql="UPDATE #db.table("inquiries", request.zos.zcoreDatasource)# inquiries 
		SET user_id=#db.param(rs.user_id)#, 
		user_id_siteIDType=#db.param(rs.user_id_siteIDType)# 
		WHERE inquiries_id=#db.param(arguments.ss.inquiries_id)# and 
		site_id = #db.param(request.zos.globals.id)#";
		db.execute("q"); 
	} 
	form.inquiries_id=inquiries_id;
	mail to="#rs.assignEmail#" cc="#rs.cc#" from="#request.fromemail#" replyto="#rs.leademail#" subject="#arguments.ss.subject#" type="html"{
		iemailCom=createobject("component", "zcorerootmapping.com.app.inquiriesFunctions");
	        iemailCom.getEmailTemplate();
	}
	rs2.success=true;
	return rs2;
	</cfscript>
</cffunction>

<!--- 
ts=structnew();
ts.leadEmail="email@address.com";
rs=application.zcore.functions.zGetNewMemberLeadRouteStruct(ts);
 --->
<cffunction name="zGetNewMemberLeadRouteStruct" localmode="modern" output="no" returntype="any">
	<cfargument name="ss" type="struct" required="yes">
    <cfscript>
	var rs=structnew();
	var ts=structnew();
	var i=0;
	var c=0;
	arguments.ss.assignUserId=0;
	arguments.ss.autoAssignMember=false;
	arguments.ss.autoAssignOffice=false;
	arguments.ss.routeIndex=0;
	if(structkeyexists(application.sitestruct[request.zos.globals.id].leadRoutingStruct, 'arrData')){
		for(i=1;i LTE arraylen(application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData);i++){
			c=application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData[i];
			if(c.data.inquiries_type_name EQ "New User Registration" and c.data.inquiries_type_id_siteIDType EQ 0){
				arguments.ss.routeIndex=i;
				break;
			}
		}
	}
	return application.zcore.functions.zProcessLeadRoute(arguments.ss);
	</cfscript>
</cffunction>



<cffunction name="zGetLeadRouteForInquiriesTypeId" localmode="modern" output="no" returntype="any">
	<cfargument name="toEmailAddress" type="string" required="yes">
	<cfargument name="inquiries_type_id" type="numeric" required="yes">
	<cfargument name="inquiries_type_id_siteIDType" type="numeric" required="yes">
	<cfscript>
	var rs=structnew();
	var ts=structnew();
	var i=0;
	var c=0;
	arguments.ss.assignUserId=0;
	arguments.ss.autoAssignMember=false;
	arguments.ss.autoAssignOffice=false;
	arguments.ss.routeIndex=0;
	arguments.ss.leadEmail=arguments.toEmailAddress;
	if(structkeyexists(application.sitestruct[request.zos.globals.id].leadRoutingStruct, 'arrData')){
		for(i=1;i LTE arraylen(application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData);i++){
			c=application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData[i];
			if(c.data.inquiries_type_id EQ arguments.inquiries_type_id and c.data.inquiries_type_id_siteIDType EQ arguments.inquiries_type_id_siteIDType){
				arguments.ss.routeIndex=i;
				break;
			}
		}
	}
	return application.zcore.functions.zProcessLeadRoute(arguments.ss);
	</cfscript>
</cffunction>

<cffunction name="zCompareListingWithSavedSearch" localmode="modern" output="no" returntype="any">
	see if listing.listing_id fits within criteria in mls_saved_search.mls_saved_search_id
</cffunction>

<cffunction name="zFindLeadRouteForInquiryId" localmode="modern" output="yes" returntype="any">
	<cfargument name="ss" type="struct" required="yes">
    <cfscript>
	var local=structnew();
	var rs=structnew();
	var i=0;
	var c=0;
	var qI2=0;
	var t9=0;
	var tempCount=0;
	var r9=0;
	var qmember=0;
	var qi=0;
	var db=request.zos.queryObject;
	rs.inquiries_id = arguments.ss.inquiries_id;
	rs.success=true;
	rs.routeIndex=0;
	rs.assignUserId=0;
	rs.autoAssignMember=false;
	rs.autoAssignOffice=false;
	if(structkeyexists(form, 'inquiries_email')){
		rs.leadEmail=form.inquiries_email;	
	}
	db.sql="select * from #db.table("inquiries", request.zos.zcoreDatasource)# inquiries 
	WHERE inquiries_id = #db.param(rs.inquiries_id)# and 
	site_id = #db.param(request.zos.globals.id)# ";
	qI=db.execute("qI"); 
	if(qI.recordcount EQ 0){
		rs.errorMessage="Inquiry doesn't exist.";
		rs.success=false;
		return rs;
	}
	//rs.qInquiry=qI;
	rs.leadEmail=qI.inquiries_email;
	//application.zcore.functions.zdump(qi);
	if(qI.inquiries_email NEQ ""){
		// auto-assign to same member if they are still active and the last inquiry was within 6 months.
		 db.sql="select user.user_username, user.site_id, user.user_id 
		 from (#db.table("inquiries", request.zos.zcoreDatasource)# inquiries, 
		 #db.table("user", request.zos.zcoreDatasource)# user) 
		WHERE user.user_id = inquiries.user_id and 
		user.user_active= #db.param(1)# and 
		inquiries_email = #db.param(qI.inquiries_email)# and 
		inquiries_id <> #db.param(rs.inquiries_id)# and 
		inquiries_datetime >=#db.param(dateformat(dateadd("m",-6,now()),"yyyy-mm-dd")&" 00:00:00")# and 
		inquiries.site_id = #db.param(request.zos.globals.id)#  and 
		user.site_id = #db.trustedSQL(application.zcore.functions.zGetSiteIdTypeSQL("inquiries.user_id_siteIDType"))# 
		ORDER BY inquiries_datetime DESC 
		LIMIT #db.param(0)#,#db.param(1)# ";
		qI2=db.execute("qI2");
		if(qI2.recordcount NEQ 0){
			rs.assignEmail=qI2.user_username;
			rs.assignUserId=qI2.user_id;
			rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qI2.site_id);
			return rs;
		}
	} 
	if(structkeyexists(application.sitestruct[request.zos.globals.id].leadRoutingStruct, 'arrData')){
		for(i=1;i LTE arraylen(application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData);i++){
			c=application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData[i];
			//writeoutput('loop ##'&i&'|'&c.data.inquiries_type_id&'|'&qI.inquiries_type_id&'<br />');
			if(c.data.inquiries_type_id NEQ "" and qI.inquiries_type_id NEQ c.data.inquiries_type_id){
				// didn't matched lead type, so skip this lead route.
				continue;
			}
			if(application.zcore.app.siteHasApp("listing")){
				if(c.data.inquiries_routing_search_mls EQ 1){
					if(ql.property_id NEQ ""){
						t9=structnew();
						//request.zdebugMlsSearch=true;
						t9.returnQueryOnly=true;
						t9.extraCriteria=structnew();
						t9.extraCriteria.arrMLSPID=listtoarray(qI.property_id,",");
						tempCount=arraylen(t9.extraCriteria.arrMLSPID);
						r9=request.zos.listing.functions.zMLSSearchOptionsDisplay(c.data.mls_saved_search_id,t9);
						if(r9.count NEQ 0 and r9.count EQ tempCount){
							// lead's listings matched saved search.
							if(c.data.inquiries_routing_member_auto_assign EQ 1 or c.data.inquiries_routing_office_auto_assign EQ 1){
								// compare agent name with member names
								db.sql="select * from #db.table("user", request.zos.zcoreDatasource)# user 
								WHERE member_mlsagentid = #db.param(r9.query.listing_agent[1])# and 
								user.site_id = #db.param(request.zos.globals.id)# and 
								user_active=#db.param('1')#";
								qMember=db.execute("qMember"); 
								if(qMember.recordcount NEQ 0){
									// override to use member auto-assign feature
									if(c.data.inquiries_routing_office_auto_assign EQ 1){
										rs.autoAssignOffice=true;
										// member or email will be determined by route type id
									}else{
										rs.autoAssignMember=true;
										rs.assignEmail=qMember.user_username;
										rs.assignUserId=qMember.user_id; // this will fail until implemented.
										rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qMember.site_id);
									}
									rs.routeIndex=i;
									return;
								}
							}
							// apply the normal selected inquiries_routing_type_id condition
							rs.routeIndex=i;
							return;
						}else{
							// one or more listings was not an exact match.	so this route doesn't apply.
							continue;
						}
					}else{
						// not a property inquiry, skip lead route.
						continue;	
					}
				}
			}
			
			// this route is the right one
			rs.routeIndex=i;
			return rs;
		}
	}
	rs.success=true;
	return rs;
	</cfscript>
</cffunction>

<!--- 
<cffunction name="zProcessLeadRouteForInquiryId" localmode="modern" output="no" returntype="struct">
	<cfargument name="ss" type="struct" required="yes">
    <cfscript>
	var local=structnew();
	var rs=structnew();
	var db=request.zos.queryObject;
	var qI=arguments.ss.qInquiry;
	var qUser=0;
	var arrCCType=0;
	var routingCCStruct=structnew();
	var qAssignUser=0;
	var userGroupCom = CreateObject("component","zcorerootmapping.com.user.user_group_admin");
	var c=0;
	rs.inquiries_id = arguments.ss.inquiries_id;
	rs.inquiriesEmail=qI.inquiries_email;
	rs.user_id=0;
	rs.cc="";
	rs.assignEmail="";
	if(arguments.ss.routeIndex EQ 0 or arraylen(application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData) LT arguments.ss.routeIndex){
		c=structnew();
		c.data=structnew();
		c.data.inquiries_routing_autoresponder_enabled=1;
		c.data.inquiries_routing_autoresponder_html="";
		c.data.inquiries_routing_autoresponder_text="";
		c.data.inquiries_routing_assign_to_email="";
		c.data.inquiries_routing_cc0="";
		c.data.inquiries_routing_type_id=0;
		
	}else{
		c=application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData[arguments.ss.routeIndex];	
	}
	
	
	// detect if autoresponder was sent yet by querying user table
	 db.sql="select user_id from #db.table("user", request.zos.zcoreDatasource)# user 
	WHERE user_username = #db.param(qI.inquiries_email)# and 
	site_id = #db.param(request.zos.globals.id)# ";
	qUser=db.execute("qUser");
	if(qUser.recordcount EQ 0){
		if(c.data.inquiries_routing_autoresponder_enabled EQ 1 and (c.data.inquiries_routing_autoresponder_html NEQ "" or c.data.inquiries_routing_autoresponder_text NEQ "")){
			// setup custom confirm opt-in autoresponder
			/*			
			inquiries_routing_autoresponder_html
			inquiries_routing_autoresponder_text
			*/
		}else{
			// setup default confirm opt-in alert assuming site has this option enabled.
		}
		// create new user for the lead email address
		/*
		ts=application.zcore.functions.zUserMapFormFields(structnew());
		ts.site_id = request.zos.globals.id;
		ts.autoLogin=true;
		ts.createPassword=true;
		userGroupCom = CreateObject("component","zcorerootmapping.com.user.user_group_admin");
		ts.user_group_id = userGroupCom.getGroupId('user',request.zos.globals.id);
		if(structkeyexists(request,'userOptOut')){
			ts.user_pref_list=0;
		}
		//ts.user_pref_html=1;
		// not all forms require an email address
		if(structkeyexists(ts,'user_username')){
			userAdminCom = CreateObject("component","zcorerootmapping.com.user.user_admin");
			user_id = userAdminCom.add(ts);
		}
		*/
	}
	
	if(arguments.ss.assignUserId NEQ 0){
		// force assignment and return with no logic
		rs.assignEmail=arguments.ss.assignEmail;
		rs.user_id_siteIDType=arguments.ss.user_id_siteIDType;
		rs.user_id=arguments.ss.assignUserId;
		return rs;
	}
	
	if(c.data.inquiries_routing_type_id EQ 0){
		// assign to zofficeemail
		db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
		user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))# 
		 LIMIT #db.param(0)#,#db.param(1)#";
		qAssignUser=db.execute("qAssignUser"); 
		if(qAssignUser.recordcount EQ 0){
			// assign to default email
			rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
		}else{
			// assign to default user instead
			rs.assignEmail=qAssignUser.user_username;
			rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
			rs.user_id=qAssignUser.user_id;
		}
	}else if(c.data.inquiries_routing_type_id EQ 1){
		// round robin from member table
		 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# 	
		ORDER BY user_next_lead DESC, user_id asc 
		LIMIT #db.param(0)#,#db.param(1)#";
		qAssignUser=db.execute("qAssignUser");
		if(qAssignUser.recordcount EQ 0 or application.zcore.functions.zEmailValidate(qAssignUser.user_email) EQ false){
			 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
			WHERE site_id = #db.param(request.zos.globals.id)# and 
			user_active= #db.param(1)# and 
			user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
			user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))# 	
			ORDER BY user_next_lead DESC, user_id asc 
			LIMIT #db.param(0)#,#db.param(1)#";
			qAssignUser=db.execute("qAssignUser");
			if(qAssignUser.recordcount EQ 0){
				db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
				WHERE site_id = #db.param(request.zos.globals.id)# and 
				user_active= #db.param(1)# and 
				user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
				user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))# 
				 LIMIT #db.param(0)#,#db.param(1)#";
				qAssignUser=db.execute("qAssignUser"); 
				if(qAssignUser.recordcount EQ 0){
					// assign to default email
					rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
				}else{
					// assign to default user instead
					rs.assignEmail=qAssignUser.user_username;
					rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
					rs.user_id=qAssignUser.user_id;
				}
			}else{
				rs.assignEmail=qAssignUser.user_username;
				rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
				rs.user_id=qAssignUser.user_id;
			}
		}else{
			rs.assignEmail=qAssignUser.user_username;
			rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
			rs.user_id=qAssignUser.user_id;
		}
		// round robin doesn't work in user is in parent site. should it?
		db.sql="UPDATE #db.table("user", request.zos.zcoreDatasource)# user SET user_next_lead = user_next_lead+1 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# ";
		db.execute("q"); 
		db.sql="UPDATE #db.table("user", request.zos.zcoreDatasource)# user 
		SET user_next_lead = #db.param(0)# 
		WHERE user_id = #db.param(qAssignUser.user_id)# and site_id = #db.param(qAssignUser.site_id)#";
		db.execute("q"); 
	}else if(c.data.inquiries_routing_type_id EQ 2){
		// assign to user id
		db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
		user_id =#db.param(c.data.inquiries_routing_assign_to_user_id)# 	
		ORDER BY user_next_lead DESC, user_id asc 
		LIMIT #db.param(0)#,#db.param(1)#";
		qAssignUser=db.execute("qAssignUser"); 
		if(qAssignUser.recordcount EQ 0 or application.zcore.functions.zEmailValidate(qAssignUser.user_email) EQ false){
			db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
			WHERE site_id = #db.param(request.zos.globals.id)# and 
			user_active= #db.param(1)# and 
			user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
			user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))# 	
			ORDER BY user_next_lead DESC, user_id asc 
			LIMIT #db.param(0)#,#db.param(1)#";
			qAssignUser=db.execute("qAssignUser"); 
			if(qAssignUser.recordcount EQ 0){
				rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
			}else{
				rs.assignEmail=qAssignUser.user_username;
				rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
				rs.user_id=qAssignUser.user_id;
			}
		}else{
			rs.assignEmail=qAssignUser.user_username;
			rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
			rs.user_id=qAssignUser.user_id;
		}
	}else if(c.data.inquiries_routing_type_id EQ 3){
		// assign to email address
		rs.assignEmail=c.data.inquiries_routing_assign_to_email;
	}else{
		application.zcore.template.fail("Invalid inquiries_routing_type_id");	
	}
	if(rs.assignEmail EQ ""){
		rs.assignEmail=request.zos.developeremailto;
	}
	
	if(c.data.inquiries_routing_cc0 NEQ ""){
		rs.cc=c.data.inquiries_routing_cc0;	
	}
	
	return rs;
	</cfscript>
</cffunction>
 --->


<cffunction name="zProcessLeadRoute" localmode="modern" output="no" returntype="struct">
	<cfargument name="ss" type="struct" required="yes">
    <cfscript>
	var local=structnew();
	var rs=structnew();
	var qUser=0;
	var arrCCType=0;
	var routingCCStruct=structnew();
	var qAssignUser=0;
	var db=request.zos.queryObject;
	var userGroupCom = CreateObject("component","zcorerootmapping.com.user.user_group_admin");
	var c=0;
	rs.leademail=arguments.ss.leademail;
	rs.user_id=0;
	rs.cc="";
	rs.assignEmail="";
	if(arguments.ss.routeIndex EQ 0 or arraylen(application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData) LT arguments.ss.routeIndex){
		c=structnew();
		c.data=structnew();
		c.data.inquiries_routing_autoresponder_enabled=1;
		c.data.inquiries_routing_autoresponder_html="";
		c.data.inquiries_routing_autoresponder_text="";
		c.data.inquiries_routing_assign_to_email="";
		c.data.inquiries_routing_cc0="";
		c.data.inquiries_routing_type_id=0;
		
	}else{
		c=application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData[arguments.ss.routeIndex];	
	}
	
	
	// detect if autoresponder was sent yet by querying user table
	 db.sql="select user_id from #db.table("user", request.zos.zcoreDatasource)# user 
	WHERE user_username = #db.param(arguments.ss.leadEmail)# and 
	site_id = #db.param(request.zos.globals.id)# ";
	qUser=db.execute("qUser");
	if(qUser.recordcount EQ 0){
		if(c.data.inquiries_routing_autoresponder_enabled EQ 1 and (c.data.inquiries_routing_autoresponder_html NEQ "" or c.data.inquiries_routing_autoresponder_text NEQ "")){
			// setup custom confirm opt-in autoresponder
			/*			
			inquiries_routing_autoresponder_html
			inquiries_routing_autoresponder_text
			*/
		}else{
			// setup default confirm opt-in alert assuming site has this option enabled.
		}
		// create new user for the lead email address
		/*
		ts=application.zcore.functions.zUserMapFormFields(structnew());
		ts.site_id = request.zos.globals.id;
		ts.autoLogin=true;
		ts.createPassword=true;
		userGroupCom = CreateObject("component","zcorerootmapping.com.user.user_group_admin");
		ts.user_group_id = userGroupCom.getGroupId('user',request.zos.globals.id);
		if(structkeyexists(request,'userOptOut')){
			ts.user_pref_list=0;
		}
		//ts.user_pref_html=1;
		// not all forms require an email address
		if(structkeyexists(ts,'user_username')){
			userAdminCom = CreateObject("component","zcorerootmapping.com.user.user_admin");
			user_id = userAdminCom.add(ts);
		}
		*/
	}
	
	if(arguments.ss.assignUserId NEQ 0){
		// force assignment and return with no logic
		rs.assignEmail=arguments.ss.assignEmail;
		rs.user_id_siteIDType=arguments.ss.user_id_siteIDType;
		rs.user_id=arguments.ss.assignUserId;
		return rs;
	}
	
	if(c.data.inquiries_routing_type_id EQ 0){
		// assign to zofficeemail
		 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
		user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))#  
		LIMIT #db.param(0)#,#db.param(1)#";
		qAssignUser=db.execute("qAssignUser");
		if(qAssignUser.recordcount EQ 0){
			// assign to default email
			rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
		}else{
			// assign to default user instead
			rs.assignEmail=qAssignUser.user_username;
			rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
			rs.user_id=qAssignUser.user_id;
		}
	}else if(c.data.inquiries_routing_type_id EQ 1){
		// round robin from member table
		db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# 	
		ORDER BY user_next_lead DESC, user_id asc LIMIT #db.param(0)#,#db.param(1)#";
		qAssignUser=db.execute("qAssignUser"); 
		if(qAssignUser.recordcount EQ 0 or application.zcore.functions.zEmailValidate(qAssignUser.user_email) EQ false){
			db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
			WHERE site_id = #db.param(request.zos.globals.id)# and 
			user_active= #db.param(1)# and 
			user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
			user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))# 	
			ORDER BY user_next_lead DESC, user_id asc LIMIT #db.param(0)#,#db.param(1)#";
			qAssignUser=db.execute("qAssignUser"); 
			if(qAssignUser.recordcount EQ 0){
				db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
				WHERE site_id = #db.param(request.zos.globals.id)# and 
				user_active= #db.param(1)# and 
				user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
				user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))#  
				LIMIT #db.param(0)#,#db.param(1)#";
				qAssignUser=db.execute("qAssignUser"); 
				if(qAssignUser.recordcount EQ 0){
					// assign to default email
					rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
				}else{
					// assign to default user instead
					rs.assignEmail=qAssignUser.user_username;
					rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
					rs.user_id=qAssignUser.user_id;
				}
			}else{
				rs.assignEmail=qAssignUser.user_username;
				rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
				rs.user_id=qAssignUser.user_id;
			}
		}else{
			rs.assignEmail=qAssignUser.user_username;
			rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
			rs.user_id=qAssignUser.user_id;
		}
		// round robin doesn't work in user is in parent site. should it?
		 db.sql="UPDATE #db.table("user", request.zos.zcoreDatasource)# user 
		 SET user_next_lead = user_next_lead+#db.param(1)# 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# ";
		db.execute("q");
		 db.sql="UPDATE #db.table("user", request.zos.zcoreDatasource)# user 
		 SET user_next_lead = #db.param(0)# 
		WHERE user_id = #db.param(qAssignUser.user_id)# and 
		site_id = #db.param(qAssignUser.site_id)#";
		db.execute("q");
	}else if(c.data.inquiries_routing_type_id EQ 2){
		// assign to user id
		 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
		WHERE site_id = #db.param(request.zos.globals.id)# and 
		user_active= #db.param(1)# and 
		user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
		user_id =#db.param(c.data.inquiries_routing_assign_to_user_id)# 	
		ORDER BY user_next_lead DESC, user_id asc LIMIT #db.param(0)#,#db.param(1)#";
		qAssignUser=db.execute("qAssignUser");
		if(qAssignUser.recordcount EQ 0 or application.zcore.functions.zEmailValidate(qAssignUser.user_email) EQ false){
			 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
			WHERE site_id = #db.param(request.zos.globals.id)# and 
			user_active= #db.param(1)# and 
			user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
			user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))# 	
			ORDER BY user_next_lead DESC, user_id asc 
			LIMIT #db.param(0)#,#db.param(1)#";
			qAssignUser=db.execute("qAssignUser");
			if(qAssignUser.recordcount EQ 0){
				rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
			}else{
				rs.assignEmail=qAssignUser.user_username;
				rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
				rs.user_id=qAssignUser.user_id;
			}
		}else{
			rs.assignEmail=qAssignUser.user_username;
			rs.user_id_siteIDType=application.zcore.functions.zGetSiteIdType(qAssignUser.site_id);
			rs.user_id=qAssignUser.user_id;
		}
	}else if(c.data.inquiries_routing_type_id EQ 3){
		// assign to email address
		rs.assignEmail=c.data.inquiries_routing_assign_to_email;
	}else{
		application.zcore.template.fail("Invalid inquiries_routing_type_id");	
	}
	if(rs.assignEmail EQ ""){
		rs.assignEmail=request.zos.developeremailto;
	}
	
	if(c.data.inquiries_routing_cc0 NEQ ""){
		rs.cc=c.data.inquiries_routing_cc0;	
	}
	
	return rs;
	</cfscript>
</cffunction>


<!--- 
all status change events:

ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="Lead assigned to user id###user_id# #user_first_name# #user_last_name# (#user_username#)";
application.zcore.functions.zLeadRecordLog(ts);

ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="Lead reassigned to user id###user_id# #user_first_name# #user_last_name# (#user_username#)";
application.zcore.functions.zLeadRecordLog(ts);


ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="Lead edited by user id###user_id# #user_first_name# #user_last_name# (#user_username#)";
application.zcore.functions.zLeadRecordLog(ts);


ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="Lead replied to by user id###user_id# #user_first_name# #user_last_name# (#user_username#)";
application.zcore.functions.zLeadRecordLog(ts);



ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="Lead assigned to external E-Mail Address: #assignEmail#";
application.zcore.functions.zLeadRecordLog(ts);


ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="1st follow-up reminder notice sent";
application.zcore.functions.zLeadRecordLog(ts);


ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="Lead note added by user id###user_id# #user_first_name# #user_last_name# (#user_username#)";
application.zcore.functions.zLeadRecordLog(ts);

ts=structnew();
ts.inquiries_id=inquiries_id;
ts.inquiries_log_description="Lead closed by user id###user_id# #user_first_name# #user_last_name# (#user_username#)";
application.zcore.functions.zLeadRecordLog(ts);



ts=structnew();
ts.inquiries_id=0;
ts.inquiries_log_description="";
application.zcore.functions.zLeadRecordLog(ts);
 --->
<cffunction name="zLeadRecordLog" localmode="modern" output="no" returntype="any">
	<cfargument name="ss" type="struct" required="yes">
	<cfscript>
	var ts=structnew();
	ts.table="inquiries_log";
	ts.datasource="#request.zos.zcoreDatasource#";
	ts.struct=structnew();
	ts.site_id=request.zos.globals.id;
	structappend(ts.struct,arguments.ss,true);
	ts.struct.inquiries_log_datetime=request.zos.mysqlnow;
	application.zcore.functions.zInsert(ts);
	</cfscript>
</cffunction>

<cffunction name="zLeadRouteStatusChange" localmode="modern" output="no" returntype="any">
	<cfscript>
	var rs=structnew();
	application.zcore.template.fail("zLeadRouteStatusChange() is not complete");
	// check if current inquiry is setup to send cc email regarding lead changes.
	
	// only do these on a scheduled task.
	if(structkeyexists(routingCCStruct, 2)){
		// On other status changes (i.e. edits/notes/replies)<br />
		rs.subjectPrefix="Lead status change: ";
		rs.cc=c.inquiries_routing_cc;
	}
	</cfscript>
</cffunction>

<cffunction name="zLeadRouteReminderScheduledTask" localmode="modern" output="no" returntype="any">
    <cfscript>
	var local=structnew();
	var c=0;
	var qRoute=0;
	var qI=0;
	var t9=0;
	var rs=0;
	var totalReminders=0;
	var reminderPrefix=0;
	var sendReminder=0;
	var finalReminder=0;
	var qAssignUser=0;
	var db=request.zos.queryObject;
	var curDate=0;
	var hoursSinceUpdate=0;
	var userGroupCom = CreateObject("component","zcorerootmapping.com.user.user_group_admin");
	// figure out a way to only query leads that need to have reminder logic or cc for inactivity
	 db.sql="select count(inquiries_routing_id) c 
	 from #db.table("inquiries_routing", request.zos.zcoreDatasource)# inquiries_routing 
	WHERE site_id = #db.param(request.zos.globals.id)# ";
	qRoute=db.execute("qRoute");
	if(qRoute.recordcount EQ 0 or qRoute.c EQ 0){
		return; // no routing reminders needed for this web site.
	}
	
	// only future inquiries that aren't closed
	db.sql="SELECT * FROM #db.table("inquiries", request.zos.zcoreDatasource)# inquiries 
	WHERE site_id = #db.param(request.zos.globals.id)# and 
	inquiries_status_id NOT IN (#db.param('4')#,#db.param('5')#) AND 
	user_id <> #db.param('0')# and 
	inquiries_datetime > #db.param('2010-02-08 14:00:00')# ";
	qI=db.execute("qI"); 
	</cfscript><cfloop query="qI"><cfscript>
	
	// find lead route
	t9=structnew();
	t9.inquiries_id=inquiries_id;
	rs=application.zcore.functions.zFindLeadRouteForInquiryId(t9);
	if(rs.routeIndex NEQ 0){
		/*
		rs.inquiries_id = arguments.ss.inquiries_id;
		rs.success=true;
		rs.assignUserId=0;
		rs.autoAssignMember=false;
		rs.autoAssignOffice=false;
		rs.routeIndex=0;
		*/
		c=application.sitestruct[request.zos.globals.id].leadRoutingStruct.arrData[rs.routeIndex];
		curDate=parsedatetime(dateformat(inquiries_updated_datetime,"yyyy-mm-dd")&" "&timeformat(inquiries_updated_datetime,"HH:mm:ss"));
		hoursSinceUpdate=(datediff("m",curDate,now()))/60;
		
		if(c.inquiries_routing_cc_inactive_hours NEQ 0 and structkeyexists(routingCCStruct, 3) and hoursSinceUpdate GTE c.inquiries_routing_cc_inactive_hours){
			// inactive for hours
			rs.subjectPrefix="Inactive for #c.inquiries_routing_cc_inactive_hours# hours: ";
			rs.cc=c.inquiries_routing_cc;
		}
		
		if(user_id NEQ 0){
			if(c.inquiries_routing_reminder_enabled EQ 1){
				totalReminders=0;
				sendReminder=false;
				finalReminder=false;
				reminderprefix="";
				if(c.inquiries_routing_reminder_hours1 NEQ 0 and hoursSinceUpdate GTE c.inquiries_routing_reminder_hours1){
					totalReminders++;
					if(inquiries_reminders_sent LT totalReminders){
						sendReminder=true;
						reminderprefix="1st follow-up reminder: ";
					}
				}
				if(c.inquiries_routing_reminder_hours2 NEQ 0 and hoursSinceUpdate GTE c.inquiries_routing_reminder_hours2){
					totalReminders++;
					if(inquiries_reminders_sent LT totalReminders){
						sendReminder=true;
						reminderprefix="2nd follow-up reminder: ";
					}
				}
				if(c.inquiries_routing_reminder_hours3 NEQ 0 and hoursSinceUpdate GTE c.inquiries_routing_reminder_hours3){
					totalReminders++;
					if(inquiries_reminders_sent LT totalReminders){
						sendReminder=true;
						reminderprefix="3rd follow-up reminder: ";
					}
				}
				if(c.inquiries_routing_reminder_hours_final NEQ 0 and hoursSinceUpdate GTE c.inquiries_routing_reminder_hours_final){
					totalReminders++;
					if(inquiries_reminders_sent LT totalReminders){
						sendReminder=true;
						finalReminder=true;
						reminderprefix="Lead reassigned to you: ";
					}
				}
				if(finalReminder){
					// reassign
					if(c.inquiries_routing_reassignment_type_id EQ 0){
						// assign to zofficeemail
						 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
						WHERE site_id = #db.param(request.zos.globals.id)# and 
						user_active= #db.param(1)# and 
						user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
						user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))#  
						LIMIT #db.param(0)#,#db.param(1)#";
						qAssignUser=db.execute("qAssignUser");
						if(qAssignUser.recordcount EQ 0){
							// assign to default email
							rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
						}else{
							// assign to default user instead
							rs.user_id=qAssignUser.user_id;
						}
					}else if(c.inquiries_routing_reassignment_type_id EQ 1){
						// round robin from member table
						 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
						WHERE site_id = #db.param(request.zos.globals.id)# and 
						user_active= #db.param(1)# and 
						user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# 	
						ORDER BY user_next_lead DESC, user_id asc 
						LIMIT #db.param(0)#,#db.param(1)#";
						qAssignUser=db.execute("qAssignUser");
						if(qAssignUser.recordcount EQ 0 or application.zcore.functions.zEmailValidate(qAssignUser.user_email) EQ false){
							 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
							WHERE site_id = #db.param(request.zos.globals.id)# and 
							user_active= #db.param(1)# and 
							user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
							user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))#  
							LIMIT #db.param(0)#,#db.param(1)#";
							qAssignUser=db.execute("qAssignUser");
							if(qAssignUser.recordcount EQ 0){
								// assign to default email
								rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
							}else{
								// assign to default user instead
								rs.user_id=qAssignUser.user_id;
							}
						}else{
							// assign to the round robin user
							rs.user_id=qAssignUser.user_id;
							db.sql="UPDATE #db.table("user", request.zos.zcoreDatasource)# user 
							SET user_next_lead = user_next_lead+#db.param(1)# 
							WHERE site_id = #db.param(request.zos.globals.id)# and 
							user_active= #db.param(1)# and 
							user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# ";
							db.execute("q");
							 db.sql="UPDATE #db.table("user", request.zos.zcoreDatasource)# user 
							 SET user_next_lead = #db.param(0)# 
							WHERE user_id = #db.param(qAssignUser.user_id)# and 
							site_id = #db.param(request.zos.globals.id)#";
							db.execute("q");
						}
					}else if(c.inquiries_routing_reassignment_type_id EQ 2){
						// assign to user id
						db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
						WHERE site_id = #db.param(request.zos.globals.id)# and 
						user_active= #db.param(1)# and 
						user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
						user_id =#db.param(c.inquiries_routing_assign_to_user_id)# 	
						ORDER BY user_next_lead DESC, user_id asc 
						LIMIT #db.param(0)#,#db.param(1)#";
						qAssignUser=db.execute("qAssignUser"); 
						if(qAssignUser.recordcount EQ 0 or application.zcore.functions.zEmailValidate(qAssignUser.user_email) EQ false){
							 db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
							WHERE site_id = #db.param(request.zos.globals.id)# and 
							user_active= #db.param(1)# and 
							user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
							user_username =#db.param(application.zcore.functions.zvarso('zofficeemail'))# 	
							ORDER BY user_next_lead DESC, user_id asc 
							LIMIT #db.param(0)#,#db.param(1)#";
							qAssignUser=db.execute("qAssignUser");
							if(qAssignUser.recordcount EQ 0){
								rs.assignEmail=application.zcore.functions.zvarso('zofficeemail');
							}else{
								rs.user_id=qAssignUser.user_id;
							}
						}else{
							rs.user_id=qAssignUser.user_id;
						}
						
					}else if(c.inquiries_routing_reassignment_type_id EQ 3){
						// assign to email address
						rs.assignEmail=c.inquiries_routing_reassignment_to_email;
					}else{
						application.zcore.template.fail("Invalid inquiries_routing_type_id");	
					}
					if(inquiries_routing_cc2 NEQ ""){
						// send copy due to reassignment
						rs.cc=inquiries_routing_cc2;	
					}
					 db.sql="update #db.table("inquiries", request.zos.zcoreDatasource)# inquiries 
					set inquiries_updated_datetime=#db.param(request.zos.mysqlnow)#, 
					inquiries_reminders_sent=#db.param(0)# 
					WHERE inquiries_id = #db.param(inquiries_id)#";
					db.execute("q");
					
					
				}else if(sendReminder){
					db.sql="SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
					WHERE site_id = #db.param(request.zos.globals.id)# and 
					user_active= #db.param(1)# and 
					user_group_id <> #db.param(userGroupCom.getGroupId('user',request.zos.globals.id))# and 
					user_id =#db.param(c.inquiries_routing_assign_to_user_id)# 	
					ORDER BY user_next_lead DESC, user_id asc 
					LIMIT #db.param(0)#,#db.param(1)#";
					qAssignUser=db.execute("qAssignUser");
					if(qAssignUser.recordcount NEQ 0){
						rs.to=qAssignUser.user_username;
						rs.subjectPrefix=reminderprefix;
					}else{
						rs.subjectPrefix="Inactive User. You must manually reassign lead: ";
						rs.to=application.zcore.functions.zvarso('zofficeemail');
					}
					 db.sql="update #db.table("inquiries", request.zos.zcoreDatasource)# inquiries 
					 set inquiries_updated_datetime=#db.param(request.zos.mysqlnow)#, inquiries_reminders_sent=#db.param(totalReminders)# 
					WHERE inquiries_id = #db.param(inquiries_id)#";
					db.execute("q");
				}
			}
		}
	}
	</cfscript></cfloop><cfscript> 
	return rs;
	</cfscript>
</cffunction>


<cffunction name="zCheckLeadStatus" localmode="modern" output="no" returntype="any">
<!--- 
query all unclosed leads and send reminders if enabled.
inquiries_updated_datetime --->
</cffunction>
 
<!--- zGetLeadRoutesStruct(); --->
<cffunction name="zGetLeadRoutesStruct" localmode="modern" output="no" returntype="any">
    <cfscript>
	var db.sql="";
	var local=structnew();
	var ts=structnew();
	var rs=structnew();
	var arrC=arraynew(1);
	var arrM=arraynew(1);
	var i=0;
	var qm=0;
	var q=0;
	var db=request.zos.queryObject;
	</cfscript>
    <cfsavecontent variable="db.sql">
    SELECT * FROM #db.table("inquiries_routing", request.zos.zcoreDatasource)# inquiries_routing 
    LEFT JOIN #db.table("inquiries_type", request.zos.zcoreDatasource)# inquiries_type ON 
	inquiries_type.inquiries_type_id = inquiries_routing.inquiries_type_id and 
	inquiries_type.site_id = #db.trustedSQL(application.zcore.functions.zGetSiteIdTypeSQL("inquiries_routing.inquiries_type_id_siteIDType"))#
     
	WHERE inquiries_routing.site_id =#db.param(request.zos.globals.id)# 
	ORDER BY inquiries_routing_sort
    </cfsavecontent><cfscript>q=db.execute("q");
	rs.arrData=arraynew(1);
	if(q.recordcount NEQ 0){
		arrC=listtoarray(q.columnlist,",");
	}
	</cfscript>
    <cfloop query="q">
		<cfscript>
        ts=structnew();
        ts.data=structnew();
        for(i=1;i LTE arraylen(arrC);i++){
            ts.data[arrC[i]]=q[arrC[i]][q.currentrow];
        }
        </cfscript>
        <cfif q.inquiries_routing_type_id EQ 2>
            <cfsavecontent variable="db.sql">
            SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
			WHERE user.user_id = #db.param(q.inquiries_routing_assign_to_user_id)# and 
			user.site_id =#db.param(request.zos.globals.id)# 
            </cfsavecontent><cfscript>qM=db.execute("qM");
            arrM=listtoarray(qM.columnlist,",");
            ts.assignToUserIdCount=qM.recordcount;
            for(i=1;i LTE arraylen(arrM);i++){
                if(qM.recordcount EQ 0){
                    ts.assignToUserIdStruct[arrM[i]]="";
                }else{
                    ts.assignToUserIdStruct[arrM[i]]=qM[arrM[i]][qm.currentrow];
                }
            }
            </cfscript>
        </cfif>
        <cfif q.inquiries_routing_reassignment_type_id EQ 2>
            <cfsavecontent variable="db.sql">
            SELECT * FROM #db.table("user", request.zos.zcoreDatasource)# user 
			WHERE user.user_id = #db.param(q.inquiries_routing_reassignment_to_user_id)# and 
			user.site_id =#db.param(request.zos.globals.id)# 
            </cfsavecontent><cfscript>qM=db.execute("qM");
            arrM=listtoarray(qM.columnlist,",");
            ts.reassignmentToUserIdCount=qM.recordcount;
            for(i=1;i LTE arraylen(arrM);i++){
                if(qM.recordcount EQ 0){
                    ts.reassignmentToUserIdQuery[arrM[i]]="";
                }else{
                    ts.reassignmentToUserIdQuery[arrM[i]]=qM[arrM[i]][qm.currentrow];
                }
            }
            </cfscript>
        </cfif>
        <cfscript>
		arrayappend(rs.arrData, ts);
		</cfscript>
    </cfloop>
    <cfscript>
	return rs;
	</cfscript>
</cffunction>
</cfoutput>
</cfcomponent>