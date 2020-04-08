module primitives;

import bindbc.opengl;

import types;
import globals;

enum SOLID;
enum HOLLOW;

@nogc nothrow:

void resize(int w, int h){
    // Set viewport size to be entire OpenGL window.
    glViewport(0, 0, w, h);
}


void _glVertex(int x, int y){
    glVertex2f(x * 2.0 / cast(float)CUR_WIN_WIDTH - 1.0, 1.0 - y * 2.0 / cast(float)CUR_WIN_HEIGHT);
}

void drawRect(Filling = HOLLOW)(Rect r, Color cl){
    static if(is(Filling == SOLID)){
        glBegin(GL_QUADS);
    }else{
        glBegin(GL_LINE_LOOP);
    }
        glColor3d(cl.r, cl.g, cl.b);
        _glVertex(r.x, r.y);
        _glVertex(r.x+r.w, r.y);
        _glVertex(r.x+r.w, r.y+r.h);
        _glVertex(r.x, r.y+r.h);
    glEnd();
}