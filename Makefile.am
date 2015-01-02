SUBDIRS = data lib

SUBST = @abs_top_builddir@/setup_tools/substvars.sh

bin_SCRIPTS = \
	spurtracerd.pl \
	spt

CLEANFILES = $(bin_SCRIPTS)

DISTCLEANFILES = spurtracerd.pl

EXTRA_DIST = \
	spurtracerd.pl.in \
	tools

spurtracerd.pl: spurtracerd.pl.in
	$(SUBST) spurtracerd.pl.in > spurtracerd.pl

