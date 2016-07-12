# GNU Make file for Headstar E-Access Bulletin.

help:
	# Targets:  e-access, bulletins, install, ssh

e-access:
	cd perl/;  perl e-access.pl

bulletins:
	cd perl/;  perl bulletins.pl

install:
	# (brew install perl) - mac os x.
	# http://www.cpan.org/modules/INSTALL.html
	# http://search.cpan.org/dist/HTML-Parser/lib/HTML/Entities.pm
	cpan App::cpanminus
	cpanm HTML::Entities

# SSH or Fugu (sftp):  http://rsug.itd.umich.edu/software/fugu/
ssh:
	ssh jaxx@headstar.posxx-inxx.com
	# cd /home/jaxx/public_html/eab

#End.
