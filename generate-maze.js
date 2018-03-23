function renderMaze(canvas, maze) {
	canvas.width = maze.x * 8;
	canvas.height = maze.y * 8;
	const context = canvas.getContext('2d');

	function renderRoom(x, y, room) {
		x = x * 8;
		y = y * 8;
		context.rect(x + 2, y + 2, 4, 4);
		if (room & Exits.TOP) {
			context.rect(x + 2, y, 4, 2);
		}
		if (room & Exits.RIGHT) {
			context.rect(x + 6, y + 2, 2, 4);
		}
		if (room & Exits.BOTTOM) {
			context.rect(x + 2, y + 6, 4, 2);
		}
		if (room & Exits.LEFT) {
			context.rect(x, y + 2, 2, 4);
		}
	}

	context.beginPath();
	context.fillStyle = 'white';
	for (let y = 0; y < maze.y; ++y) {
		for (let x = 0; x < maze.x; ++x) {
			renderRoom(x, y, maze.getRoom(x, y));
		}
	}
	context.fill();
}

const Exits = {
	NONE: 0,
	TOP: 1,
	RIGHT: 2,
	BOTTOM: 4,
	LEFT: 8,
	ALL: 15
};

const Status = {
	VISITED: 16
}

function Maze(x, y) {
	this._init(x, y);
}

Maze.prototype._init = function (x, y) {
	this.x = x;
	this.y = y;	
	this.rooms = Array(x * y);
	this.clear();
}

Maze.prototype.clear = function () {
	for (let i = 0; i < this.x * this.y; ++i) {
		this.rooms[i] = 0;
	}
}

Maze.prototype.getRoom = function (x, y) {
	return this.rooms[x + y * this.x];
}

// http://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm
Maze.prototype.generate = function () {
	this.clear();
	this._markEdgeRoomsAsVisited();
	const rooms = this.rooms;

	let index = (this.x >> 1) * (this.y + 1); // index of current room
	const pending = []; // stack of pending rooms
	while (true) {
		// mark this room as visited
		rooms[index] = rooms[index] | Status.VISITED;

		// get array of unvisited neighbours
		const neighbours = this._getUnvisitedNeighbours(index);

		// if no unvisited neighbours
		if (neighbours.length === 0) {
			// if stack is empty then we've finished
			if (pending.length === 0) {
				break;
			}
			// otherwise, move to last room on the stack
			index = pending.pop();
			continue;
		}

		// if there's only one unvisited neighbour then choose that one
		let neighbour;
		if (neighbours.length === 1) {
				neighbour = neighbours[0];
		}
		// otherwise, push current room onto stack and choose a random neighbour
		else {
			pending.push(index);
			neighbour = chooseRandomFromArray(neighbours);
		}

		// join to chosen neighbour
		rooms[index] = rooms[index] | neighbour.direction;
		index = neighbour.index;
		rooms[index] = rooms[index] | neighbour.opposite;
	}
}

Maze.prototype._getAllNeighbours = function (index) {
	return [
		{ index: index - this.x, direction: Exits.TOP, opposite: Exits.BOTTOM },
		{ index: index + 1, direction: Exits.RIGHT, opposite: Exits.LEFT },
		{ index: index + this.x, direction: Exits.BOTTOM, opposite: Exits.TOP },
		{ index: index - 1, direction: Exits.LEFT, opposite: Exits.RIGHT }
	];
}

Maze.prototype._getUnvisitedNeighbours = function (index) {
	const rooms = this.rooms;
	const neighbours = this._getAllNeighbours(index);
	const unvisited = neighbours.filter(function (neighbour) {
		return (rooms[neighbour.index] & Status.VISITED) === 0;
	});
	return unvisited;
}

Maze.prototype._markEdgeRoomsAsVisited = function () {
	// note: weird style as I'm planning on implementing in z80
	let index = 0;
	let count = this.x; // 16
	while (count--) {
		this.rooms[index] = Status.VISITED;
		index++;
	}
	count = this.y - 2; // 14
	while (count--) {
		this.rooms[index] = Status.VISITED;
		index += this.x - 1; // 15
		this.rooms[index] = Status.VISITED;
		index++;
	}
	count = this.x; // 16
	while (count--) {
		this.rooms[index] = Status.VISITED;
		index++;
	}
}

function chooseRandomFromArray(a) {
	const r = Math.floor(Math.random() * a.length);
	return a[r];
}

const canvas = document.getElementById('canvas');
const maze = new Maze(8, 12);
renderMaze(canvas, maze);
canvas.addEventListener('click', function () {
	maze.generate();
	renderMaze(canvas, maze);
});
