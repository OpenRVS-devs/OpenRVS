class OpenString extends Object;

// The native (string).Split() function is missing in this game. Replace it.
// Only supports single-character separators.
static function int Split(string input, string sep, out array<string> fields)
{
	local int i;
	local bool done;

	fields.Remove(0, fields.Length);
	while (!done) {
		i = InStr(input, sep);
		if (i != -1)//sep is present, there are more fields
		{
			fields[fields.Length] = Mid(input, 0, i);//save the field text
			input = Mid(input, i+1);//trim the string for the next iteration
		}
		else//final field
		{
			if (Len(input) > 0)
				fields[fields.Length] = input;
			done = true;
		}
	}

	return fields.Length;
}

// Replaces '"text"' with 'text'.
static function string StripQuotes(string s)
{
	return Mid(s, 1, Len(s)-2);
}