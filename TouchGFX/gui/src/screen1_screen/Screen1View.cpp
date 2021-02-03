#include <gui/screen1_screen/Screen1View.hpp>
#include <touchgfx/widgets/TextArea.hpp>
Screen1View::Screen1View()
{

}

void Screen1View::setupScreen()
{
	Unicode::snprintf(textArea1Buffer, 10, "%d", -580); 
	textArea1.resizeToCurrentText();
	Unicode::snprintf(textArea2Buffer, 10, "%d", 5);
	Unicode::snprintf(textArea3Buffer, 10, "%d", 5);
	textArea1.invalidate();
	textArea2.invalidate();


    Screen1ViewBase::setupScreen();
}

void Screen1View::tearDownScreen()
{
    Screen1ViewBase::tearDownScreen();
}

void Screen1View::updateTxt(int newValue)
{	

	

}