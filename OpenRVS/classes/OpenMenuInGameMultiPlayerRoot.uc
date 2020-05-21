//fixes disappearing server list
//implements custom FOV
//IMPORTANT - weapon will render inaccurately at custom FOV unless server implements Render Fix!

class OpenMenuInGameMultiPlayerRoot extends R6MenuInGameMultiPlayerRootWindow;

var R6PlayerController PC;
var int Count;
var int FOV;
var OpenFOV OpenFOV;

//1.0 - fixes the disappearing server list, makes the escape menu just use disconnect console command
function PopUpBoxDone(MessageBoxResult Result,ePopUpID _ePopUpID)
{
	if ( Result == MR_OK )
	{
		if ( _ePopUpID == EPopUpID_LeaveInGameToMultiMenu )
		{
			R6Console(Root.console).ConsoleCommand("disconnect");
			return;
		}
	}
	super.PopUpBoxDone(Result,_ePopUpID);
}

//1.4 FOV
//a function that will let us load custom fov
function ChangeCurrentWidget( eGameWidgetID widgetID )
{
	super.ChangeCurrentWidget(widgetID);
	if ( FOV == 0 )
	{
		OpenFOV = new class'OpenFOV';
		FOV = OpenFOV.GetFOV();
		if ( FOV != 0 )
			FOV = clamp(FOV,65,140);
		OpenFOV = none;
	}
}

//1.4 FOV
//force new FOV so we don't start first round with
function Paint(Canvas C,float X,float Y)
{
	if ( FOV != 0 )
	{
		if ( GetPlayerOwner() != none )
		{
			if ( R6PlayerController(GetPlayerOwner()) != none )
			{
				if ( R6PlayerController(GetPlayerOwner()).default.DefaultFOV != FOV )
				{
					R6PlayerController(GetPlayerOwner()).default.DefaultFOV = FOV;
					R6PlayerController(GetPlayerOwner()).default.DesiredFOV = FOV;
				}
				//this section to fix spawning first round with 90 FOV
				if ( ( R6PlayerController(GetPlayerOwner()).DefaultFOV != FOV ) && ( !R6PlayerController(GetPlayerOwner()).m_bHelmetCameraOn ) )
				{
					R6PlayerController(GetPlayerOwner()).DefaultFOV = FOV;
					R6PlayerController(GetPlayerOwner()).DesiredFOV = FOV;
				}
			}
		}
	}
	super.Paint(C,X,Y);
}