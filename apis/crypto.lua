-- simplified AES / SHA256 / Base64 library
-- By KillaVanilla

--[=[
USAGE DETAILS:

-- Symmetric Cryptography --

To encrypt, use the "encrypt_str" and "encrypt_bytestream" functions.
For example:
 my_encrypted_string = crypto.encrypt_str("something I want to keep hidden", "my secret key", "some random iv")
 
To decrypt, use the "decrypt_str" and "decrypt_bytestream" functions.
For example:
 my_original_string = crypto.decrypt_str(my_encrypted_string, "my secret key", "some random iv")
 
 Note that the key and the IV are the same; in order to decrypt properly, both the key and the IV must be same used in encryption.
 For best (most secure) results, randomize the IV /each/ time you encrypt.
 
-- Hashing --
 
To use hashing, just use the "sha256_digest" function.
 my_hash = crypto.sha256_digest("a string or a table")

 This function returns a 64-character long hexadecimal representation of the hash.
 If you want the hash in bytestream form, use "digest_to_bytestream".
 
 my_hash_bytes = crypto.digest_to_bytestream(my_hash)
 
 This function returns a 32 element long table containing byte values.
 
-- Base64 --
 
To use Base64, use the "encode_base64" and "decode_base64" functions.

"encode_base64" takes any string or bytestream, and returns a base64-encoding of the byte values contained within.
"decode_base64" takes a string previously encoded with "encode_base64", and returns the original byte values as a string.

-- Network Transmission --

Strings containing characters with values over 127 are corrupted when sent over Rednet.
For this reason, all functions that take strings also accept "bytestreams", which are tables containing byte values.

For convenience, two functions are provided to convert between bytestreams and strings: "bytestream_to_string" and "string_to_bytestream".
"encrypt_bytestream" and "decrypt_bytestream" work on raw bytestreams, and return a raw bytestream.

The Base64 functions can be used to make a string safe for network transmission. For example:
 my_encrypted_string = crypto.encrypt_str("something I want to keep hidden", "my secret key", "some random iv")
 my_safe_string = crypto.base64_encode(my_encrypted_string)
 
 modem.transmit(freq, freq, my_safe_string)

 (on the receiving end)
 
 local ev, side, freq, rfreq, received_safe_string = os.pullEvent("modem_message")
 received_encrypted_string = crypto.base64_decode(received_safe_string)
 
 my_original_string = crypto.decrypt_str(received_encrypted_string, "my secret key", "some random iv")
]=]--

local floor = math.floor
local bxor = bit.bxor
local band = bit.band
local brshift = bit.brshift
local insert = table.insert

local sbox = {
[0]=0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76,
0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0,
0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15,
0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75,
0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84,
0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF,
0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8,
0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2,
0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73,
0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB,
0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79,
0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08,
0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A,
0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E,
0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF,
0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16}

local inv_sbox = {
[0]=0x52, 0x09, 0x6A, 0xD5, 0x30, 0x36, 0xA5, 0x38, 0xBF, 0x40, 0xA3, 0x9E, 0x81, 0xF3, 0xD7, 0xFB,
0x7C, 0xE3, 0x39, 0x82, 0x9B, 0x2F, 0xFF, 0x87, 0x34, 0x8E, 0x43, 0x44, 0xC4, 0xDE, 0xE9, 0xCB,
0x54, 0x7B, 0x94, 0x32, 0xA6, 0xC2, 0x23, 0x3D, 0xEE, 0x4C, 0x95, 0x0B, 0x42, 0xFA, 0xC3, 0x4E,
0x08, 0x2E, 0xA1, 0x66, 0x28, 0xD9, 0x24, 0xB2, 0x76, 0x5B, 0xA2, 0x49, 0x6D, 0x8B, 0xD1, 0x25,
0x72, 0xF8, 0xF6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xD4, 0xA4, 0x5C, 0xCC, 0x5D, 0x65, 0xB6, 0x92,
0x6C, 0x70, 0x48, 0x50, 0xFD, 0xED, 0xB9, 0xDA, 0x5E, 0x15, 0x46, 0x57, 0xA7, 0x8D, 0x9D, 0x84,
0x90, 0xD8, 0xAB, 0x00, 0x8C, 0xBC, 0xD3, 0x0A, 0xF7, 0xE4, 0x58, 0x05, 0xB8, 0xB3, 0x45, 0x06,
0xD0, 0x2C, 0x1E, 0x8F, 0xCA, 0x3F, 0x0F, 0x02, 0xC1, 0xAF, 0xBD, 0x03, 0x01, 0x13, 0x8A, 0x6B,
0x3A, 0x91, 0x11, 0x41, 0x4F, 0x67, 0xDC, 0xEA, 0x97, 0xF2, 0xCF, 0xCE, 0xF0, 0xB4, 0xE6, 0x73,
0x96, 0xAC, 0x74, 0x22, 0xE7, 0xAD, 0x35, 0x85, 0xE2, 0xF9, 0x37, 0xE8, 0x1C, 0x75, 0xDF, 0x6E,
0x47, 0xF1, 0x1A, 0x71, 0x1D, 0x29, 0xC5, 0x89, 0x6F, 0xB7, 0x62, 0x0E, 0xAA, 0x18, 0xBE, 0x1B,
0xFC, 0x56, 0x3E, 0x4B, 0xC6, 0xD2, 0x79, 0x20, 0x9A, 0xDB, 0xC0, 0xFE, 0x78, 0xCD, 0x5A, 0xF4,
0x1F, 0xDD, 0xA8, 0x33, 0x88, 0x07, 0xC7, 0x31, 0xB1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xEC, 0x5F,
0x60, 0x51, 0x7F, 0xA9, 0x19, 0xB5, 0x4A, 0x0D, 0x2D, 0xE5, 0x7A, 0x9F, 0x93, 0xC9, 0x9C, 0xEF,
0xA0, 0xE0, 0x3B, 0x4D, 0xAE, 0x2A, 0xF5, 0xB0, 0xC8, 0xEB, 0xBB, 0x3C, 0x83, 0x53, 0x99, 0x61,
0x17, 0x2B, 0x04, 0x7E, 0xBA, 0x77, 0xD6, 0x26, 0xE1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0C, 0x7D}

local Rcon = {
[0]=0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 
0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 
0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 
0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 
0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 
0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 
0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 
0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 
0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 
0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 
0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 
0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 
0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 
0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 
0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 
0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d}

-- Finite-field multiplication lookup tables:

local mul_2 = {
[0]=0x00,0x02,0x04,0x06,0x08,0x0a,0x0c,0x0e,0x10,0x12,0x14,0x16,0x18,0x1a,0x1c,0x1e,
0x20,0x22,0x24,0x26,0x28,0x2a,0x2c,0x2e,0x30,0x32,0x34,0x36,0x38,0x3a,0x3c,0x3e,
0x40,0x42,0x44,0x46,0x48,0x4a,0x4c,0x4e,0x50,0x52,0x54,0x56,0x58,0x5a,0x5c,0x5e,
0x60,0x62,0x64,0x66,0x68,0x6a,0x6c,0x6e,0x70,0x72,0x74,0x76,0x78,0x7a,0x7c,0x7e,
0x80,0x82,0x84,0x86,0x88,0x8a,0x8c,0x8e,0x90,0x92,0x94,0x96,0x98,0x9a,0x9c,0x9e,
0xa0,0xa2,0xa4,0xa6,0xa8,0xaa,0xac,0xae,0xb0,0xb2,0xb4,0xb6,0xb8,0xba,0xbc,0xbe,
0xc0,0xc2,0xc4,0xc6,0xc8,0xca,0xcc,0xce,0xd0,0xd2,0xd4,0xd6,0xd8,0xda,0xdc,0xde,
0xe0,0xe2,0xe4,0xe6,0xe8,0xea,0xec,0xee,0xf0,0xf2,0xf4,0xf6,0xf8,0xfa,0xfc,0xfe,
0x1b,0x19,0x1f,0x1d,0x13,0x11,0x17,0x15,0x0b,0x09,0x0f,0x0d,0x03,0x01,0x07,0x05,
0x3b,0x39,0x3f,0x3d,0x33,0x31,0x37,0x35,0x2b,0x29,0x2f,0x2d,0x23,0x21,0x27,0x25,
0x5b,0x59,0x5f,0x5d,0x53,0x51,0x57,0x55,0x4b,0x49,0x4f,0x4d,0x43,0x41,0x47,0x45,
0x7b,0x79,0x7f,0x7d,0x73,0x71,0x77,0x75,0x6b,0x69,0x6f,0x6d,0x63,0x61,0x67,0x65,
0x9b,0x99,0x9f,0x9d,0x93,0x91,0x97,0x95,0x8b,0x89,0x8f,0x8d,0x83,0x81,0x87,0x85,
0xbb,0xb9,0xbf,0xbd,0xb3,0xb1,0xb7,0xb5,0xab,0xa9,0xaf,0xad,0xa3,0xa1,0xa7,0xa5,
0xdb,0xd9,0xdf,0xdd,0xd3,0xd1,0xd7,0xd5,0xcb,0xc9,0xcf,0xcd,0xc3,0xc1,0xc7,0xc5,
0xfb,0xf9,0xff,0xfd,0xf3,0xf1,0xf7,0xf5,0xeb,0xe9,0xef,0xed,0xe3,0xe1,0xe7,0xe5,
}

local mul_3 = {
[0]=0x00,0x03,0x06,0x05,0x0c,0x0f,0x0a,0x09,0x18,0x1b,0x1e,0x1d,0x14,0x17,0x12,0x11,
0x30,0x33,0x36,0x35,0x3c,0x3f,0x3a,0x39,0x28,0x2b,0x2e,0x2d,0x24,0x27,0x22,0x21,
0x60,0x63,0x66,0x65,0x6c,0x6f,0x6a,0x69,0x78,0x7b,0x7e,0x7d,0x74,0x77,0x72,0x71,
0x50,0x53,0x56,0x55,0x5c,0x5f,0x5a,0x59,0x48,0x4b,0x4e,0x4d,0x44,0x47,0x42,0x41,
0xc0,0xc3,0xc6,0xc5,0xcc,0xcf,0xca,0xc9,0xd8,0xdb,0xde,0xdd,0xd4,0xd7,0xd2,0xd1,
0xf0,0xf3,0xf6,0xf5,0xfc,0xff,0xfa,0xf9,0xe8,0xeb,0xee,0xed,0xe4,0xe7,0xe2,0xe1,
0xa0,0xa3,0xa6,0xa5,0xac,0xaf,0xaa,0xa9,0xb8,0xbb,0xbe,0xbd,0xb4,0xb7,0xb2,0xb1,
0x90,0x93,0x96,0x95,0x9c,0x9f,0x9a,0x99,0x88,0x8b,0x8e,0x8d,0x84,0x87,0x82,0x81,
0x9b,0x98,0x9d,0x9e,0x97,0x94,0x91,0x92,0x83,0x80,0x85,0x86,0x8f,0x8c,0x89,0x8a,
0xab,0xa8,0xad,0xae,0xa7,0xa4,0xa1,0xa2,0xb3,0xb0,0xb5,0xb6,0xbf,0xbc,0xb9,0xba,
0xfb,0xf8,0xfd,0xfe,0xf7,0xf4,0xf1,0xf2,0xe3,0xe0,0xe5,0xe6,0xef,0xec,0xe9,0xea,
0xcb,0xc8,0xcd,0xce,0xc7,0xc4,0xc1,0xc2,0xd3,0xd0,0xd5,0xd6,0xdf,0xdc,0xd9,0xda,
0x5b,0x58,0x5d,0x5e,0x57,0x54,0x51,0x52,0x43,0x40,0x45,0x46,0x4f,0x4c,0x49,0x4a,
0x6b,0x68,0x6d,0x6e,0x67,0x64,0x61,0x62,0x73,0x70,0x75,0x76,0x7f,0x7c,0x79,0x7a,
0x3b,0x38,0x3d,0x3e,0x37,0x34,0x31,0x32,0x23,0x20,0x25,0x26,0x2f,0x2c,0x29,0x2a,
0x0b,0x08,0x0d,0x0e,0x07,0x04,0x01,0x02,0x13,0x10,0x15,0x16,0x1f,0x1c,0x19,0x1a,
}

local mul_9 = {
[0]=0x00,0x09,0x12,0x1b,0x24,0x2d,0x36,0x3f,0x48,0x41,0x5a,0x53,0x6c,0x65,0x7e,0x77,
0x90,0x99,0x82,0x8b,0xb4,0xbd,0xa6,0xaf,0xd8,0xd1,0xca,0xc3,0xfc,0xf5,0xee,0xe7,
0x3b,0x32,0x29,0x20,0x1f,0x16,0x0d,0x04,0x73,0x7a,0x61,0x68,0x57,0x5e,0x45,0x4c,
0xab,0xa2,0xb9,0xb0,0x8f,0x86,0x9d,0x94,0xe3,0xea,0xf1,0xf8,0xc7,0xce,0xd5,0xdc,
0x76,0x7f,0x64,0x6d,0x52,0x5b,0x40,0x49,0x3e,0x37,0x2c,0x25,0x1a,0x13,0x08,0x01,
0xe6,0xef,0xf4,0xfd,0xc2,0xcb,0xd0,0xd9,0xae,0xa7,0xbc,0xb5,0x8a,0x83,0x98,0x91,
0x4d,0x44,0x5f,0x56,0x69,0x60,0x7b,0x72,0x05,0x0c,0x17,0x1e,0x21,0x28,0x33,0x3a,
0xdd,0xd4,0xcf,0xc6,0xf9,0xf0,0xeb,0xe2,0x95,0x9c,0x87,0x8e,0xb1,0xb8,0xa3,0xaa,
0xec,0xe5,0xfe,0xf7,0xc8,0xc1,0xda,0xd3,0xa4,0xad,0xb6,0xbf,0x80,0x89,0x92,0x9b,
0x7c,0x75,0x6e,0x67,0x58,0x51,0x4a,0x43,0x34,0x3d,0x26,0x2f,0x10,0x19,0x02,0x0b,
0xd7,0xde,0xc5,0xcc,0xf3,0xfa,0xe1,0xe8,0x9f,0x96,0x8d,0x84,0xbb,0xb2,0xa9,0xa0,
0x47,0x4e,0x55,0x5c,0x63,0x6a,0x71,0x78,0x0f,0x06,0x1d,0x14,0x2b,0x22,0x39,0x30,
0x9a,0x93,0x88,0x81,0xbe,0xb7,0xac,0xa5,0xd2,0xdb,0xc0,0xc9,0xf6,0xff,0xe4,0xed,
0x0a,0x03,0x18,0x11,0x2e,0x27,0x3c,0x35,0x42,0x4b,0x50,0x59,0x66,0x6f,0x74,0x7d,
0xa1,0xa8,0xb3,0xba,0x85,0x8c,0x97,0x9e,0xe9,0xe0,0xfb,0xf2,0xcd,0xc4,0xdf,0xd6,
0x31,0x38,0x23,0x2a,0x15,0x1c,0x07,0x0e,0x79,0x70,0x6b,0x62,0x5d,0x54,0x4f,0x46,
}

local mul_11 = {
[0]=0x00,0x0b,0x16,0x1d,0x2c,0x27,0x3a,0x31,0x58,0x53,0x4e,0x45,0x74,0x7f,0x62,0x69,
0xb0,0xbb,0xa6,0xad,0x9c,0x97,0x8a,0x81,0xe8,0xe3,0xfe,0xf5,0xc4,0xcf,0xd2,0xd9,
0x7b,0x70,0x6d,0x66,0x57,0x5c,0x41,0x4a,0x23,0x28,0x35,0x3e,0x0f,0x04,0x19,0x12,
0xcb,0xc0,0xdd,0xd6,0xe7,0xec,0xf1,0xfa,0x93,0x98,0x85,0x8e,0xbf,0xb4,0xa9,0xa2,
0xf6,0xfd,0xe0,0xeb,0xda,0xd1,0xcc,0xc7,0xae,0xa5,0xb8,0xb3,0x82,0x89,0x94,0x9f,
0x46,0x4d,0x50,0x5b,0x6a,0x61,0x7c,0x77,0x1e,0x15,0x08,0x03,0x32,0x39,0x24,0x2f,
0x8d,0x86,0x9b,0x90,0xa1,0xaa,0xb7,0xbc,0xd5,0xde,0xc3,0xc8,0xf9,0xf2,0xef,0xe4,
0x3d,0x36,0x2b,0x20,0x11,0x1a,0x07,0x0c,0x65,0x6e,0x73,0x78,0x49,0x42,0x5f,0x54,
0xf7,0xfc,0xe1,0xea,0xdb,0xd0,0xcd,0xc6,0xaf,0xa4,0xb9,0xb2,0x83,0x88,0x95,0x9e,
0x47,0x4c,0x51,0x5a,0x6b,0x60,0x7d,0x76,0x1f,0x14,0x09,0x02,0x33,0x38,0x25,0x2e,
0x8c,0x87,0x9a,0x91,0xa0,0xab,0xb6,0xbd,0xd4,0xdf,0xc2,0xc9,0xf8,0xf3,0xee,0xe5,
0x3c,0x37,0x2a,0x21,0x10,0x1b,0x06,0x0d,0x64,0x6f,0x72,0x79,0x48,0x43,0x5e,0x55,
0x01,0x0a,0x17,0x1c,0x2d,0x26,0x3b,0x30,0x59,0x52,0x4f,0x44,0x75,0x7e,0x63,0x68,
0xb1,0xba,0xa7,0xac,0x9d,0x96,0x8b,0x80,0xe9,0xe2,0xff,0xf4,0xc5,0xce,0xd3,0xd8,
0x7a,0x71,0x6c,0x67,0x56,0x5d,0x40,0x4b,0x22,0x29,0x34,0x3f,0x0e,0x05,0x18,0x13,
0xca,0xc1,0xdc,0xd7,0xe6,0xed,0xf0,0xfb,0x92,0x99,0x84,0x8f,0xbe,0xb5,0xa8,0xa3,
}

local mul_13 = {
[0]=0x00,0x0d,0x1a,0x17,0x34,0x39,0x2e,0x23,0x68,0x65,0x72,0x7f,0x5c,0x51,0x46,0x4b,
0xd0,0xdd,0xca,0xc7,0xe4,0xe9,0xfe,0xf3,0xb8,0xb5,0xa2,0xaf,0x8c,0x81,0x96,0x9b,
0xbb,0xb6,0xa1,0xac,0x8f,0x82,0x95,0x98,0xd3,0xde,0xc9,0xc4,0xe7,0xea,0xfd,0xf0,
0x6b,0x66,0x71,0x7c,0x5f,0x52,0x45,0x48,0x03,0x0e,0x19,0x14,0x37,0x3a,0x2d,0x20,
0x6d,0x60,0x77,0x7a,0x59,0x54,0x43,0x4e,0x05,0x08,0x1f,0x12,0x31,0x3c,0x2b,0x26,
0xbd,0xb0,0xa7,0xaa,0x89,0x84,0x93,0x9e,0xd5,0xd8,0xcf,0xc2,0xe1,0xec,0xfb,0xf6,
0xd6,0xdb,0xcc,0xc1,0xe2,0xef,0xf8,0xf5,0xbe,0xb3,0xa4,0xa9,0x8a,0x87,0x90,0x9d,
0x06,0x0b,0x1c,0x11,0x32,0x3f,0x28,0x25,0x6e,0x63,0x74,0x79,0x5a,0x57,0x40,0x4d,
0xda,0xd7,0xc0,0xcd,0xee,0xe3,0xf4,0xf9,0xb2,0xbf,0xa8,0xa5,0x86,0x8b,0x9c,0x91,
0x0a,0x07,0x10,0x1d,0x3e,0x33,0x24,0x29,0x62,0x6f,0x78,0x75,0x56,0x5b,0x4c,0x41,
0x61,0x6c,0x7b,0x76,0x55,0x58,0x4f,0x42,0x09,0x04,0x13,0x1e,0x3d,0x30,0x27,0x2a,
0xb1,0xbc,0xab,0xa6,0x85,0x88,0x9f,0x92,0xd9,0xd4,0xc3,0xce,0xed,0xe0,0xf7,0xfa,
0xb7,0xba,0xad,0xa0,0x83,0x8e,0x99,0x94,0xdf,0xd2,0xc5,0xc8,0xeb,0xe6,0xf1,0xfc,
0x67,0x6a,0x7d,0x70,0x53,0x5e,0x49,0x44,0x0f,0x02,0x15,0x18,0x3b,0x36,0x21,0x2c,
0x0c,0x01,0x16,0x1b,0x38,0x35,0x22,0x2f,0x64,0x69,0x7e,0x73,0x50,0x5d,0x4a,0x47,
0xdc,0xd1,0xc6,0xcb,0xe8,0xe5,0xf2,0xff,0xb4,0xb9,0xae,0xa3,0x80,0x8d,0x9a,0x97,
}

local mul_14 = {
[0]=0x00,0x0e,0x1c,0x12,0x38,0x36,0x24,0x2a,0x70,0x7e,0x6c,0x62,0x48,0x46,0x54,0x5a,
0xe0,0xee,0xfc,0xf2,0xd8,0xd6,0xc4,0xca,0x90,0x9e,0x8c,0x82,0xa8,0xa6,0xb4,0xba,
0xdb,0xd5,0xc7,0xc9,0xe3,0xed,0xff,0xf1,0xab,0xa5,0xb7,0xb9,0x93,0x9d,0x8f,0x81,
0x3b,0x35,0x27,0x29,0x03,0x0d,0x1f,0x11,0x4b,0x45,0x57,0x59,0x73,0x7d,0x6f,0x61,
0xad,0xa3,0xb1,0xbf,0x95,0x9b,0x89,0x87,0xdd,0xd3,0xc1,0xcf,0xe5,0xeb,0xf9,0xf7,
0x4d,0x43,0x51,0x5f,0x75,0x7b,0x69,0x67,0x3d,0x33,0x21,0x2f,0x05,0x0b,0x19,0x17,
0x76,0x78,0x6a,0x64,0x4e,0x40,0x52,0x5c,0x06,0x08,0x1a,0x14,0x3e,0x30,0x22,0x2c,
0x96,0x98,0x8a,0x84,0xae,0xa0,0xb2,0xbc,0xe6,0xe8,0xfa,0xf4,0xde,0xd0,0xc2,0xcc,
0x41,0x4f,0x5d,0x53,0x79,0x77,0x65,0x6b,0x31,0x3f,0x2d,0x23,0x09,0x07,0x15,0x1b,
0xa1,0xaf,0xbd,0xb3,0x99,0x97,0x85,0x8b,0xd1,0xdf,0xcd,0xc3,0xe9,0xe7,0xf5,0xfb,
0x9a,0x94,0x86,0x88,0xa2,0xac,0xbe,0xb0,0xea,0xe4,0xf6,0xf8,0xd2,0xdc,0xce,0xc0,
0x7a,0x74,0x66,0x68,0x42,0x4c,0x5e,0x50,0x0a,0x04,0x16,0x18,0x32,0x3c,0x2e,0x20,
0xec,0xe2,0xf0,0xfe,0xd4,0xda,0xc8,0xc6,0x9c,0x92,0x80,0x8e,0xa4,0xaa,0xb8,0xb6,
0x0c,0x02,0x10,0x1e,0x34,0x3a,0x28,0x26,0x7c,0x72,0x60,0x6e,0x44,0x4a,0x58,0x56,
0x37,0x39,0x2b,0x25,0x0f,0x01,0x13,0x1d,0x47,0x49,0x5b,0x55,0x7f,0x71,0x63,0x6d,
0xd7,0xd9,0xcb,0xc5,0xef,0xe1,0xf3,0xfd,0xa7,0xa9,0xbb,0xb5,0x9f,0x91,0x83,0x8d,
}
local function copy(input)
	local c = {}
	for i, v in pairs(input) do
		c[i] = v
	end
	return c
end

local function subBytes(input, invert)
	for i=1, #input do
		if not (sbox[input[i]] and inv_sbox[input[i]]) then
			error("subBytes: input["..i.."] > 0xFF")
		end
		if invert then
			input[i] = inv_sbox[input[i]]
		else
			input[i] = sbox[input[i]]
		end
	end
	return input
end

local function shiftRows(input)
	local copy = {}
	-- Row 1: No change
	copy[1] = input[1]
	copy[2] = input[2]
	copy[3] = input[3]
	copy[4] = input[4]
	-- Row 2: Offset 1
	copy[5] = input[6]
	copy[6] = input[7]
	copy[7] = input[8]
	copy[8] = input[5]
	-- Row 3: Offset 2
	copy[9] = input[11]
	copy[10] = input[12]
	copy[11] = input[9]
	copy[12] = input[10]
	-- Row 4: Offset 3
	copy[13] = input[16]
	copy[14] = input[13]
	copy[15] = input[14]
	copy[16] = input[15]
	return copy
end

local function invShiftRows(input)
	local copy = {}
	-- Row 1: No change
	copy[1] = input[1]
	copy[2] = input[2]
	copy[3] = input[3]
	copy[4] = input[4]
	-- Row 2: Offset 1
	copy[5] = input[8]
	copy[6] = input[5]
	copy[7] = input[6]
	copy[8] = input[7]
	-- Row 3: Offset 2
	copy[9] = input[11]
	copy[10] = input[12]
	copy[11] = input[9]
	copy[12] = input[10]
	-- Row 4: Offset 3
	copy[13] = input[14]
	copy[14] = input[15]
	copy[15] = input[16]
	copy[16] = input[13]
	return copy
end

local function finite_field_mul(a,b) -- Multiply two numbers in GF(256), assuming that polynomials are 8 bits wide
	local product = 0
	local mulA, mulB = a,b
	for i=1, 8 do
		--print("FFMul: MulA: "..mulA.." MulB: "..mulB)
		if mulA == 0 or mulB == 0 then
			break
		end
		if bit.band(1, mulB) > 0 then
			product = bxor(product, mulA)
		end
		mulB = bit.brshift(mulB, 1)
		local carry = bit.band(0x80, mulA)
		mulA = bit.band(0xFF, bit.blshift(mulA, 1))
		if carry > 0 then
			mulA = bxor( mulA, 0x1B )
		end
	end
	return product
end

local function mixColumn(column)
	local output = {}
	--print("MixColumn: #column: "..#column)
	output[1] = bxor( mul_2[column[1]], bxor( mul_3[column[2]], bxor( column[3], column[4] ) ) )
	output[2] = bxor( column[1], bxor( mul_2[column[2]], bxor( mul_3[column[3]], column[4] ) ) )
	output[3] = bxor( column[1], bxor( column[2], bxor( mul_2[column[3]], mul_3[column[4]] ) ) )
	output[4] = bxor( mul_3[column[1]], bxor( column[2], bxor( column[3], mul_2[column[4]] ) ) )
	return output
end

local function invMixColumn(column)
	local output = {}
	--print("InvMixColumn: #column: "..#column)
	output[1] = bxor( mul_14[column[1]], bxor( mul_11[column[2]], bxor( mul_13[column[3]], mul_9[column[4]] ) ) )
	output[2] = bxor( mul_9[column[1]], bxor( mul_14[column[2]], bxor( mul_11[column[3]], mul_13[column[4]] ) ) )
	output[3] = bxor( mul_13[column[1]], bxor( mul_9[column[2]], bxor( mul_14[column[3]], mul_11[column[4]] ) ) )
	output[4] = bxor( mul_11[column[1]], bxor( mul_13[column[2]], bxor( mul_9[column[3]], mul_14[column[4]] ) ) )
	return output
end

local function mixColumns(input, invert)
	--print("MixColumns: #input: "..#input)
	-- Ooops. I mixed the ROWS instead of the COLUMNS on accident.
	local output = {}
	local c1 = { input[1], input[5], input[9], input[13] }
	local c2 = { input[2], input[6], input[10], input[14] }
	local c3 = { input[3], input[7], input[11], input[15] }
	local c4 = { input[4], input[8], input[12], input[16] }
	if invert then
		c1 = invMixColumn(c1)
		c2 = invMixColumn(c2)
		c3 = invMixColumn(c3)
		c4 = invMixColumn(c4)
	else
		c1 = mixColumn(c1)
		c2 = mixColumn(c2)
		c3 = mixColumn(c3)
		c4 = mixColumn(c4)
	end
	
	output[1] = c1[1]
	output[5] = c1[2]
	output[9] = c1[3]
	output[13] = c1[4]
	
	output[2] = c2[1]
	output[6] = c2[2]
	output[10] = c2[3]
	output[14] = c2[4]
	
	output[3] = c3[1]
	output[7] = c3[2]
	output[11] = c3[3]
	output[15] = c3[4]
	
	output[4] = c4[1]
	output[8] = c4[2]
	output[12] = c4[3]
	output[16] = c4[4]
	
	return output
end

local function addRoundKey(input, exp_key, round)
	local output = {}
	for i=1, 16 do
		assert(input[i], "input["..i.."]=nil!")
		assert(exp_key[ ((round-1)*16)+i ], "round_key["..(((round-1)*16)+i).."]=nil!")
		output[i] = bxor( input[i], exp_key[ ((round-1)*16)+i ] )
	end
	return output
end

function key_schedule(enc_key)
	local function core(in1, in2, in3, in4, i)
		local s1 = in2
		local s2 = in3
		local s3 = in4
		local s4 = in1
		s1 = bxor(sbox[s1], Rcon[i])
		s2 = sbox[s2]
		s3 = sbox[s3]
		s4 = sbox[s4]
		return s1, s2, s3, s4
	end
	
	local n, b, key_type = 0, 0, 0
	
	-- Len | n | b |
	-- 128 |16 |176|
	-- 192 |24 |208|
	-- 256 |32 |240|
	
	-- Determine keysize:
	
	if #enc_key < 16 then
		error("Encryption key is too small; key size must be more than 16 bytes.")
	elseif #enc_key >= 16 and #enc_key < 24 then
		n = 16
		b = 176
		--key_type = 1
	elseif #enc_key >= 24 and #enc_key < 32 then
		n = 24
		b = 208
		--key_type = 2
	else
		n = 32
		b = 240
		--key_type = 3
	end
	
	local exp_key = {}
	local rcon_iter = 1
	for i=1, n do
		exp_key[i] = enc_key[i]
	end
	while #exp_key < b do
		local t1 = exp_key[#exp_key]
		local t2 = exp_key[#exp_key-1]
		local t3 = exp_key[#exp_key-2]
		local t4 = exp_key[#exp_key-3]
		t1, t2, t3, t4 = core(t1, t2, t3, t4, rcon_iter)
		rcon_iter = rcon_iter+1
		t1 = bxor(t1, exp_key[#exp_key-(n-1)])
		t2 = bxor(t2, exp_key[#exp_key-(n-2)])
		t3 = bxor(t3, exp_key[#exp_key-(n-3)])
		t4 = bxor(t4, exp_key[#exp_key-(n-4)])
		insert(exp_key, t1)
		insert(exp_key, t2)
		insert(exp_key, t3)
		insert(exp_key, t4)
		for i=1, 3 do
			t1 = bxor(exp_key[#exp_key], exp_key[#exp_key-(n-1)])
			t2 = bxor(exp_key[#exp_key-1], exp_key[#exp_key-(n-2)])
			t3 = bxor(exp_key[#exp_key-2], exp_key[#exp_key-(n-3)])
			t4 = bxor(exp_key[#exp_key-3], exp_key[#exp_key-(n-4)])
			insert(exp_key, t1)
			insert(exp_key, t2)
			insert(exp_key, t3)
			insert(exp_key, t4)
		end
		if key_type == 3 then -- If we're processing a 256 bit key...
			-- Take the previous 4 bytes of the expanded key, run them through the sbox,
			-- then XOR them with the previous n bytes of the expanded key, then output them
			-- as the next 4 bytes of expanded key.
			t1 = bxor(sbox[exp_key[#exp_key]], exp_key[#exp_key-(n-1)])
			t2 = bxor(sbox[exp_key[#exp_key-1]], exp_key[#exp_key-(n-2)])
			t3 = bxor(sbox[exp_key[#exp_key-2]], exp_key[#exp_key-(n-3)])
			t4 = bxor(sbox[exp_key[#exp_key-3]], exp_key[#exp_key-(n-4)])
			insert(exp_key, t1)
			insert(exp_key, t2)
			insert(exp_key, t3)
			insert(exp_key, t4)
		end
		if key_type == 2 or key_type == 3 then -- If we're processing a 192-bit or 256-bit key..
			local i = 2
			if key_type == 3 then
				i = 3
			end
			for j=1, i do
				t1 = bxor(exp_key[#exp_key], exp_key[#exp_key-(n-1)])
				t2 = bxor(exp_key[#exp_key-1], exp_key[#exp_key-(n-2)])
				t3 = bxor(exp_key[#exp_key-2], exp_key[#exp_key-(n-3)])
				t4 = bxor(exp_key[#exp_key-3], exp_key[#exp_key-(n-4)])
				insert(exp_key, t1)
				insert(exp_key, t2)
				insert(exp_key, t3)
				insert(exp_key, t4)
			end
		end
	end
	return exp_key
end

function encrypt_block(data, key)
	local exp_key = key_schedule(key)
	local state = data
	local nr = 0
	
	if #exp_key == 176 then -- Key type 1 (128-bits)
		nr = 10
	elseif #exp_key == 208 then -- Key type 2 (192-bits)
		nr = 12
	elseif #exp_key == 240 then -- Key type 3 (256-bits)
		nr = 14
	else
		error("encrypt_block: Unknown key size?", 2)
	end
	
	-- Inital round:
	state = addRoundKey(state, exp_key, 1)
	
	-- Repeat (Nr-1) times:
	for round_num = 2, nr-1 do	
		state = subBytes(state)
		state = shiftRows(state)
		state = mixColumns(state)
		state = addRoundKey(state, exp_key, round_num)
	end
	
	-- Final round (No mixColumns()):
	state = subBytes(state)
	state = shiftRows(state)
	state = addRoundKey(state, exp_key, nr)
	return state
end

function decrypt_block(data, key)
	local exp_key = key_schedule(key)
	local state = data
	local nr = 0
	
	if #exp_key == 176 then -- Key type 1 (128-bits)
		nr = 10
	elseif #exp_key == 208 then -- Key type 2 (192-bits)
		nr = 12
	elseif #exp_key == 240 then -- Key type 3 (256-bits)
		nr = 14
	else
		error("decrypt_block: Unknown key size?", 2)
	end
	
	-- Inital round:
	state = addRoundKey(state, exp_key, nr)
	
	-- Repeat (Nr-1) times:
	for round_num = nr-1, 2, -1 do
		state = invShiftRows(state)
		state = subBytes(state, true)
		state = addRoundKey(state, exp_key, round_num)
		state = mixColumns(state, true)
	end
	
	-- Final round (No mixColumns()):
	state = invShiftRows(state)
	state = subBytes(state, true)
	state = addRoundKey(state, exp_key, 1)
	return state
end

local function encrypt_block_customExpKey(data, exp_key)
	local state = data
	local nr = 0
	if #exp_key == 176 then -- Key type 1 (128-bits)
		nr = 10
	elseif #exp_key == 208 then -- Key type 2 (192-bits)
		nr = 12
	elseif #exp_key == 240 then -- Key type 3 (256-bits)
		nr = 14
	else
		error("encrypt_block: Unknown key size?", 2)
	end
	
	-- Inital round:
	state = addRoundKey(state, exp_key, 1)
	
	-- Repeat (Nr-1) times:
	for round_num = 2, nr-1 do	
		state = subBytes(state)
		state = shiftRows(state)
		state = mixColumns(state)
		state = addRoundKey(state, exp_key, round_num)
	end
	
	-- Final round (No mixColumns()):
	state = subBytes(state)
	state = shiftRows(state)
	state = addRoundKey(state, exp_key, nr)
	return state
end

local function decrypt_block_customExpKey(data, exp_key)
	local state = data
	local nr = 0
	if #exp_key == 176 then -- Key type 1 (128-bits)
		nr = 10
	elseif #exp_key == 208 then -- Key type 2 (192-bits)
		nr = 12
	elseif #exp_key == 240 then -- Key type 3 (256-bits)
		nr = 14
	else
		error("decrypt_block: Unknown key size?", 2)
	end
	
	-- Inital round:
	state = addRoundKey(state, exp_key, nr)
	
	-- Repeat (Nr-1) times:
	for round_num = nr-1, 2, -1 do
		state = invShiftRows(state)
		state = subBytes(state, true)
		state = addRoundKey(state, exp_key, round_num)
		state = mixColumns(state, true)
	end
	
	-- Final round (No mixColumns()):
	state = invShiftRows(state)
	state = subBytes(state, true)
	state = addRoundKey(state, exp_key, 1)
	return state
end

function encrypt_bytestream(data, key, init_vector)
	local outputBytestream = {}
    
	local exp_key = {}
    
    if type(key) == "string" then
        local k2 = {}
        for i=1, #key do
            k2[i] = string.byte(key, i, i)
        end
        exp_key = key_schedule(k2)
    elseif type(key) == "table" then
        exp_key = key_schedule(key)
    else
        error("encrypt: Invalid data passed as key (is your key a string or table?)", 2)
    end
    
    local actual_iv = {}
    
    if type(init_vector) == "string" then
        local iv2 = {}
        for i=1, #init_vector do
            iv2[i] = string.byte(init_vector, i, i)
        end
        actual_iv = iv2
    elseif type(init_vector) == "table" then
        actual_iv = init_vector
    else
        error("encrypt: Invalid data passed as IV (is your init vector a string or table?)", 2)
    end
    
    if #actual_iv < 16 then
        for i=0, 16-#actual_iv do
            table.insert(actual_iv, 0)
        end
    end
    
    local blocks = { actual_iv }
    
	for i=1, #data do
		if data[i] == nil or data[i] >= 256 then
			if type(data[i]) == "number" then
				error("encrypt: Invalid data at i="..i.." data[i]="..data[i], 2)
			else
				error("encrypt: Invalid data at i="..i.." data[i]="..type(data[i]), 2)
			end
		end
	end
	local s = os.clock()
	for i=1, math.ceil(#data/16) do
		local block = {}
		if not blocks[i] then
			error("encrypt: blocks["..i.."] is nil! Input size: "..#data, 2)
		end
		for j=1, 16 do
			block[j] = data[((i-1)*16)+j] or 0
			block[j] = bxor(block[j], blocks[i][j]) -- XOR this block with the previous one
		end
		--print("#bytes: "..#block)
		block = encrypt_block_customExpKey(block, exp_key)
		table.insert(blocks, block)
		for j=1, 16 do
			insert(outputBytestream, block[j])
		end
        if os.clock() - s >= 2.5 then
            os.queueEvent("")
            os.pullEvent("")
            s = os.clock()
        end
	end
	return outputBytestream
end

function decrypt_bytestream(data, key, init_vector)
	local outputBytestream = {}
	local exp_key = {}
    
    if type(key) == "string" then
        local k2 = {}
        for i=1, #key do
            k2[i] = string.byte(key, i, i)
        end
        exp_key = key_schedule(k2)
    elseif type(key) == "table" then
        exp_key = key_schedule(key)
    else
        error("decrypt: Invalid data passed as key (is your key a string or table?)", 2)
    end
    
    local actual_iv = {}
    
    if type(init_vector) == "string" then
        local iv2 = {}
        for i=1, #init_vector do
            iv2[i] = string.byte(init_vector, i, i)
        end
        actual_iv = iv2
    elseif type(init_vector) == "table" then
        actual_iv = init_vector
    else
        error("decrypt: Invalid data passed as IV (is your init vector a string or table?)", 2)
    end
    
    if #actual_iv < 16 then
        for i=0, 16-#actual_iv do
            table.insert(actual_iv, 0)
        end
    end
    
    local blocks = { actual_iv }
    
	local s = os.clock()
	for i=1, math.ceil(#data/16) do
		local block = {}
		if not blocks[i] then
			error("decrypt: blocks["..i.."] is nil! Input size: "..#data, 2)
		end
		for j=1, 16 do
			block[j] = data[((i-1)*16)+j] or 0
		end
		table.insert(blocks, block)
		local dec_block = decrypt_block_customExpKey(block, exp_key)
		for j=1, 16 do
			dec_block[j] = bxor(dec_block[j], blocks[i][j]) -- We use XOR on the plaintext, not the ciphertext
			table.insert(outputBytestream, dec_block[j])
		end
        if os.clock() - s >= 2.5 then
            os.queueEvent("")
            os.pullEvent("")
            s = os.clock()
        end
	end
	-- Remove padding:
	for i=#outputBytestream, #outputBytestream-15, -1 do
		if outputBytestream[i] ~= 0 then
			break
		else
			outputBytestream[i] = nil
		end
	end
	return outputBytestream
end

-- Encrypt / Decrypt strings:

function encrypt_str(data, key, iv)
	local byteStream = {}
	for i=1, #data do
		table.insert(byteStream, string.byte(data, i, i))
	end
    
	local output_bytestream = encrypt_bytestream(byteStream, key, iv)
    
	local output = ""
	for i=1, #output_bytestream do
		output = output..string.char(output_bytestream[i])
	end
	return output
end

function decrypt_str(data, key, iv)
	local byteStream = {}
	for i=1, #data do
		table.insert(byteStream, string.byte(data, i, i))
	end
	local output_bytestream = decrypt_bytestream(byteStream, key, iv)
	local output = ""
	for i=1, #output_bytestream do
		output = output..string.char(output_bytestream[i])
	end
	return output
end

-- SHA2:

local k = {
   0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
   0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
   0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
   0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
   0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
   0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
   0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
   0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local function generateShiftBitmask(bits)
	local bitmask = 0x80000000
	for i=1, bits do
		--bit.bor(bitmask, 0x8000000)
		bitmask = bitmask / 2 -- arithmetic right shift by 1 copies sign (leftmost) bit
	end
	return bitmask
end

local function rrotate(input, shiftAmount)
	if input > (2^32) then
		input = input % (2^32)
	end
	--return bit.bor( bit.brshift(input, shiftAmount), bit.blshift(input, 32-shiftAmount) )
	return (floor(input/(2^shiftAmount)) + ((input*(2^(32-shiftAmount))) % (2^32))) % (2^32)
end

local function Preprocessing(message)
	local out = {}
    
    for i=1, #message do
        insert(out, message[i])
    end
    
    local len = #message*8
	local bits = #message*8
	insert(out, 0x80)
	while true do
		if bits % 512 == 448 then
			break
		else
			insert(out, 0)
			bits = #out*8
		end
	end
	insert(out, len)
	return out
end

local function breakMsg(message)
	local chunks = {}
	local chunk = 1
	for word=1, #message, 16 do
		chunks[chunk] = {}
		insert(chunks[chunk], message[word] or 0)
		insert(chunks[chunk], message[word+1] or 0)
		insert(chunks[chunk], message[word+2] or 0)
		insert(chunks[chunk], message[word+3] or 0)
		insert(chunks[chunk], message[word+4] or 0)
		insert(chunks[chunk], message[word+5] or 0)
		insert(chunks[chunk], message[word+6] or 0)
		insert(chunks[chunk], message[word+7] or 0)
		insert(chunks[chunk], message[word+8] or 0)
		insert(chunks[chunk], message[word+9] or 0)
		insert(chunks[chunk], message[word+10] or 0)
		insert(chunks[chunk], message[word+11] or 0)
		insert(chunks[chunk], message[word+12] or 0)
		insert(chunks[chunk], message[word+13] or 0)
		insert(chunks[chunk], message[word+14] or 0)
		insert(chunks[chunk], message[word+15] or 0)
		chunk = chunk+1
	end
	return chunks
end

local function digestChunk(chunk, hash)
	for i=17, 64 do
		local s0 = bxor( brshift(chunk[i-15], 3), bxor( rrotate(chunk[i-15], 7), rrotate(chunk[i-15], 18) ) )
		local s1 = bxor( brshift(chunk[i-2], 10), bxor( rrotate(chunk[i-2], 17), rrotate(chunk[i-2], 19) ) )
		chunk[i] = (chunk[i-16] + s0 + chunk[i-7] + s1) % (2^32)
	end

	local a = hash[1]
	local b = hash[2]
	local c = hash[3]
	local d = hash[4]
	local e = hash[5]
	local f = hash[6]
	local g = hash[7]
	local h = hash[8]
	
	for i=1, 64 do
		local S1 = bxor(rrotate(e, 6), bxor(rrotate(e,11),rrotate(e,25)))
		local ch = bxor( band(e, f), band(bit.bnot(e), g) )
		local t1 = h + S1 + ch + k[i] + chunk[i]
		--d = d+h
		S0 = bxor(rrotate(a,2), bxor( rrotate(a,13), rrotate(a,22) ))
		local maj = bxor( band( a, bxor(b, c) ), band(b, c) )
		local t2 = S0 + maj
		
		h = g
		g = f
		f = e
		e = d + t1
		d = c
		c = b
		b = a
		a = t1 + t2
		
		a = a % (2^32)
		b = b % (2^32)
		c = c % (2^32)
		d = d % (2^32)
		e = e % (2^32)
		f = f % (2^32)
		g = g % (2^32)
		h = h % (2^32)
		
	end
		
	hash[1] = (hash[1] + a) % (2^32)
	hash[2] = (hash[2] + b) % (2^32)
	hash[3] = (hash[3] + c) % (2^32)
	hash[4] = (hash[4] + d) % (2^32)
	hash[5] = (hash[5] + e) % (2^32)
	hash[6] = (hash[6] + f) % (2^32)
	hash[7] = (hash[7] + g) % (2^32)
	hash[8] = (hash[8] + h) % (2^32)
	
	return hash
end

local function hashToBytes(hash)
	local bytes = {}
	for i=1, 8 do
		table.insert(bytes, band(brshift(band(hash[i], 0xFF000000), 24), 0xFF))
		table.insert(bytes, band(brshift(band(hash[i], 0xFF0000), 16), 0xFF))
		table.insert(bytes, band(brshift(band(hash[i], 0xFF00), 8), 0xFF))
		table.insert(bytes, band(hash[i], 0xFF))
	end
	return bytes
end

function sha256_digest(msg)
    local preprocessed_msg = {}
    
    if type(msg) == "table" then
        preprocessed_msg = Preprocessing(msg)
    elseif type(msg) == "string" then
        local bytes = {}
        for i=1, #msg do
            bytes[i] = string.byte(msg, i, i)
        end
        preprocessed_msg = Preprocessing(bytes)
    end
    
	local hash = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19}
	local chunks = breakMsg(preprocessed_msg)
	local lastPause = os.clock()
    
	for i=1, #chunks do
		hash = digestChunk(chunks[i], hash)
		if (os.clock() - lastPause) >= 2.5 then
			os.queueEvent("")
			os.pullEvent("")
			lastPause = os.clock()
		end
	end
    
    local outputStr = ""
	for i=1, #hash do
        local cur = string.format("%X", hash[i])
        for i=1, 8-#cur do
            cur = "0"..cur
        end
		outputStr = outputStr..cur
	end
    
    return outputStr
end

function digest_to_bytestream(str)
    local out = {}
    
    for i=1, #str, 2 do
        local sub = string.sub(str, i, i+1)
        table.insert(out, tonumber(sub, 16))
    end
    
    return out
end

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function sixBitToBase64(input)
	return string.sub(alphabet, input+1, input+1)
end

local function base64ToSixBit(input)
	for i=1, 64 do
		if input == string.sub(alphabet, i, i) then
			return i-1
		end
	end
end

local function octetToBase64(o1, o2, o3)
	local i1 = sixBitToBase64(bit.brshift(bit.band(o1, 0xFC), 2))
	local i2 = "A"
	local i3 = "="
	local i4 = "="
	if o2 then
		i2 = sixBitToBase64(bit.bor( bit.blshift(bit.band(o1, 3), 4), bit.brshift(bit.band(o2, 0xF0), 4) ))
		if not o3 then
			i3 = sixBitToBase64(bit.blshift(bit.band(o2, 0x0F), 2))
		else
			i3 = sixBitToBase64(bit.bor( bit.blshift(bit.band(o2, 0x0F), 2), bit.brshift(bit.band(o3, 0xC0), 6) ))
		end
	else
		i2 = sixBitToBase64(bit.blshift(bit.band(o1, 3), 4))
	end
	if o3 then
		i4 = sixBitToBase64(bit.band(o3, 0x3F))
	end
	
	return i1..i2..i3..i4
end

-- octet 1 needs characters 1/2
-- octet 2 needs characters 2/3
-- octet 3 needs characters 3/4

local function base64ToThreeOctet(s1)
	local c1 = base64ToSixBit(string.sub(s1, 1, 1))
	local c2 = base64ToSixBit(string.sub(s1, 2, 2))
	local c3 = 0
	local c4 = 0
	local o1 = 0
	local o2 = 0
	local o3 = 0
	if string.sub(s1, 3, 3) == "=" then
		c3 = nil
		c4 = nil
	elseif string.sub(s1, 4, 4) == "=" then
		c3 = base64ToSixBit(string.sub(s1, 3, 3))
		c4 = nil
	else
		c3 = base64ToSixBit(string.sub(s1, 3, 3))
		c4 = base64ToSixBit(string.sub(s1, 4, 4))
	end
	o1 = bit.bor( bit.blshift(c1, 2), bit.brshift(bit.band( c2, 0x30 ), 4) )
	if c3 then
		o2 = bit.bor( bit.blshift(bit.band(c2, 0x0F), 4), bit.brshift(bit.band( c3, 0x3C ), 2) )
	else
		o2 = nil
	end
	if c4 then
		o3 = bit.bor( bit.blshift(bit.band(c3, 3), 6), c4 )
	else
		o3 = nil
	end
	return o1, o2, o3
end

local function splitIntoBlocks(bytes)
	local blockNum = 1
	local blocks = {}
	for i=1, #bytes, 3 do
		blocks[blockNum] = {bytes[i], bytes[i+1], bytes[i+2]}
		--[[
		if #blocks[blockNum] < 3 then
			for j=#blocks[blockNum]+1, 3 do
				table.insert(blocks[blockNum], 0)
			end
		end
		]]
		blockNum = blockNum+1
	end
	return blocks
end

function encode_base64(bytes)
    local actual_bytes = {}
    
    if type(bytes) == "table" then
        actual_bytes = bytes
    elseif type(bytes) == "string" then
        for i=1, #bytes do
            table.insert(actual_bytes, string.byte(bytes, i, i))
        end
    else
        error("encode_base64: invalid value passed to encode (is your input data a table or string?)", 2)
    end
    
	local blocks = splitIntoBlocks(actual_bytes)
	local output = ""
	for i=1, #blocks do
		output = output..octetToBase64( unpack(blocks[i]) )
	end
	return output
end

function decode_base64(str)
	local bytes = {}
	local blocks = {}
	local blockNum = 1
	for i=1, #str, 4 do
		blocks[blockNum] = string.sub(str, i, i+3)
		blockNum = blockNum+1
	end
	for i=1, #blocks do
		local o1, o2, o3 = base64ToThreeOctet(blocks[i])
		table.insert(bytes, o1)
		table.insert(bytes, o2)
		table.insert(bytes, o3)
	end
	-- Remove padding:
	--[[
	for i=#bytes, 1, -1 do
		if bytes[i] ~= 0 then
			break
		else
			bytes[i] = nil
		end
	end
	]]
	local str = ""
    
    for i=1, #bytes do
        str = str .. string.char(bytes[i])
    end
    
    return str
end

function string_to_bytestream(str)
    local bytes = {}
    
    for i=1, #str do
        table.insert(bytes, string.byte(str, i, i))
    end
    
    return bytes
end

function bytestream_to_string(bytes)
    local str = ""
    
    for i=1, #bytes do
        str = str .. string.char(bytes[i])
    end
    
    return str
end