module types;

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