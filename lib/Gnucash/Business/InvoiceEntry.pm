package InvoiceEntry;

use Gnucash::Business::TaxTable;

use XML::SimpleObject;
use Date::Parse;
use strict;

## By Stefan Tomanek <stefan@pico.ruhr.de>

sub new($$$) {
    my ($proto, $gc, $guid) = @_;
    my $self = {};

    $self->{guid} = $guid;
    
    fillInfo($self, $gc);
    
    bless($self);
    return $self;
}

sub fillInfo($$) {
    my ($self, $gc) = @_;
    
    my @entries = $gc->child("gnc-v2")->child("gnc:book")->children("gnc:GncEntry");
    foreach my $entry (@entries) {
	next unless ($entry->child("entry:guid")->value() eq $self->{guid});
	
	$self->{info}{date} = str2time($entry->child("entry:date")->child("ts:date")->value());
	$self->{info}{description} = $entry->child("entry:description")->value();
	$self->{info}{action} = $entry->child("entry:action")->value();
	
	$self->{info}{quantity} = 0;
	if ($entry->child("entry:qty")->value() =~ /(\d+)\/(\d+)/) {
	     $self->{info}{quantity} = $1/$2;
	}

	$self->{info}{price} = 0;
	if ($entry->child("entry:i-price")->value() =~ /(\d+)\/(\d+)/) {
	    $self->{info}{price} = $1/$2;
	}

	$self->{info}{taxincluded} = $entry->child("entry:i-taxincluded")->value();
	
	my $taxid = 0;
	if ( $entry->child("entry:i-taxable")->value() && $entry->child("entry:i-taxtable") ) {
	    $taxid = $entry->child("entry:i-taxtable")->value();
	}
	$self->{taxtable} = new TaxTable($gc, $taxid);
	
	last;
    }
}

sub getDate ($) { return $_[0]->{info}{date}; }
sub getDescription ($) { return $_[0]->{info}{description}; }
sub getAction ($) { return $_[0]->{info}{action}; }
sub getQuantity ($) { return $_[0]->{info}{quantity}; }
sub getPrice ($) { return $_[0]->{info}{price}; }
sub isTaxIncluded ($) { return $_[0]->{info}{taxincluded}; }

sub getNetPrice ($) {
    my ($self) = @_;
    my $price = $self->getPrice();
    if (isTaxIncluded($self)) {
        $price -= $self->{taxtable}->calcTaxFromInvoiceEntry($self) / $self->getQuantity();
    }
    return $price;
}

sub getNetSum ($) {
    my ($self) = @_;
    my $sum = $self->getQuantity() * $self->getNetPrice();
    return $sum;
}

sub getGrossSum ($) {
    my ($self) = @_;
    my $sum = getQuantity($self) * getPrice($self);
    if (not isTaxIncluded($self)) {
        $sum += $self->{taxtable}->calcTaxFromInvoiceEntry($self);
    }
    return $sum;
}

sub getTax ($) {
    my ($self) = @_;
    return getGrossSum($self)-getNetSum($self);
}

1;
