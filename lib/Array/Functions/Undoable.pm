package Array::Functions::Undoable;
# ABSTRACT: Array manipulation functions that support undo operation

use 5.010;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(afu);

our %SPEC;

$SPEC{afu} = {
    summary => "Perform undoable array operations",
    args=>{
        op   => ['str*' => {
            summary => 'Operation on array',
            in      => [qw/pop push shift unshift pluck/],
                       # splice sort shuffle reverse
        }],
        ary  => ['array*' => {
            summary=>'The array',
        }],
        item => ['any' => {
            summary => 'Item to insert to array',
            description => <<'_',

Required when doing these operations: unshift, push.

_
        }],
    },
    features=>{undo=>1},
};
sub afu {
    my %args  = @_;

    my $undo_action = $args{-undo_action} // 'do'; # we always save undo info
    my $undo_data   = $args{-undo_data};
    my $is_undo     = $undo_action eq 'undo';

    my $op    = $args{op}
        or return [400, "Please specify op"];
    my $ary   = $args{ary}
        or return [400, "Please specify ary"];
    ref($ary) eq 'ARRAY'
        or return [400, "Invalid ary: must be an arrayref"];
    my $item  = $args{item};
    if ($op =~ /^(unshift|push)$/ && !$is_undo) {
        exists($args{item}) or return [400, "Please specify item"];
    }

    my $steps;
    if ($is_undo) {
        $steps = $undo_data
            or return [400, "Please supply -undo_data"];
    } else {
        $steps = [];
        if ($op eq 'push') {
            push @$steps, ['insert-item', scalar(@$ary), $item];
        } elsif ($op eq 'pop') {
            push @$steps, ['remove-item', scalar(@$ary)-1];
        } elsif ($op eq 'unshift') {
            push @$steps, ['insert-item', 0, $item];
        } elsif ($op eq 'shift') {
            push @$steps, ['remove-item', 0];
        } elsif ($op eq 'pluck') {
            push @$steps, ['remove-item', int(rand()*@$ary)]
                if @$ary;
        } else {
            return [400, "Unknown op: $op"];
        }
    }

    my $changed;
    my $undo_steps = [];
    for my $i (0..@$steps-1) {
        my $step = $steps->[$i];
        if ($step->[0] eq 'remove-item') {
            next unless @$ary;
            my $pos = $step->[1];
            push @$undo_steps, ['insert-item', $pos, $ary->[$pos]];
            splice @$ary, $pos, 1;
            $changed++;
        } elsif ($step->[0] eq 'insert-item') {
            my $pos = $step->[1];
            push @$undo_steps, ['remove-item', $pos];
            splice @$ary, $pos, 0, $step->[2];
            $changed++;
        } else {
            die "BUG: unknown step command: $step->[0]";
        }
    }
    my $meta = {};
    $meta->{undo_data} = $undo_steps;
    return [$changed ? 200:304, $changed? "OK":"Nothing done", undef, $meta];
}

1;
__END__

=head1 SYNOPSIS

 use Array::Functions::Undoable qw(afu);

 # raw "low-level" functional interface
 my $ary = [0, 1, 2, 3];
 my $res1 = afu(op=>'pop'    , ary=>$ary);          # ary now [0, 1, 2]
 my $res2 = afu(op=>'pluck'  , ary=>$ary);          # ary now [0, 2]
 my $res3 = afu(op=>'unshift', ary=>$ary, item=>4); # ary now [4, 0, 2]

 # undo
 afu(op=>'unshift', ary=>$ary, -undo_action=>'undo',
     -undo_data=>$res3->[3]{undo_data});      # ary now [0, 2]
 afu(op=>'pluck'  , ary=>$ary, -undo_action=>'undo',
     -undo_data=>$res2->[3]{undo_data});      # ary now [0, 1, 2]
 afu(op=>'pop'    , ary=>$ary, -undo_action=>'undo',
     -undo_data=>$res1->[3]{undo_data});      # ary now [0, 1, 2, 3]

 # nicer OO interface, which provides an undo stack. not yet implemented.

 my $afu = Array::Functions::Undoable->new;
 $ary = [0, 1, 2, 3]

 $afu->pop($ary);        # ary now [0, 1, 2]
 $afu->pluck($ary);      # ary now [0, 2]
 $afu->unshift($ary, 4); # ary now [4, 0, 2]

 $afu->undo;             # ary now [0, 2]
 $afu->redo;             # ary now [4, 0, 2]

 $afu->undo;             # ary now [0, 2]
 $afu->undo;             # ary now [0, 1, 2]
 $afu->undo;             # ary now [0, 1, 2, 3]

 $afu->undo;             # does nothing, undo stack empty


=head1 DESCRIPTION

This module provides the usual array manipulation functionalities like for
popping, pushing, splicing, but with undo capability. It is currently used just
for testing the L<Sub::Spec> undo protocol and other Sub::Spec modules like
L<Sub::Spec::Runner>.


=head1 FUNCTIONS

None of the functions are exported by default, but they are exportable.


=head1 SEE ALSO

L<Sub::Spec>

=cut

