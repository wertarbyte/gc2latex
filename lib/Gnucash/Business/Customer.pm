package Customer;

use XML::SimpleObject;

use strict;

## By Stefan Tomanek <stefan@pico.ruhr.de>

sub new($$$) {
    my ($proto, $gc, $guid) = @_;
    
    my $self = {};
    $self->{guid} = $guid;	
    fillInfos($self, $gc);
    
    bless($self);
    return $self;
}

sub fillInfos($) {
    my ($self, $xml) = @_;
    
    my $gc = $xml->child("gnc-v2")->child("gnc:book");

    foreach my $cust ( $gc->children("gnc:GncCustomer") ) {
	next unless ($cust->child("cust:guid")->value() eq $self->{guid});
	$self->{info}{address}{name} = $cust->child("cust:addr")->child("addr:name")->value();

	if ($cust->child("cust:addr")->child("addr:addr1")) {
	  $self->{info}{address}{addr1} =
	    $cust->child("cust:addr")->child("addr:addr1")->value();
	} else {
	  $self->{info}{address}{addr1} = undef;
	};
	if ($cust->child("cust:addr")->child("addr:addr2")) {
	  $self->{info}{address}{addr2} =
	    $cust->child("cust:addr")->child("addr:addr2")->value();
	} else {
	  $self->{info}{address}{addr2} = undef;
	};
	if ($cust->child("cust:addr")->child("addr:addr3")) {
	  $self->{info}{address}{addr3} =
	    $cust->child("cust:addr")->child("addr:addr3")->value();
	} else {
	  $self->{info}{address}{addr3} = undef;
	};
	if ($cust->child("cust:addr")->child("addr:addr4")) {
	  $self->{info}{address}{addr4} =
	    $cust->child("cust:addr")->child("addr:addr4")->value();
	} else {
	  $self->{info}{address}{addr4} = undef;
	};
	last;
    }
}

sub getName($) { return $_[0]->{info}{address}{name}; }
sub getAddr1($) { return $_[0]->{info}{address}{addr1}; }
sub getAddr2($) { return $_[0]->{info}{address}{addr2}; }
sub getAddr3($) { return $_[0]->{info}{address}{addr3}; }
sub getAddr4($) { return $_[0]->{info}{address}{addr4}; }

sub getAddress($) {
    my $text = "";
    $text .= getName($_[0])."\n";
    if (getAddr1($_[0])) {
      $text .= getAddr1($_[0])."\n";
    };
    if (getAddr2($_[0])) {
      $text .= getAddr2($_[0])."\n";
    };
    if (getAddr3($_[0])) {
      $text .= getAddr3($_[0])."\n";
    };
    if (getAddr4($_[0])) {
      $text .= getAddr4($_[0])."\n";
    };
    return $text;
}

1;
