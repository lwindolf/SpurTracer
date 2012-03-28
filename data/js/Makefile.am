install-data-local:
	$(mkinstalldirs) $(DESTDIR)$(pkgdatadir)/js
	$(FIND) * \( -name '*.js' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	$(INSTALL_DATA) $$f $(DESTDIR)$(pkgdatadir)/js/$$f; done
	$(RM) -f list.tmp

uninstall-local:
	$(RM) -f $(DESTDIR)$(pkgdatadir)/js/*.js; \
	$(RMDIR) $(DESTDIR)$(pkgdatadir)/js/

dist-hook:
	$(FIND) * \( -name '*.js' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	cp $$f $(distdir)/$$f; done
	$(RM) -f list.tmp
