module types;

import std.stdint;

enum SOLID;
enum HOLLOW;

struct Point {
    int x;
    int y;

    @nogc nothrow:
    bool opEqual(in ref Point other) const {
        return x == other.x && y == other.y;
    }
}

struct Rect {
    int x, y, w, h;

    @nogc nothrow:
    
    @property Point pos(){
        return Point(x, y);
    }

    @property void pos(Point p){
        x = p.x;
        y = p.y;
    }
}

struct _Color(T){
    T r, g, b;
}

alias Color = _Color!float;

static struct Clock {
    import bindbc.sdl;

    static uint32_t lastTickTime = 0;
    static uint32_t delta = 0;

    @nogc nothrow:
    
    static void tick()
    {
        uint32_t tickTime = SDL_GetTicks();
        delta = tickTime - lastTickTime;
        lastTickTime = tickTime;
    }
}