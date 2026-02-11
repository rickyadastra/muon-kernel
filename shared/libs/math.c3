module std::math;

import lang;

const DOUBLE_MANT_DIG = 53;
const DOUBLE_MAX_EXP = 1024;
const DOUBLE_EPSILON = 2.22044604925031308085e-16;

macro max(x, y, ...)
{
	$if $vacount == 0:
		return $$max(x, y);
	$else
		var m = $$max(x, y);
		$for var $i = 0; $i < $vacount; $i++:
			m = $$max(m, $vaarg[$i]);
		$endfor
		return m;
	$endif
}

macro min(x, y, ...)
{
	$if $vacount == 0:
		return $$min(x, y);
	$else
		var m = $$min(x, y);
		$for var $i = 0; $i < $vacount; $i++:
			m = $$min(m, $vaarg[$i]);
		$endfor
		return m;
	$endif
}

macro int signbit(x) {
	$switch $typeof(x):
	$case float:
	$case float16:
		return bitcast((float)x, uint) >> 31;
	$default:
		return (int)(bitcast((double)x, ulong) >> 63);
	$endswitch
}

macro bool is_finite(x) {
	$switch $typeof(x):
		$case float:
		$case float16:
			return bitcast((float)x, uint) & 0x7fffffff < 0x7f800000;
		$default:
			return bitcast((double)x, ulong) & (~0UL >> 1) < 0x7ffUL << 52;
	$endswitch
}

macro is_nan(x) {
	$switch $typeof(x):
	$case float:
	$case float16:
		return bitcast((float)x, uint) & 0x7fffffff > 0x7f800000;
	$default:
		return bitcast((double)x, ulong) & (~0UL >> 1) > 0x7ffUL << 52;
	$endswitch
}

macro is_inf(x) {
	$switch $typeof(x):
	$case float:
	$case float16:
		return bitcast((float)x, uint) & 0x7fffffff == 0x7f800000;
	$default:
		return bitcast((double)x, ulong) & (~0UL >> 1) == 0x7ffUL << 52;
	$endswitch
}

macro frexp(x, int* e) {
	$switch $typeof(x):
	$case float:
	$case float16:
		return _frexpf((float)x, e);
	$default:
		return _frexp((double)x, e);
	$endswitch
}

fn double _frexp(double x, int* e) {
	ulong i = bitcast(x, ulong);
	int ee = (int)((i >> 52) & 0x7ff);
	switch
	{
		case !ee:
			if (!x)
			{
				*e = 0;
				return x;
			}
			x = _frexp(x * 0x1p64, e);
			*e -= 64;
			return x;
		case ee == 0x7ff:
			return x;
		default:
			*e = ee - 0x3fe;
			i &= 0x800fffffffffffffUL;
			i |= 0x3fe0000000000000UL;
			return bitcast(i, double);
	}
}

fn float _frexpf(float x, int* e) {
	uint i = bitcast(x, uint);
	int ee = (i >> 23) & 0xff;

	switch
	{
		case !ee:
			if (!x)
			{
				*e = 0;
				return x;
			}
			x = _frexpf(x * 0x1p64, e);
			*e -= 64;
			return x;
		case ee == 0xff:
			return x;
		default:
			*e = ee - 0x7e;
			i &= 0x807fffffU;
			i |= 0x3f000000U;
			return bitcast(i, float);
	}
}

macro sqrt(x) => $$sqrt(values::promote_int(x));
