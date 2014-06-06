gen-sed = ../helpers/gen-sed
mc-files = $(notdir $(wildcard mc/*))
outdir = $(DESTINSTALLSHARE)
sed-files = $(addsuffix .sed,$(addprefix $(outdir)/,$(mc-files)))

$(outdir)/%.sed : mc/%
	$(gen-sed) < $< > $@

install :: $(sed-files)

clean ::
	rm $(sed-files)
