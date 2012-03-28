
install-data-local:
	$(mkinstalldirs) $(DESTDIR)$(perllibdir)
	$(FIND) * \( -name '*.pm' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	$(INSTALL_DATA) $$f $(DESTDIR)$(perllibdir)/$$f; done
	$(RM) -f list.tmp

uninstall-local:
	$(RM) -f $(DESTDIR)$(perllibdir)/*.pm; \
	$(RMDIR) $(DESTDIR)$(perllibdir)/

dist-hook:
	$(FIND) * -type d -print >list.tmp
	$(FIND) * \( -name '*.pm' \) -type f -print >list.tmp
	for f in `cat list.tmp`; do \
	cp $$f $(distdir)/$$f; done
	$(RM) -f list.tmp

