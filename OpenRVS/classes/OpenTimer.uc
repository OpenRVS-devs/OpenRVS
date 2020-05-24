// OpenTimer provides convenience functions for measuring how long things take
class OpenTimer extends Object;

// Timing correlates a start time with a user-provided ID
struct Timing
{
	var transient string ID;//unique id for this timing, e.g. an IP address
	var transient int StartTime;
};

const ERR_VALUE = -1;

// Timings stores all timers in the class object
var private array<Timing> Timings;
var OpenMultiPlayerWidget LevelSource;//provides clock

// Custom constructor.
static function OpenTimer New(OpenMultiPlayerWidget OMPW)
{
	local OpenTimer ot;
	ot = new class'OpenTimer';
	ot.LevelSource = OMPW;
	return ot;
}

// Start the clock
function StartTimer(string id)
{
	local Timing t;
	local LevelInfo now;
	local int i;

	// Prevent writes for duplicate timings.
	for ( i=0; i<Timings.Length; i++ )
	{
		if ( Timings[i].ID == id )
			return;
	}

	t.ID = id;
	t.StartTime = int(LevelSource.GetLevel().TimeSeconds*1000);
	Timings[Timings.Length] = t;//Save this timing entry.
}

// Stop the clock and return the elapsed duration in milliseconds
function int EndTimer(string id)
{
	local Timing t;
	local int i;
	local int endTime;

	endTime = int(LevelSource.GetLevel().TimeSeconds*1000);

	// Find our timing ID
	t.StartTime = ERR_VALUE;
	for ( i=0; i<Timings.Length; i++ )
	{
		if ( Timings[i].ID == id )
		{
			t = Timings[i];
			break;
		}
	}
	Timings.Remove(i, 1);//We are done with this timing entry.

	// Never found matching start time
	if (t.StartTime == ERR_VALUE)
		return ERR_VALUE;

	return endTime - t.StartTime;
}