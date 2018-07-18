	--1. 
create or replace procedure saveSigners (pV_FIO in scd_signers.V_FIO%type,
                                        pID_MANAGER in ci_users.id_user%type,
                                        pACTION in number) is
  user_code number;
begin 
    select cu.id_user 
      into user_code
      from ci_users  cu
    where cu.id_user = pID_MANAGER;
case 
    when pACTION = 1 then 
        select count(*) into user_code
        from scd_signers 
        where  scd_signers.id_manager = pID_MANAGER;
        if user_code = 0 then
            insert into scd_signers 
                (v_fio, id_manager)
            values
                (pV_FIO, pID_MANAGER);
        else 
        raise_application_error(-20202, 'Запись с данным пользователем уже существует.');
        end if;
    when pACTION = 2 then 
        update scd_signers
            set v_fio = pV_FIO
        where id_manager = pID_MANAGER;
    when pACTION =3 then 
        delete from scd_signers where id_manager = pID_MANAGER;
end case;
exception 
    when no_data_found then 
    raise_application_error(-20020, 'Пользователь не найден.');
	when others then
    raise_application_error(-20020, 'Ошибка'); 
end;
--2.
create function getDecoder (pID_EQUIP_KITS_INST in scd_equip_kits.id_equip_kits_inst%type) 
return number is 
count_kit number; 
begin 
select count(*) into count_kit
from scd_equip_kits 
where dt_start <= current_timestamp
and dt_stop > current_timestamp
and id_equip_kits_inst = pID_EQUIP_KITS_INST;
if (count_kit = 0) then
raise_application_error(-20202, 'Оборудование не найдено.');
else 
for i in (select sek.v_cas_id, sek.v_ext_ident, sc.b_agency
            from scd_equip_kits sek
            inner join fw_contracts fc
            on fc.id_contract_inst = sek.id_contract_inst
            and fc.dt_start <= current_timestamp 
            and fc.dt_stop > current_timestamp
            and fc.v_status = 'A'
            and sek.dt_start <= current_timestamp 
            and sek.dt_stop > current_timestamp
            and ID_EQUIP_KITS_INST = pID_EQUIP_KITS_INST
                inner join scd_contracts sc
                on sc.id_contract_inst = sek.id_contract_inst)
loop 
    if (i.b_agency = 1) then 
    return i.v_cas_id;
    else 
    return i.v_ext_ident;
    end if;
end loop;
end if;
end;
--3.
create or replace procedure getEquip (pID_EQUIP_KITS_INST in scd_equip_kits.id_equip_kits_inst%type default null, dwr out sys_refcursor) is 
    begin 
        if pID_EQUIP_KITS_INST is null then 
        open dwr for 
        select fc.V_LONG_TITLE, cu.v_username, fco.v_ext_ident, sekt.v_name, getDecoder(sek.id_equip_kits_inst)
        from fw_clients fc
            join ci_users cu 
            on cu.id_client_inst = fc.id_client_inst 
            and fc.dt_start <= current_timestamp 
            and fc.dt_stop > current_timestamp 
                join fw_contracts fco
                on fco.id_client_inst = fc.id_client_inst 
                and fco.dt_start <= current_timestamp 
                and fco.dt_stop > current_timestamp 
                and fco.v_status = 'A'
                    join scd_equip_kits sek
                    on sek.id_contract_inst = fco.id_contract_inst 
                    and sek.dt_start <= current_timestamp 
                    and sek.dt_stop > current_timestamp 
                        join scd_equipment_kits_type sekt
                        on sekt.id_equip_kits_type = sek.id_equip_kits_type
                        and sekt.dt_start <= current_timestamp 
                        and sekt.dt_stop > current_timestamp ;
        else
        open dwr for 
        select fc.V_LONG_TITLE, cu.v_username, fco.v_ext_ident, sekt.v_name, getDecoder(pID_EQUIP_KITS_INST)
        from fw_clients fc
            join ci_users cu 
            on cu.id_client_inst = fc.id_client_inst 
            and fc.dt_start <= current_timestamp 
            and fc.dt_stop > current_timestamp 
                join fw_contracts fco
                on fco.id_client_inst = fc.id_client_inst 
                and fco.dt_start <= current_timestamp 
                and fco.dt_stop > current_timestamp 
                and fco.v_status = 'A'
                    join scd_equip_kits sek
                    on sek.id_contract_inst = fco.id_contract_inst 
                    and sek.dt_start <= current_timestamp 
                    and sek.dt_stop > current_timestamp 
                        join scd_equipment_kits_type sekt
                        on sekt.id_equip_kits_type = sek.id_equip_kits_type
                        and sekt.dt_start <= current_timestamp 
                        and sekt.dt_stop > current_timestamp 
        where sek.id_equip_kits_inst = pID_EQUIP_KITS_INST;
        end if;
    end;
--4.
create or replace procedure checkstatus is
cursor dwr is
select sek.id_equip_kits_inst,  fc.v_long_title, fco.v_ext_ident, sc.b_agency, ses.v_name
            from fw_clients fc 
                join fw_contracts fco
                on fco.id_client_inst = fc.id_client_inst
                and fco.dt_start <= current_timestamp 
                and fco.dt_stop > current_timestamp
                and fco.v_status = 'A'
                and fc.dt_start <= current_timestamp 
                and fc.dt_stop > current_timestamp 
                    join scd_equip_kits sek
                    on sek.id_contract_inst = fco.id_contract_inst
                    and sek.dt_start <= current_timestamp
                    and sek.dt_stop > current_timestamp 
                    and sek.id_dealer_client is not null
                        join scd_equipment_status ses 
                        on ses.id_equipment_status = sek.id_status
                        and ses.b_deleted = 0 
                        and ses.v_name != 'Продано'
                            join scd_contracts sc
                            on sc.id_contract_inst = fco.id_contract_inst
                            for update of ses.v_name;
begin 
DBMS_OUTPUT.enable;
for i in dwr
loop
update scd_equipment_status 
set scd_equipment_status.v_name = 'Продано'
where current of dwr;
dbms_output.put_line('Для оборудования' || i.id_equip_kits_inst || 'дилера' || i.v_long_title || 'с контрактом,' || i.v_ext_ident ||  
case when i.b_agency = 1 then 
'являющегося'
when i.b_agency = 0 then 
'неявляющегося'
end ||
'агентской сетью был проставлен статус Продано.');
end loop; 
end;