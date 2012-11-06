<%@ page import="java.util.*"%>
<%
	response.setHeader("Cache-Control", "no-cache");
	response.setDateHeader("Expires", 0);
%>
<html>
<head>
	<title>Login</title>
	<link rel="stylesheet" href="main.css">
	<script type="text/javascript" src="fn.js"></script>
	
	<script type="text/javascript">
		<!--
		function initialize()
		{
			/*
			var username = getCookie("username");
			if(username && username.length > 1)
			{
				document.authform.user.value = username;
				document.authform.remember.checked = true;
			}
			*/
			
			// place the cursor on the user login field
			setTimeout("document.authform.user.focus();", 5);
		}
		
		function onSelectRadio( val ) {
			if ( val == "signup" ) {
				// Sign Up
				document.getElementById("tr_password").style.display = "none";
				document.authform.btn_submit.value = "Sign Up";
			} else {
				// Sign In
				document.getElementById("tr_password").style.display = "";
				document.authform.btn_submit.value = "Sign In";
			}
		}
		
		function checkEmail() {
			var pattern = /^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$/;
			return pattern.test(document.authform.user.value);
		}
		
		// Submit form
		function onSubmit() {
			document.authform.user.value = document.authform.user.value.toLowerCase();
			
			if ( ! checkEmail() ) {
				if ( document.getElementById("err_msg_up")!=null ) {
					document.getElementById("err_msg_up").style.display = "none";					
				}
				document.getElementById("err_msg").style.display = "";
				document.getElementById("err_msg").innerHTML = "Invalid email address!";
				return false;
			}
			
			if ( document.authform.radiobox[1].checked && document.authform.password.value.length <= 0 ) {
				if ( document.getElementById("err_msg_up")!=null ) {
					document.getElementById("err_msg_up").style.display = "none";					
				}
				document.getElementById("err_msg").style.display = "";
				document.getElementById("err_msg").innerHTML = "Please fill in password!";
				return false;
			}
			
			if ( document.authform.radiobox[0].checked ) {
				// Sign Up
				document.authform.action = "checkuser.jsp";
			} else {
				// Sign In
				document.authform.action = "loginpost.jsp";
			}
			
			/*
			// save username in cookie if the Remember Me checkbox is checked
			if( document.authform.remember.checked ) {
				setCookie("username", document.authform.user.value, 60);
			} else {
				setCookie("username", "", -1);
			}
			*/
			
			return true;
		}
		// -->
	</script>
</head>

<body onLoad="initialize()">

<div align="center" style="width:100%; height: 100%">
<div id="body_wrapper">

<table width="100%" cellspacing="0" cellpadding="0" border="0">
	<tr>
		<td>
			<!-- Common navigation / top banner -->
			<%@ include file="common_banner.jsp" %>
		</td>
	</tr>
	<tr>
		<td class="box_wrapper" align="middle" valign="top">
			<br>
			<h1 style="margin-left:-240px; margin-bottom:-5px;">Login to Cloud Storage as a Service</h1>
			<div class="dblBorderMedBody">
				<div class="dblBorderMedTop"></div>
				<div class="dblBorderMedBodyInner">
					
					<form name="authform" method="post" accept-charset="utf-8" onsubmit="return onSubmit()">
						<% if (null != request.getParameter("service") && !request.getParameter("service").isEmpty()) {
						%>
						<input type="hidden" name="service" value="<%=request.getParameter("service") %>">
						<%	} %>

						<%	String regObj = request.getParameter( "reg" );
							if ( regObj != null ) {
							%>
								<input type="hidden" name="reg" value="<%=regObj%>">
						<%	} %>
						<%	//decide to display signup view or signin view
							boolean isSignUp = false;
							//display the succ or error message if there is any
							String CTLoginMsg = request.getParameter( "msg" );
							if ( CTLoginMsg != null ) {
								if ( CTLoginMsg.equals("succ_logout")) {
								%>
									<div id="err_msg_up" class="success_message">You have successfully logged out.</div>
							<%	} else if ( CTLoginMsg.equals("relogin") ) {
								%>
									<div id="err_msg_up" class="success_message">Your information has been modified, please re-login for update.</div>
							<%	} else if ( CTLoginMsg.equals("user_exist") ) {
									String email = request.getParameter( "user" );
									if ( email != null ) {
										isSignUp = true; %>
										<div id="err_msg_up" class="error_message">A user already exists for <%=email%>.</div>
								<%	}
								} else { %>
									<div id="err_msg_up" class="success_message">
									<%
									out.println( CTLoginMsg );
									%>
									</div>
							<%	} %>
								<script type="text/javascript">
									var date = new Date();
									date.setTime(date.getTime()-(24*60*60*1000));
									document.cookie="CDPTGC=; expires="+date.toGMTString()+"; path=/";
									document.cookie="user=; expires="+date.toGMTString()+"; path=/";
								</script>
						<%	}
							// if signing up for a service, initially assume user is new.
							if(request.getParameter("reg") != null)
							{
								isSignUp = true;
							}
							
							String CTLoginErrorMsg = request.getParameter( "errMsg" );
							if ( CTLoginErrorMsg != null && CTLoginErrorMsg.length () > 0) {%>
								<div id="err_msg" class="error_message">
								<%
								if ( CTLoginErrorMsg.equals( "err_pw" ) ) {
									out.println( "Invalid username or password!" );
								} else if ( CTLoginErrorMsg.equals( "err_closed" ) ) {
									out.println( "Your account is closed!" );
								} else if ( CTLoginErrorMsg.equals( "err_cancelled" ) ) {
									out.println( "Your account is cancelled!" );
								} else if ( CTLoginErrorMsg.equals( "err_suspended" ) ) {
									out.println( "Your account has been disabled. Please contact your account administrator or " +
												"customer support for details." );
								} else {
									out.println( CTLoginErrorMsg );
								}
								%>		
								</div>
								<script type="text/javascript">
									var date = new Date();
									date.setTime(date.getTime()-(24*60*60*1000));
									document.cookie="CDPTGC=; expires="+date.toGMTString()+"; path=/";
									document.cookie="user=; expires="+date.toGMTString()+"; path=/";
								</script>
						<%	} else {%>
								<div id="err_msg" class="error_message" style="display:none"></div>
						<%	}%>
						<table border="0" cellpadding="0" cellspacing="0" style="width:100%">
							<tr> 
								<td align="right" style="width:100px">User ID:</td>
								<td> 
									<input type="text" name="user" size="30"> <span style="color: #aaaaaa; margin-left: 20px">Email Address</span>
								</td>
							</tr>
							<tr> 
								<td valign="top" align="right" style="width:100px">
									<input type="radio" value="signup" <%if(isSignUp) {out.println("checked");}%> name="radiobox" id="signup_radio" onclick="onSelectRadio(this.value)"/>
								</td>
								<td valign="top">
									<label for="signup_radio"><b>I am a new user.</b></label>
								</td>
							</tr>
							<tr> 
								<td valign="top" align="right" style="width:100px">
									<input type="radio" value="signin" <%if(!isSignUp) {out.println("checked");}%> name="radiobox" id="signin_radio" onclick="onSelectRadio(this.value)"/>
								</td>
								<td valign="top">
									<label for="signin_radio"><b>I am a registered user.</b></label>
								</td>
							</tr>
							<tr id="tr_password" <%if(isSignUp) {out.println("style='display:none'");}%>> 
								<td align="right" style="width:100px">Password:</td>
								<td> 
									<input type="password" name="password" size="30">
								</td>
							</tr>
							<tr> 
								<td style="width:100px">&nbsp;</td>
								<td style="padding-top:8px">
									<input class="button" type="submit" name="btn_submit" value='<%= isSignUp ? "Sign Up" : "Sign In"%>' />
									<span style="margin-left: 20px">
										<!--input type="checkbox" name="remember" id="remember"-->
										<!--label for="remember">Remember Me</label-->
									</span>
								</td>
							</tr>
							<tr> 
								<td style="width:100px">&nbsp;</td>
								<td style="padding-top:8px">
									<a href="./?v=reset_request">Forgot your password?<a><br>
								</td>
							</tr>
						</table>
					</form>		
			
				</div>
				<div class="dblBorderMedBottom"></div>
			</div>
			
		</td>
	</tr>
	<tr>
		<td>
			<!-- Common Footer -->
			<%@ include file="common_footer.jsp" %>	
		</td>
	</tr>
</table>
</div>
</div>

</body>
</html>
