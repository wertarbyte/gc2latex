package Job;

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

    foreach my $job ( $gc->children("gnc:GncJob") ) {
	next unless ($job->child("job:guid")->value() eq $self->{guid});
	my $customerId = $job->child("job:owner")->child("owner:id")->value();

	$self->{info}{customer} = new Customer($xml, $customerId);
	last;
    }
}

sub getCustomer($) {
    my ($self) = @_;
    return $self->{info}{customer};
}

1;
