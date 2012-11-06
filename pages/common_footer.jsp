
<table id="footer" width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td style="white-space: nowrap; padding-left: 10px; padding-right: 10px">
			<a href="<%=this.getServletContext().getInitParameter("termsOfUseURL")%>" target="_blank">Terms of Use</a>
			<span style="font-size: 14px; color: #999999;padding:5px">|</span>
			<a href="<%=this.getServletContext().getInitParameter("privacyPolicyURL")%>" target="_blank">Privacy Policy</a>
		</td>
		<td width="100%">
			&nbsp;
		</td>
		<td align="right" style="white-space: nowrap; padding-right: 20px; color: #666666">
			<!--<%=this.getServletContext().getInitParameter("copyrightText")%>-->
			
		</td>
	</tr>
	<tr>
		<td style="white-space:pre-wrap; padding-left: 10px; padding-top: 5px; color: #999999;font-size:10px;font-style:arial">
			<!-- Use of this website means you accept its terms. 			
					<p>Copyright &copy; 2012 Cable&amp;Wireless Worldwide plc. All rights reserved. Registered in England and Wales. Company Number 07029206<br/>
					Registered office:
					Waterside House, Longshot Lane, Bracknell, Berkshire, RG12 1XL, United Kingdom
					</p>-->
                  <span style="word-wrap:break-word;width:600px">
			<%=this.getServletContext().getInitParameter("copyrightText")%></span>
		</td>
		<td colspan="2" align="right" style="padding-right: 15px; padding-top: 5px">
			&nbsp;
		</td>
	</tr>
</table>
