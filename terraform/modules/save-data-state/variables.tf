variable "init" {
  description = "Module initialize"
}
variable "key" {
  type        = string
  default     = ""
  description = "key state, juga sebagai sub directory"
}
variable "id" {
  type        = string
  description = "id state, juga sebagai nama file"
}
variable "data" {
  description = "data state"
}
