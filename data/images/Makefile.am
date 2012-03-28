install-data-local:
	$(mkinstalldirs) $(DESTDIR)$(pkgdatadir)/images
	$(FIND) * \( -name '*.png' -o -name '*.ico' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	$(INSTALL_DATA) $$f $(DESTDIR)$(pkgdatadir)/images/$$f; done
	$(RM) -f list.tmp

uninstall-local:
	$(RM) -f $(DESTDIR)$(pkgdatadir)/images/*; \
	$(RMDIR) $(DESTDIR)$(pkgdatadir)/images/

dist-hook:
	$(FIND) * \( -name '*.png' -o -name '*.ico' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	cp $$f $(distdir)/$$f; done
	$(RM) -f list.tmp
