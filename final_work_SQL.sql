-- 1 задание В каких городах больше одного аэропорта?
-- Вывел города, сгруппировал и выставил условия по фильтрации.
select   city from airports a 
group by 1
having count(*) > 1 

--2 задание В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
--При помощи сортировки и ограничения подзапрос получил код самолета
-- Основной запрос получает имя аэропорта

select distinct(airport_name)
from airports a  
   join flights f on a.airport_code = f.departure_airport 
      where f.aircraft_code = (
select a.aircraft_code 
from aircrafts a 
	  order by a."range"  desc limit 1 )
       

--3 задание Вывести 10 рейсов с максимальным временем задержки вылета
--Оператор LIMIT
--Запланироанное время отбытия, минусоввал от реального время отбытия, выставил (is not null) что бы не выводило значения (NULL)
-- Сделал сортировку от большего к меньшему, выставил лимит в 10 рейсов.
select flight_id, actual_departure - scheduled_departure  as Delay
from flights f
  where actual_departure is not null
    order by Delay desc
      limit 10
      
 --4. Были ли брони, по которым не были получены посадочные талоны?
--вывил список броней и посадочных талонов
-- присоеденил  таблицы
--выбирал графы, где нет посадочного талона
select b.book_ref as booking_number,
       bp.boarding_no  as boarding_pass 
from bookings b  
join tickets t on t.book_ref = b.book_ref 
left join boarding_passes bp on t.ticket_no = bp.ticket_no 
where bp.boarding_no is  null

 
--5. Найдите количество свободных мест для каждого рейса, 
--их % отношение к общему количеству мест в самолете.

--Добавьте столбец с накопительным итогом - 
--суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день.
--(Т.е. в этом столбце должна отражаться накопительная сумма - 
--сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня).

--общее количество мест в самолете:
with cte as (
          select s.aircraft_code, count (s.seat_no) as numberseats, a.model
          from seats s
          join aircrafts a on a.aircraft_code = s.aircraft_code
          group by s.aircraft_code, a.model
)
--и добавляем столбик с накопительным итогом 
select departure_airport, 
       actual_departure, 
       cte.numberseats - count(bp.seat_no) as "Свободные места",--находим свободные места (общее количество мест - посадочные места на рейсе)
       (((cte.numberseats - count(bp.seat_no)) / cte.numberseats))*100 as "% отношение к общему количеству мест", 
       sum(count(bp.seat_no) over (partition by f.actual_departure::date, f.departure_airport order by f.actual_departure)
from boarding_passes bp 
join flights f on f.flight_id = bp.flight_id 
join cte on cte.aircraft_code = f.aircraft_code 
group by f.flight_id , cte.numberseats


  --6 задание Найдите процентное соотношение перелетов по типам самолетов от общего количества
      --Подзапрос или окно; оператор ROUND
      --Выбрал моедли самолета, взял общее количество  сделал процентное соотношение,отсортиваол по is not null, сгрупировал по моделям
 select a.model, 
    round(count(f.flight_id) /
		(select count(f.flight_id)
		from flights f 
		where f.actual_departure is not null
		)::dec * 100) percentage_of_total
from aircrafts a 
join flights f on f.aircraft_code = a.aircraft_code 
where f.actual_departure is not null
group by a.model;  


--7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета? (cte)
--создаем CTE для определения стоимости билетов Эконом класса ,берем максимальную цену 
--создаем CTE для определения стоимости билетов Бизнес класса  , берем минимальную цену
--  с помощью сортировки проверяем есть ли города, где бизнес стоит меньше эконома
with cteE as(
			select tf.flight_id, max(tf.amount) as amount_eco 
			from ticket_flights tf 
			where tf.fare_conditions::text like 'Econom'
			group by 1
			order by 1
			),  
	cteB as(
			select tf.flight_id , min(tf.amount) as amount_bus
			from ticket_flights tf 
			where tf.fare_conditions::text like 'Business'
			group by 1
			order by 1) 
select 	a.city as "Город" --
from cteE											
join cteB on cteB.flight_id = cteE.flight_id 
join flights f on f.flight_id  = cteE.flight_id
join airports a on a.airport_code = f.arrival_airport
where cteE.amount_eco > cteB.amount_bus  



--8. Между какими городами нет прямых рейсов?
-- Декартово произведение в предложении FROM
-- Самостоятельно созданные представления (если облачное подключение, то без представления)
-- Оператор EXCEPT

select distinct 
	a.city departure_city,
	a2.city arrival_city 
from airports a, airports a2 
where a.city != a2.city
except 
select fv.departure_city , fv.arrival_city 
from flights_v fv

--9.Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
--сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы
--- Оператор RADIANS или использование sind/cosd
--CASE 


-- Проверяем долетит ли самолёт  

select distinct -- Выводим в таблицу необходимые данные
	dep.airport_name "Аэропорт отправления",
	arr.airport_name "Аэропорт прибытия",
	ac."range" "Дальность полёта самолёта",
	round((acos(sind(dep.coordinates[1]) * sind(arr.coordinates[1]) + cosd(dep.coordinates[1]) * cosd(arr.coordinates[1]) * cosd(dep.coordinates[0] - arr.coordinates[0])) * 6371)::dec, 2) "Расстояние между аэропортами", -- формула расстояния полёта
	case when 
	ac."range" > acos(sind(dep.coordinates[1]) * sind(arr.coordinates[1]) + cosd(dep.coordinates[1]) * cosd(arr.coordinates[1]) * cosd(dep.coordinates[0] - arr.coordinates[0])) * 6371
-- Проверяем долетит ли самолёт 
	then 'Самолёт долетит'
	else 'Самолёт не долетит' end
from flights f 
join airports dep on dep.airport_code = f.departure_airport
join airports arr on arr.airport_code = f.arrival_airport
join aircrafts ac on ac.aircraft_code = f.aircraft_code 


