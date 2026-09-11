provider "random" {}

variable "num_of_pets" {
  type    = number
  description = "Number of random pets to generate"
}

resource "random_pet" "name" {
  length = var.num_of_pets
}

resource "random_pet" "name_2" {
  length = var.num_of_pets
}

output "random_pet_name" {
  value = random_pet.name.id
}