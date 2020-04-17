module widget;

import core.stdc.stdio;

import bindbc.sdl;
import dvector;

import globals;
import types;
import drawobjects;
import stringnogc;

alias String = dString!aumem;

enum: int {
    TYPE_WINDOW = 1 << 0,
    TYPE_SIZER = 1 << 1,
    TYPE_FLEXSIZER = 1 << 2,
    TYPE_SPACER = 1 << 3,
    TYPE_FRAME = 1 << 4,
    TYPE_WIDGET = 1 << 5,
    TYPE_BUTTON = 1 << 6,
    TYPE_TEXTCTRL = 1 << 7
}

enum DRAWABLE = TYPE_WIDGET | TYPE_BUTTON | TYPE_TEXTCTRL;
enum CONTAINER = TYPE_SIZER | TYPE_FLEXSIZER | TYPE_FRAME;
enum CLICKABLE = TYPE_WIDGET | TYPE_BUTTON | TYPE_TEXTCTRL;


template LocalDims(){
    @property int lx(){
        return x + marginLeft;
    }

    @property int ly(){
        return y + marginTop;
    }

    @property int lw(){
        return w - (marginLeft + marginRight);
    }

    @property int lh(){
        return h - (marginTop + marginBottom);
    }

    @property Rect lrect(){
        return Rect(lx, ly, lw, lh);
    }
}

struct Window {
    string id;

    Rect rect;

    int marginLeft;
    int marginTop;
    int marginRight;
    int marginBottom;

    Dvector!(Window*) children;

    bool hover = false;

    void* derived;

    alias rect this;

    int typeId = TYPE_WINDOW;

    @nogc nothrow:

    @property void marginAll(int v){
        marginLeft = v;
        marginTop = v;
        marginRight = v;
        marginBottom = v;
    }

    mixin LocalDims;

    auto as(T)(){
        return cast(T*)derived;
    }
}

struct Spacer {
    Window window;

    alias window this;

    @nogc nothrow:
    
    this(string id){

        this.id = id;

        derived = &this;

        typeId = TYPE_SPACER;
    }
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
        foreach (_i, ref child; children){
            immutable i = cast(int)_i;
            if(orientation == horizontal){
                child.w = cast(int)((this.w - (children.length + 1) * padding) / children.length);
                child.h = h;
                child.pos = Point(this.x + i * (child.w + padding) + padding, this.y);
            } else {
                child.w = w;
                child.h = cast(int)((this.h - (children.length + 1) * padding) / children.length);
                child.pos = Point(this.x, this.y + i * (child.h + padding) + padding);
            }
            switch (child.typeId){
                case TYPE_SIZER:
                    child.as!Sizer.layout();
                    break;
                case TYPE_FLEXSIZER:
                    child.as!FlexSizer.layout();
                    break;
                case TYPE_TEXTCTRL:
                    child.as!TextCtrl.layout();
                    break;
                default: break;
            }
        }
    }

    ~this(){
        children.clear;
    }

}

struct FlexSizer {
    Window window;

    alias window this;

    int padding = 5;
    
    int orientation = vertical;

    private float[] spaceRates;

    @nogc nothrow:

    this(size_t N)(string id, int or, float[N] spaceRates){
        orientation = or;

        this.spaceRates = spaceRates[];

        this.id = id;

        derived = &this;

        typeId = TYPE_FLEXSIZER;
    }

    ~this(){
        children.clear;
    }

    void add(ref Window child){
        if(children.length < spaceRates.length){
            children.pushBack(&child);
            layout();
        }else{
            printf("Maximum children count reached! ".ptr);
            import core.stdc.stdlib;
            exit(1);
        }
    }
    
    void layout(){
        int accum = 0;
        foreach (_i, ref child; children){
            immutable i = cast(int)_i;
            immutable sr = spaceRates[i];
            if(orientation == horizontal){
                child.w = cast(int)(this.w * sr  - padding);
                accum = child.w + padding;
                if(i == children.length - 1) child.w += padding;
                else if(i == 0) accum = 0;
                child.h = h;
                child.pos = Point(cast(int)(this.x + accum ), this.y);
            } else {
                child.w = w;
                child.h = cast(int)(this.h * sr - padding);
                accum = child.h + padding;
                if(i == children.length - 1) child.h += padding;
                else if(i == 0) accum = 0;
                child.pos = Point(this.x, cast(int)(this.y + accum));
            }
            switch (child.typeId){
                case TYPE_SIZER:
                    child.as!Sizer.layout();
                    break;
                case TYPE_FLEXSIZER:
                    child.as!FlexSizer.layout();
                    break;
                case TYPE_TEXTCTRL:
                    child.as!TextCtrl.layout();
                    break;
                default: break;
            }
        }
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
            drawRect!SOLID(Rect(lx, ly, lw, lh), color);
        else
            drawRect(Rect(lx, ly, lw, lh), color);
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

    uint cursorBlinker;
    bool cursorRelay = true;

    @nogc nothrow:
    this(string id){
        this.id = id;
        
        derived = &this;

        typeId = TYPE_TEXTCTRL;

        font = TTF_OpenFont("SourceSansPro-Semibold.ttf", 22 );

        void widgetCB(Widget* wid, SDL_Event* event){
            root.focused = &wid.window;
            wid.as!TextCtrl.computeClickedIndex(event);
            wid.as!TextCtrl.cursorRelay = true;
        }
        onClicked = &widgetCB;

        marginLeft = 5;
        marginTop = 5;
        marginRight = 5;
        marginBottom = 5;
    }

    void computeClickedIndex(SDL_Event* event){
        if(font is null || utf8cv.empty || event is null)
            return;
        int mouseX = event.button.x;
        auto localx = mouseX - lx;
        
        size_t accum = leftTextOffset;
        foreach (i, ref c; utf8cv){
            const cw = getUTF8CharWidth(c, font);
            accum += cw;
            if(accum > localx){
                cursorInd = i;
                cursorX = cast(int)accum - cw;
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

    void delFront(){
        if(cursorInd < utf8cv.length){
            auto delCharWidth = getUTF8CharWidth(utf8cv[cursorInd], font);
            utf8cv.remove(cursorInd);
        }
    }

    void moveCursorLeft(){
        if(cursorInd){
            auto nextCharWidth = getUTF8CharWidth(utf8cv[cursorInd-1], font);
            --cursorInd;
            cursorX -= nextCharWidth;
        }
    }

    void moveCursorRight(){
        if(cursorInd < utf8cv.length){
            auto nextCharWidth = getUTF8CharWidth(utf8cv[cursorInd], font);
            ++cursorInd;
            cursorX += nextCharWidth;
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
        drawRect!SOLID(lrect, Color(1.0f, 1.0f, 1.0f));
        
        if(text.length > 0)
            renderText(text.ptr, Color(0.0f,0.0f,0.0f), lx + leftTextOffset, ly+cast(int)(lh*0.15f), cast(int)(lh*0.6f));
        
        // draw a cursor
        
        if(root.focused == &window){
            cursorBlinker += Clock.delta;
            if(cursorBlinker > 500){
                cursorBlinker = 0;
                cursorRelay = !cursorRelay;
            }
            if(cursorRelay)
                drawLine(
                    Point(cursorX + marginLeft, ly + cast(int)(lh*0.15f)),
                    Point(cursorX + marginLeft, ly + lh - cast(int)(lh*0.15f)),
                    Color(0.5f, 0.5f, 0.5f)
                );
            drawRect!HOLLOW(Rect(lx, ly, lw, lh), Color(0.0f, 0.0f, 0.0f));
        } else
            drawRect!HOLLOW(Rect(lx, ly, lw, lh), Color(0.5f, 0.5f, 0.5f));
    }

    void layout(){
        TTF_CloseFont(font);
        font = TTF_OpenFont("SourceSansPro-Semibold.ttf", cast(int)(lh*0.6f) );
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
        if(hover){
            drawRoundedRectGradientFill(cast(float)lx, cast(float)ly, cast(float)lw, cast(float)lh, 8, Color(0.9f, 0.9f, 1.0f), Color(0.7f, 0.7f, 1.0f));
            drawRoundedRectBorder(lx, ly, lw, lh, 8, Color(0.0f, 0.0f, 0.0f));
        }else{
            drawRoundedRectGradientFill(cast(float)lx, cast(float)ly, cast(float)lw, cast(float)lh, 8, Color(0.8f, 0.8f, 1.0f), Color(0.6f, 0.6f, 1.0f));
            drawRoundedRectBorder(lx, ly, lw, lh, 8, Color(0.0f, 0.0f, 0.0f));
        }    
            //drawRect(Rect(lx, ly, lw, lh), color);
        
        renderText(label.ptr, Color(0.0f,0.0f,0.0f), lx+8, ly+cast(int)(lh*0.1f), cast(int)(lh*0.6f));
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

void requestDelChar(ref Dvector!(Window*) wins, SDL_Event* event){
    void injection(Window* window, SDL_Event* event){
        if(window.typeId == TYPE_TEXTCTRL && window == root.focused && window.as!TextCtrl.utf8cv.length > 0){
            if(event.key.keysym.sym == SDLK_BACKSPACE)
                window.as!TextCtrl.delBack();
            else if(event.key.keysym.sym == SDLK_DELETE)
                window.as!TextCtrl.delFront();

        }
    }
    
    doItForAllWindows(&injection, event, wins);
}

void requestKeyArrow(ref Dvector!(Window*) wins, SDL_Event* event){
    void injection(Window* window, SDL_Event* event){
        if(window.typeId == TYPE_TEXTCTRL && window == root.focused && window.as!TextCtrl.utf8cv.length > 0){
            if(event.key.keysym.sym == SDLK_LEFT)
                window.as!TextCtrl.moveCursorLeft();
            else if(event.key.keysym.sym == SDLK_RIGHT)
                window.as!TextCtrl.moveCursorRight();

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
