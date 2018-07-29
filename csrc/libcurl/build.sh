LIB_CFILES="
file.c timeval.c base64.c hostip.c progress.c formdata.c
cookie.c http.c sendf.c ftp.c url.c dict.c if2ip.c speedcheck.c
ldap.c version.c getenv.c escape.c mprintf.c telnet.c netrc.c
getinfo.c transfer.c strequal.c easy.c security.c curl_fnmatch.c
fileinfo.c ftplistparser.c wildcard.c krb5.c memdebug.c http_chunks.c
strtok.c connect.c llist.c hash.c multi.c content_encoding.c share.c
http_digest.c md4.c md5.c http_negotiate.c inet_pton.c strtoofft.c
strerror.c amigaos.c hostasyn.c hostip4.c hostip6.c hostsyn.c
inet_ntop.c parsedate.c select.c tftp.c splay.c strdup.c socks.c
ssh.c rawstr.c curl_addrinfo.c socks_gssapi.c socks_sspi.c
curl_sspi.c slist.c nonblock.c curl_memrchr.c imap.c pop3.c smtp.c
pingpong.c rtsp.c curl_threads.c warnless.c hmac.c curl_rtmp.c
openldap.c curl_gethostname.c gopher.c
http_negotiate_sspi.c http_proxy.c non-ascii.c asyn-ares.c
asyn-thread.c curl_gssapi.c curl_ntlm.c curl_ntlm_wb.c
curl_ntlm_core.c curl_ntlm_msgs.c curl_sasl.c curl_multibyte.c
hostcheck.c conncache.c pipeline.c dotdot.c x509asn1.c
http2.c curl_sasl_sspi.c smb.c curl_sasl_gssapi.c curl_endian.c
curl_des.c
vtls/vtls.c
"
cd lib || exit 1
rm -f *.o
${X}gcc -c -O2 -Wall -fno-strict-aliasing -DBUILDING_LIBCURL $C \
	$LIB_CFILES \
	-I. -I../include \
	-DHAVE_LIBZ -DHAVE_ZLIB_H -I../../zlib \
	-DENABLE_IPV6 \
	-DCURL_DISABLE_LDAP
${X}gcc *.o -shared -o ../../../bin/$P/$D $L \
	-L../../../bin/$P -lz
rm -f      ../../../bin/$P/$A
${X}ar rcs ../../../bin/$P/$A *.o
rm *.o
