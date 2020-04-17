module drawobjects;

import types;
import primitivesogl;

@nogc nothrow:

void resize(int w, int h){
    _resize(w, h);
}

void drawRect(Filling = HOLLOW)(Rect r, Color cl){
    _drawRect!Filling(r, cl);
}

void drawLine(Point p1, Point p2, Color cl){
    _drawLine(p1, p2, cl);
}

void renderText(const(char)* message, Color color, int x, int y, int size){
    _renderText(message, color, x, y, size);
}

void drawRoundedRectGradientFill(float x, float y, float width, float height,
    float radius, Color topColor, Color bottomColor){
        _drawRoundedRectGradientFill(x, y, width, height,radius, topColor, bottomColor);
}

void drawRoundedRectBorder(int x, int y, int width, int height, int radius, Color color){
    _drawRoundedRectBorder(x, y, width, height, radius, color);
}