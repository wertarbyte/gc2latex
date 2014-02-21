package BillTerm;

use XML::SimpleObject;

use strict;

## By Susanne Wunsch <Susanne.Wunsch@gleisBezug.de>
## Adapted from Stefan Tomanek <stefan@pico.ruhr.de>

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

    my @terms = $gc->children("gnc:GncBillTerm");
    return if ($terms[0] eq "");
    foreach my $tm (@terms) {
        next unless ($self->{guid} eq $tm->child("billterm:guid")->value());
        $self->{info}{description} = $tm->child("billterm:desc")->value();
        last;
    }
}

1;
