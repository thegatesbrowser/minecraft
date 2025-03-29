extends RefCounted
class_name  UserCrypto

func GenerateSalt(length = 32):
	var crypto = Crypto.new()
	return crypto.generate_random_bytes(length).hex_encode()
	
func HashPassword(password, salt):
	var passwordData = password.to_utf8_buffer()
	var saltData = salt.to_utf8_buffer()
	
	var combinedData = passwordData + saltData
	var hashContext = HashingContext.new()
	hashContext.start(HashingContext.HASH_SHA256)
	hashContext.update(combinedData)
	var hash = hashContext.finish()
	
	return hash.hex_encode() 
	
func HashData(combinedData):
	var hashContext = HashingContext.new()
	hashContext.start(HashingContext.HASH_SHA256)
	hashContext.update(combinedData.to_utf8_buffer())
	var hash = hashContext.finish()
	
	return hash.hex_encode() 
