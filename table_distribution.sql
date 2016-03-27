CREATE TABLE distribution.taxon_distribution (
    taxon_distribution_id serial primary key,
    taxon_key integer not null,
    cell_id integer not null,
    relative_abundance double precision not null,
    is_backfilled boolean not null default false
);
