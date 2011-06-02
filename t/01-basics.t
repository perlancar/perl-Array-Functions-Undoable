#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More 0.96;

use Array::Functions::Undoable qw(afu);

my $ary;
my $undo_data;

$ary = [0, 1, 2, 3];
test_afu(op => "push", undo => 0, item => 10, result => [0, 1, 2, 3, 10]);
test_afu(op => "push", undo => 1, item => 10, result => [0, 1, 2, 3]);
test_afu(name => "push (redo)",
         op => "push", undo => 1, item => 10, result => [0, 1, 2, 3, 10]);

$ary = [0, 1, 2, 3];
test_afu(op => "pop", undo => 0, result => [0, 1, 2]);
test_afu(op => "pop", undo => 1, result => [0, 1, 2, 3]);
test_afu(name => "pop (redo)",
         op => "pop", undo => 1, result => [0, 1, 2]);

$ary = [0, 1, 2, 3];
test_afu(op => "unshift", undo => 0, item => 10, result => [10, 0, 1, 2, 3]);
test_afu(op => "unshift", undo => 1, item => 10, result => [0, 1, 2, 3]);
test_afu(name => "unshift (redo)",
         op => "unshift", undo => 1, item => 10, result => [10, 0, 1, 2, 3]);

$ary = [0, 1, 2, 3];
test_afu(op => "shift", undo => 0, result => [1, 2, 3]);
test_afu(op => "shift", undo => 1, result => [0, 1, 2, 3]);
test_afu(name => "shift (redo)",
         op => "shift", undo => 1, result => [1, 2, 3]);

# XXX test pluck

$ary = [];
test_afu(name => 'remove on empty element -> 304',
         op => "pop", status => 304, result => []);

DONE_TESTING:
done_testing();

my %test_name_counters;
sub test_afu {
    my (%args) = @_;

    my $test_name = $args{name};
    if (!$test_name) {
        $test_name = "$args{op} ".(++$test_name_counters{$args{op}});
        $test_name .= " (undo)" if $args{undo};
    }

    subtest $test_name => sub {
        my %sub_args = (op => $args{op}, ary => $ary);
        if (exists $args{item}) { $sub_args{item} = $args{item} }
        if ($args{undo}) {
            $sub_args{-undo_action} = 'undo';
            $sub_args{-undo_data}   = $undo_data;
        }
        my $res = afu(%sub_args);
        $undo_data = $res->[3]{undo_data};

        $args{status} //= 200;
        is($res->[0], $args{status}, "status is $args{status}");

        if ($args{result}) {
            is_deeply($ary, $args{result}, "result") or diag explain $ary;
        }

        if ($args{posttest}) {
            $args{posttest}->($res);
        }
    };
}

