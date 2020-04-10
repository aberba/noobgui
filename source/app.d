import core.stdc.stdio;

import bindbc.sdl;
import bindbc.opengl;
import dvector;
import stringnogc;

import boilerplate;
import util;
import primitives;
import globals;
import types;
import widget;
import frame;

@nogc nothrow:

alias String = dString!aumem;

extern (C) int main(){
    initSDL();
    initSDLTTF();
    initGL();
    initUtil();

	glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

    root = Frame("root");

    Widget w1 = Widget("w1");

    void changeColor(Widget* wid) @nogc nothrow {
        wid.color = Color(
            rnd!float(0.0f, 1.0f),
            rnd!float(0.0f, 1.0f),
            rnd!float(0.0f, 1.0f));
    }

    w1.setClickHandler(&changeColor);

    Widget w2 = Widget("w2");
    Widget w3 = Widget("w3");

    Button button1 = Button("button1", "Click me change color of w2!");
    Button button2 = Button("button2", "Click me for nothing!");

    Sizer h1 = Sizer("h1", horizontal);

    auto text1 = TextCtrl("text1");
    
    text1.text = "Your text goes here!";

    auto text2 = TextCtrl("text2", "another text");

    root.add(text1);
    root.add(text2);
    root.add(w1);
    root.add(w2);
    root.add(h1); // another Sizer
    root.add(w3);
    root.add(button1);
    root.add(button2);

    button1.setClickHandler(delegate void(Widget* widget){
        
        auto other = getWindowById("w2");

        other.as!Widget.color = Color(
            rnd!float(0.0f, 1.0f),
            rnd!float(0.0f, 1.0f),
            rnd!float(0.0f, 1.0f));
    });
    
    auto wh1 = Widget("wh1");
    auto wh2 = Widget("wh2");
    auto wh3 = Widget("wh3");

    h1.add(wh1);
    h1.add(wh2);
    h1.add(wh3);
    
    static int dummy1 = 0; // has to be static
    static int dummy2 = 45;
    wh2.setClickHandler(delegate void(Widget* wid){
        printf("%s has clicked! %d \n", wid.id.ptr, dummy2);
        dummy1 = 13;
    });

    void onClicked(Widget* wi) @nogc nothrow {
        printf("%s has clicked!\n", wi.id.ptr);
    }

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
                        case SDLK_BACKSPACE:
                            requestBSpace(root.children);
                            break;
                        default:
                            break;
                    }
                    break;
                case SDL_WINDOWEVENT:
                    if(event.window.event == SDL_WINDOWEVENT_RESIZED){
                        SDL_GetWindowSize(sdl_window, &CUR_WIN_WIDTH, &CUR_WIN_HEIGHT);
                        resize(CUR_WIN_WIDTH, CUR_WIN_HEIGHT);
                        root.w = CUR_WIN_WIDTH;
                        root.h = CUR_WIN_HEIGHT;
                        root.layout;
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
                    doItForAllWindows( &cb, root.children);

                    break;
                case SDL_MOUSEBUTTONDOWN:
                    void clicked(Widget* wi) @nogc nothrow {
                        int mouseX, mouseY;
                        SDL_GetMouseState(&mouseX, &mouseY);
                        
                        if(isPointInRect(Point(mouseX, mouseY), wi.rect)){
                            root.focused = &wi.window;
                            wi.onClicked(wi);
                            printf("%s focused \n", root.focused.id.ptr);
                        }
                    }

                    processClickEvents( &clicked, root.children);
                    break;
                case SDL_TEXTINPUT:
                    processTextInput(event.text.text.ptr, root.children);
                    break;
                default:
                    break;
            }
        }
        glClearColor(0.8, 0.8, 1.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        //drawRect(Rect(100, 150, 80, 300), Color(1.0f, 0.5f, 0.5f));// debug
        
        drawAllWindows(root.children);

        SDL_GL_SwapWindow(sdl_window);
    }


}
