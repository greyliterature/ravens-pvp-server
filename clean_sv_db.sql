ATTACH DATABASE 'sv_cleaned.db' AS 'sv_cleaned';
ATTACH DATABASE 'sv.db' as 'sv';
-- from https://stackoverflow.com/questions/2359205/copying-data-from-one-sqlite-database-to-another#:~:text=ATTACH%20DATABASE%20%27db2%2Esqlite%27%20as%20%27Y%27%3B
--
-- copying tables part
-- from https://til.simonwillison.net/sqlite/copy-tables-between-databases#:~:text=create%20table%20simonwillisonblog%2Etil%20as%20select%20%2A%20from%20tils%2Etil
-- glickos
CREATE TABLE sv_cleaned.player_glickos AS SELECT * FROM sv.player_glickos;
-- match history
CREATE TABLE sv_cleaned.match_data AS SELECT * FROM sv.match_data;
-- mapvotes counts
CREATE TABLE sv_cleaned.mapvote_played_maps AS SELECT * FROM sv.mapvote_played_maps;
--
-- used cmd
-- sqlite3 :memory: < extract_important_info.sql
-- sv.db has 1005 matches logged, sv_cleaned has 1005 too, so data should be finely copied
