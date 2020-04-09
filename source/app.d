import core.stdc.stdio;

import bindbc.sdl;
import bindbc.opengl;
import dvector;

import boilerplate;
import util;
import primitives;
import globals;
import types;
import widget;

Sizer vl;

@nogc nothrow:

extern (C) int main(){
    initSDL();
    initSDLTTF();
    initGL();
    initUtil();

	glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

    vl = Sizer("vl1", vertical, Point(100, 150), 150, 200);

    Widget w1 = Widget("w1");

    void changeColor(Widget* wid) @nogc nothrow {
        wid.color = Color(rnd!float(0.0f, 1.0f), rnd!float(0.0f, 1.0f), rnd!float(0.0f, 1.0f));
    }

    w1.setClickHandler(&changeColor);

    Widget w2 = Widget("w2");
    Widget w3 = Widget("w3");
    Widget w4 = Widget("w4");
    Sizer h1 = Sizer("h1", horizontal);

    vl.add(w1);
    vl.add(w2);
    vl.add(h1); // another Sizer
    vl.add(w3);
    vl.add(w4);
    
    auto wh1 = Widget("wh1");
    auto wh2 = Widget("wh2");
    auto wh3 = Widget("wh3");

    h1.add(wh1);
    h1.add(wh2);
    h1.add(wh3);

    

    void onClicked(Widget* wi) @nogc nothrow {
        printf("%s has clicked! \n", wi.id.ptr);
    }

    wh2.setClickHandler(&onClicked);
    w3.setClickHandler(&onClicked);

    mainLoop;

    SDL_GL_DeleteContext(glcontext);
    SDL_DestroyWindow(sdl_window);
    SDL_Quit();

    return 0;
}

void mainLoop(){
    bool quit;

    SDL_Event event;

    while (!quit){
        while( SDL_PollEvent( &event ) != 0 ){
            switch(event.type){
                case SDL_QUIT:
                    quit = true;
                    break;
                case SDL_KEYDOWN:
                    switch (event.key.keysym.sym){
                        case SDLK_ESCAPE:
                            quit = true;
                            break;
                        default:
                            break;
                    }
                    break;
                case SDL_WINDOWEVENT:
                    if(event.window.event == SDL_WINDOWEVENT_RESIZED){
                        SDL_GetWindowSize(sdl_window, &CUR_WIN_WIDTH, &CUR_WIN_HEIGHT);
                        resize(CUR_WIN_WIDTH, CUR_WIN_HEIGHT);
                    }
                    break;
                case SDL_MOUSEMOTION:
                    void cb(Window* widget) @nogc nothrow {
                        if(widget.typeId != TYPE_SIZER &&
                            isPointInRect(Point(event.motion.x, event.motion.y), widget.rect)){
                            widget.hover = true;
                        } else {
                            widget.hover = false;
                        }
                    }
                    doItForAllWindows( &cb, vl.children);

                    break;
                case SDL_MOUSEBUTTONDOWN:
                    void clicked(Widget* wi) @nogc nothrow {
                        int mouseX, mouseY;
                        SDL_GetMouseState(&mouseX, &mouseY);
                        if(isPointInRect(Point(mouseX, mouseY), wi.rect))
                            wi.as!Widget.onClicked(wi);
                    }

                    doItForAllWidgets( &clicked, vl.children);
                    break;
                default:
                    break;
            }
        }
        glClearColor(0.8, 0.8, 1.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        //drawRect(Rect(100, 150, 80, 300), Color(1.0f, 0.5f, 0.5f));// debug
        
        doItForAllWindows( &draw, vl.children);

        SDL_GL_SwapWindow(sdl_window);
    }


}
