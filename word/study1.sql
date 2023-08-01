show tables;

describe city;
describe country;
describe countrylanguage;

## sql에서 index를 어떤경우에 활용하는지 확인
# 대부분의 경우 직감적으로 생각했을 때 index를 활용할 수 있다면 활용할 수 있고 활용할 수 없다면 활용할 수 없음
# B-tree가 정렬된 자료구조 이므로 조건이 정렬된 자료구조에서 쉽게 찾을 수 있는지를 생각하면 됨
# 만약 테이블의 대부분이 결과로 나온다고 optimizer가 예상하면 index를 활용하지 않음
# index만 가지고 수행할 수 있는 쿼리는 table을 조회하지 않음. 이 index를 covering index라고 함
# 인터넷 서칭 결과
# where 적용 조건
#  1. index가 where 절의 and 조건들을 포함한다.
#  2. 컬럼에 계산식이 포함되면 안된다. (ex, Population + 1 = 10001)
#  3. 부정문이면 안된다.
#  4. like 연산자는 앞에 %를 표시해선 안된다.
#  5. or 연산자로 이어진 조건이면 안된다.
# order by 적용 조건
#  1. index가 order by 절의 컬럼들을 포함한다.
#  2. 순서가 같다.
#  3. order by 정렬 기준이 index 정렬 기준과 같거나 반대여야 한다.
#  group by 적용 조건
#  1. index가 order by 절의 컬럼들을 포함한다.
#  2. 순서가 같다.

# 쿼리 실행 계획 조회
explain select * from country where Code = 'KOR';
explain analyze select * from country where Code = 'KOR';

# 한국 정보 (이름으로 조회)
select * from country where Name = 'South Korea';

# 한국 정보 (이름으로 조회)
create index name_idx ON country(Name);

# 퀴리 실행 계획 조회
EXPLAIN select * from country where Name = 'South Korea';
# Result
# 1,SIMPLE,country,,ref,name_idx,name_idx,208,const,1,100,Using index condition
EXPLAIN analyze select * from country where Name = 'South Korea';
# Result
# -> Index lookup on country using name_idx (Name='South Korea'), with index condition: (country.`Name` = 'South Korea')  (cost=0.35 rows=1) (actual time=0.386..0.388 rows=1 loops=1)

EXPLAIN select * from country where Name != 'South Korea';
# Result
# 1,SIMPLE,country,,ALL,name_idx,,,,239,99.58,Using where
EXPLAIN analyze select * from country where Name != 'South Korea';
# Result
# -> Filter: (country.`Name` <> 'South Korea')  (cost=25.7 rows=238) (actual time=0.141..0.355 rows=238 loops=1)
#     -> Table scan on country  (cost=25.7 rows=239) (actual time=0.138..0.311 rows=239 loops=1)

EXPLAIN select * from country where Name like 'South%';
# Result
# 1,SIMPLE,country,,range,name_idx,name_idx,208,,3,100,Using index condition
EXPLAIN analyze select * from country where Name like 'South%';
# Result
# -> Index range scan on country using name_idx over ('South' <= Name <= 'South􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿􏿿'), with index condition: (country.`Name` like 'South%')  (cost=1.61 rows=3) (actual time=0.855..0.938 rows=3 loops=1)
EXPLAIN select * from country where Name like '%South';
# Result
# 1,SIMPLE,country,,ALL,,,,,239,11.11,Using where
EXPLAIN analyze select * from country where Name like '%South';
# Result
# -> Filter: (country.`Name` like '%South')  (cost=25.6 rows=26.6) (actual time=7.05..7.05 rows=0 loops=1)
#     -> Table scan on country  (cost=25.6 rows=239) (actual time=2.49..2.84 rows=239 loops=1)
EXPLAIN select * from country where Name like '%South%';
# Result
# 1,SIMPLE,country,,ALL,,,,,239,11.11,Using where
EXPLAIN analyze select * from country where Name like '%South%';
# Result
# -> Filter: (country.`Name` like '%South%')  (cost=25.6 rows=26.6) (actual time=2.68..3.11 rows=4 loops=1)
#     -> Table scan on country  (cost=25.6 rows=239) (actual time=2.62..2.98 rows=239 loops=1)

select * from country where Population <= 100; # 8 rows
EXPLAIN select * from country where Population <= 100; # 8 rows
# result
# 1,SIMPLE,country,,ALL,,,,,239,33.33,Using where
EXPLAIN analyze select * from country where Population <= 100; # 8 rows
# result
# -> Filter: (country.Population <= 100)  (cost=25.6 rows=79.7) (actual time=0.688..1.01 rows=8 loops=1)
#     -> Table scan on country  (cost=25.6 rows=239) (actual time=0.665..0.972 rows=239 loops=1)
select * from country where Population > 1000000000; # 2 rows
EXPLAIN select * from country where Population > 1000000000; # 2 rows
# result
# 1,SIMPLE,country,,ALL,,,,,239,33.33,Using where
EXPLAIN analyze select * from country where Population > 1000000000; # 2 rows
# result
# -> Filter: (country.Population > 1000000000)  (cost=25.6 rows=79.7) (actual time=0.765..1.17 rows=2 loops=1)
#     -> Table scan on country  (cost=25.6 rows=239) (actual time=0.723..1.13 rows=239 loops=1)


create index population_idx on country(Population);


EXPLAIN select * from country where Population < 100;
# result
# 1,SIMPLE,country,,range,population_idx,population_idx,4,,8,100,Using index condition
EXPLAIN analyze select * from country where Population < 100;
# result
# -> Index range scan on country using population_idx over (Population < 100), with index condition: (country.Population < 100)  (cost=3.86 rows=8) (actual time=0.335..0.732 rows=8 loops=1)

EXPLAIN select * from country where Population > 1000000000; # 2 rows
# result
# 1,SIMPLE,country,,range,population_idx,population_idx,4,,2,100,Using index condition
EXPLAIN analyze select * from country where Population > 1000000000; # 2 rows
# result
# -> Index range scan on country using population_idx over (1000000000 < Population), with index condition: (country.Population > 1000000000)  (cost=1.16 rows=2) (actual time=0.357..0.409 rows=2 loops=1)

# ORDER BY 절의 인덱스 사용

create index population_surfacearea_idx on country(Population, SurfaceArea);

EXPLAIN select * from country order by Population, SurfaceArea limit 3;
# 1,SIMPLE,country,,index,,population_surfacearea_idx,9,,3,100,
EXPLAIN analyze select * from country order by Population, SurfaceArea limit 3;
# result
# -> Limit: 3 row(s)  (cost=0.0257 rows=3) (actual time=3.51..3.51 rows=3 loops=1)
#     -> Index scan on country using population_surfacearea_idx  (cost=0.0257 rows=3) (actual time=3.5..3.5 rows=3 loops=1)
EXPLAIN analyze select * from country order by Population limit 3;
# -> Limit: 3 row(s)  (cost=0.0257 rows=3) (actual time=0.815..0.817 rows=3 loops=1)
#     -> Index scan on country using population_idx  (cost=0.0257 rows=3) (actual time=0.808..0.809 rows=3 loops=1)

## index 사용 안함
EXPLAIN analyze select * from country order by SurfaceArea, Population limit 3;
# -> Limit: 3 row(s)  (cost=25.7 rows=3) (actual time=1.65..1.65 rows=3 loops=1)
#     -> Sort: country.SurfaceArea, country.Population, limit input to 3 row(s) per chunk  (cost=25.7 rows=239) (actual time=1.65..1.65 rows=3 loops=1)
#         -> Table scan on country  (cost=25.7 rows=239) (actual time=0.778..1.22 rows=239 loops=1)
EXPLAIN analyze select * from country order by Population, SurfaceArea desc limit 3;
# -> Limit: 3 row(s)  (cost=25.7 rows=3) (actual time=1.78..1.78 rows=3 loops=1)
#     -> Sort: country.Population, country.SurfaceArea DESC, limit input to 3 row(s) per chunk  (cost=25.7 rows=239) (actual time=1.77..1.77 rows=3 loops=1)
#         -> Table scan on country  (cost=25.7 rows=239) (actual time=0.611..0.783 rows=239 loops=1)


# GROUP BY 절의 인덱스 사용
EXPLAIN analyze select Continent from country group by Continent;
# -> Table scan on <temporary>  (cost=49.6..55 rows=239) (actual time=0.986..0.987 rows=7 loops=1)
#     -> Temporary table with deduplication  (cost=49.6..49.6 rows=239) (actual time=0.985..0.985 rows=7 loops=1)
#         -> Table scan on country  (cost=25.7 rows=239) (actual time=0.49..0.714 rows=239 loops=1)

create index continent_idx on country(Continent);

EXPLAIN analyze select Continent from country group by Continent;
# -> Covering index skip scan for deduplication on country using continent_idx  (cost=2.25 rows=8) (actual time=0.638..0.691 rows=7 loops=1)

select Continent from country group by Continent;

select Continent, Region from country group by Continent, Region;