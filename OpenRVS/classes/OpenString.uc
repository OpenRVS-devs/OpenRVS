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

// replaces "replace" with "with" in "Text"
// this function exists in Actor.uc but is not static and thus not available to non-actor objects
// thus, added here
static function string ReplaceText(string Text, string Replace, string With)
{
	local int i;
	local string Input;
	
	Input = Text;
	Text = "";
	i = InStr(Input, Replace);
	while ( i != -1 )
	{
		Text = Text $ Left(Input, i) $ With;
		Input = Mid(Input, i + Len(Replace));	
		i = InStr(Input, Replace);
	}
	Text = Text $ Input;
	return Text;
}
