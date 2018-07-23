create or replace package comm_pack is 
    TYPE nested_typ IS TABLE OF NUMBER;
    function check_ip (pIP_ADDRESS in incb_commutator.ip_address%type) return number;
    procedure getCOMMUTATOR(pDWR out sys_refcursor,
                            pV_MAC_ADDRESS in incb_commutator.v_mac_address%TYPE, 
                            pIP_ADDRESS in incb_commutator.ip_address%type);
    procedure saveCOMMUTATOR(pID_COMMUTATOR in incb_commutator.id_commutator%type,
                            pIP_ADDRESS in incb_commutator.ip_address%type,
                            pID_COMMUTATOR_TYPE in incb_commutator.id_commutator_type%type,
                            pV_DESCRIPTION in incb_commutator.v_description%type,
                            pB_DELETED in incb_commutator.b_deleted%type,
                            pV_MAC_ADDRESS in incb_commutator.v_mac_address%type,
                            pV_COMMUNITY_READ in incb_commutator.v_community_read%type,
                            pV_COMMUNITY_WRITE in incb_commutator.v_community_write%type,
                            pREMOTE_ID in incb_commutator.remote_id%type, 
                            pB_NEED_CONVERT_HEX in incb_commutator.b_need_convert_hex%type,
                            pREMOTE_ID_HEX in incb_commutator.remote_id_hex%type,
                            pACTION in number);
    function check_access_comm(pIP_ADDRESS in incb_commutator.ip_address%type,
                                pV_COMMUNITY in varchar2,
                                pB_MODE_WRITE in number) return number;
    function get_remote_id (pID_COMMUTATOR in incb_commutator.id_commutator%type) return varchar2;
    procedure check_and_del_data (pB_FORCE_DELETE in incb_commutator.b_deleted%type,
                                                out_n out nested_typ);
end comm_pack;
create or replace package body comm_pack is 
function check_ip (pIP_ADDRESS in incb_commutator.ip_address%type)
return number is
cou_ip_str number;
parse_str varchar(18);
begin 
case
    when length(pIP_ADDRESS) < 7 then 
        return 0;
    when length(pIP_ADDRESS) > 15 then
        return 0;
    when instr(pIP_ADDRESS, ' ') != 0 then 
        return 0;
    else 
        GOTO end_proc;
end case;
<<end_proc>>
cou_ip_str:= (length (pIP_ADDRESS) - LENGTH (REPLACE (pIP_ADDRESS, '.', ''))) + 1;
if (cou_ip_str != 4) then
    return 0;
end if;
for i in 1 .. cou_ip_str
    loop
    begin
    parse_str:= to_number(regexp_substr(pIP_ADDRESS, '[^.+ || ^]+', 1, i));
    if(parse_str < 1 or parse_str > 255) then
        return 0;
    end if;
    parse_str:= 0;
    exception 
    when value_error then 
        return 0;
    end;
end loop;
return 1;
end;
    procedure getCOMMUTATOR(pDWR out sys_refcursor,
                                                pV_MAC_ADDRESS in incb_commutator.v_mac_address%TYPE, 
                                                pIP_ADDRESS in incb_commutator.ip_address%type) is
    begin
    open pDWR for
    select * 
    from incb_commutator ic
    where ic.IP_ADDRESS = pIP_ADDRESS
    and ic.V_MAC_ADDRESS = pV_MAC_ADDRESS;
    end getCOMMUTATOR;
    
    procedure saveCOMMUTATOR(pID_COMMUTATOR in incb_commutator.id_commutator%type,
                                                pIP_ADDRESS in incb_commutator.ip_address%type,
                                                pID_COMMUTATOR_TYPE in incb_commutator.id_commutator_type%type,
                                                pV_DESCRIPTION in incb_commutator.v_description%type,
                                                pB_DELETED in incb_commutator.b_deleted%type,
                                                pV_MAC_ADDRESS in incb_commutator.v_mac_address%type,
                                                pV_COMMUNITY_READ in incb_commutator.v_community_read%type,
                                                pV_COMMUNITY_WRITE in incb_commutator.v_community_write%type,
                                                pREMOTE_ID in incb_commutator.remote_id%type, 
                                                pB_NEED_CONVERT_HEX in incb_commutator.b_need_convert_hex%type,
                                                pREMOTE_ID_HEX in incb_commutator.remote_id_hex%type,
                                                pACTION in number) is
    cou_ip number;
    cou_mac number;
    cou_ip_str number;
    parse_str varchar(18);
    begin 
        if (pV_COMMUNITY_READ is null or pV_COMMUNITY_WRITE is null or pIP_ADDRESS is null or pV_MAC_ADDRESS is null or pREMOTE_ID is null) then
            raise_application_error(-20206, 'Поля доступов на чтение и запись, IP, MAC, remote_id являются обязательными для заполнения параметрами.');
        end if;
        if (pB_NEED_CONVERT_HEX = 1 and pREMOTE_ID_HEX is null) then
            raise_application_error(-20203, 'Поле REMOTE_ID_HEX обязательно к заполнению');
        end if;
        case pACTION  
            when 1 then 
                select count(*) into cou_ip
                from incb_commutator ic
                where ic.b_deleted= 0 
                and ic.ip_address = pIP_ADDRESS; 
                if (cou_ip != 0) then
                    raise_application_error(-20202, 'Запись с данным ip уже существует.');
                end if;
                
                select count(*) into cou_mac
                from incb_commutator ico
                where ico.b_deleted= 0 
                and ico.v_mac_address = pV_MAC_ADDRESS;
                if (cou_mac != 0) then
                    raise_application_error(-20202, 'Запись с данным mac адресом уже существует.');
                end if;
                case
                    when length(pIP_ADDRESS) < 7 then 
                        raise_application_error(-20201, 'Размер IP-адреса меньше 7 символов.');
                    when length(pIP_ADDRESS) > 15 then
                        raise_application_error(-20201, 'Размер IP-адреса больше 15 символов.');
                    when instr(pIP_ADDRESS, ' ') != 0 then 
                        raise_application_error(-20201, 'В IP-адресе присутствуют пробелы.');
                    else 
                        GOTO end_proc;
                end case;
                <<end_proc>>
                cou_ip_str:= (length (pIP_ADDRESS) - LENGTH (REPLACE (pIP_ADDRESS, '.', ''))) + 1;
                if (cou_ip_str != 4) then
                    raise_application_error(-20202, 'Формат ip-адреса неправильный.');
                end if;
                for i in 1 .. cou_ip_str
                    loop
                        begin
                        parse_str:= to_number(regexp_substr(pIP_ADDRESS, '[^.+ || ^]+', 1, i));
                        if(parse_str < 1 or parse_str > 255) then
                            raise_application_error(-20201, 'Числа в ip-адресе выходят из диапазона от 1 до 255.');
                        end if;
                        parse_str:= 0;
                        exception 
                            when value_error then 
                            raise_application_error(-20205, 'В данной части ip-адреса ' ||regexp_substr(pIP_ADDRESS, '[^.+ || ^]+', 1, i)||' присутствуют буквы.');
                        end;
                    end loop;
                insert into incb_commutator (id_commutator,
                                            ip_address,
                                            id_commutator_type,
                                            v_description, 
                                            b_deleted,
                                            v_mac_address,
                                            v_community_read,
                                            v_community_write,
                                            remote_id,
                                            b_need_convert_hex,
                                            remote_id_hex)
                values (s_incb_commutator.nextval,
                        pIP_ADDRESS, 
                        pID_COMMUTATOR_TYPE,
                        pV_DESCRIPTION,
                        pB_DELETED,
                        pV_MAC_ADDRESS,
                        pV_COMMUNITY_READ,
                        pV_COMMUNITY_WRITE,
                        pREMOTE_ID,
                        pB_NEED_CONVERT_HEX,
                        pREMOTE_ID_HEX);
            when 2 then 
                 if (pV_COMMUNITY_READ is null or pV_COMMUNITY_WRITE is null or pIP_ADDRESS is null or pV_MAC_ADDRESS is null or pREMOTE_ID_HEX is null) then
                    raise_application_error(-20206, 'Поля доступов на чтение и запись, IP, MAC, remote_id являются обязательными для заполнения параметрами.');
                end if;
                if (pB_NEED_CONVERT_HEX = 1 and pREMOTE_ID_HEX is null) then
                    raise_application_error(-20203, 'Поле REMOTE_ID_HEX обязательно к заполнению');
                end if;
                update incb_commutator 
                    set id_commutator = s_incb_commutator.nextval,
                        ip_address = pIP_ADDRESS, 
                        id_commutator_type = pID_COMMUTATOR_TYPE,
                        v_description = pV_DESCRIPTION,
                        b_deleted = pB_DELETED,
                        v_mac_address = pV_MAC_ADDRESS,
                        v_community_read = pV_COMMUNITY_READ,
                        v_community_write = pV_COMMUNITY_WRITE,
                        remote_id = pREMOTE_ID,
                        b_need_convert_hex = pB_NEED_CONVERT_HEX,
                        remote_id_hex = pREMOTE_ID_HEX
                        where ip_address = pIP_ADDRESS
                        or v_mac_address = pV_MAC_ADDRESS;
            when 3 then 
                delete from incb_commutator inc
                    where inc.id_commutator = pID_COMMUTATOR
                    and inc.ip_address = pIP_ADDRESS
                    and inc.v_mac_address = pV_MAC_ADDRESS;
            else 
                raise_application_error(-20203, 'Действие с записью может принимать только 3 значения. 1 - создание, 2 - редактирование, 3 - удаление');
        end case;
    end;
    
    function check_access_comm (pIP_ADDRESS in incb_commutator.ip_address%type,
                            pV_COMMUNITY in varchar2,
                            pB_MODE_WRITE in number)
    return number is
    coun_ip number;
    com_read incb_commutator.v_community_read%type;
    com_write incb_commutator.v_community_write%type;
    begin 
select count(*)
into coun_ip 
from incb_commutator ic 
where ic.ip_address = pIP_ADDRESS
and ic.b_deleted = 0;
if (coun_ip = 0) then 
    raise_application_error(-20205, 'Такой ip-адрес не существует.');
end if;
select ic.v_community_read, ic.v_community_write
into com_read, com_write
from incb_commutator ic 
where ic.ip_address = pIP_ADDRESS
and ic.b_deleted = 0;
case 
    when pB_MODE_WRITE = 1 and pV_COMMUNITY = com_write then 
        return 1;
    when pB_MODE_WRITE = 1 and pV_COMMUNITY != com_write then 
        return 0;
    when pB_MODE_WRITE = 0 and pV_COMMUNITY = com_read then
        return 1;
    when pB_MODE_WRITE = 0 and pV_COMMUNITY != com_read then
        return 0;
end case;
end;
   
    function get_remote_id (pID_COMMUTATOR in incb_commutator.id_commutator%type) 
return varchar2 is 
b_need_con incb_commutator.b_need_convert_hex%type;
rem_id_hex incb_commutator.remote_id_hex%type;
rem_id incb_commutator.remote_id%type;
begin
begin
    select ic.b_need_convert_hex, ic.remote_id_hex, ic.remote_id
    into b_need_con, rem_id_hex, rem_id
    from incb_commutator ic
    where ic.id_commutator = pID_COMMUTATOR
    and ic.b_deleted = 0;
exception 
    when NO_DATA_FOUND then
        raise_application_error(-20000, 'Нет данных!');
    when TOO_MANY_ROWS then
        raise_application_error(-20001, 'Больше 1 строчки!');
end;
case
    when (b_need_con = 1 and rem_id_hex is not null) then 
        return rem_id_hex;
    when (b_need_con = 1 and rem_id_hex is null) then 
        raise_application_error(-20002, 'Признак использования remote_id в hex = 1, но идентификатор коммутатора в hex формате пуст!');
    when b_need_con = 0 then 
        return rem_id;
end case;
end;
   procedure check_and_del_data (pB_FORCE_DELETE in incb_commutator.b_deleted%type,
                                                out_n out nested_typ ) is 
TYPE nested_typ IS TABLE OF NUMBER;
nt1 nested_typ;
nt2 nested_typ;
nt3 nested_typ;
nt4 nested_typ;
nt nested_typ;
begin
select ic1.id_commutator bulk collect 
into nt1
from (select ic.ip_address, count(*) as cou_ip
        from incb_commutator ic
        group by ic.ip_address) ta
inner join incb_commutator ic1
on ic1.ip_address = ta.ip_address
where ta.cou_ip > 1;

select ic2.id_commutator bulk collect 
into nt2
from (select ico.v_mac_address, count(*) as cou_mac
        from incb_commutator ico
        group by ico.v_mac_address) ta1
inner join incb_commutator ic2
on ic2.v_mac_address = ta1.v_mac_address
where ta1.cou_mac > 1;

select inc.id_commutator bulk collect 
into nt3 
from incb_commutator inc
where inc.b_need_convert_hex = 1 
and inc.remote_id_hex is null;

select id_commutator bulk collect 
into nt4
from (select ic.id_commutator, ic.ip_address 
        from incb_commutator ic 
        where check_ip (ic.ip_address) = 0);  
nt:= nt1 MULTISET UNION DISTINCT nt2 MULTISET UNION DISTINCT nt3 MULTISET UNION DISTINCT nt4;
if (pB_FORCE_DELETE = 1) then
    for i in 1 .. nt.count loop
    comm_pack.saveCOMMUTATOR(pID_COMMUTATOR => nt(i),
                     pIP_ADDRESS         => nt(i),
                     pID_COMMUTATOR_TYPE => null,
                     pV_DESCRIPTION      => null,
                     pB_DELETED          => null,
                     pV_MAC_ADDRESS      => nt(i),
                     pV_COMMUNITY_READ   => null,
                     pV_COMMUNITY_WRITE  => null,
                     pREMOTE_ID          => null,
                     pB_NEED_CONVERT_HEX => null,
                     pREMOTE_ID_HEX      => null,
                     pACTION             => 3);
    end loop;
end if;
end;
end comm_pack;



Insert into INCB_COMMUTATOR (ID_COMMUTATOR,IP_ADDRESS,ID_COMMUTATOR_TYPE,V_DESCRIPTION,B_DELETED,V_MAC_ADDRESS,V_COMMUNITY_READ,V_COMMUNITY_WRITE,REMOTE_ID,B_NEED_CONVERT_HEX,REMOTE_ID_HEX) values (1,'232323',2,'какое-то',0,'1:1:1','аот','ма','1',0,null);
Insert into INCB_COMMUTATOR (ID_COMMUTATOR,IP_ADDRESS,ID_COMMUTATOR_TYPE,V_DESCRIPTION,B_DELETED,V_MAC_ADDRESS,V_COMMUNITY_READ,V_COMMUNITY_WRITE,REMOTE_ID,B_NEED_CONVERT_HEX,REMOTE_ID_HEX) values (2,'1.1.1.1',2,'лаалал',0,'3:2:1','ама','ма','11',0,null);
Insert into INCB_COMMUTATOR (ID_COMMUTATOR,IP_ADDRESS,ID_COMMUTATOR_TYPE,V_DESCRIPTION,B_DELETED,V_MAC_ADDRESS,V_COMMUNITY_READ,V_COMMUNITY_WRITE,REMOTE_ID,B_NEED_CONVERT_HEX,REMOTE_ID_HEX) values (3,'1.155555.1.1',2,'лаалал',0,'10:10:10','ама','ма','11',1,null);
Insert into INCB_COMMUTATOR (ID_COMMUTATOR,IP_ADDRESS,ID_COMMUTATOR_TYPE,V_DESCRIPTION,B_DELETED,V_MAC_ADDRESS,V_COMMUNITY_READ,V_COMMUNITY_WRITE,REMOTE_ID,B_NEED_CONVERT_HEX,REMOTE_ID_HEX) values (5,'121.1521.1.1',2,'лаалал',0,'1:2:3','ама','ма','11',1,null);
Insert into INCB_COMMUTATOR (ID_COMMUTATOR,IP_ADDRESS,ID_COMMUTATOR_TYPE,V_DESCRIPTION,B_DELETED,V_MAC_ADDRESS,V_COMMUNITY_READ,V_COMMUNITY_WRITE,REMOTE_ID,B_NEED_CONVERT_HEX,REMOTE_ID_HEX) values (10,'121.1jkjm21.1.1',2,'лаалал',0,'5:6:7','ама','ма','11',1,null);
