#“SQL and data acquisition”
Проектная работа по модулю 

              “SQL и получение данных”





 
![Безымянный](https://user-images.githubusercontent.com/110686280/220353884-8db1e616-d409-4183-b95f-775658c1fdb4.png)









                                                                   
Федосеева Виталия                                                                      Группы SAL-29, SQL-45
1. В работе использовался облачный тип подключения


 



![Безымянный1](https://user-images.githubusercontent.com/110686280/220354339-e2cfc413-3bb4-4e3d-9c41-80884e227bf8.png)










2. Скриншот ER-диаграммы из DBeaver`a согласно моего подключения.

 
![Безымянный3](https://user-images.githubusercontent.com/110686280/220354537-a3946e1e-d294-474f-83c0-5c1d9137b5e4.png)


3. Краткое описание БД

Таблицы:
       ● aircrafts (Самолёты)    
       ● airports (Аэропорты)       
       ● boarding_passes (Посадочные талоны)      
       ● bookings (Бронирования)
       ● flights (Рейсы)
       ● seats (Места)
       ● ticket_flights (Перелёты)
       ● tickets (Билеты)

Представления:
       ● flights_v (Рейсы)

Материализованные представления:
       ● routes (Маршруты)




















4. Развернутый анализ БД - описание таблиц, логики, связей и бизнес области (частично можно взять из описания базы данных, оформленной в виде анализа базы данных).

Таблица bookings.aircrafts
               ● Каждая модель воздушного судна идентифицируется своим                  трехзначным кодом  (aircraft_code). Указывается также название модели (model) и максимальная дальность полета в километрах (range). 
                
               ● Индексы:
                            PRIMARY KEY, btree (aircraft_code)
                ● Ограничения-проверки: 
                            CHECK (range > 0) 
                ● Ссылки извне: 
                           TABLE "flights" FOREIGN KEY (aircraft_code)  
                                  REFERENCES aircrafts(aircraft_code)
                           TABLE "seats" FOREIGN KEY (aircraft_code) 
                                 REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE 

            Таблица bookings.airports
                ● Аэропорт идентифицируется трехбуквенным кодом (airport_code) и имеет свое имя (airport_name). Для города не предусмотрено отдельной сущности, но название (city) указывается и может служить для того, чтобы определить аэропорты одного города. Также указывается широта (longitude), долгота (latitude) и часовой пояс (timezone).
     
                    ● Индексы:
                              PRIMARY KEY, btree (airport_code)
                 ● Ссылки извне:
                        TABLE "flights" FOREIGN KEY (arrival_airport) 
                                 REFERENCES airports(airport_code) 
                         TABLE "flights" FOREIGN KEY (departure_airport)
                                  REFERENCES airports(airpor t_code) 
       
             Таблица bookings.boarding_passes
              ● При регистрации на рейс, которая возможна за сутки до плановой даты отправления, пассажиру выдается посадочный талон. Он идентифицируется также, как и перелет — номером билета и номером рейса. Посадочным талонам присваиваются последовательные номера (boarding_no) в порядке регистрации пассажиров на рейс этот номер будет уникальным только в пределах данного рейса). В посадочном талоне указывается номер места (seat_no)
             
               ● Индексы: 
                    PRIMARY KEY, btree (ticket_no, flight_id) 
                    UNIQUE CONSTRAINT, btree (flight_id, boarding_no) 
                    UNIQUE CONSTRAINT, btree (flight_id, seat_no) 
               ● Ограничения внешнего ключа:
                      FOREIGN KEY (ticket_no, flight_id) 
                      REFERENCES ticket_flights(ticket_no, flight_id)
          
            Таблица bookings.bookings
               ● Пассажир заранее (book_date, максимум за месяц до рейса) бронирует билет себе и, возможно, нескольким другим пассажирам. Бронирование идентифицируется номером (book_ref, шестизначная комбинация букв и цифр). Поле total_amount хранит общую стоимость включенных в бронирование перелетов всех пассажиров. 
                ● Индексы: 
                        PRIMARY KEY, btree (book_ref)
                ● Ссылки извне: 
                        TABLE "tickets" FOREIGN KEY (book_ref) 
                        REFERENCES bookings(book_ref) 
                 
            Таблица bookings.flights
                ● Естественный ключ таблицы рейсов состоит из двух полей — номера рейса (flight_no) и даты отправления (scheduled_departure). Чтобы сделать внешние ключи на эту таблицу компактнее, в качестве первичного используется суррогатный ключ (flight_id). Рейс всегда соединяет две точки — аэропорты вылета (departure_airport) и прибытия (arrival_airport). Такое понятие, как «рейс с пересадками» отсутствует: если из одного аэропорта до другого нет прямого рейса, в билет просто включаются несколько необходимых рейсов. У каждого рейса есть запланированные дата и время вылета (scheduled_departure) и прибытия (scheduled_arrival). Реальные время вылета (actual_departure) и прибытия (actual_arrival) могут отличаться: обычно не сильно, но иногда и на несколько часов, если рейс задержан. 
          Статус рейса (status) может принимать одно из следующих значений:          
                ○ Scheduled Рейс доступен для бронирования. Это происходит за месяц до плановой даты вылета; до этого запись о рейсе не существует в базе данных. 
                ○ On Time 
                      Рейс доступен для регистрации (за сутки до плановой даты вылета) и не задержан. 
                 ○ Delayed
                      Рейс доступен для регистрации (за сутки до плановой даты вылета), но задержан. 
                 ○ Departed 
                     Самолет уже вылетел и находится в воздухе.
                 ○ Arrived 
                     Самолет прибыл в пункт назначения.
                 ○ Cancelled
                    и  Рейс отменен. 
                 ● Индексы: 
                        PRIMARY KEY, btree (flight_id)
                        UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)
                 ● Ограничения-проверки:
                        CHECK (scheduled_arrival > scheduled_departure)
                        CHECK ((actual_arrival IS NULL) OR ((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure)))
                       CHECK (status IN ('On Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled' 'Cancelled')) 
                 ● Ограничения внешнего ключа:
                                       FOREIGN KEY (aircraft_code)
                                               REFERENCES aircrafts(aircraft_code)
                                       FOREIGN KEY (arrival_airport)  
                                               REFERENCES airports(airport_code)
                                       FOREIGN KEY (departure_airport)
                                               REFERENCES airports(airport_code)
                  ● Ссылки извне:
                                       TABLE "ticket_flights" FOREIGN KEY (flight_id)
                                                     REFERENCES flights(flight_id)


Таблица bookings.seats 

         ● Места определяют схему салона каждой модели. Каждое место определяется своим номером (seat_no) и имеет закрепленный за ним класс обслуживания (fare_conditions) — Economy, Comfort или Business. 
          ● Индексы:
                     PRIMARY KEY, btree (aircraft_code, seat_no)
          ● Ограничения-проверки: 
                     CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business')) 
          ● Ограничения внешнего ключа:
                      FOREIGN KEY (aircraft_code) 
                                 REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

Таблица bookings.ticket_flights 
            ● Перелет соединяет билет с рейсом и идентифицируется их номерами. Для каждого перелета указываются его стоимость (amount) и класс обслуживания (fare_conditions).  
            ● Индексы:
                       PRIMARY KEY, btree (ticket_no, flight_id) 
             ● Ограничения-проверки:
                       CHECK (amount >= 0)
                       CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))

             ● Ограничения внешнего ключа: 
                       FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
                       FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no)
               ● Ссылки извне:
                       TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id)
                                                REFERENCES ticket_flights(ticket_no, flight_id)


Таблица bookings.tickets
            ● Билет имеет уникальный номер (ticket_no), состоящий из 13 цифр. Билет содержит идентификатор пассажира (passenger_id) — номер документа, удостоверяющего личность, — его фамилию и имя (passenger_name) и контактную информацию (contact_date). Ни идентификатор пассажира, ни имя не являются постоянными (можно поменять паспорт, можно сменить фамилию), поэтому однозначно найти все билеты одного и того же пассажира невозможно. 

             ● Индексы:
                       PRIMARY KEY, btree (ticket)
               ● Ограничения внешнего ключа:
                       FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)
               ● Ссылки извне:
                       TABLE "ticket_flights" FOREIGN KEY (ticket_no) REFERENCES
                        tickets(ticket_no)        
4.2 Бизнес задачи, которые можно решить, используя БД
         При помощи этой базы данных можно решить ряд бизнес-задач, связанных с организацией пассажирских авиаперевозок и аналитикой совершенных перелетов.
         Анализируя данные по бронированиям и перелетам из БД bookings,   можно решить следующие задачи:     
         ● Выявлять наиболее популярные маршруты 
         ● Выявлять какие модели самолетов используются чаще остальных  
         ● Отслеживать бронирования, заполняемость самолетов, рейсы 
         ● Получать информацию о пассажирах по конкретным номерам билетов, бронированиям 
         ● Выявлять какие рейсы чаще остальных отменяются 
         ● Выявлять разницу между фактическим и плановым временем вылета/прилета, для их дальнейшей оптимизации 
         ● Оперативно получать информацию о существующих рейсах 
         

























   5. Список SQL запросов из приложения №2 с описанием логики их выполнения. 
        Запросы с комментариями выполнены в отдельном sql-файле.

