#!./parrot-nqp
# Copyright (C) 2010, Parrot Foundation.

# Checking for OpLib num and skip files parsing.

pir::tag('load')_bytecode("opsc.pbc");

plan(2);

my $lib := Ops::OpLib.new(
    :skip_file('src/ops/ops.skip'),
);

ok( $lib.op_skip_table<abs_i_ic>,       "'abs_i_ic' in skiptable");
ok( $lib.op_skip_table<ne_nc_nc_ic>,    "'ne_nc_nc_ic' in skiptable");
#_dumper($lib.skiptable);

# vim: expandtab shiftwidth=4 ft=perl6:
