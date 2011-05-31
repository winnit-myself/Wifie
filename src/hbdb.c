/* Copyright (C) 2001-2010, Parrot Foundation. */

/* TODO Remove unnecessary header files */
/* TODO Add perldoc                     */

#include "parrot/runcore_api.h"
#include "parrot/extend.h"
#include "parrot/embed.h"
#include "parrot/runcore_profiling.h"
#include "parrot/oplib/core_ops.h"

#include "pmc/pmc_sub.h"
#include "pmc/pmc_callcontext.h"
#include "pmc/pmc_namespace.h"

/* HEADERIZER HFILE: include/parrot/hbdb.h */

/*

=item C<INTVAL hbdb_get_line_number(PARROT_INTERP, PMC *context_pmc)>

Return the line number for the current context

=cut

*/

INTVAL
hbdb_get_line_number(PARROT_INTERP, ARGIN(PMC *context_pmc))
{
    ASSERT_ARGS(hbdb_get_line_number)

    INTVAL line_num;
    Parrot_Context * const context = PMC_data_typed(context_pmc, Parrot_Context *);

    line_num = Parrot_sub_get_line_from_pc(interp,
                                           Parrot_pcc_get_sub(interp, context_pmc),
                                           context->current_pc);

    return line_num;
}

/*
 * Local variables:
 *   c-file-style: "parrot"
 * End:
 * vim: expandtab shiftwidth=4 cinoptions='\:2=2' :
 */

