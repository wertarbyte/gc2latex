package TaxTable;

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
    
    my @tables = $gc->children("gnc:GncTaxTable");
    return if ($tables[0] eq "");
    foreach my $tab (@tables) {
        next unless ($self->{guid} eq $tab->child("taxtable:guid")->value());
        
        $self->{info}{name} = $tab->child("taxtable:name")->value();

        $self->{entries} = [];
        foreach my $entry ($tab->child("taxtable:entries")->children("gnc:GncTaxTableEntry")) {
            my %item;
            if ($entry->child("tte:amount")->value() =~ /^(\d+)\/(\d+)$/) {
            $item{amount} = $1/$2;
            } 
            $item{type} = $entry->child("tte:type")->value();
            push @{ $self->{entries} }, \%item;
        }
        
        last;
    }
}

sub calcTaxFromInvoiceEntry($$) {
    my ($self, $entry) = @_;
    my $tax = 0;
    my $sum = $entry->getQuantity() * $entry->getPrice();
    
    foreach my $t (@{ $self->{entries} }) {
        if ($t->{type} eq "VALUE") {
            $tax += $t->{amount};
        } elsif ($t->{type} eq "PERCENT") {
            if ($entry->isTaxIncluded()) {
                $tax += (100*$sum / (100+$t->{amount}) * ($t->{amount}/100) ) ;
            } else {
                $tax += $sum * $t->{amount} / 100;
            }
        }
    }
    return $tax;
}

1;
