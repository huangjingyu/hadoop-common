<%@ page
  contentType="text/html; charset=UTF-8"
  import="java.io.*"
  import="java.security.PrivilegedExceptionAction"
  import="java.util.*"
  import="javax.servlet.*"
  import="javax.servlet.http.*"
  import="org.apache.hadoop.conf.Configuration"
  import="org.apache.hadoop.hdfs.*"
  import="org.apache.hadoop.hdfs.server.namenode.*"
  import="org.apache.hadoop.hdfs.server.datanode.*"
  import="org.apache.hadoop.hdfs.protocol.*"
  import="org.apache.hadoop.hdfs.security.token.delegation.*"
  import="org.apache.hadoop.io.Text"
  import="org.apache.hadoop.security.UserGroupInformation"
  import="org.apache.hadoop.security.token.Token"
  import="org.apache.hadoop.util.*"
  import="java.text.DateFormat"
  import="java.net.InetAddress"
  import="java.net.URLEncoder"
%>
<%!
  static String getDelegationToken(final NameNode nn,
                                   HttpServletRequest request, Configuration conf) 
                                   throws IOException, InterruptedException {
    final UserGroupInformation ugi = JspHelper.getUGI(request, conf);
    Token<DelegationTokenIdentifier> token =
      ugi.doAs(
              new PrivilegedExceptionAction<Token<DelegationTokenIdentifier>>()
          {
            public Token<DelegationTokenIdentifier> run() throws IOException {
              return nn.getDelegationToken(new Text(ugi.getUserName()));
            }
          });
    return token.encodeToUrlString();
  }

  public void redirectToRandomDataNode(
                            NameNode nn, 
                            HttpServletRequest request,
                            HttpServletResponse resp,
                            Configuration conf
                           ) throws IOException, InterruptedException {
    String tokenString = null;
    if (UserGroupInformation.isSecurityEnabled()) {
      tokenString = getDelegationToken(nn, request, conf);
    }
    FSNamesystem fsn = nn.getNamesystem();
    String datanode = fsn.randomDataNode();
    String redirectLocation;
    String nodeToRedirect;
    int redirectPort;
    if (datanode != null) {
      redirectPort = Integer.parseInt(datanode.substring(datanode.indexOf(':')
                     + 1));
      nodeToRedirect = datanode.substring(0, datanode.indexOf(':'));
    }
    else {
      nodeToRedirect = nn.getHttpAddress().getHostName();
      redirectPort = nn.getHttpAddress().getPort();
    }
    String fqdn = InetAddress.getByName(nodeToRedirect).getCanonicalHostName();
    redirectLocation = "http://" + fqdn + ":" + redirectPort + 
                       "/browseDirectory.jsp?namenodeInfoPort=" + 
                       nn.getHttpAddress().getPort() +
                       "&dir=/" + 
                       (tokenString == null ? "" :
                        JspHelper.SET_DELEGATION + tokenString);
    resp.sendRedirect(redirectLocation);
  }
%>

<html>

<title></title>

<body>
<% 
  NameNode nn = (NameNode)application.getAttribute("name.node");
  Configuration conf = (Configuration) application.getAttribute(JspHelper.CURRENT_CONF);
  redirectToRandomDataNode(nn, request, response, conf); 
%>
<hr>

<h2>Local logs</h2>
<a href="/logs/">Log</a> directory

<%
out.println(ServletUtil.htmlFooter());
%>
