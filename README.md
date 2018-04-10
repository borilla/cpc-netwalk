# cpc-netwalk

This repo is a record of my attempt to meake a "[netwalk](https://netwalk.github.io/)" game for the
[Amstrad CPC](https://en.wikipedia.org/wiki/Amstrad_CPC), using [Z80](https://en.wikipedia.org/wiki/Zilog_Z80)
assembly language

_Note: Are you kidding me; there's a [russian wikipedia page for netwalk](https://ru.wikipedia.org/wiki/NetWalk)
but no english?!_

## Maze generation

The game is based around maze generation. I've written many maze generators, in various languages,
over the years but almost all based on [Prim's algorithm](https://en.wikipedia.org/wiki/Prim's_algorithm)

But, after reading [Jamis Buck's page on maze algorithms](http://www.jamisbuck.org/mazes/), I found a
beautiful (and simple) alternative to Prim's algorithm; the
"[Growing Tree algorithm](http://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm)"

This algorithm (which can actually return exactly the same maze as Prim's) is naturally stack-based, so can
be implemented more efficiently in Z80. This inspired me to finally combine my interests in mazes and in Z80
code, and make a Z80 netwalk game

## progress

So far I've got the maze generation working. Everything else is **_pending..._**
