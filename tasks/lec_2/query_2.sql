-- 1. Найти сумму последнего платежа на контракте с лицевым счетом 0102100000088207_MG1 Результат: сумма платежа, дата платежа
select f_sum, dt.dt_event
from 
    (select *
    from fw_contracts f 
        inner join trans_external t
        on t.id_contract = f.id_contract_inst 
    where v_ext_ident = '0102100000088207_MG1'
    and f.dt_start <= current_timestamp 
    and f.dt_stop > current_timestamp
    and t.v_status = 'A') dt
where dt.dt_event = (select max(dt_event)
    from fw_contracts f 
        inner join trans_external t
        on t.id_contract = f.id_contract_inst 
    where v_ext_ident = '0102100000088207_MG1'
    and f.dt_start <= current_timestamp 
    and f.dt_stop > current_timestamp
    and t.v_status = 'A')
-- 2. Создать отчет по департаментам контрактов. Выводить только те контракты, которые активны на текущий момент. 
-- Результат: номер лицевого счета, дату регистрации контракта, наименование департамента (если у контракта не указан департамент, то выводить null)
select fc.v_ext_ident,fc.dt_reg_event, fd.v_name
from fw_contracts fc 
    left join fw_departments fd 
    on fd.id_department = fc.id_department  
where fc.v_status ='A'
and fc.dt_stop > current_timestamp 
and fc.dt_start <= current_timestamp
and fd.b_deleted = 0
-- 3. Найти департаменты, к которым привязано менее 2 контрактов Результат: наименования департаментов
select v_name
from fw_departments fd
where 2 > (select count(*)
            from fw_contracts fc
            where fc.id_department = fd.id_department
            and fc.v_status ='A'
            and fc.dt_stop > current_timestamp 
            and fc.dt_start <= current_timestamp
            and fd.b_deleted = 0
            group by fd.v_name)
-- 4. Создать отчет по платежам за последний месяц в разрезе департаментов 
-- Результат: наименование департамента, сумма платежей в этом департаменте за последний месяц, количество платежей в этом департаменте за последний месяц, 
-- количество контрактов в этом департаменте.
select fd.v_name, sum(te.f_sum), count(te.id_trans), count(fc.id_contract_inst)
from fw_departments fd
    left join fw_contracts fc
    on fc.id_department = fd.id_department
        left join trans_external te
        on te.id_contract = fc.id_contract_inst
        where trunc(te.dt_event, 'MM') = (select trunc(max(dt_event),'MM')
                                            from trans_external)
group by fd.v_name
-- 5. Найти контракты, на которые в 2017 году было совершено более 3 платежей Результат: номер лицевого счета, статус контракта, количество платежей на этом контракте за 2017 году
select fc.v_ext_ident, fc.v_status, count (te1.id_trans)
from fw_contracts fc 
inner join trans_external te1
    on te1.id_contract = fc.id_contract_inst
    and trunc(te1.dt_event, 'YEAR') = '2017-01-01'
    and fc.dt_stop > current_timestamp 
    and fc.dt_start <= current_timestamp
where 3 < (select count(te.id_trans)
            from trans_external te
            where te.id_contract = fc.id_contract_inst
            and trunc(te.dt_event, 'YEAR') = '2017-01-01')
group by fc.v_ext_ident, fc.v_status
-- 6. Найти такие контракты, на которых есть хотя бы один платеж в 2017 году Результат: Номер лицевого счета, статус контракта, департамент контракта 
-- (если департамент не указан то показать NULL)
select distinct fc.v_ext_ident, fc.v_status, fd.v_name
from fw_contracts fc 
    inner join trans_external te
    on te.id_contract = fc.id_contract_inst
    and trunc(te.dt_event, 'YEAR') = '2017-01-01'
        left join fw_departments fd 
        on fd.id_department = fc.id_department
-- 7. Найти такие департаменты, к которым не привязано ни одного контракта Результат: наименование департаментов
select fd.v_name
from fw_departments fd
where not exists (select *
                    from fw_contracts fc
                    where fd.id_department = fc.id_department
                    and fd.b_deleted = 0)
-- 8. Вывести количество платежей на контрактах. Результат: количество платежей, дата последнего платежа, номер лицевого счета контракта, имя пользователя, создавшего платеж
select ex.coun_trans, ex.max_date, ex.v_ext_ident, cu.id_user 
from
    (select fc.id_contract_inst, fc.v_ext_ident, count(te.id_trans) as coun_trans, max(dt_event) as max_date
    from fw_contracts fc
        left join trans_external te
        on te.id_contract = fc.id_contract_inst
    where fc.v_status ='A'
    and fc.dt_stop > current_timestamp 
    and fc.dt_start <= current_timestamp
    group by fc.v_ext_ident, fc.id_contract_inst) ex
        inner join trans_external te1
        on te1.id_contract = ex.id_contract_inst
        and te1.dt_event = ex.max_date
            left join ci_users cu
            on cu.id_user = te1.id_manager
-- 9. Какой был лицевой счет первого января 2016 у контракта, на который совершили платеж ID_TRANCE = 6397542 Результат: номер лицевого счета
select fc.v_ext_ident
from fw_contracts fc
    inner join trans_external te 
    on te.id_contract = fc.id_contract_inst
    where te.id_trans = 6397542
    and fc.dt_start <= to_date ('2016-01-01', 'yyyy-mm-dd')
    and fc.dt_stop > to_date ('2016-01-01', 'yyyy-mm-dd')
-- 10. Найти те контракты, у которых менялась валюта, например, была указана валюта рубль, потом появилась новая запись с валютой уже доллар 
-- Результат: код контракта, лицевой счет, статус, наименование валюты Данные вывести на текущий день
select fc1.id_contract_inst, fc1.v_ext_ident, fc1.v_status, fcu1.v_name
from (select ex.id_contract_inst, count(count_con) as c_c
        from (select fcu.v_name, fc.id_contract_inst, count (fc.id_contract_inst) as count_con
                from fw_contracts fc 
                    inner join fw_currency fcu 
                    on fcu.id_currency = fc.id_currency 
                group by fcu.v_name, fc.id_contract_inst) ex
        group by ex.id_contract_inst) ex 
    inner join fw_contracts fc1
    on fc1.id_contract_inst = ex.id_contract_inst 
        inner join fw_currency fcu1 
        on fcu1.id_currency = fc1.id_currency 
where ex.c_c > 1 
and fc1.dt_start <= current_timestamp
and fc1.dt_stop> current_timestamp 
-- 11. Найти контракты, у которых есть несколько записей со статусом "Расторгнут"
select id_contract_inst 
from (select id_contract_inst, count (id_contract_inst) as count_con
        from fw_contracts 
        where v_status = 'C'
        group by id_contract_inst )
where count_con > 1