module globals;

import bindbc.sdl;
import bindbc.opengl;

import types;
import widget;

__gshared {
    SDL_GLContext glcontext;
    SDL_Window *sdl_window;

    enum SCREEN_WIDTH  = 800;
    enum SCREEN_HEIGHT = 600;

    int CUR_WIN_WIDTH = SCREEN_WIDTH;
    int CUR_WIN_HEIGHT = SCREEN_HEIGHT;

    Sizer root;
}

@nogc nothrow:

bool isPointInRect(Point p, Rect r) {
    
    return
        p.x <= r.x + r.w &&
        p.x >= r.x &&
        p.y <= r.y + r.h &&
        p.y >= r.y;

}