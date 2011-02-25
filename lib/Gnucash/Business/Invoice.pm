package Invoice;

use Gnucash::Business::InvoiceEntry;
use Gnucash::Business::Customer;
use Gnucash::Business::Job;
use Date::Parse;
use XML::SimpleObject;

use strict;

## By Stefan Tomanek <stefan@pico.ruhr.de>

sub new($$$) {
    my ($proto, $gc, $id) = @_;
    
    my $self = {};
    $self->{id} = $id;	
    fillInfos($self, $gc);
    
    $self->{entries} = [];
    fillEntries($self, $gc);

    bless($self);
    return $self;
}

sub fillInfos($$) {
    my ($self, $xml) = @_;
    
    my @invoices = $xml->child("gnc-v2")->child("gnc:book")->children("gnc:GncInvoice");
    foreach (@invoices) {
        my $id = $_->child("invoice:id")->value();
        $id =~ s/^0*//g;
        next unless ($id eq $self->{id});
        
        $self->{guid} = $_->child("invoice:guid")->value();
        

        $self->{info}{opened} = str2time( $_->child("invoice:opened")->child("ts:date")->value() );

        if (defined $_->child("invoice:posted")) {
            $self->{info}{posted} = str2time( $_->child("invoice:posted")->child("ts:date")->value() );
        } 
	
        if ( $_->child("invoice:owner")->child("owner:type")->value() eq "gncJob" ) {
            $self->{customer} = new Job($xml, $_->child("invoice:owner")->child("owner:id")->value())->getCustomer();
        } elsif ($_->child("invoice:owner")->child("owner:type")->value() eq "gncCustomer") {
            $self->{customer} = new Customer($xml, $_->child("invoice:owner")->child("owner:id")->value() );
        }

        $self->{currency} = $_->child("invoice:currency")->child("cmdty:id")->value();

        if ($_->child("invoice:billing_id")) {
            $self->{billing_id} = $_->child("invoice:billing_id")->value();
        }

        last;
    }
}

sub fillEntries($$) {
    my ($self, $gc) = @_;
    my @entries = $gc->child("gnc-v2")->child("gnc:book")->children("gnc:GncEntry");
    my @items;
    foreach my $entry (@entries) {
        next unless ($entry->child("entry:invoice")->value() eq $self->{guid});
        
        my $entry = new InvoiceEntry( $gc, $entry->child("entry:guid")->value() );
        push @items, $entry;
    }
    @{ $self->{entries} } = sort { $a->{info}{date} <=> $b->{info}{date} } @items;
}


sub getNetSum($) {
    my ($self) = @_;
    
    my $sum = 0;
    foreach my $e (@{$self->{entries}}) {
	$sum += $e->getNetSum();
    }
    return $sum;
}

sub getTaxes($) {
    my ($self) = @_;

    my $tax = 0;
    foreach my $e (@{$self->{entries}}) {
	$tax += $e->getTax();
    }
    return $tax;
}

sub getCustomer($) {
    my ($self) = @_;

    return $self->{customer};
}

sub getEntries($) {
    my ($self) = @_;

    return $self->{entries};
}

sub getPostingDate($) {
    my ($self) = @_;
    return $self->{info}{posted};
}

sub getID($) {
    my ($self) = @_;
    return $self->{id};
}

sub getCurrency($) {
    my ($self) = @_;
    return $self->{currency};
}

sub getBillingID($) {
    my ($self) = @_;
    return $self->{billing_id};
}
1;
