module util;

import core.stdc.time;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.stdio;

import dvector;

nothrow @nogc :

T rnd(T)(T lo, T up) {
        return cast(T)((up-lo)*(cast(float)rand())/RAND_MAX + lo);
}

void setRandomSeed(uint seed){
    srand(seed);
}

void initUtil() {
    setRandomSeed(time(null));
}

import utf8proc;

void getUTF8CharPVector(string mstring, ref Dvector!(char*) utf8cv){
    
    ubyte* mstr = cast(ubyte*)malloc(mstring.length + 1);
    memcpy(mstr, mstring.ptr, mstring.length + 1);
    
    ubyte* dst;

    utf8proc_ssize_t size = utf8proc_map(mstr, mstring.length, &dst, UTF8PROC_NULLTERM);
    utf8proc_int32_t data;
    utf8proc_ssize_t n;

    ubyte* char_ptr = mstr;

    size_t nchar;
    char[8] buffer;
    while ((n = utf8proc_iterate(char_ptr, size, &data)) > 0) {

        sprintf(buffer.ptr, "%.*s", cast(int)n, char_ptr);
        auto cptr = cast(char*)malloc(n * char.sizeof + 1);
        memcpy(cptr, buffer.ptr, n * char.sizeof + 1);

        utf8cv.pushBack(cptr);

        char_ptr += n;
        size -= n;
        nchar++;
    }

    free(mstr);
    free(dst);
}

import bindbc.sdl.ttf;
int getUTF8CharWidth(char* utf8c, TTF_Font *font){
    int w = 16, h;
    
    TTF_SizeUTF8(font, utf8c, &w, &h);
    return w;
}

string composeText(ref Dvector!(char*) cv){
    
    import stringnogc;
    alias String = dString!aumem;

    String outstr;

    foreach(cp; cv){
        outstr.addCharP(cp);
    }

    return outstr.str;
}