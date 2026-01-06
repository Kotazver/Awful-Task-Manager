local cipher = require("openssl.cipher")

-- Configuration
local key = "8char_ky" 
local iv  = "8char_iv"
local msg = "Hello from Lua 5.4"

-- Encrypt
local enc = cipher.new("des-cbc")
enc:encrypt(key, iv)
local ciphertext = enc:update(msg) .. enc:final()

-- Decrypt
local dec = cipher.new("des-cbc")
dec:decrypt(key, iv)
local decrypted = dec:update(ciphertext) .. dec:final()

print("Decrypted message: " .. decrypted)