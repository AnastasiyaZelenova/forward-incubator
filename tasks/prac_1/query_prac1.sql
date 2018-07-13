--4
select fss.v_name, fdep.v_name, sum(ta3.ex) as sum_n_cost
from
    (select ta1.id_contract_inst, ta1.ex, ta2.id_department
    from 
    (select fc.id_contract_inst, sum(fsc.n_cost_period) as ex, fd.id_department
       from fw_contracts fc
           left join fw_services_cost fsc
           on fsc.id_contract_inst = fc.id_contract_inst
           and fsc.dt_stop > current_timestamp
           and fsc.dt_start <= current_timestamp
               left join fw_departments fd
               on fd.id_department = fc.id_department
               and fd.b_deleted = 0
           where fc.dt_stop > current_timestamp
           and fc.dt_start <= current_timestamp
           and fc.v_status = 'A'
       group by fc.id_contract_inst, fd.id_department) ta1
        inner join (select ex.id_department, avg(ex.sum_cost) as avg_sum
                         from
                           (select fc.v_ext_ident, sum(fsc.n_cost_period) as sum_cost, fd.id_department
                           from fw_contracts fc
                               left join fw_services_cost fsc
                               on fsc.id_contract_inst = fc.id_contract_inst
                               and fsc.dt_stop > current_timestamp
                               and fsc.dt_start <= current_timestamp
                                   left join fw_departments fd
                                   on fd.id_department = fc.id_department
                                   and fd.b_deleted = 0
                               where fc.dt_stop > current_timestamp
                               and fc.dt_start <= current_timestamp
                               and fc.v_status = 'A'
                           group by fc.v_ext_ident, fd.id_department) ex
                    group by ex.id_department) ta2 
        on ta2.id_department = ta1.id_department 
        where ta1.ex> ta2.avg_sum) ta3
    join fw_services fser
    on fser.id_contract_inst = ta3.id_contract_inst
    and fser.dt_stop > current_timestamp 
    and fser.dt_start <= current_timestamp 
    and fser.b_deleted = 0
    and fser.v_status = 'A'
    join fw_service fss
    on fss.id_service = fser.id_service
    join fw_departments fdep
    on fdep.id_department = ta3.id_department 
group by fss.v_name, fdep.v_name
--5.
select tab.id_contract_inst, tab.cou_disc
from 
    (select fc.id_contract_inst, fsc.id_service_inst , count (distinct fsc.n_discount_period) as cou_disc
    from fw_services_cost fsc 
        join fw_contracts fc
        on fsc.id_contract_inst = fc.id_contract_inst 
        and fsc.dt_start > to_date('2017-10-31', 'yyyy-mm-dd')
        and fsc.dt_start < to_date('2017-12-01', 'yyyy-mm-dd')
        and fc.dt_start < to_date ('2017-11-01')
    group by fc.id_contract_inst, fsc.id_service_inst) tab
where cou_disc >= 2
--6. 
select tab2.v_name, tab1.max_sum, tab2.pl
from 
    (select tab.v_name, tab.id_department, max(tab.fkv) as max_sum
    from
        (select fd.id_department, fd.v_name, fp.v_name as pl, sum(fsc.n_cost_period) as fkv--fp.id_tariff_plan, fp.v_name, fp.v_ext_ident, fss.id_contract_inst, fss.id_service_inst, fss.id_service, fc.id_department, fd.v_name, fsc.n_cost_period
        from fw_tariff_plan fp
            join fw_services fss
            on fss.id_tariff_plan = fp.id_tariff_plan
            and fss.b_deleted = 0
            and fss.dt_stop > current_timestamp 
            and fss.dt_start <= current_timestamp 
            and fss.v_status = 'A'
            and fp.dt_start <= current_timestamp 
            and fp.dt_stop > current_timestamp  
            and fp.b_deleted = 0
                join fw_contracts fc
                on fc.id_contract_inst = fss.id_contract_inst
                and fc.dt_stop > current_timestamp 
                and fc.dt_start <= current_timestamp 
                and fc.v_status = 'A'
                    join fw_departments fd 
                    on fd.id_department = fc.id_department 
                        join fw_service fs
                        on fs.id_service = fss.id_service
                        and fs.b_deleted = 0
                        and fs.b_add_service = 1
                            join fw_services_cost fsc 
                            on fsc.id_contract_inst = fss.id_contract_inst
                            and fsc.id_service_inst = fss.id_service_inst
                            and fsc.dt_stop > current_timestamp 
                            and fsc.dt_start <= current_timestamp 
        group by fd.id_department, fd.v_name, fp.v_name) tab
    group by tab.v_name, tab.id_department) tab1 inner join (select fd.id_department, fd.v_name, fp.v_name as pl, sum(fsc.n_cost_period) as fkv--fp.id_tariff_plan, fp.v_name, fp.v_ext_ident, fss.id_contract_inst, fss.id_service_inst, fss.id_service, fc.id_department, fd.v_name, fsc.n_cost_period
        from fw_tariff_plan fp
            join fw_services fss
            on fss.id_tariff_plan = fp.id_tariff_plan
            and fss.b_deleted = 0
            and fss.dt_stop > current_timestamp 
            and fss.dt_start <= current_timestamp 
            and fss.v_status = 'A'
            and fp.dt_start <= current_timestamp 
            and fp.dt_stop > current_timestamp  
            and fp.b_deleted = 0
                join fw_contracts fc
                on fc.id_contract_inst = fss.id_contract_inst
                and fc.dt_stop > current_timestamp 
                and fc.dt_start <= current_timestamp 
                and fc.v_status = 'A'
                    join fw_departments fd 
                    on fd.id_department = fc.id_department 
                        join fw_service fs
                        on fs.id_service = fss.id_service
                        and fs.b_deleted = 0
                        and fs.b_add_service = 1
                            join fw_services_cost fsc 
                            on fsc.id_contract_inst = fss.id_contract_inst
                            and fsc.id_service_inst = fss.id_service_inst
                            and fsc.dt_stop > current_timestamp 
                            and fsc.dt_start <= current_timestamp 
        group by fd.id_department, fd.v_name, fp.v_name) tab2
        on tab1.id_department = tab2.id_department 
        and tab1.max_sum = tab2.fkv