start:
	bash init.sh

up:
	docker compose down
	docker compose up -d
	docker compose exec api alembic stamp base
	docker compose exec api alembic upgrade head
	docker compose exec api dundie initialize
