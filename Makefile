.PHONY: up down logs ps restart reset-db migrate

up:
	./scripts/bootstrap.sh

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

ps:
	docker compose ps

# Wipes the local Postgres volume — local data only, does not touch any deployed DB.
reset-db:
	docker compose down
	docker volume rm veganverse-infra_pgdata
	docker compose up --build

migrate:
	docker compose exec backend npm run prisma:migrate
