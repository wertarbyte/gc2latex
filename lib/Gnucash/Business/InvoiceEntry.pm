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
        if ( $entry->child("entry:action") ) {
	  $self->{info}{action} = $entry->child("entry:action")->value();
        }
	$self->{info}{quantity} = 0;
	if ($entry->child("entry:qty")->value() =~ /(\d+)\/(\d+)/) {
	     $self->{info}{quantity} = $1/$2;
	}

	$self->{info}{price} = 0;
	if ($entry->child("entry:i-price")->value() =~ /(\d+)\/(\d+)/) {
	    $self->{info}{price} = $1/$2;
	}

        if ( $entry->child("entry:i-disc-type") ) {
	  $self->{info}{discounttype} = $entry->child("entry:i-disc-type")->value();
        }

        if ( $entry->child("entry:i-disc-how") ) {
	  $self->{info}{discounthow} = $entry->child("entry:i-disc-how")->value();
        }

	$self->{info}{discount} = 0;
        if ($entry->child("entry:i-discount")) {
          $entry->child("entry:i-discount")->value() =~ /(\d+)\/(\d+)/ ;
          $self->{info}{discount} = $1/$2;
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
sub getDiscount ($) { return $_[0]->{info}{discount}; }
sub getDiscountHow ($) { return $_[0]->{info}{discounthow}; }
sub getDiscountType ($) { return $_[0]->{info}{discounttype}; }
sub isTaxIncluded ($) { return $_[0]->{info}{taxincluded}; }

sub isTaxable ($) {
  my ($self) = @_;

  if (getTaxTable($self) eq '') {
    return 0;
  }else {
    return 1;
  }
}

sub getTaxTable ($) {
  my ($self) = @_;

  if ($self->{taxtable}) {
   return $self->{taxtable}->TaxTableName();
  }else{
   return '';
  }
}

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
    return round($sum);
}

sub getGrossSum ($) {
    my ($self) = @_;
    my $sum = getQuantity($self) * getPrice($self);
    if (not isTaxIncluded($self)) {
        $sum += $self->{taxtable}->calcTaxFromInvoiceEntry($self);
    }
    return round($sum);
}

sub getTax ($) {
    my ($self) = @_;
    return getGrossSum($self)-getNetSum($self);
}

sub round($) {
    my ($value) = @_;
    return int($value * 100 + 0.5) / 100;
}

1;
