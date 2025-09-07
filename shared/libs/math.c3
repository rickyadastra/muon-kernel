module std::math;

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
