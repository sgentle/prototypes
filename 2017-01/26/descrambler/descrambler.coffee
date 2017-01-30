# Descrambles byte 2 given byte 1

lowkeys = [
  "BA461B61" #0
  "67598EA3" #1
  "80F25628" #2
  "1DF756B4" #3
  "FE8A5FA1" #4
  "AB9DC2E3" #5
  "C4369A68" #6
  "513B9AF4" #7
  "32CE93E1" #8
  "EFD10623" #9
  "087ADEA8" #A
  "957FDE34" #B
  "7602D721" #C
  "23154A63" #D
  "4CBE12E8" #E
  "D9B31274" #F
]

for i in [0..15]
  lowkeys[i] = (parseInt(v, 16) for v in lowkeys[i])


# highmap = [ 13, 11, 10, 15, 12, 10, 9,  14, 13, 10, 10, 14, 12, 10, 9, 13 ]
# lowmap  = [ 11, 6,  8,  1,  15, 10, 12, 5,  3,  14, 0,  9,  7,  2,  4, 13 ]

highmap = [0xD, 0xB, 0xA, 0xF, 0xC, 0xA, 0x9, 0xE, 0xD, 0xA, 0xA, 0xE, 0xC, 0xA, 0x9, 0xD]

highbit = (x) -> x >> 4
lowbit = (x) -> x & 0xF

getNum = (num) -> (((highmap[lowbit(num)] - highbit(num) + 16) % 16) << 4) + lowkeys[lowbit(num)][0]

module.exports = getNum

if module is require.main
  console.log getNum(parseInt(process.argv[2], 16)).toString(16).toUpperCase()


