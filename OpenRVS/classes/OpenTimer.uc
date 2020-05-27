// OpenTimer provides convenience functions for measuring how long things take
// Example usage:
//   var OpenTimer Timer;
//   var int Duration;
//   Timer = new class'OpenTimer';
//   Timer.ClockSource = GetEntryLevel();//Level provides clock
//   Timer.StartTimer("my-timer-id");
//   Duration = Timer.EndTimer("my-timer-id");
// Timer IDs are unique. Attempting to create a timer with a repeat ID will not
// overwrite the existing timer (reusing its start time).
// When a Timer is ended, its data is deleted from the set.
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
//var OpenMultiPlayerWidget LevelSource;//provides clock
var LevelInfo ClockSource;//provides clock

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
	t.StartTime = int(ClockSource.TimeSeconds*1000);
	Timings[Timings.Length] = t;//Save this timing entry.
	class'OpenLogger'.static.Debug("started timer with id" @ t.ID @ "at time" @ t.StartTime, self);
}

// Stop the clock and return the elapsed duration in milliseconds
function int EndTimer(string id)
{
	local Timing t;
	local int i;
	local int endTime;
	local bool found;

	endTime = int(ClockSource.TimeSeconds*1000);

	// Find our timing ID
	for ( i=0; i<Timings.Length; i++ )
	{
		if ( Timings[i].ID == id )
		{
			found = true;
			t = Timings[i];
			break;
		}
	}

	if (!found)
	{
		class'OpenLogger'.static.Debug("timing not found with id=" $ id, self);
		return ERR_VALUE;
	}

	class'OpenLogger'.static.Debug("timing '" $ t.ID $ "' had start time" @ t.StartTime $ ", end time" @ endTime $ ", and duration" @ endTime - t.StartTime, self);
	Timings.Remove(i, 1);//We are done with this timing entry.
	return endTime - t.StartTime;
}

// Write the current time (in ms since level start) to the log file.
function LogTime()
{
	class'OpenLogger'.static.Debug("the time is now" @ int(ClockSource.TimeSeconds*1000), self);
}