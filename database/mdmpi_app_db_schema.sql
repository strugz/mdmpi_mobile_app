--
-- PostgreSQL database dump
--

\restrict wg67uZkvB4dYZWUrbJRdxslu7E86VR5CJrDP5x7hiS5lSF6YXGsqNXRvpsXQXen

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-08-28 08:56:08

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 247 (class 1255 OID 16389)
-- Name: trg_a_tblrequestairsea_history_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_a_tblrequestairsea_history_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.a_tblrequestairsea_history (
            requestid, clientid, mobileid, itemcategoryid, datepickup,
            createdby, receivedby, itempreparedat, itempreparedendat, preparedby,
            waybillnumber, remarks, status, tripticketnumber, driver, helper,
            dispatchedat, dropoffat,
            provincialpickupby, provincialpickupat,
            provincialintransitat, provincialintransitlocation, provincialreceivername,
            provincialdeliveredendat, provincialdeliveredlocation,
            createdat, updatedat,
            actiontype, changedat, changedby
        )
        VALUES (
            NEW.requestid, NEW.clientid, NEW.mobileid, NEW.itemcategoryid, NEW.datepickup,
            NEW.createdby, NEW.receivedby, NEW.itempreparedat, NEW.itempreparedendat, NEW.preparedby,
            NEW.waybillnumber, NEW.remarks, NEW.status, NEW.tripticketnumber, NEW.driver, NEW.helper,
            NEW.dispatchedat, NEW.dropoffat,
            NEW.provincialpickupby, NEW.provincialpickupat,
            NEW.provincialintransitat, NEW.provincialintransitlocation, NEW.provincialreceivername,
            NEW.provincialdeliveredendat, NEW.provincialdeliveredlocation,
            NEW.createdat, NEW.updatedat,
            'INSERT', CURRENT_TIMESTAMP, NEW.updatedby
        );

        RETURN NEW;
    END IF;

    -- UPDATE
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.a_tblrequestairsea_history (
            requestid, clientid, mobileid, itemcategoryid, datepickup,
            createdby, receivedby, itempreparedat, itempreparedendat, preparedby,
            waybillnumber, remarks, status, tripticketnumber, driver, helper,
            dispatchedat, dropoffat,
            provincialpickupby, provincialpickupat,
            provincialintransitat, provincialintransitlocation, provincialreceivername,
            provincialdeliveredendat, provincialdeliveredlocation,
            createdat, updatedat,
            actiontype, changedat, changedby
        )
        VALUES (
            NEW.requestid, NEW.clientid, NEW.mobileid, NEW.itemcategoryid, NEW.datepickup,
            NEW.createdby, NEW.receivedby, NEW.itempreparedat, NEW.itempreparedendat, NEW.preparedby,
            NEW.waybillnumber, NEW.remarks, NEW.status, NEW.tripticketnumber, NEW.driver, NEW.helper,
            NEW.dispatchedat, NEW.dropoffat,
            NEW.provincialpickupby, NEW.provincialpickupat,
            NEW.provincialintransitat, NEW.provincialintransitlocation, NEW.provincialreceivername,
            NEW.provincialdeliveredendat, NEW.provincialdeliveredlocation,
            NEW.createdat, NEW.updatedat,
            'UPDATE', CURRENT_TIMESTAMP, NEW.updatedby
        );

        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.trg_a_tblrequestairsea_history_fn() OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 16390)
-- Name: trg_a_tblrequestpickupmdmpi_history_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_a_tblrequestpickupmdmpi_history_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.a_tblrequestpickupmdmpi_history (
            actiontype, changedat, changedby,
            requestid, clientid, itemcategoryid,
            preparedby, itempreparedat, itempreparedendat,
            datepickup, remarks, status,
            releasedby, receivedby,
            createdby, createdat, updatedat, updatedby
        )
        VALUES (
            'INSERT',
            CURRENT_TIMESTAMP,
            current_user,

            NEW.requestid,
            NEW.clientid,
            NEW.itemcategoryid,
            NEW.preparedby,
            NEW.itempreparedat,
            NEW.itempreparedendat,
            NEW.datepickup,
            NEW.remarks,
            NEW.status,
            NEW.releasedby,
            NEW.receivedby,
            NEW.createdby,
            NEW.createdat,
            NEW.updatedat,
            NEW.updatedby
        );

        RETURN NEW;
    END IF;

    -- UPDATE
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.a_tblrequestpickupmdmpi_history (
            actiontype, changedat, changedby,
            requestid, clientid, itemcategoryid,
            preparedby, itempreparedat, itempreparedendat,
            datepickup, remarks, status,
            releasedby, receivedby,
            createdby, createdat, updatedat, updatedby
        )
        VALUES (
            'UPDATE',
            CURRENT_TIMESTAMP,
            current_user,

            NEW.requestid,
            NEW.clientid,
            NEW.itemcategoryid,
            NEW.preparedby,
            NEW.itempreparedat,
            NEW.itempreparedendat,
            NEW.datepickup,
            NEW.remarks,
            NEW.status,
            NEW.releasedby,
            NEW.receivedby,
            NEW.createdby,
            NEW.createdat,
            NEW.updatedat,
            NEW.updatedby
        );

        RETURN NEW;
    END IF;

    -- DELETE
    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.a_tblrequestpickupmdmpi_history (
            actiontype, changedat, changedby,
            requestid, clientid, itemcategoryid,
            preparedby, itempreparedat, itempreparedendat,
            datepickup, remarks, status,
            releasedby, receivedby,
            createdby, createdat, updatedat, updatedby
        )
        VALUES (
            'DELETE',
            CURRENT_TIMESTAMP,
            current_user,

            OLD.requestid,
            OLD.clientid,
            OLD.itemcategoryid,
            OLD.preparedby,
            OLD.itempreparedat,
            OLD.itempreparedendat,
            OLD.datepickup,
            OLD.remarks,
            OLD.status,
            OLD.releasedby,
            OLD.receivedby,
            OLD.createdby,
            OLD.createdat,
            OLD.updatedat,
            OLD.updatedby
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.trg_a_tblrequestpickupmdmpi_history_fn() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 16391)
-- Name: trg_a_tblrequestpulloutreturnpickup_history_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_a_tblrequestpulloutreturnpickup_history_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.a_tblrequestpulloutreturnpickup_history (
            actiontype,
            changedat,
            changedby,
            requestid,
            clientid,
            clientcontactperson,
            formcategoryid,
            slipno,
            irrfnumber,
            irrfdate,
            reasonforreturn,
            releasedby,
            receivedby,
            itemcategoryid,
            pulloutdate,
            pulloutdatestartat,
            pulloutdateendat,
            requeststatus,
            tripticketnumber,
            driver,
            helper,
            mobileid,
            createdat,
            updatedat,
            createdby,
            requestedby
        )
        VALUES (
            'INSERT',
            CURRENT_TIMESTAMP,
            current_user,
            NEW.requestid,
            NEW.clientid,
            NEW.clientcontactperson,
            NEW.formcategoryid,
            NEW.slipno,
            NEW.irrfnumber,
            NEW.irrfdate,
            NEW.reasonforreturn,
            NEW.releasedby,
            NEW.receivedby,
            NEW.itemcategoryid,
            NEW.pulloutdate,
            NEW.pulloutdatestartat,
            NEW.pulloutdateendat,
            NEW.requeststatus,
            NEW.tripticketnumber,
            NEW.driver,
            NEW.helper,
            NEW.mobileid,
            NEW.createdat,
            NEW.updatedat,
            NEW.createdby,
            NEW.requestedby
        );

        RETURN NEW;
    END IF;

    -- UPDATE
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.a_tblrequestpulloutreturnpickup_history (
            actiontype,
            changedat,
            changedby,
            requestid,
            clientid,
            clientcontactperson,
            formcategoryid,
            slipno,
            irrfnumber,
            irrfdate,
            reasonforreturn,
            releasedby,
            receivedby,
            itemcategoryid,
            pulloutdate,
            pulloutdatestartat,
            pulloutdateendat,
            requeststatus,
            tripticketnumber,
            driver,
            helper,
            mobileid,
            createdat,
            updatedat,
            createdby,
            requestedby
        )
        VALUES (
            'UPDATE',
            CURRENT_TIMESTAMP,
            current_user,
            NEW.requestid,
            NEW.clientid,
            NEW.clientcontactperson,
            NEW.formcategoryid,
            NEW.slipno,
            NEW.irrfnumber,
            NEW.irrfdate,
            NEW.reasonforreturn,
            NEW.releasedby,
            NEW.receivedby,
            NEW.itemcategoryid,
            NEW.pulloutdate,
            NEW.pulloutdatestartat,
            NEW.pulloutdateendat,
            NEW.requeststatus,
            NEW.tripticketnumber,
            NEW.driver,
            NEW.helper,
            NEW.mobileid,
            NEW.createdat,
            NEW.updatedat,
            NEW.createdby,
            NEW.requestedby
        );

        RETURN NEW;
    END IF;

    -- DELETE
    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.a_tblrequestpulloutreturnpickup_history (
            actiontype,
            changedat,
            changedby,
            requestid,
            clientid,
            clientcontactperson,
            formcategoryid,
            slipno,
            irrfnumber,
            irrfdate,
            reasonforreturn,
            releasedby,
            receivedby,
            itemcategoryid,
            pulloutdate,
            pulloutdatestartat,
            pulloutdateendat,
            requeststatus,
            tripticketnumber,
            driver,
            helper,
            mobileid,
            createdat,
            updatedat,
            createdby,
            requestedby
        )
        VALUES (
            'DELETE',
            CURRENT_TIMESTAMP,
            current_user,
            OLD.requestid,
            OLD.clientid,
            OLD.clientcontactperson,
            OLD.formcategoryid,
            OLD.slipno,
            OLD.irrfnumber,
            OLD.irrfdate,
            OLD.reasonforreturn,
            OLD.releasedby,
            OLD.receivedby,
            OLD.itemcategoryid,
            OLD.pulloutdate,
            OLD.pulloutdatestartat,
            OLD.pulloutdateendat,
            OLD.requeststatus,
            OLD.tripticketnumber,
            OLD.driver,
            OLD.helper,
            OLD.mobileid,
            OLD.createdat,
            OLD.updatedat,
            OLD.createdby,
            OLD.requestedby
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.trg_a_tblrequestpulloutreturnpickup_history_fn() OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16392)
-- Name: trg_backload_resetstandarddelivery_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_backload_resetstandarddelivery_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE public.a_tblrequeststandarddelivery rsd
    SET
        requestitempreparedby   = NULL,
        requestdeliveredby      = NULL,
        requestitempreparedat   = NULL,
        requestitempreparedendat= NULL,
        requestdeliveredat      = NULL,
        requestdeliveredendat   = NULL,
        locationstartedat       = NULL,
        locationendat           = NULL,
        mobileid                = NULL,
        requestdriverhelper     = NULL,
        receiver                = NULL,
        requesttripticketnumber = NULL,
        updatedby               = NULL,
        requeststatus           = 'New Request',
        requestdeliverydate     = NEW.deliverydate
    WHERE rsd.requestid = NEW.requestid;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_backload_resetstandarddelivery_fn() OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 16393)
-- Name: trg_requeststandarddelivery_history_fn(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_requeststandarddelivery_history_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    -- INSERT
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.a_tblrequeststandarddeliveryhistory (
            actiontype,
            changedat,
            requestid,
            itemcategoryid,
            formcategoryid,
            requestclientid,
            requestshippingmethod,
            requestdeliveryterms,
            requestdeliverydate,
            requestpreference,
            requeststatus,
            requestby,
            requestcreatedby,
            requestitempreparedby,
            requestdeliveredby,
            requestcreatedat,
            requestitempreparedat,
            requestitempreparedendat,
            requestdeliveredat,
            requestdeliveredendat,
            locationstartedat,
            locationendat,
            mobileid,
            requestdriverhelper,
            receiver,
            recipientcontactdetails,
            requesttripticketnumber,
            changedby,
			recipientname
        )
        VALUES (
            'INSERT',
            CURRENT_TIMESTAMP,
            NEW.requestid,
            NEW.itemcategoryid,
            NEW.formcategoryid,
            NEW.requestclientid,
            NEW.requestshippingmethod,
            NEW.requestdeliveryterms,
            NEW.requestdeliverydate,
            NEW.requestpreference,
            NEW.requeststatus,
            NEW.requestby,
            NEW.requestcreatedby,
            NEW.requestitempreparedby,
            NEW.requestdeliveredby,
            NEW.requestcreatedat,
            NEW.requestitempreparedat,
            NEW.requestitempreparedendat,
            NEW.requestdeliveredat,
            NEW.requestdeliveredendat,
            NEW.locationstartedat,
            NEW.locationendat,
            NEW.mobileid,
            NEW.requestdriverhelper,
            NEW.receiver,
            NEW.recipientcontactdetails,
            NEW.requesttripticketnumber,
            NEW.updatedby,
			NEW.recipientname
        );

        RETURN NEW;
    END IF;

    -- UPDATE
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.a_tblrequeststandarddeliveryhistory (
            actiontype,
            changedat,
            requestid,
            itemcategoryid,
            formcategoryid,
            requestclientid,
            requestshippingmethod,
            requestdeliveryterms,
            requestdeliverydate,
            requestpreference,
            requeststatus,
            requestby,
            requestcreatedby,
            requestitempreparedby,
            requestdeliveredby,
            requestcreatedat,
            requestitempreparedat,
            requestitempreparedendat,
            requestdeliveredat,
            requestdeliveredendat,
            locationstartedat,
            locationendat,
            mobileid,
            requestdriverhelper,
            receiver,
            recipientcontactdetails,
            requesttripticketnumber,
            changedby,
			recipientname
        )
        VALUES (
            'UPDATE',
            CURRENT_TIMESTAMP,
            NEW.requestid,
            NEW.itemcategoryid,
            NEW.formcategoryid,
            NEW.requestclientid,
            NEW.requestshippingmethod,
            NEW.requestdeliveryterms,
            NEW.requestdeliverydate,
            NEW.requestpreference,
            NEW.requeststatus,
            NEW.requestby,
            NEW.requestcreatedby,
            NEW.requestitempreparedby,
            NEW.requestdeliveredby,
            NEW.requestcreatedat,
            NEW.requestitempreparedat,
            NEW.requestitempreparedendat,
            NEW.requestdeliveredat,
            NEW.requestdeliveredendat,
            NEW.locationstartedat,
            NEW.locationendat,
            NEW.mobileid,
            NEW.requestdriverhelper,
            NEW.receiver,
            NEW.recipientcontactdetails,
            NEW.requesttripticketnumber,
            NEW.updatedby,
			NEW.recipientname
        );

        RETURN NEW;
    END IF;

    -- DELETE
    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.a_tblrequeststandarddeliveryhistory (
            actiontype,
            changedat,
            requestid,
            itemcategoryid,
            formcategoryid,
            requestclientid,
            requestshippingmethod,
            requestdeliveryterms,
            requestdeliverydate,
            requestpreference,
            requeststatus,
            requestby,
            requestcreatedby,
            requestitempreparedby,
            requestdeliveredby,
            requestcreatedat,
            requestitempreparedat,
            requestitempreparedendat,
            requestdeliveredat,
            requestdeliveredendat,
            locationstartedat,
            locationendat,
            mobileid,
            requestdriverhelper,
            receiver,
            recipientcontactdetails,
            requesttripticketnumber,
            changedby,
			recipientname
        )
        VALUES (
            'DELETE',
            CURRENT_TIMESTAMP,
            OLD.requestid,
            OLD.itemcategoryid,
            OLD.formcategoryid,
            OLD.requestclientid,
            OLD.requestshippingmethod,
            OLD.requestdeliveryterms,
            OLD.requestdeliverydate,
            OLD.requestpreference,
            OLD.requeststatus,
            OLD.requestby,
            OLD.requestcreatedby,
            OLD.requestitempreparedby,
            OLD.requestdeliveredby,
            OLD.requestcreatedat,
            OLD.requestitempreparedat,
            OLD.requestitempreparedendat,
            OLD.requestdeliveredat,
            OLD.requestdeliveredendat,
            OLD.locationstartedat,
            OLD.locationendat,
            OLD.mobileid,
            OLD.requestdriverhelper,
            OLD.receiver,
            OLD.recipientcontactdetails,
            OLD.requesttripticketnumber,
            OLD.updatedby,
			OLD.recipientname
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.trg_requeststandarddelivery_history_fn() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 16394)
-- Name: a_tblbackloadcounters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblbackloadcounters (
    yearmonth character(6) NOT NULL,
    lastnumber integer NOT NULL
);


ALTER TABLE public.a_tblbackloadcounters OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16399)
-- Name: a_tblbatchcounters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblbatchcounters (
    yearmonth character(6) NOT NULL,
    lastnumber integer NOT NULL
);


ALTER TABLE public.a_tblbatchcounters OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16404)
-- Name: a_tblcategory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblcategory (
    id bigint NOT NULL,
    category character varying(20),
    type character varying(25)
);


ALTER TABLE public.a_tblcategory OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16408)
-- Name: a_tblcategory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblcategory ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblcategory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 223 (class 1259 OID 16409)
-- Name: a_tblitemcounters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblitemcounters (
    yearmonth character(6) NOT NULL,
    lastnumber integer NOT NULL
);


ALTER TABLE public.a_tblitemcounters OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16414)
-- Name: a_tblmobile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblmobile (
    mobileid bigint NOT NULL,
    mobilename character varying(50)
);


ALTER TABLE public.a_tblmobile OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16418)
-- Name: a_tblmobile_mobileid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblmobile ALTER COLUMN mobileid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblmobile_mobileid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 226 (class 1259 OID 16419)
-- Name: a_tblrequestairsea; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestairsea (
    requestid bigint NOT NULL,
    clientid character varying(100),
    mobileid bigint,
    itemcategoryid bigint,
    datepickup timestamp without time zone,
    createdby character varying(4),
    receivedby character varying(100),
    itempreparedat timestamp without time zone,
    itempreparedendat timestamp without time zone,
    preparedby character varying(4),
    waybillnumber character varying(25),
    remarks character varying(255),
    status character varying(25),
    tripticketnumber character varying(50),
    driver character varying(25),
    helper character varying(25),
    dispatchedat timestamp without time zone,
    dropoffat timestamp without time zone,
    provincialpickupby character varying(4),
    provincialpickupat timestamp without time zone,
    provincialintransitat timestamp without time zone,
    provincialintransitlocation character varying(100),
    provincialreceivername character varying(100),
    provincialdeliveredendat timestamp without time zone,
    provincialdeliveredlocation character varying(100),
    createdat timestamp without time zone,
    updatedat timestamp without time zone,
    updatedby character varying(4)
);


ALTER TABLE public.a_tblrequestairsea OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16425)
-- Name: a_tblrequestairsea_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestairsea_history (
    historyid bigint NOT NULL,
    changedat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    actiontype character varying(10),
    requestid bigint NOT NULL,
    clientid character varying(100),
    mobileid bigint,
    itemcategoryid bigint,
    datepickup timestamp without time zone,
    createdby character varying(4),
    receivedby character varying(100),
    itempreparedat timestamp without time zone,
    itempreparedendat timestamp without time zone,
    preparedby character varying(4),
    waybillnumber character varying(25),
    remarks character varying(255),
    status character varying(25),
    tripticketnumber character varying(50),
    driver character varying(25),
    helper character varying(25),
    dispatchedat timestamp without time zone,
    dropoffat timestamp without time zone,
    provincialpickupby character varying(4),
    provincialpickupat timestamp without time zone,
    provincialintransitat timestamp without time zone,
    provincialintransitlocation character varying(100),
    provincialreceivername character varying(100),
    provincialdeliveredendat timestamp without time zone,
    provincialdeliveredlocation character varying(100),
    createdat timestamp without time zone,
    updatedat timestamp without time zone,
    changedby character varying(50)
);


ALTER TABLE public.a_tblrequestairsea_history OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16433)
-- Name: a_tblrequestairsea_history_historyid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblrequestairsea_history ALTER COLUMN historyid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblrequestairsea_history_historyid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 229 (class 1259 OID 16434)
-- Name: a_tblrequestbackload; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestbackload (
    backloadid bigint NOT NULL,
    requestid bigint,
    remarks text,
    deliverydate date,
    datereported timestamp without time zone
);


ALTER TABLE public.a_tblrequestbackload OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16440)
-- Name: a_tblrequestcounters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestcounters (
    yearmonth character(6) NOT NULL,
    lastnumber integer NOT NULL
);


ALTER TABLE public.a_tblrequestcounters OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16445)
-- Name: a_tblrequestdocumentreference; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestdocumentreference (
    id bigint NOT NULL,
    requestid bigint NOT NULL,
    reference character varying(100),
    requestcreatedat timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.a_tblrequestdocumentreference OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16451)
-- Name: a_tblrequestdocumentreference_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblrequestdocumentreference ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblrequestdocumentreference_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 233 (class 1259 OID 16452)
-- Name: a_tblrequestimagepath; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestimagepath (
    id bigint NOT NULL,
    requestid bigint,
    imagepath character varying(255),
    imagetype character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.a_tblrequestimagepath OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16457)
-- Name: a_tblrequestimagepath_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblrequestimagepath ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblrequestimagepath_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 235 (class 1259 OID 16458)
-- Name: a_tblrequestpickupmdmpi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestpickupmdmpi (
    requestid bigint NOT NULL,
    clientid character varying(150) NOT NULL,
    itemcategoryid bigint,
    preparedby character varying(4),
    itempreparedat timestamp without time zone,
    itempreparedendat timestamp without time zone,
    datepickup date,
    remarks character varying(255),
    status character varying(50) DEFAULT 'New Request'::character varying,
    releasedby character varying(100),
    receivedby character varying(100),
    createdby character varying(4),
    createdat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updatedat timestamp without time zone,
    updatedby character varying(4)
);


ALTER TABLE public.a_tblrequestpickupmdmpi OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16467)
-- Name: a_tblrequestpickupmdmpi_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestpickupmdmpi_history (
    historyid bigint NOT NULL,
    actiontype character varying(10),
    changedat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    changedby character varying(50),
    requestid bigint,
    clientid character varying(150),
    itemcategoryid bigint,
    preparedby character varying(4),
    itempreparedat timestamp without time zone,
    itempreparedendat timestamp without time zone,
    datepickup date,
    remarks character varying(255),
    status character varying(50),
    releasedby character varying(100),
    receivedby character varying(100),
    createdby character varying(4),
    createdat timestamp without time zone,
    updatedat timestamp without time zone,
    updatedby character varying(4)
);


ALTER TABLE public.a_tblrequestpickupmdmpi_history OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16474)
-- Name: a_tblrequestpickupmdmpi_history_historyid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblrequestpickupmdmpi_history ALTER COLUMN historyid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblrequestpickupmdmpi_history_historyid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 238 (class 1259 OID 16475)
-- Name: a_tblrequestpulloutreturnpickup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestpulloutreturnpickup (
    requestid bigint NOT NULL,
    clientid character varying(100),
    clientcontactperson character varying(100),
    formcategoryid bigint,
    slipno character varying(50),
    irrfnumber character varying(50),
    irrfdate date,
    reasonforreturn character varying(255),
    releasedby character varying(100),
    receivedby character varying(100),
    itemcategoryid bigint,
    pulloutdate date,
    pulloutdatestartat timestamp without time zone,
    pulloutdateendat timestamp without time zone,
    requeststatus character varying(50) DEFAULT 'New Request'::character varying,
    tripticketnumber character varying(50),
    driver character varying(100),
    helper character varying(100),
    mobileid bigint,
    createdat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updatedat timestamp without time zone,
    createdby character varying(4),
    requestedby character varying(4),
    updatedby character varying(4)
);


ALTER TABLE public.a_tblrequestpulloutreturnpickup OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16483)
-- Name: a_tblrequestpulloutreturnpickup_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestpulloutreturnpickup_history (
    historyid bigint NOT NULL,
    actiontype character varying(10),
    changedat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    changedby character varying(50),
    requestid bigint,
    clientid character varying(100),
    clientcontactperson character varying(100),
    formcategoryid bigint,
    slipno character varying(50),
    irrfnumber character varying(50),
    irrfdate date,
    reasonforreturn character varying(255),
    releasedby character varying(100),
    receivedby character varying(100),
    itemcategoryid bigint,
    pulloutdate date,
    pulloutdatestartat timestamp without time zone,
    pulloutdateendat timestamp without time zone,
    requeststatus character varying(50),
    tripticketnumber character varying(50),
    driver character varying(100),
    helper character varying(100),
    mobileid bigint,
    createdat timestamp without time zone,
    updatedat timestamp without time zone,
    createdby character varying(4),
    requestedby character varying(4)
);


ALTER TABLE public.a_tblrequestpulloutreturnpickup_history OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16490)
-- Name: a_tblrequestpulloutreturnpickup_history_historyid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblrequestpulloutreturnpickup_history ALTER COLUMN historyid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblrequestpulloutreturnpickup_history_historyid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 241 (class 1259 OID 16491)
-- Name: a_tblrequestremarks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequestremarks (
    requestid bigint,
    remarks text,
    userupdated character varying(4),
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.a_tblrequestremarks OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16497)
-- Name: a_tblrequeststandarddelivery; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequeststandarddelivery (
    requestid bigint NOT NULL,
    itemcategoryid bigint,
    formcategoryid bigint,
    requestclientid character varying(100),
    requestshippingmethod character varying(15),
    requestdeliveryterms character varying(15),
    requestdeliverydate date,
    requestpreference character varying(15),
    requeststatus character varying(50),
    requestby character varying(4),
    requestcreatedby character varying(4),
    requestitempreparedby character varying(4),
    requestdeliveredby character varying(4),
    requestcreatedat timestamp without time zone,
    requestitempreparedat timestamp without time zone,
    requestitempreparedendat timestamp without time zone,
    requestdeliveredat timestamp without time zone,
    requestdeliveredendat timestamp without time zone,
    locationstartedat character varying(100),
    locationendat character varying(100),
    mobileid bigint,
    requestdriverhelper character varying(25),
    receiver character varying(50),
    recipientcontactdetails character varying(50),
    requesttripticketnumber character varying(50),
    updatedby character varying(4),
    recipientname character varying(100)
);


ALTER TABLE public.a_tblrequeststandarddelivery OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16503)
-- Name: a_tblrequeststandarddeliveryhistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequeststandarddeliveryhistory (
    historyid bigint NOT NULL,
    actiontype character varying(10),
    changedat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    requestid bigint,
    itemcategoryid bigint,
    formcategoryid bigint,
    requestclientid character varying(100),
    requestshippingmethod character varying(15),
    requestdeliveryterms character varying(15),
    requestdeliverydate date,
    requestpreference character varying(15),
    requeststatus character varying(50),
    requestby character varying(4),
    requestcreatedby character varying(4),
    requestitempreparedby character varying(4),
    requestdeliveredby character varying(4),
    requestcreatedat timestamp without time zone,
    requestitempreparedat timestamp without time zone,
    requestitempreparedendat timestamp without time zone,
    requestdeliveredat timestamp without time zone,
    requestdeliveredendat timestamp without time zone,
    locationstartedat character varying(100),
    locationendat character varying(100),
    mobileid bigint,
    requestdriverhelper character varying(25),
    receiver character varying(50),
    recipientcontactdetails character varying(50),
    requesttripticketnumber character varying(50),
    changedby character varying(4),
    recipientname character varying(100)
);


ALTER TABLE public.a_tblrequeststandarddeliveryhistory OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16510)
-- Name: a_tblrequeststandarddeliveryhistory_historyid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.a_tblrequeststandarddeliveryhistory ALTER COLUMN historyid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.a_tblrequeststandarddeliveryhistory_historyid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 245 (class 1259 OID 16511)
-- Name: a_tblrequeststandarditem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequeststandarditem (
    requestitemid bigint,
    requestid bigint NOT NULL,
    itemcode character varying(100),
    description character varying(500),
    qty numeric(18,2),
    unit character varying(50)
);


ALTER TABLE public.a_tblrequeststandarditem OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 16517)
-- Name: a_tblrequeststandarditembatch; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.a_tblrequeststandarditembatch (
    requestitembatchid bigint NOT NULL,
    requestitemid bigint NOT NULL,
    batchserial character varying(200),
    batchquantity numeric(18,2),
    expirydate date
);


ALTER TABLE public.a_tblrequeststandarditembatch OWNER TO postgres;

--
-- TOC entry 4956 (class 2606 OID 16523)
-- Name: a_tblbackloadcounters pk_a_tblbackloadcounters; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblbackloadcounters
    ADD CONSTRAINT pk_a_tblbackloadcounters PRIMARY KEY (yearmonth);


--
-- TOC entry 4958 (class 2606 OID 16525)
-- Name: a_tblbatchcounters pk_a_tblbatchcounters; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblbatchcounters
    ADD CONSTRAINT pk_a_tblbatchcounters PRIMARY KEY (yearmonth);


--
-- TOC entry 4960 (class 2606 OID 16527)
-- Name: a_tblcategory pk_a_tblcategory; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblcategory
    ADD CONSTRAINT pk_a_tblcategory PRIMARY KEY (id);


--
-- TOC entry 4962 (class 2606 OID 16529)
-- Name: a_tblitemcounters pk_a_tblitemcounters; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblitemcounters
    ADD CONSTRAINT pk_a_tblitemcounters PRIMARY KEY (yearmonth);


--
-- TOC entry 4964 (class 2606 OID 16531)
-- Name: a_tblmobile pk_a_tblmobile; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblmobile
    ADD CONSTRAINT pk_a_tblmobile PRIMARY KEY (mobileid);


--
-- TOC entry 4966 (class 2606 OID 16533)
-- Name: a_tblrequestairsea pk_a_tblrequestairsea; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestairsea
    ADD CONSTRAINT pk_a_tblrequestairsea PRIMARY KEY (requestid);


--
-- TOC entry 4968 (class 2606 OID 16535)
-- Name: a_tblrequestairsea_history pk_a_tblrequestairsea_history; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestairsea_history
    ADD CONSTRAINT pk_a_tblrequestairsea_history PRIMARY KEY (historyid);


--
-- TOC entry 4970 (class 2606 OID 16537)
-- Name: a_tblrequestbackload pk_a_tblrequestbackload; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestbackload
    ADD CONSTRAINT pk_a_tblrequestbackload PRIMARY KEY (backloadid);


--
-- TOC entry 4972 (class 2606 OID 16539)
-- Name: a_tblrequestcounters pk_a_tblrequestcounters; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestcounters
    ADD CONSTRAINT pk_a_tblrequestcounters PRIMARY KEY (yearmonth);


--
-- TOC entry 4974 (class 2606 OID 16541)
-- Name: a_tblrequestdocumentreference pk_a_tblrequestdocumentreference; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestdocumentreference
    ADD CONSTRAINT pk_a_tblrequestdocumentreference PRIMARY KEY (id);


--
-- TOC entry 4976 (class 2606 OID 16543)
-- Name: a_tblrequestimagepath pk_a_tblrequestimagepath; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestimagepath
    ADD CONSTRAINT pk_a_tblrequestimagepath PRIMARY KEY (id);


--
-- TOC entry 4978 (class 2606 OID 16545)
-- Name: a_tblrequestpickupmdmpi pk_a_tblrequestpickupmdmpi; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestpickupmdmpi
    ADD CONSTRAINT pk_a_tblrequestpickupmdmpi PRIMARY KEY (requestid);


--
-- TOC entry 4980 (class 2606 OID 16547)
-- Name: a_tblrequestpickupmdmpi_history pk_a_tblrequestpickupmdmpi_history; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestpickupmdmpi_history
    ADD CONSTRAINT pk_a_tblrequestpickupmdmpi_history PRIMARY KEY (historyid);


--
-- TOC entry 4982 (class 2606 OID 16549)
-- Name: a_tblrequestpulloutreturnpickup pk_a_tblrequestpulloutreturnpickup; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestpulloutreturnpickup
    ADD CONSTRAINT pk_a_tblrequestpulloutreturnpickup PRIMARY KEY (requestid);


--
-- TOC entry 4984 (class 2606 OID 16551)
-- Name: a_tblrequestpulloutreturnpickup_history pk_a_tblrequestpulloutreturnpickup_history; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequestpulloutreturnpickup_history
    ADD CONSTRAINT pk_a_tblrequestpulloutreturnpickup_history PRIMARY KEY (historyid);


--
-- TOC entry 4986 (class 2606 OID 16553)
-- Name: a_tblrequeststandarddelivery pk_a_tblrequeststandarddelivery; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequeststandarddelivery
    ADD CONSTRAINT pk_a_tblrequeststandarddelivery PRIMARY KEY (requestid);


--
-- TOC entry 4988 (class 2606 OID 16555)
-- Name: a_tblrequeststandarddeliveryhistory pk_a_tblrequeststandarddeliveryhistory; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.a_tblrequeststandarddeliveryhistory
    ADD CONSTRAINT pk_a_tblrequeststandarddeliveryhistory PRIMARY KEY (historyid);


--
-- TOC entry 4989 (class 2620 OID 16556)
-- Name: a_tblrequestairsea trg_a_tblrequestairsea_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_a_tblrequestairsea_history AFTER INSERT OR UPDATE ON public.a_tblrequestairsea FOR EACH ROW EXECUTE FUNCTION public.trg_a_tblrequestairsea_history_fn();


--
-- TOC entry 4991 (class 2620 OID 16557)
-- Name: a_tblrequestpickupmdmpi trg_a_tblrequestpickupmdmpi_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_a_tblrequestpickupmdmpi_history AFTER INSERT OR DELETE OR UPDATE ON public.a_tblrequestpickupmdmpi FOR EACH ROW EXECUTE FUNCTION public.trg_a_tblrequestpickupmdmpi_history_fn();


--
-- TOC entry 4992 (class 2620 OID 16558)
-- Name: a_tblrequestpulloutreturnpickup trg_a_tblrequestpulloutreturnpickup_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_a_tblrequestpulloutreturnpickup_history AFTER INSERT OR DELETE OR UPDATE ON public.a_tblrequestpulloutreturnpickup FOR EACH ROW EXECUTE FUNCTION public.trg_a_tblrequestpulloutreturnpickup_history_fn();


--
-- TOC entry 4990 (class 2620 OID 16559)
-- Name: a_tblrequestbackload trg_backload_resetstandarddelivery; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_backload_resetstandarddelivery AFTER INSERT ON public.a_tblrequestbackload FOR EACH ROW EXECUTE FUNCTION public.trg_backload_resetstandarddelivery_fn();


--
-- TOC entry 4993 (class 2620 OID 16560)
-- Name: a_tblrequeststandarddelivery trg_requeststandarddelivery_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_requeststandarddelivery_history AFTER INSERT OR DELETE OR UPDATE ON public.a_tblrequeststandarddelivery FOR EACH ROW EXECUTE FUNCTION public.trg_requeststandarddelivery_history_fn();


-- Completed on 2026-08-28 08:56:08

--
-- PostgreSQL database dump complete
--

\unrestrict wg67uZkvB4dYZWUrbJRdxslu7E86VR5CJrDP5x7hiS5lSF6YXGsqNXRvpsXQXen

