package function

// Handle a serverless request
func Handle(req []byte) string {
	value := string(req)
	if len(value) > 10 {
		return value[:10]
	} else {
		return value
	}
}
