-- View: public.allevents

-- DROP VIEW public.allevents;

CREATE OR REPLACE VIEW public.allevents AS
 WITH order_events AS (
         SELECT ev1.ereportercode AS equipment,
            ev1.eorder AS ordernumber,
            ev1.etime AS starttime,
            ev2.etime AS endtime
           FROM ( SELECT eventmark.ereportercode,
                    eventmark.eorder,
                    eventmark.etime,
                    eventmark.eeventmodifier,
                    row_number() OVER (PARTITION BY eventmark.eorder, eventmark.ereportercode ORDER BY eventmark.etime) AS row_num
                   FROM eventmark
                  WHERE eventmark.eeventtype = 1) ev1
             LEFT JOIN ( SELECT eventmark.etime,
                    eventmark.ereportercode,
                    eventmark.eorder,
                    row_number() OVER (PARTITION BY eventmark.eorder, eventmark.ereportercode ORDER BY eventmark.etime) AS row_num
                   FROM eventmark
                  WHERE eventmark.eeventtype = 1) ev2 ON (ev1.row_num + 1) = ev2.row_num AND ev1.ereportercode::text = ev2.ereportercode::text AND ev1.eorder::text = ev2.eorder::text
          WHERE ev1.eeventmodifier = 1
        ), crew_events AS (
         SELECT ev1.ereportercode AS employee,
            ev1.ecrew AS crewjoined,
            ev1.etime AS jointime,
            ev2.etime AS leavetime,
            ev2.ecrew AS nextcrew
           FROM ( SELECT eventmark.ereportercode,
                    eventmark.ecrew,
                    eventmark.etime,
                    row_number() OVER (PARTITION BY eventmark.ereportercode ORDER BY eventmark.etime) AS row_num
                   FROM eventmark
                  WHERE eventmark.eeventtype = 1024) ev1
             LEFT JOIN ( SELECT eventmark.ereportercode,
                    eventmark.ecrew,
                    eventmark.etime,
                    row_number() OVER (PARTITION BY eventmark.ereportercode ORDER BY eventmark.etime) AS row_num
                   FROM eventmark
                  WHERE eventmark.eeventtype = 1024) ev2 ON (ev1.row_num + 1) = ev2.row_num AND ev1.ereportercode::text = ev2.ereportercode::text
        ), all_events AS (
         SELECT oe.ordernumber,
            oe.equipment,
            oe.starttime,
            oe.endtime,
            ce_mid.employee,
            ce_mid.crewjoined,
            ce_mid.jointime,
            ce_mid.leavetime,
            ce_mid.nextcrew,
            'POST'::text AS eventtype
           FROM order_events oe
            LEFT JOIN LATERAL ( SELECT ce_tmp.employee,
                    ce_tmp.crewjoined,
                    ce_tmp.jointime,
                    ce_tmp.leavetime,
                    ce_tmp.nextcrew
                   FROM crew_events ce_tmp
                  WHERE ce_tmp.crewjoined::text = oe.equipment::text AND ce_tmp.jointime > oe.starttime AND (ce_tmp.jointime < oe.endtime OR oe.endtime is null)) ce_mid ON true
        UNION
         SELECT oe.ordernumber,
            oe.equipment,
            oe.starttime,
            oe.endtime,
            ce_pre.employee,
            ce_pre.crewjoined,
            ce_pre.jointime,
            ce_pre.leavetime,
            ce_pre.nextcrew,
            'PRE'::text AS eventtype
           FROM order_events oe
             LEFT JOIN LATERAL ( SELECT tmp3.employee,
                    tmp3.crewjoined,
                    tmp3.jointime,
                    tmp3.leavetime,
                    tmp3.nextcrew,
                    tmp3.row_num
                   FROM ( SELECT ce_tmp2.employee,
                            ce_tmp2.crewjoined,
                            ce_tmp2.jointime,
                            ce_tmp2.leavetime,
                            ce_tmp2.nextcrew,
                            row_number() OVER (PARTITION BY ce_tmp2.employee ORDER BY ce_tmp2.jointime DESC) AS row_num
                           FROM crew_events ce_tmp2
                          WHERE ce_tmp2.jointime < oe.starttime AND (ce_tmp2.leavetime > oe.starttime OR ce_tmp2.leavetime IS NULL) AND ce_tmp2.crewjoined::text = oe.equipment::text) tmp3
                  WHERE tmp3.row_num = 1) ce_pre ON true
        )
 SELECT all_events.ordernumber,
    all_events.equipment,
    all_events.starttime,
    all_events.endtime,
    all_events.employee,
    all_events.crewjoined,
    all_events.jointime,
    all_events.leavetime,
    all_events.nextcrew,
    all_events.eventtype
   FROM all_events;

ALTER TABLE public.allevents
    OWNER TO postgres;

