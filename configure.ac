AC_INIT([spurtracer],[0.8],[lars.lindner@gmail.com])
AC_PREREQ([2.59])
AC_CANONICAL_HOST
AM_INIT_AUTOMAKE(1.9)

AC_PATH_PROG(PERL, perl, no)
AC_PATH_PROG(SED, sed, no)
AC_PATH_PROG(RM, rm, no)
AC_PATH_PROG(RMDIR, rmdir, no)
AC_PATH_PROG(FIND, find, no)

AC_ARG_ENABLE(pkgonly, [AC_HELP_STRING([--enable-pkgonly], [Skip all checking])])
AC_SUBST(enable_pkgonly)

        
perllibdirs="\'\${perllibdir}\'"

PERLOPTS=
AC_ARG_VAR(PERLINC, [[] Additional space-separated Perl library paths])
if test ! -z "$PERLINC"; then
   for d in $PERLINC; do
       PERLOPTS="${PERLOPTS} -I${d}"
       perllibdirs=${perllibdirs}"\,\'"${d}"\'"
   done
fi

AC_SUBST(perllibdirs, [${perllibdirs}])


# Check the necessary Perl modules

if test "$enable_pkgonly" != yes; then

   for module in 'XML::Writer' 'Redis' 'Net::Server::HTTP' 'Error'
   do
     AC_MSG_CHECKING([presence of $module])
     if ${PERL} ${PERLOPTS} -e 'use '$module 2>/dev/null; then
         AC_MSG_RESULT([Ok])
     else
         AC_MSG_ERROR([Perl cannot find $module]);
     fi
   done
fi

AC_ARG_VAR(perllibdir, [[LIBDIR/PACKAGE/perl] SpurTracer Perl libraries])
if test -z "$perllibdir"; then
   perllibdir='${libdir}/${PACKAGE}/perl'; fi

AC_ARG_VAR(pkgdatadir, [[DATADIR/PACKAGE] SpurTracer data directory])
if test -z "$pkgdatadir"; then
   pkgdatadir='${datadir}/${PACKAGE}'; fi
   
AC_CONFIG_FILES([
Makefile
lib/Makefile
data/Makefile
data/css/Makefile
data/images/Makefile
data/js/Makefile
data/xslt/Makefile
])
AC_CONFIG_FILES([setup_tools/substvars.sh],[chmod +x setup_tools/substvars.sh])

AC_SUBST(VERSION)

AC_OUTPUT
