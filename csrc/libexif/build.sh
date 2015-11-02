${X}gcc -c -O2 $C libexif/*.c libexif/*/*.c \
	-I. -DHAVE_GETTEXT=1 -DGETTEXT_PACKAGE=\"libexif\" -DLOCALEDIR=\"UTF-8\"
${X}gcc *.o -shared -o ../../bin/$P/$D $L
${X}ar rcs ../../bin/$P/$A *.o
rm *.o
