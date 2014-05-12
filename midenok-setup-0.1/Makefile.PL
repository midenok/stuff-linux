use 5.010001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

our %CONFIG = (
    NAME => 'midenok-setup',
	NO_META => 1,
	NO_MYMETA => 1,
    EXE_FILES         => [glob 'bin/*'],
);

our @SHARE_FILES = (
	'$(wildcard share/*)'
);

sub MY::post_constants
{
    return <<END;
INSTALLSHARE = \$(PREFIX)/share/$CONFIG{NAME}
DESTINSTALLSHARE = \$(DESTDIR)\$(INSTALLSHARE)
SHARE_FILES = @SHARE_FILES
END
}

sub MY::postamble
{
    return <<'END';
pure_all :: manifest

pure_install ::
	$(NOECHO) mkdir -p $(DESTINSTALLSHARE)
	$(NOECHO) $(CP) -t $(DESTINSTALLSHARE) $(SHARE_FILES)
END
}

WriteMakefile(%CONFIG);
