#ifndef NOISE
#define NOISE

// Returns a pseudorandom number, given a seed
float PseudoRandom(float seed)
{
    return frac(sin(seed) * 43758.5453);
}

#endif