<%@ page language="java" %>
<%@ page import="java.util.*" %>
<html>
    <head>
        <title>Server Two</title>
    </head>
    <body>
            <font size=10 color="#32CD99" > Tomcat Second Server  </font>
            <table align="centre" border="1">
            <tr>
                    <td>Session ID</td>
                     <% session.setAttribute("maxie.io","maxie.io"); %>
                      <td><%= session.getId() %></td>
          </tr>
            <tr>
                    <td>Created on</td>
                            <td><%= session.getCreationTime() %></td>
                </tr>
            </table>
           <br>
		<% out.println("Taiwan No.2");
		%>
    </body>
</html>
