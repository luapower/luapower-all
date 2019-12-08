---
tagline: URL transfers
---

## `local curl = require'libcurl'`

[libcurl](http://curl.haxx.se/libcurl/) is a client-side URL transfer
library, supporting DICT, FILE, FTP, FTPS, Gopher, HTTP, HTTPS, IMAP,
IMAPS, LDAP, LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMTP, SMTPS,
Telnet and TFTP. libcurl supports SSL certificates, HTTP POST, HTTP PUT,
FTP uploading, HTTP form based upload, proxies, cookies, user+password
authentication (Basic, Digest, NTLM, Negotiate, Kerberos),
file transfer resume, http proxy tunneling and more!

## API

-------------------------------------------------------- --------------------------------------------------------
__easy interface__

`curl.easy(url | {opt=val}) -> etr`                      [create][curl_easy_init] an [easy transfer][libcurl-easy]

`etr:set(opt,val | {opt=val}) -> etr`                    [set option(s)][curl_easy_setopt]

`etr:perform() -> etr | nil,err,ecode`                   [perform the transfer][curl_easy_perform]

`etr:close()`                                            [close the transfer][curl_easy_cleanup]

`etr:clone([url | {opt=val}]) -> etr`                    [clone a transfer][curl_easy_duphandle]

`etr:reset([{opt=val}]) -> etr`                          [reset all options to their default values][curl_easy_reset]

`etr:info(opt) -> val`                                   [get info about the transfer][curl_easy_getinfo]

`etr:recv(buf, bufsize) -> n | nil,err,errcode`          [receive raw data][curl_easy_recv]

`etr:send(buf, bufsize) -> n | nil,err,errcode`          [send raw data][curl_easy_send]

`etr:escape(s) -> s|nil`                                 [escape URL][curl_easy_escape]

`etr:unescape(s) -> s|nil`                               [unescape URL][curl_easy_unescape]

`etr:pause([flags])`                                     [pause transfer][curl_easy_pause]

__multi interface__

`curl.multi([{opt=val}]) -> mtr`                         [create][curl_multi_init] a [multi transfer][libcurl-multi]

`mtr:set(opt,val | {opt=val}) -> mtr`                    [set option(s)][curl_multi_setopt]

`mtr:add(etr) -> mtr`                                    [add an easy transfer to the queue][curl_multi_add_handle]

`mtr:remove(etr) -> mtr`                                 [remove an easy transfer to the queue][curl_multi_remove_handle]

`mtr:perform() -> transfers_left | nil,err,ecode`        [start/keep transfering][curl_multi_perform]

`mtr:close()`                                            [close the transfer][curl_multi_cleanup]

`mtr:wait([timeout_seconds], [extra_fds, extra_nfds])    [poll on all handles][curl_multi_wait]
-> numfds | nil,err,errcode`

`mtr:fdset(read_fd_set, write_fd_set, exc_fd_set)        [get file descriptors][curl_multi_fdset]
-> max_fd | nil,err,errcode`

`mtr:timeout() -> seconds | nil`                         [how long to wait for socket actions][curl_multi_timeout]

`mtr:info_read() -> CURLMsg*|nil, msgs_in_queue`         [read multi stack info][curl_multi_info_read]

`mtr:socket_action()`                                    [read/write available data given an action][curl_multi_socket_action]

`mtr:assign(sockfd, p) -> mtr`                           [set data to associate with an internal socket][curl_multi_assign]

__share interface__

`curl.share([{opt=val}]) -> shr`                         [create][curl_share_init] a [share object][libcurl-share]

`shr:set(opt,val | {opt=val}) -> shr`                    [set option(s)][curl_share_setopt]

`shr:free()`                                             [free the share object][curl_share_cleanup]

__multipart forms__

`curl.form() -> frm`                                     [create a multipart form][curl_formadd]

`frm:add(opt1, val1, ...) -> frm`                        [add a section to a multipart form][curl_formadd]

`frm:get() -> s`                                         [get a multipart form as string][curl_formget]

`frm:get(out_t) -> out_t`                                [get a multipart form as an array of strings][curl_formget]

`frm:get(function(buf, len) end)`                        [get a multipart form to a callback][curl_formget]

__misc.__

`curl.C`                                                 the libcurl ffi clib object/namespace

`curl.init([opt])`													[global init][curl_global_init]

`curl.init{malloc=,free=,realloc=...}`							[global init with custom allocators][curl_global_init_mem]

`curl.free()`                                            [global cleanup][curl_global_cleanup]

`curl.version() -> s`                                    [get version info as a string][curl_version]

`curl.version_info([ver]) -> t`                          [get detailed version info as a table][curl_version_info]

`curl.checkver(maj[, min[, patch]]) -> true|false`       check if CURL version is >= maj.min.patch

`curl.getdate(s) -> timestamp`                           [parse a date/time to a Unix timestamp][curl_getdate]

`curl.easy.strerror(errcode) -> errmsg`                  [look-up an easy interface error code][curl_easy_strerror]

`curl.multi.strerror(errcode) -> errmsg`                 [look-up a multi interface error code][curl_multi_strerror]

`curl.share.strerror(errcode) -> errmsg`                 [look-up a share interface error code][curl_share_strerror]

`curl.type(x) -> 'easy'|'multi'|'share'|nil`             get curl object type
-------------------------------------------------------- --------------------------------------------------------

[libcurl-easy]:             http://curl.haxx.se/libcurl/c/libcurl-easy.html
[curl_easy_init]:           http://curl.haxx.se/libcurl/c/curl_easy_init.html
[curl_easy_setopt]:         http://curl.haxx.se/libcurl/c/curl_easy_setopt.html
[curl_easy_perform]:        http://curl.haxx.se/libcurl/c/curl_easy_perform.html
[curl_easy_cleanup]:        http://curl.haxx.se/libcurl/c/curl_easy_cleanup.html
[curl_easy_duphandle]:      http://curl.haxx.se/libcurl/c/curl_easy_duphandle.html
[curl_easy_reset]:          http://curl.haxx.se/libcurl/c/curl_easy_reset.html
[curl_easy_getinfo]:        http://curl.haxx.se/libcurl/c/curl_easy_getinfo.html
[curl_easy_recv]:           http://curl.haxx.se/libcurl/c/curl_easy_recv.html
[curl_easy_send]:           http://curl.haxx.se/libcurl/c/curl_easy_send.html
[curl_easy_escape]:         http://curl.haxx.se/libcurl/c/curl_easy_escape.html
[curl_easy_unescape]:       http://curl.haxx.se/libcurl/c/curl_easy_unescape.html
[curl_easy_pause]:          http://curl.haxx.se/libcurl/c/curl_easy_pause.html

[libcurl-multi]:            http://curl.haxx.se/libcurl/c/libcurl-multi.html
[curl_multi_init]:          http://curl.haxx.se/libcurl/c/curl_multi_init.html
[curl_multi_setopt]:        http://curl.haxx.se/libcurl/c/curl_multi_setopt.html
[curl_multi_add_handle]:    http://curl.haxx.se/libcurl/c/curl_multi_add_handle.html
[curl_multi_remove_handle]: http://curl.haxx.se/libcurl/c/curl_multi_remove_handle.html
[curl_multi_perform]:       http://curl.haxx.se/libcurl/c/curl_multi_perform.html
[curl_multi_cleanup]:       http://curl.haxx.se/libcurl/c/curl_multi_cleanup.html
[curl_multi_wait]:          http://curl.haxx.se/libcurl/c/curl_multi_wait.html
[curl_multi_fdset]:         http://curl.haxx.se/libcurl/c/curl_multi_fdset.html
[curl_multi_timeout]:       http://curl.haxx.se/libcurl/c/curl_multi_timeout.html
[curl_multi_info_read]:     http://curl.haxx.se/libcurl/c/curl_multi_info_read.html
[curl_multi_socket_action]: http://curl.haxx.se/libcurl/c/curl_multi_socket_action.html
[curl_multi_assign]:        http://curl.haxx.se/libcurl/c/curl_multi_assign.html

[libcurl-share]:            http://curl.haxx.se/libcurl/c/libcurl-share.html
[curl_share_init]:          http://curl.haxx.se/libcurl/c/curl_share_init.html
[curl_share_cleanup]:       http://curl.haxx.se/libcurl/c/curl_share_cleanup.html
[curl_share_setopt]:        http://curl.haxx.se/libcurl/c/curl_share_setopt.html

[curl_formadd]:             http://curl.haxx.se/libcurl/c/curl_formadd.html
[curl_formget]:             http://curl.haxx.se/libcurl/c/curl_formget.html

[curl_global_init]:         http://curl.haxx.se/libcurl/c/curl_global_init.html
[curl_global_init_mem]:     http://curl.haxx.se/libcurl/c/curl_global_init_mem.html
[curl_global_cleanup]:      http://curl.haxx.se/libcurl/c/curl_global_cleanup.html
[curl_version]:             http://curl.haxx.se/libcurl/c/curl_version.html
[curl_version_info]:        http://curl.haxx.se/libcurl/c/curl_version_info.html
[curl_getdate]:             http://curl.haxx.se/libcurl/c/curl_getdate.html
[curl_easy_strerror]:       http://curl.haxx.se/libcurl/c/curl_easy_strerror.html
[curl_multi_strerror]:      http://curl.haxx.se/libcurl/c/curl_multi_strerror.html
[curl_share_strerror]:      http://curl.haxx.se/libcurl/c/curl_share_strerror.html

## Easy vs multi interface

The [easy interface][libcurl-easy] is synchronous while the
[multi interface][libcurl-multi] can do multiple transfers asynchronously.
A multi transfer is set up as a list of easy transfers.

## Easy interface

### `curl.easy(url | {opt=val}) -> etr`

Create a transfer using the [easy interface][libcurl-easy]. Options are below
(they also go for `etr:set()`). All options are assumed immutable and the
option values are anchored internally for the lifetime of the transfer object.

How option values are converted:

* `long` options can be given as Lua numbers.
* `char*` options can be given as Lua strings (anchored).
* `off_t` options can be given as Lua numbers (no need for the `_long` suffix).
* Enum options can be given as strings (case-insensitive, no prefix).
* Bitmask options can be given as tables of form `{mask_name = true|false}`
(again, the mask name follows the C name but case-insensitive and without
the prefix).
* `curl_slist` options can be given as lists of strings (anchored).
* Callbacks can be given as Lua functions (anchored). The ffi callback objects
are freed on `etr:free()` (*).

> (*) Callback objects are ref-counted which means that replacing them on
cloned transfers does not result in double-frees, and freeing them is
deterministic, which is important since their number is hard-limited.

----------------------------- --------------------------------------------------------------------
__Main options__
`url`                         [URL to work on.][curlopt_url]
`protocols`                   [Allowed protocols.][curlopt_protocols]
`redir_protocols`             [Protocols to allow redirects to.][curlopt_redir_protocols]
`default_protocol`            [Default protocol.][curlopt_default_protocol]
`port`                        [Port number to connect to.][curlopt_port]
`range`                       [Request range: "X-Y,N-M,...".][curlopt_range]
`resume_from`                 [Resume transfer from offset.][curlopt_resume_from_large]
`header`                      [Include the header in the body output.][curlopt_header]
`maxfilesize`                 [Max. file size to get.][curlopt_maxfilesize_large]
`upload`                      [Enable data upload.][curlopt_upload]
`infilesize`                  [Size of file to send.][curlopt_infilesize_large]
`timecondition`               [Make a time-conditional request.][curlopt_timecondition]
`timevalue`                   [Timestamp for conditional request.][curlopt_timevalue]
__Progress Tracking__
`noprogress`                  [Shut off the progress meter.][curlopt_noprogress]
`progressfunction`            [OBSOLETE callback for progress meter.][curlopt_progressfunction]
`progressdata`                [Data pointer to pass to the progress meter callback.][curlopt_progressdata]
`xferinfofunction`            [Callback for progress meter.][curlopt_xferinfofunction]
`xferinfodata`                [Data pointer to pass to the progress meter callback.][curlopt_xferinfodata]
__Error Handling__
`verbose`                     [Display verbose information.][curlopt_verbose]
`stderr`                      [stderr replacement stream.][curlopt_stderr]
`errorbuffer`                 [Error message buffer.][curlopt_errorbuffer]
`failonerror`                 [Fail on HTTP 4xx errors.][curlopt_failonerror]
__Proxies__
`proxy`                       [Proxy to use.][curlopt_proxy]
`proxyport`                   [Proxy port to use.][curlopt_proxyport]
`proxytype`                   [Proxy type.][curlopt_proxytype]
`noproxy`                     [Filter out hosts from proxy use.][curlopt_noproxy]
`httpproxytunnel`             [Tunnel through the HTTP proxy.][curlopt_httpproxytunnel]
`socks5_gssapi_service`       [Socks5 GSSAPI service name.][curlopt_socks5_gssapi_service]
`socks5_gssapi_nec`           [Socks5 GSSAPI NEC mode.][curlopt_socks5_gssapi_nec]
`proxy_service_name`          [Proxy service name.][curlopt_proxy_service_name]
__I/O Callbacks__
`writefunction`               [Callback for writing data.][curlopt_writefunction]
`writedata`                   [Data pointer to pass to the write callback.][curlopt_writedata]
`readfunction`                [Callback for reading data.][curlopt_readfunction]
`readdata`                    [Data pointer to pass to the read callback.][curlopt_readdata]
`seekfunction`                [Callback for seek operations.][curlopt_seekfunction]
`seekdata`                    [Data pointer to pass to the seek callback.][curlopt_seekdata]
__Speed Limits__
`low_speed_limit`             [Low speed limit to abort transfer.][curlopt_low_speed_limit]
`low_speed_time`              [Time to be below the speed to trigger low speed abort.][curlopt_low_speed_time]
`max_send_speed`              [Cap the upload speed.][curlopt_max_send_speed_large]
`max_recv_speed`              [Cap the download speed.][curlopt_max_recv_speed_large]
__Authentication__
`netrc`                       [Enable .netrc parsing.][curlopt_netrc]
`netrc_file`                  [.netrc file name.][curlopt_netrc_file]
`userpwd`                     [User name and password.][curlopt_userpwd]
`proxyuserpwd`                [Proxy user name and password.][curlopt_proxyuserpwd]
`username`                    [User name.][curlopt_username]
`password`                    [Password.][curlopt_password]
`login_options`               [Login options.][curlopt_login_options]
`proxyusername`               [Proxy user name.][curlopt_proxyusername]
`proxypassword`               [Proxy password.][curlopt_proxypassword]
`httpauth`                    [HTTP server authentication methods.][curlopt_httpauth]
`tlsauth_username`            [TLS authentication user name.][curlopt_tlsauth_username]
`tlsauth_password`            [TLS authentication password.][curlopt_tlsauth_password]
`tlsauth_type`                [TLS authentication methods.][curlopt_tlsauth_type]
`proxyauth`                   [HTTP proxy authentication methods.][curlopt_proxyauth]
`sasl_ir`                     [Enable SASL initial response.][curlopt_sasl_ir]
`xoauth2_bearer`              [OAuth2 bearer token.][curlopt_xoauth2_bearer]
__HTTP Protocol__
`autoreferer`                 [Automatically set Referer: header.][curlopt_autoreferer]
`accept_encoding`             [Accept-Encoding and automatic decompressing data.][curlopt_accept_encoding]
`transfer_encoding`           [Request Transfer-Encoding.][curlopt_transfer_encoding]
`followlocation`              [Follow HTTP redirects.][curlopt_followlocation]
`unrestricted_auth`           [Do not restrict authentication to original host.][curlopt_unrestricted_auth]
`maxredirs`                   [Maximum number of redirects to follow.][curlopt_maxredirs]
`postredir`                   [How to act on redirects after POST.][curlopt_postredir]
`put`                         [Issue a HTTP PUT request.][curlopt_put]
`post`                        [Issue a HTTP POST request.][curlopt_post]
`httpget`                     [Do a HTTP GET request.][curlopt_httpget]
`postfields`                  [Send a POST with this data.][curlopt_postfields]
`postfieldsize`               [The POST data is this big.][curlopt_postfieldsize_large]
`copypostfields`              [Send a POST with this data - and copy it.][curlopt_copypostfields]
`httppost`                    [Multipart formpost HTTP POST.][curlopt_httppost]
`referer`                     [Referer: header.][curlopt_referer]
`useragent`                   [User-Agent: header.][curlopt_useragent]
`httpheader`                  [Custom HTTP headers.][curlopt_httpheader]
`headeropt`                   [Control custom headers. ][curlopt_headeropt]
`proxyheader`                 [Custom HTTP headers sent to proxy.][curlopt_proxyheader]
`http200aliases`              [Alternative versions of 200 OK.][curlopt_http200aliases]
`cookie`                      [Cookie(s) to send.][curlopt_cookie]
`cookiefile`                  [File to read cookies from.][curlopt_cookiefile]
`cookiejar`                   [File to write cookies to.][curlopt_cookiejar]
`cookiesession`               [Start a new cookie session.][curlopt_cookiesession]
`cookielist`                  [Add or control cookies.][curlopt_cookielist]
`http_version`                [HTTP version to use.][curlopt_http_version]
`ignore_content_length`       [Ignore Content-Length.][curlopt_ignore_content_length]
`http_content_decoding`       [Disable Content decoding.][curlopt_http_content_decoding]
`http_transfer_decoding`      [Disable Transfer decoding.][curlopt_http_transfer_decoding]
`expect_100_timeout_ms`       [100-continue timeout in ms.][curlopt_expect_100_timeout_ms]
`pipewait`                    [Wait on connection to pipeline on it.][curlopt_pipewait]
__Connection__
`interface`                   [Bind connection locally to this.][curlopt_interface]
`localport`                   [Bind connection locally to this port.][curlopt_localport]
`localportrange`              [Bind connection locally to port range.][curlopt_localportrange]
`tcp_nodelay`                 [Disable the Nagle algorithm.][curlopt_tcp_nodelay]
`tcp_keepalive`               [Enable TCP keep-alive.][curlopt_tcp_keepalive]
`tcp_keepidle`                [Idle time before sending keep-alive.][curlopt_tcp_keepidle]
`tcp_keepintvl`               [Interval between keep-alive probes.][curlopt_tcp_keepintvl]
`address_scope`               [IPv6 scope for local addresses.][curlopt_address_scope]
`unix_socket_path`            [Path to a Unix domain socket.][curlopt_unix_socket_path]
`dns_interface`               [Bind name resolves to an interface.][curlopt_dns_interface]
`dns_cache_timeout`           [Timeout for DNS cache.][curlopt_dns_cache_timeout]
`dns_local_ip4`               [Bind name resolves to an IP4 address.][curlopt_dns_local_ip4]
`dns_local_ip6`               [Bind name resolves to an IP6 address.][curlopt_dns_local_ip6]
`dns_servers`                 [Preferred DNS servers.][curlopt_dns_servers]
`dns_use_global_cache`        [OBSOLETE Enable global DNS cache.][curlopt_dns_use_global_cache]
`timeout`                     [Timeout for the entire request in seconds.][curlopt_timeout]
`timeout_ms`                  [Timeout for the entire request in ms.][curlopt_timeout_ms]
`connecttimeout`              [Timeout for the connection phase in seconds.][curlopt_connecttimeout]
`connecttimeout_ms`           [Timeout for the connection phase in ms.][curlopt_connecttimeout_ms]
`accepttimeout_ms`            [Timeout for a connection be accepted.][curlopt_accepttimeout_ms]
`server_response_timeout`     [][curlopt_server_response_timeout]
`fresh_connect`               [Use a new connection.][curlopt_fresh_connect]
`forbid_reuse`                [Prevent subsequent connections from re-using this connection.][curlopt_forbid_reuse]
`connect_only`                [Only connect, nothing else.][curlopt_connect_only]
`resolve`                     [Provide fixed/fake name resolves.][curlopt_resolve]
`conv_from_network_function`  [Callback for code base conversion.][curlopt_conv_from_network_function]
`conv_to_network_function`    [Callback for code base conversion.][curlopt_conv_to_network_function]
`conv_from_utf8_function`     [Callback for code base conversion.][curlopt_conv_from_utf8_function]
`opensocketfunction`          [][curlopt_opensocketfunction]
`opensocketdata`              [][curlopt_opensocketdata]
`closesocketfunction`         [][curlopt_closesocketfunction]
`closesocketdata`             [][curlopt_closesocketdata]
`sockoptfunction`             [Callback for sockopt operations.][curlopt_sockoptfunction]
`sockoptdata`                 [Data pointer to pass to the sockopt callback.][curlopt_sockoptdata]
__SSH Protocol__
`ssh_auth_types`              [SSH authentication types.][curlopt_ssh_auth_types]
`ssh_public_keyfile`          [File name of public key.][curlopt_ssh_public_keyfile]
`ssh_private_keyfile`         [File name of private key.][curlopt_ssh_private_keyfile]
`ssh_knownhosts`              [File name with known hosts.][curlopt_ssh_knownhosts]
`ssh_keyfunction`             [Callback for known hosts handling.][curlopt_ssh_keyfunction]
`ssh_keydata`                 [Custom pointer to pass to ssh key callback.][curlopt_ssh_keydata]
`ssh_host_public_key_md5`     [MD5 of host's public key.][curlopt_ssh_host_public_key_md5]
__SMTP Protocol__
`mail_from`                   [Address of the sender.][curlopt_mail_from]
`mail_rcpt`                   [Address of the recipients.][curlopt_mail_rcpt]
`mail_auth`                   [Authentication address.][curlopt_mail_auth]
__TFTP Protocol__
`tftp_blksize`                [TFTP block size.][curlopt_tftp_blksize]
__SSL__
`use_ssl`                     [Use TLS/SSL.][curlopt_use_ssl]
`sslcert`                     [Client cert.][curlopt_sslcert]
`sslversion`                  [SSL version to use.][curlopt_sslversion]
`sslcerttype`                 [Client cert type.][curlopt_sslcerttype]
`sslkey`                      [Client key.][curlopt_sslkey]
`sslkeytype`                  [Client key type.][curlopt_sslkeytype]
`keypasswd`                   [Client key password.][curlopt_keypasswd]
`sslengine`                   [Use identifier with SSL engine.][curlopt_sslengine]
`sslengine_default`           [Default SSL engine.][curlopt_sslengine_default]
`ssl_options`                 [Control SSL behavior.][curlopt_ssl_options]
`ssl_falsestart`              [Enable TLS False Start.][curlopt_ssl_falsestart]
`ssl_cipher_list`             [Ciphers to use.][curlopt_ssl_cipher_list]
`ssl_verifyhost`              [Verify the host name in the SSL certificate.][curlopt_ssl_verifyhost]
`ssl_verifypeer`              [Verify the SSL certificate.][curlopt_ssl_verifypeer]
`ssl_verifystatus`            [Verify the SSL certificate's status.][curlopt_ssl_verifystatus]
`ssl_ctx_function`            [Callback for SSL context logic.][curlopt_ssl_ctx_function]
`ssl_ctx_data`                [Data pointer to pass to the SSL context callback.][curlopt_ssl_ctx_data]
`ssl_sessionid_cache`         [Disable SSL session-id cache.][curlopt_ssl_sessionid_cache]
`ssl_enable_npn`              [][curlopt_ssl_enable_npn]
`ssl_enable_alpn`             [][curlopt_ssl_enable_alpn]
`cainfo`                      [CA cert bundle.][curlopt_cainfo]
`capath`                      [Path to CA cert bundle.][curlopt_capath]
`crlfile`                     [Certificate Revocation List.][curlopt_crlfile]
`issuercert`                  [Issuer certificate.][curlopt_issuercert]
`certinfo`                    [Extract certificate info.][curlopt_certinfo]
`pinnedpublickey`             [Set pinned SSL public key.][curlopt_pinnedpublickey]
`krblevel`                    [Kerberos security level.][curlopt_krblevel]
`random_file`                 [Provide source for entropy random data.][curlopt_random_file]
`egdsocket`                   [Identify EGD socket for entropy.][curlopt_egdsocket]
`gssapi_delegation`           [Disable GSS-API delegation. ][curlopt_gssapi_delegation]
__FTP Protocol__
`ftpport`                     [Use active FTP.][curlopt_ftpport]
`quote`                       [Commands to run before transfer.][curlopt_quote]
`postquote`                   [Commands to run after transfer.][curlopt_postquote]
`prequote`                    [Commands to run just before transfer.][curlopt_prequote]
`append`                      [Append to remote file.][curlopt_append]
`ftp_use_eprt`                [Use EPTR.][curlopt_ftp_use_eprt]
`ftp_use_epsv`                [Use EPSV.][curlopt_ftp_use_epsv]
`ftp_use_pret`                [Use PRET.][curlopt_ftp_use_pret]
`ftp_create_missing_dirs`     [Create missing directories on the remote server.][curlopt_ftp_create_missing_dirs]
`ftp_response_timeout`        [Timeout for FTP responses.][curlopt_ftp_response_timeout]
`ftp_alternative_to_user`     [Alternative to USER.][curlopt_ftp_alternative_to_user]
`ftp_skip_pasv_ip`            [Ignore the IP address in the PASV response.][curlopt_ftp_skip_pasv_ip]
`ftpsslauth`                  [Control how to do TLS.][curlopt_ftpsslauth]
`ftp_ssl_ccc`                 [Back to non-TLS again after authentication. ][curlopt_ftp_ssl_ccc]
`ftp_account`                 [Send ACCT command.][curlopt_ftp_account]
`ftp_filemethod`              [Specify how to reach files.][curlopt_ftp_filemethod]
`transfertext`                [Use text transfer.][curlopt_transfertext]
`proxy_transfer_mode`         [Add transfer mode to URL over proxy.][curlopt_proxy_transfer_mode]
__RTSP Protocol__
`rtsp_request`                [RTSP request.][curlopt_rtsp_request]
`rtsp_session_id`             [RTSP session-id.][curlopt_rtsp_session_id]
`rtsp_stream_uri`             [RTSP stream URI.][curlopt_rtsp_stream_uri]
`rtsp_transport`              [RTSP Transport:][curlopt_rtsp_transport]
`rtsp_client_cseq`            [Client CSEQ number.][curlopt_rtsp_client_cseq]
`rtsp_server_cseq`            [CSEQ number for RTSP Server->Client request.][curlopt_rtsp_server_cseq]
`interleavefunction`          [Callback for RTSP interleaved data.][curlopt_interleavefunction]
`interleavedata`              [Data pointer to pass to the RTSP interleave callback.][curlopt_interleavedata]
__Misc. Options__
`path_as_is`                  [Disable squashing /../ and /./ sequences in the path.][curlopt_path_as_is]
`buffersize`                  [Ask for smaller buffer size.][curlopt_buffersize]
`nosignal`                    [Do not install signal handlers.][curlopt_nosignal]
`share`                       [Share object to use.][curlopt_share]
`private`                     [Private pointer to store.][curlopt_private]
`ipresolve`                   [IP version to resolve to.][curlopt_ipresolve]
`ioctlfunction`               [Callback for I/O operations.][curlopt_ioctlfunction]
`ioctldata`                   [Data pointer to pass to the I/O callback.][curlopt_ioctldata]
`service_name`                [SPNEGO service name.][curlopt_service_name]
`crlf`                        [Convert newlines.][curlopt_crlf]
`customrequest`               [Custom request/method.][curlopt_customrequest]
`filetime`                    [Request file modification date and time.][curlopt_filetime]
`dirlistonly`                 [List only.][curlopt_dirlistonly]
`nobody`                      [Do not get the body contents.][curlopt_nobody]
`new_file_perms`              [Mode for creating new remote files.][curlopt_new_file_perms]
`new_directory_perms`         [Mode for creating new remote directories.][curlopt_new_directory_perms]
`chunk_bgn_function`          [Callback for wildcard download start of chunk.][curlopt_chunk_bgn_function]
`chunk_end_function`          [Callback for wildcard download end of chunk.][curlopt_chunk_end_function]
`chunk_data`                  [Data pointer to pass to the chunk callbacks.][curlopt_chunk_data]
`fnmatch_function`            [Callback for wildcard matching.][curlopt_fnmatch_function]
`fnmatch_data`                [Data pointer to pass to the wildcard matching callback.][curlopt_fnmatch_data]
`wildcardmatch`               [Transfer multiple files according to a file name pattern.][curlopt_wildcardmatch]
`telnetoptions`               [TELNET options.][curlopt_telnetoptions]
`maxconnects`                 [Maximum number of connections in the connection pool.][curlopt_maxconnects]
`headerfunction`              [Callback for writing received headers.][curlopt_headerfunction]
`headerdata`                  [Data pointer to pass to the header callback.][curlopt_headerdata]
__Debugging__
`debugfunction`               [Callback for debug information.][curlopt_debugfunction]
`debugdata`                   [Data pointer to pass to the debug callback.][curlopt_debugdata]
----------------------------- --------------------------------------------------------------------

[curlopt_url]:                         http://curl.haxx.se/libcurl/c/CURLOPT_URL.html
[curlopt_protocols]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROTOCOLS.html
[curlopt_default_protocol]:            http://curl.haxx.se/libcurl/c/CURLOPT_DEFAULT_PROTOCOL.html
[curlopt_redir_protocols]:             http://curl.haxx.se/libcurl/c/CURLOPT_REDIR_PROTOCOLS.html
[curlopt_port]:                        http://curl.haxx.se/libcurl/c/CURLOPT_PORT.html
[curlopt_userpwd]:                     http://curl.haxx.se/libcurl/c/CURLOPT_USERPWD.html
[curlopt_range]:                       http://curl.haxx.se/libcurl/c/CURLOPT_RANGE.html
[curlopt_referer]:                     http://curl.haxx.se/libcurl/c/CURLOPT_REFERER.html
[curlopt_useragent]:                   http://curl.haxx.se/libcurl/c/CURLOPT_USERAGENT.html
[curlopt_postfields]:                  http://curl.haxx.se/libcurl/c/CURLOPT_POSTFIELDS.html
[curlopt_cookie]:                      http://curl.haxx.se/libcurl/c/CURLOPT_COOKIE.html
[curlopt_cookiefile]:                  http://curl.haxx.se/libcurl/c/CURLOPT_COOKIEFILE.html
[curlopt_post]:                        http://curl.haxx.se/libcurl/c/CURLOPT_POST.html
[curlopt_put]:                         http://curl.haxx.se/libcurl/c/CURLOPT_PUT.html
[curlopt_header]:                      http://curl.haxx.se/libcurl/c/CURLOPT_HEADER.html
[curlopt_headerdata]:                  http://curl.haxx.se/libcurl/c/CURLOPT_HEADERDATA.html
[curlopt_nobody]:                      http://curl.haxx.se/libcurl/c/CURLOPT_NOBODY.html
[curlopt_followlocation]:              http://curl.haxx.se/libcurl/c/CURLOPT_FOLLOWLOCATION.html
[curlopt_timeout]:                     http://curl.haxx.se/libcurl/c/CURLOPT_TIMEOUT.html
[curlopt_timeout_ms]:                  http://curl.haxx.se/libcurl/c/CURLOPT_TIMEOUT_MS.html
[curlopt_connecttimeout]:              http://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT.html
[curlopt_connecttimeout_ms]:           http://curl.haxx.se/libcurl/c/CURLOPT_CONNECTTIMEOUT_MS.html
[curlopt_accepttimeout_ms]:            http://curl.haxx.se/libcurl/c/CURLOPT_ACCEPTTIMEOUT_MS.html
[curlopt_server_response_timeout]:     http://curl.haxx.se/libcurl/c/CURLOPT_SERVER_RESPONSE_TIMEOUT.html
[curlopt_noprogress]:                  http://curl.haxx.se/libcurl/c/CURLOPT_NOPROGRESS.html
[curlopt_progressfunction]:            http://curl.haxx.se/libcurl/c/CURLOPT_PROGRESSFUNCTION.html
[curlopt_progressdata]:                http://curl.haxx.se/libcurl/c/CURLOPT_PROGRESSDATA.html
[curlopt_verbose]:                     http://curl.haxx.se/libcurl/c/CURLOPT_VERBOSE.html
[curlopt_stderr]:                      http://curl.haxx.se/libcurl/c/CURLOPT_STDERR.html
[curlopt_errorbuffer]:                 http://curl.haxx.se/libcurl/c/CURLOPT_ERRORBUFFER.html
[curlopt_failonerror]:                 http://curl.haxx.se/libcurl/c/CURLOPT_FAILONERROR.html
[curlopt_proxy]:                       http://curl.haxx.se/libcurl/c/CURLOPT_PROXY.html
[curlopt_proxytype]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROXYTYPE.html
[curlopt_proxyport]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROXYPORT.html
[curlopt_proxyuserpwd]:                http://curl.haxx.se/libcurl/c/CURLOPT_PROXYUSERPWD.html
[curlopt_proxy_service_name]:          http://curl.haxx.se/libcurl/c/CURLOPT_PROXY_SERVICE_NAME.html
[curlopt_proxyauth]:                   http://curl.haxx.se/libcurl/c/CURLOPT_PROXYAUTH.html
[curlopt_proxy_transfer_mode]:         http://curl.haxx.se/libcurl/c/CURLOPT_PROXY_TRANSFER_MODE.html
[curlopt_proxyusername]:               http://curl.haxx.se/libcurl/c/CURLOPT_PROXYUSERNAME.html
[curlopt_proxypassword]:               http://curl.haxx.se/libcurl/c/CURLOPT_PROXYPASSWORD.html
[curlopt_proxyheader]:                 http://curl.haxx.se/libcurl/c/CURLOPT_PROXYHEADER.html
[curlopt_noproxy]:                     http://curl.haxx.se/libcurl/c/CURLOPT_NOPROXY.html
[curlopt_writefunction]:               http://curl.haxx.se/libcurl/c/CURLOPT_WRITEFUNCTION.html
[curlopt_writedata]:                   http://curl.haxx.se/libcurl/c/CURLOPT_WRITEDATA.html
[curlopt_readfunction]:                http://curl.haxx.se/libcurl/c/CURLOPT_READFUNCTION.html
[curlopt_readdata]:                    http://curl.haxx.se/libcurl/c/CURLOPT_READDATA.html
[curlopt_seekfunction]:                http://curl.haxx.se/libcurl/c/CURLOPT_SEEKFUNCTION.html
[curlopt_seekdata]:                    http://curl.haxx.se/libcurl/c/CURLOPT_SEEKDATA.html
[curlopt_infilesize]:                  http://curl.haxx.se/libcurl/c/CURLOPT_INFILESIZE.html
[curlopt_low_speed_limit]:             http://curl.haxx.se/libcurl/c/CURLOPT_LOW_SPEED_LIMIT.html
[curlopt_low_speed_time]:              http://curl.haxx.se/libcurl/c/CURLOPT_LOW_SPEED_TIME.html
[curlopt_max_send_speed_large]:        http://curl.haxx.se/libcurl/c/CURLOPT_MAX_SEND_SPEED_LARGE.html
[curlopt_max_recv_speed_large]:        http://curl.haxx.se/libcurl/c/CURLOPT_MAX_RECV_SPEED_LARGE.html
[curlopt_resume_from]:                 http://curl.haxx.se/libcurl/c/CURLOPT_RESUME_FROM.html
[curlopt_keypasswd]:                   http://curl.haxx.se/libcurl/c/CURLOPT_KEYPASSWD.html
[curlopt_crlf]:                        http://curl.haxx.se/libcurl/c/CURLOPT_CRLF.html
[curlopt_quote]:                       http://curl.haxx.se/libcurl/c/CURLOPT_QUOTE.html
[curlopt_timecondition]:               http://curl.haxx.se/libcurl/c/CURLOPT_TIMECONDITION.html
[curlopt_timevalue]:                   http://curl.haxx.se/libcurl/c/CURLOPT_TIMEVALUE.html
[curlopt_customrequest]:               http://curl.haxx.se/libcurl/c/CURLOPT_CUSTOMREQUEST.html
[curlopt_postquote]:                   http://curl.haxx.se/libcurl/c/CURLOPT_POSTQUOTE.html
[curlopt_upload]:                      http://curl.haxx.se/libcurl/c/CURLOPT_UPLOAD.html
[curlopt_dirlistonly]:                 http://curl.haxx.se/libcurl/c/CURLOPT_DIRLISTONLY.html
[curlopt_append]:                      http://curl.haxx.se/libcurl/c/CURLOPT_APPEND.html
[curlopt_transfertext]:                http://curl.haxx.se/libcurl/c/CURLOPT_TRANSFERTEXT.html
[curlopt_autoreferer]:                 http://curl.haxx.se/libcurl/c/CURLOPT_AUTOREFERER.html
[curlopt_postfieldsize]:               http://curl.haxx.se/libcurl/c/CURLOPT_POSTFIELDSIZE.html
[curlopt_httpheader]:                  http://curl.haxx.se/libcurl/c/CURLOPT_HTTPHEADER.html
[curlopt_httppost]:                    http://curl.haxx.se/libcurl/c/CURLOPT_HTTPPOST.html
[curlopt_httpproxytunnel]:             http://curl.haxx.se/libcurl/c/CURLOPT_HTTPPROXYTUNNEL.html
[curlopt_httpget]:                     http://curl.haxx.se/libcurl/c/CURLOPT_HTTPGET.html
[curlopt_http_version]:                http://curl.haxx.se/libcurl/c/CURLOPT_HTTP_VERSION.html
[curlopt_http200aliases]:              http://curl.haxx.se/libcurl/c/CURLOPT_HTTP200ALIASES.html
[curlopt_httpauth]:                    http://curl.haxx.se/libcurl/c/CURLOPT_HTTPAUTH.html
[curlopt_http_transfer_decoding]:      http://curl.haxx.se/libcurl/c/CURLOPT_HTTP_TRANSFER_DECODING.html
[curlopt_http_content_decoding]:       http://curl.haxx.se/libcurl/c/CURLOPT_HTTP_CONTENT_DECODING.html
[curlopt_interface]:                   http://curl.haxx.se/libcurl/c/CURLOPT_INTERFACE.html
[curlopt_krblevel]:                    http://curl.haxx.se/libcurl/c/CURLOPT_KRBLEVEL.html
[curlopt_cainfo]:                      http://curl.haxx.se/libcurl/c/CURLOPT_CAINFO.html
[curlopt_maxredirs]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAXREDIRS.html
[curlopt_filetime]:                    http://curl.haxx.se/libcurl/c/CURLOPT_FILETIME.html
[curlopt_telnetoptions]:               http://curl.haxx.se/libcurl/c/CURLOPT_TELNETOPTIONS.html
[curlopt_maxconnects]:                 http://curl.haxx.se/libcurl/c/CURLOPT_MAXCONNECTS.html
[curlopt_fresh_connect]:               http://curl.haxx.se/libcurl/c/CURLOPT_FRESH_CONNECT.html
[curlopt_forbid_reuse]:                http://curl.haxx.se/libcurl/c/CURLOPT_FORBID_REUSE.html
[curlopt_random_file]:                 http://curl.haxx.se/libcurl/c/CURLOPT_RANDOM_FILE.html
[curlopt_egdsocket]:                   http://curl.haxx.se/libcurl/c/CURLOPT_EGDSOCKET.html
[curlopt_headerfunction]:              http://curl.haxx.se/libcurl/c/CURLOPT_HEADERFUNCTION.html
[curlopt_cookiejar]:                   http://curl.haxx.se/libcurl/c/CURLOPT_COOKIEJAR.html
[curlopt_use_ssl]:                     http://curl.haxx.se/libcurl/c/CURLOPT_USE_SSL.html
[curlopt_sslcert]:                     http://curl.haxx.se/libcurl/c/CURLOPT_SSLCERT.html
[curlopt_sslversion]:                  http://curl.haxx.se/libcurl/c/CURLOPT_SSLVERSION.html
[curlopt_sslcerttype]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SSLCERTTYPE.html
[curlopt_sslkey]:                      http://curl.haxx.se/libcurl/c/CURLOPT_SSLKEY.html
[curlopt_sslkeytype]:                  http://curl.haxx.se/libcurl/c/CURLOPT_SSLKEYTYPE.html
[curlopt_sslengine]:                   http://curl.haxx.se/libcurl/c/CURLOPT_SSLENGINE.html
[curlopt_sslengine_default]:           http://curl.haxx.se/libcurl/c/CURLOPT_SSLENGINE_DEFAULT.html
[curlopt_ssl_options]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SSL_OPTIONS.html
[curlopt_ssl_cipher_list]:             http://curl.haxx.se/libcurl/c/CURLOPT_SSL_CIPHER_LIST.html
[curlopt_ssl_verifyhost]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYHOST.html
[curlopt_ssl_verifypeer]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYPEER.html
[curlopt_ssl_ctx_function]:            http://curl.haxx.se/libcurl/c/CURLOPT_SSL_CTX_FUNCTION.html
[curlopt_ssl_ctx_data]:                http://curl.haxx.se/libcurl/c/CURLOPT_SSL_CTX_DATA.html
[curlopt_ssl_sessionid_cache]:         http://curl.haxx.se/libcurl/c/CURLOPT_SSL_SESSIONID_CACHE.html
[curlopt_ssl_enable_npn]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_ENABLE_NPN.html
[curlopt_ssl_enable_alpn]:             http://curl.haxx.se/libcurl/c/CURLOPT_SSL_ENABLE_ALPN.html
[curlopt_ssl_verifystatus]:            http://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYSTATUS.html
[curlopt_ssl_falsestart]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSL_FALSESTART.html
[curlopt_crlfile]:                     http://curl.haxx.se/libcurl/c/CURLOPT_CRLFILE.html
[curlopt_issuercert]:                  http://curl.haxx.se/libcurl/c/CURLOPT_ISSUERCERT.html
[curlopt_certinfo]:                    http://curl.haxx.se/libcurl/c/CURLOPT_CERTINFO.html
[curlopt_prequote]:                    http://curl.haxx.se/libcurl/c/CURLOPT_PREQUOTE.html
[curlopt_debugfunction]:               http://curl.haxx.se/libcurl/c/CURLOPT_DEBUGFUNCTION.html
[curlopt_debugdata]:                   http://curl.haxx.se/libcurl/c/CURLOPT_DEBUGDATA.html
[curlopt_cookiesession]:               http://curl.haxx.se/libcurl/c/CURLOPT_COOKIESESSION.html
[curlopt_capath]:                      http://curl.haxx.se/libcurl/c/CURLOPT_CAPATH.html
[curlopt_buffersize]:                  http://curl.haxx.se/libcurl/c/CURLOPT_BUFFERSIZE.html
[curlopt_nosignal]:                    http://curl.haxx.se/libcurl/c/CURLOPT_NOSIGNAL.html
[curlopt_share]:                       http://curl.haxx.se/libcurl/c/CURLOPT_SHARE.html
[curlopt_accept_encoding]:             http://curl.haxx.se/libcurl/c/CURLOPT_ACCEPT_ENCODING.html
[curlopt_private]:                     http://curl.haxx.se/libcurl/c/CURLOPT_PRIVATE.html
[curlopt_unrestricted_auth]:           http://curl.haxx.se/libcurl/c/CURLOPT_UNRESTRICTED_AUTH.html
[curlopt_ipresolve]:                   http://curl.haxx.se/libcurl/c/CURLOPT_IPRESOLVE.html
[curlopt_maxfilesize]:                 http://curl.haxx.se/libcurl/c/CURLOPT_MAXFILESIZE.html
[curlopt_infilesize_large]:            http://curl.haxx.se/libcurl/c/CURLOPT_INFILESIZE_LARGE.html
[curlopt_resume_from_large]:           http://curl.haxx.se/libcurl/c/CURLOPT_RESUME_FROM_LARGE.html
[curlopt_maxfilesize_large]:           http://curl.haxx.se/libcurl/c/CURLOPT_MAXFILESIZE_LARGE.html
[curlopt_postfieldsize_large]:         http://curl.haxx.se/libcurl/c/CURLOPT_POSTFIELDSIZE_LARGE.html
[curlopt_tcp_nodelay]:                 http://curl.haxx.se/libcurl/c/CURLOPT_TCP_NODELAY.html
[curlopt_ftpsslauth]:                  http://curl.haxx.se/libcurl/c/CURLOPT_FTPSSLAUTH.html
[curlopt_ioctlfunction]:               http://curl.haxx.se/libcurl/c/CURLOPT_IOCTLFUNCTION.html
[curlopt_ioctldata]:                   http://curl.haxx.se/libcurl/c/CURLOPT_IOCTLDATA.html
[curlopt_cookielist]:                  http://curl.haxx.se/libcurl/c/CURLOPT_COOKIELIST.html
[curlopt_ignore_content_length]:       http://curl.haxx.se/libcurl/c/CURLOPT_IGNORE_CONTENT_LENGTH.html
[curlopt_ftpport]:                     http://curl.haxx.se/libcurl/c/CURLOPT_FTPPORT.html
[curlopt_ftp_use_eprt]:                http://curl.haxx.se/libcurl/c/CURLOPT_FTP_USE_EPRT.html
[curlopt_ftp_create_missing_dirs]:     http://curl.haxx.se/libcurl/c/CURLOPT_FTP_CREATE_MISSING_DIRS.html
[curlopt_ftp_response_timeout]:        http://curl.haxx.se/libcurl/c/CURLOPT_FTP_RESPONSE_TIMEOUT.html
[curlopt_ftp_use_epsv]:                http://curl.haxx.se/libcurl/c/CURLOPT_FTP_USE_EPSV.html
[curlopt_ftp_account]:                 http://curl.haxx.se/libcurl/c/CURLOPT_FTP_ACCOUNT.html
[curlopt_ftp_skip_pasv_ip]:            http://curl.haxx.se/libcurl/c/CURLOPT_FTP_SKIP_PASV_IP.html
[curlopt_ftp_filemethod]:              http://curl.haxx.se/libcurl/c/CURLOPT_FTP_FILEMETHOD.html
[curlopt_ftp_use_pret]:                http://curl.haxx.se/libcurl/c/CURLOPT_FTP_USE_PRET.html
[curlopt_ftp_ssl_ccc]:                 http://curl.haxx.se/libcurl/c/CURLOPT_FTP_SSL_CCC.html
[curlopt_ftp_alternative_to_user]:     http://curl.haxx.se/libcurl/c/CURLOPT_FTP_ALTERNATIVE_TO_USER.html
[curlopt_localport]:                   http://curl.haxx.se/libcurl/c/CURLOPT_LOCALPORT.html
[curlopt_localportrange]:              http://curl.haxx.se/libcurl/c/CURLOPT_LOCALPORTRANGE.html
[curlopt_connect_only]:                http://curl.haxx.se/libcurl/c/CURLOPT_CONNECT_ONLY.html
[curlopt_conv_from_network_function]:  http://curl.haxx.se/libcurl/c/CURLOPT_CONV_FROM_NETWORK_FUNCTION.html
[curlopt_conv_to_network_function]:    http://curl.haxx.se/libcurl/c/CURLOPT_CONV_TO_NETWORK_FUNCTION.html
[curlopt_conv_from_utf8_function]:     http://curl.haxx.se/libcurl/c/CURLOPT_CONV_FROM_UTF8_FUNCTION.html
[curlopt_opensocketfunction]:          http://curl.haxx.se/libcurl/c/CURLOPT_OPENSOCKETFUNCTION.html
[curlopt_opensocketdata]:              http://curl.haxx.se/libcurl/c/CURLOPT_OPENSOCKETDATA.html
[curlopt_closesocketfunction]:         http://curl.haxx.se/libcurl/c/CURLOPT_CLOSESOCKETFUNCTION.html
[curlopt_closesocketdata]:             http://curl.haxx.se/libcurl/c/CURLOPT_CLOSESOCKETDATA.html
[curlopt_sockoptfunction]:             http://curl.haxx.se/libcurl/c/CURLOPT_SOCKOPTFUNCTION.html
[curlopt_sockoptdata]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SOCKOPTDATA.html
[curlopt_ssh_auth_types]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSH_AUTH_TYPES.html
[curlopt_ssh_public_keyfile]:          http://curl.haxx.se/libcurl/c/CURLOPT_SSH_PUBLIC_KEYFILE.html
[curlopt_ssh_private_keyfile]:         http://curl.haxx.se/libcurl/c/CURLOPT_SSH_PRIVATE_KEYFILE.html
[curlopt_ssh_knownhosts]:              http://curl.haxx.se/libcurl/c/CURLOPT_SSH_KNOWNHOSTS.html
[curlopt_ssh_keyfunction]:             http://curl.haxx.se/libcurl/c/CURLOPT_SSH_KEYFUNCTION.html
[curlopt_ssh_keydata]:                 http://curl.haxx.se/libcurl/c/CURLOPT_SSH_KEYDATA.html
[curlopt_ssh_host_public_key_md5]:     http://curl.haxx.se/libcurl/c/CURLOPT_SSH_HOST_PUBLIC_KEY_MD5.html
[curlopt_new_file_perms]:              http://curl.haxx.se/libcurl/c/CURLOPT_NEW_FILE_PERMS.html
[curlopt_new_directory_perms]:         http://curl.haxx.se/libcurl/c/CURLOPT_NEW_DIRECTORY_PERMS.html
[curlopt_postredir]:                   http://curl.haxx.se/libcurl/c/CURLOPT_POSTREDIR.html
[curlopt_copypostfields]:              http://curl.haxx.se/libcurl/c/CURLOPT_COPYPOSTFIELDS.html
[curlopt_address_scope]:               http://curl.haxx.se/libcurl/c/CURLOPT_ADDRESS_SCOPE.html
[curlopt_username]:                    http://curl.haxx.se/libcurl/c/CURLOPT_USERNAME.html
[curlopt_password]:                    http://curl.haxx.se/libcurl/c/CURLOPT_PASSWORD.html
[curlopt_socks5_gssapi_service]:       http://curl.haxx.se/libcurl/c/CURLOPT_SOCKS5_GSSAPI_SERVICE.html
[curlopt_socks5_gssapi_nec]:           http://curl.haxx.se/libcurl/c/CURLOPT_SOCKS5_GSSAPI_NEC.html
[curlopt_interleavedata]:              http://curl.haxx.se/libcurl/c/CURLOPT_INTERLEAVEDATA.html
[curlopt_interleavefunction]:          http://curl.haxx.se/libcurl/c/CURLOPT_INTERLEAVEFUNCTION.html
[curlopt_chunk_bgn_function]:          http://curl.haxx.se/libcurl/c/CURLOPT_CHUNK_BGN_FUNCTION.html
[curlopt_chunk_end_function]:          http://curl.haxx.se/libcurl/c/CURLOPT_CHUNK_END_FUNCTION.html
[curlopt_chunk_data]:                  http://curl.haxx.se/libcurl/c/CURLOPT_CHUNK_DATA.html
[curlopt_fnmatch_function]:            http://curl.haxx.se/libcurl/c/CURLOPT_FNMATCH_FUNCTION.html
[curlopt_fnmatch_data]:                http://curl.haxx.se/libcurl/c/CURLOPT_FNMATCH_DATA.html
[curlopt_resolve]:                     http://curl.haxx.se/libcurl/c/CURLOPT_RESOLVE.html
[curlopt_wildcardmatch]:               http://curl.haxx.se/libcurl/c/CURLOPT_WILDCARDMATCH.html
[curlopt_tlsauth_username]:            http://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_USERNAME.html
[curlopt_tlsauth_password]:            http://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_PASSWORD.html
[curlopt_tlsauth_type]:                http://curl.haxx.se/libcurl/c/CURLOPT_TLSAUTH_TYPE.html
[curlopt_transfer_encoding]:           http://curl.haxx.se/libcurl/c/CURLOPT_TRANSFER_ENCODING.html
[curlopt_gssapi_delegation]:           http://curl.haxx.se/libcurl/c/CURLOPT_GSSAPI_DELEGATION.html
[curlopt_tcp_keepalive]:               http://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPALIVE.html
[curlopt_tcp_keepidle]:                http://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPIDLE.html
[curlopt_tcp_keepintvl]:               http://curl.haxx.se/libcurl/c/CURLOPT_TCP_KEEPINTVL.html
[curlopt_mail_from]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAIL_FROM.html
[curlopt_mail_rcpt]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAIL_RCPT.html
[curlopt_mail_auth]:                   http://curl.haxx.se/libcurl/c/CURLOPT_MAIL_AUTH.html
[curlopt_tftp_blksize]:                http://curl.haxx.se/libcurl/c/CURLOPT_TFTP_BLKSIZE.html
[curlopt_rtsp_request]:                http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_REQUEST.html
[curlopt_rtsp_session_id]:             http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_SESSION_ID.html
[curlopt_rtsp_stream_uri]:             http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_STREAM_URI.html
[curlopt_rtsp_transport]:              http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_TRANSPORT.html
[curlopt_rtsp_client_cseq]:            http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_CLIENT_CSEQ.html
[curlopt_rtsp_server_cseq]:            http://curl.haxx.se/libcurl/c/CURLOPT_RTSP_SERVER_CSEQ.html
[curlopt_netrc]:                       http://curl.haxx.se/libcurl/c/CURLOPT_NETRC.html
[curlopt_netrc_file]:                  http://curl.haxx.se/libcurl/c/CURLOPT_NETRC_FILE.html
[curlopt_dns_servers]:                 http://curl.haxx.se/libcurl/c/CURLOPT_DNS_SERVERS.html
[curlopt_dns_interface]:               http://curl.haxx.se/libcurl/c/CURLOPT_DNS_INTERFACE.html
[curlopt_dns_local_ip4]:               http://curl.haxx.se/libcurl/c/CURLOPT_DNS_LOCAL_IP4.html
[curlopt_dns_local_ip6]:               http://curl.haxx.se/libcurl/c/CURLOPT_DNS_LOCAL_IP6.html
[curlopt_dns_use_global_cache]:        http://curl.haxx.se/libcurl/c/CURLOPT_DNS_USE_GLOBAL_CACHE.html
[curlopt_dns_cache_timeout]:           http://curl.haxx.se/libcurl/c/CURLOPT_DNS_CACHE_TIMEOUT.html
[curlopt_login_options]:               http://curl.haxx.se/libcurl/c/CURLOPT_LOGIN_OPTIONS.html
[curlopt_expect_100_timeout_ms]:       http://curl.haxx.se/libcurl/c/CURLOPT_EXPECT_100_TIMEOUT_MS.html
[curlopt_headeropt]:                   http://curl.haxx.se/libcurl/c/CURLOPT_HEADEROPT.html
[curlopt_pinnedpublickey]:             http://curl.haxx.se/libcurl/c/CURLOPT_PINNEDPUBLICKEY.html
[curlopt_unix_socket_path]:            http://curl.haxx.se/libcurl/c/CURLOPT_UNIX_SOCKET_PATH.html
[curlopt_path_as_is]:                  http://curl.haxx.se/libcurl/c/CURLOPT_PATH_AS_IS.html
[curlopt_service_name]:                http://curl.haxx.se/libcurl/c/CURLOPT_SERVICE_NAME.html
[curlopt_pipewait]:                    http://curl.haxx.se/libcurl/c/CURLOPT_PIPEWAIT.html
[curlopt_sasl_ir]:                     http://curl.haxx.se/libcurl/c/CURLOPT_SASL_IR.html
[curlopt_xoauth2_bearer]:              http://curl.haxx.se/libcurl/c/CURLOPT_XOAUTH2_BEARER.html
[curlopt_xferinfofunction]:            http://curl.haxx.se/libcurl/c/CURLOPT_XFERINFOFUNCTION.html
[curlopt_xferinfodata]:                http://curl.haxx.se/libcurl/c/CURLOPT_XFERINFODATA.html

## Multi interface

### `curl.multi([{etr1,..., opt=val}]) -> mtr`

Create a transfer using the [multi interface][libcurl-multi].
The details are the same as with the easy interface except that the list
of options is different (see below). Also, if the options table has any
elements in the array part, `mtr:add()` is called for/with each element.

There's a section on the [libcurl tutorial] on how to use the multi interface.

[libcurl tutorial]: http://curl.haxx.se/libcurl/c/libcurl-tutorial.html

----------------------------- --------------------------------------------------------------------
`socketfunction`              [Callback about what to wait for][curlmopt_socketfunction]
`socketdata`                  [Custom pointer passed to the socket callback][curlmopt_socketdata]
`pipelining`                  [enable/disable HTTP pipelining][curlmopt_pipelining]
`timerfunction`               [Set callback to receive timeout values][curlmopt_timerfunction]
`timerdata`                   [Custom pointer to pass to timer callback][curlmopt_timerdata]
`maxconnects`                 [Set size of connection cache][curlmopt_maxconnects]
`max_host_connections`        [Set max number of connections to a single host][curlmopt_max_host_connections]
`max_pipeline_length`         [Maximum number of requests in a pipeline][curlmopt_max_pipeline_length]
`content_length_penalty_size` [Size threshold for pipelining penalty][curlmopt_content_length_penalty_size]
`chunk_length_penalty_size`   [Chunk length threshold for pipelining][curlmopt_chunk_length_penalty_size]
`pipelining_site_bl`          [Pipelining host blacklist (list of strings)][curlmopt_pipelining_site_bl]
`pipelining_server_bl`        [Pipelining server blacklist (list of strings)][curlmopt_pipelining_server_bl]
`max_total_connections`       [Max simultaneously open connections][curlmopt_max_total_connections]
`pushfunction`                [Callback that approves or denies server pushes][curlmopt_pushfunction]
`pushdata`                    [Pointer to pass to push callback][curlmopt_pushdata]
----------------------------- --------------------------------------------------------------------

[curlmopt_socketfunction]:               http://curl.haxx.se/libcurl/c/CURLMOPT_SOCKETFUNCTION.html
[curlmopt_socketdata]:                   http://curl.haxx.se/libcurl/c/CURLMOPT_SOCKETDATA.html
[curlmopt_pipelining]:                   http://curl.haxx.se/libcurl/c/CURLMOPT_PIPELINING.html
[curlmopt_timerfunction]:                http://curl.haxx.se/libcurl/c/CURLMOPT_TIMERFUNCTION.html
[curlmopt_timerdata]:                    http://curl.haxx.se/libcurl/c/CURLMOPT_TIMERDATA.html
[curlmopt_maxconnects]:                  http://curl.haxx.se/libcurl/c/CURLMOPT_MAXCONNECTS.html
[curlmopt_max_host_connections]:         http://curl.haxx.se/libcurl/c/CURLMOPT_MAX_HOST_CONNECTIONS.html
[curlmopt_max_pipeline_length]:          http://curl.haxx.se/libcurl/c/CURLMOPT_MAX_PIPELINE_LENGTH.html
[curlmopt_content_length_penalty_size]:  http://curl.haxx.se/libcurl/c/CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE.html
[curlmopt_chunk_length_penalty_size]:    http://curl.haxx.se/libcurl/c/CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE.html
[curlmopt_pipelining_site_bl]:           http://curl.haxx.se/libcurl/c/CURLMOPT_PIPELINING_SITE_BL.html
[curlmopt_pipelining_server_bl]:         http://curl.haxx.se/libcurl/c/CURLMOPT_PIPELINING_SERVER_BL.html
[curlmopt_max_total_connections]:        http://curl.haxx.se/libcurl/c/CURLMOPT_MAX_TOTAL_CONNECTIONS.html
[curlmopt_pushfunction]:                 http://curl.haxx.se/libcurl/c/CURLMOPT_PUSHFUNCTION.html
[curlmopt_pushdata]:                     http://curl.haxx.se/libcurl/c/CURLMOPT_PUSHDATA.html

## Share interface

### `curl.share([{opt=val}]) -> shr`

Create a [share object][libcurl-share]. Options below (also for `shr:set()`):

----------------------------- --------------------------------------------------------------------
`lockfunc`                    [lock data callback][curl_share_setopt]
`unlockfunc`                  [unlock data callback][curl_share_setopt]
`share`                       [what tyoe of data to share][curl_share_setopt]
`unshare`                     [what type of data _not_ to share][curl_share_setopt]
`userdata`                    [pointer to pass to lock and unlock functions][curl_share_setopt]
----------------------------- --------------------------------------------------------------------

## Multipart forms

### `frm:add(opt1, val1, ...) -> frm`

Add a section to a [multipart form][curl_formadd]. Options can be given
as strings (case-insensitive, no prefix). The value for the 'array' option
is a Lua array of options. The 'end' option is appended automatically
to the arg list and to arrays. All values are anchored for the lifetime
of the form, so strings and cdata arrays can be passed in freely.

Examples:

~~~{.lua}
form:add(
	'ptrname', 'main-section',
	'file', 'file1.txt',
	'file', 'file2.txt'
)
form:add('array', {
	'ptrname', 'main-section',
	'ptrcontents', 'hello',
	'contentheader', {'Header1: Value1', 'Header2: Value2'},
})
~~~

## Binaries

The included libcurl binaries are compiled to use the SSL/TLS APIs
provided by the host OS by default but can also use luapower's [openssl]
as SSL backend provided libcurl is initalized manually with
`curl.init{sslbackend='openssl'}`.

The decision to ship OpenSSL even on Linux is because OpenSSL is not
ABI-compatible between versions and distros don't usually ship multiple
versions of it (sigh, Linux).

DNS resolving is asynchronous using the multi-threaded resolver.

Features that were _not_ compiled in:

* SFTP and SCP (requires libssh2).
* HTTP2 (requires ng-http2).
* IDN (requires libidn).
* RTMP (requires librtmp).
* PSL (requires libpsl).
* LDAP.
