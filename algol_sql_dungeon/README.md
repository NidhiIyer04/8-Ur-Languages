## algol dungeon game with database save

This project runs an algol68 dungeon game and saves each run into a postgres database. After finishing the game, your results are automatically stored and can be viewed using sql queries.

## setup

make sure you have the following installed:

* algol68g
* postgres (psql)

create the database:

```bash
createdb blackthorn
```

create tables and views:

```bash
psql -d blackthorn -f dungeon_schema.sql
```

## run the game

give execute permission:

```bash
chmod +x dungeon_save.sh
```

run the script:

```bash
./dungeon_save.sh
```

play the game. when the game ends, your results will be saved automatically.

## view results

run:

```bash
psql -d blackthorn -f queries.sql
```

or open psql:

```bash
psql -d blackthorn
```

example queries:

```sql
select * from runs;

select * from leaderboard limit 10;

select * from best_runs;
```

exit:

```sql
\q
```

