package Finance::Bank::DE::LBB::Creditcard;
use strict;
use warnings;
use Exporter;
use LWP::UserAgent;
our @ISA = qw/Exporter/;
our @EXPORT = qw/lbbcheck/;
our $VERSION = '0.1';

sub lbbcheck($$){
	my $user = shift;
	return unless($user);
	my $password = shift;
	return unless($password);

	my $ua = LWP::UserAgent->new;
	$ua->max_redirect(0);
	my $firsturl = 'https://kreditkarten-banking.lbb.de/Amazon/';
	my $res = $ua->get($firsturl);
	my $secondurl = $res->header('Location');
	die "Redirect not found" if(!$secondurl);

	my $ua2 = LWP::UserAgent->new;
	my $res2 = $ua2->get($firsturl);
	my $dourl = 'https://kreditkarten-banking.lbb.de/Amazon/cas/';
	my $html = $res2->content;
	my($dodata) = ($html =~ /<form name="preLogonForm" method="post" action="([^"]*)"/);
	die "preLogonForm not found" if(!$dodata);
	$dourl .= $dodata;
	my($token) = ($html =~ /<input type="hidden" name="org.apache.struts.taglib.html.TOKEN" value="([^"]*)">/);
	die "Token not found" if(!$token);

	my $res3 = $ua->post($dourl, [
		user => $user,
		password => $password,
		intred => 'bt_REG',
		intred => 'PARAM_postprocess_NOT_FOUND',
		registration => 'false',
		bt_LOGON => 'Kreditkarten-Banking starten',
		'ref' => '1200_AMAZON',
		'service' => 'COS',
		'org.apache.struts.taglib.html.TOKEN' => $token
		],
		'Referer' => $secondurl
	);

	my $html2 = $res3->content;
	die "TEXT NOT FOUND WITHIN THE CONFIGURATION" if($html2 =~ /TEXT NOT FOUND WITHIN THE CONFIGURATION/);

	my($clientcode) = ($html2 =~ /<input type="hidden" name="clientCode" value="([^"]*)">/);
	my($ticket) = ($html2 =~ /<input type="hidden" name="ticket" value="([^"]*)">/s);
	my $nexturl = 'https://kreditkarten-banking.lbb.de/lbb/cos_lbb/dispatch.do?bt_PRELOGON=-1';
	die "Ticket or clientcode not found" if(!$ticket or !$clientcode);

	my $ua4 = LWP::UserAgent->new;
	my $res4 = $ua4->post($nexturl, [
		'ticket' => $ticket,
		'clientCode' => $clientcode,
		'ref' => '1200_AMAZON',
		'ref' => 'false'
		],
		'Referer' => $dourl
	);
	my $html3 = $res4->content;
	#print $html3;
	my($creditaccount) = ($html3 =~ /"rai-0">(\d+ \d+ \d+ \d+)<\/a>/);
	my($lastdate) = ($html3 =~ /<td class="tabdata">(\d+\.\d+\.\d+)<\/td>/);

	my($html4) = ($html3 =~ /<td width="40\%" class="tabtext">Kreditkartenkonto:<\/td>(.*?)<td colspan="2">&nbsp;<\/td>/s);
	$html4 =~ s/[\n\r]//sg;
	$html4 =~ s/\r//g;
	$html4 =~ s/\n//g;
	$html4 =~ s/\s\s//g;

	my($mail) = ($html4 =~ /<tr><td class="tabtext">E-Mail:<\/td>[^<]*<td class="tabdata">([^<]*)<\/td>[^<]*<\/tr>/);
	my($bank) = ($html4 =~ /<td width="40\%" class="tabtext">Kontostand:<\/td>[^<]*<td class="tabtext">[^E]*EUR&nbsp;([\d\.\,]*)[^<]*<\/td>/);
	my($credit) = ($html4 =~ /<td width="40\%" class="tabtext">Aktuell verf&uuml;gbar:<\/td>[^<]*<td class="tabdata">[^E]*EUR&nbsp;[^\d]*([\d\.\,]*)[^<]*<\/td>[^<]*<\/tr>/);
	my($fullcredit) = ($html4 =~ /<td width="40\%" class="tabtext">Verf&uuml;gungsrahmen:<\/td>[^<]*<td class="tabdata">[^E]*EUR&nbsp;[^\d]*([\d\.\,]*)[^<]*<\/td>[^<]*<\/tr>/);
	my($requested) = ($html4 =~ /<td width="40\%" class="tabtext">Angefragte Ums&auml;tze:<\/td>[^<]*<td class="tabdata">[^E]*EUR&nbsp;[^\d]*([\d\.\,]*)[^<]*<\/td>[^<]*<\/tr>/);
	my($points) = ($html4 =~ /<td width="40\%" class="tabtext">Aktueller Stand AMAZON.DE PUNKTE:<\/td>[^<]*<td class="tabdata">[^\d\-]*([\d\.\,\-]*)[^<]*<\/td>[^<]*<\/tr>/);

	return(
		'creditaccount' => $creditaccount,
		'lastdate' => $lastdate,
		'bank' => $bank,
		'points' => $points,
		'requested' => $requested,
		'fullcredit' => $fullcredit,
		'credit' => $credit,
		'mail' => $mail
	);
}

=pod

=head1 NAME

Finance::Bank::DE::LBB::Creditcard - Creditcard details

=head1 SYNOPSIS

	use Finance::Bank::DE::LBB::Creditcard;
	my $user = "0000000000000000";#Creditcardnumber
	my $password = "passwort";
	my %data = lbbcheck($user,$password);

	print "Kreditkartenkonto: $data{'creditaccount'}\n";
	print "Datum: $data{'lastdate'}\n";
	print "Kontostand: $data{'bank'} EUR\n";
	print "Punkte: $data{'points'} Punkte\n";
	print "Angefragt: $data{'requested'} EUR\n";
	print "Kredit: $data{'fullcredit'} EUR\n";
	print "Aktuell: $data{'credit'} EUR\n";
	print "E-Mail: $data{'mail'}\n";

=head1 DESCRIPTION

Finance::Bank::DE::LBB::Creditcard - Creditcard details

=head1 AUTHOR

    Stefan Gipper <stefanos@cpan.org>, http://www.coder-world.de/

=head1 COPYRIGHT

	Finance::Bank::DE::LBB::Creditcard is Copyright (c) 2012 Stefan Gipper
	All rights reserved.

	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO



=cut
