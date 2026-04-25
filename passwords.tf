resource "random_password" "postgres_password" {
	length  = 16
	special = true
}

resource "random_password" "authentik_token" {
	length  = 50
	special = false
}
