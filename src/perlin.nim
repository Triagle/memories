import random
import math
import tables

type
    Vec = tuple[x: float, y: float]
      
func interpolate(a: float, b: float, w: float): float = 
    return a + (3 * w * w - 2*pow(w, 3))*(b - a)

func normalise(point: Vec): Vec =
    let (x, y) = point
    let length = sqrt(x*x + y*y)
    return (x / length, y / length)


proc gradientMap(x1: int, x2: int, y1: int, y2: int): Table =
    result = initTable[Vec, Vec]
    for x in countup(x1, x2):
        for y in countup(y1, y2):
            let point = (rand(1), rand(1))
            result[(x.float, y.float)] = normalise(point)


func dot(v1, v2: Vec): float =
    let (x1, x2) = v1
    let (y1, y2) = v2
    return x1*x2 + y1*y2


func perlin(gradMap: Table[Vec,Vec], v: Vec): float =
    #[
    g1            g3
      +----------+
      |          |
      |    p     |
      |    x     |
      |          |
      |          |
    g2+----------+g4
    ]#
    let (x, y) = v
    let g1 = gradMap[(x.floor,y.floor)].dot(v)
    let g2 = gradMap[(x.floor,y.floor + 1)].dot(v)
    let g3 = gradMap[(x.floor + 1, y.floor)].dot(v)
    let g4 = gradMap[(x.floor + 1, y.floor + 1)].dot(v)
    let x1 = interpolate(g1, g2, y - y.floor)
    let x2 = interpolate(g3, g4, y - y.floor)
    return interpolate(x1, x2, x - x.floor)

# Inspired by https://flafla2.github.io/2014/08/09/perlinnoise.html
# Basic idea:
# We want to produce noise with more detail, and to do that we layer the noise with some weighting and a frequency.
# By increasing the frequency two close vectors, say (1, 1) and (1, 2) will get very different noise values (since they are basically uncorrelated at that point).
# The job of the amplitude is to damp the discontinuous effects of the increasing frequency and the result is tiny variations in the noise that is still continuous,
# this is how we get detail in perlin noise.
func octavePerlin(gradMap: Table[Vec,Vec], v: Vec, octaves: int, persistence: float): float =
    var total: float = 0
    for i in countup(0, octaves):
        let (x, y) = v
        let frequency = (2^i).float
        let amplitude = pow(persistence, i.float)
        total += perlin(gradMap, (x * frequency, y * frequency)) * amplitude
    # Normalising constant = sum of persistence^i, which is a geometric series
    # Every octave i added is in bounds [0, persistence^i] so dividing by this value normalises back to [0, 1]
    let normalisingConstant = (1 - pow(persistence, octaves.float))/(1 - persistence)
    return total / normalisingConstant
