module widget;

import core.stdc.stdio;

import dvector;

import globals;
import types;
import primitives;

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
            }
        }else{
            foreach (i, ref child; children){
                child.w = w;
                child.h = cast(int)((this.h - (children.length + 1) * padding) / children.length);
                child.pos = Point(this.x, cast(int)(this.y + i * (child.h + padding) + padding));
                
                if(child.typeId & CONTAINER ){
                    child.as!Sizer.layout();
                }
            }
        }
        
    }

    ~this(){
        children.clear;
    }

}

alias ClickCallback = void delegate(Widget*) @nogc nothrow;

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

struct TextCtrl {
    Widget widget;

    alias widget this;

    string text;

    @nogc nothrow:
    this(string id){
        this.id = id;
        
        derived = &this;

        typeId = TYPE_TEXTCTRL;
    }

    this(string id, string text){
        this(id);
        this.text = text;
    }

    void draw(){
        if(hover)
            drawRect!SOLID(rect, color);
        else
            drawRect(rect, color);
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
        import bindbc.sdl;
        renderText(label.ptr, SDL_Color(0,0,0), x+10, y+10, 22);
    }
}

@nogc nothrow:

bool isDrawable(Window* obj){
    return (obj.typeId & DRAWABLE)?true:false;
}

bool isClickable(Window* obj){
    return (obj.typeId & CLICKABLE)?true:false;
}

// TODO: avoid dittos

void drawAllWindows(ref Dvector!(Window*) wins){
    void cb(Window* window){
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

    doItForAllWindows( &cb, wins);
}

void doItForAllWindows(Cb)(scope Cb cb, ref Dvector!(Window*) wins){
    auto stack = wins.save;
    while(!stack.empty){
        immutable n = stack.length - 1;
        auto window = stack[n];
        
        cb(window);

        stack.popBack;
        if(window.children.length){
            foreach (ref child; window.children)
                stack.pushBack(child);
        }
    }
    stack.free;
}

void doItForAllWidgets(ClickCallback cb, ref Dvector!(Window*) wins){
    auto stack = wins.save;
    while(!stack.empty){
        immutable n = stack.length - 1;
        auto widget = stack[n];
        
        if(widget.isClickable && widget.as!Widget.onClicked)
            cb(widget.as!Widget);

        stack.popBack;
        if(widget.children.length){
            foreach (ref child; widget.children)
                stack.pushBack(child);
        }
    }
    stack.free;
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
