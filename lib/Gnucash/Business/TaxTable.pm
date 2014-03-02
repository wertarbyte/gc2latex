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

sub TaxTableName($) {
  my ($self) = @_;

  if ($self->{info}->{name}) {
    return $self->{info}->{name};
  }else {
    return '';
  }
}

sub CalculateTax ($$$) {
  my ($self, $isTaxIncluded, $amounttotax) = @_;

  my $tax = 0;

  foreach my $t (@{ $self->{entries} }) {
    if ($t->{type} eq "VALUE") {
      $tax += $t->{amount};
    } elsif ($t->{type} eq "PERCENT") {
      if ($isTaxIncluded) {
        $tax += (100*$amounttotax / (100+$t->{amount}) * ($t->{amount}/100) ) ;
      } else {
        $tax += $amounttotax * $t->{amount} / 100;
      }
    }
    else {
      die 'Unknown Taxtype' . $t->{type} ;
    }
  }
  return $tax;
}

1;
