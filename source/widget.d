module widget;

import core.stdc.stdio;

import bindbc.sdl;
import dvector;

import globals;
import types;
import primitives;
import stringnogc;

alias String = dString!aumem;

enum: int {
    TYPE_WINDOW = 1 << 0,
    TYPE_SIZER = 1 << 1,
    TYPE_FRAME = 1 << 2,
    TYPE_WIDGET = 1 << 3,
    TYPE_BUTTON = 1 << 4,
    TYPE_TEXTCTRL = 1 << 5
}

enum DRAWABLE = TYPE_WIDGET | TYPE_BUTTON | TYPE_TEXTCTRL;
enum CONTAINER = TYPE_SIZER | TYPE_FRAME;
enum CLICKABLE = TYPE_WIDGET | TYPE_BUTTON | TYPE_TEXTCTRL;

struct Window {
    string id;

    Rect rect;

    Dvector!(Window*) children;

    bool hover = false;

    void* derived;

    alias rect this;

    int typeId = TYPE_WINDOW;

    @nogc nothrow:

    auto as(T)(){
        return cast(T*)derived;
    }

    //void draw(){}

}

enum {
    vertical,
    horizontal
}

struct Sizer {
    Window window;
    
    int orientation = vertical;

    uint padding = 5;

    alias window this;

    @nogc nothrow:

    this(string id, int or, Point pos, int w, int h){
        orientation = or;

        this.id = id;
        this.pos = pos;
        this.w = w;
        this.h = h;

        derived = &this;

        typeId = TYPE_SIZER;
    }

    this(string id, int or){
        orientation = or;

        this.id = id;

        derived = &this;

        typeId = TYPE_SIZER;
    }

    void add(ref Window child){
        children.pushBack(&child);
        layout();
    }

    void layout(){
        if(orientation == horizontal){
            foreach (i, ref child; children){
                child.w = cast(int)((this.w - (children.length + 1) * padding) / children.length);
                child.h = h;
                child.pos = Point(cast(int)(this.x + i * (child.w + padding) + padding), this.y);
                
                if(child.typeId & CONTAINER ){
                    child.as!Sizer.layout();
                }
                if(child.typeId == TYPE_TEXTCTRL){
                    TTF_CloseFont(child.as!TextCtrl.font);
                    child.as!TextCtrl.font = TTF_OpenFont("SourceSansPro-Semibold.ttf", cast(int)(child.h*0.6f) );
                }
            }
        }else{
            foreach (i, ref child; children){
                child.w = w;
                child.h = cast(int)((this.h - (children.length + 1) * padding) / children.length);
                child.pos = Point(this.x, cast(int)(this.y + i * (child.h + padding) + padding));
                
                if(child.typeId & CONTAINER ){
                    child.as!Sizer.layout();
                }
                if(child.typeId == TYPE_TEXTCTRL){
                    TTF_CloseFont(child.as!TextCtrl.font);
                    child.as!TextCtrl.font = TTF_OpenFont("SourceSansPro-Semibold.ttf", cast(int)(child.h*0.6f) );
                }
            }
        }
        
    }

    ~this(){
        children.clear;
    }

}

alias ClickCallback = void delegate(Widget*, SDL_Event* event) @nogc nothrow;

const char[] defCB = "
    void defaultWidgetCB(Widget* wid, SDL_Event* event){
        root.focused = &wid.window;
    }
        
    onClicked = &defaultWidgetCB;
";

struct Widget {
    Window window;
    Color color = Color(0.5f, 0.5f, 0.5f);
    
    alias window this;

    @nogc nothrow:

    ClickCallback onClicked;

    this(string id){
        this.id = id;
        
        derived = &this;

        typeId = TYPE_WIDGET;

        mixin(defCB);
    }

    void setClickHandler(ClickCallback cb){
        onClicked = cb;
    }

    void draw(){
        if(hover)
            drawRect!SOLID(rect, color);
        else
            drawRect(rect, color);
    }
}

import bindbc.sdl.ttf;
import util;

struct TextCtrl {
    Widget widget;

    alias widget this;

    Dvector!(char*) utf8cv;
    TTF_Font *font;

    int leftTextOffset = 8;

    size_t cursorInd;
    int cursorX = 0;

    @nogc nothrow:
    this(string id){
        this.id = id;
        
        derived = &this;

        typeId = TYPE_TEXTCTRL;

        font = TTF_OpenFont("SourceSansPro-Semibold.ttf", 22 );

        void widgetCB(Widget* wid, SDL_Event* event){
            root.focused = &wid.window;
            wid.as!TextCtrl.computeClickedIndex(event);
        }
        onClicked = &widgetCB;
    }

    void computeClickedIndex(SDL_Event* event){
        if(font is null || utf8cv.empty || event is null)
            return;
        //int mouseX, mouseY;
        //SDL_GetMouseState(&mouseX, &mouseY);
        int mouseX = event.button.x;
        auto localx = mouseX - x;
        if(localx < 0)
            return;
        size_t accum = leftTextOffset;
        foreach (i, ref c; utf8cv){
            accum += getUTF8CharWidth(c, font);
            if(accum > localx){
                cursorInd = i + 1;
                cursorX = cast(int)accum;
                printf("clicked index %d\n", cursorInd);
                return;
            }
        }
        cursorX = cast(int)accum;
        cursorInd = utf8cv.length;
    }

    this(string id, string text){
        this(id);
        this.text = text;
    }

    @property void text(string str){
        utf8cv.clear;
        getUTF8CharPVector(str, utf8cv);
    }

    @property string text(){
        return composeText(utf8cv);
    }

    void addCharP(char* cptr){
        import core.stdc.string;
        import core.stdc.stdlib;
        char* mstr = cast(char*)malloc(strlen(cptr)*char.sizeof + 1);
        sprintf(mstr, "%.*s", strlen(cptr), cptr);

        utf8cv.insert(mstr, cursorInd++);

        auto newCharWidth = getUTF8CharWidth(cptr, font);
        cursorX += newCharWidth;
    }

    void delBack(){
        if(cursorInd > 0){
            auto delCharWidth = getUTF8CharWidth(utf8cv[cursorInd-1], font);
            utf8cv.remove(--cursorInd);
            cursorX -= delCharWidth;
        }
    }

    void freeCV(){
        import core.stdc.stdlib;
        foreach (ref c; utf8cv)
            free(c);
        utf8cv.free;
    }

    ~this(){
        freeCV();
    }

    void draw(){
        drawRect!SOLID(rect, Color(1.0f, 1.0f, 1.0f));
        
        if(text.length > 0)
            renderText(text.ptr, Color(0.0f,0.0f,0.0f), x + leftTextOffset, y+cast(int)(h*0.1f), cast(int)(h*0.6f));
        
        // draw a cursor
        if(root.focused == &window)
            line(
                Point(cursorX, y + cast(int)(h*0.15f)),
                Point(cursorX, y + h - cast(int)(h*0.15f)),
                Color(0.5f, 0.5f, 0.5f));
    }
}

struct Button {
    Widget widget;

    alias widget this;

    string label = "undefined";

    @nogc nothrow:
    this(string id){
        this.id = id;
        
        derived = &this;

        typeId = TYPE_BUTTON;

        color = Color(0.2, 0.8, 0.8);

        mixin(defCB);
    }

    this(string id, string label){
        this(id);
        this.label = label;
    }

    void draw(){
        if(hover)
            drawRect!SOLID(rect, color);
        else
            drawRect(rect, color);
        
        renderText(label.ptr, Color(0.0f,0.0f,0.0f), x+8, y+cast(int)(h*0.1f), cast(int)(h*0.6f));
    }
}

@nogc nothrow:

bool isDrawable(Window* obj){
    return (obj.typeId & DRAWABLE)?true:false;
}

bool isClickable(Window* obj){
    return (obj.typeId & CLICKABLE)?true:false;
}

void doItForAllWindows(Cb)(scope Cb cb, SDL_Event* event, ref Dvector!(Window*) wins){
    auto stack = wins.save;
    while(!stack.empty){
        immutable n = stack.length - 1;
        auto window = stack[n];
        
        cb(window, event);

        stack.popBack;
        if(window.children.length){
            foreach (ref child; window.children)
                stack.pushBack(child);
        }
    }
    stack.free;
}

void drawAllWindows(ref Dvector!(Window*) wins){
    void cb(Window* window, SDL_Event* event){
        if(window.isDrawable){
            switch (window.typeId){
                case TYPE_BUTTON:
                    window.as!Button.draw();
                    break;
                case TYPE_TEXTCTRL:
                    window.as!TextCtrl.draw();
                    break;
                case TYPE_WIDGET:
                    window.as!Widget.draw();
                    break;
                default:
                    break;
            }
        }
    }

    doItForAllWindows( &cb, null, wins);
}

void processClickEvents(Cb)(scope Cb cb, SDL_Event* event, ref Dvector!(Window*) wins){
    void injection(Window* win, SDL_Event* event){
        
        if(win.isClickable){
            
            cb(win.as!Widget, event);
            
        }
    }

    doItForAllWindows(&injection, event, wins);
}

void processTextInput(char* c, ref Dvector!(Window*) wins){
    auto stack = wins.save;
    while(!stack.empty){
        immutable n = stack.length - 1;
        auto window = stack[n];
        
        if(window.typeId == TYPE_TEXTCTRL && window == root.focused){
            window.as!TextCtrl.addCharP(c);
            break;// only one widget can have focus at the same time
        }

        stack.popBack;
        if(window.children.length){
            foreach (ref child; window.children)
                stack.pushBack(child);
        }
    }
    stack.free;
}

import utf8proc;

void requestBSpace(ref Dvector!(Window*) wins, SDL_Event* event){
    import core.stdc.stdlib;
    import core.stdc.string;
    import utf8proc;

    void injection(Window* window, SDL_Event* event){
        if(window.typeId == TYPE_TEXTCTRL && window == root.focused && window.as!TextCtrl.utf8cv.length > 0){
            window.as!TextCtrl.delBack();
        }
    }
    
    doItForAllWindows(&injection, event, wins);
}

Window* getWindowById(string id){
    auto stack = root.children.save;
    while(!stack.empty){
        immutable n = stack.length - 1;
        auto window = stack[n];
        
        if(window.id == id){
            stack.free;
            return window;
        }
        
        stack.popBack;
        if(window.children.length){
            foreach (ref child; window.children)
                stack.pushBack(child);
        }
    }
    stack.free;
    return null;
}
