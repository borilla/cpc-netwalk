# cpc-netwalk

This repo is a record of my attempt to make a "[netwalk](https://netwalk.github.io/)" game for the
[Amstrad CPC](https://en.wikipedia.org/wiki/Amstrad_CPC), using [Z80](https://en.wikipedia.org/wiki/Zilog_Z80)
assembly language

_Note: Are you kidding me; there's a [russian wikipedia page for netwalk](https://ru.wikipedia.org/wiki/NetWalk)
but no english?!_

## Maze generation

The game is based around maze generation. I've written many maze generators, in various languages,
over the years but almost all based on [Prim's algorithm](https://en.wikipedia.org/wiki/Prim's_algorithm)

But, after reading [Jamis Buck's page on maze algorithms](http://www.jamisbuck.org/mazes/), I found a
beautiful (and simple) alternative to Prim's algorithm, which he calls the
"[Growing Tree algorithm](http://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm)"

This algorithm (which can actually return exactly the same maze as Prim's) is naturally stack-based, so
is easier to implement in Z80. This inspired me to finally combine my interests in mazes and in Z80 code,
and make a Z80 netwalk game

## Graphics

Sprites for table cells have been generated using [Retro Game Asset Studio](http://www.cpcwiki.eu/index.php/Retro_Game_Asset_Studio)
and exported as raw byte data. My next task is to work out how to get them to render to the screen

I'm not a pixel artist at all so they're _very_ raw at the moment. Hopefully I can do them a bit better
in future and just output from RGAS over the top of the current crappy ones

## Progress

Here's a quick list of tasks in the approximate order I intend to do them. Not complete and probably
going to change quite significantly as I gradually get stuff done...

- [x] Maze generation
- [x] Draw maze-cell sprites
- [ ] Render a single sprite
- [ ] Render whole maze
- [ ] Show currently selected cell in rendered maze
- [ ] Navigate around the maze using keyboard
- [ ] Animate cell rotation
- [ ] Calculate which cells are connected to power supply
