drop table if exists public.metadata_test_fixture;
create table public.metadata_test_fixture(a int, b text, c double precision);
insert into public.metadata_test_fixture values (1, 'a', 2.3);
insert into public.metadata_test_fixture values (1, 'a', 2.3);
insert into public.metadata_test_fixture values (1, 'a', 2.3);
insert into public.metadata_test_fixture values (1, 'a', 2.3);
analyze public.metadata_test_fixture;