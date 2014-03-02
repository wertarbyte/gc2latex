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

sub CalculateDiscount {
  my $origAmount=$_[0];
  my $discType=$_[1];
  my $discount=$_[2];
  my $action=$_[3];

  if ($discType eq 'VALUE') {
    return $discount ;
  }
  elsif ($discType eq 'PERCENT') {
    return $discount * $origAmount / 100;
  }
  else {
      die 'Unknown DiscountType ' . $discType;
  }
}

sub getAmount ($$) {
    my ($self,$amounttype) = @_;
    my $subtotal = $self->getQuantity() * $self->getPrice();

    my $quantity = $self->getQuantity();
    my $price = $self->getPrice();

    my $tax = 0;

    if (getDiscountHow($self) eq 'PRETAX') {
      if (isTaxIncluded($self)) {
        # Discount calc before tax, but tax is include in unitprice
        $tax = $self->{taxtable}->CalculateTax(isTaxIncluded($self),$subtotal);
        $subtotal -= $tax;
        $subtotal -= CalculateDiscount($subtotal,getDiscountType($self),getDiscount($self),$self->getQuantity());
        $tax = $self->{taxtable}->CalculateTax(0,$subtotal);
      } else {
        # Discount calc before tax, tax is not in unitprice
        $subtotal -= CalculateDiscount($subtotal,getDiscountType($self),getDiscount($self),$self->getQuantity());
        $tax = $self->{taxtable}->CalculateTax(isTaxIncluded($self),$subtotal);
      }
    }
    elsif (getDiscountHow($self) eq 'SAMETIME') {
      if (isTaxIncluded($self)) {
        # Discount calc same as tax, but tax is include in unitprice
        $tax = $self->{taxtable}->CalculateTax(isTaxIncluded($self),$subtotal);
        $subtotal -= $tax;
        $subtotal -= CalculateDiscount($subtotal,getDiscountType($self),getDiscount($self),$self->getQuantity());
      } else {
        # Discount calc same as tax, tax is not in unitprice
        $tax = $self->{taxtable}->CalculateTax(isTaxIncluded($self),$subtotal);
        $subtotal -= CalculateDiscount($subtotal,getDiscountType($self),getDiscount($self),$self->getQuantity());
      }
    }
    elsif (getDiscountHow($self) eq 'POSTTAX') {
      if (isTaxIncluded($self)) {
        # Discount calc after tax, tax included in unitprice
        $tax = $self->{taxtable}->CalculateTax(isTaxIncluded($self),$subtotal);
        $subtotal -= CalculateDiscount($subtotal,getDiscountType($self),getDiscount($self),$self->getQuantity());
        $subtotal -= $tax;
      } else {
        # Discount caclc after tax, but tax is not included in unitprice
        $tax = $self->{taxtable}->CalculateTax(isTaxIncluded($self),$subtotal);
        $subtotal -= CalculateDiscount($subtotal+$tax,getDiscountType($self),getDiscount($self),$self->getQuantity());
      }
    }
    else
    {
      die 'Unknown Discount ' . getDiscountHow($self);
    }

    if ($amounttype eq 'SubTotal') {
      return $subtotal;
    }
    elsif ($amounttype eq 'Tax') {
      return $tax;
    }
    elsif ($amounttype eq 'Total') {
      return $tax + $subtotal;
    }
    else {
      die 'Unknown Amount ' . $amounttype ;
    }
}

sub round($) {
    my ($value) = @_;
    return int($value * 100 + 0.5) / 100;
}

1;
