all: doc format test

doc : README.md
	terraform-docs .
install:
	pre-commit install --install-hooks -t pre-commit -t commit-msg
format :
	terraform fmt
	terraform validate
test :
	terraform test -compact-warnings | awk '/Warnings/ {exit} {print}'
