<%@ page language="java" %>
<%@ page import="java.util.*" %>
<html>
    <head>
        <title>Server </title>
    </head>
    <body>
            <font size=10 color="#38B0DE" > Tomcat First Server  </font>
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
		<% out.println("China No.1");
		%>
    </body>
</html>
