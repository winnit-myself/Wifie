#!perl
# Copyright (C) 2006-2016, Parrot Foundation.

use strict;
use warnings;
use lib qw( . lib ../lib ../../lib );

use Test::More;
use Parrot::Test tests => 27;

=head1 NAME

t/pmc/stringhandle.t - test the StringHandle PMC

=head1 SYNOPSIS

    % prove t/pmc/stringhandle.t

=head1 DESCRIPTION

Tests the StringHandle PMC.

=cut

# L<PDD22/I\/O PMC API/=item new>
pir_output_is( <<'CODE', <<'OUT', 'new' );
.sub 'test' :main
    new $P0, ['StringHandle']
    say "ok 1 - $P0 = new ['StringHandle']"
.end
CODE
ok 1 - $P0 = new ['StringHandle']
OUT

# L<PDD22/I\/O PMC API/=item open.*=item close>
pir_output_is( <<"CODE", <<'OUT', 'open and close - synchronous' );
.sub 'test' :main
    \$P1 = new ['StringHandle']
    \$P1.'open'('README.pod')
    say 'ok 1 - \$P1.open(\$S1)'

    \$P1.'close'()
    say 'ok 2 - \$P1.close()'

    \$P3 = new ['StringHandle']
    \$P3.'open'('temp_file', 'rw')
    say 'ok 3 - \$P3.open(\$S1, \$S2) # rw mode'
    \$P3.'close'()

    \$P3.'open'()
    say 'ok 4 - \$P3.open()         # reopening'
    \$P3.'close'()

  test_7:
    \$P7 = new ['StringHandle']
    \$P7.'open'('temp_file', 'w')
    say 'ok 7 - \$P7.open(\$S1, \$S2) # new file, write mode succeeds'

    goto end

  end:
.end
CODE
ok 1 - $P1.open($S1)
ok 2 - $P1.close()
ok 3 - $P3.open($S1, $S2) # rw mode
ok 4 - $P3.open()         # reopening
ok 7 - $P7.open($S1, $S2) # new file, write mode succeeds
OUT

pir_output_is( <<'CODE', <<'OUT', 'get_bool' );
.sub test :main
    .local pmc sh
    .local int b
    sh = new ['StringHandle']
    b = 0
    unless sh goto b_false
    b = 1
  b_false:
    say b
    sh.'open'('mockname', 'w')
    sh.'print'('Some content')
    sh.'close'()
    sh.'open'()
    b = 0
    unless sh goto b_true
    b = 1
  b_true:
    say b
.end
CODE
0
1
OUT

# StringHandle doesn't use file descriptor, get_fd always return -1
pir_output_is( <<'CODE', <<'OUT', 'get_fd method' );
.sub test :main
    .local pmc sh
    .local int fd
    sh = new ['StringHandle']
    fd = sh.'get_fd'()
    say fd
    sh.'open'('mockname', 'r')
    fd = sh.'get_fd'()
    say fd
.end
CODE
-1
-1
OUT

SKIP: {
    skip 'no async calls yet' => 1;

    pir_output_is( <<'CODE', <<'OUT', 'open and close - asynchronous' );
.sub 'test' :main
    $P1 = # GH #535 create a callback here
    $P0 = new ['StringHandle']

    $P0.'open'('README.pod')
    say 'ok 1 - $P0.open($S1)'

    $P0.'close'()
    say 'ok 2 - $P0.close($P1)'

    $P0.'open'('README.pod', 'rw')
    say 'ok 3 - $P0.open($S1, $S2)'

    $P0.'close'()
    $P0.'open'()
    say 'ok 4 - $P0.open()'

  cleanup:
    $P0.'close'()
.end
CODE
ok 1 - $P0.open($S1)
ok 2 - $P0.close()
ok 3 - $P0.open($S1, $S2)
ok 4 - $P0.open()
OUT
}

# L<PDD22/I\/O PMC API/=item read>
pir_output_is(
    <<'CODE', <<'OUT', 'read - synchronous' );
.sub 'test' :main
    $P0 = new ['StringHandle']
    $P0.'open'('README.pod', 'w')

    $P0.'print'("# Copyright (C) 2001-2012, Parrot Foundation.")

    $P0.'close'()

    $P0.'open'('README.pod')

    $S0 = $P0.'read'(15) # bytes
    if $S0 == '# Copyright (C)' goto ok_1
    print 'not '
  ok_1:
    say 'ok 1 - $S0 = $P1.read($I2)'

    $S0 = $P0.'read'(12)  # throw away bytes
    $S0 = $P0.'read'(17)  # bytes
    if $S0 == 'Parrot Foundation' goto ok_2
    print 'not '
  ok_2:
    say 'ok 2 - $S0 = $P1.read($I2) # again on same stream'
.end
CODE
ok 1 - $S0 = $P1.read($I2)
ok 2 - $S0 = $P1.read($I2) # again on same stream
OUT

pir_output_is(
    <<'CODE', <<'OUT', 'read opcode' );
.sub 'test' :main
    $P0 = new ['StringHandle']
    $P0.'open'('README.pod', 'w')

    print $P0, "# Copyright (C) 2001-2012, Parrot Foundation."
    $P0.'close'()

    $P0.'open'('README.pod')

    $S0 = $P0.'read'(15) # bytes
    if $S0 == '# Copyright (C)' goto ok_1
    print 'not '
  ok_1:
    say 'ok 1 - $S0 = $P1.read($I2)'

    $S0 = $P0.'read'(12)  # throw away bytes
    $S0 = $P0.'read'(17)  # bytes
    if $S0 == 'Parrot Foundation' goto ok_2
    print 'not '
  ok_2:
    say 'ok 2 - $S0 = $P1.read($I2) # again on same stream'
.end
CODE
ok 1 - $S0 = $P1.read($I2)
ok 2 - $S0 = $P1.read($I2) # again on same stream
OUT

# L<PDD22/I\/O PMC API/=item print>
pir_output_is( <<"CODE", <<'OUT', 'print - synchronous' );
.sub 'test' :main

    \$P0 = new ['StringHandle']
    \$P0.'open'('temp_file', 'w')

    \$P0.'print'(123)
    say 'ok 1 - \$P0.print(\$I1)'
    \$P0.'print'(456.789)
    say 'ok 2 - \$P0.print(\$N1)'
    \$P0.'print'("squawk\\n")
    say 'ok 3 - \$P0.print(\$S1)'
    \$P1 = new ['Integer']
    \$P1 = 42
    \$P0.'print'(\$P1)
    say 'ok 4 - \$P0.print(\$P1)'

    \$P0.'close'()

    \$P0.'open'('temp_file', 'r')

    \$S0 = \$P0.'read'(3) # bytes
    if \$S0 == "123" goto ok_5
    print 'not '
  ok_5:
    say 'ok 5 - read integer back from file'

    \$S0 = \$P0.'read'(16) # bytes
    if \$S0 == "456.789squawk\\n42" goto ok_6
    say \$S0

    print 'not '
  ok_6:
    say 'ok 6 - read string back from file'

    \$P0.'close'()
.end
CODE
ok 1 - $P0.print($I1)
ok 2 - $P0.print($N1)
ok 3 - $P0.print($S1)
ok 4 - $P0.print($P1)
ok 5 - read integer back from file
ok 6 - read string back from file
OUT

pir_output_is( <<'CODE', <<'OUT', 'print errors', todo => 'no errors until 8.3.0' );
.include 'except_types.pasm'
.sub 'test' :main
    .local pmc sh, eh
    .local int result
    sh = new ['StringHandle']
    eh = new ['ExceptionHandler']
    eh.'handle_types'(.EXCEPTION_PIO_ERROR)
    push_eh eh

    # print to SH not opened
    result = 0
    set_label eh, handle1
    sh.'print'('something')
    result = 1
    goto done1
handle1:
    finalize eh
done1:
    say result

    # print to SH opened for reading throws an error
    result = 0
    set_label eh, handle2
    sh.'open'('mockname', 'r')
    sh.'print'('something')
    result = 1
    goto done2
handle2:
    finalize eh
done2:
    say result
.end
CODE
0
0
OUT

pir_output_is( <<'CODE', <<'OUT', 'read/write mode errors', todo => 'no errors until 8.3.0' );
.include 'except_types.pasm'
.sub 'test' :main
    .local pmc sh, eh
    .local int result
    sh = new ['StringHandle']
    eh = new ['ExceptionHandler']
    eh.'handle_types'(.EXCEPTION_PIO_ERROR)
    push_eh eh

    # read from SH not yet opened
    result = 0
    set_label eh, handle1
    $S0 = sh.'read'(1)
    result = 1
    goto done1
handle1:
    finalize eh
done1:
    say result

    # read from SH opened for writing throws an error
    result = 0
    set_label eh, handle2
    sh.'open'('mockname', 'w')
    result = sh.'peek'()
    result = 1
    goto done2
handle2:
    finalize eh
done2:
    say result
.end
CODE
0
0
OUT

# L<PDD22/I\/O PMC API/=item print.*=item readline>
pir_output_is( <<"CODE", <<'OUT', 'readline - synchronous' );
.sub 'test' :main
    load_bytecode 'String/Utils.pbc'
    .local pmc chomp
               chomp = get_global ['String';'Utils'], 'chomp'

    \$P0 = new ['StringHandle']
    \$P0.'open'('temp_file', 'w')
    \$P0.'print'("foobarbaz\\n42")
    \$P0.'close'()

    \$P0.'open'('temp_file')

    \$S0 = \$P0.'readline'()
    \$S0 = chomp( \$S0 )
    if \$S0 == 'foobarbaz' goto ok_1
    print 'not '
  ok_1:
    say 'ok 1 - \$S0 = \$P0.readline()'

    \$S0 = \$P0.'readline'()
    \$S0 = chomp( \$S0 )
    if \$S0 == '42' goto ok_2
    print 'not '
  ok_2:
    say 'ok 2 - \$S0 = \$P0.readline() # again on same stream'

    \$P0.'close'()
.end
CODE
ok 1 - $S0 = $P0.readline()
ok 2 - $S0 = $P0.readline() # again on same stream
OUT

pir_output_is( <<'CODE', <<'OUT', 'readline 10,000 lines' );
.sub 'test' :main
    load_bytecode 'String/Utils.pbc'
    .local pmc chomp
               chomp = get_global ['String';'Utils'], 'chomp'
    .local string test_line
    .local pmc stringhandle
    .local int counter
    stringhandle = new ['StringHandle']

    stringhandle.'open'('temp_file', 'w')

    counter = 0
  write_loop:
    inc counter
    if counter > 10000 goto end_write_loop

    stringhandle.'print'(counter)
    stringhandle.'print'("\n")

    goto write_loop
  end_write_loop:
    stringhandle.'close'()
    stringhandle.'open'('temp_file')

    counter = 0
  read_loop:
    inc counter
    # read in the file one line at a time...
    $I0 = stringhandle.'eof'()
    if $I0 goto end_read_loop

    test_line = stringhandle.'readline'()
    if test_line == "" goto end_read_loop
    test_line = chomp( test_line )
    $I1 = test_line
    if $I1 == counter goto read_loop
      print "not "
## the following lines provide more extensive debugging
## output on a readline failure
#      print counter
#      print " = "
#      print $I1
#      print "\n"
#      counter = $I1
#      goto read_loop

  end_read_loop:
    if counter > 9000 goto read_something
      print "not "
  read_something:
    say 'ok 1 - read 10,000 lines'
    stringhandle.'close'()
.end
CODE
ok 1 - read 10,000 lines
OUT


# GH #535 test reading long chunks, eof, and across newlines

# GH #535 pir_output_is( <<'CODE', <<'OUT', 'print, read, and readline - asynchronous', todo => 'not yet implemented' );

# L<PDD22/I\/O PMC API/=item record_separator>
pir_output_is( <<'CODE', <<'OUT', 'record_separator', todo => 'not yet implemented' );
.sub 'test' :main
    $P0 = new ['StringHandle']

    $S0 = $P0.'record_separator'()
    if $S0 == "\n" goto ok_1
    print 'not '
  ok_1:
    say 'ok 1 - $S0 = $P1.record_separator() # default'

    $S99 = 'abc'
    $P0.'record_separator'($S99)
    $S0 = $P0.'record_separator'()
    if $S0 == $S99 goto ok_2
    print 'not '
  ok_2:
    say 'ok 2 - $P0.record_separator($S1)'

    $P0.'print'(123)
    $S0 = $P0.'record_separator'()
    $P0.'print'($S0)
    $P0.'print'(456)

    $S0 = $P0.'readline'()
    if $S0 == '123abc' goto ok_3
    print 'not '
  ok_3:
    say 'ok 3 - $P0.record_separator() # .readline works as expected'
.end
CODE
ok 1 - $S0 = $P1.record_separator() # default
ok 2 - $P0.record_separator($S1)
ok 3 - $P0.record_separator() # .readline works as expected
OUT

# L<PDD22/I\/O PMC API/=item buffer_type>
pir_output_is( <<'CODE', <<'OUT', 'buffer_type' );
.sub 'test' :main
    $P0 = new ['StringHandle']

    $P0.'buffer_type'('unbuffered')
    $S0 = $P0.'buffer_type'()
    if $S0 == 'unbuffered' goto ok_1
    print 'not '
  ok_1:
    say 'ok 1 - $S0 = $P1.buffer_type() # unbuffered'

    $P0.'buffer_type'('line-buffered')
    $S0 = $P0.'buffer_type'()
    if $S0 == 'line-buffered' goto ok_2
    print 'not '
  ok_2:
    say 'ok 2 - $S0 = $P1.buffer_type() # line-buffered'

    $P0.'buffer_type'('full-buffered')
    $S0 = $P0.'buffer_type'()
    if $S0 == 'full-buffered' goto ok_3
    print 'not '
  ok_3:
    say 'ok 3 - $S0 = $P1.buffer_type() # full-buffered'

.end
CODE
ok 1 - $S0 = $P1.buffer_type() # unbuffered
ok 2 - $S0 = $P1.buffer_type() # line-buffered
ok 3 - $S0 = $P1.buffer_type() # full-buffered
OUT

# GH #535 test effects of buffer_type, not just set/get

# GH #458
# L<PDD22/I\/O PMC API/=item buffer_size>
# NOTES: try setting positive, zero, negative int
# perform print and read ops
# change buffer size while it contains data
# try with all 'buffer_type' modes

pir_output_is( <<"CODE", <<'OUT', 'buffer_size' );
.sub 'test' :main
    \$P0 = new ['StringHandle']

    \$P0.'buffer_type'('full-buffered')
    \$P0.'buffer_size'(42)
    say 'ok 1 - \$P0.buffer_size(42)     # set buffer size'

    \$P0.'open'('temp_file', 'w')
    \$P0.'print'(1234567890)

    \$I0 = \$P0.'buffer_size'()

    # The set buffer size is a minimum, the I/O subsystem may scale it upward
    # to a round block, so test that the buffer size is equal or greater than
    # the set size.
    if \$I0 >= 10 goto ok_2
    print 'not '
  ok_2:
    say 'ok 2 - \$I0 = \$P0.buffer_size() # get buffer size'

    \$P0.'close'()

    \$P0.'open'('temp_file')
    \$S0 = \$P0.'readline'()

    if \$S0 == '1234567890' goto ok_3
    print 'not '
  ok_3:
    say 'ok 3 - \$S0 = \$P0.readline()    # buffer flushed'

    \$P0.'close'()

.end
CODE
ok 1 - $P0.buffer_size(42)     # set buffer size
ok 2 - $I0 = $P0.buffer_size() # get buffer size
ok 3 - $S0 = $P0.readline()    # buffer flushed
OUT

# L<PDD22/I\/O PMC API/=item encoding>
pir_output_is( <<'CODE', <<'OUT', 'encoding' );
.sub 'test' :main
    $P0 = new ['StringHandle']

    $P0.'encoding'('utf8')
    $S0 = $P0.'encoding'()
    if $S0 == 'utf8' goto ok_1
    print 'not '
  ok_1:
    say 'ok 1 - $S0 = $P1.encoding() # utf8'

.end
CODE
ok 1 - $S0 = $P1.encoding() # utf8
OUT

pir_output_is( <<"CODE", <<'OUT', 'encoding - read/write' );
.sub 'test' :main
    \$P0 = new ['StringHandle']
    \$P0.'encoding'('utf8')

    \$P0.'open'('temp_file', 'w')

    \$P0.'print'(1234567890)
    \$P0.'print'("\\n")
    \$S0 = iso-8859-1:"T??TSCH"
    \$I9 = find_encoding "utf8"
    \$S9 = trans_encoding \$S0, \$I9
    \$P0.'print'(\$S0)
    \$P0.'close'()

    \$P0.'open'('temp_file')

    \$S1 = \$P0.'readline'()
    if \$S1 == "1234567890\\n" goto ok_1

    print 'not '
  ok_1:
    say 'ok 1 - \$S1 = \$P0.readline() # read with utf8 encoding on'

    \$S2 = \$P0.'readline'()
    if \$S2 == \$S9 goto ok_2

    print 'not '
  ok_2:
    say 'ok 2 - \$S2 = \$P0.readline() # read iso-8859-1 string'

    \$P0.'close'()

.end
CODE
ok 1 - $S1 = $P0.readline() # read with utf8 encoding on
ok 2 - $S2 = $P0.readline() # read iso-8859-1 string
OUT


# L<PDD22/I\/O PMC API/=item mode>
pir_output_is( <<'CODE', <<'OUT', 'mode' );
.sub 'test' :main
    $P0 = new ['StringHandle']

    $P0.'open'('README.pod')
    $S0 = $P0.'mode'()

    if $S0 == 'r' goto ok_1
    print 'not '
  ok_1:
    say 'ok 1 - $S0 = $P0.mode() # get read mode'

    $P0.'close'()

.end
CODE
ok 1 - $S0 = $P0.mode() # get read mode
OUT

pir_output_is( <<"CODE", <<"OUTPUT", "readall an reopened handle" );
.sub main :main
    \$S0 = <<"EOS"
line 1
line 2
line 3
EOS
    .local pmc pio, pio2
    pio = new ['StringHandle']
    pio.'open'("temp_file", "w")
    pio.'print'(\$S0)
    pio.'close'()
    pio.'open'("temp_file")
    \$S1 = pio.'readall'('temp_file')
    if \$S0 == \$S1 goto ok
    print "not "
ok:
    say "ok"
.end
CODE
ok
OUTPUT

pir_output_is( <<"CODE", <<"OUTPUT", "readall - flushed stringhandle errors", todo => 'no errors until 8.3.0' );
.sub main :main
    .local pmc sh
    .local string s
    sh = new ['StringHandle']
    sh.'open'('mockname', 'r')
    # Open sets content to an empty string, flush resets is to null
    # and that is the case we are testing here.
    # Also, ensures coverage of the flush method.
    sh.'flush'()
    push_eh E1
    sh.'readall'()
    s = "error1"
E1:
    pop_eh
    print '['
    print s
    say ']'

    sh.'open'('mockname', 'r')
    sh.'seek'(0, 0)
    push_eh E2
    s = sh.'readall'()
    s = "error2"
E2:
    pop_eh

    print '['
    print s
    say ']'
.end
CODE
[error1]
[]
OUTPUT

pir_output_is( <<"CODE", <<"OUTPUT", "readall() - rw stringhandle" );
.sub main :main
    \$S0 = <<"EOS"
line 1
line 2
line 3
EOS
    .local pmc pio, pio2
    pio = new ['StringHandle']
    pio.'open'("temp_file", "rw")
    pio.'print'(\$S0)
    pio.'seek'(0, 0)
    \$S1 = pio.'readall'()
    if \$S0 == \$S1 goto ok
    print "not "
ok:
    say "ok"
.end
CODE
ok
OUTPUT

pir_output_is( <<'CODE', <<"OUTPUT", "is_closed" );
.sub main :main
    .local pmc sh
    .local int i
    sh = new ['StringHandle']
    i = sh.'is_closed'()
    say i
    sh.'open'("foo", "w")
    i = sh.'is_closed'()
    say i
.end
CODE
1
0
OUTPUT

pir_output_is( <<'CODE', <<'OUTPUT', 'StringHandle is not a tty' );
.sub main :main
    .local pmc sh
    .local int i
    sh = new ['StringHandle']

    i = sh.'isatty'()
    say i
.end
CODE
0
OUTPUT

pir_output_is( <<"CODE", <<"OUTPUT", "readall() - on closed stringhandle", todo => 'no errors until 8.3.0' );
.include 'except_types.pasm'
.sub 'main' :main
    .local pmc ifh, eh
    .local int result
    ifh = new ['StringHandle']
    ifh.'encoding'('utf8')

    eh = new ['ExceptionHandler']
    eh.'handle_types'(.EXCEPTION_PIO_ERROR)
    push_eh eh
    result = 0
    set_label eh, handle1
    \$S0 = ifh.'readall'()
    result = 1
    goto done1
handle1:
    finalize eh
done1:

    say result
.end
CODE
0
OUTPUT

pir_output_is( <<"CODE", <<"OUTPUT", "readall() - utf8 on opened stringhandle" );
.sub 'main' :main
    .local pmc ifh
    ifh = new ['StringHandle']
    ifh.'encoding'('utf8')
    ifh.'open'('temp_file')

    \$S0 = ifh.'readall'()

    \$I0 = encoding \$S0
    \$S1 = encodingname \$I0

    say \$S1
.end
CODE
utf8
OUTPUT

pir_output_is( <<'CODE', <<'OUTPUT', "clone an uninitialized stringhandle" );
.sub 'main' :main
    $P0 = new ['StringHandle']
    $P1 = clone $P0
    say "ok"
.end
CODE
ok
OUTPUT

# GH 1011 FileHandle analog methods
pir_output_is( <<'CODE', <<"OUTPUT", "seek/tell/peek stringhandle" );
.sub 'main' :main
    .local pmc ifh
    ifh = new ['StringHandle']
    ifh.'encoding'('utf8')
    ifh.'open'('README.pod', 'rw')
    ifh.'puts'('# Copyright (C) 2001-2014, Parrot Foundation.')

    ifh.'seek'(0, 27)
    $S0 = ifh.'read'(17)
    if $S0 == 'Parrot Foundation' goto ok_1
    print 'not '
    print $S0
  ok_1:
    say 'ok 1 - seek 0,28'

    $I0 = ifh.'tell'()
    if $I0 == 45 goto ok_2
    print 'not '
    print $I0
  ok_2:
    say 'ok 2 - tell'

    $S0 = ifh.'peek'() # one byte
    if $S0 == '.' goto ok_3
    print 'not '
    print $S0
  ok_3:
    say 'ok 3 - peek value'

    $I0 = ifh.'tell'()
    if $I0 == 45 goto ok_4
    print 'not '
    print $I0
  ok_4:
    say 'ok 4 - peek does not advance'
    ifh.'close'()
.end
CODE
ok 1 - seek 0,28
ok 2 - tell
ok 3 - peek value
ok 4 - peek does not advance
OUTPUT


# GH #465
# L<PDD22/I\/O PMC API/=item get_fd>
# NOTES: this is going to be platform dependent

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
