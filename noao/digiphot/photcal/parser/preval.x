include	"../lib/parser.h"
include	"../lib/preval.h"

# Evaluation stack depth
define	STACK_DEPTH		50


# PR_EVAL - Evaluate an RPN code expression generated by the parser. This
# procedure checks for consistency in the input, although the code generated
# by the parser should be correct, and for stack underflow and overflow.
# The underflow can only happen under wrong generated code, but overflow
# can happen in complex expressions. This is not a syntactic, but related
# with the number of parenthesis used in the original source code expression.
# Illegal operations, such as division by zero, return and undefined value.

real procedure pr_eval (code, vdata, pdata)

pointer	code			# RPN code buffer
real	vdata[ARB]		# variables
real	pdata[ARB]		# parameters

real	pr_evs ()

begin
	return (pr_evs (code, vdata, pdata))
end


# PR_EV[SILRDX] - These procedures are called in chain, one for each indirect
# call to an equation expression (recursion). In this way it is possible to
# have up to six levels of indirection. Altough it works well, this is a patch,
# and should be replaced with a more elegant procedure that keeps a stack of
# indirect calls.


real procedure pr_evs (code, vdata, pdata)

pointer	code			# RPN code buffer
real	vdata[ARB]		# variables
real	pdata[ARB]		# parameters

char	str[SZ_LINE]
int	ip			# instruction pointer
int	sp			# stack pointer
int	ins			# current instruction
int	sym			# equation symbol
real	stack[STACK_DEPTH]	# evaluation stack
real	dummy
pointer	caux, paux

real	pr_evi ()
pointer	pr_gsym(), pr_gsymp()

begin
	# Set the instruction pointer (offset from the
	# beginning) to the first instruction in the buffer
	ip = 0

	# Get first instruction from the code buffer
	ins = Memi[code + ip]

	# Reset execution stack pointer
	sp = 0

	# Returned value when recursion overflows
	dummy = INDEFR

	# Loop reading instructions from the code buffer
	# until the end-of-code instruction is found
	while (ins != PEV_EOC) {

	    # Branch on the instruction type
	    switch (ins) {

	    case PEV_NUMBER:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = Memr[code + ip]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_CATVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_OBSVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_PARAM:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = pdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_SETEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_SETEQ)
		caux = pr_gsymp (sym, PSEQRPNEQ)

		stack[sp] = pr_evi (caux, vdata, pdata)

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_EXTEQ:
		# not yet implemented
		ip = ip + 1
		sp = sp + 1
		stack[sp] = INDEFR
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_TRNEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_TRNEQ)
		caux = pr_gsymp (sym, PTEQRPNFIT)
		paux = pr_gsymp (sym, PTEQSPARVAL)

		stack[sp] = pr_evi (caux, vdata, Memr[paux])

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_UPLUS:
		# do nothing

	    case PEV_UMINUS:
		stack[sp] = - stack[sp]

	    case PEV_PLUS:
		stack[sp - 1] = stack[sp - 1] + stack[sp]
		sp = sp - 1

	    case PEV_MINUS:
		stack[sp - 1] = stack[sp - 1] - stack[sp]
		sp = sp - 1

	    case PEV_STAR:
		stack[sp - 1] = stack[sp - 1] * stack[sp]
		sp = sp - 1

	    case PEV_SLASH:
		if (stack[sp] != 0) {
		    stack[sp - 1] = stack[sp - 1] / stack[sp]
		    sp = sp - 1
		} else {
		    stack[sp - 1] = INDEFR
		    sp = sp - 1
		    break
		}

	    case PEV_EXPON:
		if (stack[sp - 1] != 0)
		    stack[sp - 1] = stack[sp - 1] ** stack[sp]
		else
		    stack[sp - 1] = 0.0
		sp = sp - 1

	    case PEV_ABS:
		stack[sp] = abs (stack[sp])

	    case PEV_ACOS:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = acos (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ASIN:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = asin (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ATAN:
		stack[sp] = atan (stack[sp])

	    case PEV_COS:
		stack[sp] = cos (stack[sp])

	    case PEV_EXP:
		stack[sp] = exp (stack[sp])

	    case PEV_LOG:
		if (stack[sp] > 0.0)
		    stack[sp] = log (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_LOG10:
		if (stack[sp] > 0.0)
		    stack[sp] = log10 (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_SIN:
		stack[sp] = sin (stack[sp])

	    case PEV_SQRT:
		if (stack[sp] >= 0.0)
		    stack[sp] = sqrt (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_TAN:
		stack[sp] = tan (stack[sp])

	    default:	# (just in case)
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation code error (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack overflow. This is the 
	    # only check really needed.
	    if (sp >= STACK_DEPTH) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack overflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack underflow (just in case)
	    if (sp < 1) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack underflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Get next instruction
	    ip = ip + 1
	    ins = Memi[code + ip]
	}

	# Return expression value
	return (stack[sp])
end


real procedure pr_evi (code, vdata, pdata)

pointer	code			# RPN code buffer
real	vdata[ARB]		# variables
real	pdata[ARB]		# parameters

char	str[SZ_LINE]
int	ip			# instruction pointer
int	sp			# stack pointer
int	ins			# current instruction
int	sym			# equation symbol
real	stack[STACK_DEPTH]	# evaluation stack
real	dummy
pointer	caux, paux

real	pr_evl ()
pointer	pr_gsym(), pr_gsymp()

begin
	# Set the instruction pointer (offset from the
	# beginning) to the first instruction in the buffer
	ip = 0

	# Get first instruction from the code buffer
	ins = Memi[code + ip]

	# Reset execution stack pointer
	sp = 0

	# Returned value when recursion overflows
	dummy = INDEFR

	# Loop reading instructions from the code buffer
	# until the end-of-code instruction is found
	while (ins != PEV_EOC) {

	    # Branch on the instruction type
	    switch (ins) {

	    case PEV_NUMBER:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = Memr[code + ip]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_CATVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_OBSVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_PARAM:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = pdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_SETEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_SETEQ)
		caux = pr_gsymp (sym, PSEQRPNEQ)

		stack[sp] = pr_evl (caux, vdata, pdata)

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_EXTEQ:
		# not yet implemented
		ip = ip + 1
		sp = sp + 1
		stack[sp] = INDEFR
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_TRNEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_TRNEQ)
		caux = pr_gsymp (sym, PTEQRPNFIT)
		paux = pr_gsymp (sym, PTEQSPARVAL)

		stack[sp] = pr_evl (caux, vdata, Memr[paux])

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_UPLUS:
		# do nothing

	    case PEV_UMINUS:
		stack[sp] = - stack[sp]

	    case PEV_PLUS:
		stack[sp - 1] = stack[sp - 1] + stack[sp]
		sp = sp - 1

	    case PEV_MINUS:
		stack[sp - 1] = stack[sp - 1] - stack[sp]
		sp = sp - 1

	    case PEV_STAR:
		stack[sp - 1] = stack[sp - 1] * stack[sp]
		sp = sp - 1

	    case PEV_SLASH:
		if (stack[sp] != 0) {
		    stack[sp - 1] = stack[sp - 1] / stack[sp]
		    sp = sp - 1
		} else {
		    stack[sp - 1] = INDEFR
		    sp = sp - 1
		    break
		}

	    case PEV_EXPON:
		if (stack[sp - 1] != 0)
		    stack[sp - 1] = stack[sp - 1] ** stack[sp]
		else
		    stack[sp - 1] = 0.0
		sp = sp - 1

	    case PEV_ABS:
		stack[sp] = abs (stack[sp])

	    case PEV_ACOS:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = acos (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ASIN:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = asin (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ATAN:
		stack[sp] = atan (stack[sp])

	    case PEV_COS:
		stack[sp] = cos (stack[sp])

	    case PEV_EXP:
		stack[sp] = exp (stack[sp])

	    case PEV_LOG:
		if (stack[sp] > 0.0)
		    stack[sp] = log (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_LOG10:
		if (stack[sp] > 0.0)
		    stack[sp] = log10 (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_SIN:
		stack[sp] = sin (stack[sp])

	    case PEV_SQRT:
		if (stack[sp] >= 0.0)
		    stack[sp] = sqrt (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_TAN:
		stack[sp] = tan (stack[sp])

	    default:	# (just in case)
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation code error (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack overflow. This is the 
	    # only check really needed.
	    if (sp >= STACK_DEPTH) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack overflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack underflow (just in case)
	    if (sp < 1) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack underflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Get next instruction
	    ip = ip + 1
	    ins = Memi[code + ip]
	}

	# Return expression value
	return (stack[sp])
end


real procedure pr_evl (code, vdata, pdata)

pointer	code			# RPN code buffer
real	vdata[ARB]		# variables
real	pdata[ARB]		# parameters

char	str[SZ_LINE]
int	ip			# instruction pointer
int	sp			# stack pointer
int	ins			# current instruction
int	sym			# equation symbol
real	stack[STACK_DEPTH]	# evaluation stack
real	dummy
pointer	caux, paux

real	pr_evr ()
pointer	pr_gsym(), pr_gsymp()

begin
	# Set the instruction pointer (offset from the
	# beginning) to the first instruction in the buffer
	ip = 0

	# Get first instruction from the code buffer
	ins = Memi[code + ip]

	# Reset execution stack pointer
	sp = 0

	# Returned value when recursion overflows
	dummy = INDEFR

	# Loop reading instructions from the code buffer
	# until the end-of-code instruction is found
	while (ins != PEV_EOC) {

	    # Branch on the instruction type
	    switch (ins) {

	    case PEV_NUMBER:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = Memr[code + ip]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_CATVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_OBSVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_PARAM:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = pdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_SETEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_SETEQ)
		caux = pr_gsymp (sym, PSEQRPNEQ)

		stack[sp] = pr_evr (caux, vdata, pdata)

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_EXTEQ:
		# not yet implemented
		ip = ip + 1
		sp = sp + 1
		stack[sp] = INDEFR
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_TRNEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_TRNEQ)
		caux = pr_gsymp (sym, PTEQRPNFIT)
		paux = pr_gsymp (sym, PTEQSPARVAL)

		stack[sp] = pr_evr (caux, vdata, Memr[paux])

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_UPLUS:
		# do nothing

	    case PEV_UMINUS:
		stack[sp] = - stack[sp]

	    case PEV_PLUS:
		stack[sp - 1] = stack[sp - 1] + stack[sp]
		sp = sp - 1

	    case PEV_MINUS:
		stack[sp - 1] = stack[sp - 1] - stack[sp]
		sp = sp - 1

	    case PEV_STAR:
		stack[sp - 1] = stack[sp - 1] * stack[sp]
		sp = sp - 1

	    case PEV_SLASH:
		if (stack[sp] != 0) {
		    stack[sp - 1] = stack[sp - 1] / stack[sp]
		    sp = sp - 1
		} else {
		    stack[sp - 1] = INDEFR
		    sp = sp - 1
		    break
		}

	    case PEV_EXPON:
		if (stack[sp - 1] != 0)
		    stack[sp - 1] = stack[sp - 1] ** stack[sp]
		else
		    stack[sp - 1] = 0.0
		sp = sp - 1

	    case PEV_ABS:
		stack[sp] = abs (stack[sp])

	    case PEV_ACOS:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = acos (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ASIN:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = asin (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ATAN:
		stack[sp] = atan (stack[sp])

	    case PEV_COS:
		stack[sp] = cos (stack[sp])

	    case PEV_EXP:
		stack[sp] = exp (stack[sp])

	    case PEV_LOG:
		if (stack[sp] > 0.0)
		    stack[sp] = log (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_LOG10:
		if (stack[sp] > 0.0)
		    stack[sp] = log10 (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_SIN:
		stack[sp] = sin (stack[sp])

	    case PEV_SQRT:
		if (stack[sp] >= 0.0)
		    stack[sp] = sqrt (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_TAN:
		stack[sp] = tan (stack[sp])

	    default:	# (just in case)
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation code error (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack overflow. This is the 
	    # only check really needed.
	    if (sp >= STACK_DEPTH) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack overflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack underflow (just in case)
	    if (sp < 1) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack underflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Get next instruction
	    ip = ip + 1
	    ins = Memi[code + ip]
	}

	# Return expression value
	return (stack[sp])
end


real procedure pr_evr (code, vdata, pdata)

pointer	code			# RPN code buffer
real	vdata[ARB]		# variables
real	pdata[ARB]		# parameters

char	str[SZ_LINE]
int	ip			# instruction pointer
int	sp			# stack pointer
int	ins			# current instruction
int	sym			# equation symbol
real	stack[STACK_DEPTH]	# evaluation stack
real	dummy
pointer	caux, paux

real	pr_evd ()
pointer	pr_gsym(), pr_gsymp()

begin
	# Set the instruction pointer (offset from the
	# beginning) to the first instruction in the buffer
	ip = 0

	# Get first instruction from the code buffer
	ins = Memi[code + ip]

	# Reset execution stack pointer
	sp = 0

	# Returned value when recursion overflows
	dummy = INDEFR

	# Loop reading instructions from the code buffer
	# until the end-of-code instruction is found
	while (ins != PEV_EOC) {

	    # Branch on the instruction type
	    switch (ins) {

	    case PEV_NUMBER:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = Memr[code + ip]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_CATVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_OBSVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_PARAM:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = pdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_SETEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_SETEQ)
		caux = pr_gsymp (sym, PSEQRPNEQ)

		stack[sp] = pr_evd (caux, vdata, pdata)

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_EXTEQ:
		# not yet implemented
		ip = ip + 1
		sp = sp + 1
		stack[sp] = INDEFR
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_TRNEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_TRNEQ)
		caux = pr_gsymp (sym, PTEQRPNFIT)
		paux = pr_gsymp (sym, PTEQSPARVAL)

		stack[sp] = pr_evd (caux, vdata, Memr[paux])

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_UPLUS:
		# do nothing

	    case PEV_UMINUS:
		stack[sp] = - stack[sp]

	    case PEV_PLUS:
		stack[sp - 1] = stack[sp - 1] + stack[sp]
		sp = sp - 1

	    case PEV_MINUS:
		stack[sp - 1] = stack[sp - 1] - stack[sp]
		sp = sp - 1

	    case PEV_STAR:
		stack[sp - 1] = stack[sp - 1] * stack[sp]
		sp = sp - 1

	    case PEV_SLASH:
		if (stack[sp] != 0) {
		    stack[sp - 1] = stack[sp - 1] / stack[sp]
		    sp = sp - 1
		} else {
		    stack[sp - 1] = INDEFR
		    sp = sp - 1
		    break
		}

	    case PEV_EXPON:
		if (stack[sp - 1] != 0)
		    stack[sp - 1] = stack[sp - 1] ** stack[sp]
		else
		    stack[sp - 1] = 0.0
		sp = sp - 1

	    case PEV_ABS:
		stack[sp] = abs (stack[sp])

	    case PEV_ACOS:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = acos (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ASIN:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = asin (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ATAN:
		stack[sp] = atan (stack[sp])

	    case PEV_COS:
		stack[sp] = cos (stack[sp])

	    case PEV_EXP:
		stack[sp] = exp (stack[sp])

	    case PEV_LOG:
		if (stack[sp] > 0.0)
		    stack[sp] = log (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_LOG10:
		if (stack[sp] > 0.0)
		    stack[sp] = log10 (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_SIN:
		stack[sp] = sin (stack[sp])

	    case PEV_SQRT:
		if (stack[sp] >= 0.0)
		    stack[sp] = sqrt (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_TAN:
		stack[sp] = tan (stack[sp])

	    default:	# (just in case)
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation code error (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack overflow. This is the 
	    # only check really needed.
	    if (sp >= STACK_DEPTH) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack overflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack underflow (just in case)
	    if (sp < 1) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack underflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Get next instruction
	    ip = ip + 1
	    ins = Memi[code + ip]
	}

	# Return expression value
	return (stack[sp])
end


real procedure pr_evd (code, vdata, pdata)

pointer	code			# RPN code buffer
real	vdata[ARB]		# variables
real	pdata[ARB]		# parameters

char	str[SZ_LINE]
int	ip			# instruction pointer
int	sp			# stack pointer
int	ins			# current instruction
int	sym			# equation symbol
real	stack[STACK_DEPTH]	# evaluation stack
real	dummy
pointer	caux, paux

real	pr_evx ()
pointer	pr_gsym(), pr_gsymp()

begin
	# Set the instruction pointer (offset from the
	# beginning) to the first instruction in the buffer
	ip = 0

	# Get first instruction from the code buffer
	ins = Memi[code + ip]

	# Reset execution stack pointer
	sp = 0

	# Returned value when recursion overflows
	dummy = INDEFR

	# Loop reading instructions from the code buffer
	# until the end-of-code instruction is found
	while (ins != PEV_EOC) {

	    # Branch on the instruction type
	    switch (ins) {

	    case PEV_NUMBER:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = Memr[code + ip]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_CATVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_OBSVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_PARAM:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = pdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_SETEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_SETEQ)
		caux = pr_gsymp (sym, PSEQRPNEQ)

		stack[sp] = pr_evx (caux, vdata, pdata)

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_EXTEQ:
		# not yet implemented
		ip = ip + 1
		sp = sp + 1
		stack[sp] = INDEFR
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_TRNEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_TRNEQ)
		caux = pr_gsymp (sym, PTEQRPNFIT)
		paux = pr_gsymp (sym, PTEQSPARVAL)

		stack[sp] = pr_evx (caux, vdata, Memr[paux])

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_UPLUS:
		# do nothing

	    case PEV_UMINUS:
		stack[sp] = - stack[sp]

	    case PEV_PLUS:
		stack[sp - 1] = stack[sp - 1] + stack[sp]
		sp = sp - 1

	    case PEV_MINUS:
		stack[sp - 1] = stack[sp - 1] - stack[sp]
		sp = sp - 1

	    case PEV_STAR:
		stack[sp - 1] = stack[sp - 1] * stack[sp]
		sp = sp - 1

	    case PEV_SLASH:
		if (stack[sp] != 0) {
		    stack[sp - 1] = stack[sp - 1] / stack[sp]
		    sp = sp - 1
		} else {
		    stack[sp - 1] = INDEFR
		    sp = sp - 1
		    break
		}

	    case PEV_EXPON:
		if (stack[sp - 1] != 0)
		    stack[sp - 1] = stack[sp - 1] ** stack[sp]
		else
		    stack[sp - 1] = 0.0
		sp = sp - 1

	    case PEV_ABS:
		stack[sp] = abs (stack[sp])

	    case PEV_ACOS:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = acos (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ASIN:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = asin (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ATAN:
		stack[sp] = atan (stack[sp])

	    case PEV_COS:
		stack[sp] = cos (stack[sp])

	    case PEV_EXP:
		stack[sp] = exp (stack[sp])

	    case PEV_LOG:
		if (stack[sp] > 0.0)
		    stack[sp] = log (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_LOG10:
		if (stack[sp] > 0.0)
		    stack[sp] = log10 (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_SIN:
		stack[sp] = sin (stack[sp])

	    case PEV_SQRT:
		if (stack[sp] >= 0.0)
		    stack[sp] = sqrt (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_TAN:
		stack[sp] = tan (stack[sp])

	    default:	# (just in case)
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation code error (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack overflow. This is the 
	    # only check really needed.
	    if (sp >= STACK_DEPTH) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack overflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack underflow (just in case)
	    if (sp < 1) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack underflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Get next instruction
	    ip = ip + 1
	    ins = Memi[code + ip]
	}

	# Return expression value
	return (stack[sp])
end


real procedure pr_evx (code, vdata, pdata)

pointer	code			# RPN code buffer
real	vdata[ARB]		# variables
real	pdata[ARB]		# parameters

char	str[SZ_LINE]
int	ip			# instruction pointer
int	sp			# stack pointer
int	ins			# current instruction
int	sym			# equation symbol
real	stack[STACK_DEPTH]	# evaluation stack
real	dummy
pointer	caux, paux

pointer	pr_gsym(), pr_gsymp()

begin
	# Set the instruction pointer (offset from the
	# beginning) to the first instruction in the buffer
	ip = 0

	# Get first instruction from the code buffer
	ins = Memi[code + ip]

	# Reset execution stack pointer
	sp = 0

	# Returned value when recursion overflows
	dummy = INDEFR

	# Loop reading instructions from the code buffer
	# until the end-of-code instruction is found
	while (ins != PEV_EOC) {

	    # Branch on the instruction type
	    switch (ins) {

	    case PEV_NUMBER:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = Memr[code + ip]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_CATVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_OBSVAR:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = vdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_PARAM:
		ip = ip + 1
		sp = sp + 1
		stack[sp] = pdata[Memi[code + ip]]
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_SETEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_SETEQ)
		caux = pr_gsymp (sym, PSEQRPNEQ)

		stack[sp] = dummy

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_EXTEQ:
		# not yet implemented
		ip = ip + 1
		sp = sp + 1
		stack[sp] = INDEFR
		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_TRNEQ:
		ip = ip + 1
		sp = sp + 1

		sym = pr_gsym (Memi[code + ip], PTY_TRNEQ)
		caux = pr_gsymp (sym, PTEQRPNFIT)
		paux = pr_gsymp (sym, PTEQSPARVAL)

		stack[sp] = dummy

		if (IS_INDEFR (stack[sp]))
		    break

	    case PEV_UPLUS:
		# do nothing

	    case PEV_UMINUS:
		stack[sp] = - stack[sp]

	    case PEV_PLUS:
		stack[sp - 1] = stack[sp - 1] + stack[sp]
		sp = sp - 1

	    case PEV_MINUS:
		stack[sp - 1] = stack[sp - 1] - stack[sp]
		sp = sp - 1

	    case PEV_STAR:
		stack[sp - 1] = stack[sp - 1] * stack[sp]
		sp = sp - 1

	    case PEV_SLASH:
		if (stack[sp] != 0) {
		    stack[sp - 1] = stack[sp - 1] / stack[sp]
		    sp = sp - 1
		} else {
		    stack[sp - 1] = INDEFR
		    sp = sp - 1
		    break
		}

	    case PEV_EXPON:
		if (stack[sp - 1] != 0)
		    stack[sp - 1] = stack[sp - 1] ** stack[sp]
		else
		    stack[sp - 1] = 0.0
		sp = sp - 1

	    case PEV_ABS:
		stack[sp] = abs (stack[sp])

	    case PEV_ACOS:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = acos (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ASIN:
		if (abs (stack[sp]) <= 1.0)
		    stack[sp] = asin (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_ATAN:
		stack[sp] = atan (stack[sp])

	    case PEV_COS:
		stack[sp] = cos (stack[sp])

	    case PEV_EXP:
		stack[sp] = exp (stack[sp])

	    case PEV_LOG:
		if (stack[sp] > 0.0)
		    stack[sp] = log (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_LOG10:
		if (stack[sp] > 0.0)
		    stack[sp] = log10 (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_SIN:
		stack[sp] = sin (stack[sp])

	    case PEV_SQRT:
		if (stack[sp] >= 0.0)
		    stack[sp] = sqrt (stack[sp])
		else {
		    stack[sp] = INDEFR
		    break
		}

	    case PEV_TAN:
		stack[sp] = tan (stack[sp])

	    default:	# (just in case)
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation code error (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack overflow. This is the 
	    # only check really needed.
	    if (sp >= STACK_DEPTH) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack overflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Check for stack underflow (just in case)
	    if (sp < 1) {
		call sprintf (str, SZ_LINE,
		"pr_eval: Evaluation stack underflow (code=%d ip=%d ins=%d sp=%d)")
		    call pargi (code)
		    call pargi (ip)
		    call pargi (ins)
		    call pargi (sp)
		call error (0, str)
	    }

	    # Get next instruction
	    ip = ip + 1
	    ins = Memi[code + ip]
	}

	# Return expression value
	return (stack[sp])
end
