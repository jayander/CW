<%@ page import="java.net.*" %>
<%@ page import="java.util.regex.*" %>
<%@ page import="com.emc.cdp.portal.util.HttpServiceUtil" %>

<%
    // Constants.
    String TGT_COOKIE = "CDPTGC";
    String USER_COOKIE = "user";
    String TGT_PARAM = "cdp_session";
    String LOGIN_PAGE = "login.jsp";
    String NOT_FOUND_PAGE = "404.jsp";
    String LOGOUT_PAGE = "logout.jsp";
    String INDEX_PAGE = "index.jsp";
    String SERVER_ERR_PAGE = "servererr.jsp";
    String UTF_8 = "UTF-8";
	String URL_HOST = "http://localhost:8080";
    String STORAGE_SERVICE_ID = "storageservice";
    String ERRCODE_ACCOUNT_NOT_ACCESSIBLE = "AccountNotAccessible";
	
	String restBasePath = this.getServletContext().getInitParameter("usermgmtContextPath");
	restBasePath = (restBasePath == null) ? "" : restBasePath;
	if(!restBasePath.startsWith("/"))
		restBasePath = "/" + restBasePath;
    String GET_IDENTITY_API_ADDR = URL_HOST + restBasePath + "/v1/identities/";
    String GET_ACCOUNT_OF_IDENTITY_API_ADDR = URL_HOST + restBasePath + "/v1/identities/%1$s/account";
    String LIST_SUBSCRIPTION_API_ADDR = URL_HOST + restBasePath + "/v1/accounts/%1$s/subscriptions";
    
    // Variables for display.
    boolean isIndexPage = false;
    boolean isLoggedIn = false;
    String fullName = null;
    boolean hasAccount = false;
    boolean hasMaas = false;
    boolean blockServicesAccess = false;
    String accountMessage = "";
    String overviewTabClass = "nav_tab";
    String maasTabClass = "nav_tab";
    
    String currentPage = request.getRequestURI();  // If authentication failed, redirect to login page with current retain page info.
    currentPage = currentPage.substring(currentPage.lastIndexOf("/") + 1);
    if (currentPage == null || currentPage.isEmpty()) {
        currentPage = INDEX_PAGE;
    } else if (currentPage.startsWith("/")) {
        currentPage = currentPage.substring(1);
    }
    String queryStr = request.getQueryString();
    if (queryStr != null && ! queryStr.isEmpty()) {
        currentPage = currentPage + "?" + queryStr;
    }
    
    if (currentPage.startsWith(INDEX_PAGE)) {
        isIndexPage = true;
        overviewTabClass = "nav_tab_sel";
    }
    
    if (! currentPage.startsWith(LOGIN_PAGE)) {
        // To get identityId and tgt.
        String id = null;
        String tgt = null;
        Cookie[] cookies = request.getCookies();
        if ( cookies != null ) {
            for ( int i=0; i<cookies.length; i++ ) {
                if ( cookies[i].getName().equals( TGT_COOKIE ) ) {
                    tgt = cookies[i].getValue();
                } else if ( cookies[i].getName().equals( USER_COOKIE ) ) {
                    id = cookies[i].getValue();
                }
                if (tgt != null && id != null) {
                    break;
                }
            }
        }
        if ((id == null || tgt == null) && !isIndexPage && !currentPage.startsWith(NOT_FOUND_PAGE)) {
            response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8));
			return;
        } else if (id != null && tgt != null) {
            HttpURLConnection conn = null;
            // To get identity profile to verify tgt valid. (fn + ln)
            try {
                // API request.
                conn = HttpServiceUtil.openConnection(GET_IDENTITY_API_ADDR + id + "?" + TGT_PARAM + "=" + tgt, "GET");
                conn.connect();
                // API response.
                String resultBody = null;
                Pattern pattern;
                Matcher match;
                String errCode;
                String msg;
                switch (conn.getResponseCode()) {
                    case HttpURLConnection.HTTP_OK:
                        resultBody = HttpServiceUtil.getHttpBody(conn);
                        conn.disconnect();
                        // isLoggedIn.
                        isLoggedIn = true;
                        // hasAccount.
                        pattern = Pattern.compile("<identity.*<role>(.*)</role>.*");
                        match = pattern.matcher(resultBody);
                        if (match.find()) {
                            hasAccount = match.group(1).startsWith("account_");
                        }
                        // fullName.
                        pattern = Pattern.compile("<identity.*<profile>.*<firstName>(.*)</firstName>.*");
                        match = pattern.matcher(resultBody);
                        if (match.find()) {
                            fullName = match.group(1);
                        }
                        pattern = Pattern.compile("<identity.*<profile>.*<lastName>(.*)</lastName>.*");
                        match = pattern.matcher(resultBody);
                        if (match.find()) {
                            fullName = fullName + " " + match.group(1);
                        }
                        break;
                    case HttpURLConnection.HTTP_UNAUTHORIZED:
                        resultBody = HttpServiceUtil.getHttpBody(conn);
                        conn.disconnect();
                        pattern = Pattern.compile("<error.*<code>(.*)</code>.*");
                        match = pattern.matcher(resultBody);
                        if (match.find()) {
                            errCode = match.group(1);
                        } else {
                            errCode = "UnknownErrorCode";
                        }
                        System.err.println("[Portal Error] Authentication failed. Status code: " + conn.getResponseCode());
                        if (errCode.equals("SecurityContextChanged")) {
                            response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8) + "&msg=Please+login+to+continue.");
                        } else {
                            response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8) + "&errMsg=Session+invalid.");
                        }
                        return;
                    case HttpURLConnection.HTTP_BAD_REQUEST:
                        resultBody = HttpServiceUtil.getHttpBody(conn);
                        conn.disconnect();
                        pattern = Pattern.compile("<error.*<code>(.*)</code>.*");
                        match = pattern.matcher(resultBody);
                        if (match.find()) {
                            errCode = match.group(1);
                        } else {
                            errCode = "UnknownErrorCode";
                        }
                        pattern = Pattern.compile("<error.*<message>(.*)</message>.*");
                        match = pattern.matcher(resultBody);
                        if (match.find()) {
                            msg = match.group(1);
                        } else {
                            msg = "Unknown error!";
                        }
                        System.err.println("[Portal Error] Get unexpected response when requesting user info: " + msg);
                        if (errCode.equals(ERRCODE_ACCOUNT_NOT_ACCESSIBLE)) {
                            response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8) + "&errMsg=" + URLEncoder.encode(URLDecoder.decode(msg, UTF_8), UTF_8));
                        } else {
                            response.sendRedirect(SERVER_ERR_PAGE);
                        }
                        return;
                    default:
                        resultBody = HttpServiceUtil.getHttpBody(conn);
                        conn.disconnect();
                        pattern = Pattern.compile("<error.*<message>(.*)</message>.*");
                        match = pattern.matcher(resultBody);
                        if (match.find()) {
                            msg = match.group(1);
                        } else {
                            msg = "Unknown error!";
                        }
                        System.err.println("[Portal Error] Get unexpected response when requesting user info: " + msg);
                        response.sendRedirect(SERVER_ERR_PAGE);
                        return;
                }
            } catch (Exception e) {
                System.err.println("[Portal Error] Exception when requesting user info:");
                e.printStackTrace(System.err);
                if (conn != null) {
                    conn.disconnect();
                }
                response.sendRedirect(SERVER_ERR_PAGE);
				return;
            }
            
            if (hasAccount) {
                // To get accountId. (account status)
                String accountId = null;
                try {
                    // API request.
                    conn = HttpServiceUtil.openConnection(String.format(GET_ACCOUNT_OF_IDENTITY_API_ADDR, id) + "?" + TGT_PARAM + "=" + tgt, "GET");
                    conn.connect();
                    // API response.
                    String resultBody = null;
                    Pattern pattern;
                    Matcher match;
                    String errCode;
                    switch (conn.getResponseCode()) {
                        case HttpURLConnection.HTTP_OK:
                            resultBody = HttpServiceUtil.getHttpBody(conn);
                            conn.disconnect();
                            // account id.
                            pattern = Pattern.compile("<account.*<id>(.*)</id>.*");
                            match = pattern.matcher(resultBody);
                            if (match.find()) {
                                accountId = match.group(1);
                            }
                            // account state.
                            pattern = Pattern.compile("<account.*<state>(.*)</state>.*");
                            match = pattern.matcher(resultBody);
                            if (match.find()) {
                                String accountStatus = match.group(1);
                                if(accountStatus.equals("closed")) {
                                    response.sendRedirect(LOGOUT_PAGE + "?errMsg=err_closed");
                                    return;
                                }
                                else if(accountStatus.equals("cancelled")) {
                                    response.sendRedirect(LOGOUT_PAGE + "?errMsg=err_cancelled");
                                    return;
                                }
                                else if(accountStatus.equals("suspended")) {
                                    response.sendRedirect(LOGOUT_PAGE + "?errMsg=err_suspended");
                                    return;
                                }
                                else if(accountStatus.equals("pending_cancellation")) {
                                    blockServicesAccess = true;
                                    accountMessage = "Account cancelled.";
                                }
                            }
                            break;
                        case HttpURLConnection.HTTP_UNAUTHORIZED:
                            resultBody = HttpServiceUtil.getHttpBody(conn);
                            conn.disconnect();
                            pattern = Pattern.compile("<error.*<code>(.*)</code>.*");
                            match = pattern.matcher(resultBody);
                            if (match.find()) {
                                errCode = match.group(1);
                            } else {
                                errCode = "UnknownErrorCode";
                            }
                            System.err.println("[Portal Error] Authentication failed when requesting account info. Status code: " + conn.getResponseCode());
                            if (errCode.equals("SecurityContextChanged")) {
                                response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8) + "&msg=Please+login+to+continue.");
                            } else {
                                response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8) + "&errMsg=Session+invalid.");
                            }
                            return;
                        default:
                            resultBody = HttpServiceUtil.getHttpBody(conn);
                            conn.disconnect();
                            String msg;
                            pattern = Pattern.compile("<error.*<message>(.*)</message>.*");
                            match = pattern.matcher(resultBody);
                            if (match.find()) {
                                msg = match.group(1);
                            } else {
                                msg = "Unknown error!";
                            }
                            System.err.println("[Portal Error] Get unexpected response when requesting account info: " + msg);
                            response.sendRedirect(SERVER_ERR_PAGE);
                            return;
                    }
                } catch (Exception e) {
                    System.err.println("[Portal Error] Exception when requesting account info:");
                    e.printStackTrace(System.err);
                    if (conn != null) {
                        conn.disconnect();
                    }
                    response.sendRedirect(SERVER_ERR_PAGE);
					return;
                }
                
                // To get subscription.
                if (! blockServicesAccess) {
                    try {
                        // API request.
                        conn = HttpServiceUtil.openConnection(String.format(LIST_SUBSCRIPTION_API_ADDR, accountId) + "?" + TGT_PARAM + "=" + tgt, "GET");
                        conn.connect();
                        // API response.
                        String resultBody = null;
                        Pattern pattern;
                        Matcher match;
                        String errCode;
                        switch (conn.getResponseCode()) {
                            case HttpURLConnection.HTTP_OK:
                                resultBody = HttpServiceUtil.getHttpBody(conn);
                                conn.disconnect();
                                // hasMaas.
                                pattern = Pattern.compile(".*<serviceId>" + STORAGE_SERVICE_ID + "</serviceId>.*");
                                match = pattern.matcher(resultBody);
                                if (match.find()) {
                                    hasMaas = true;
                                }
                                break;
                            case HttpURLConnection.HTTP_UNAUTHORIZED:
                                resultBody = HttpServiceUtil.getHttpBody(conn);
                                conn.disconnect();
                                pattern = Pattern.compile("<error.*<code>(.*)</code>.*");
                                match = pattern.matcher(resultBody);
                                if (match.find()) {
                                    errCode = match.group(1);
                                } else {
                                    errCode = "UnknownErrorCode";
                                }
                                System.err.println("[Portal Error] Authentication failed when requesting subscription info. Status code: " + conn.getResponseCode());
                                if (errCode.equals("SecurityContextChanged")) {
                                    response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8) + "&msg=Please+login+to+continue.");
                                } else {
                                    response.sendRedirect(LOGIN_PAGE + "?service=" + URLEncoder.encode(currentPage, UTF_8) + "&errMsg=Session+invalid.");
                                }
                                return;
                            default:
                                resultBody = HttpServiceUtil.getHttpBody(conn);
                                conn.disconnect();
                                String msg;
                                pattern = Pattern.compile("<error.*<message>(.*)</message>.*");
                                match = pattern.matcher(resultBody);
                                if (match.find()) {
                                    msg = match.group(1);
                                } else {
                                    msg = "Unknown error!";
                                }
                                System.err.println("[Portal Error] Get unexpected response when requesting subscription info: " + msg);
                                response.sendRedirect(SERVER_ERR_PAGE);
                                return;
                        }
                    } catch (Exception e) {
                        System.err.println("[Portal Error] Exception when requesting subscription info:");
                        e.printStackTrace(System.err);
                        if (conn != null) {
                            conn.disconnect();
                        }
                        response.sendRedirect(SERVER_ERR_PAGE);
						return;
                    }
                }
            }
            
            // Do not allow registration for a service when subscription already exists.
            // Instead of displaying error, go to service management page.
            String queryString = request.getQueryString();
            if(queryString == null)
                queryString = "";
            if(isLoggedIn) {
                if(currentPage.lastIndexOf("account.jsp") > 0) {
                    if(hasMaas && queryString.indexOf("reg=" + STORAGE_SERVICE_ID) >= 0) {
                        response.sendRedirect(response.encodeRedirectURL("storage.jsp"));
                        return;
                    }
                }
                else if(currentPage.lastIndexOf("index.jsp") > 0) {
                    if(queryString.indexOf("reg=" + STORAGE_SERVICE_ID) >= 0) {
                        response.sendRedirect(response.encodeRedirectURL("account.jsp?reg=" + STORAGE_SERVICE_ID));
                        return;
                    }
                }
                
                // if account is blocked, disable service access and new service registrations 
                if(blockServicesAccess) {
                    if(currentPage.lastIndexOf("storage.jsp") > 0 || 
                        (currentPage.lastIndexOf("account.jsp") > 0 && queryString.indexOf("reg=") >= 0)) { 
                            response.sendRedirect(response.encodeRedirectURL("/"));
                            return;
                    }
                }
            }

            // Show selected tab on navigation (if any) based on url using CSS class
            maasTabClass = currentPage.lastIndexOf("storage.jsp") >= 0 ? "nav_tab_sel" : "nav_tab";
        }
    }

%>

<table width="100%" height="100" border="0" cellpadding="0" cellspacing="0">
	<tr height="81" class="header_bg">
		<td>
			<table width="100%" cellpadding="0" cellspacing="0" border="0">
				<tr>
					<td>
						<a href="<%=this.getServletContext().getInitParameter("cdpLogoURL")%>"><img src="images/cdp_logo.png" width="157" height="81" border="0"></a>
					</td>
					<td class="cdp_title_td">
							<%=this.getServletContext().getInitParameter("cdpTitle")%>
					</td>
					<td class="nav_user_top" align="right" width="100%">
					
					<% if (isLoggedIn) { %>
						<font id="fullName" color="black">Welcome <%=fullName%>.</font>
						<span class="nav_account_message"><%=accountMessage%></span>
						<span style="font-size: 14px; color: black;padding:5px">|</span>
						<a href="account.jsp" style="padding-right: 8px">Your Account</a>
						
						<% if (isLoggedIn) { %>
							<a href="account.jsp?v=support" style="padding-right: 8px">Support</a>
						<% } %>
						
						<a href="logout.jsp">Sign Out</a>
					<% } else { %>
						<a href="login.jsp">Sign In</a>
					<% } %>	
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr height="30" style="background-color:#222222; background-image: url('images/nav_strip_tabs.png');">
		<td style="padding-left:25px; padding-right: 10px">
			<table width="100%" height="100%" cellpadding="0" cellspacing="0">
				<tr>
					<td><img src="images/nav_tab_divider.png" border="0"></td>
					<td class="<%=overviewTabClass%>"><a href="index.jsp">Overview</a></td>
					<td><img src="images/nav_tab_divider.png" border="0"></td>
					
					<% if (isLoggedIn) { %>
						
						<% if(hasMaas) { %>
							<td class="<%=maasTabClass%>"><a href="storage.jsp">Storage Service</a></td>
							<td><img src="images/nav_tab_divider.png" border="0"></td>
						<% } %>
						
					<% } %>
					<td width="100%" align="right">
						&nbsp;
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr height="9" style="background-color: #c7dff9; background-image: url('images/nav_strip_fade.png');">
		<td style="font-size:1px">&nbsp;</td>
	</tr>
</table>
