function mod3(n) {
	// limit to 8 bits
	n = n & 0xff;

	// split into two 4-bit nibbles
	const n0 = n & 0x0f;
	const n1 = (n & 0xf0) >> 4;

	// get each nibble mod 3 (2 bits each)
	const r0 = n0 % 3;
	const r1 = n1 % 3;

	// conbine two 2-bit remainders
	const m = r0 + (r1 << 2);

	// return combined number mod 3
	return m % 3;
}

let results = [];

for (let n = 0; n < 256; ++n) {
	results.push({
		n,
		a: n % 3,
		b: mod3(n)
	});
}

console.dir(results);
