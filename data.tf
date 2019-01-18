data "aws_ami"

"int_tableau" {
most_recent = true

filter {
  name = "name"

  values = [
    "dq-tableau-17*",
  ]
}

"int_tableau_linux" {
most_recent = true

filter {
  name = "name"

  values = [
    "dq-tableau-linux-16 *",
  ]
}

owners = [
  "self",
]
}
