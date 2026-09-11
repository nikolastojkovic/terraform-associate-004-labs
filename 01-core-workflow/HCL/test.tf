resource "github_repository" "testing-repo" {
  name        = "test-repo"
  description = "An example repository created for testing purposes"
  private     = true
}