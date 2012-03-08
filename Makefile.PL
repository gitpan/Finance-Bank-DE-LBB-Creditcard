use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Finance::Bank::DE::LBB::Creditcard',
    'VERSION_FROM'	=> 'Creditcard.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP::UserAgent => 1.00},
    ($] >= 5.005 ? (
      ABSTRACT_FROM => 'Creditcard.pm', 
      AUTHOR     => 'Stefan Gipper <stefanos@cpan.org>',
    ) : ()),
);
