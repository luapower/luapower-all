---
tagname: libcurl binding
---

<warn>Work In Progress.</warn>

## `curl = require'libcurl'`

[LibCURL](http://curl.haxx.se/) binding.

## API

-------------------------------------- --------------------------------------
__easy interface__
`curl.easy{options...} -> easy`        create an easy request
`easy:perform() -> true|nil,err,ecode` perform the request
`easy:free()`                          free the request
`easy:getinfo(...) -> t`               get info
`easy:duphandle() -> easy`             duplicate the request
`easy:reset()`                         reset the request
`easy:recv() -> true|nil,err,ecode`
`easy:send() -> true|nil,err,ecode`
`easy.strerror(ecode) -> s`            look-up an error code
-------------------------------------- --------------------------------------

## Easy interface

### `curl.easy{options...} -> easy`

Create an request using the easy interface. Options below:

<div class=small>
----------------------------- -------------------------------------------------------
__Main options__
`url`                         [URL to work on.][curl_url]
`protocols`                   [Allowed protocols.][curl_protocols]
`redir_protocols`             [Protocols to allow redirects to.][curl_redir_protocols]
`default_protocol`            [Default protocol.][curl_default_protocol]
`port`                        [Port number to connect to.][curl_port]
`range`                       [Request range: "X-Y,N-M,...".][curl_range]
`resume_from_large`           [Resume transfer from offset.][curl_resume_from_large]
`header`                      [Include the header in the body output.][curl_header]
`maxfilesize_large`           [Max. file size to get.][curl_maxfilesize_large]
`upload`                      [Enable data upload.][curl_upload]
`infilesize_large`            [Size of file to send.][curl_infilesize_large]
`timecondition`               [Make a time conditional request.][curl_timecondition]
`timevalue`                   [Timestamp for conditional request.][curl_timevalue]
__Progress Tracking__
`noprogress`                  [Shut off the progress meter.][curl_noprogress]
`progressfunction`            [OBSOLETE callback for progress meter.][curl_progressfunction]
`progressdata`                [Data pointer to pass to the progress meter callback.][curl_progressdata]
`xferinfofunction`            [Callback for progress meter.][curl_xferinfofunction]
`xferinfodata`                [Data pointer to pass to the progress meter callback.][curl_xferinfodata]
__Error Handling__
`verbose`                     [Display verbose information.][curl_verbose]
`stderr`                      [stderr replacement stream.][curl_stderr]
`errorbuffer`                 [Error message buffer.][curl_errorbuffer]
`failonerror`                 [Fail on HTTP 4xx errors.][curl_failonerror]
__Proxies__
`proxy`                       [Proxy to use.][curl_proxy]
`proxyport`                   [Proxy port to use.][curl_proxyport]
`proxytype`                   [Proxy type.][curl_proxytype]
`noproxy`                     [Filter out hosts from proxy use.][curl_noproxy]
`httpproxytunnel`             [Tunnel through the HTTP proxy.][curl_httpproxytunnel]
`socks5_gssapi_service`       [Socks5 GSSAPI service name.][curl_socks5_gssapi_service]
`socks5_gssapi_nec`           [Socks5 GSSAPI NEC mode.][curl_socks5_gssapi_nec]
`proxy_service_name`          [Proxy service name.][curl_proxy_service_name]
__I/O Callbacks__
`writefunction`               [Callback for writing data.][curl_writefunction]
`writedata`                   [Data pointer to pass to the write callback.][curl_writedata]
`readfunction`                [Callback for reading data.][curl_readfunction]
`readdata`                    [Data pointer to pass to the read callback.][curl_readdata]
`seekfunction`                [Callback for seek operations.][curl_seekfunction]
`seekdata`                    [Data pointer to pass to the seek callback.][curl_seekdata]
__Speed Limits__
`low_speed_limit`             [Low speed limit to abort transfer.][curl_low_speed_limit]
`low_speed_time`              [Time to be below the speed to trigger low speed abort.][curl_low_speed_time]
`max_send_speed_large`        [Cap the upload speed.][curl_max_send_speed_large]
`max_recv_speed_large`        [Cap the download speed.][curl_max_recv_speed_large]
__Authentication__
`netrc`                       [Enable .netrc parsing.][curl_netrc]
`netrc_file`                  [.netrc file name.][curl_netrc_file]
`userpwd`                     [User name and password.][curl_userpwd]
`proxyuserpwd`                [Proxy user name and password.][curl_proxyuserpwd]
`username`                    [User name.][curl_username]
`password`                    [Password.][curl_password]
`login_options`               [Login options.][curl_login_options]
`proxyusername`               [Proxy user name.][curl_proxyusername]
`proxypassword`               [Proxy password.][curl_proxypassword]
`httpauth`                    [HTTP server authentication methods.][curl_httpauth]
`tlsauth_username`            [TLS authentication user name.][curl_tlsauth_username]
`tlsauth_password`            [TLS authentication password.][curl_tlsauth_password]
`tlsauth_type`                [TLS authentication methods.][curl_tlsauth_type]
`proxyauth`                   [HTTP proxy authentication methods.][curl_proxyauth]
`sasl_ir`                     [Enable SASL initial response.][curl_sasl_ir]
`xoauth2_bearer`              [OAuth2 bearer token.][curl_xoauth2_bearer]
__HTTP Protocol__
`autoreferer`                 [Automatically set Referer: header.][curl_autoreferer]
`accept_encoding`             [Accept-Encoding and automatic decompressing data.][curl_accept_encoding]
`transfer_encoding`           [Request Transfer-Encoding.][curl_transfer_encoding]
`followlocation`              [Follow HTTP redirects.][curl_followlocation]
`unrestricted_auth`           [Do not restrict authentication to original host.][curl_unrestricted_auth]
`maxredirs`                   [Maximum number of redirects to follow.][curl_maxredirs]
`postredir`                   [How to act on redirects after POST.][curl_postredir]
`put`                         [Issue a HTTP PUT request.][curl_put]
`post`                        [Issue a HTTP POST request.][curl_post]
`httpget`                     [Do a HTTP GET request.][curl_httpget]
`postfields`                  [Send a POST with this data.][curl_postfields]
`postfieldsize_large`         [The POST data is this big.][curl_postfieldsize_large]
`copypostfields`              [Send a POST with this data - and copy it.][curl_copypostfields]
`httppost`                    [Multipart formpost HTTP POST.][curl_httppost]
`referer`                     [Referer: header.][curl_referer]
`useragent`                   [User-Agent: header.][curl_useragent]
`httpheader`                  [Custom HTTP headers.][curl_httpheader]
`headeropt`                   [Control custom headers. ][curl_headeropt]
`proxyheader`                 [Custom HTTP headers sent to proxy.][curl_proxyheader]
`http200aliases`              [Alternative versions of 200 OK.][curl_http200aliases]
`cookie`                      [Cookie(s) to send.][curl_cookie]
`cookiefile`                  [File to read cookies from.][curl_cookiefile]
`cookiejar`                   [File to write cookies to.][curl_cookiejar]
`cookiesession`               [Start a new cookie session.][curl_cookiesession]
`cookielist`                  [Add or control cookies.][curl_cookielist]
`http_version`                [HTTP version to use.][curl_http_version]
`ignore_content_length`       [Ignore Content-Length.][curl_ignore_content_length]
`http_content_decoding`       [Disable Content decoding.][curl_http_content_decoding]
`http_transfer_decoding`      [Disable Transfer decoding.][curl_http_transfer_decoding]
`expect_100_timeout_ms`       [100-continue timeout in ms.][curl_expect_100_timeout_ms]
`pipewait`                    [Wait on connection to pipeline on it.][curl_pipewait]
__Connection__
`interface`                   [Bind connection locally to this.][curl_interface]
`localport`                   [Bind connection locally to this port.][curl_localport]
`localportrange`              [Bind connection locally to port range.][curl_localportrange]
`tcp_nodelay`                 [Disable the Nagle algorithm.][curl_tcp_nodelay]
`tcp_keepalive`               [Enable TCP keep-alive.][curl_tcp_keepalive]
`tcp_keepidle`                [Idle time before sending keep-alive.][curl_tcp_keepidle]
`tcp_keepintvl`               [Interval between keep-alive probes.][curl_tcp_keepintvl]
`address_scope`               [IPv6 scope for local addresses.][curl_address_scope]
`unix_socket_path`            [Path to a Unix domain socket.][curl_unix_socket_path]
`dns_interface`               [Bind name resolves to an interface.][curl_dns_interface]
`dns_cache_timeout`           [Timeout for DNS cache.][curl_dns_cache_timeout]
`dns_local_ip4`               [Bind name resolves to an IP4 address.][curl_dns_local_ip4]
`dns_local_ip6`               [Bind name resolves to an IP6 address.][curl_dns_local_ip6]
`dns_servers`                 [Preferred DNS servers.][curl_dns_servers]
`dns_use_global_cache`        [OBSOLETE Enable global DNS cache.][curl_dns_use_global_cache]
`timeout`                     [Timeout for the entire request in seconds.][curl_timeout]
`timeout_ms`                  [Timeout for the entire request in ms.][curl_timeout_ms]
`connecttimeout`              [Timeout for the connection phase in seconds.][curl_connecttimeout]
`connecttimeout_ms`           [Timeout for the connection phase in ms.][curl_connecttimeout_ms]
`accepttimeout_ms`            [Timeout for a connection be accepted.][curl_accepttimeout_ms]
`server_response_timeout`     [][curl_server_response_timeout]
`fresh_connect`               [Use a new connection.][curl_fresh_connect]
`forbid_reuse`                [Prevent subsequent connections from re-using this connection.][curl_forbid_reuse]
`connect_only`                [Only connect, nothing else.][curl_connect_only]
`resolve`                     [Provide fixed/fake name resolves.][curl_resolve]
`conv_from_network_function`  [Callback for code base conversion.][curl_conv_from_network_function]
`conv_to_network_function`    [Callback for code base conversion.][curl_conv_to_network_function]
`conv_from_utf8_function`     [Callback for code base conversion.][curl_conv_from_utf8_function]
`opensocketfunction`          [][curl_opensocketfunction]
`opensocketdata`              [][curl_opensocketdata]
`closesocketfunction`         [][curl_closesocketfunction]
`closesocketdata`             [][curl_closesocketdata]
`sockoptfunction`             [Callback for sockopt operations.][curl_sockoptfunction]
`sockoptdata`                 [Data pointer to pass to the sockopt callback.][curl_sockoptdata]
__SSH Protocol__
`ssh_auth_types`              [SSH authentication types.][curl_ssh_auth_types]
`ssh_public_keyfile`          [File name of public key.][curl_ssh_public_keyfile]
`ssh_private_keyfile`         [File name of private key.][curl_ssh_private_keyfile]
`ssh_knownhosts`              [File name with known hosts.][curl_ssh_knownhosts]
`ssh_keyfunction`             [Callback for known hosts handling.][curl_ssh_keyfunction]
`ssh_keydata`                 [Custom pointer to pass to ssh key callback.][curl_ssh_keydata]
`ssh_host_public_key_md5`     [MD5 of host's public key.][curl_ssh_host_public_key_md5]
__SMTP Protocol__
`mail_from`                   [Address of the sender.][curl_mail_from]
`mail_rcpt`                   [Address of the recipients.][curl_mail_rcpt]
`mail_auth`                   [Authentication address.][curl_mail_auth]
__TFTP Protocol__
`tftp_blksize`                [TFTP block size.][curl_tftp_blksize]
__SSL__
`use_ssl`                     [Use TLS/SSL.][curl_use_ssl]
`sslcert`                     [Client cert.][curl_sslcert]
`sslversion`                  [SSL version to use.][curl_sslversion]
`sslcerttype`                 [Client cert type.][curl_sslcerttype]
`sslkey`                      [Client key.][curl_sslkey]
`sslkeytype`                  [Client key type.][curl_sslkeytype]
`keypasswd`                   [Client key password.][curl_keypasswd]
`sslengine`                   [Use identifier with SSL engine.][curl_sslengine]
`sslengine_default`           [Default SSL engine.][curl_sslengine_default]
`ssl_options`                 [Control SSL behavior.][curl_ssl_options]
`ssl_falsestart`              [Enable TLS False Start.][curl_ssl_falsestart]
`ssl_cipher_list`             [Ciphers to use.][curl_ssl_cipher_list]
`ssl_verifyhost`              [Verify the host name in the SSL certificate.][curl_ssl_verifyhost]
`ssl_verifypeer`              [Verify the SSL certificate.][curl_ssl_verifypeer]
`ssl_verifystatus`            [Verify the SSL certificate's status.][curl_ssl_verifystatus]
`ssl_ctx_function`            [Callback for SSL context logic.][curl_ssl_ctx_function]
`ssl_ctx_data`                [Data pointer to pass to the SSL context callback.][curl_ssl_ctx_data]
`ssl_sessionid_cache`         [Disable SSL session-id cache.][curl_ssl_sessionid_cache]
`ssl_enable_npn`              [][curl_ssl_enable_npn]
`ssl_enable_alpn`             [][curl_ssl_enable_alpn]
`cainfo`                      [CA cert bundle.][curl_cainfo]
`capath`                      [Path to CA cert bundle.][curl_capath]
`crlfile`                     [Certificate Revocation List.][curl_crlfile]
`issuercert`                  [Issuer certificate.][curl_issuercert]
`certinfo`                    [Extract certificate info.][curl_certinfo]
`pinnedpublickey`             [Set pinned SSL public key.][curl_pinnedpublickey]
`krblevel`                    [Kerberos security level.][curl_krblevel]
`random_file`                 [Provide source for entropy random data.][curl_random_file]
`egdsocket`                   [Identify EGD socket for entropy.][curl_egdsocket]
`gssapi_delegation`           [Disable GSS-API delegation. ][curl_gssapi_delegation]
__FTP Protocol__
`ftpport`                     [Use active FTP.][curl_ftpport]
`quote`                       [Commands to run before transfer.][curl_quote]
`postquote`                   [Commands to run after transfer.][curl_postquote]
`prequote`                    [Commands to run just before transfer.][curl_prequote]
`append`                      [Append to remote file.][curl_append]
`ftp_use_eprt`                [Use EPTR.][curl_ftp_use_eprt]
`ftp_use_epsv`                [Use EPSV.][curl_ftp_use_epsv]
`ftp_use_pret`                [Use PRET.][curl_ftp_use_pret]
`ftp_create_missing_dirs`     [Create missing directories on the remote server.][curl_ftp_create_missing_dirs]
`ftp_response_timeout`        [Timeout for FTP responses.][curl_ftp_response_timeout]
`ftp_alternative_to_user`     [Alternative to USER.][curl_ftp_alternative_to_user]
`ftp_skip_pasv_ip`            [Ignore the IP address in the PASV response.][curl_ftp_skip_pasv_ip]
`ftpsslauth`                  [Control how to do TLS.][curl_ftpsslauth]
`ftp_ssl_ccc`                 [Back to non-TLS again after authentication. ][curl_ftp_ssl_ccc]
`ftp_account`                 [Send ACCT command.][curl_ftp_account]
`ftp_filemethod`              [Specify how to reach files.][curl_ftp_filemethod]
`transfertext`                [Use text transfer.][curl_transfertext]
`proxy_transfer_mode`         [Add transfer mode to URL over proxy.][curl_proxy_transfer_mode]
__RTSP Protocol__
`rtsp_request`                [RTSP request.][curl_rtsp_request]
`rtsp_session_id`             [RTSP session-id.][curl_rtsp_session_id]
`rtsp_stream_uri`             [RTSP stream URI.][curl_rtsp_stream_uri]
`rtsp_transport`              [RTSP Transport:][curl_rtsp_transport]
`rtsp_client_cseq`            [Client CSEQ number.][curl_rtsp_client_cseq]
`rtsp_server_cseq`            [CSEQ number for RTSP Server->Client request.][curl_rtsp_server_cseq]
`interleavefunction`          [Callback for RTSP interleaved data.][curl_interleavefunction]
`interleavedata`              [Data pointer to pass to the RTSP interleave callback.][curl_interleavedata]
__Misc. Options__
`path_as_is`                  [Disable squashing /../ and /./ sequences in the path.][curl_path_as_is]
`buffersize`                  [Ask for smaller buffer size.][curl_buffersize]
`nosignal`                    [Do not install signal handlers.][curl_nosignal]
`share`                       [Share object to use.][curl_share]
`private`                     [Private pointer to store.][curl_private]
`ipresolve`                   [IP version to resolve to.][curl_ipresolve]
`ioctlfunction`               [Callback for I/O operations.][curl_ioctlfunction]
`ioctldata`                   [Data pointer to pass to the I/O callback.][curl_ioctldata]
`service_name`                [SPNEGO service name.][curl_service_name]
`crlf`                        [Convert newlines.][curl_crlf]
`customrequest`               [Custom request/method.][curl_customrequest]
`filetime`                    [Request file modification date and time.][curl_filetime]
`dirlistonly`                 [List only.][curl_dirlistonly]
`nobody`                      [Do not get the body contents.][curl_nobody]
`new_file_perms`              [Mode for creating new remote files.][curl_new_file_perms]
`new_directory_perms`         [Mode for creating new remote directories.][curl_new_directory_perms]
`chunk_bgn_function`          [Callback for wildcard download start of chunk.][curl_chunk_bgn_function]
`chunk_end_function`          [Callback for wildcard download end of chunk.][curl_chunk_end_function]
`chunk_data`                  [Data pointer to pass to the chunk callbacks.][curl_chunk_data]
`fnmatch_function`            [Callback for wildcard matching.][curl_fnmatch_function]
`fnmatch_data`                [Data pointer to pass to the wildcard matching callback.][curl_fnmatch_data]
`wildcardmatch`               [Transfer multiple files according to a file name pattern.][curl_wildcardmatch]
`telnetoptions`               [TELNET options.][curl_telnetoptions]
`maxconnects`                 [Maximum number of connections in the connection pool.][curl_maxconnects]
`headerfunction`              [Callback for writing received headers.][curl_headerfunction]
`headerdata`                  [Data pointer to pass to the header callback.][curl_headerdata]
__Debugging__
`debugfunction`               [Callback for debug information.][curl_debugfunction]
`debugdata`                   [Data pointer to pass to the debug callback.][curl_debugdata]
----------------------------- -------------------------------------------------------
</div>

[curl_url]:                         http://curl.haxx.se/libcurl/c/CURLOPT_URL.html
[curl_protocols]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROTOCOLS.html
[curl_default_protocol]:            http://curl.haxx.se/libcurl/c/CURLOPT_DEFAULT_PROTOCOL.html
[curl_redir_protocols]:             http://curl.haxx.se/libcurl/c/CURLOPT_REDIR_PROTOCOLS.html
[curl_port]:                        http://curl.haxx.se/libcurl/c/CURLOPT_PORT.html
[curl_userpwd]:                     http://curl.haxx.se/libcurl/c/CURLOPT_USERPWD.html
[curl_range]:                       http://curl.haxx.se/libcurl/c/CURLOPT_RANGE.html
[curl_referer]:                     http://curl.haxx.se/libcurl/c/CURLOPT_REFERER.html
[curl_useragent]:                   http://curl.haxx.se/libcurl/c/CURLOPT_USERAGENT.html
[curl_postfields]:                  http://curl.haxx.se/libcurl/c/CURLOPT_POSTFIELDS.html
[curl_cookie]:                      http://curl.haxx.se/libcurl/c/CURLOPT_COOKIE.html
[curl_cookiefile]:                  http://curl.haxx.se/libcurl/c/CURLOPT_COOKIEFILE.html
[curl_post]:                        http://curl.haxx.se/libcurl/c/CURLOPT_POST.html
[curl_put]:                         http://curl.haxx.se/libcurl/c/CURLOPT_PUT.html
[curl_header]:                      http://curl.haxx.se/libcurl/c/CURLOPT_HEADER.html
[curl_headerdata]:                  http://curl.haxx.se/libcurl/c/CURLOPT_HEADERDATA.html
[curl_nobody]:                      http://curl.haxx.se/libcurl/c/CURLOPT_NOBODY.html
[curl_followlocation]:              http://curl.haxx.se/libcurl/c/CURLOPT_FOLLOWLOCATION.html
[curl_timeout]:                     http://curl.haxx.se/libcurl/c/CURLOPT_TIMEOUT.html
[curl_timeout_ms]:                  http://curl.haxx.se/libcurl/c/CURLOPT_TIMEOUT_MS.html
[curl_connecttimeout]:              http://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT.html
[curl_connecttimeout_ms]:           http://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT_MS.html
[curl_accepttimeout_ms]:            http://curl.haxx.se/libcurl/c/CURLOPT_ACCEPTTIMEOUT_MS.html
[curl_server_response_timeout]:     http://curl.haxx.se/libcurl/c/CURLOPT_SERVER_RESPONSE_TIMEOUT.html
[curl_noprogress]:                  http://curl.haxx.se/libcurl/c/CURLOPT_NOPROGRESS.html
[curl_progressfunction]:            http://curl.haxx.se/libcurl/c/CURLOPT_PROGRESSFUNCTION.html
[curl_progressdata]:                http://curl.haxx.se/libcurl/c/CURLOPT_PROGRESSDATA.html
[curl_verbose]:                     http://curl.haxx.se/libcurl/c/CURLOPT_VERBOSE.html
[curl_stderr]:                      http://curl.haxx.se/libcurl/c/CURLOPT_STDERR.html
[curl_errorbuffer]:                 http://curl.haxx.se/libcurl/c/CURLOPT_ERRORBUFFER.html
[curl_failonerror]:                 http://curl.haxx.se/libcurl/c/CURLOPT_FAILONERROR.html
[curl_proxy]:                       http://curl.haxx.se/libcurl/c/CURLOPT_PROXY.html
[curl_proxytype]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROXYTYPE.html
[curl_proxyport]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROXYPORT.html
[curl_proxyuserpwd]:                http://curl.haxx.se/libcurl/c/CURLOPT_PROXYUSERPWD.html
[curl_proxy_service_name]:          http://curl.haxx.se/libcurl/c/CURLOPT_PROXY_SERVICE_NAME.html
[curl_proxyauth]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROXYAUTH.html
[curl_proxy_transfer_mode]:         http://curl.haxx.se/libcurl/c/CURLOPT_PROXY_TRANSFER_MODE.html
[curl_proxyusername]:               http://curl.haxx.se/libcurl/c/CURLOPT_PROXYUSERNAME.html
[curl_proxypassword]:               http://curl.haxx.se/libcurl/c/CURLOPT_PROXYPASSWORD.html
[curl_proxyheader]:                 http://curl.haxx.se/libcurl/c/CURLOPT_PROXYHEADER.html
[curl_noproxy]:                     http://curl.haxx.se/libcurl/c/CURLOPT_NOPROXY.html
[curl_writefunction]:               http://curl.haxx.se/libcurl/c/CURLOPT_WRITEFUNCTION.html
[curl_writedata]:                   http://curl.haxx.se/libcurl/c/CURLOPT_WRITEDATA.html
[curl_readfunction]:                http://curl.haxx.se/libcurl/c/CURLOPT_READFUNCTION.html
[curl_readdata]:                    http://curl.haxx.se/libcurl/c/CURLOPT_READDATA.html
[curl_seekfunction]:                http://curl.haxx.se/libcurl/c/CURLOPT_SEEKFUNCTION.html
[curl_seekdata]:                    http://curl.haxx.se/libcurl/c/CURLOPT_SEEKDATA.html
[curl_infilesize]:                  http://curl.haxx.se/libcurl/c/CURLOPT_INFILESIZE.html
[curl_low_speed_limit]:             http://curl.haxx.se/libcurl/c/CURLOPT_LOW_SPEED_LIMIT.html
[curl_low_speed_time]:              http://curl.haxx.se/libcurl/c/CURLOPT_LOW_SPEED_TIME.html
[curl_max_send_speed_large]:        http://curl.haxx.se/libcurl/c/CURLOPT_MAX_SEND_SPEED_LARGE.html
[curl_max_recv_speed_large]:        http://curl.haxx.se/libcurl/c/CURLOPT_MAX_RECV_SPEED_LARGE.html
[curl_resume_from]:                 http://curl.haxx.se/libcurl/c/CURLOPT_RESUME_FROM.html
[curl_keypasswd]:                   http://curl.haxx.se/libcurl/c/CURLOPT_KEYPASSWD.html
[curl_crlf]:                        http://curl.haxx.se/libcurl/c/CURLOPT_CRLF.html
[curl_quote]:                       http://curl.haxx.se/libcurl/c/CURLOPT_QUOTE.html
[curl_timecondition]:               http://curl.haxx.se/libcurl/c/CURLOPT_TIMECONDITION.html
[curl_timevalue]:                   http://curl.haxx.se/libcurl/c/CURLOPT_TIMEVALUE.html
[curl_customrequest]:               http://curl.haxx.se/libcurl/c/CURLOPT_CUSTOMREQUEST.html
[curl_postquote]:                   http://curl.haxx.se/libcurl/c/CURLOPT_POSTQUOTE.html
[curl_upload]:                      http://curl.haxx.se/libcurl/c/CURLOPT_UPLOAD.html
[curl_dirlistonly]:                 http://curl.haxx.se/libcurl/c/CURLOPT_DIRLISTONLY.html
[curl_append]:                      http://curl.haxx.se/libcurl/c/CURLOPT_APPEND.html
[curl_transfertext]:                http://curl.haxx.se/libcurl/c/CURLOPT_TRANSFERTEXT.html
[curl_autoreferer]:                 http://curl.haxx.se/libcurl/c/CURLOPT_AUTOREFERER.html
[curl_postfieldsize]:               http://curl.haxx.se/libcurl/c/CURLOPT_POSTFIELDSIZE.html
[curl_httpheader]:                  http://curl.haxx.se/libcurl/c/CURLOPT_HTTPHEADER.html
[curl_httppost]:                    http://curl.haxx.se/libcurl/c/CURLOPT_HTTPPOST.html
[curl_httpproxytunnel]:             http://curl.haxx.se/libcurl/c/CURLOPT_HTTPPROXYTUNNEL.html
[curl_httpget]:                     http://curl.haxx.se/libcurl/c/CURLOPT_HTTPGET.html
[curl_http_version]:                http://curl.haxx.se/libcurl/c/CURLOPT_HTTP_VERSION.html
[curl_http200aliases]:              http://curl.haxx.se/libcurl/c/CURLOPT_HTTP200ALIASES.html
[curl_httpauth]:                    http://curl.haxx.se/libcurl/c/CURLOPT_HTTPAUTH.html
[curl_http_transfer_decoding]:      http://curl.haxx.se/libcurl/c/CURLOPT_HTTP_TRANSFER_DECODING.html
[curl_http_content_decoding]:       http://curl.haxx.se/libcurl/c/CURLOPT_HTTP_CONTENT_DECODING.html
[curl_interface]:                   http://curl.haxx.se/libcurl/c/CURLOPT_INTERFACE.html
[curl_krblevel]:                    http://curl.haxx.se/libcurl/c/CURLOPT_KRBLEVEL.html
[curl_cainfo]:                      http://curl.haxx.se/libcurl/c/CURLOPT_CAINFO.html
[curl_maxredirs]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAXREDIRS.html
[curl_filetime]:                    http://curl.haxx.se/libcurl/c/CURLOPT_FILETIME.html
[curl_telnetoptions]:               http://curl.haxx.se/libcurl/c/CURLOPT_TELNETOPTIONS.html
[curl_maxconnects]:                 http://curl.haxx.se/libcurl/c/CURLOPT_MAXCONNECTS.html
[curl_fresh_connect]:               http://curl.haxx.se/libcurl/c/CURLOPT_FRESH_CONNECT.html
[curl_forbid_reuse]:                http://curl.haxx.se/libcurl/c/CURLOPT_FORBID_REUSE.html
[curl_random_file]:                 http://curl.haxx.se/libcurl/c/CURLOPT_RANDOM_FILE.html
[curl_egdsocket]:                   http://curl.haxx.se/libcurl/c/CURLOPT_EGDSOCKET.html
[curl_headerfunction]:              http://curl.haxx.se/libcurl/c/CURLOPT_HEADERFUNCTION.html
[curl_cookiejar]:                   http://curl.haxx.se/libcurl/c/CURLOPT_COOKIEJAR.html
[curl_use_ssl]:                     http://curl.haxx.se/libcurl/c/CURLOPT_USE_SSL.html
[curl_sslcert]:                     http://curl.haxx.se/libcurl/c/CURLOPT_SSLCERT.html
[curl_sslversion]:                  http://curl.haxx.se/libcurl/c/CURLOPT_SSLVERSION.html
[curl_sslcerttype]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SSLCERTTYPE.html
[curl_sslkey]:                      http://curl.haxx.se/libcurl/c/CURLOPT_SSLKEY.html
[curl_sslkeytype]:                  http://curl.haxx.se/libcurl/c/CURLOPT_SSLKEYTYPE.html
[curl_sslengine]:                   http://curl.haxx.se/libcurl/c/CURLOPT_SSLENGINE.html
[curl_sslengine_default]:           http://curl.haxx.se/libcurl/c/CURLOPT_SSLENGINE_DEFAULT.html
[curl_ssl_options]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SSL_OPTIONS.html
[curl_ssl_cipher_list]:             http://curl.haxx.se/libcurl/c/CURLOPT_SSL_CIPHER_LIST.html
[curl_ssl_verifyhost]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYHOST.html
[curl_ssl_verifypeer]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYPEER.html
[curl_ssl_ctx_function]:            http://curl.haxx.se/libcurl/c/CURLOPT_SSL_CTX_FUNCTION.html
[curl_ssl_ctx_data]:                http://curl.haxx.se/libcurl/c/CURLOPT_SSL_CTX_DATA.html
[curl_ssl_sessionid_cache]:         http://curl.haxx.se/libcurl/c/CURLOPT_SSL_SESSIONID_CACHE.html
[curl_ssl_enable_npn]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_ENABLE_NPN.html
[curl_ssl_enable_alpn]:             http://curl.haxx.se/libcurl/c/CURLOPT_SSL_ENABLE_ALPN.html
[curl_ssl_verifystatus]:            http://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYSTATUS.html
[curl_ssl_falsestart]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_FALSESTART.html
[curl_crlfile]:                     http://curl.haxx.se/libcurl/c/CURLOPT_CRLFILE.html
[curl_issuercert]:                  http://curl.haxx.se/libcurl/c/CURLOPT_ISSUERCERT.html
[curl_certinfo]:                    http://curl.haxx.se/libcurl/c/CURLOPT_CERTINFO.html
[curl_prequote]:                    http://curl.haxx.se/libcurl/c/CURLOPT_PREQUOTE.html
[curl_debugfunction]:               http://curl.haxx.se/libcurl/c/CURLOPT_DEBUGFUNCTION.html
[curl_debugdata]:                   http://curl.haxx.se/libcurl/c/CURLOPT_DEBUGDATA.html
[curl_cookiesession]:               http://curl.haxx.se/libcurl/c/CURLOPT_COOKIESESSION.html
[curl_capath]:                      http://curl.haxx.se/libcurl/c/CURLOPT_CAPATH.html
[curl_buffersize]:                  http://curl.haxx.se/libcurl/c/CURLOPT_BUFFERSIZE.html
[curl_nosignal]:                    http://curl.haxx.se/libcurl/c/CURLOPT_NOSIGNAL.html
[curl_share]:                       http://curl.haxx.se/libcurl/c/CURLOPT_SHARE.html
[curl_accept_encoding]:             http://curl.haxx.se/libcurl/c/CURLOPT_ACCEPT_ENCODING.html
[curl_private]:                     http://curl.haxx.se/libcurl/c/CURLOPT_PRIVATE.html
[curl_unrestricted_auth]:           http://curl.haxx.se/libcurl/c/CURLOPT_UNRESTRICTED_AUTH.html
[curl_ipresolve]:                   http://curl.haxx.se/libcurl/c/CURLOPT_IPRESOLVE.html
[curl_maxfilesize]:                 http://curl.haxx.se/libcurl/c/CURLOPT_MAXFILESIZE.html
[curl_infilesize_large]:            http://curl.haxx.se/libcurl/c/CURLOPT_INFILESIZE_LARGE.html
[curl_resume_from_large]:           http://curl.haxx.se/libcurl/c/CURLOPT_RESUME_FROM_LARGE.html
[curl_maxfilesize_large]:           http://curl.haxx.se/libcurl/c/CURLOPT_MAXFILESIZE_LARGE.html
[curl_postfieldsize_large]:         http://curl.haxx.se/libcurl/c/CURLOPT_POSTFIELDSIZE_LARGE.html
[curl_tcp_nodelay]:                 http://curl.haxx.se/libcurl/c/CURLOPT_TCP_NODELAY.html
[curl_ftpsslauth]:                  http://curl.haxx.se/libcurl/c/CURLOPT_FTPSSLAUTH.html
[curl_ioctlfunction]:               http://curl.haxx.se/libcurl/c/CURLOPT_IOCTLFUNCTION.html
[curl_ioctldata]:                   http://curl.haxx.se/libcurl/c/CURLOPT_IOCTLDATA.html
[curl_cookielist]:                  http://curl.haxx.se/libcurl/c/CURLOPT_COOKIELIST.html
[curl_ignore_content_length]:       http://curl.haxx.se/libcurl/c/CURLOPT_IGNORE_CONTENT_LENGTH.html
[curl_ftpport]:                     http://curl.haxx.se/libcurl/c/CURLOPT_FTPPORT.html
[curl_ftp_use_eprt]:                http://curl.haxx.se/libcurl/c/CURLOPT_FTP_USE_EPRT.html
[curl_ftp_create_missing_dirs]:     http://curl.haxx.se/libcurl/c/CURLOPT_FTP_CREATE_MISSING_DIRS.html
[curl_ftp_response_timeout]:        http://curl.haxx.se/libcurl/c/CURLOPT_FTP_RESPONSE_TIMEOUT.html
[curl_ftp_use_epsv]:                http://curl.haxx.se/libcurl/c/CURLOPT_FTP_USE_EPSV.html
[curl_ftp_account]:                 http://curl.haxx.se/libcurl/c/CURLOPT_FTP_ACCOUNT.html
[curl_ftp_skip_pasv_ip]:            http://curl.haxx.se/libcurl/c/CURLOPT_FTP_SKIP_PASV_IP.html
[curl_ftp_filemethod]:              http://curl.haxx.se/libcurl/c/CURLOPT_FTP_FILEMETHOD.html
[curl_ftp_use_pret]:                http://curl.haxx.se/libcurl/c/CURLOPT_FTP_USE_PRET.html
[curl_ftp_ssl_ccc]:                 http://curl.haxx.se/libcurl/c/CURLOPT_FTP_SSL_CCC.html
[curl_ftp_alternative_to_user]:     http://curl.haxx.se/libcurl/c/CURLOPT_FTP_ALTERNATIVE_TO_USER.html
[curl_localport]:                   http://curl.haxx.se/libcurl/c/CURLOPT_LOCALPORT.html
[curl_localportrange]:              http://curl.haxx.se/libcurl/c/CURLOPT_LOCALPORTRANGE.html
[curl_connect_only]:                http://curl.haxx.se/libcurl/c/CURLOPT_CONNECT_ONLY.html
[curl_conv_from_network_function]:  http://curl.haxx.se/libcurl/c/CURLOPT_CONV_FROM_NETWORK_FUNCTION.html
[curl_conv_to_network_function]:    http://curl.haxx.se/libcurl/c/CURLOPT_CONV_TO_NETWORK_FUNCTION.html
[curl_conv_from_utf8_function]:     http://curl.haxx.se/libcurl/c/CURLOPT_CONV_FROM_UTF8_FUNCTION.html
[curl_opensocketfunction]:          http://curl.haxx.se/libcurl/c/CURLOPT_OPENSOCKETFUNCTION.html
[curl_opensocketdata]:              http://curl.haxx.se/libcurl/c/CURLOPT_OPENSOCKETDATA.html
[curl_closesocketfunction]:         http://curl.haxx.se/libcurl/c/CURLOPT_CLOSESOCKETFUNCTION.html
[curl_closesocketdata]:             http://curl.haxx.se/libcurl/c/CURLOPT_CLOSESOCKETDATA.html
[curl_sockoptfunction]:             http://curl.haxx.se/libcurl/c/CURLOPT_SOCKOPTFUNCTION.html
[curl_sockoptdata]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SOCKOPTDATA.html
[curl_ssh_auth_types]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSH_AUTH_TYPES.html
[curl_ssh_public_keyfile]:          http://curl.haxx.se/libcurl/c/CURLOPT_SSH_PUBLIC_KEYFILE.html
[curl_ssh_private_keyfile]:         http://curl.haxx.se/libcurl/c/CURLOPT_SSH_PRIVATE_KEYFILE.html
[curl_ssh_knownhosts]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSH_KNOWNHOSTS.html
[curl_ssh_keyfunction]:             http://curl.haxx.se/libcurl/c/CURLOPT_SSH_KEYFUNCTION.html
[curl_ssh_keydata]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SSH_KEYDATA.html
[curl_ssh_host_public_key_md5]:     http://curl.haxx.se/libcurl/c/CURLOPT_SSH_HOST_PUBLIC_KEY_MD5.html
[curl_new_file_perms]:              http://curl.haxx.se/libcurl/c/CURLOPT_NEW_FILE_PERMS.html
[curl_new_directory_perms]:         http://curl.haxx.se/libcurl/c/CURLOPT_NEW_DIRECTORY_PERMS.html
[curl_postredir]:                   http://curl.haxx.se/libcurl/c/CURLOPT_POSTREDIR.html
[curl_copypostfields]:              http://curl.haxx.se/libcurl/c/CURLOPT_COPYPOSTFIELDS.html
[curl_address_scope]:               http://curl.haxx.se/libcurl/c/CURLOPT_ADDRESS_SCOPE.html
[curl_username]:                    http://curl.haxx.se/libcurl/c/CURLOPT_USERNAME.html
[curl_password]:                    http://curl.haxx.se/libcurl/c/CURLOPT_PASSWORD.html
[curl_socks5_gssapi_service]:       http://curl.haxx.se/libcurl/c/CURLOPT_SOCKS5_GSSAPI_SERVICE.html
[curl_socks5_gssapi_nec]:           http://curl.haxx.se/libcurl/c/CURLOPT_SOCKS5_GSSAPI_NEC.html
[curl_interleavedata]:              http://curl.haxx.se/libcurl/c/CURLOPT_INTERLEAVEDATA.html
[curl_interleavefunction]:          http://curl.haxx.se/libcurl/c/CURLOPT_INTERLEAVEFUNCTION.html
[curl_chunk_bgn_function]:          http://curl.haxx.se/libcurl/c/CURLOPT_CHUNK_BGN_FUNCTION.html
[curl_chunk_end_function]:          http://curl.haxx.se/libcurl/c/CURLOPT_CHUNK_END_FUNCTION.html
[curl_chunk_data]:                  http://curl.haxx.se/libcurl/c/CURLOPT_CHUNK_DATA.html
[curl_fnmatch_function]:            http://curl.haxx.se/libcurl/c/CURLOPT_FNMATCH_FUNCTION.html
[curl_fnmatch_data]:                http://curl.haxx.se/libcurl/c/CURLOPT_FNMATCH_DATA.html
[curl_resolve]:                     http://curl.haxx.se/libcurl/c/CURLOPT_RESOLVE.html
[curl_wildcardmatch]:               http://curl.haxx.se/libcurl/c/CURLOPT_WILDCARDMATCH.html
[curl_tlsauth_username]:            http://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_USERNAME.html
[curl_tlsauth_password]:            http://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_PASSWORD.html
[curl_tlsauth_type]:                http://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_TYPE.html
[curl_transfer_encoding]:           http://curl.haxx.se/libcurl/c/CURLOPT_TRANSFER_ENCODING.html
[curl_gssapi_delegation]:           http://curl.haxx.se/libcurl/c/CURLOPT_GSSAPI_DELEGATION.html
[curl_tcp_keepalive]:               http://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPALIVE.html
[curl_tcp_keepidle]:                http://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPIDLE.html
[curl_tcp_keepintvl]:               http://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPINTVL.html
[curl_mail_from]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAIL_FROM.html
[curl_mail_rcpt]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAIL_RCPT.html
[curl_mail_auth]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAIL_AUTH.html
[curl_tftp_blksize]:                http://curl.haxx.se/libcurl/c/CURLOPT_TFTP_BLKSIZE.html
[curl_rtsp_request]:                http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_REQUEST.html
[curl_rtsp_session_id]:             http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_SESSION_ID.html
[curl_rtsp_stream_uri]:             http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_STREAM_URI.html
[curl_rtsp_transport]:              http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_TRANSPORT.html
[curl_rtsp_client_cseq]:            http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_CLIENT_CSEQ.html
[curl_rtsp_server_cseq]:            http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_SERVER_CSEQ.html
[curl_netrc]:                       http://curl.haxx.se/libcurl/c/CURLOPT_NETRC.html
[curl_netrc_file]:                  http://curl.haxx.se/libcurl/c/CURLOPT_NETRC_FILE.html
[curl_dns_servers]:                 http://curl.haxx.se/libcurl/c/CURLOPT_DNS_SERVERS.html
[curl_dns_interface]:               http://curl.haxx.se/libcurl/c/CURLOPT_DNS_INTERFACE.html
[curl_dns_local_ip4]:               http://curl.haxx.se/libcurl/c/CURLOPT_DNS_LOCAL_IP4.html
[curl_dns_local_ip6]:               http://curl.haxx.se/libcurl/c/CURLOPT_DNS_LOCAL_IP6.html
[curl_dns_use_global_cache]:        http://curl.haxx.se/libcurl/c/CURLOPT_DNS_USE_GLOBAL_CACHE.html
[curl_dns_cache_timeout]:           http://curl.haxx.se/libcurl/c/CURLOPT_DNS_CACHE_TIMEOUT.html
[curl_login_options]:               http://curl.haxx.se/libcurl/c/CURLOPT_LOGIN_OPTIONS.html
[curl_expect_100_timeout_ms]:       http://curl.haxx.se/libcurl/c/CURLOPT_EXPECT_100_TIMEOUT_MS.html
[curl_headeropt]:                   http://curl.haxx.se/libcurl/c/CURLOPT_HEADEROPT.html
[curl_pinnedpublickey]:             http://curl.haxx.se/libcurl/c/CURLOPT_PINNEDPUBLICKEY.html
[curl_unix_socket_path]:            http://curl.haxx.se/libcurl/c/CURLOPT_UNIX_SOCKET_PATH.html
[curl_path_as_is]:                  http://curl.haxx.se/libcurl/c/CURLOPT_PATH_AS_IS.html
[curl_service_name]:                http://curl.haxx.se/libcurl/c/CURLOPT_SERVICE_NAME.html
[curl_pipewait]:                    http://curl.haxx.se/libcurl/c/CURLOPT_PIPEWAIT.html
[curl_sasl_ir]:                     http://curl.haxx.se/libcurl/c/CURLOPT_SASL_IR.html
[curl_xoauth2_bearer]:              http://curl.haxx.se/libcurl/c/CURLOPT_XOAUTH2_BEARER.html
[curl_xferinfofunction]:            http://curl.haxx.se/libcurl/c/CURLOPT_XFERINFOFUNCTION.html
[curl_xferinfodata]:                http://curl.haxx.se/libcurl/c/CURLOPT_XFERINFODATA.html
