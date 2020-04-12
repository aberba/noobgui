module util;

import core.stdc.time;
import core.stdc.stdlib;

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

size_t utflen(string mstring ){
    import core.stdc.string;

    ubyte* mstr = cast(ubyte*)malloc((mstring.sizeof / ubyte.sizeof) * mstring.length);
    memcpy(mstr, mstring.ptr, (mstring.sizeof / ubyte.sizeof) * mstring.length);

    ubyte* dst;

    auto sz = utf8proc_map(mstr, 0, &dst, UTF8PROC_NULLTERM);

    utf8proc_ssize_t size = sz;
    utf8proc_int32_t data;
    utf8proc_ssize_t n;

    ubyte* char_ptr = mstr;

    size_t nchar;

    while ((n = utf8proc_iterate(char_ptr, size, &data)) > 0) {
        char_ptr += n;
        size -= n;
        nchar++;
    }

    return nchar;
}