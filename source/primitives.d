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
    glVertex2f(x * 2.0f / cast(float)CUR_WIN_WIDTH - 1.0f, 1.0f - y * 2.0f / cast(float)CUR_WIN_HEIGHT);
}

void _glVertex2f(float x, float y){
    glVertex2f(x * 2.0f / cast(float)CUR_WIN_WIDTH - 1.0f, 1.0f - y * 2.0f / cast(float)CUR_WIN_HEIGHT);
}

void line(Point p1, Point p2, Color cl){
    glBegin(GL_LINES);
        glColor3f(cl.r, cl.g, cl.b);
        _glVertex(p1.x, p1.y);
        _glVertex(p2.x, p2.y);
    glEnd();
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

void renderText(const(char)* message, Color color, int x, int y, int size) {
    import bindbc.sdl.ttf;

    glEnable(GL_BLEND);
    glEnable(GL_TEXTURE_2D);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    TTF_Font *font = TTF_OpenFont("SourceSansPro-Semibold.ttf", size );

    auto _color = SDL_Color(cast(ubyte)(color.r*255), cast(ubyte)(color.g*255), cast(ubyte)(color.b*255));

    SDL_Surface * sFont = TTF_RenderUTF8_Blended(font, message, _color);

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


// https://stackoverflow.com/questions/5369507/opengl-es-1-0-2d-rounded-rectangle
import core.stdc.math;
import std.math: PI;

enum GLW_SMALL_ROUNDED_CORNER_SLICES = 25;  // How many vertexes you want of each corner


struct glwVec2{float x, y;}

static glwVec2[GLW_SMALL_ROUNDED_CORNER_SLICES] glwRoundedCorners; // This array keep the generated vertexes of one corner

static void createRoundedCorners(glwVec2 *arr, int num) {
  // Generate the corner vertexes
  float slice = PI / 2.0f / num;
  int i;
  float a = 0;
  for (i = 0; i < num; a += slice, ++i) {
    arr[i].x = cosf(a);
    arr[i].y = sinf(a);
  }
}

void glwDrawRoundedRectGradientFill(float x, float y, float width, float height,
    float radius, Color topColor, Color bottomColor) {
  
  createRoundedCorners(glwRoundedCorners.ptr, GLW_SMALL_ROUNDED_CORNER_SLICES);
  
  float left = x;
  float top = y;
  float bottom = y + height - 1;
  float right = x + width - 1;
  int i;
  glDisable(GL_TEXTURE_2D);
  glBegin(GL_QUAD_STRIP);
    // Draw left rounded side.
    for (i = 0; i < GLW_SMALL_ROUNDED_CORNER_SLICES; ++i) {
      glColor3d(bottomColor.r, bottomColor.g, bottomColor.b);
      _glVertex2f(left + radius - radius * glwRoundedCorners[i].x,
        bottom - radius + radius * glwRoundedCorners[i].y);
      glColor3d(topColor.r, topColor.g, topColor.b);
      _glVertex2f(left + radius - radius * glwRoundedCorners[i].x,
        top + radius - radius * glwRoundedCorners[i].y);
    }
    // Draw right rounded side.
    for (i = GLW_SMALL_ROUNDED_CORNER_SLICES - 1; i >= 0; --i) {
      glColor3d(bottomColor.r, bottomColor.g, bottomColor.b);
      _glVertex2f(right - radius + radius * glwRoundedCorners[i].x,
        bottom - radius + radius * glwRoundedCorners[i].y);
      glColor3d(topColor.r, topColor.g, topColor.b);
      _glVertex2f(right - radius + radius * glwRoundedCorners[i].x,
        top + radius - radius * glwRoundedCorners[i].y);
    }
  glEnd();
}

static void glwDrawRightTopVertexs(float left, float top, float right,
    float bottom, float radius) {
  int i;
  for (i = GLW_SMALL_ROUNDED_CORNER_SLICES - 1; i >= 0; --i) {
    _glVertex2f(right - radius + radius * glwRoundedCorners[i].x,
      top + radius - radius * glwRoundedCorners[i].y);
  }
}

static void glwDrawRightBottomVertexs(float left, float top, float right,
    float bottom, float radius) {
  int i;
  for (i = 0; i < GLW_SMALL_ROUNDED_CORNER_SLICES; ++i) {
    _glVertex2f(right - radius + radius * glwRoundedCorners[i].x,
      bottom - radius + radius * glwRoundedCorners[i].y);
  }
}

static void glwDrawLeftBottomVertexs(float left, float top, float right,
    float bottom, float radius) {
  int i;
  for (i = GLW_SMALL_ROUNDED_CORNER_SLICES - 1; i >= 0; --i) {
    _glVertex2f(left + radius - radius * glwRoundedCorners[i].x,
      bottom - radius + radius * glwRoundedCorners[i].y);
  }
}

static void glwDrawLeftTopVertexs(float left, float top, float right,
    float bottom, float radius) {
  int i;
  for (i = 0; i < GLW_SMALL_ROUNDED_CORNER_SLICES; ++i) {
    _glVertex2f(left + radius - radius * glwRoundedCorners[i].x,
      top + radius - radius * glwRoundedCorners[i].y);
  }
}

void glwDrawRoundedRectBorder(int x, int y, int width, int height,
    int radius, Color color) {
  float left = cast(float)x;
  float top = cast(float)y;
  float bottom = cast(float)y + height - 1;
  float right = x + cast(float)width - 1;
  glDisable(GL_TEXTURE_2D);
  glColor3d(color.r, color.g, color.b);
  glBegin(GL_LINE_LOOP);
    _glVertex2f(left, top + radius);
    glwDrawLeftTopVertexs(left, top, right, bottom, radius);
    _glVertex2f(left + radius, top);

    _glVertex2f(right - radius, top);
    glwDrawRightTopVertexs(left, top, right, bottom, radius);
    _glVertex2f(right, top + radius);

    _glVertex2f(right, bottom - radius);
    glwDrawRightBottomVertexs(left, top, right, bottom, radius);
    _glVertex2f(right - radius, bottom);

    _glVertex2f(left + radius, bottom);
    glwDrawLeftBottomVertexs(left, top, right, bottom, radius);
    _glVertex2f(left, bottom - radius);
  glEnd();
}