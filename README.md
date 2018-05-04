# cpc-netwalk

This repo is a record of my attempt to make a "[netwalk](https://netwalk.github.io/)" game for the
[Amstrad CPC](https://en.wikipedia.org/wiki/Amstrad_CPC), using [Z80](https://en.wikipedia.org/wiki/Zilog_Z80)
assembly language

_Note: Are you kidding me; there's a [russian wikipedia page for netwalk](https://ru.wikipedia.org/wiki/NetWalk)
but no english?!_

## Maze algorithm

The game is really based around maze generation. I've written many maze generators, in various languages,
over the years but almost all based on [Prim's algorithm](https://en.wikipedia.org/wiki/Prim's_algorithm)

But, after reading [Jamis Buck's page on maze algorithms](http://www.jamisbuck.org/mazes/), I found a
beautiful (and simple) alternative to Prim's algorithm, which he calls the
"[Growing Tree algorithm](http://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm)"

This algorithm (which can actually be made to return exactly the same maze as Prim's) is naturally
stack-based, so is easier to implement in Z80. This inspired me to finally combine my interests in mazes
and in Z80 code, and make a Z80 netwalk game

## Game size

I decided to use a maximum game-grid size of `16 x 16` cells/rooms. Each grid-cell doesn't need to store too
much data, so we can probably get away with using a single byte per cell, which means our entire grid can
be stored in `16 x 16 x 1 = 256 bytes`. This is a neat number for an 8-bit processor as we can index all
cells by manipulating a single 8-bit register

In addition to the grid itself, we also set aside another 256-byte section of memory to use as a
[stack](https://en.wikipedia.org/wiki/Stack) of cell indexes, which we need for generating the grid,
calculating connected cells, etc

## Cell structure

Each cell is a single byte. The bits of this byte are used to represent different properties of the
cell. My original intuition was to use the lowest four bits to represent exits to top, right, bottom
and left respectively. Amazingly this coincided exactly with the subset of the [Amstrad CPC character
set](http://cpctech.cpc-live.com/docs/cpckybd.pdf) between `&90` and `&9f` used to represent maze-type
shapes

![Amstrad CPC maze characters](./doc/maze-chars.gif)

This made writing a quick BASIC program to help debugging so much easier

![BASIC test prorgam](./doc/basic-test.gif)

### Cell bit pattern

The final bit pattern for each grid-cell looks as follows, where bit 0 is the least-significant bit
(LSB), bit 7 is most-significant bit (MSB):

| Bit | Usage |
| --- | --- |
| 0 | Top exit |
| 1 | Right exit |
| 2 | Bottom exit |
| 3 | Left exit |
| 4 | "Visited" - used for maze generation |
| 5 | _Currently unused_ |
| 6 | _Currently unused_ |
| 7 | _Currently unused_ |

## Sprites

Sprites for cells have been generated using [Retro Game Asset Studio (RGAS)](http://www.cpcwiki.eu/index.php/Retro_Game_Asset_Studio)
and exported as raw byte data. There are 15 possible different combinations of exits for each cell and,
for each of these, there are four rotation positions (to allow for relatively smooth rotation animation).
In addition to these is another set of 15 "connected" cells (ie with a different colouring to represent
being connected to the power supply). My next task is to work out how to get them to render to the screen.
We want this code to run as fast as possible as there will be times when a lot of cells will be changing
per frame

![Cell sprites](./doc/sprites.gif)

I'm not a pixel artist at all so they're _very_ raw at the moment. Hopefully I can do them a bit better
in future and just output from RGAS over the top of the current crappy ones

## Progress

Here's a quick list of tasks in the approximate order I intend to do them. Not complete and probably
going to change quite significantly as I gradually get stuff done...

- [x] Maze generation
- [x] Draw cell sprites
- [ ] Render a single sprite
- [ ] Render whole game-grid
- [ ] Show currently selected cell in rendered grid
- [ ] Navigate around the grid using keyboard
- [ ] Animate cell rotation
- [ ] Calculate which cells are connected to power supply
- [ ] ...