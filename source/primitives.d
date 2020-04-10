module primitives;

import bindbc.opengl;
import bindbc.sdl;

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

void renderText(const(char)* message, SDL_Color color, int x, int y, int size) {
    import bindbc.sdl.ttf;

    glEnable(GL_BLEND);
    glEnable(GL_TEXTURE_2D);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    TTF_Font *font = TTF_OpenFont("SourceSansPro-Semibold.ttf", size );
    
    SDL_Surface * sFont = TTF_RenderText_Blended(font, message, color);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, sFont.w, sFont.h, 0, GL_BGRA, GL_UNSIGNED_BYTE, sFont.pixels);

    glBegin(GL_QUADS);
    {
        glTexCoord2f(0,0); _glVertex(x, y);
        glTexCoord2f(1,0); _glVertex(x + sFont.w, y);
        glTexCoord2f(1,1); _glVertex(x + sFont.w, y + sFont.h);
        glTexCoord2f(0,1); _glVertex(x, y + sFont.h);
    }
    glEnd();
    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);

    TTF_CloseFont(font);
    SDL_FreeSurface(sFont);
}