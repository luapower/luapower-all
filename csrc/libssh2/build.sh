files="
channel.c comp.c crypt.c hostkey.c kex.c mac.c misc.c
packet.c publickey.c scp.c session.c sftp.c userauth.c transport.c
version.c knownhost.c agent.c pem.c keepalive.c global.c
wincng.c
"
cd src || exit 1
${X}gcc -c -O2 $C $files -I. -I../include \
	-DLIBSSH2_HAVE_ZLIB -I../../zlib
${X}gcc *.o -shared -o ../../../bin/$P/$D $L -lz
${X}ar rcs ../../../bin/$P/$A *.o
rm *.o
