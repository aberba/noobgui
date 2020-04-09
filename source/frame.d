module frame;

import globals;
import types;
import widget;

// WIP

struct Frame {
    Sizer sizer;
    alias sizer this;

    this(string id){
        this.id = id;
        this.typeId = TYPE_FRAME;
        derived = &this;

        sizer = Sizer("root", vertical, Point(0, 0), CUR_WIN_WIDTH, CUR_WIN_HEIGHT);
    }
}