module globals;

import bindbc.sdl;
import bindbc.opengl;

import types;
import widget;
import frame;

__gshared {
    SDL_GLContext glcontext;
    SDL_Window *sdl_window;

    enum SCREEN_WIDTH  = 640;
    enum SCREEN_HEIGHT = 480;

    int CUR_WIN_WIDTH = SCREEN_WIDTH;
    int CUR_WIN_HEIGHT = SCREEN_HEIGHT;

    Frame root;
}

@nogc nothrow:

bool isPointInRect(Point p, Rect r) {
    
    return
        p.x <= r.x + r.w &&
        p.x >= r.x &&
        p.y <= r.y + r.h &&
        p.y >= r.y;

}