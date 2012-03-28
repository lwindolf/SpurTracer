install-data-local:
	$(mkinstalldirs) $(DESTDIR)$(pkgdatadir)/css
	$(FIND) * \( -name '*.css' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	$(INSTALL_DATA) $$f $(DESTDIR)$(pkgdatadir)/css/$$f; done
	$(RM) -f list.tmp

uninstall-local:
	$(RM) -f $(DESTDIR)$(pkgdatadir)/css/*.css; \
	$(RMDIR) $(DESTDIR)$(pkgdatadir)/css

dist-hook:
	$(FIND) * \( -name '*.css' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	cp $$f $(distdir)/$$f; done
	$(RM) -f list.tmp
