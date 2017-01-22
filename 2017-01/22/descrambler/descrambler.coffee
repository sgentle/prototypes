# Descrambles byte 2 given byte 1

highmap = [ 13, 11, 10, 15, 12, 10, 9,  14, 13, 10, 10, 14, 12, 10, 9, 13 ]
lowmap  = [ 11, 6,  8,  1,  15, 10, 12, 5,  3,  14, 0,  9,  7,  2,  4, 13 ]

getNum = (num) -> (((highmap[num & 0xF] - (num >> 4) + 16) % 16) << 4) + lowmap[num & 0xF]

module.exports = getNum

if module is require.main
  console.log getNum(parseInt(process.argv[2], 16)).toString(16)