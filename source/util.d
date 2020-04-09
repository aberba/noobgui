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
