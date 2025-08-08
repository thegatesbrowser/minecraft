extends RefCounted
class_name  UserCrypto


func GenerateSalt(length = 32):
	var crypto = Crypto.new()
	return crypto.generate_random_bytes(length).hex_encode()
