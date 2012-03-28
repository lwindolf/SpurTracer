install-data-local:
	$(mkinstalldirs) $(DESTDIR)$(pkgdatadir)/xslt
	$(FIND) * \( -name '*.xsl' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	$(INSTALL_DATA) $$f $(DESTDIR)$(pkgdatadir)/xslt/$$f; done
	$(RM) -f list.tmp

uninstall-local:
	$(RM) -f $(DESTDIR)$(pkgdatadir)/xslt/*.xsl; \
	$(RMDIR) $(DESTDIR)$(pkgdatadir)/xslt/

dist-hook:
	$(FIND) * \( -name '*.xsl' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	cp $$f $(distdir)/$$f; done
	$(RM) -f list.tmp
