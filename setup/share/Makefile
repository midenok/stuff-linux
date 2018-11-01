ini2sed = ../helpers/ini2sed
mc-files = $(notdir $(wildcard mc/*))
outdir = $(DESTINSTALLSHARE)
sed-files = $(addsuffix .sed,$(addprefix $(outdir)/,$(mc-files)))

$(outdir)/%.sed : mc/%
	$(ini2sed) < $< > $@

install :: $(sed-files)

clean ::
	rm $(sed-files)
