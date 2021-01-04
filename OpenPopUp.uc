class OpenPopUp extends Object;

// A simple object that allows creation of a pop up box at any time, with no concrete references neede

static function OpenPopUpWindow CreatePopUp(optional string sTitle,optional int iWidth,optional int iHeight)
{
	local OpenPopUpWindow Window;
	local Canvas C;
	
	C = class'Actor'.static.GetCanvas();
	if ( ( C == none ) || ( C.Viewport == none ) || ( C.Viewport.Console == none ) )//won't work on a server
		return none;
	Window = OpenPopUpWindow(R6Console(C.Viewport.Console).Root.CreateWindow(class'OpenPopUpWindow',0,0,640,480));
	Window.BuildPopUp(sTitle,iWidth,iHeight);
	return Window;
}