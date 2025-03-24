// generate data for rot_nibble_data table

function rotnib(n) {
	const hi = n & 0xf0;
	const lo = n & 0x07;
	const carry = n & 0x08;

	return hi + (lo << 1) + (carry >> 3);
}

function binary(n) {
	const s = n.toString(2);
	const pad = '00000000'.slice(s.length);
	return pad + s;
}

function hex(n) {
	const s = n.toString(16);
	const pad = '00'.slice(s.length);
	return '&' + pad + s;
}

function run() {
	const a = [];
	for (let n = 0; n < 256; ++n) {
		a.push(hex(rotnib(n)));
	}
	console.log(a.join(','));
}
