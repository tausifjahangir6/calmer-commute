--
-- PostgreSQL database dump
--

\restrict EcNEQnl2xxOLQRlOWmhmPGJdjVzQe10FQHVeuiCYSGTWArRF164rCBxEdRUSKnQ

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

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
-- Name: serving; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA serving;


--
-- Name: SCHEMA serving; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA serving IS 'Compact application schema for Supabase. Source: City of Melbourne Open
     Data (CC BY 4.0). Rebuilt from hush by sql/16_serving_layer.sql.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: density_band; Type: TABLE; Schema: serving; Owner: -
--

CREATE TABLE serving.density_band (
    band_name text NOT NULL,
    min_count integer,
    max_count integer
);


--
-- Name: hourly_profile; Type: TABLE; Schema: serving; Owner: -
--

CREATE TABLE serving.hourly_profile (
    location_id integer NOT NULL,
    display_name text,
    hour_day smallint NOT NULL,
    observations bigint,
    avg_count integer,
    median_count integer,
    min_count integer,
    max_count integer
);


--
-- Name: minute_count; Type: TABLE; Schema: serving; Owner: -
--

CREATE TABLE serving.minute_count (
    location_id integer NOT NULL,
    sensing_datetime timestamp with time zone NOT NULL,
    direction_1 integer,
    direction_2 integer,
    total_of_direction integer NOT NULL
);


--
-- Name: refuge; Type: TABLE; Schema: serving; Owner: -
--

CREATE TABLE serving.refuge (
    location_id integer NOT NULL,
    landmark_id integer NOT NULL,
    feature_name text,
    theme_name text,
    sub_theme text,
    sensory_load text,
    latitude numeric(9,6),
    longitude numeric(9,6),
    walk_m numeric(10,2),
    walk_minutes numeric(5,1),
    straight_m numeric(10,2),
    detour_ratio numeric(6,2),
    distance_reliable boolean
);


--
-- Name: sensor; Type: TABLE; Schema: serving; Owner: -
--

CREATE TABLE serving.sensor (
    location_id integer NOT NULL,
    display_name text,
    device_code text,
    latitude numeric(9,6),
    longitude numeric(9,6),
    is_cbd boolean,
    is_active boolean,
    direction_1 text,
    direction_2 text
);


--
-- Name: sensor_network; Type: TABLE; Schema: serving; Owner: -
--

CREATE TABLE serving.sensor_network (
    location_id integer NOT NULL,
    walkable_m_within_400m numeric(12,2),
    nodes_within_400m integer,
    node_degree integer,
    low_sensory_within_800m integer,
    nearest_low_sensory_m numeric(10,2),
    network_snap_reliable boolean
);


--
-- Name: v_current_density; Type: VIEW; Schema: serving; Owner: -
--

CREATE VIEW serving.v_current_density AS
 SELECT DISTINCT ON (m.location_id) s.location_id,
    s.display_name,
    s.latitude,
    s.longitude,
    m.sensing_datetime,
    m.total_of_direction AS people_per_minute,
    b.band_name AS density_level,
    (round((EXTRACT(epoch FROM (now() - m.sensing_datetime)) / (60)::numeric)))::integer AS data_age_minutes
   FROM ((serving.minute_count m
     JOIN serving.sensor s ON ((s.location_id = m.location_id)))
     JOIN serving.density_band b ON (((m.total_of_direction >= b.min_count) AND ((b.max_count IS NULL) OR (m.total_of_direction <= b.max_count)))))
  WHERE s.is_active
  ORDER BY m.location_id, m.sensing_datetime DESC;


--
-- Data for Name: density_band; Type: TABLE DATA; Schema: serving; Owner: -
--

COPY serving.density_band (band_name, min_count, max_count) FROM stdin;
Low	0	50
Medium	51	150
High	151	\N
\.


--
-- Data for Name: hourly_profile; Type: TABLE DATA; Schema: serving; Owner: -
--

COPY serving.hourly_profile (location_id, display_name, hour_day, observations, avg_count, median_count, min_count, max_count) FROM stdin;
1	Bourke Street Mall (North)	0	488	88	59	5	855
1	Bourke Street Mall (North)	1	488	53	35	4	545
1	Bourke Street Mall (North)	2	486	35	26	5	390
1	Bourke Street Mall (North)	3	488	24	16	2	123
1	Bourke Street Mall (North)	4	487	17	13	1	130
1	Bourke Street Mall (North)	5	487	17	16	3	60
1	Bourke Street Mall (North)	6	487	65	70	1	219
1	Bourke Street Mall (North)	7	486	151	166	30	740
1	Bourke Street Mall (North)	8	486	376	410	84	2022
1	Bourke Street Mall (North)	9	487	651	637	238	1824
1	Bourke Street Mall (North)	10	487	1071	1018	400	2613
1	Bourke Street Mall (North)	11	487	1705	1648	658	3213
1	Bourke Street Mall (North)	12	487	2458	2440	1038	3806
1	Bourke Street Mall (North)	13	487	2680	2625	1118	4398
1	Bourke Street Mall (North)	14	487	2488	2364	1083	4620
1	Bourke Street Mall (North)	15	486	2454	2340	1266	4550
1	Bourke Street Mall (North)	16	487	2401	2317	1256	4333
1	Bourke Street Mall (North)	17	487	2397	2391	944	4210
1	Bourke Street Mall (North)	18	488	1843	1810	366	3966
1	Bourke Street Mall (North)	19	488	1303	1176	61	3551
1	Bourke Street Mall (North)	20	487	871	725	11	2977
1	Bourke Street Mall (North)	21	487	560	486	14	2138
1	Bourke Street Mall (North)	22	488	317	249	4	1516
1	Bourke Street Mall (North)	23	486	181	121	6	1084
2	Bourke Street Mall (South)	0	729	73	49	6	775
2	Bourke Street Mall (South)	1	728	47	27	1	534
2	Bourke Street Mall (South)	2	727	36	23	1	262
2	Bourke Street Mall (South)	3	729	26	16	2	161
2	Bourke Street Mall (South)	4	727	13	11	1	69
2	Bourke Street Mall (South)	5	728	17	16	2	87
2	Bourke Street Mall (South)	6	728	46	47	5	198
2	Bourke Street Mall (South)	7	728	105	112	22	425
2	Bourke Street Mall (South)	8	728	267	291	51	1095
2	Bourke Street Mall (South)	9	728	424	420	149	928
2	Bourke Street Mall (South)	10	729	709	666	64	2416
2	Bourke Street Mall (South)	11	728	1105	1037	340	2938
2	Bourke Street Mall (South)	12	728	1649	1590	457	3799
2	Bourke Street Mall (South)	13	728	1769	1711	395	3997
2	Bourke Street Mall (South)	14	728	1559	1461	456	3744
2	Bourke Street Mall (South)	15	728	1500	1392	425	3857
2	Bourke Street Mall (South)	16	728	1423	1324	400	3800
2	Bourke Street Mall (South)	17	728	1331	1275	311	3564
2	Bourke Street Mall (South)	18	728	980	910	317	3104
2	Bourke Street Mall (South)	19	728	671	561	228	3071
2	Bourke Street Mall (South)	20	728	527	414	131	3270
2	Bourke Street Mall (South)	21	728	360	286	94	3241
2	Bourke Street Mall (South)	22	728	225	176	43	1622
2	Bourke Street Mall (South)	23	728	131	91	19	816
3	Melbourne Central	0	730	358	229	32	3540
3	Melbourne Central	1	730	217	133	37	4805
3	Melbourne Central	2	728	134	80	15	1597
3	Melbourne Central	3	730	95	51	7	680
3	Melbourne Central	4	729	58	38	6	389
3	Melbourne Central	5	729	50	44	8	200
3	Melbourne Central	6	729	88	88	3	195
3	Melbourne Central	7	729	172	180	32	371
3	Melbourne Central	8	729	391	409	74	909
3	Melbourne Central	9	729	549	548	114	1126
3	Melbourne Central	10	729	839	824	166	2632
3	Melbourne Central	11	729	1316	1305	245	3039
3	Melbourne Central	12	729	2069	2055	490	4894
3	Melbourne Central	13	729	2246	2202	502	4475
3	Melbourne Central	14	729	2214	2136	589	4677
3	Melbourne Central	15	729	2258	2199	651	4353
3	Melbourne Central	16	729	2294	2252	506	4152
3	Melbourne Central	17	729	2414	2406	819	4101
3	Melbourne Central	18	729	2289	2261	654	4017
3	Melbourne Central	19	729	2042	1972	408	3966
3	Melbourne Central	20	729	1788	1709	504	3589
3	Melbourne Central	21	729	1499	1402	600	3397
3	Melbourne Central	22	729	1035	878	303	4410
3	Melbourne Central	23	729	664	500	141	2227
4	Town Hall (West)	0	727	342	196	19	6217
4	Town Hall (West)	1	727	188	88	13	4215
4	Town Hall (West)	2	725	110	47	6	1541
4	Town Hall (West)	3	727	73	35	5	756
4	Town Hall (West)	4	726	51	38	9	381
4	Town Hall (West)	5	726	68	66	23	270
4	Town Hall (West)	6	726	163	164	44	366
4	Town Hall (West)	7	726	348	366	77	987
4	Town Hall (West)	8	726	760	810	192	1624
4	Town Hall (West)	9	726	1069	1080	182	1747
4	Town Hall (West)	10	725	1607	1577	810	4552
4	Town Hall (West)	11	725	2329	2268	1014	3852
4	Town Hall (West)	12	725	3227	3217	1707	5211
4	Town Hall (West)	13	725	3431	3384	1615	5339
4	Town Hall (West)	14	725	3181	3075	1333	5591
4	Town Hall (West)	15	725	3120	3045	1333	5473
4	Town Hall (West)	16	725	3119	3097	1424	5159
4	Town Hall (West)	17	725	3198	3220	1379	5271
4	Town Hall (West)	18	726	2660	2577	1161	5204
4	Town Hall (West)	19	726	2159	1978	825	4583
4	Town Hall (West)	20	726	1801	1613	560	4702
4	Town Hall (West)	21	726	1543	1328	388	6193
4	Town Hall (West)	22	726	1144	922	63	4806
4	Town Hall (West)	23	726	686	486	35	3785
5	Princes Bridge	0	730	229	126	1	2926
5	Princes Bridge	1	728	110	60	1	2724
5	Princes Bridge	2	727	61	37	2	1398
5	Princes Bridge	3	729	51	37	3	730
5	Princes Bridge	4	726	40	37	3	315
5	Princes Bridge	5	728	76	75	8	390
5	Princes Bridge	6	729	216	234	26	1845
5	Princes Bridge	7	729	427	478	30	1740
5	Princes Bridge	8	728	824	908	70	2830
5	Princes Bridge	9	728	884	901	109	3551
5	Princes Bridge	10	728	1153	1126	120	4100
5	Princes Bridge	11	729	1510	1491	102	4224
5	Princes Bridge	12	729	1910	1892	55	4187
5	Princes Bridge	13	729	2036	1949	59	4398
5	Princes Bridge	14	729	1948	1845	113	4569
5	Princes Bridge	15	729	1996	1889	142	4171
5	Princes Bridge	16	729	2119	2053	146	4673
5	Princes Bridge	17	729	2385	2399	189	6267
5	Princes Bridge	18	729	2015	1920	101	7381
5	Princes Bridge	19	729	1647	1477	94	6111
5	Princes Bridge	20	729	1360	1167	107	5812
5	Princes Bridge	21	729	1452	1158	11	6270
5	Princes Bridge	22	729	1150	854	5	5525
5	Princes Bridge	23	728	586	352	1	4036
6	Flinders Underpass - Myki Barriers	0	730	82	44	10	517
6	Flinders Underpass - Myki Barriers	1	688	32	7	1	715
6	Flinders Underpass - Myki Barriers	2	662	25	5	1	1710
6	Flinders Underpass - Myki Barriers	3	718	17	7	1	903
6	Flinders Underpass - Myki Barriers	4	729	30	28	8	375
6	Flinders Underpass - Myki Barriers	5	729	92	99	5	221
6	Flinders Underpass - Myki Barriers	6	729	263	314	7	478
6	Flinders Underpass - Myki Barriers	7	729	515	601	45	1002
6	Flinders Underpass - Myki Barriers	8	729	1266	1558	89	2495
6	Flinders Underpass - Myki Barriers	9	729	579	616	127	1134
6	Flinders Underpass - Myki Barriers	10	729	278	269	125	533
6	Flinders Underpass - Myki Barriers	11	729	315	296	129	733
6	Flinders Underpass - Myki Barriers	12	729	340	313	144	895
6	Flinders Underpass - Myki Barriers	13	729	361	344	162	870
6	Flinders Underpass - Myki Barriers	14	729	455	443	190	867
6	Flinders Underpass - Myki Barriers	15	729	597	602	250	944
6	Flinders Underpass - Myki Barriers	16	729	952	1016	206	1620
6	Flinders Underpass - Myki Barriers	17	729	1369	1600	210	2917
6	Flinders Underpass - Myki Barriers	18	729	678	689	201	1348
6	Flinders Underpass - Myki Barriers	19	729	376	355	155	996
6	Flinders Underpass - Myki Barriers	20	729	294	270	8	1228
6	Flinders Underpass - Myki Barriers	21	729	281	248	20	1653
6	Flinders Underpass - Myki Barriers	22	729	274	228	30	2805
6	Flinders Underpass - Myki Barriers	23	729	187	146	43	3203
8	Webb Bridge	0	610	9	5	1	478
8	Webb Bridge	1	492	4	3	1	170
8	Webb Bridge	2	399	3	2	1	140
8	Webb Bridge	3	338	2	1	1	83
8	Webb Bridge	4	395	2	2	1	17
8	Webb Bridge	5	632	10	7	1	46
8	Webb Bridge	6	703	61	46	1	199
8	Webb Bridge	7	729	222	217	18	7508
8	Webb Bridge	8	729	352	373	46	4725
8	Webb Bridge	9	729	308	315	31	610
8	Webb Bridge	10	729	302	295	41	1086
8	Webb Bridge	11	729	346	341	37	1032
8	Webb Bridge	12	729	558	570	43	1219
8	Webb Bridge	13	729	499	508	45	1081
8	Webb Bridge	14	729	407	399	71	1142
8	Webb Bridge	15	729	419	411	72	980
8	Webb Bridge	16	729	476	489	69	999
8	Webb Bridge	17	729	489	495	16	1005
8	Webb Bridge	18	728	257	276	2	793
8	Webb Bridge	19	724	144	135	1	797
8	Webb Bridge	20	723	98	66	1	1273
8	Webb Bridge	21	716	51	40	1	798
8	Webb Bridge	22	710	34	24	1	541
8	Webb Bridge	23	681	25	12	1	684
9	Southern Cross Station	0	730	34	19	1	4513
9	Southern Cross Station	1	726	15	10	1	1037
9	Southern Cross Station	2	718	9	8	1	154
9	Southern Cross Station	3	702	7	5	1	45
9	Southern Cross Station	4	726	7	7	1	40
9	Southern Cross Station	5	729	40	46	2	93
9	Southern Cross Station	6	729	220	269	8	601
9	Southern Cross Station	7	729	758	904	16	1653
9	Southern Cross Station	8	728	1937	2284	23	4080
9	Southern Cross Station	9	728	1218	1411	39	2576
9	Southern Cross Station	10	729	496	557	51	2382
9	Southern Cross Station	11	729	450	508	38	1864
9	Southern Cross Station	12	729	877	1059	25	1729
9	Southern Cross Station	13	729	674	775	53	1663
9	Southern Cross Station	14	729	551	637	57	1464
9	Southern Cross Station	15	729	758	922	57	1500
9	Southern Cross Station	16	729	1526	1848	51	3396
9	Southern Cross Station	17	729	1745	2007	52	3915
9	Southern Cross Station	18	729	629	676	54	1865
9	Southern Cross Station	19	729	246	234	36	1521
9	Southern Cross Station	20	729	144	132	29	1817
9	Southern Cross Station	21	729	109	95	30	3176
9	Southern Cross Station	22	729	110	81	18	3056
9	Southern Cross Station	23	729	88	39	7	3072
10	Victoria Point	0	724	21	7	1	5137
10	Victoria Point	1	605	8	4	1	1191
10	Victoria Point	2	526	5	3	1	173
10	Victoria Point	3	538	4	2	1	37
10	Victoria Point	4	590	3	2	1	34
10	Victoria Point	5	707	7	7	1	37
10	Victoria Point	6	718	28	29	1	257
10	Victoria Point	7	729	86	96	3	1254
10	Victoria Point	8	729	153	179	10	743
10	Victoria Point	9	729	130	141	9	1387
10	Victoria Point	10	729	106	103	26	2150
10	Victoria Point	11	728	129	132	18	1129
10	Victoria Point	12	729	232	260	6	490
10	Victoria Point	13	728	178	192	24	579
10	Victoria Point	14	728	128	132	27	406
10	Victoria Point	15	729	147	153	32	352
10	Victoria Point	16	729	193	208	24	429
10	Victoria Point	17	729	205	208	29	1123
10	Victoria Point	18	729	156	136	38	1083
10	Victoria Point	19	729	117	96	19	1527
10	Victoria Point	20	729	88	74	18	1381
10	Victoria Point	21	729	70	50	7	2933
10	Victoria Point	22	729	66	27	1	2199
10	Victoria Point	23	727	50	15	1	1858
11	Docklands Waterfront City Building Side	0	728	30	17	1	3505
11	Docklands Waterfront City Building Side	1	694	12	7	1	1112
11	Docklands Waterfront City Building Side	2	621	6	4	1	309
11	Docklands Waterfront City Building Side	3	527	4	3	1	54
11	Docklands Waterfront City Building Side	4	606	3	2	1	26
11	Docklands Waterfront City Building Side	5	682	8	6	1	32
11	Docklands Waterfront City Building Side	6	728	36	34	1	399
11	Docklands Waterfront City Building Side	7	729	99	82	4	10101
11	Docklands Waterfront City Building Side	8	729	122	120	5	447
11	Docklands Waterfront City Building Side	9	729	123	115	5	839
11	Docklands Waterfront City Building Side	10	729	138	119	2	1145
11	Docklands Waterfront City Building Side	11	729	164	138	2	2279
11	Docklands Waterfront City Building Side	12	729	229	217	2	2674
11	Docklands Waterfront City Building Side	13	729	214	197	6	2828
11	Docklands Waterfront City Building Side	14	729	185	148	3	2587
11	Docklands Waterfront City Building Side	15	729	185	147	7	2076
11	Docklands Waterfront City Building Side	16	729	207	176	10	1772
11	Docklands Waterfront City Building Side	17	729	256	235	9	3035
11	Docklands Waterfront City Building Side	18	729	260	243	9	2888
11	Docklands Waterfront City Building Side	19	729	256	226	1	2796
11	Docklands Waterfront City Building Side	20	728	250	193	2	4152
11	Docklands Waterfront City Building Side	21	729	173	128	2	4141
11	Docklands Waterfront City Building Side	22	728	112	78	3	4931
11	Docklands Waterfront City Building Side	23	728	62	36	1	5312
12	New Quay	0	706	36	16	1	5355
12	New Quay	1	646	15	8	1	1605
12	New Quay	2	588	8	5	1	551
12	New Quay	3	521	6	3	1	151
12	New Quay	4	532	6	3	1	323
12	New Quay	5	637	12	7	1	347
12	New Quay	6	713	48	42	1	369
12	New Quay	7	729	149	134	8	4235
12	New Quay	8	727	223	223	6	2963
12	New Quay	9	727	220	214	5	928
12	New Quay	10	729	234	211	10	1405
12	New Quay	11	729	272	240	6	2220
12	New Quay	12	727	379	359	9	2853
12	New Quay	13	727	364	340	9	2827
12	New Quay	14	727	323	274	9	2716
12	New Quay	15	729	323	278	4	2290
12	New Quay	16	729	379	333	9	2044
12	New Quay	17	729	444	422	3	2225
12	New Quay	18	729	429	421	1	2069
12	New Quay	19	729	380	377	3	3342
12	New Quay	20	728	316	254	1	4923
12	New Quay	21	729	210	140	2	4951
12	New Quay	22	727	156	85	1	6096
12	New Quay	23	723	93	40	1	6598
14	Sandridge Bridge	0	651	83	44	1	881
14	Sandridge Bridge	1	615	42	18	1	353
14	Sandridge Bridge	2	569	28	11	1	987
14	Sandridge Bridge	3	556	18	8	1	695
14	Sandridge Bridge	4	591	21	18	1	360
14	Sandridge Bridge	5	616	41	40	1	167
14	Sandridge Bridge	6	657	115	84	1	430
14	Sandridge Bridge	7	700	241	242	1	803
14	Sandridge Bridge	8	703	578	633	2	1571
14	Sandridge Bridge	9	703	381	388	2	1260
14	Sandridge Bridge	10	703	344	337	14	832
14	Sandridge Bridge	11	704	401	390	3	1258
14	Sandridge Bridge	12	707	474	470	2	1311
14	Sandridge Bridge	13	707	487	480	5	1403
14	Sandridge Bridge	14	706	495	484	15	1598
14	Sandridge Bridge	15	705	563	553	17	1553
14	Sandridge Bridge	16	705	726	747	5	1740
14	Sandridge Bridge	17	704	834	832	5	2145
14	Sandridge Bridge	18	697	484	563	1	1604
14	Sandridge Bridge	19	697	344	371	1	1451
14	Sandridge Bridge	20	688	312	305	1	1628
14	Sandridge Bridge	21	687	362	263	1	4246
14	Sandridge Bridge	22	688	311	197	1	4258
14	Sandridge Bridge	23	677	191	128	1	2983
17	Collins Place (South)	0	729	36	26	2	1261
17	Collins Place (South)	1	729	17	13	1	363
17	Collins Place (South)	2	720	11	9	1	65
17	Collins Place (South)	3	725	10	9	1	42
17	Collins Place (South)	4	727	16	15	1	41
17	Collins Place (South)	5	729	53	59	2	119
17	Collins Place (South)	6	729	129	148	10	276
17	Collins Place (South)	7	729	348	414	22	792
17	Collins Place (South)	8	729	982	1177	53	2016
17	Collins Place (South)	9	729	682	784	55	1449
17	Collins Place (South)	10	729	503	554	79	1828
17	Collins Place (South)	11	729	525	576	50	1049
17	Collins Place (South)	12	729	980	1124	74	1958
17	Collins Place (South)	13	729	939	1080	56	1942
17	Collins Place (South)	14	729	577	630	125	1112
17	Collins Place (South)	15	729	523	552	90	1084
17	Collins Place (South)	16	729	524	564	114	950
17	Collins Place (South)	17	729	739	806	102	1435
17	Collins Place (South)	18	729	431	441	58	1023
17	Collins Place (South)	19	729	253	245	64	712
17	Collins Place (South)	20	729	217	208	54	1137
17	Collins Place (South)	21	729	168	160	46	1513
17	Collins Place (South)	22	729	158	137	26	949
17	Collins Place (South)	23	729	84	69	12	1069
18	Collins Place (North)	0	630	8	4	1	333
18	Collins Place (North)	1	563	4	3	1	136
18	Collins Place (North)	2	470	3	2	1	26
18	Collins Place (North)	3	422	3	2	1	33
18	Collins Place (North)	4	475	2	2	1	14
18	Collins Place (North)	5	661	9	8	1	33
18	Collins Place (North)	6	708	51	42	1	154
18	Collins Place (North)	7	725	245	295	3	546
18	Collins Place (North)	8	725	840	1018	7	1702
18	Collins Place (North)	9	725	512	619	14	1166
18	Collins Place (North)	10	724	315	359	14	1195
18	Collins Place (North)	11	724	302	342	31	758
18	Collins Place (North)	12	725	388	441	29	1327
18	Collins Place (North)	13	725	393	441	20	1101
18	Collins Place (North)	14	725	325	364	38	620
18	Collins Place (North)	15	725	337	390	28	631
18	Collins Place (North)	16	725	445	528	31	827
18	Collins Place (North)	17	724	569	567	20	1345
18	Collins Place (North)	18	721	216	157	1	583
18	Collins Place (North)	19	711	87	69	1	351
18	Collins Place (North)	20	708	44	38	1	421
18	Collins Place (North)	21	711	33	29	1	361
18	Collins Place (North)	22	708	28	22	1	182
18	Collins Place (North)	23	694	16	11	1	205
19	Chinatown-Swanston St (North)	0	714	235	160	47	837
19	Chinatown-Swanston St (North)	1	714	146	93	20	817
19	Chinatown-Swanston St (North)	2	712	78	48	6	475
19	Chinatown-Swanston St (North)	3	714	49	30	2	265
19	Chinatown-Swanston St (North)	4	712	24	15	1	166
19	Chinatown-Swanston St (North)	5	712	14	12	1	119
19	Chinatown-Swanston St (North)	6	713	23	23	3	51
19	Chinatown-Swanston St (North)	7	713	42	42	8	144
19	Chinatown-Swanston St (North)	8	713	95	100	32	183
19	Chinatown-Swanston St (North)	9	713	166	166	59	465
19	Chinatown-Swanston St (North)	10	712	322	319	185	1179
19	Chinatown-Swanston St (North)	11	713	569	554	359	1628
19	Chinatown-Swanston St (North)	12	713	959	943	520	1962
19	Chinatown-Swanston St (North)	13	714	1046	999	131	1872
19	Chinatown-Swanston St (North)	14	714	983	920	461	1850
19	Chinatown-Swanston St (North)	15	714	940	892	535	1648
19	Chinatown-Swanston St (North)	16	713	942	891	506	1561
19	Chinatown-Swanston St (North)	17	713	1106	1078	615	1794
19	Chinatown-Swanston St (North)	18	713	1241	1212	650	1975
19	Chinatown-Swanston St (North)	19	713	1219	1161	645	2050
19	Chinatown-Swanston St (North)	20	713	1073	1018	463	1800
19	Chinatown-Swanston St (North)	21	713	894	826	404	1686
19	Chinatown-Swanston St (North)	22	713	622	499	214	1435
19	Chinatown-Swanston St (North)	23	713	388	285	98	1083
20	Chinatown-Lt Bourke St (South)	0	728	230	77	6	1284
20	Chinatown-Lt Bourke St (South)	1	728	140	43	1	1060
20	Chinatown-Lt Bourke St (South)	2	727	88	25	1	542
20	Chinatown-Lt Bourke St (South)	3	729	66	18	1	411
20	Chinatown-Lt Bourke St (South)	4	727	37	16	1	235
20	Chinatown-Lt Bourke St (South)	5	726	19	12	1	186
20	Chinatown-Lt Bourke St (South)	6	729	23	21	5	125
20	Chinatown-Lt Bourke St (South)	7	729	50	49	12	127
20	Chinatown-Lt Bourke St (South)	8	729	99	100	24	264
20	Chinatown-Lt Bourke St (South)	9	729	124	120	39	652
20	Chinatown-Lt Bourke St (South)	10	729	209	205	54	1139
20	Chinatown-Lt Bourke St (South)	11	729	346	335	85	1819
20	Chinatown-Lt Bourke St (South)	12	729	589	586	156	1912
20	Chinatown-Lt Bourke St (South)	13	729	593	567	158	1717
20	Chinatown-Lt Bourke St (South)	14	729	475	439	134	1226
20	Chinatown-Lt Bourke St (South)	15	729	457	423	138	1062
20	Chinatown-Lt Bourke St (South)	16	729	461	426	124	1308
20	Chinatown-Lt Bourke St (South)	17	729	639	620	172	1241
20	Chinatown-Lt Bourke St (South)	18	729	821	785	231	1667
20	Chinatown-Lt Bourke St (South)	19	729	856	767	237	1957
20	Chinatown-Lt Bourke St (South)	20	729	717	636	228	1723
20	Chinatown-Lt Bourke St (South)	21	729	620	579	191	1404
20	Chinatown-Lt Bourke St (South)	22	729	480	328	93	1550
20	Chinatown-Lt Bourke St (South)	23	728	325	160	33	1554
21	155-161 Russell Street	0	728	180	95	16	1393
21	155-161 Russell Street	1	728	119	56	7	946
21	155-161 Russell Street	2	726	70	31	1	470
21	155-161 Russell Street	3	727	52	20	1	356
21	155-161 Russell Street	4	721	23	12	1	145
21	155-161 Russell Street	5	727	16	13	1	159
21	155-161 Russell Street	6	727	31	31	9	75
21	155-161 Russell Street	7	727	65	67	16	150
21	155-161 Russell Street	8	728	137	144	14	282
21	155-161 Russell Street	9	728	181	178	49	397
21	155-161 Russell Street	10	728	286	280	75	907
21	155-161 Russell Street	11	728	475	465	121	1566
21	155-161 Russell Street	12	728	875	867	209	1999
21	155-161 Russell Street	13	728	903	884	255	2318
21	155-161 Russell Street	14	728	747	719	304	2065
21	155-161 Russell Street	15	728	703	659	263	1852
21	155-161 Russell Street	16	728	718	680	209	1627
21	155-161 Russell Street	17	728	810	778	213	1667
21	155-161 Russell Street	18	728	800	752	315	1842
21	155-161 Russell Street	19	728	758	718	255	1904
21	155-161 Russell Street	20	728	637	587	121	1569
21	155-161 Russell Street	21	728	502	442	72	1451
21	155-161 Russell Street	22	728	392	310	79	1204
21	155-161 Russell Street	23	728	266	182	45	1139
23	Spencer St-Collins St (South)	0	730	57	43	8	1117
23	Spencer St-Collins St (South)	1	730	31	20	1	711
23	Spencer St-Collins St (South)	2	727	19	12	1	160
23	Spencer St-Collins St (South)	3	729	16	13	1	92
23	Spencer St-Collins St (South)	4	729	13	10	1	75
23	Spencer St-Collins St (South)	5	729	36	36	6	112
23	Spencer St-Collins St (South)	6	729	131	152	21	488
23	Spencer St-Collins St (South)	7	729	349	399	19	941
23	Spencer St-Collins St (South)	8	729	820	918	4	2115
23	Spencer St-Collins St (South)	9	729	571	583	6	1266
23	Spencer St-Collins St (South)	10	729	420	423	7	1179
23	Spencer St-Collins St (South)	11	729	447	444	5	1149
23	Spencer St-Collins St (South)	12	729	770	828	9	1497
23	Spencer St-Collins St (South)	13	729	656	702	8	1306
23	Spencer St-Collins St (South)	14	729	463	467	25	883
23	Spencer St-Collins St (South)	15	729	476	490	13	911
23	Spencer St-Collins St (South)	16	729	648	685	3	1202
23	Spencer St-Collins St (South)	17	729	850	922	103	1648
23	Spencer St-Collins St (South)	18	728	495	508	79	1308
23	Spencer St-Collins St (South)	19	728	333	328	65	863
23	Spencer St-Collins St (South)	20	729	263	256	36	667
23	Spencer St-Collins St (South)	21	729	224	215	59	703
23	Spencer St-Collins St (South)	22	729	176	151	44	965
23	Spencer St-Collins St (South)	23	729	115	88	27	882
24	Spencer St-Collins St (North)	0	727	189	131	37	1800
24	Spencer St-Collins St (North)	1	726	93	52	8	1622
24	Spencer St-Collins St (North)	2	723	54	36	9	681
24	Spencer St-Collins St (North)	3	725	45	34	1	292
24	Spencer St-Collins St (North)	4	724	40	34	7	253
24	Spencer St-Collins St (North)	5	724	132	141	2	243
24	Spencer St-Collins St (North)	6	724	402	471	16	775
24	Spencer St-Collins St (North)	7	724	915	1058	5	1898
24	Spencer St-Collins St (North)	8	725	1754	2077	12	3626
24	Spencer St-Collins St (North)	9	725	1288	1400	10	2456
24	Spencer St-Collins St (North)	10	725	1054	1047	13	2856
24	Spencer St-Collins St (North)	11	725	1107	1095	4	2246
24	Spencer St-Collins St (North)	12	725	1356	1390	3	2191
24	Spencer St-Collins St (North)	13	725	1322	1368	7	2126
24	Spencer St-Collins St (North)	14	725	1264	1287	17	1995
24	Spencer St-Collins St (North)	15	725	1504	1569	23	2286
24	Spencer St-Collins St (North)	16	725	1997	2141	51	3398
24	Spencer St-Collins St (North)	17	725	2304	2600	759	3923
24	Spencer St-Collins St (North)	18	726	1445	1495	35	2632
24	Spencer St-Collins St (North)	19	726	930	904	485	2352
24	Spencer St-Collins St (North)	20	726	705	688	423	1630
24	Spencer St-Collins St (North)	21	726	677	658	52	1442
24	Spencer St-Collins St (North)	22	726	607	548	71	1776
24	Spencer St-Collins St (North)	23	726	419	332	45	2334
25	Melbourne Convention Exhibition Centre	0	723	105	58	0	5241
25	Melbourne Convention Exhibition Centre	1	722	54	31	0	2600
25	Melbourne Convention Exhibition Centre	2	720	25	14	0	762
25	Melbourne Convention Exhibition Centre	3	719	15	10	0	460
25	Melbourne Convention Exhibition Centre	4	719	15	13	0	110
25	Melbourne Convention Exhibition Centre	5	721	37	34	0	206
25	Melbourne Convention Exhibition Centre	6	721	153	139	0	634
25	Melbourne Convention Exhibition Centre	7	721	374	357	0	5133
25	Melbourne Convention Exhibition Centre	8	721	648	594	0	2860
25	Melbourne Convention Exhibition Centre	9	722	673	614	0	4036
25	Melbourne Convention Exhibition Centre	10	725	846	732	0	6565
25	Melbourne Convention Exhibition Centre	11	726	1045	919	0	4506
25	Melbourne Convention Exhibition Centre	12	722	1292	1179	0	4777
25	Melbourne Convention Exhibition Centre	13	722	1386	1290	0	4515
25	Melbourne Convention Exhibition Centre	14	722	1408	1270	0	4802
25	Melbourne Convention Exhibition Centre	15	722	1475	1346	0	5633
25	Melbourne Convention Exhibition Centre	16	722	1503	1394	0	4524
25	Melbourne Convention Exhibition Centre	17	722	1531	1489	0	4807
25	Melbourne Convention Exhibition Centre	18	722	1295	1206	0	5636
25	Melbourne Convention Exhibition Centre	19	722	782	672	0	3512
25	Melbourne Convention Exhibition Centre	20	722	698	606	0	3071
25	Melbourne Convention Exhibition Centre	21	722	637	500	0	3656
25	Melbourne Convention Exhibition Centre	22	722	466	332	0	5428
25	Melbourne Convention Exhibition Centre	23	722	241	141	0	5400
27	QV Market-Peel St	0	728	32	28	2	255
27	QV Market-Peel St	1	725	19	15	1	199
27	QV Market-Peel St	2	717	11	8	1	90
27	QV Market-Peel St	3	725	10	8	0	71
27	QV Market-Peel St	4	715	7	5	1	53
27	QV Market-Peel St	5	726	11	9	1	77
27	QV Market-Peel St	6	726	31	30	5	179
27	QV Market-Peel St	7	726	75	74	10	220
27	QV Market-Peel St	8	727	157	158	21	483
27	QV Market-Peel St	9	727	195	181	46	443
27	QV Market-Peel St	10	727	251	220	51	547
27	QV Market-Peel St	11	727	306	271	94	674
27	QV Market-Peel St	12	727	354	329	79	766
27	QV Market-Peel St	13	727	348	321	96	833
27	QV Market-Peel St	14	728	298	268	68	694
27	QV Market-Peel St	15	729	266	238	65	695
27	QV Market-Peel St	16	729	227	213	73	462
27	QV Market-Peel St	17	729	235	231	42	535
27	QV Market-Peel St	18	727	226	214	78	859
27	QV Market-Peel St	19	727	187	171	64	774
27	QV Market-Peel St	20	727	158	141	41	631
27	QV Market-Peel St	21	727	127	117	19	409
27	QV Market-Peel St	22	727	86	82	9	261
27	QV Market-Peel St	23	727	57	50	3	272
29	St Kilda Rd-Alexandra Gardens	0	719	49	31	1	2545
29	St Kilda Rd-Alexandra Gardens	1	720	30	20	1	2215
29	St Kilda Rd-Alexandra Gardens	2	710	19	12	1	962
29	St Kilda Rd-Alexandra Gardens	3	703	11	8	1	317
29	St Kilda Rd-Alexandra Gardens	4	711	12	7	1	1203
29	St Kilda Rd-Alexandra Gardens	5	718	36	27	1	2426
29	St Kilda Rd-Alexandra Gardens	6	724	111	99	1	1462
29	St Kilda Rd-Alexandra Gardens	7	727	234	195	1	2989
29	St Kilda Rd-Alexandra Gardens	8	726	336	272	3	4252
29	St Kilda Rd-Alexandra Gardens	9	727	332	271	1	4002
29	St Kilda Rd-Alexandra Gardens	10	725	437	352	1	4138
29	St Kilda Rd-Alexandra Gardens	11	726	565	465	1	3884
29	St Kilda Rd-Alexandra Gardens	12	727	701	590	1	5883
29	St Kilda Rd-Alexandra Gardens	13	726	747	626	2	5110
29	St Kilda Rd-Alexandra Gardens	14	727	717	585	2	4783
29	St Kilda Rd-Alexandra Gardens	15	727	717	595	3	4519
29	St Kilda Rd-Alexandra Gardens	16	725	702	583	1	4832
29	St Kilda Rd-Alexandra Gardens	17	725	768	647	1	5785
29	St Kilda Rd-Alexandra Gardens	18	721	714	541	1	6831
29	St Kilda Rd-Alexandra Gardens	19	722	583	374	1	8164
29	St Kilda Rd-Alexandra Gardens	20	721	452	238	1	7739
29	St Kilda Rd-Alexandra Gardens	21	718	375	191	1	6809
29	St Kilda Rd-Alexandra Gardens	22	723	350	160	1	5582
29	St Kilda Rd-Alexandra Gardens	23	716	207	83	1	3606
30	Lonsdale St (South)	0	730	296	192	12	1206
30	Lonsdale St (South)	1	730	219	132	6	1000
30	Lonsdale St (South)	2	728	137	80	3	772
30	Lonsdale St (South)	3	729	111	66	1	666
30	Lonsdale St (South)	4	728	76	46	1	467
30	Lonsdale St (South)	5	729	57	37	4	390
30	Lonsdale St (South)	6	729	51	43	5	161
30	Lonsdale St (South)	7	729	82	82	8	179
30	Lonsdale St (South)	8	728	154	160	28	381
30	Lonsdale St (South)	9	728	198	198	33	439
30	Lonsdale St (South)	10	729	289	285	5	857
30	Lonsdale St (South)	11	729	425	421	7	1536
30	Lonsdale St (South)	12	729	704	697	10	1940
30	Lonsdale St (South)	13	729	738	723	51	1883
30	Lonsdale St (South)	14	729	643	613	21	1954
30	Lonsdale St (South)	15	729	636	604	207	1904
30	Lonsdale St (South)	16	729	668	639	172	1790
30	Lonsdale St (South)	17	729	781	769	302	1308
30	Lonsdale St (South)	18	728	828	788	286	1688
30	Lonsdale St (South)	19	728	797	733	320	1783
30	Lonsdale St (South)	20	728	729	658	232	1684
30	Lonsdale St (South)	21	729	675	595	181	1617
30	Lonsdale St (South)	22	729	561	443	129	1506
30	Lonsdale St (South)	23	729	425	310	30	1567
31	Lygon St (West)	0	730	60	28	2	361
31	Lygon St (West)	1	728	22	14	1	189
31	Lygon St (West)	2	720	11	9	1	101
31	Lygon St (West)	3	706	9	8	1	87
31	Lygon St (West)	4	712	9	7	1	56
31	Lygon St (West)	5	725	10	8	1	94
31	Lygon St (West)	6	728	16	14	1	92
31	Lygon St (West)	7	729	45	45	7	106
31	Lygon St (West)	8	729	91	91	1	261
31	Lygon St (West)	9	729	131	130	29	382
31	Lygon St (West)	10	729	186	180	32	564
31	Lygon St (West)	11	729	245	234	68	835
31	Lygon St (West)	12	729	328	323	44	907
31	Lygon St (West)	13	729	357	342	85	942
31	Lygon St (West)	14	729	332	297	82	904
31	Lygon St (West)	15	729	315	279	68	983
31	Lygon St (West)	16	729	302	277	81	842
31	Lygon St (West)	17	729	334	317	49	737
31	Lygon St (West)	18	729	381	368	84	835
31	Lygon St (West)	19	729	451	412	85	1241
31	Lygon St (West)	20	729	486	446	141	1497
31	Lygon St (West)	21	729	434	352	107	1578
31	Lygon St (West)	22	729	302	210	54	1372
31	Lygon St (West)	23	729	156	86	13	852
35	Southbank Promenade	0	730	283	154	10	3560
35	Southbank Promenade	1	730	134	61	4	4238
35	Southbank Promenade	2	728	60	31	2	2029
35	Southbank Promenade	3	730	34	20	1	906
35	Southbank Promenade	4	729	25	21	1	288
35	Southbank Promenade	5	729	81	71	2	337
35	Southbank Promenade	6	729	373	327	18	856
35	Southbank Promenade	7	729	944	1013	114	6794
35	Southbank Promenade	8	729	1927	2120	261	6808
35	Southbank Promenade	9	729	1440	1422	194	9836
35	Southbank Promenade	10	729	1331	1258	170	3483
35	Southbank Promenade	11	729	1608	1510	261	3979
35	Southbank Promenade	12	729	2337	2369	318	4139
35	Southbank Promenade	13	729	2320	2339	279	4257
35	Southbank Promenade	14	729	2072	1963	377	4061
35	Southbank Promenade	15	729	2140	2006	312	4254
35	Southbank Promenade	16	729	2493	2421	353	4767
35	Southbank Promenade	17	729	3101	3193	348	5153
35	Southbank Promenade	18	729	2431	2391	239	7029
35	Southbank Promenade	19	729	1947	1841	86	6283
35	Southbank Promenade	20	729	1662	1387	74	7117
35	Southbank Promenade	21	729	1354	1103	89	5445
35	Southbank Promenade	22	729	1098	827	40	5168
35	Southbank Promenade	23	729	659	440	32	4968
36	Queen St (West)	0	730	108	31	2	1057
36	Queen St (West)	1	729	90	17	1	613
36	Queen St (West)	2	724	75	10	1	510
36	Queen St (West)	3	724	77	11	1	496
36	Queen St (West)	4	716	20	8	1	173
36	Queen St (West)	5	729	21	18	4	191
36	Queen St (West)	6	729	49	51	11	307
36	Queen St (West)	7	729	110	125	17	568
36	Queen St (West)	8	729	282	342	28	588
36	Queen St (West)	9	729	262	293	58	524
36	Queen St (West)	10	729	266	275	102	583
36	Queen St (West)	11	729	309	325	81	490
36	Queen St (West)	12	729	530	604	108	912
36	Queen St (West)	13	729	502	582	75	896
36	Queen St (West)	14	729	353	382	102	612
36	Queen St (West)	15	729	310	327	112	494
36	Queen St (West)	16	729	335	360	99	570
36	Queen St (West)	17	729	442	501	105	861
36	Queen St (West)	18	729	337	345	93	686
36	Queen St (West)	19	729	245	242	88	618
36	Queen St (West)	20	729	222	213	69	593
36	Queen St (West)	21	729	196	185	51	470
36	Queen St (West)	22	729	164	111	22	552
36	Queen St (West)	23	729	144	69	12	896
37	Lygon St (East)	0	730	50	30	1	223
37	Lygon St (East)	1	726	19	14	1	133
37	Lygon St (East)	2	710	9	7	1	49
37	Lygon St (East)	3	682	6	5	1	41
37	Lygon St (East)	4	647	5	5	1	20
37	Lygon St (East)	5	701	6	5	1	20
37	Lygon St (East)	6	725	10	10	1	32
37	Lygon St (East)	7	729	26	26	3	79
37	Lygon St (East)	8	729	62	62	15	154
37	Lygon St (East)	9	729	77	76	25	175
37	Lygon St (East)	10	729	108	107	32	385
37	Lygon St (East)	11	729	155	151	33	305
37	Lygon St (East)	12	729	227	230	71	405
37	Lygon St (East)	13	604	208	218	27	367
37	Lygon St (East)	14	385	202	196	46	470
37	Lygon St (East)	15	382	190	182	15	348
37	Lygon St (East)	16	378	193	187	8	328
37	Lygon St (East)	17	369	243	241	2	453
37	Lygon St (East)	18	337	247	249	4	639
37	Lygon St (East)	19	155	145	106	3	718
37	Lygon St (East)	20	15	300	221	7	885
37	Lygon St (East)	21	7	392	246	150	813
37	Lygon St (East)	22	366	128	79	19	732
37	Lygon St (East)	23	729	97	61	10	462
39	Alfred Place	0	606	6	4	1	54
39	Alfred Place	1	450	4	2	1	26
39	Alfred Place	2	345	3	2	1	25
39	Alfred Place	3	299	2	2	1	14
39	Alfred Place	4	336	3	2	1	67
39	Alfred Place	5	615	6	4	1	29
39	Alfred Place	6	711	18	14	1	153
39	Alfred Place	7	720	54	48	2	233
39	Alfred Place	8	721	148	163	12	334
39	Alfred Place	9	722	164	173	19	307
39	Alfred Place	10	722	151	155	1	515
39	Alfred Place	11	722	157	168	1	377
39	Alfred Place	12	722	334	396	17	659
39	Alfred Place	13	720	272	318	26	561
39	Alfred Place	14	720	173	187	39	340
39	Alfred Place	15	720	142	146	27	311
39	Alfred Place	16	720	134	138	8	282
39	Alfred Place	17	720	152	155	5	390
39	Alfred Place	18	720	101	98	4	265
39	Alfred Place	19	720	58	53	3	265
39	Alfred Place	20	721	30	25	1	129
39	Alfred Place	21	718	24	18	1	111
39	Alfred Place	22	711	20	13	1	117
39	Alfred Place	23	667	13	8	1	96
40	Lonsdale St-Spring St (West)	0	728	30	19	1	600
40	Lonsdale St-Spring St (West)	1	720	18	11	1	244
40	Lonsdale St-Spring St (West)	2	700	10	7	1	75
40	Lonsdale St-Spring St (West)	3	701	8	5	1	67
40	Lonsdale St-Spring St (West)	4	696	7	5	1	127
40	Lonsdale St-Spring St (West)	5	727	14	14	1	85
40	Lonsdale St-Spring St (West)	6	727	53	59	5	153
40	Lonsdale St-Spring St (West)	7	727	142	163	13	352
40	Lonsdale St-Spring St (West)	8	728	384	442	44	992
40	Lonsdale St-Spring St (West)	9	726	330	359	52	769
40	Lonsdale St-Spring St (West)	10	726	336	350	69	956
40	Lonsdale St-Spring St (West)	11	725	381	381	86	1034
40	Lonsdale St-Spring St (West)	12	726	636	615	129	1393
40	Lonsdale St-Spring St (West)	13	726	528	547	125	1159
40	Lonsdale St-Spring St (West)	14	726	365	366	103	861
40	Lonsdale St-Spring St (West)	15	726	322	316	77	1111
40	Lonsdale St-Spring St (West)	16	726	345	353	61	678
40	Lonsdale St-Spring St (West)	17	727	402	416	85	1065
40	Lonsdale St-Spring St (West)	18	727	327	334	92	1220
40	Lonsdale St-Spring St (West)	19	727	210	189	70	1037
40	Lonsdale St-Spring St (West)	20	727	173	166	58	390
40	Lonsdale St-Spring St (West)	21	727	191	171	32	616
40	Lonsdale St-Spring St (West)	22	727	143	92	17	467
40	Lonsdale St-Spring St (West)	23	727	62	44	6	299
41	Flinders La-Swanston St (West)	0	725	389	245	30	4521
41	Flinders La-Swanston St (West)	1	724	229	127	15	3363
41	Flinders La-Swanston St (West)	2	722	152	83	7	1928
41	Flinders La-Swanston St (West)	3	725	116	70	8	1060
41	Flinders La-Swanston St (West)	4	723	101	86	6	901
41	Flinders La-Swanston St (West)	5	723	165	178	16	648
41	Flinders La-Swanston St (West)	6	723	370	392	21	868
41	Flinders La-Swanston St (West)	7	724	678	772	22	2414
41	Flinders La-Swanston St (West)	8	726	1371	1635	52	3245
41	Flinders La-Swanston St (West)	9	726	1497	1656	64	3260
41	Flinders La-Swanston St (West)	10	726	1758	1908	161	3732
41	Flinders La-Swanston St (West)	11	724	2197	2369	312	4109
41	Flinders La-Swanston St (West)	12	725	2733	2973	233	4665
41	Flinders La-Swanston St (West)	13	725	2811	3040	208	4764
41	Flinders La-Swanston St (West)	14	725	2733	2947	366	4801
41	Flinders La-Swanston St (West)	15	725	2716	2933	352	5015
41	Flinders La-Swanston St (West)	16	725	2828	3092	280	5100
41	Flinders La-Swanston St (West)	17	724	3046	3360	204	5411
41	Flinders La-Swanston St (West)	18	724	2451	2644	96	5226
41	Flinders La-Swanston St (West)	19	725	1893	1900	56	4460
41	Flinders La-Swanston St (West)	20	724	1581	1575	62	4170
41	Flinders La-Swanston St (West)	21	725	1481	1404	59	4947
41	Flinders La-Swanston St (West)	22	724	1236	1052	44	4213
41	Flinders La-Swanston St (West)	23	724	778	588	26	2822
42	Grattan St-Swanston St (West)	0	703	19	17	1	77
42	Grattan St-Swanston St (West)	1	694	11	10	1	58
42	Grattan St-Swanston St (West)	2	671	7	5	1	34
42	Grattan St-Swanston St (West)	3	637	5	4	1	26
42	Grattan St-Swanston St (West)	4	633	4	3	1	25
42	Grattan St-Swanston St (West)	5	678	7	6	1	31
42	Grattan St-Swanston St (West)	6	701	27	27	1	75
42	Grattan St-Swanston St (West)	7	701	66	72	7	237
42	Grattan St-Swanston St (West)	8	700	216	194	6	788
42	Grattan St-Swanston St (West)	9	699	251	199	12	982
42	Grattan St-Swanston St (West)	10	696	288	204	18	1048
42	Grattan St-Swanston St (West)	11	695	347	243	15	1253
42	Grattan St-Swanston St (West)	12	695	501	385	16	1784
42	Grattan St-Swanston St (West)	13	693	500	359	20	1763
42	Grattan St-Swanston St (West)	14	693	405	272	23	1429
42	Grattan St-Swanston St (West)	15	695	392	280	20	1270
42	Grattan St-Swanston St (West)	16	695	392	290	25	1249
42	Grattan St-Swanston St (West)	17	694	403	314	25	1194
42	Grattan St-Swanston St (West)	18	694	270	194	19	944
42	Grattan St-Swanston St (West)	19	694	176	141	8	537
42	Grattan St-Swanston St (West)	20	698	122	104	2	488
42	Grattan St-Swanston St (West)	21	698	95	84	4	334
42	Grattan St-Swanston St (West)	22	700	63	58	5	228
42	Grattan St-Swanston St (West)	23	701	37	35	2	113
43	Monash Rd-Swanston St (West)	0	710	15	12	1	99
43	Monash Rd-Swanston St (West)	1	680	8	6	1	75
43	Monash Rd-Swanston St (West)	2	612	5	4	1	31
43	Monash Rd-Swanston St (West)	3	543	3	2	1	26
43	Monash Rd-Swanston St (West)	4	490	3	2	1	29
43	Monash Rd-Swanston St (West)	5	667	5	4	1	52
43	Monash Rd-Swanston St (West)	6	710	20	18	1	176
43	Monash Rd-Swanston St (West)	7	711	55	57	3	530
43	Monash Rd-Swanston St (West)	8	712	166	154	4	478
43	Monash Rd-Swanston St (West)	9	712	205	170	12	594
43	Monash Rd-Swanston St (West)	10	713	213	162	8	684
43	Monash Rd-Swanston St (West)	11	713	251	186	18	858
43	Monash Rd-Swanston St (West)	12	714	339	268	25	1341
43	Monash Rd-Swanston St (West)	13	713	343	268	4	1303
43	Monash Rd-Swanston St (West)	14	712	302	226	8	977
43	Monash Rd-Swanston St (West)	15	711	326	250	17	1149
43	Monash Rd-Swanston St (West)	16	710	357	280	16	960
43	Monash Rd-Swanston St (West)	17	710	394	328	21	1052
43	Monash Rd-Swanston St (West)	18	710	246	202	15	826
43	Monash Rd-Swanston St (West)	19	710	175	146	10	645
43	Monash Rd-Swanston St (West)	20	710	111	90	3	515
43	Monash Rd-Swanston St (West)	21	710	81	69	4	483
43	Monash Rd-Swanston St (West)	22	710	55	49	4	275
43	Monash Rd-Swanston St (West)	23	710	30	26	1	221
44	Tin Alley-Swanston St (West)	0	692	9	6	1	82
44	Tin Alley-Swanston St (West)	1	616	5	4	1	73
44	Tin Alley-Swanston St (West)	2	524	3	2	1	29
44	Tin Alley-Swanston St (West)	3	378	3	2	1	20
44	Tin Alley-Swanston St (West)	4	353	2	1	1	32
44	Tin Alley-Swanston St (West)	5	587	3	2	1	31
44	Tin Alley-Swanston St (West)	6	718	12	10	1	181
44	Tin Alley-Swanston St (West)	7	729	37	37	2	533
44	Tin Alley-Swanston St (West)	8	729	85	81	4	276
44	Tin Alley-Swanston St (West)	9	729	98	85	7	334
44	Tin Alley-Swanston St (West)	10	729	108	93	5	429
44	Tin Alley-Swanston St (West)	11	729	123	112	8	498
44	Tin Alley-Swanston St (West)	12	729	162	142	11	616
44	Tin Alley-Swanston St (West)	13	729	164	145	4	650
44	Tin Alley-Swanston St (West)	14	729	141	126	3	582
44	Tin Alley-Swanston St (West)	15	729	146	129	7	497
44	Tin Alley-Swanston St (West)	16	729	151	136	7	374
44	Tin Alley-Swanston St (West)	17	729	179	160	14	445
44	Tin Alley-Swanston St (West)	18	729	120	106	10	351
44	Tin Alley-Swanston St (West)	19	729	88	74	9	344
44	Tin Alley-Swanston St (West)	20	729	62	55	3	260
44	Tin Alley-Swanston St (West)	21	729	44	37	1	185
44	Tin Alley-Swanston St (West)	22	729	31	26	2	188
44	Tin Alley-Swanston St (West)	23	723	17	13	1	205
45	Little Collins St-Swanston St (East)	0	697	201	113	1	2177
45	Little Collins St-Swanston St (East)	1	697	123	58	5	1581
45	Little Collins St-Swanston St (East)	2	683	72	33	1	838
45	Little Collins St-Swanston St (East)	3	686	51	28	1	448
45	Little Collins St-Swanston St (East)	4	686	34	26	1	268
45	Little Collins St-Swanston St (East)	5	685	47	42	17	262
45	Little Collins St-Swanston St (East)	6	685	93	88	26	391
45	Little Collins St-Swanston St (East)	7	710	210	226	10	464
45	Little Collins St-Swanston St (East)	8	724	470	524	84	1103
45	Little Collins St-Swanston St (East)	9	724	525	540	32	957
45	Little Collins St-Swanston St (East)	10	725	682	670	89	2706
45	Little Collins St-Swanston St (East)	11	724	991	960	337	2327
45	Little Collins St-Swanston St (East)	12	724	1509	1492	577	2742
45	Little Collins St-Swanston St (East)	13	724	1644	1594	729	3231
45	Little Collins St-Swanston St (East)	14	724	1507	1405	598	3601
45	Little Collins St-Swanston St (East)	15	724	1458	1379	573	3185
45	Little Collins St-Swanston St (East)	16	725	1484	1422	570	2940
45	Little Collins St-Swanston St (East)	17	725	1645	1604	634	3622
45	Little Collins St-Swanston St (East)	18	725	1401	1349	637	3183
45	Little Collins St-Swanston St (East)	19	725	1247	1141	434	3198
45	Little Collins St-Swanston St (East)	20	725	1112	997	385	2976
45	Little Collins St-Swanston St (East)	21	725	955	835	271	2724
45	Little Collins St-Swanston St (East)	22	724	675	540	19	2781
45	Little Collins St-Swanston St (East)	23	724	380	264	7	3154
46	Pelham St (South)	0	348	2	1	1	11
46	Pelham St (South)	1	240	2	1	1	9
46	Pelham St (South)	2	188	1	1	1	14
46	Pelham St (South)	3	106	1	1	1	4
46	Pelham St (South)	4	74	1	1	1	3
46	Pelham St (South)	5	236	2	1	1	12
46	Pelham St (South)	6	603	9	8	1	36
46	Pelham St (South)	7	710	29	29	1	90
46	Pelham St (South)	8	710	104	96	4	332
46	Pelham St (South)	9	709	112	110	3	331
46	Pelham St (South)	10	709	110	97	7	292
46	Pelham St (South)	11	710	126	105	12	338
46	Pelham St (South)	12	710	200	185	9	507
46	Pelham St (South)	13	710	215	182	15	574
46	Pelham St (South)	14	710	154	134	20	369
46	Pelham St (South)	15	710	147	130	14	368
46	Pelham St (South)	16	710	168	140	21	480
46	Pelham St (South)	17	710	162	144	15	431
46	Pelham St (South)	18	706	87	73	1	361
46	Pelham St (South)	19	688	58	44	1	300
46	Pelham St (South)	20	682	24	10	1	91
46	Pelham St (South)	21	670	6	4	1	54
46	Pelham St (South)	22	605	4	3	1	27
46	Pelham St (South)	23	517	2	2	1	18
47	Melbourne Central-Elizabeth St (East)	0	729	202	144	44	2803
47	Melbourne Central-Elizabeth St (East)	1	729	129	85	18	4320
47	Melbourne Central-Elizabeth St (East)	2	727	77	49	11	840
47	Melbourne Central-Elizabeth St (East)	3	729	52	34	7	424
47	Melbourne Central-Elizabeth St (East)	4	728	40	34	4	228
47	Melbourne Central-Elizabeth St (East)	5	728	63	61	17	170
47	Melbourne Central-Elizabeth St (East)	6	728	160	144	20	349
47	Melbourne Central-Elizabeth St (East)	7	729	289	314	5	754
47	Melbourne Central-Elizabeth St (East)	8	729	646	704	12	1374
47	Melbourne Central-Elizabeth St (East)	9	729	723	727	12	1664
47	Melbourne Central-Elizabeth St (East)	10	729	911	914	9	1586
47	Melbourne Central-Elizabeth St (East)	11	729	1241	1236	2	2053
47	Melbourne Central-Elizabeth St (East)	12	728	1706	1724	18	2575
47	Melbourne Central-Elizabeth St (East)	13	729	1908	1917	16	3133
47	Melbourne Central-Elizabeth St (East)	14	729	1816	1750	7	3566
47	Melbourne Central-Elizabeth St (East)	15	729	1840	1787	43	3616
47	Melbourne Central-Elizabeth St (East)	16	729	1907	1913	430	3335
47	Melbourne Central-Elizabeth St (East)	17	729	2050	2106	317	2927
47	Melbourne Central-Elizabeth St (East)	18	729	1642	1645	548	2717
47	Melbourne Central-Elizabeth St (East)	19	729	1315	1269	355	2775
47	Melbourne Central-Elizabeth St (East)	20	729	1048	999	16	2291
47	Melbourne Central-Elizabeth St (East)	21	729	807	754	4	2081
47	Melbourne Central-Elizabeth St (East)	22	728	553	486	170	2769
47	Melbourne Central-Elizabeth St (East)	23	729	350	270	1	2290
48	QVM-Queen St (East)	0	134	37	32	1	110
48	QVM-Queen St (East)	1	120	24	20	3	71
48	QVM-Queen St (East)	2	120	15	12	1	67
48	QVM-Queen St (East)	3	119	12	9	1	73
48	QVM-Queen St (East)	4	122	11	10	2	54
48	QVM-Queen St (East)	5	246	21	19	8	129
48	QVM-Queen St (East)	6	625	58	57	9	304
48	QVM-Queen St (East)	7	648	114	111	29	455
48	QVM-Queen St (East)	8	648	233	231	53	1066
48	QVM-Queen St (East)	9	649	324	315	38	1081
48	QVM-Queen St (East)	10	684	450	418	136	995
48	QVM-Queen St (East)	11	692	564	518	25	1244
48	QVM-Queen St (East)	12	701	669	649	177	1566
48	QVM-Queen St (East)	13	703	669	654	17	1604
48	QVM-Queen St (East)	14	703	602	579	6	1355
48	QVM-Queen St (East)	15	703	529	497	122	1206
48	QVM-Queen St (East)	16	703	389	336	110	913
48	QVM-Queen St (East)	17	703	370	315	105	1853
48	QVM-Queen St (East)	18	691	363	286	9	2528
48	QVM-Queen St (East)	19	690	309	236	3	2719
48	QVM-Queen St (East)	20	665	252	194	21	1864
48	QVM-Queen St (East)	21	664	190	166	1	972
48	QVM-Queen St (East)	22	597	120	116	1	421
48	QVM-Queen St (East)	23	397	44	40	1	174
49	QVM-Therry St (South)	0	729	117	111	23	539
49	QVM-Therry St (South)	1	729	85	80	10	316
49	QVM-Therry St (South)	2	727	64	60	12	205
49	QVM-Therry St (South)	3	730	50	47	6	131
49	QVM-Therry St (South)	4	729	40	36	3	114
49	QVM-Therry St (South)	5	729	42	41	10	101
49	QVM-Therry St (South)	6	729	75	73	19	143
49	QVM-Therry St (South)	7	729	131	129	4	241
49	QVM-Therry St (South)	8	727	264	266	6	509
49	QVM-Therry St (South)	9	726	376	380	9	731
49	QVM-Therry St (South)	10	728	561	554	1	1100
49	QVM-Therry St (South)	11	728	711	696	2	1766
49	QVM-Therry St (South)	12	727	893	903	11	1959
49	QVM-Therry St (South)	13	728	887	895	10	1882
49	QVM-Therry St (South)	14	729	759	745	2	1753
49	QVM-Therry St (South)	15	728	681	632	21	1618
49	QVM-Therry St (South)	16	728	514	488	19	1348
49	QVM-Therry St (South)	17	729	489	481	19	1328
49	QVM-Therry St (South)	18	729	510	478	146	2133
49	QVM-Therry St (South)	19	729	456	408	36	2595
49	QVM-Therry St (South)	20	728	392	348	2	1931
49	QVM-Therry St (South)	21	729	318	291	3	1149
49	QVM-Therry St (South)	22	729	227	216	4	559
49	QVM-Therry St (South)	23	728	171	162	31	417
50	Faraday St-Lygon St (West)	0	724	22	13	1	114
50	Faraday St-Lygon St (West)	1	703	9	6	1	112
50	Faraday St-Lygon St (West)	2	674	5	4	1	54
50	Faraday St-Lygon St (West)	3	628	5	4	1	44
50	Faraday St-Lygon St (West)	4	637	7	6	1	48
50	Faraday St-Lygon St (West)	5	723	9	8	1	56
50	Faraday St-Lygon St (West)	6	729	19	17	2	61
50	Faraday St-Lygon St (West)	7	729	43	45	6	100
50	Faraday St-Lygon St (West)	8	729	100	111	17	218
50	Faraday St-Lygon St (West)	9	729	178	177	37	360
50	Faraday St-Lygon St (West)	10	729	262	252	37	598
50	Faraday St-Lygon St (West)	11	729	352	328	48	756
50	Faraday St-Lygon St (West)	12	729	457	442	66	891
50	Faraday St-Lygon St (West)	13	729	458	439	55	917
50	Faraday St-Lygon St (West)	14	729	428	398	23	979
50	Faraday St-Lygon St (West)	15	729	398	366	58	921
50	Faraday St-Lygon St (West)	16	729	383	359	73	1031
50	Faraday St-Lygon St (West)	17	729	416	407	54	1034
50	Faraday St-Lygon St (West)	18	729	427	414	41	730
50	Faraday St-Lygon St (West)	19	729	398	365	50	759
50	Faraday St-Lygon St (West)	20	729	378	338	52	779
50	Faraday St-Lygon St (West)	21	729	290	248	47	752
50	Faraday St-Lygon St (West)	22	729	152	115	20	484
50	Faraday St-Lygon St (West)	23	729	57	37	4	286
51	QVM-Franklin St (North)	0	730	37	34	5	502
51	QVM-Franklin St (North)	1	730	24	22	2	179
51	QVM-Franklin St (North)	2	727	16	14	1	84
51	QVM-Franklin St (North)	3	730	14	12	1	67
51	QVM-Franklin St (North)	4	728	11	9	1	48
51	QVM-Franklin St (North)	5	729	17	16	3	46
51	QVM-Franklin St (North)	6	729	42	36	5	128
51	QVM-Franklin St (North)	7	729	58	57	9	157
51	QVM-Franklin St (North)	8	729	99	100	18	245
51	QVM-Franklin St (North)	9	729	134	135	28	260
51	QVM-Franklin St (North)	10	729	173	176	23	352
51	QVM-Franklin St (North)	11	729	205	206	1	465
51	QVM-Franklin St (North)	12	729	250	257	76	579
51	QVM-Franklin St (North)	13	729	248	253	67	429
51	QVM-Franklin St (North)	14	728	230	228	71	455
51	QVM-Franklin St (North)	15	729	205	200	31	410
51	QVM-Franklin St (North)	16	729	188	189	59	326
51	QVM-Franklin St (North)	17	729	194	193	94	357
51	QVM-Franklin St (North)	18	729	191	186	72	418
51	QVM-Franklin St (North)	19	729	170	163	76	424
51	QVM-Franklin St (North)	20	729	141	134	53	298
51	QVM-Franklin St (North)	21	729	115	110	37	479
51	QVM-Franklin St (North)	22	729	82	80	29	296
51	QVM-Franklin St (North)	23	729	58	55	14	383
52	Elizabeth St-Lonsdale St (South)	0	730	119	48	2	722
52	Elizabeth St-Lonsdale St (South)	1	730	82	28	1	674
52	Elizabeth St-Lonsdale St (South)	2	720	46	18	1	419
52	Elizabeth St-Lonsdale St (South)	3	711	34	12	1	321
52	Elizabeth St-Lonsdale St (South)	4	710	20	9	1	158
52	Elizabeth St-Lonsdale St (South)	5	727	17	14	1	130
52	Elizabeth St-Lonsdale St (South)	6	729	31	31	3	71
52	Elizabeth St-Lonsdale St (South)	7	729	99	112	16	203
52	Elizabeth St-Lonsdale St (South)	8	729	320	378	21	615
52	Elizabeth St-Lonsdale St (South)	9	728	277	298	57	470
52	Elizabeth St-Lonsdale St (South)	10	729	340	342	139	636
52	Elizabeth St-Lonsdale St (South)	11	729	479	474	201	852
52	Elizabeth St-Lonsdale St (South)	12	729	755	765	256	1170
52	Elizabeth St-Lonsdale St (South)	13	729	825	830	291	1259
52	Elizabeth St-Lonsdale St (South)	14	729	745	731	346	1248
52	Elizabeth St-Lonsdale St (South)	15	729	734	724	304	1269
52	Elizabeth St-Lonsdale St (South)	16	729	685	672	255	1207
52	Elizabeth St-Lonsdale St (South)	17	729	745	748	250	1261
52	Elizabeth St-Lonsdale St (South)	18	729	669	663	222	1243
52	Elizabeth St-Lonsdale St (South)	19	729	596	581	108	1266
52	Elizabeth St-Lonsdale St (South)	20	729	477	443	64	1093
52	Elizabeth St-Lonsdale St (South)	21	729	349	318	67	784
52	Elizabeth St-Lonsdale St (South)	22	729	241	188	33	780
52	Elizabeth St-Lonsdale St (South)	23	729	185	107	11	874
53	Collins Street (North)	0	714	68	41	7	1327
53	Collins Street (North)	1	714	37	22	2	719
53	Collins Street (North)	2	712	21	12	1	212
53	Collins Street (North)	3	710	15	9	1	153
53	Collins Street (North)	4	708	10	8	1	124
53	Collins Street (North)	5	713	19	16	2	142
53	Collins Street (North)	6	713	59	57	2	190
53	Collins Street (North)	7	712	201	218	30	498
53	Collins Street (North)	8	712	521	568	60	1162
53	Collins Street (North)	9	713	631	671	144	1080
53	Collins Street (North)	10	714	851	854	30	1787
53	Collins Street (North)	11	714	1131	1134	303	1989
53	Collins Street (North)	12	714	1514	1542	434	2430
53	Collins Street (North)	13	714	1544	1568	397	2673
53	Collins Street (North)	14	714	1350	1351	447	2253
53	Collins Street (North)	15	714	1245	1228	511	2171
53	Collins Street (North)	16	714	1153	1146	376	1896
53	Collins Street (North)	17	714	1130	1147	338	1959
53	Collins Street (North)	18	713	728	724	198	1406
53	Collins Street (North)	19	713	495	470	104	1177
53	Collins Street (North)	20	713	397	376	116	1107
53	Collins Street (North)	21	713	339	322	99	1052
53	Collins Street (North)	22	713	247	203	46	1241
53	Collins Street (North)	23	713	136	95	14	896
54	Lincoln-Swanston (West)	0	722	51	48	11	155
54	Lincoln-Swanston (West)	1	722	33	31	2	118
54	Lincoln-Swanston (West)	2	720	21	17	1	78
54	Lincoln-Swanston (West)	3	718	15	12	1	67
54	Lincoln-Swanston (West)	4	717	11	9	1	47
54	Lincoln-Swanston (West)	5	719	11	10	1	63
54	Lincoln-Swanston (West)	6	720	21	19	1	82
54	Lincoln-Swanston (West)	7	720	50	48	5	200
54	Lincoln-Swanston (West)	8	719	164	134	13	795
54	Lincoln-Swanston (West)	9	719	160	128	20	772
54	Lincoln-Swanston (West)	10	719	188	149	15	841
54	Lincoln-Swanston (West)	11	719	223	189	40	775
54	Lincoln-Swanston (West)	12	719	293	256	46	880
54	Lincoln-Swanston (West)	13	719	322	283	21	919
54	Lincoln-Swanston (West)	14	719	304	270	34	926
54	Lincoln-Swanston (West)	15	719	327	283	41	1011
54	Lincoln-Swanston (West)	16	719	351	302	40	1239
54	Lincoln-Swanston (West)	17	718	401	339	42	1345
54	Lincoln-Swanston (West)	18	718	331	290	53	1046
54	Lincoln-Swanston (West)	19	719	273	259	6	827
54	Lincoln-Swanston (West)	20	719	237	228	27	617
54	Lincoln-Swanston (West)	21	719	202	193	40	732
54	Lincoln-Swanston (West)	22	719	141	136	13	381
54	Lincoln-Swanston (West)	23	720	86	82	15	293
56	Lonsdale St - Elizabeth St (North)	0	716	116	78	15	762
56	Lonsdale St - Elizabeth St (North)	1	715	69	42	4	734
56	Lonsdale St - Elizabeth St (North)	2	714	40	21	1	355
56	Lonsdale St - Elizabeth St (North)	3	704	29	12	1	229
56	Lonsdale St - Elizabeth St (North)	4	702	21	10	1	155
56	Lonsdale St - Elizabeth St (North)	5	718	26	19	2	148
56	Lonsdale St - Elizabeth St (North)	6	720	43	42	8	84
56	Lonsdale St - Elizabeth St (North)	7	722	110	116	5	259
56	Lonsdale St - Elizabeth St (North)	8	722	255	288	60	608
56	Lonsdale St - Elizabeth St (North)	9	723	320	324	132	614
56	Lonsdale St - Elizabeth St (North)	10	722	433	433	31	1026
56	Lonsdale St - Elizabeth St (North)	11	721	544	538	13	1241
56	Lonsdale St - Elizabeth St (North)	12	722	782	786	184	1215
56	Lonsdale St - Elizabeth St (North)	13	721	847	843	206	1693
56	Lonsdale St - Elizabeth St (North)	14	721	751	725	235	1722
56	Lonsdale St - Elizabeth St (North)	15	720	733	716	225	1838
56	Lonsdale St - Elizabeth St (North)	16	718	741	728	221	1724
56	Lonsdale St - Elizabeth St (North)	17	717	878	876	394	1798
56	Lonsdale St - Elizabeth St (North)	18	717	865	850	300	1618
56	Lonsdale St - Elizabeth St (North)	19	718	820	790	225	1680
56	Lonsdale St - Elizabeth St (North)	20	718	707	685	167	1495
56	Lonsdale St - Elizabeth St (North)	21	716	569	534	212	1202
56	Lonsdale St - Elizabeth St (North)	22	715	366	313	99	900
56	Lonsdale St - Elizabeth St (North)	23	715	211	156	19	827
58	Bourke St - Spencer St (North)	0	715	175	135	13	1381
58	Bourke St - Spencer St (North)	1	716	100	74	6	1165
58	Bourke St - Spencer St (North)	2	714	68	50	11	557
58	Bourke St - Spencer St (North)	3	716	30	21	2	253
58	Bourke St - Spencer St (North)	4	715	29	24	7	157
58	Bourke St - Spencer St (North)	5	715	77	82	18	132
58	Bourke St - Spencer St (North)	6	715	206	235	46	372
58	Bourke St - Spencer St (North)	7	714	580	684	8	1309
58	Bourke St - Spencer St (North)	8	713	1220	1448	154	2400
58	Bourke St - Spencer St (North)	9	714	963	1054	152	1795
58	Bourke St - Spencer St (North)	10	714	847	853	389	1621
58	Bourke St - Spencer St (North)	11	714	947	937	453	1993
58	Bourke St - Spencer St (North)	12	715	1148	1174	420	2020
58	Bourke St - Spencer St (North)	13	716	1113	1152	452	1727
58	Bourke St - Spencer St (North)	14	716	962	958	347	1922
58	Bourke St - Spencer St (North)	15	717	1050	1068	402	2247
58	Bourke St - Spencer St (North)	16	717	1388	1487	460	2713
58	Bourke St - Spencer St (North)	17	717	1603	1741	447	3296
58	Bourke St - Spencer St (North)	18	716	1063	1026	256	2347
58	Bourke St - Spencer St (North)	19	715	705	639	163	2140
58	Bourke St - Spencer St (North)	20	716	513	492	126	1140
58	Bourke St - Spencer St (North)	21	716	470	438	35	1618
58	Bourke St - Spencer St (North)	22	716	456	356	25	2221
58	Bourke St - Spencer St (North)	23	716	335	230	4	2919
59	Building 80 RMIT	0	730	134	112	22	558
59	Building 80 RMIT	1	730	86	71	13	677
59	Building 80 RMIT	2	728	55	40	2	358
59	Building 80 RMIT	3	730	43	27	1	209
59	Building 80 RMIT	4	729	25	21	2	102
59	Building 80 RMIT	5	729	29	28	3	94
59	Building 80 RMIT	6	729	78	80	7	235
59	Building 80 RMIT	7	729	210	208	11	603
59	Building 80 RMIT	8	729	751	569	21	2905
59	Building 80 RMIT	9	729	757	619	59	2245
59	Building 80 RMIT	10	729	1076	675	53	4545
59	Building 80 RMIT	11	728	1126	856	48	7146
59	Building 80 RMIT	12	728	1694	1179	49	6978
59	Building 80 RMIT	13	728	1528	1294	88	7676
59	Building 80 RMIT	14	729	1638	1238	99	6460
59	Building 80 RMIT	15	729	1457	1268	191	3953
59	Building 80 RMIT	16	729	1609	1307	174	4725
59	Building 80 RMIT	17	728	1487	1354	198	3999
59	Building 80 RMIT	18	728	1217	1145	195	3655
59	Building 80 RMIT	19	729	896	875	154	2197
59	Building 80 RMIT	20	729	705	673	90	1613
59	Building 80 RMIT	21	729	517	489	118	1120
59	Building 80 RMIT	22	729	364	348	75	843
59	Building 80 RMIT	23	729	249	227	35	689
61	RMIT Building 14	0	730	87	72	12	349
61	RMIT Building 14	1	730	56	46	6	477
61	RMIT Building 14	2	728	36	27	1	184
61	RMIT Building 14	3	730	27	18	1	153
61	RMIT Building 14	4	729	18	15	2	90
61	RMIT Building 14	5	729	28	26	2	187
61	RMIT Building 14	6	729	68	63	6	303
61	RMIT Building 14	7	727	202	203	22	612
61	RMIT Building 14	8	728	542	510	48	1690
61	RMIT Building 14	9	729	580	545	55	1498
61	RMIT Building 14	10	729	708	643	89	1808
61	RMIT Building 14	11	729	821	788	76	2638
61	RMIT Building 14	12	729	1105	1006	144	3823
61	RMIT Building 14	13	729	1081	1027	145	3099
61	RMIT Building 14	14	729	1055	982	189	2650
61	RMIT Building 14	15	729	1022	979	194	2331
61	RMIT Building 14	16	729	1068	1008	176	2627
61	RMIT Building 14	17	728	1103	1018	146	3000
61	RMIT Building 14	18	728	888	830	110	2652
61	RMIT Building 14	19	728	730	680	115	2068
61	RMIT Building 14	20	728	573	548	72	1411
61	RMIT Building 14	21	728	439	410	77	1173
61	RMIT Building 14	22	728	296	269	66	959
61	RMIT Building 14	23	729	170	147	33	544
62	La Trobe St (North)	0	730	117	105	36	656
62	La Trobe St (North)	1	730	71	63	18	326
62	La Trobe St (North)	2	728	46	41	8	202
62	La Trobe St (North)	3	730	32	25	2	170
62	La Trobe St (North)	4	729	24	19	2	162
62	La Trobe St (North)	5	729	24	22	5	78
62	La Trobe St (North)	6	729	73	59	14	326
62	La Trobe St (North)	7	729	83	78	13	536
62	La Trobe St (North)	8	729	168	160	27	1258
62	La Trobe St (North)	9	729	206	196	57	1308
62	La Trobe St (North)	10	729	285	271	85	1970
62	La Trobe St (North)	11	729	348	332	77	2073
62	La Trobe St (North)	12	729	471	446	153	2442
62	La Trobe St (North)	13	729	500	479	187	2305
62	La Trobe St (North)	14	729	502	480	48	2466
62	La Trobe St (North)	15	729	501	481	178	2412
62	La Trobe St (North)	16	729	533	511	210	2753
62	La Trobe St (North)	17	729	582	556	237	2842
62	La Trobe St (North)	18	729	556	535	247	1963
62	La Trobe St (North)	19	729	504	486	234	1214
62	La Trobe St (North)	20	729	427	418	154	830
62	La Trobe St (North)	21	729	363	344	135	821
62	La Trobe St (North)	22	729	284	267	111	680
62	La Trobe St (North)	23	729	189	170	16	534
63	231 Bourke St	0	730	122	69	2	920
63	231 Bourke St	1	730	80	37	1	820
63	231 Bourke St	2	727	54	26	1	531
63	231 Bourke St	3	720	36	16	1	383
63	231 Bourke St	4	710	14	9	1	91
63	231 Bourke St	5	722	15	13	1	213
63	231 Bourke St	6	728	47	43	2	190
63	231 Bourke St	7	729	122	132	11	521
63	231 Bourke St	8	729	263	291	23	1253
63	231 Bourke St	9	729	339	348	17	993
63	231 Bourke St	10	729	456	452	16	867
63	231 Bourke St	11	729	638	626	99	1527
63	231 Bourke St	12	728	1026	1034	232	2904
63	231 Bourke St	13	728	1050	1042	282	2906
63	231 Bourke St	14	728	864	830	109	2355
63	231 Bourke St	15	728	808	787	7	1951
63	231 Bourke St	16	729	823	796	21	1678
63	231 Bourke St	17	729	889	885	7	1780
63	231 Bourke St	18	729	715	709	116	1707
63	231 Bourke St	19	729	634	613	43	1779
63	231 Bourke St	20	729	497	456	27	1583
63	231 Bourke St	21	729	393	359	27	1100
63	231 Bourke St	22	729	287	222	7	1191
63	231 Bourke St	23	729	186	124	4	1022
66	QV2 Apartments, 300 Swanston Street	0	728	210	141	33	1737
66	QV2 Apartments, 300 Swanston Street	1	728	121	77	8	2189
66	QV2 Apartments, 300 Swanston Street	2	726	67	40	7	716
66	QV2 Apartments, 300 Swanston Street	3	728	46	28	2	433
66	QV2 Apartments, 300 Swanston Street	4	727	29	23	3	174
66	QV2 Apartments, 300 Swanston Street	5	727	38	37	9	222
66	QV2 Apartments, 300 Swanston Street	6	727	81	86	13	281
66	QV2 Apartments, 300 Swanston Street	7	727	229	256	26	461
66	QV2 Apartments, 300 Swanston Street	8	727	544	612	53	1336
66	QV2 Apartments, 300 Swanston Street	9	727	656	683	136	1358
66	QV2 Apartments, 300 Swanston Street	10	727	977	967	138	3378
66	QV2 Apartments, 300 Swanston Street	11	727	1488	1478	220	2706
66	QV2 Apartments, 300 Swanston Street	12	727	2200	2203	478	3878
66	QV2 Apartments, 300 Swanston Street	13	727	2468	2455	603	4531
66	QV2 Apartments, 300 Swanston Street	14	727	2513	2489	737	5087
66	QV2 Apartments, 300 Swanston Street	15	727	2628	2599	856	4608
66	QV2 Apartments, 300 Swanston Street	16	727	2776	2796	727	4583
66	QV2 Apartments, 300 Swanston Street	17	727	2933	2958	1166	4340
66	QV2 Apartments, 300 Swanston Street	18	727	2469	2471	845	4043
66	QV2 Apartments, 300 Swanston Street	19	726	2154	2136	497	3666
66	QV2 Apartments, 300 Swanston Street	20	726	1855	1798	433	3352
66	QV2 Apartments, 300 Swanston Street	21	726	1454	1373	530	2828
66	QV2 Apartments, 300 Swanston Street	22	726	894	768	260	2736
66	QV2 Apartments, 300 Swanston Street	23	726	431	316	112	2498
67	Flinders Ln -Degraves St (South)	0	728	66	38	5	292
67	Flinders Ln -Degraves St (South)	1	729	35	18	1	361
67	Flinders Ln -Degraves St (South)	2	726	21	11	1	155
67	Flinders Ln -Degraves St (South)	3	725	15	9	1	94
67	Flinders Ln -Degraves St (South)	4	727	11	10	1	57
67	Flinders Ln -Degraves St (South)	5	729	23	22	1	245
67	Flinders Ln -Degraves St (South)	6	729	119	128	12	252
67	Flinders Ln -Degraves St (South)	7	729	242	264	27	481
67	Flinders Ln -Degraves St (South)	8	729	528	574	79	1019
67	Flinders Ln -Degraves St (South)	9	729	690	736	83	1075
67	Flinders Ln -Degraves St (South)	10	728	729	740	58	1171
67	Flinders Ln -Degraves St (South)	11	729	865	870	5	2082
67	Flinders Ln -Degraves St (South)	12	729	1150	1191	8	1751
67	Flinders Ln -Degraves St (South)	13	729	1135	1175	6	1692
67	Flinders Ln -Degraves St (South)	14	729	967	977	16	1788
67	Flinders Ln -Degraves St (South)	15	729	960	964	6	1915
67	Flinders Ln -Degraves St (South)	16	729	899	909	17	1321
67	Flinders Ln -Degraves St (South)	17	729	971	988	122	2220
67	Flinders Ln -Degraves St (South)	18	729	776	794	88	1558
67	Flinders Ln -Degraves St (South)	19	729	621	615	37	1257
67	Flinders Ln -Degraves St (South)	20	729	518	488	1	1156
67	Flinders Ln -Degraves St (South)	21	729	411	374	1	990
67	Flinders Ln -Degraves St (South)	22	728	281	222	1	1125
67	Flinders Ln -Degraves St (South)	23	727	147	95	16	550
68	Flinders Ln -Degraves St (North)	0	673	12	6	1	90
68	Flinders Ln -Degraves St (North)	1	569	6	3	1	146
68	Flinders Ln -Degraves St (North)	2	521	4	2	1	90
68	Flinders Ln -Degraves St (North)	3	477	3	2	1	28
68	Flinders Ln -Degraves St (North)	4	478	3	2	1	27
68	Flinders Ln -Degraves St (North)	5	619	3	3	1	28
68	Flinders Ln -Degraves St (North)	6	728	23	19	1	86
68	Flinders Ln -Degraves St (North)	7	729	110	108	14	363
68	Flinders Ln -Degraves St (North)	8	729	303	299	45	617
68	Flinders Ln -Degraves St (North)	9	729	399	406	63	758
68	Flinders Ln -Degraves St (North)	10	728	469	480	37	1060
68	Flinders Ln -Degraves St (North)	11	729	579	595	3	1025
68	Flinders Ln -Degraves St (North)	12	729	837	869	3	1416
68	Flinders Ln -Degraves St (North)	13	729	780	820	5	1374
68	Flinders Ln -Degraves St (North)	14	729	648	659	17	1148
68	Flinders Ln -Degraves St (North)	15	729	580	582	4	1096
68	Flinders Ln -Degraves St (North)	16	729	504	505	6	932
68	Flinders Ln -Degraves St (North)	17	729	461	449	66	867
68	Flinders Ln -Degraves St (North)	18	729	357	332	49	820
68	Flinders Ln -Degraves St (North)	19	729	289	271	15	784
68	Flinders Ln -Degraves St (North)	20	728	223	208	12	538
68	Flinders Ln -Degraves St (North)	21	727	158	143	30	472
68	Flinders Ln -Degraves St (North)	22	728	97	68	1	443
68	Flinders Ln -Degraves St (North)	23	726	50	28	1	279
69	Flinders Ln -Degraves St (Crossing)	0	628	10	6	1	68
69	Flinders Ln -Degraves St (Crossing)	1	558	6	4	1	48
69	Flinders Ln -Degraves St (Crossing)	2	551	5	4	1	57
69	Flinders Ln -Degraves St (Crossing)	3	583	5	4	1	48
69	Flinders Ln -Degraves St (Crossing)	4	639	5	4	1	39
69	Flinders Ln -Degraves St (Crossing)	5	684	6	5	1	107
69	Flinders Ln -Degraves St (Crossing)	6	728	23	23	1	66
69	Flinders Ln -Degraves St (Crossing)	7	729	112	118	4	352
69	Flinders Ln -Degraves St (Crossing)	8	729	303	313	23	802
69	Flinders Ln -Degraves St (Crossing)	9	729	359	361	51	727
69	Flinders Ln -Degraves St (Crossing)	10	728	426	419	47	903
69	Flinders Ln -Degraves St (Crossing)	11	729	508	503	8	1004
69	Flinders Ln -Degraves St (Crossing)	12	729	648	658	9	1060
69	Flinders Ln -Degraves St (Crossing)	13	729	612	615	14	1038
69	Flinders Ln -Degraves St (Crossing)	14	729	531	519	21	1021
69	Flinders Ln -Degraves St (Crossing)	15	729	469	457	7	972
69	Flinders Ln -Degraves St (Crossing)	16	729	388	381	4	876
69	Flinders Ln -Degraves St (Crossing)	17	729	347	341	19	659
69	Flinders Ln -Degraves St (Crossing)	18	729	196	188	1	579
69	Flinders Ln -Degraves St (Crossing)	19	724	119	102	2	402
69	Flinders Ln -Degraves St (Crossing)	20	723	84	70	1	283
69	Flinders Ln -Degraves St (Crossing)	21	723	59	45	1	225
69	Flinders Ln -Degraves St (Crossing)	22	725	40	23	1	164
69	Flinders Ln -Degraves St (Crossing)	23	668	23	10	1	111
70	Errol Street (East)	0	719	11	7	1	300
70	Errol Street (East)	1	691	6	5	1	52
70	Errol Street (East)	2	603	4	3	1	77
70	Errol Street (East)	3	535	3	2	1	112
70	Errol Street (East)	4	604	3	2	1	104
70	Errol Street (East)	5	698	5	4	1	94
70	Errol Street (East)	6	729	16	16	2	78
70	Errol Street (East)	7	729	53	57	5	219
70	Errol Street (East)	8	729	124	134	29	349
70	Errol Street (East)	9	729	154	151	34	263
70	Errol Street (East)	10	729	197	188	45	365
70	Errol Street (East)	11	729	246	237	51	442
70	Errol Street (East)	12	729	312	315	82	546
70	Errol Street (East)	13	729	303	307	40	682
70	Errol Street (East)	14	728	250	244	43	922
70	Errol Street (East)	15	728	272	272	44	1000
70	Errol Street (East)	16	728	274	276	39	754
70	Errol Street (East)	17	727	319	323	23	834
70	Errol Street (East)	18	728	350	342	33	845
70	Errol Street (East)	19	729	317	324	47	775
70	Errol Street (East)	20	729	260	226	30	870
70	Errol Street (East)	21	729	177	170	32	481
70	Errol Street (East)	22	729	151	156	5	625
70	Errol Street (East)	23	728	45	22	1	319
71	Westwood Place	0	686	9	7	1	53
71	Westwood Place	1	656	9	7	1	60
71	Westwood Place	2	660	7	5	1	50
71	Westwood Place	3	603	6	3	1	78
71	Westwood Place	4	587	5	3	1	77
71	Westwood Place	5	692	7	4	1	77
71	Westwood Place	6	702	10	7	1	75
71	Westwood Place	7	713	20	16	1	149
71	Westwood Place	8	727	29	27	1	136
71	Westwood Place	9	727	42	44	1	184
71	Westwood Place	10	729	41	42	1	142
71	Westwood Place	11	728	42	44	1	163
71	Westwood Place	12	729	49	52	2	153
71	Westwood Place	13	727	33	31	1	115
71	Westwood Place	14	727	20	18	1	120
71	Westwood Place	15	726	21	19	2	73
71	Westwood Place	16	727	31	30	3	117
71	Westwood Place	17	725	45	45	4	183
71	Westwood Place	18	726	43	37	2	297
71	Westwood Place	19	727	26	22	1	164
71	Westwood Place	20	724	14	12	1	121
71	Westwood Place	21	718	13	10	1	68
71	Westwood Place	22	719	11	9	1	95
71	Westwood Place	23	707	10	7	1	66
72	Flinders St- ACMI	0	725	55	26	1	3976
72	Flinders St- ACMI	1	719	24	11	1	1296
72	Flinders St- ACMI	2	712	12	8	1	263
72	Flinders St- ACMI	3	700	8	5	1	101
72	Flinders St- ACMI	4	709	8	6	1	237
72	Flinders St- ACMI	5	725	23	21	1	386
72	Flinders St- ACMI	6	727	72	74	6	238
72	Flinders St- ACMI	7	729	172	188	15	643
72	Flinders St- ACMI	8	729	510	567	38	1277
72	Flinders St- ACMI	9	729	348	341	35	1220
72	Flinders St- ACMI	10	729	341	331	19	1706
72	Flinders St- ACMI	11	729	423	411	35	1360
72	Flinders St- ACMI	12	729	529	522	50	2310
72	Flinders St- ACMI	13	729	532	517	101	1377
72	Flinders St- ACMI	14	729	544	522	101	1219
72	Flinders St- ACMI	15	729	537	514	64	1235
72	Flinders St- ACMI	16	729	690	680	82	2011
72	Flinders St- ACMI	17	729	883	901	133	3034
72	Flinders St- ACMI	18	729	564	535	105	2094
72	Flinders St- ACMI	19	729	379	335	20	3348
72	Flinders St- ACMI	20	729	292	238	24	3645
72	Flinders St- ACMI	21	729	248	196	15	2366
72	Flinders St- ACMI	22	729	289	194	16	2298
72	Flinders St- ACMI	23	726	174	114	5	1711
75	Spring St- Flinders st (West)	0	589	7	4	1	593
75	Spring St- Flinders st (West)	1	456	4	2	1	181
75	Spring St- Flinders st (West)	2	367	3	2	1	38
75	Spring St- Flinders st (West)	3	390	2	2	1	22
75	Spring St- Flinders st (West)	4	499	3	2	1	24
75	Spring St- Flinders st (West)	5	675	10	8	1	160
75	Spring St- Flinders st (West)	6	712	33	28	1	376
75	Spring St- Flinders st (West)	7	717	58	61	6	341
75	Spring St- Flinders st (West)	8	717	102	111	8	209
75	Spring St- Flinders st (West)	9	718	82	80	6	360
75	Spring St- Flinders st (West)	10	717	81	75	4	505
75	Spring St- Flinders st (West)	11	718	90	84	6	422
75	Spring St- Flinders st (West)	12	718	127	126	14	441
75	Spring St- Flinders st (West)	13	718	128	130	3	677
75	Spring St- Flinders st (West)	14	718	112	108	14	2501
75	Spring St- Flinders st (West)	15	718	101	100	10	298
75	Spring St- Flinders st (West)	16	716	115	112	26	331
75	Spring St- Flinders st (West)	17	716	136	134	17	323
75	Spring St- Flinders st (West)	18	716	103	86	6	489
75	Spring St- Flinders st (West)	19	708	65	53	1	426
75	Spring St- Flinders st (West)	20	705	36	29	1	501
75	Spring St- Flinders st (West)	21	665	26	23	1	339
75	Spring St- Flinders st (West)	22	657	34	19	1	567
75	Spring St- Flinders st (West)	23	651	17	10	1	286
76	Macaulay Rd- Bellair St	0	565	4	2	1	90
76	Macaulay Rd- Bellair St	1	417	2	2	1	23
76	Macaulay Rd- Bellair St	2	329	2	1	1	16
76	Macaulay Rd- Bellair St	3	383	2	1	1	11
76	Macaulay Rd- Bellair St	4	321	2	1	1	20
76	Macaulay Rd- Bellair St	5	675	3	3	1	13
76	Macaulay Rd- Bellair St	6	726	16	16	1	47
76	Macaulay Rd- Bellair St	7	729	48	53	1	101
76	Macaulay Rd- Bellair St	8	729	104	113	8	190
76	Macaulay Rd- Bellair St	9	729	104	104	21	198
76	Macaulay Rd- Bellair St	10	729	107	102	21	285
76	Macaulay Rd- Bellair St	11	729	113	108	18	258
76	Macaulay Rd- Bellair St	12	729	128	130	21	241
76	Macaulay Rd- Bellair St	13	729	114	116	15	226
76	Macaulay Rd- Bellair St	14	729	94	95	11	176
76	Macaulay Rd- Bellair St	15	729	114	117	15	209
76	Macaulay Rd- Bellair St	16	729	112	115	10	188
76	Macaulay Rd- Bellair St	17	729	118	124	18	221
76	Macaulay Rd- Bellair St	18	729	96	97	23	284
76	Macaulay Rd- Bellair St	19	729	66	64	10	285
76	Macaulay Rd- Bellair St	20	729	40	37	7	160
76	Macaulay Rd- Bellair St	21	729	22	20	2	76
76	Macaulay Rd- Bellair St	22	728	14	12	1	99
76	Macaulay Rd- Bellair St	23	696	7	5	1	108
77	Harbour Esplanade (West) - Pedestrian path	0	697	42	30	1	2787
77	Harbour Esplanade (West) - Pedestrian path	1	692	18	13	1	991
77	Harbour Esplanade (West) - Pedestrian path	2	676	9	7	1	192
77	Harbour Esplanade (West) - Pedestrian path	3	653	6	5	1	58
77	Harbour Esplanade (West) - Pedestrian path	4	689	6	5	1	42
77	Harbour Esplanade (West) - Pedestrian path	5	693	16	16	1	44
77	Harbour Esplanade (West) - Pedestrian path	6	696	64	64	3	241
77	Harbour Esplanade (West) - Pedestrian path	7	696	185	165	8	10223
77	Harbour Esplanade (West) - Pedestrian path	8	696	248	256	16	3709
77	Harbour Esplanade (West) - Pedestrian path	9	696	212	208	5	1395
77	Harbour Esplanade (West) - Pedestrian path	10	697	208	183	5	1660
77	Harbour Esplanade (West) - Pedestrian path	11	697	229	197	6	2034
77	Harbour Esplanade (West) - Pedestrian path	12	697	316	298	10	2451
77	Harbour Esplanade (West) - Pedestrian path	13	698	283	264	14	2416
77	Harbour Esplanade (West) - Pedestrian path	14	698	250	218	18	2102
77	Harbour Esplanade (West) - Pedestrian path	15	698	284	257	22	1951
77	Harbour Esplanade (West) - Pedestrian path	16	698	331	304	29	1823
77	Harbour Esplanade (West) - Pedestrian path	17	698	440	412	28	3284
77	Harbour Esplanade (West) - Pedestrian path	18	698	463	381	28	5176
77	Harbour Esplanade (West) - Pedestrian path	19	698	396	334	6	5575
77	Harbour Esplanade (West) - Pedestrian path	20	698	330	276	6	5651
77	Harbour Esplanade (West) - Pedestrian path	21	698	246	198	14	4747
77	Harbour Esplanade (West) - Pedestrian path	22	698	209	121	2	3517
77	Harbour Esplanade (West) - Pedestrian path	23	698	111	58	4	3427
79	Flinders St (South)	0	727	168	113	3	910
79	Flinders St (South)	1	725	93	50	4	1310
79	Flinders St (South)	2	722	62	33	4	919
79	Flinders St (South)	3	725	48	28	2	745
79	Flinders St (South)	4	723	38	25	2	602
79	Flinders St (South)	5	723	55	51	9	587
79	Flinders St (South)	6	727	132	124	4	855
79	Flinders St (South)	7	727	269	271	36	691
79	Flinders St (South)	8	727	606	624	20	1347
79	Flinders St (South)	9	727	566	547	14	1535
79	Flinders St (South)	10	727	644	620	13	1954
79	Flinders St (South)	11	727	775	748	17	2423
79	Flinders St (South)	12	728	888	865	2	2218
79	Flinders St (South)	13	727	922	904	13	2166
79	Flinders St (South)	14	727	916	889	41	1834
79	Flinders St (South)	15	727	916	896	17	1649
79	Flinders St (South)	16	726	1010	997	30	1925
79	Flinders St (South)	17	726	1149	1140	24	2361
79	Flinders St (South)	18	726	922	888	14	2241
79	Flinders St (South)	19	726	683	629	7	2131
79	Flinders St (South)	20	726	578	528	4	1862
79	Flinders St (South)	21	726	580	514	6	2985
79	Flinders St (South)	22	726	555	443	4	2690
79	Flinders St (South)	23	726	370	294	15	2278
84	Elizabeth St - Flinders St (East) - New footpath	0	730	235	143	10	5067
84	Elizabeth St - Flinders St (East) - New footpath	1	729	142	76	9	3965
84	Elizabeth St - Flinders St (East) - New footpath	2	727	89	48	5	1136
84	Elizabeth St - Flinders St (East) - New footpath	3	729	63	38	1	835
84	Elizabeth St - Flinders St (East) - New footpath	4	726	51	37	11	451
84	Elizabeth St - Flinders St (East) - New footpath	5	728	79	78	10	262
84	Elizabeth St - Flinders St (East) - New footpath	6	728	280	302	48	543
84	Elizabeth St - Flinders St (East) - New footpath	7	728	645	718	139	1404
84	Elizabeth St - Flinders St (East) - New footpath	8	728	1362	1562	228	2423
84	Elizabeth St - Flinders St (East) - New footpath	9	728	1230	1263	397	2043
84	Elizabeth St - Flinders St (East) - New footpath	10	728	1286	1262	648	2154
84	Elizabeth St - Flinders St (East) - New footpath	11	728	1552	1525	663	2426
84	Elizabeth St - Flinders St (East) - New footpath	12	728	2037	2062	837	2777
84	Elizabeth St - Flinders St (East) - New footpath	13	728	2157	2174	1019	3081
84	Elizabeth St - Flinders St (East) - New footpath	14	728	2094	2080	1102	3204
84	Elizabeth St - Flinders St (East) - New footpath	15	728	2208	2210	1122	3250
84	Elizabeth St - Flinders St (East) - New footpath	16	728	2432	2462	1022	3309
84	Elizabeth St - Flinders St (East) - New footpath	17	728	2791	2906	1266	3963
84	Elizabeth St - Flinders St (East) - New footpath	18	728	2248	2285	1182	3203
84	Elizabeth St - Flinders St (East) - New footpath	19	728	1729	1702	850	3382
84	Elizabeth St - Flinders St (East) - New footpath	20	728	1470	1416	633	3808
84	Elizabeth St - Flinders St (East) - New footpath	21	728	1290	1214	599	4015
84	Elizabeth St - Flinders St (East) - New footpath	22	728	968	867	400	6136
84	Elizabeth St - Flinders St (East) - New footpath	23	728	493	383	117	6528
85	Macaulay Rd (North)	0	662	5	4	1	91
85	Macaulay Rd (North)	1	393	3	2	1	42
85	Macaulay Rd (North)	2	330	2	2	1	27
85	Macaulay Rd (North)	3	284	2	1	1	7
85	Macaulay Rd (North)	4	557	2	2	1	18
85	Macaulay Rd (North)	5	716	6	6	1	22
85	Macaulay Rd (North)	6	728	27	27	1	87
85	Macaulay Rd (North)	7	729	72	83	8	146
85	Macaulay Rd (North)	8	729	149	167	33	261
85	Macaulay Rd (North)	9	729	144	144	30	252
85	Macaulay Rd (North)	10	729	154	145	45	335
85	Macaulay Rd (North)	11	729	176	165	41	400
85	Macaulay Rd (North)	12	729	208	206	26	367
85	Macaulay Rd (North)	13	729	172	168	31	327
85	Macaulay Rd (North)	14	729	142	136	9	299
85	Macaulay Rd (North)	15	729	177	177	13	334
85	Macaulay Rd (North)	16	729	154	154	24	253
85	Macaulay Rd (North)	17	729	178	183	15	306
85	Macaulay Rd (North)	18	729	154	155	17	298
85	Macaulay Rd (North)	19	729	102	99	15	205
85	Macaulay Rd (North)	20	729	60	58	13	151
85	Macaulay Rd (North)	21	729	32	31	2	80
85	Macaulay Rd (North)	22	728	22	18	1	114
85	Macaulay Rd (North)	23	726	13	9	1	245
86	Queensberry St - Errol St (South)	0	646	4	3	1	32
86	Queensberry St - Errol St (South)	1	542	3	2	1	43
86	Queensberry St - Errol St (South)	2	455	2	1	1	19
86	Queensberry St - Errol St (South)	3	372	2	1	1	13
86	Queensberry St - Errol St (South)	4	440	2	1	1	11
86	Queensberry St - Errol St (South)	5	604	3	3	1	11
86	Queensberry St - Errol St (South)	6	718	12	10	1	52
86	Queensberry St - Errol St (South)	7	729	32	33	1	71
86	Queensberry St - Errol St (South)	8	729	66	68	10	128
86	Queensberry St - Errol St (South)	9	729	76	75	14	150
86	Queensberry St - Errol St (South)	10	729	89	86	19	206
86	Queensberry St - Errol St (South)	11	729	103	99	15	223
86	Queensberry St - Errol St (South)	12	729	143	145	25	287
86	Queensberry St - Errol St (South)	13	729	130	131	27	327
86	Queensberry St - Errol St (South)	14	729	102	100	26	524
86	Queensberry St - Errol St (South)	15	729	99	99	17	402
86	Queensberry St - Errol St (South)	16	729	92	93	28	270
86	Queensberry St - Errol St (South)	17	729	102	105	27	337
86	Queensberry St - Errol St (South)	18	729	103	105	36	208
86	Queensberry St - Errol St (South)	19	729	86	85	24	192
86	Queensberry St - Errol St (South)	20	729	67	63	10	158
86	Queensberry St - Errol St (South)	21	729	41	41	5	110
86	Queensberry St - Errol St (South)	22	728	22	20	1	86
86	Queensberry St - Errol St (South)	23	712	10	7	1	58
87	Errol St (West)	0	722	11	8	1	80
87	Errol St (West)	1	674	6	4	1	46
87	Errol St (West)	2	577	4	3	1	15
87	Errol St (West)	3	562	3	2	1	14
87	Errol St (West)	4	621	5	3	1	20
87	Errol St (West)	5	725	8	8	1	30
87	Errol St (West)	6	729	19	20	2	55
87	Errol St (West)	7	729	48	51	6	122
87	Errol St (West)	8	729	115	124	14	229
87	Errol St (West)	9	729	124	123	38	245
87	Errol St (West)	10	729	181	172	38	370
87	Errol St (West)	11	729	194	188	60	351
87	Errol St (West)	12	728	286	285	48	504
87	Errol St (West)	13	728	242	246	41	552
87	Errol St (West)	14	728	192	188	51	590
87	Errol St (West)	15	728	187	187	17	662
87	Errol St (West)	16	728	180	182	39	457
87	Errol St (West)	17	728	202	207	34	520
87	Errol St (West)	18	728	221	222	30	532
87	Errol St (West)	19	729	179	174	32	448
87	Errol St (West)	20	729	129	123	28	365
87	Errol St (West)	21	729	68	63	11	309
87	Errol St (West)	22	729	40	36	6	281
87	Errol St (West)	23	729	24	19	1	118
107	Royal Mint 280 William St	0	729	40	32	2	1153
107	Royal Mint 280 William St	1	727	23	18	1	318
107	Royal Mint 280 William St	2	723	14	11	1	165
107	Royal Mint 280 William St	3	714	9	6	1	68
107	Royal Mint 280 William St	4	717	7	6	1	47
107	Royal Mint 280 William St	5	728	14	14	2	44
107	Royal Mint 280 William St	6	727	35	35	7	107
107	Royal Mint 280 William St	7	727	96	105	8	181
107	Royal Mint 280 William St	8	728	229	276	14	436
107	Royal Mint 280 William St	9	728	220	237	34	394
107	Royal Mint 280 William St	10	728	211	209	23	796
107	Royal Mint 280 William St	11	728	230	231	34	839
107	Royal Mint 280 William St	12	728	308	320	25	717
107	Royal Mint 280 William St	13	728	365	389	37	644
107	Royal Mint 280 William St	14	729	260	262	23	683
107	Royal Mint 280 William St	15	729	230	231	46	850
107	Royal Mint 280 William St	16	729	252	258	19	599
107	Royal Mint 280 William St	17	728	313	328	54	642
107	Royal Mint 280 William St	18	728	240	238	35	686
107	Royal Mint 280 William St	19	728	191	189	14	649
107	Royal Mint 280 William St	20	728	164	161	3	564
107	Royal Mint 280 William St	21	728	133	128	8	1329
107	Royal Mint 280 William St	22	728	104	95	2	628
107	Royal Mint 280 William St	23	728	69	57	4	661
108	William St - Little Lonsdale St (West)	0	702	69	56	8	1295
108	William St - Little Lonsdale St (West)	1	702	38	30	1	611
108	William St - Little Lonsdale St (West)	2	700	26	20	1	255
108	William St - Little Lonsdale St (West)	3	701	19	14	1	184
108	William St - Little Lonsdale St (West)	4	701	16	14	1	155
108	William St - Little Lonsdale St (West)	5	702	60	64	6	136
108	William St - Little Lonsdale St (West)	6	702	173	204	9	363
108	William St - Little Lonsdale St (West)	7	702	530	638	13	1080
108	William St - Little Lonsdale St (West)	8	702	1582	1962	28	3076
108	William St - Little Lonsdale St (West)	9	702	881	1056	27	1870
108	William St - Little Lonsdale St (West)	10	702	501	574	30	1244
108	William St - Little Lonsdale St (West)	11	702	473	526	40	2050
108	William St - Little Lonsdale St (West)	12	702	674	790	44	1325
108	William St - Little Lonsdale St (West)	13	701	807	941	66	1557
108	William St - Little Lonsdale St (West)	14	702	528	592	48	1804
108	William St - Little Lonsdale St (West)	15	702	532	600	39	986
108	William St - Little Lonsdale St (West)	16	702	828	956	55	1663
108	William St - Little Lonsdale St (West)	17	702	1202	1348	26	2325
108	William St - Little Lonsdale St (West)	18	702	554	619	49	1178
108	William St - Little Lonsdale St (West)	19	701	337	348	73	663
108	William St - Little Lonsdale St (West)	20	701	258	262	70	995
108	William St - Little Lonsdale St (West)	21	701	228	224	54	1572
108	William St - Little Lonsdale St (West)	22	701	185	171	47	1221
108	William St - Little Lonsdale St (West)	23	701	125	106	24	1124
109	La Trobe St- William St (South)	0	730	52	43	4	1920
109	La Trobe St- William St (South)	1	730	28	23	4	570
109	La Trobe St- William St (South)	2	728	17	13	1	223
109	La Trobe St- William St (South)	3	727	12	9	1	105
109	La Trobe St- William St (South)	4	726	9	8	1	83
109	La Trobe St- William St (South)	5	729	23	23	2	58
109	La Trobe St- William St (South)	6	729	70	80	4	143
109	La Trobe St- William St (South)	7	729	182	218	7	377
109	La Trobe St- William St (South)	8	729	433	539	9	863
109	La Trobe St- William St (South)	9	729	298	343	27	582
109	La Trobe St- William St (South)	10	729	201	210	27	456
109	La Trobe St- William St (South)	11	729	202	208	25	524
109	La Trobe St- William St (South)	12	729	292	315	24	738
109	La Trobe St- William St (South)	13	728	307	336	31	700
109	La Trobe St- William St (South)	14	728	257	266	59	507
109	La Trobe St- William St (South)	15	728	276	290	30	516
109	La Trobe St- William St (South)	16	728	364	404	55	698
109	La Trobe St- William St (South)	17	728	440	508	49	837
109	La Trobe St- William St (South)	18	728	277	291	40	757
109	La Trobe St- William St (South)	19	728	192	188	22	578
109	La Trobe St- William St (South)	20	728	162	159	25	519
109	La Trobe St- William St (South)	21	728	148	144	42	1262
109	La Trobe St- William St (South)	22	729	125	113	21	991
109	La Trobe St- William St (South)	23	729	94	69	16	937
117	114 Flinders Street Car Park Footpath	0	728	60	37	2	1380
117	114 Flinders Street Car Park Footpath	1	726	33	20	1	628
117	114 Flinders Street Car Park Footpath	2	717	16	11	1	233
117	114 Flinders Street Car Park Footpath	3	696	10	6	1	184
117	114 Flinders Street Car Park Footpath	4	700	7	5	1	125
117	114 Flinders Street Car Park Footpath	5	721	16	15	1	469
117	114 Flinders Street Car Park Footpath	6	726	56	56	1	1037
117	114 Flinders Street Car Park Footpath	7	727	125	134	8	953
117	114 Flinders Street Car Park Footpath	8	727	340	383	41	962
117	114 Flinders Street Car Park Footpath	9	726	268	278	47	1780
117	114 Flinders Street Car Park Footpath	10	726	234	222	39	1997
117	114 Flinders Street Car Park Footpath	11	727	262	250	40	1686
117	114 Flinders Street Car Park Footpath	12	727	382	380	87	2016
117	114 Flinders Street Car Park Footpath	13	727	375	377	67	903
117	114 Flinders Street Car Park Footpath	14	727	325	310	96	1547
117	114 Flinders Street Car Park Footpath	15	727	333	322	87	842
117	114 Flinders Street Car Park Footpath	16	727	417	408	104	1212
117	114 Flinders Street Car Park Footpath	17	727	567	565	102	1552
117	114 Flinders Street Car Park Footpath	18	726	450	408	115	1981
117	114 Flinders Street Car Park Footpath	19	727	309	272	47	1159
117	114 Flinders Street Car Park Footpath	20	727	236	211	30	1858
117	114 Flinders Street Car Park Footpath	21	727	205	176	28	1181
117	114 Flinders Street Car Park Footpath	22	727	271	198	17	3216
117	114 Flinders Street Car Park Footpath	23	727	172	120	10	1576
118	114 Flinders Street Car Park Crossing	0	622	6	4	1	90
118	114 Flinders Street Car Park Crossing	1	480	4	3	1	37
118	114 Flinders Street Car Park Crossing	2	265	3	2	1	18
118	114 Flinders Street Car Park Crossing	3	116	2	1	1	37
118	114 Flinders Street Car Park Crossing	4	88	2	1	1	17
118	114 Flinders Street Car Park Crossing	5	374	1	1	1	11
118	114 Flinders Street Car Park Crossing	6	647	4	4	1	17
118	114 Flinders Street Car Park Crossing	7	717	13	13	1	37
118	114 Flinders Street Car Park Crossing	8	727	32	36	1	85
118	114 Flinders Street Car Park Crossing	9	726	30	29	2	128
118	114 Flinders Street Car Park Crossing	10	726	28	26	5	106
118	114 Flinders Street Car Park Crossing	11	727	31	28	7	129
118	114 Flinders Street Car Park Crossing	12	727	39	36	4	140
118	114 Flinders Street Car Park Crossing	13	727	40	37	8	131
118	114 Flinders Street Car Park Crossing	14	727	40	37	6	268
118	114 Flinders Street Car Park Crossing	15	727	41	38	12	147
118	114 Flinders Street Car Park Crossing	16	727	51	48	9	143
118	114 Flinders Street Car Park Crossing	17	727	66	64	10	171
118	114 Flinders Street Car Park Crossing	18	726	54	46	4	228
118	114 Flinders Street Car Park Crossing	19	727	35	28	2	154
118	114 Flinders Street Car Park Crossing	20	727	21	17	1	120
118	114 Flinders Street Car Park Crossing	21	727	19	14	1	93
118	114 Flinders Street Car Park Crossing	22	726	25	17	1	148
118	114 Flinders Street Car Park Crossing	23	710	18	11	1	129
123	Birrarung Marr East - Batman Ave Bridge Entry	0	129	6	1	1	216
123	Birrarung Marr East - Batman Ave Bridge Entry	1	98	3	1	1	56
123	Birrarung Marr East - Batman Ave Bridge Entry	2	49	2	1	1	34
123	Birrarung Marr East - Batman Ave Bridge Entry	3	40	1	1	1	7
123	Birrarung Marr East - Batman Ave Bridge Entry	4	36	1	1	1	3
123	Birrarung Marr East - Batman Ave Bridge Entry	5	195	2	1	1	12
123	Birrarung Marr East - Batman Ave Bridge Entry	6	547	13	8	1	113
123	Birrarung Marr East - Batman Ave Bridge Entry	7	726	40	35	1	243
123	Birrarung Marr East - Batman Ave Bridge Entry	8	729	52	54	1	141
123	Birrarung Marr East - Batman Ave Bridge Entry	9	726	39	38	1	492
123	Birrarung Marr East - Batman Ave Bridge Entry	10	722	45	35	1	2003
123	Birrarung Marr East - Batman Ave Bridge Entry	11	728	49	43	1	906
123	Birrarung Marr East - Batman Ave Bridge Entry	12	728	90	86	1	671
123	Birrarung Marr East - Batman Ave Bridge Entry	13	728	92	87	1	518
123	Birrarung Marr East - Batman Ave Bridge Entry	14	727	57	53	1	564
123	Birrarung Marr East - Batman Ave Bridge Entry	15	728	53	45	1	465
123	Birrarung Marr East - Batman Ave Bridge Entry	16	729	61	52	1	555
123	Birrarung Marr East - Batman Ave Bridge Entry	17	726	68	54	1	588
123	Birrarung Marr East - Batman Ave Bridge Entry	18	649	52	23	1	795
123	Birrarung Marr East - Batman Ave Bridge Entry	19	540	46	18	1	749
123	Birrarung Marr East - Batman Ave Bridge Entry	20	460	26	6	1	686
123	Birrarung Marr East - Batman Ave Bridge Entry	21	365	9	2	1	326
123	Birrarung Marr East - Batman Ave Bridge Entry	22	347	12	5	1	219
123	Birrarung Marr East - Batman Ave Bridge Entry	23	285	9	3	1	107
124	Birrarung Marr East - Batman Ave Bridge Entry	0	3	2	2	1	2
124	Birrarung Marr East - Batman Ave Bridge Entry	1	2	1	1	1	1
124	Birrarung Marr East - Batman Ave Bridge Entry	2	2	1	1	1	1
124	Birrarung Marr East - Batman Ave Bridge Entry	5	12	1	1	1	2
124	Birrarung Marr East - Batman Ave Bridge Entry	6	122	3	2	1	24
124	Birrarung Marr East - Batman Ave Bridge Entry	7	400	4	2	1	48
124	Birrarung Marr East - Batman Ave Bridge Entry	8	467	5	4	1	44
124	Birrarung Marr East - Batman Ave Bridge Entry	9	480	6	4	1	127
124	Birrarung Marr East - Batman Ave Bridge Entry	10	506	8	4	1	452
124	Birrarung Marr East - Batman Ave Bridge Entry	11	516	8	5	1	247
124	Birrarung Marr East - Batman Ave Bridge Entry	12	542	11	8	1	81
124	Birrarung Marr East - Batman Ave Bridge Entry	13	556	12	10	1	79
124	Birrarung Marr East - Batman Ave Bridge Entry	14	535	8	6	1	79
124	Birrarung Marr East - Batman Ave Bridge Entry	15	535	8	5	1	103
124	Birrarung Marr East - Batman Ave Bridge Entry	16	523	8	6	1	78
124	Birrarung Marr East - Batman Ave Bridge Entry	17	496	9	6	1	82
124	Birrarung Marr East - Batman Ave Bridge Entry	18	315	11	7	1	82
124	Birrarung Marr East - Batman Ave Bridge Entry	19	245	9	6	1	71
124	Birrarung Marr East - Batman Ave Bridge Entry	20	151	7	4	1	153
124	Birrarung Marr East - Batman Ave Bridge Entry	21	21	2	1	1	20
124	Birrarung Marr East - Batman Ave Bridge Entry	22	6	1	1	1	2
124	Birrarung Marr East - Batman Ave Bridge Entry	23	1	1	1	1	1
130	I-Hub 892 Bourke Street	0	475	3	2	1	141
130	I-Hub 892 Bourke Street	1	303	2	1	1	28
130	I-Hub 892 Bourke Street	2	235	2	1	1	9
130	I-Hub 892 Bourke Street	3	178	2	1	1	7
130	I-Hub 892 Bourke Street	4	166	2	1	1	7
130	I-Hub 892 Bourke Street	5	461	2	2	1	14
130	I-Hub 892 Bourke Street	6	673	21	10	1	127
130	I-Hub 892 Bourke Street	7	728	29	26	1	174
130	I-Hub 892 Bourke Street	8	729	49	45	2	164
130	I-Hub 892 Bourke Street	9	729	74	72	5	223
130	I-Hub 892 Bourke Street	10	729	95	94	7	265
130	I-Hub 892 Bourke Street	11	729	104	100	10	898
130	I-Hub 892 Bourke Street	12	729	158	156	11	520
130	I-Hub 892 Bourke Street	13	729	132	133	20	326
130	I-Hub 892 Bourke Street	14	729	109	108	14	282
130	I-Hub 892 Bourke Street	15	729	107	107	16	220
130	I-Hub 892 Bourke Street	16	729	95	95	10	264
130	I-Hub 892 Bourke Street	17	729	93	93	3	523
130	I-Hub 892 Bourke Street	18	713	77	70	1	1088
130	I-Hub 892 Bourke Street	19	699	53	45	1	1154
130	I-Hub 892 Bourke Street	20	693	38	27	1	1126
130	I-Hub 892 Bourke Street	21	690	21	16	1	698
130	I-Hub 892 Bourke Street	22	685	12	9	1	390
130	I-Hub 892 Bourke Street	23	630	6	4	1	150
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	0	679	107	55	8	2183
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	1	679	78	35	2	1308
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	2	676	57	25	1	685
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	3	679	47	21	1	382
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	4	677	34	17	1	242
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	5	678	26	15	1	206
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	6	678	38	36	8	115
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	7	678	77	77	10	198
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	8	679	153	167	16	349
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	9	680	165	162	36	405
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	10	679	200	189	8	910
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	11	679	224	217	48	1042
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	12	679	310	311	2	517
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	13	679	325	325	2	604
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	14	678	255	252	3	827
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	15	677	237	232	64	535
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	16	677	243	241	46	466
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	17	677	260	264	59	502
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	18	677	210	206	47	456
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	19	677	180	171	34	421
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	20	677	174	162	30	600
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	21	678	178	150	38	952
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	22	678	175	132	7	1287
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	23	678	154	98	20	1137
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	0	730	72	59	18	1423
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	1	730	41	33	5	571
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	2	728	24	18	4	236
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	3	729	16	12	1	151
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	4	728	13	10	1	125
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	5	729	19	18	4	75
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	6	729	42	42	6	77
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	7	729	85	88	14	222
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	8	729	194	214	33	429
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	9	729	192	194	37	336
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	10	729	230	231	31	423
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	11	729	246	249	30	488
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	12	729	317	320	38	540
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	13	729	327	329	50	547
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	14	729	277	280	52	473
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	15	729	275	279	65	432
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	16	729	287	292	64	428
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	17	728	333	339	72	546
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	18	729	316	316	68	554
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	19	729	277	278	56	548
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	20	729	239	237	53	767
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	21	729	207	204	76	1651
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	22	729	167	157	54	1054
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	23	729	128	105	27	1417
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	0	726	106	86	26	2423
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	1	726	58	47	12	1273
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	2	724	30	23	5	508
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	3	727	30	27	4	236
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	4	725	41	40	7	177
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	5	726	140	147	25	278
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	6	726	436	490	111	680
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	7	726	773	874	190	1331
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	8	726	783	827	272	1288
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	9	726	761	762	399	1122
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	10	726	801	786	352	1551
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	11	726	837	827	483	1381
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	12	726	1012	1032	393	1618
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	13	726	1003	1020	472	1524
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	14	727	940	930	349	1759
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	15	727	1056	1060	584	1568
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	16	727	1169	1176	502	1683
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	17	727	1242	1249	531	1956
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	18	727	1186	1161	535	2263
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	19	727	874	861	393	1818
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	20	727	705	702	307	1812
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	21	727	636	622	267	1943
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	22	725	503	456	174	2332
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	23	725	264	193	71	2842
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	0	729	161	133	11	2373
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	1	729	92	71	7	1319
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	2	728	50	36	5	508
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	3	730	45	36	4	343
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	4	729	50	43	6	207
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	5	729	97	96	15	214
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	6	729	245	244	40	526
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	7	729	460	473	78	979
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	8	729	575	587	107	1488
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	9	729	595	596	38	1165
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	10	728	670	661	72	1173
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	11	728	698	688	161	1193
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	12	728	795	813	100	1542
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	13	728	740	739	142	1538
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	14	728	720	713	189	1270
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	15	728	866	856	191	1526
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	16	728	957	964	135	1883
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	17	728	1037	1049	202	2060
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	18	728	918	900	168	2312
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	19	728	702	684	106	1799
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	20	728	570	575	4	1567
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	21	728	535	540	1	2061
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	22	727	458	396	53	2234
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	23	728	316	229	39	3517
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	0	729	96	78	7	1807
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	1	729	64	50	6	1120
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	2	727	35	24	2	465
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	3	729	36	31	5	187
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	4	728	39	34	1	133
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	5	729	54	52	2	141
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	6	729	131	131	1	337
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	7	729	299	311	2	884
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	8	729	571	600	16	1887
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	9	729	598	596	21	1468
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	10	729	716	702	58	1420
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	11	729	813	796	33	1718
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	12	729	930	928	32	1848
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	13	729	888	888	26	1673
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	14	729	799	783	32	1922
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	15	729	851	839	42	2573
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	16	729	961	938	58	2821
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	17	729	1015	998	48	2798
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	18	729	776	708	37	2824
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	19	729	537	487	21	2981
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	20	729	351	334	10	1697
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	21	729	322	301	9	2222
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	22	729	329	221	4	2784
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	23	729	231	133	1	3754
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	0	427	6	2	1	147
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	1	321	4	2	1	140
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	2	270	2	2	1	88
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	3	214	2	1	1	17
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	4	225	2	1	1	13
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	5	484	7	3	1	566
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	6	704	48	27	1	1959
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	7	717	152	134	15	5551
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	8	717	269	219	31	8730
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	9	718	223	147	7	10140
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	10	718	193	116	8	6416
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	11	718	201	123	10	6715
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	12	717	274	166	15	8276
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	13	717	236	155	8	4912
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	14	716	227	124	11	5660
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	15	716	236	139	11	4466
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	16	716	318	202	10	7409
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	17	717	360	263	4	7071
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	18	714	408	174	1	11113
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	19	704	207	81	1	4152
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	20	698	62	18	1	1756
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	21	673	32	8	1	3021
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	22	647	166	9	1	8228
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	23	558	64	7	1	3707
137	COM Pole 2353 - Towards the city, NAB Building	0	419	6	2	1	1300
137	COM Pole 2353 - Towards the city, NAB Building	1	240	3	1	1	276
137	COM Pole 2353 - Towards the city, NAB Building	2	186	2	1	1	12
137	COM Pole 2353 - Towards the city, NAB Building	3	148	2	1	1	47
137	COM Pole 2353 - Towards the city, NAB Building	4	158	1	1	1	7
137	COM Pole 2353 - Towards the city, NAB Building	5	425	3	2	1	10
137	COM Pole 2353 - Towards the city, NAB Building	6	664	15	10	1	75
137	COM Pole 2353 - Towards the city, NAB Building	7	725	61	47	1	225
137	COM Pole 2353 - Towards the city, NAB Building	8	727	130	102	1	433
137	COM Pole 2353 - Towards the city, NAB Building	9	727	103	83	4	394
137	COM Pole 2353 - Towards the city, NAB Building	10	727	62	52	4	436
137	COM Pole 2353 - Towards the city, NAB Building	11	727	74	68	5	221
137	COM Pole 2353 - Towards the city, NAB Building	12	727	131	133	3	378
137	COM Pole 2353 - Towards the city, NAB Building	13	727	101	97	6	421
137	COM Pole 2353 - Towards the city, NAB Building	14	727	82	75	8	308
137	COM Pole 2353 - Towards the city, NAB Building	15	727	110	112	6	304
137	COM Pole 2353 - Towards the city, NAB Building	16	728	160	156	10	435
137	COM Pole 2353 - Towards the city, NAB Building	17	727	135	116	3	1163
137	COM Pole 2353 - Towards the city, NAB Building	18	726	56	36	1	997
137	COM Pole 2353 - Towards the city, NAB Building	19	725	41	23	1	1228
137	COM Pole 2353 - Towards the city, NAB Building	20	706	26	13	1	1961
137	COM Pole 2353 - Towards the city, NAB Building	21	704	15	7	1	1999
137	COM Pole 2353 - Towards the city, NAB Building	22	676	14	5	1	1748
137	COM Pole 2353 - Towards the city, NAB Building	23	590	9	3	1	1673
138	COM Pole 1671 - Enterprize Park, Queens Bridge	0	91	2	1	1	50
138	COM Pole 1671 - Enterprize Park, Queens Bridge	1	64	2	1	1	6
138	COM Pole 1671 - Enterprize Park, Queens Bridge	2	49	1	1	1	6
138	COM Pole 1671 - Enterprize Park, Queens Bridge	3	48	1	1	1	6
138	COM Pole 1671 - Enterprize Park, Queens Bridge	4	34	1	1	1	2
138	COM Pole 1671 - Enterprize Park, Queens Bridge	5	48	1	1	1	6
138	COM Pole 1671 - Enterprize Park, Queens Bridge	6	390	2	2	1	14
138	COM Pole 1671 - Enterprize Park, Queens Bridge	7	692	5	4	1	50
138	COM Pole 1671 - Enterprize Park, Queens Bridge	8	724	8	7	1	46
138	COM Pole 1671 - Enterprize Park, Queens Bridge	9	725	9	8	1	66
138	COM Pole 1671 - Enterprize Park, Queens Bridge	10	724	12	10	1	139
138	COM Pole 1671 - Enterprize Park, Queens Bridge	11	726	15	12	1	245
138	COM Pole 1671 - Enterprize Park, Queens Bridge	12	728	21	20	2	112
138	COM Pole 1671 - Enterprize Park, Queens Bridge	13	728	21	19	1	95
138	COM Pole 1671 - Enterprize Park, Queens Bridge	14	727	16	14	1	235
138	COM Pole 1671 - Enterprize Park, Queens Bridge	15	729	15	14	1	129
138	COM Pole 1671 - Enterprize Park, Queens Bridge	16	728	16	15	1	195
138	COM Pole 1671 - Enterprize Park, Queens Bridge	17	726	13	12	1	114
138	COM Pole 1671 - Enterprize Park, Queens Bridge	18	527	11	10	1	42
138	COM Pole 1671 - Enterprize Park, Queens Bridge	19	441	9	8	1	71
138	COM Pole 1671 - Enterprize Park, Queens Bridge	20	352	7	4	1	83
138	COM Pole 1671 - Enterprize Park, Queens Bridge	21	213	2	1	1	25
138	COM Pole 1671 - Enterprize Park, Queens Bridge	22	170	2	1	1	13
138	COM Pole 1671 - Enterprize Park, Queens Bridge	23	145	2	1	1	45
139	COM Pole 1647 - Sandridge Bridge Signal Box	0	705	14	8	1	469
139	COM Pole 1647 - Sandridge Bridge Signal Box	1	650	8	5	1	505
139	COM Pole 1647 - Sandridge Bridge Signal Box	2	555	5	3	1	175
139	COM Pole 1647 - Sandridge Bridge Signal Box	3	511	4	2	1	36
139	COM Pole 1647 - Sandridge Bridge Signal Box	4	510	3	2	1	25
139	COM Pole 1647 - Sandridge Bridge Signal Box	5	664	4	3	1	43
139	COM Pole 1647 - Sandridge Bridge Signal Box	6	726	20	19	1	68
139	COM Pole 1647 - Sandridge Bridge Signal Box	7	729	92	95	2	356
139	COM Pole 1647 - Sandridge Bridge Signal Box	8	729	298	335	6	1137
139	COM Pole 1647 - Sandridge Bridge Signal Box	9	729	124	127	13	532
139	COM Pole 1647 - Sandridge Bridge Signal Box	10	729	82	76	10	250
139	COM Pole 1647 - Sandridge Bridge Signal Box	11	729	89	84	3	265
139	COM Pole 1647 - Sandridge Bridge Signal Box	12	729	122	118	7	292
139	COM Pole 1647 - Sandridge Bridge Signal Box	13	729	136	136	11	276
139	COM Pole 1647 - Sandridge Bridge Signal Box	14	729	108	104	17	266
139	COM Pole 1647 - Sandridge Bridge Signal Box	15	729	112	111	3	280
139	COM Pole 1647 - Sandridge Bridge Signal Box	16	729	160	161	13	311
139	COM Pole 1647 - Sandridge Bridge Signal Box	17	729	244	249	9	531
139	COM Pole 1647 - Sandridge Bridge Signal Box	18	729	126	118	10	349
139	COM Pole 1647 - Sandridge Bridge Signal Box	19	729	77	67	2	522
139	COM Pole 1647 - Sandridge Bridge Signal Box	20	729	64	51	3	307
139	COM Pole 1647 - Sandridge Bridge Signal Box	21	729	52	35	2	746
139	COM Pole 1647 - Sandridge Bridge Signal Box	22	728	39	26	1	517
139	COM Pole 1647 - Sandridge Bridge Signal Box	23	728	26	17	1	242
140	COM Pole 2837 - Boyd Park	0	5	3	1	1	11
140	COM Pole 2837 - Boyd Park	1	7	2	1	1	10
140	COM Pole 2837 - Boyd Park	2	5	2	1	1	8
140	COM Pole 2837 - Boyd Park	3	4	2	1	1	6
140	COM Pole 2837 - Boyd Park	4	3	1	1	1	1
140	COM Pole 2837 - Boyd Park	5	140	5	4	1	19
140	COM Pole 2837 - Boyd Park	6	502	29	26	1	79
140	COM Pole 2837 - Boyd Park	7	722	78	79	1	160
140	COM Pole 2837 - Boyd Park	8	720	165	178	1	316
140	COM Pole 2837 - Boyd Park	9	722	139	145	1	247
140	COM Pole 2837 - Boyd Park	10	721	149	149	2	418
140	COM Pole 2837 - Boyd Park	11	722	158	149	1	564
140	COM Pole 2837 - Boyd Park	12	721	170	168	1	633
140	COM Pole 2837 - Boyd Park	13	721	160	158	2	500
140	COM Pole 2837 - Boyd Park	14	723	155	152	1	415
140	COM Pole 2837 - Boyd Park	15	725	180	185	1	443
140	COM Pole 2837 - Boyd Park	16	725	199	203	7	322
140	COM Pole 2837 - Boyd Park	17	724	207	216	2	410
140	COM Pole 2837 - Boyd Park	18	531	174	199	1	367
140	COM Pole 2837 - Boyd Park	19	425	149	169	1	298
140	COM Pole 2837 - Boyd Park	20	329	74	71	1	258
140	COM Pole 2837 - Boyd Park	21	87	2	1	1	16
140	COM Pole 2837 - Boyd Park	22	34	1	1	1	5
140	COM Pole 2837 - Boyd Park	23	31	2	1	1	21
141	Awning of Nationwide Parking 474 Flinders Street	0	695	91	60	11	1623
141	Awning of Nationwide Parking 474 Flinders Street	1	693	63	36	1	868
141	Awning of Nationwide Parking 474 Flinders Street	2	695	44	24	2	507
141	Awning of Nationwide Parking 474 Flinders Street	3	711	35	19	2	284
141	Awning of Nationwide Parking 474 Flinders Street	4	713	28	19	3	143
141	Awning of Nationwide Parking 474 Flinders Street	5	714	28	23	6	118
141	Awning of Nationwide Parking 474 Flinders Street	6	715	47	46	1	158
141	Awning of Nationwide Parking 474 Flinders Street	7	718	86	89	19	323
141	Awning of Nationwide Parking 474 Flinders Street	8	718	186	198	7	475
141	Awning of Nationwide Parking 474 Flinders Street	9	718	210	208	63	704
141	Awning of Nationwide Parking 474 Flinders Street	10	718	241	231	74	686
141	Awning of Nationwide Parking 474 Flinders Street	11	718	261	252	108	728
141	Awning of Nationwide Parking 474 Flinders Street	12	719	350	348	129	780
141	Awning of Nationwide Parking 474 Flinders Street	13	719	351	344	126	728
141	Awning of Nationwide Parking 474 Flinders Street	14	719	300	293	91	624
141	Awning of Nationwide Parking 474 Flinders Street	15	719	287	277	103	711
141	Awning of Nationwide Parking 474 Flinders Street	16	719	297	282	40	709
141	Awning of Nationwide Parking 474 Flinders Street	17	716	328	322	30	849
141	Awning of Nationwide Parking 474 Flinders Street	18	713	280	261	102	887
141	Awning of Nationwide Parking 474 Flinders Street	19	703	232	212	11	672
141	Awning of Nationwide Parking 474 Flinders Street	20	699	216	198	17	629
141	Awning of Nationwide Parking 474 Flinders Street	21	697	205	182	53	808
141	Awning of Nationwide Parking 474 Flinders Street	22	697	195	147	35	1054
141	Awning of Nationwide Parking 474 Flinders Street	23	694	167	115	23	1081
142	COM Pole 1584 - Hammer Hall Entrance	0	556	34	10	1	3990
142	COM Pole 1584 - Hammer Hall Entrance	1	493	18	6	1	2231
142	COM Pole 1584 - Hammer Hall Entrance	2	416	9	3	1	376
142	COM Pole 1584 - Hammer Hall Entrance	3	375	6	3	1	123
142	COM Pole 1584 - Hammer Hall Entrance	4	344	4	3	1	85
142	COM Pole 1584 - Hammer Hall Entrance	5	568	13	10	1	119
142	COM Pole 1584 - Hammer Hall Entrance	6	691	126	103	1	531
142	COM Pole 1584 - Hammer Hall Entrance	7	719	390	358	59	5795
142	COM Pole 1584 - Hammer Hall Entrance	8	719	529	503	57	6711
142	COM Pole 1584 - Hammer Hall Entrance	9	719	479	395	31	9127
142	COM Pole 1584 - Hammer Hall Entrance	10	721	558	479	9	2145
142	COM Pole 1584 - Hammer Hall Entrance	11	719	709	629	45	2110
142	COM Pole 1584 - Hammer Hall Entrance	12	719	1052	1043	61	2989
142	COM Pole 1584 - Hammer Hall Entrance	13	720	1012	995	17	2722
142	COM Pole 1584 - Hammer Hall Entrance	14	719	814	701	49	2683
142	COM Pole 1584 - Hammer Hall Entrance	15	719	769	644	28	2456
142	COM Pole 1584 - Hammer Hall Entrance	16	720	819	708	38	2477
142	COM Pole 1584 - Hammer Hall Entrance	17	721	929	935	40	2977
142	COM Pole 1584 - Hammer Hall Entrance	18	719	784	759	1	3558
142	COM Pole 1584 - Hammer Hall Entrance	19	701	684	604	1	4431
142	COM Pole 1584 - Hammer Hall Entrance	20	697	432	231	1	4053
142	COM Pole 1584 - Hammer Hall Entrance	21	691	185	69	1	3742
142	COM Pole 1584 - Hammer Hall Entrance	22	676	137	38	1	3809
142	COM Pole 1584 - Hammer Hall Entrance	23	643	75	21	1	2858
143	Mounted on Toilet - Spencer Street, Batman Park	0	722	138	94	18	2518
143	Mounted on Toilet - Spencer Street, Batman Park	1	722	90	61	6	1455
143	Mounted on Toilet - Spencer Street, Batman Park	2	720	58	37	7	658
143	Mounted on Toilet - Spencer Street, Batman Park	3	722	42	27	2	431
143	Mounted on Toilet - Spencer Street, Batman Park	4	720	34	30	6	197
143	Mounted on Toilet - Spencer Street, Batman Park	5	720	41	39	5	283
143	Mounted on Toilet - Spencer Street, Batman Park	6	720	109	103	9	620
143	Mounted on Toilet - Spencer Street, Batman Park	7	720	199	182	28	866
143	Mounted on Toilet - Spencer Street, Batman Park	8	719	349	324	44	1593
143	Mounted on Toilet - Spencer Street, Batman Park	9	719	335	297	34	1559
143	Mounted on Toilet - Spencer Street, Batman Park	10	722	361	314	33	1995
143	Mounted on Toilet - Spencer Street, Batman Park	11	724	393	350	8	1824
143	Mounted on Toilet - Spencer Street, Batman Park	12	724	436	392	48	1582
143	Mounted on Toilet - Spencer Street, Batman Park	13	724	443	408	59	1704
143	Mounted on Toilet - Spencer Street, Batman Park	14	723	439	389	80	1761
143	Mounted on Toilet - Spencer Street, Batman Park	15	723	464	418	84	1699
143	Mounted on Toilet - Spencer Street, Batman Park	16	722	515	468	139	1699
143	Mounted on Toilet - Spencer Street, Batman Park	17	722	602	562	145	2544
143	Mounted on Toilet - Spencer Street, Batman Park	18	722	518	458	97	2584
143	Mounted on Toilet - Spencer Street, Batman Park	19	721	398	356	40	1991
143	Mounted on Toilet - Spencer Street, Batman Park	20	721	348	314	28	1569
143	Mounted on Toilet - Spencer Street, Batman Park	21	721	343	300	99	1403
143	Mounted on Toilet - Spencer Street, Batman Park	22	721	333	254	37	1678
143	Mounted on Toilet - Spencer Street, Batman Park	23	721	260	169	20	2054
161	Birrarung Marr - COM - Pole 1109	0	432	34	5	1	2446
161	Birrarung Marr - COM - Pole 1109	1	343	16	4	1	1350
161	Birrarung Marr - COM - Pole 1109	2	297	9	3	1	510
161	Birrarung Marr - COM - Pole 1109	3	297	10	3	1	920
161	Birrarung Marr - COM - Pole 1109	4	320	10	3	1	1635
161	Birrarung Marr - COM - Pole 1109	5	490	14	8	1	669
161	Birrarung Marr - COM - Pole 1109	6	706	73	52	1	2121
161	Birrarung Marr - COM - Pole 1109	7	729	205	184	13	5454
161	Birrarung Marr - COM - Pole 1109	8	728	323	292	37	7482
161	Birrarung Marr - COM - Pole 1109	9	729	296	198	11	6515
161	Birrarung Marr - COM - Pole 1109	10	729	350	184	2	4927
161	Birrarung Marr - COM - Pole 1109	11	729	348	196	1	6117
161	Birrarung Marr - COM - Pole 1109	12	729	442	313	25	8880
161	Birrarung Marr - COM - Pole 1109	13	729	423	310	3	4503
161	Birrarung Marr - COM - Pole 1109	14	729	362	212	8	4125
161	Birrarung Marr - COM - Pole 1109	15	729	378	216	1	4187
161	Birrarung Marr - COM - Pole 1109	16	729	501	277	3	6337
161	Birrarung Marr - COM - Pole 1109	17	729	571	350	22	5684
161	Birrarung Marr - COM - Pole 1109	18	719	619	248	1	6273
161	Birrarung Marr - COM - Pole 1109	19	695	395	161	1	5672
161	Birrarung Marr - COM - Pole 1109	20	676	186	54	1	5374
161	Birrarung Marr - COM - Pole 1109	21	619	135	21	1	4834
161	Birrarung Marr - COM - Pole 1109	22	607	330	22	1	8220
161	Birrarung Marr - COM - Pole 1109	23	560	187	14	1	4791
162	iHub 489 Elizabeth Street	0	729	111	99	3	568
162	iHub 489 Elizabeth Street	1	730	76	67	1	514
162	iHub 489 Elizabeth Street	2	728	53	43	2	262
162	iHub 489 Elizabeth Street	3	729	40	31	2	225
162	iHub 489 Elizabeth Street	4	728	33	28	5	138
162	iHub 489 Elizabeth Street	5	729	37	34	5	130
162	iHub 489 Elizabeth Street	6	729	86	83	14	232
162	iHub 489 Elizabeth Street	7	729	192	193	37	494
162	iHub 489 Elizabeth Street	8	729	389	381	27	1092
162	iHub 489 Elizabeth Street	9	728	507	517	79	997
162	iHub 489 Elizabeth Street	10	728	751	751	141	1417
162	iHub 489 Elizabeth Street	11	728	1004	987	156	2022
162	iHub 489 Elizabeth Street	12	728	1354	1389	95	2537
162	iHub 489 Elizabeth Street	13	728	1350	1380	161	2823
162	iHub 489 Elizabeth Street	14	729	1136	1091	13	2832
162	iHub 489 Elizabeth Street	15	729	969	901	167	2155
162	iHub 489 Elizabeth Street	16	729	740	711	79	1684
162	iHub 489 Elizabeth Street	17	729	667	652	124	1283
162	iHub 489 Elizabeth Street	18	729	636	591	140	1890
162	iHub 489 Elizabeth Street	19	729	570	525	90	2216
162	iHub 489 Elizabeth Street	20	729	462	426	27	1550
162	iHub 489 Elizabeth Street	21	728	375	348	4	1047
162	iHub 489 Elizabeth Street	22	729	260	248	4	604
162	iHub 489 Elizabeth Street	23	729	173	161	1	468
164	I-Hub 526 La Trobe Street (Footpath)	0	720	27	21	1	1777
164	I-Hub 526 La Trobe Street (Footpath)	1	711	12	9	1	485
164	I-Hub 526 La Trobe Street (Footpath)	2	678	6	5	1	122
164	I-Hub 526 La Trobe Street (Footpath)	3	658	5	4	1	53
164	I-Hub 526 La Trobe Street (Footpath)	4	665	4	3	1	32
164	I-Hub 526 La Trobe Street (Footpath)	5	718	10	9	1	26
164	I-Hub 526 La Trobe Street (Footpath)	6	720	39	43	3	78
164	I-Hub 526 La Trobe Street (Footpath)	7	720	87	98	10	219
164	I-Hub 526 La Trobe Street (Footpath)	8	720	146	165	18	282
164	I-Hub 526 La Trobe Street (Footpath)	9	720	144	146	22	436
164	I-Hub 526 La Trobe Street (Footpath)	10	721	152	152	15	600
164	I-Hub 526 La Trobe Street (Footpath)	11	721	163	163	9	454
164	I-Hub 526 La Trobe Street (Footpath)	12	721	198	199	18	487
164	I-Hub 526 La Trobe Street (Footpath)	13	721	197	198	29	382
164	I-Hub 526 La Trobe Street (Footpath)	14	721	183	182	8	415
164	I-Hub 526 La Trobe Street (Footpath)	15	721	202	202	8	454
164	I-Hub 526 La Trobe Street (Footpath)	16	721	232	234	12	438
164	I-Hub 526 La Trobe Street (Footpath)	17	721	250	258	49	708
164	I-Hub 526 La Trobe Street (Footpath)	18	721	210	208	21	576
164	I-Hub 526 La Trobe Street (Footpath)	19	721	159	155	21	448
164	I-Hub 526 La Trobe Street (Footpath)	20	721	130	128	14	716
164	I-Hub 526 La Trobe Street (Footpath)	21	721	110	105	28	1138
164	I-Hub 526 La Trobe Street (Footpath)	22	721	100	81	9	1208
164	I-Hub 526 La Trobe Street (Footpath)	23	721	67	45	3	1010
165	475 Spencer Street	0	682	9	6	1	186
165	475 Spencer Street	1	633	5	4	1	102
165	475 Spencer Street	2	557	4	3	1	50
165	475 Spencer Street	3	499	3	2	1	21
165	475 Spencer Street	4	505	3	2	1	13
165	475 Spencer Street	5	620	4	3	1	17
165	475 Spencer Street	6	714	12	11	1	37
165	475 Spencer Street	7	720	35	37	1	67
165	475 Spencer Street	8	720	61	67	3	162
165	475 Spencer Street	9	720	53	53	7	139
165	475 Spencer Street	10	720	59	56	8	176
165	475 Spencer Street	11	720	64	62	21	171
165	475 Spencer Street	12	720	79	77	13	490
165	475 Spencer Street	13	720	76	74	19	364
165	475 Spencer Street	14	720	69	66	16	183
165	475 Spencer Street	15	721	75	73	16	227
165	475 Spencer Street	16	721	87	85	24	220
165	475 Spencer Street	17	720	99	98	17	355
165	475 Spencer Street	18	721	82	77	11	484
165	475 Spencer Street	19	721	63	59	3	543
165	475 Spencer Street	20	721	47	45	1	232
165	475 Spencer Street	21	721	35	32	1	166
165	475 Spencer Street	22	719	33	22	1	334
165	475 Spencer Street	23	714	22	12	1	453
166	484 Spencer Street	0	646	5	4	1	139
166	484 Spencer Street	1	572	4	3	1	65
166	484 Spencer Street	2	485	3	2	1	24
166	484 Spencer Street	3	395	2	2	1	17
166	484 Spencer Street	4	471	2	2	1	10
166	484 Spencer Street	5	608	4	3	1	24
166	484 Spencer Street	6	671	11	10	1	58
166	484 Spencer Street	7	676	26	27	1	65
166	484 Spencer Street	8	677	61	65	3	114
166	484 Spencer Street	9	677	69	68	7	146
166	484 Spencer Street	10	678	75	73	6	168
166	484 Spencer Street	11	678	89	87	7	212
166	484 Spencer Street	12	678	110	110	14	243
166	484 Spencer Street	13	678	109	109	13	206
166	484 Spencer Street	14	678	99	97	18	354
166	484 Spencer Street	15	678	102	101	12	288
166	484 Spencer Street	16	679	113	113	6	298
166	484 Spencer Street	17	679	135	139	13	220
166	484 Spencer Street	18	678	124	122	7	310
166	484 Spencer Street	19	678	99	95	17	210
166	484 Spencer Street	20	678	30	28	3	89
166	484 Spencer Street	21	678	17	16	2	104
166	484 Spencer Street	22	676	15	12	1	145
166	484 Spencer Street	23	666	10	7	1	117
167	I-Hub 526 La Trobe Street (Crossing)	0	705	9	7	1	196
167	I-Hub 526 La Trobe Street (Crossing)	1	669	6	4	1	115
167	I-Hub 526 La Trobe Street (Crossing)	2	598	4	3	1	45
167	I-Hub 526 La Trobe Street (Crossing)	3	569	3	2	1	38
167	I-Hub 526 La Trobe Street (Crossing)	4	589	3	2	1	18
167	I-Hub 526 La Trobe Street (Crossing)	5	679	5	5	1	17
167	I-Hub 526 La Trobe Street (Crossing)	6	707	18	16	1	60
167	I-Hub 526 La Trobe Street (Crossing)	7	716	44	43	1	128
167	I-Hub 526 La Trobe Street (Crossing)	8	720	81	72	1	218
167	I-Hub 526 La Trobe Street (Crossing)	9	720	80	82	2	168
167	I-Hub 526 La Trobe Street (Crossing)	10	720	79	80	4	217
167	I-Hub 526 La Trobe Street (Crossing)	11	721	80	82	5	207
167	I-Hub 526 La Trobe Street (Crossing)	12	721	85	81	3	281
167	I-Hub 526 La Trobe Street (Crossing)	13	721	65	47	1	280
167	I-Hub 526 La Trobe Street (Crossing)	14	721	57	43	1	262
167	I-Hub 526 La Trobe Street (Crossing)	15	720	74	71	1	256
167	I-Hub 526 La Trobe Street (Crossing)	16	721	91	91	1	221
167	I-Hub 526 La Trobe Street (Crossing)	17	721	111	106	2	284
167	I-Hub 526 La Trobe Street (Crossing)	18	721	96	91	2	297
167	I-Hub 526 La Trobe Street (Crossing)	19	721	72	60	1	228
167	I-Hub 526 La Trobe Street (Crossing)	20	720	50	44	1	276
167	I-Hub 526 La Trobe Street (Crossing)	21	721	33	33	1	203
167	I-Hub 526 La Trobe Street (Crossing)	22	720	28	26	1	249
167	I-Hub 526 La Trobe Street (Crossing)	23	715	18	15	1	215
179	61-67 Power Street Southbank	0	593	19	16	1	297
179	61-67 Power Street Southbank	1	585	11	9	1	152
179	61-67 Power Street Southbank	2	557	8	6	1	96
179	61-67 Power Street Southbank	3	554	6	4	1	50
179	61-67 Power Street Southbank	4	569	5	4	1	38
179	61-67 Power Street Southbank	5	588	9	9	1	40
179	61-67 Power Street Southbank	6	592	22	23	1	75
179	61-67 Power Street Southbank	7	592	44	46	6	77
179	61-67 Power Street Southbank	8	592	79	86	15	129
179	61-67 Power Street Southbank	9	592	88	89	30	144
179	61-67 Power Street Southbank	10	593	96	94	37	167
179	61-67 Power Street Southbank	11	593	103	101	41	182
179	61-67 Power Street Southbank	12	593	111	110	35	195
179	61-67 Power Street Southbank	13	593	109	108	44	181
179	61-67 Power Street Southbank	14	593	107	105	48	179
179	61-67 Power Street Southbank	15	593	112	111	55	182
179	61-67 Power Street Southbank	16	593	122	122	41	255
179	61-67 Power Street Southbank	17	593	147	147	63	311
179	61-67 Power Street Southbank	18	593	152	151	76	297
179	61-67 Power Street Southbank	19	593	136	134	45	261
179	61-67 Power Street Southbank	20	593	119	118	36	330
179	61-67 Power Street Southbank	21	593	105	102	37	288
179	61-67 Power Street Southbank	22	593	83	78	27	318
179	61-67 Power Street Southbank	23	593	42	37	9	271
180	Pumping Station No.2, 330 Macaulay Road	0	279	3	2	1	34
180	Pumping Station No.2, 330 Macaulay Road	1	166	3	1	1	39
180	Pumping Station No.2, 330 Macaulay Road	2	113	2	1	1	11
180	Pumping Station No.2, 330 Macaulay Road	3	92	2	1	1	29
180	Pumping Station No.2, 330 Macaulay Road	4	120	1	1	1	4
180	Pumping Station No.2, 330 Macaulay Road	5	410	4	3	1	18
180	Pumping Station No.2, 330 Macaulay Road	6	493	20	17	1	72
180	Pumping Station No.2, 330 Macaulay Road	7	506	69	76	6	152
180	Pumping Station No.2, 330 Macaulay Road	8	506	127	141	11	297
180	Pumping Station No.2, 330 Macaulay Road	9	509	82	79	4	189
180	Pumping Station No.2, 330 Macaulay Road	10	510	72	70	12	170
180	Pumping Station No.2, 330 Macaulay Road	11	512	77	70	9	240
180	Pumping Station No.2, 330 Macaulay Road	12	512	87	83	13	234
180	Pumping Station No.2, 330 Macaulay Road	13	512	82	76	14	215
180	Pumping Station No.2, 330 Macaulay Road	14	512	85	81	16	208
180	Pumping Station No.2, 330 Macaulay Road	15	512	88	83	28	222
180	Pumping Station No.2, 330 Macaulay Road	16	512	106	101	18	231
180	Pumping Station No.2, 330 Macaulay Road	17	511	121	124	20	242
180	Pumping Station No.2, 330 Macaulay Road	18	511	60	52	3	177
180	Pumping Station No.2, 330 Macaulay Road	19	511	36	19	1	154
180	Pumping Station No.2, 330 Macaulay Road	20	508	19	10	1	93
180	Pumping Station No.2, 330 Macaulay Road	21	500	10	8	1	58
180	Pumping Station No.2, 330 Macaulay Road	22	476	6	5	1	40
180	Pumping Station No.2, 330 Macaulay Road	23	416	4	3	1	69
181	368 Elizabeth Street	0	496	351	299	120	1370
181	368 Elizabeth Street	1	496	225	189	72	1233
181	368 Elizabeth Street	2	495	142	112	36	778
181	368 Elizabeth Street	3	496	97	70	22	437
181	368 Elizabeth Street	4	495	72	58	21	288
181	368 Elizabeth Street	5	495	81	79	36	335
181	368 Elizabeth Street	6	495	177	182	51	367
181	368 Elizabeth Street	7	495	352	373	78	829
181	368 Elizabeth Street	8	496	700	738	166	1723
181	368 Elizabeth Street	9	496	782	768	315	1304
181	368 Elizabeth Street	10	496	978	978	342	1471
181	368 Elizabeth Street	11	496	1229	1216	473	1949
181	368 Elizabeth Street	12	496	1651	1650	495	2410
181	368 Elizabeth Street	13	496	1781	1777	477	2883
181	368 Elizabeth Street	14	496	1705	1671	535	2990
181	368 Elizabeth Street	15	496	1772	1762	687	2725
181	368 Elizabeth Street	16	496	1900	1931	106	2659
181	368 Elizabeth Street	17	495	2102	2108	851	3202
181	368 Elizabeth Street	18	495	1992	1993	827	2969
181	368 Elizabeth Street	19	496	1726	1706	687	2631
181	368 Elizabeth Street	20	496	1468	1452	515	2454
181	368 Elizabeth Street	21	496	1240	1208	614	2149
181	368 Elizabeth Street	22	496	936	880	423	1954
181	368 Elizabeth Street	23	496	604	542	257	1371
182	163 King Street	0	480	177	116	41	1543
182	163 King Street	1	480	128	77	17	1279
182	163 King Street	2	479	97	54	10	702
182	163 King Street	3	480	79	41	8	481
182	163 King Street	4	479	64	37	8	351
182	163 King Street	5	479	58	51	21	388
182	163 King Street	6	479	74	74	25	140
182	163 King Street	7	479	119	117	25	249
182	163 King Street	8	480	249	274	17	554
182	163 King Street	9	480	254	252	37	470
182	163 King Street	10	480	306	302	80	529
182	163 King Street	11	480	361	356	105	628
182	163 King Street	12	480	572	604	108	994
182	163 King Street	13	480	577	600	130	1002
182	163 King Street	14	480	418	412	152	665
182	163 King Street	15	480	390	390	175	588
182	163 King Street	16	480	403	404	136	782
182	163 King Street	17	480	529	542	192	811
182	163 King Street	18	480	548	544	188	1142
182	163 King Street	19	480	519	509	151	1044
182	163 King Street	20	480	466	444	136	1054
182	163 King Street	21	480	404	374	136	1129
182	163 King Street	22	480	341	281	107	1544
182	163 King Street	23	480	268	188	65	2307
184	124 Elizabeth Street	0	403	136	86	23	1748
184	124 Elizabeth Street	1	403	97	59	18	1051
184	124 Elizabeth Street	2	402	64	36	11	660
184	124 Elizabeth Street	3	403	46	28	6	388
184	124 Elizabeth Street	4	402	35	28	9	154
184	124 Elizabeth Street	5	402	52	51	16	189
184	124 Elizabeth Street	6	402	107	107	31	222
184	124 Elizabeth Street	7	402	217	227	70	625
184	124 Elizabeth Street	8	402	545	596	151	959
184	124 Elizabeth Street	9	402	773	772	307	1228
184	124 Elizabeth Street	10	403	1094	1074	545	1768
184	124 Elizabeth Street	11	403	1505	1480	789	2538
184	124 Elizabeth Street	12	403	2159	2161	879	3209
184	124 Elizabeth Street	13	403	2378	2391	1086	3848
184	124 Elizabeth Street	14	403	2087	2039	1003	3382
184	124 Elizabeth Street	15	403	2030	1989	716	3519
184	124 Elizabeth Street	16	403	2004	1988	779	3386
184	124 Elizabeth Street	17	403	2024	2037	978	3060
184	124 Elizabeth Street	18	403	1535	1517	719	2542
184	124 Elizabeth Street	19	403	1159	1092	460	2332
184	124 Elizabeth Street	20	403	901	850	212	2419
184	124 Elizabeth Street	21	403	684	628	17	2332
184	124 Elizabeth Street	22	403	448	368	12	2182
184	124 Elizabeth Street	23	403	270	195	32	1928
185	197 Elizabeth Street	0	396	204	134	53	1838
185	197 Elizabeth Street	1	396	127	84	31	1306
185	197 Elizabeth Street	2	396	83	52	3	549
185	197 Elizabeth Street	3	397	64	38	6	387
185	197 Elizabeth Street	4	396	47	35	10	233
185	197 Elizabeth Street	5	396	51	48	16	167
185	197 Elizabeth Street	6	394	109	111	25	309
185	197 Elizabeth Street	7	394	262	289	69	675
185	197 Elizabeth Street	8	394	621	702	104	1404
185	197 Elizabeth Street	9	394	669	691	226	1246
185	197 Elizabeth Street	10	394	784	765	301	1565
185	197 Elizabeth Street	11	395	1062	1051	378	1781
185	197 Elizabeth Street	12	395	1566	1576	455	2212
185	197 Elizabeth Street	13	395	1717	1740	565	2439
185	197 Elizabeth Street	14	395	1521	1502	477	2379
185	197 Elizabeth Street	15	394	1477	1466	460	2442
185	197 Elizabeth Street	16	394	1462	1470	528	2180
185	197 Elizabeth Street	17	394	1580	1638	736	2530
185	197 Elizabeth Street	18	393	1275	1289	540	1908
185	197 Elizabeth Street	19	394	1090	1056	320	1894
185	197 Elizabeth Street	20	394	958	924	307	1747
185	197 Elizabeth Street	21	394	789	748	304	1718
185	197 Elizabeth Street	22	395	542	456	166	2026
185	197 Elizabeth Street	23	397	346	253	73	1316
187	RMIT Building 22 - 330 Swanston Street	0	289	43	35	4	226
187	RMIT Building 22 - 330 Swanston Street	1	289	23	18	1	170
187	RMIT Building 22 - 330 Swanston Street	2	286	15	11	1	93
187	RMIT Building 22 - 330 Swanston Street	3	277	11	7	1	49
187	RMIT Building 22 - 330 Swanston Street	4	279	6	4	1	26
187	RMIT Building 22 - 330 Swanston Street	5	288	10	10	1	26
187	RMIT Building 22 - 330 Swanston Street	6	287	48	43	1	122
187	RMIT Building 22 - 330 Swanston Street	7	288	136	122	10	394
187	RMIT Building 22 - 330 Swanston Street	8	288	380	360	24	1025
187	RMIT Building 22 - 330 Swanston Street	9	288	370	340	42	1774
187	RMIT Building 22 - 330 Swanston Street	10	289	373	307	41	2718
187	RMIT Building 22 - 330 Swanston Street	11	289	414	353	69	1574
187	RMIT Building 22 - 330 Swanston Street	12	290	598	526	71	1801
187	RMIT Building 22 - 330 Swanston Street	13	290	540	472	66	1695
187	RMIT Building 22 - 330 Swanston Street	14	290	514	452	79	1502
187	RMIT Building 22 - 330 Swanston Street	15	291	506	467	111	1278
187	RMIT Building 22 - 330 Swanston Street	16	290	569	504	97	1346
187	RMIT Building 22 - 330 Swanston Street	17	290	560	540	10	1248
187	RMIT Building 22 - 330 Swanston Street	18	289	337	319	28	1071
187	RMIT Building 22 - 330 Swanston Street	19	290	256	240	4	1005
187	RMIT Building 22 - 330 Swanston Street	20	290	181	183	4	553
187	RMIT Building 22 - 330 Swanston Street	21	289	135	134	3	293
187	RMIT Building 22 - 330 Swanston Street	22	289	108	103	4	269
187	RMIT Building 22 - 330 Swanston Street	23	289	77	67	1	278
188	RMIT Building 51 - 80-92 Victoria Street	0	119	1	1	0	4
188	RMIT Building 51 - 80-92 Victoria Street	1	35	1	1	1	4
188	RMIT Building 51 - 80-92 Victoria Street	2	66	1	1	1	1
188	RMIT Building 51 - 80-92 Victoria Street	3	19	1	1	1	2
188	RMIT Building 51 - 80-92 Victoria Street	4	12	1	1	1	2
188	RMIT Building 51 - 80-92 Victoria Street	5	130	5	2	1	25
188	RMIT Building 51 - 80-92 Victoria Street	6	247	19	9	1	79
188	RMIT Building 51 - 80-92 Victoria Street	7	291	62	66	1	161
188	RMIT Building 51 - 80-92 Victoria Street	8	291	183	128	4	557
188	RMIT Building 51 - 80-92 Victoria Street	9	291	156	129	1	455
188	RMIT Building 51 - 80-92 Victoria Street	10	292	204	124	13	649
188	RMIT Building 51 - 80-92 Victoria Street	11	292	183	111	10	1284
188	RMIT Building 51 - 80-92 Victoria Street	12	292	262	134	16	1376
188	RMIT Building 51 - 80-92 Victoria Street	13	292	219	138	20	1031
188	RMIT Building 51 - 80-92 Victoria Street	14	292	215	128	16	774
188	RMIT Building 51 - 80-92 Victoria Street	15	292	185	116	13	556
188	RMIT Building 51 - 80-92 Victoria Street	16	292	184	128	13	590
188	RMIT Building 51 - 80-92 Victoria Street	17	292	160	123	7	520
188	RMIT Building 51 - 80-92 Victoria Street	18	291	73	61	1	328
188	RMIT Building 51 - 80-92 Victoria Street	19	288	51	49	1	260
188	RMIT Building 51 - 80-92 Victoria Street	20	280	22	10	1	148
188	RMIT Building 51 - 80-92 Victoria Street	21	259	4	3	1	15
188	RMIT Building 51 - 80-92 Victoria Street	22	203	3	2	1	18
188	RMIT Building 51 - 80-92 Victoria Street	23	118	2	1	1	14
209	Flinders Underpass - Walkway	0	730	206	130	26	1221
209	Flinders Underpass - Walkway	1	730	103	57	7	523
209	Flinders Underpass - Walkway	2	728	56	32	5	749
209	Flinders Underpass - Walkway	3	730	35	21	2	582
209	Flinders Underpass - Walkway	4	729	26	21	5	244
209	Flinders Underpass - Walkway	5	729	40	40	11	169
209	Flinders Underpass - Walkway	6	729	123	133	29	238
209	Flinders Underpass - Walkway	7	729	344	382	71	638
209	Flinders Underpass - Walkway	8	729	855	960	119	1643
209	Flinders Underpass - Walkway	9	729	698	711	281	1145
209	Flinders Underpass - Walkway	10	729	708	700	314	1223
209	Flinders Underpass - Walkway	11	729	880	863	358	1578
209	Flinders Underpass - Walkway	12	729	1230	1237	392	1957
209	Flinders Underpass - Walkway	13	729	1267	1272	441	1914
209	Flinders Underpass - Walkway	14	729	1155	1121	434	1925
209	Flinders Underpass - Walkway	15	729	1161	1135	438	1950
209	Flinders Underpass - Walkway	16	729	1280	1271	602	2082
209	Flinders Underpass - Walkway	17	729	1611	1635	658	2756
209	Flinders Underpass - Walkway	18	729	1313	1289	616	2239
209	Flinders Underpass - Walkway	19	729	1068	1026	327	2268
209	Flinders Underpass - Walkway	20	729	962	909	101	2768
209	Flinders Underpass - Walkway	21	729	891	786	62	3935
209	Flinders Underpass - Walkway	22	729	684	562	54	3617
209	Flinders Underpass - Walkway	23	729	410	311	82	3365
\.


--
-- Data for Name: minute_count; Type: TABLE DATA; Schema: serving; Owner: -
--

COPY serving.minute_count (location_id, sensing_datetime, direction_1, direction_2, total_of_direction) FROM stdin;
1	2026-08-03 23:56:00+10	1	0	1
1	2026-08-03 23:58:00+10	2	0	2
1	2026-08-03 23:59:00+10	0	2	2
1	2026-08-04 00:07:00+10	0	1	1
1	2026-08-04 00:15:00+10	1	0	1
1	2026-08-04 00:26:00+10	0	1	1
1	2026-08-04 00:30:00+10	0	1	1
1	2026-08-04 00:33:00+10	1	2	3
1	2026-08-04 00:58:00+10	1	1	2
1	2026-08-04 01:01:00+10	1	2	3
1	2026-08-04 01:02:00+10	0	1	1
1	2026-08-04 01:05:00+10	0	1	1
1	2026-08-04 01:24:00+10	1	0	1
1	2026-08-04 01:25:00+10	0	1	1
1	2026-08-04 01:35:00+10	0	1	1
1	2026-08-04 01:49:00+10	0	1	1
1	2026-08-04 02:42:00+10	1	0	1
1	2026-08-04 03:27:00+10	0	1	1
1	2026-08-04 03:34:00+10	0	2	2
1	2026-08-04 04:44:00+10	0	1	1
1	2026-08-04 04:50:00+10	1	0	1
1	2026-08-04 05:16:00+10	1	0	1
1	2026-08-04 05:50:00+10	1	0	1
1	2026-08-04 06:11:00+10	1	0	1
1	2026-08-04 06:13:00+10	1	1	2
1	2026-08-04 06:18:00+10	1	0	1
1	2026-08-04 06:20:00+10	1	0	1
1	2026-08-04 06:35:00+10	0	1	1
1	2026-08-04 06:52:00+10	1	0	1
1	2026-08-04 06:55:00+10	2	2	4
1	2026-08-04 06:58:00+10	0	1	1
1	2026-08-04 07:00:00+10	2	2	4
1	2026-08-04 07:12:00+10	1	0	1
1	2026-08-04 07:14:00+10	1	0	1
1	2026-08-04 07:16:00+10	0	1	1
1	2026-08-04 07:28:00+10	1	2	3
1	2026-08-04 07:30:00+10	1	8	9
1	2026-08-04 07:48:00+10	5	3	8
1	2026-08-04 07:51:00+10	2	7	9
1	2026-08-04 07:52:00+10	1	3	4
1	2026-08-04 07:55:00+10	1	0	1
1	2026-08-04 08:05:00+10	1	2	3
1	2026-08-04 08:06:00+10	1	4	5
1	2026-08-04 08:09:00+10	0	5	5
1	2026-08-04 08:11:00+10	1	8	9
1	2026-08-04 08:13:00+10	1	5	6
1	2026-08-04 08:15:00+10	2	3	5
1	2026-08-04 08:20:00+10	4	4	8
1	2026-08-04 08:21:00+10	3	2	5
1	2026-08-04 08:23:00+10	2	4	6
1	2026-08-04 08:26:00+10	3	2	5
1	2026-08-04 08:27:00+10	5	2	7
1	2026-08-04 08:28:00+10	1	3	4
1	2026-08-04 08:32:00+10	3	6	9
1	2026-08-04 08:35:00+10	3	6	9
1	2026-08-04 08:37:00+10	3	11	14
1	2026-08-04 08:42:00+10	3	5	8
1	2026-08-04 08:50:00+10	2	8	10
1	2026-08-04 08:51:00+10	7	4	11
1	2026-08-04 08:54:00+10	2	2	4
1	2026-08-04 08:56:00+10	2	5	7
1	2026-08-04 08:58:00+10	2	2	4
1	2026-08-04 09:01:00+10	5	1	6
1	2026-08-04 09:02:00+10	6	7	13
1	2026-08-04 09:04:00+10	2	3	5
1	2026-08-04 09:05:00+10	4	4	8
1	2026-08-04 09:07:00+10	1	5	6
1	2026-08-04 09:14:00+10	6	2	8
1	2026-08-04 09:16:00+10	2	3	5
1	2026-08-04 09:17:00+10	2	1	3
1	2026-08-04 09:19:00+10	3	3	6
1	2026-08-04 09:21:00+10	3	6	9
1	2026-08-04 09:29:00+10	6	8	14
1	2026-08-04 09:31:00+10	4	3	7
1	2026-08-04 09:32:00+10	3	11	14
1	2026-08-04 09:36:00+10	3	12	15
1	2026-08-04 09:37:00+10	5	1	6
1	2026-08-04 09:38:00+10	6	4	10
1	2026-08-04 09:39:00+10	6	8	14
1	2026-08-04 09:40:00+10	3	5	8
1	2026-08-04 09:42:00+10	4	4	8
1	2026-08-04 09:46:00+10	0	7	7
1	2026-08-04 09:47:00+10	4	2	6
1	2026-08-04 09:48:00+10	4	9	13
1	2026-08-04 09:49:00+10	6	7	13
1	2026-08-04 09:51:00+10	7	5	12
1	2026-08-04 09:55:00+10	3	1	4
1	2026-08-04 09:57:00+10	2	9	11
1	2026-08-04 09:58:00+10	4	4	8
1	2026-08-04 10:00:00+10	4	2	6
1	2026-08-04 10:03:00+10	3	4	7
1	2026-08-04 10:05:00+10	6	11	17
1	2026-08-04 10:06:00+10	4	2	6
1	2026-08-04 10:18:00+10	4	6	10
1	2026-08-04 10:21:00+10	6	2	8
1	2026-08-04 10:26:00+10	6	2	8
1	2026-08-04 10:32:00+10	3	10	13
1	2026-08-04 10:33:00+10	11	2	13
1	2026-08-04 10:36:00+10	3	2	5
1	2026-08-04 10:38:00+10	9	7	16
1	2026-08-04 10:39:00+10	6	5	11
1	2026-08-04 10:40:00+10	12	5	17
1	2026-08-04 10:46:00+10	3	3	6
1	2026-08-04 10:47:00+10	10	7	17
1	2026-08-04 10:50:00+10	8	6	14
1	2026-08-04 11:02:00+10	6	10	16
1	2026-08-04 11:07:00+10	19	3	22
1	2026-08-04 11:08:00+10	10	8	18
1	2026-08-04 11:09:00+10	5	6	11
1	2026-08-04 11:13:00+10	8	8	16
1	2026-08-04 11:26:00+10	11	8	19
1	2026-08-04 11:27:00+10	17	9	26
1	2026-08-04 11:31:00+10	11	9	20
1	2026-08-04 11:33:00+10	3	8	11
1	2026-08-04 11:36:00+10	2	5	7
1	2026-08-04 11:37:00+10	11	4	15
1	2026-08-04 11:38:00+10	1	9	10
1	2026-08-04 11:41:00+10	10	10	20
1	2026-08-04 11:42:00+10	5	2	7
1	2026-08-04 11:44:00+10	5	9	14
1	2026-08-04 11:47:00+10	8	10	18
1	2026-08-04 11:50:00+10	5	5	10
1	2026-08-04 11:52:00+10	6	4	10
1	2026-08-04 11:57:00+10	7	4	11
1	2026-08-04 11:58:00+10	6	7	13
1	2026-08-04 12:02:00+10	4	3	7
1	2026-08-04 12:08:00+10	9	8	17
1	2026-08-04 12:09:00+10	9	20	29
1	2026-08-04 12:12:00+10	8	6	14
1	2026-08-04 12:13:00+10	11	20	31
1	2026-08-04 12:14:00+10	15	18	33
1	2026-08-04 12:15:00+10	12	12	24
1	2026-08-04 12:17:00+10	16	9	25
1	2026-08-04 12:19:00+10	17	15	32
1	2026-08-04 12:21:00+10	17	11	28
1	2026-08-04 12:25:00+10	10	11	21
1	2026-08-04 12:30:00+10	24	12	36
1	2026-08-04 12:31:00+10	13	23	36
1	2026-08-04 12:33:00+10	8	13	21
1	2026-08-04 12:36:00+10	19	14	33
1	2026-08-04 12:41:00+10	13	25	38
1	2026-08-04 12:47:00+10	12	25	37
1	2026-08-04 12:52:00+10	10	14	24
1	2026-08-04 12:54:00+10	25	11	36
1	2026-08-04 12:55:00+10	21	21	42
1	2026-08-04 12:58:00+10	28	8	36
1	2026-08-04 13:03:00+10	19	17	36
1	2026-08-04 13:06:00+10	17	19	36
1	2026-08-04 13:08:00+10	27	19	46
1	2026-08-04 13:10:00+10	21	16	37
1	2026-08-04 13:11:00+10	15	24	39
1	2026-08-04 13:12:00+10	19	28	47
1	2026-08-04 13:14:00+10	20	14	34
1	2026-08-04 13:18:00+10	24	20	44
1	2026-08-04 13:23:00+10	16	11	27
1	2026-08-04 13:24:00+10	18	19	37
1	2026-08-04 13:28:00+10	23	17	40
1	2026-08-04 13:31:00+10	13	20	33
1	2026-08-04 13:35:00+10	18	11	29
1	2026-08-04 13:36:00+10	17	19	36
1	2026-08-04 13:38:00+10	23	17	40
1	2026-08-04 13:40:00+10	20	16	36
1	2026-08-04 13:45:00+10	6	25	31
1	2026-08-04 13:46:00+10	23	16	39
1	2026-08-04 13:49:00+10	16	23	39
1	2026-08-04 13:57:00+10	11	17	28
1	2026-08-04 14:05:00+10	15	14	29
1	2026-08-04 14:06:00+10	11	11	22
1	2026-08-04 14:09:00+10	15	14	29
1	2026-08-04 14:12:00+10	13	12	25
1	2026-08-04 14:13:00+10	14	27	41
1	2026-08-04 14:14:00+10	15	7	22
1	2026-08-04 14:15:00+10	17	9	26
1	2026-08-04 14:16:00+10	13	10	23
1	2026-08-04 14:18:00+10	17	13	30
1	2026-08-04 14:19:00+10	16	21	37
1	2026-08-04 14:20:00+10	15	10	25
1	2026-08-04 14:23:00+10	20	18	38
1	2026-08-04 14:24:00+10	8	12	20
1	2026-08-04 14:33:00+10	20	10	30
1	2026-08-04 14:36:00+10	16	14	30
1	2026-08-04 14:39:00+10	6	9	15
2	2026-08-03 23:59:00+10	1	1	2
2	2026-08-04 00:39:00+10	1	0	1
2	2026-08-04 01:08:00+10	0	1	1
2	2026-08-04 01:21:00+10	0	1	1
2	2026-08-04 01:53:00+10	0	1	1
2	2026-08-04 02:12:00+10	0	1	1
2	2026-08-04 02:40:00+10	0	1	1
2	2026-08-04 02:45:00+10	0	3	3
2	2026-08-04 02:47:00+10	0	1	1
2	2026-08-04 03:18:00+10	1	0	1
2	2026-08-04 03:42:00+10	1	1	2
2	2026-08-04 03:56:00+10	0	1	1
2	2026-08-04 04:01:00+10	0	1	1
2	2026-08-04 04:25:00+10	1	0	1
2	2026-08-04 04:38:00+10	0	1	1
2	2026-08-04 04:49:00+10	0	1	1
2	2026-08-04 05:17:00+10	1	0	1
2	2026-08-04 05:31:00+10	0	1	1
2	2026-08-04 05:55:00+10	1	0	1
2	2026-08-04 05:56:00+10	1	1	2
2	2026-08-04 06:09:00+10	1	1	2
2	2026-08-04 06:10:00+10	0	2	2
2	2026-08-04 06:11:00+10	1	0	1
2	2026-08-04 06:25:00+10	0	2	2
2	2026-08-04 06:37:00+10	2	1	3
2	2026-08-04 06:41:00+10	1	0	1
2	2026-08-04 06:50:00+10	1	1	2
2	2026-08-04 06:51:00+10	0	2	2
2	2026-08-04 07:00:00+10	4	0	4
2	2026-08-04 07:09:00+10	1	0	1
2	2026-08-04 07:14:00+10	1	1	2
2	2026-08-04 07:17:00+10	2	0	2
2	2026-08-04 07:18:00+10	0	1	1
2	2026-08-04 07:26:00+10	3	1	4
2	2026-08-04 07:28:00+10	2	3	5
2	2026-08-04 07:29:00+10	0	1	1
2	2026-08-04 07:36:00+10	2	0	2
2	2026-08-04 07:37:00+10	2	0	2
2	2026-08-04 07:38:00+10	0	3	3
2	2026-08-04 07:43:00+10	1	3	4
2	2026-08-04 07:45:00+10	2	1	3
2	2026-08-04 07:47:00+10	0	3	3
2	2026-08-04 07:54:00+10	1	3	4
2	2026-08-04 08:00:00+10	2	6	8
2	2026-08-04 08:05:00+10	1	1	2
2	2026-08-04 08:06:00+10	3	2	5
2	2026-08-04 08:08:00+10	2	2	4
2	2026-08-04 08:10:00+10	1	2	3
2	2026-08-04 08:17:00+10	0	7	7
2	2026-08-04 08:22:00+10	2	6	8
2	2026-08-04 08:30:00+10	3	12	15
2	2026-08-04 08:34:00+10	3	5	8
2	2026-08-04 08:35:00+10	5	5	10
2	2026-08-04 08:36:00+10	1	2	3
2	2026-08-04 08:43:00+10	5	6	11
2	2026-08-04 08:45:00+10	2	13	15
2	2026-08-04 08:47:00+10	5	11	16
2	2026-08-04 08:50:00+10	2	7	9
2	2026-08-04 08:51:00+10	4	10	14
2	2026-08-04 08:52:00+10	2	5	7
2	2026-08-04 08:53:00+10	0	9	9
2	2026-08-04 08:56:00+10	2	8	10
2	2026-08-04 08:57:00+10	3	3	6
2	2026-08-04 08:58:00+10	8	6	14
2	2026-08-04 09:03:00+10	4	5	9
2	2026-08-04 09:04:00+10	2	6	8
2	2026-08-04 09:05:00+10	5	8	13
2	2026-08-04 09:06:00+10	0	7	7
2	2026-08-04 09:07:00+10	0	6	6
2	2026-08-04 09:18:00+10	0	2	2
2	2026-08-04 09:22:00+10	1	1	2
2	2026-08-04 09:25:00+10	3	6	9
2	2026-08-04 09:31:00+10	4	3	7
2	2026-08-04 09:39:00+10	2	2	4
2	2026-08-04 09:42:00+10	3	1	4
2	2026-08-04 09:47:00+10	1	7	8
2	2026-08-04 09:49:00+10	3	3	6
2	2026-08-04 09:53:00+10	3	2	5
2	2026-08-04 09:55:00+10	2	4	6
2	2026-08-04 09:56:00+10	2	4	6
2	2026-08-04 09:58:00+10	2	4	6
2	2026-08-04 10:02:00+10	4	1	5
2	2026-08-04 10:03:00+10	2	11	13
2	2026-08-04 10:07:00+10	3	3	6
2	2026-08-04 10:08:00+10	7	9	16
2	2026-08-04 10:15:00+10	22	2	24
2	2026-08-04 10:16:00+10	0	2	2
2	2026-08-04 10:21:00+10	5	5	10
2	2026-08-04 10:22:00+10	1	10	11
2	2026-08-04 10:23:00+10	5	3	8
2	2026-08-04 10:27:00+10	2	5	7
2	2026-08-04 10:28:00+10	8	3	11
2	2026-08-04 10:30:00+10	4	7	11
2	2026-08-04 10:33:00+10	1	4	5
2	2026-08-04 10:37:00+10	12	6	18
2	2026-08-04 10:44:00+10	0	5	5
2	2026-08-04 10:46:00+10	6	2	8
2	2026-08-04 10:51:00+10	3	3	6
2	2026-08-04 10:54:00+10	8	2	10
2	2026-08-04 10:59:00+10	3	10	13
2	2026-08-04 11:01:00+10	4	7	11
2	2026-08-04 11:03:00+10	3	5	8
2	2026-08-04 11:06:00+10	7	5	12
2	2026-08-04 11:08:00+10	5	5	10
2	2026-08-04 11:09:00+10	7	5	12
2	2026-08-04 11:10:00+10	10	5	15
2	2026-08-04 11:14:00+10	9	7	16
2	2026-08-04 11:15:00+10	12	4	16
2	2026-08-04 11:22:00+10	3	16	19
2	2026-08-04 11:24:00+10	7	5	12
2	2026-08-04 11:25:00+10	4	5	9
2	2026-08-04 11:29:00+10	4	9	13
2	2026-08-04 11:31:00+10	3	10	13
2	2026-08-04 11:32:00+10	9	6	15
2	2026-08-04 11:33:00+10	13	6	19
2	2026-08-04 11:37:00+10	10	2	12
2	2026-08-04 11:39:00+10	9	9	18
2	2026-08-04 11:43:00+10	2	6	8
2	2026-08-04 11:45:00+10	4	2	6
2	2026-08-04 11:48:00+10	13	9	22
2	2026-08-04 11:52:00+10	2	3	5
2	2026-08-04 11:54:00+10	9	5	14
2	2026-08-04 11:57:00+10	5	11	16
2	2026-08-04 11:58:00+10	4	6	10
2	2026-08-04 12:03:00+10	18	1	19
2	2026-08-04 12:04:00+10	14	6	20
2	2026-08-04 12:12:00+10	22	10	32
2	2026-08-04 12:15:00+10	11	6	17
2	2026-08-04 12:16:00+10	17	9	26
2	2026-08-04 12:20:00+10	6	6	12
2	2026-08-04 12:21:00+10	13	14	27
2	2026-08-04 12:24:00+10	14	7	21
2	2026-08-04 12:29:00+10	15	14	29
2	2026-08-04 12:36:00+10	13	10	23
2	2026-08-04 12:37:00+10	9	15	24
2	2026-08-04 12:40:00+10	16	17	33
2	2026-08-04 12:41:00+10	12	16	28
2	2026-08-04 12:46:00+10	12	15	27
2	2026-08-04 12:47:00+10	8	22	30
2	2026-08-04 12:51:00+10	18	22	40
2	2026-08-04 13:00:00+10	16	14	30
2	2026-08-04 13:05:00+10	14	11	25
2	2026-08-04 13:06:00+10	9	12	21
2	2026-08-04 13:12:00+10	15	13	28
2	2026-08-04 13:15:00+10	16	19	35
2	2026-08-04 13:17:00+10	11	19	30
2	2026-08-04 13:19:00+10	17	7	24
2	2026-08-04 13:22:00+10	8	6	14
2	2026-08-04 13:35:00+10	6	14	20
2	2026-08-04 13:36:00+10	13	11	24
2	2026-08-04 13:37:00+10	14	11	25
2	2026-08-04 13:43:00+10	9	15	24
2	2026-08-04 13:44:00+10	9	8	17
2	2026-08-04 13:45:00+10	9	11	20
2	2026-08-04 13:52:00+10	6	7	13
2	2026-08-04 13:57:00+10	4	12	16
2	2026-08-04 13:58:00+10	14	16	30
2	2026-08-04 14:06:00+10	4	16	20
2	2026-08-04 14:08:00+10	16	17	33
2	2026-08-04 14:10:00+10	18	3	21
2	2026-08-04 14:12:00+10	13	14	27
2	2026-08-04 14:14:00+10	15	0	15
2	2026-08-04 14:18:00+10	18	10	28
2	2026-08-04 14:19:00+10	8	4	12
2	2026-08-04 14:20:00+10	8	11	19
2	2026-08-04 14:24:00+10	4	11	15
2	2026-08-04 14:25:00+10	8	12	20
2	2026-08-04 14:26:00+10	9	5	14
2	2026-08-04 14:34:00+10	10	10	20
2	2026-08-04 14:35:00+10	8	11	19
2	2026-08-04 14:36:00+10	13	5	18
3	2026-08-03 23:55:00+10	0	1	1
3	2026-08-03 23:57:00+10	1	2	3
3	2026-08-03 23:58:00+10	4	3	7
3	2026-08-03 23:59:00+10	0	1	1
3	2026-08-04 00:00:00+10	1	0	1
3	2026-08-04 00:06:00+10	2	0	2
3	2026-08-04 00:07:00+10	1	0	1
3	2026-08-04 00:09:00+10	1	0	1
3	2026-08-04 00:16:00+10	0	2	2
3	2026-08-04 00:18:00+10	1	0	1
3	2026-08-04 00:19:00+10	1	4	5
3	2026-08-04 00:24:00+10	1	1	2
3	2026-08-04 00:25:00+10	0	1	1
3	2026-08-04 00:26:00+10	7	2	9
3	2026-08-04 00:32:00+10	0	4	4
3	2026-08-04 00:42:00+10	0	8	8
3	2026-08-04 00:45:00+10	6	2	8
3	2026-08-04 00:48:00+10	0	3	3
3	2026-08-04 00:56:00+10	1	2	3
3	2026-08-04 00:58:00+10	4	0	4
3	2026-08-04 01:07:00+10	1	0	1
3	2026-08-04 01:08:00+10	3	0	3
3	2026-08-04 01:17:00+10	2	2	4
3	2026-08-04 01:20:00+10	2	0	2
3	2026-08-04 01:28:00+10	0	2	2
3	2026-08-04 01:32:00+10	0	2	2
3	2026-08-04 01:35:00+10	4	0	4
3	2026-08-04 01:42:00+10	2	1	3
3	2026-08-04 01:48:00+10	2	0	2
3	2026-08-04 01:50:00+10	1	0	1
3	2026-08-04 01:55:00+10	0	2	2
3	2026-08-04 02:06:00+10	1	0	1
3	2026-08-04 02:08:00+10	0	1	1
3	2026-08-04 02:19:00+10	1	0	1
3	2026-08-04 02:22:00+10	4	1	5
3	2026-08-04 02:24:00+10	0	2	2
3	2026-08-04 02:34:00+10	0	1	1
3	2026-08-04 02:39:00+10	0	1	1
3	2026-08-04 03:00:00+10	1	0	1
3	2026-08-04 03:05:00+10	1	0	1
3	2026-08-04 03:06:00+10	0	2	2
3	2026-08-04 03:36:00+10	1	0	1
3	2026-08-04 03:49:00+10	0	1	1
3	2026-08-04 03:54:00+10	1	1	2
3	2026-08-04 03:59:00+10	0	1	1
3	2026-08-04 04:00:00+10	1	0	1
3	2026-08-04 04:33:00+10	0	1	1
3	2026-08-04 04:34:00+10	0	2	2
3	2026-08-04 04:37:00+10	1	0	1
3	2026-08-04 04:39:00+10	2	0	2
3	2026-08-04 04:40:00+10	1	0	1
3	2026-08-04 04:41:00+10	0	1	1
3	2026-08-04 04:42:00+10	0	1	1
3	2026-08-04 04:47:00+10	0	1	1
3	2026-08-04 05:08:00+10	1	0	1
3	2026-08-04 05:22:00+10	0	2	2
3	2026-08-04 05:24:00+10	0	2	2
3	2026-08-04 05:29:00+10	0	1	1
3	2026-08-04 05:33:00+10	0	1	1
3	2026-08-04 05:38:00+10	0	2	2
3	2026-08-04 05:41:00+10	0	2	2
3	2026-08-04 05:44:00+10	0	1	1
3	2026-08-04 05:45:00+10	0	1	1
3	2026-08-04 05:46:00+10	0	3	3
3	2026-08-04 05:47:00+10	1	2	3
3	2026-08-04 05:49:00+10	1	0	1
3	2026-08-04 05:55:00+10	1	0	1
3	2026-08-04 05:59:00+10	0	1	1
3	2026-08-04 06:06:00+10	0	1	1
3	2026-08-04 06:07:00+10	1	0	1
3	2026-08-04 06:13:00+10	0	2	2
3	2026-08-04 06:14:00+10	0	2	2
3	2026-08-04 06:16:00+10	0	2	2
3	2026-08-04 06:23:00+10	0	1	1
3	2026-08-04 06:26:00+10	1	4	5
3	2026-08-04 06:32:00+10	0	1	1
3	2026-08-04 06:33:00+10	0	1	1
3	2026-08-04 06:35:00+10	0	1	1
3	2026-08-04 06:38:00+10	2	0	2
3	2026-08-04 06:41:00+10	1	2	3
3	2026-08-04 06:42:00+10	1	2	3
3	2026-08-04 06:51:00+10	1	1	2
3	2026-08-04 06:52:00+10	1	0	1
3	2026-08-04 06:53:00+10	0	2	2
3	2026-08-04 06:54:00+10	2	0	2
3	2026-08-04 06:59:00+10	1	0	1
3	2026-08-04 07:01:00+10	1	2	3
3	2026-08-04 07:02:00+10	1	3	4
3	2026-08-04 07:06:00+10	1	1	2
3	2026-08-04 07:11:00+10	1	1	2
3	2026-08-04 07:24:00+10	1	0	1
3	2026-08-04 07:27:00+10	1	1	2
3	2026-08-04 07:28:00+10	1	2	3
3	2026-08-04 07:30:00+10	1	2	3
3	2026-08-04 07:34:00+10	2	1	3
3	2026-08-04 07:35:00+10	1	1	2
3	2026-08-04 07:39:00+10	0	3	3
3	2026-08-04 07:42:00+10	3	2	5
3	2026-08-04 07:43:00+10	1	5	6
3	2026-08-04 07:44:00+10	1	5	6
3	2026-08-04 07:46:00+10	0	1	1
3	2026-08-04 07:48:00+10	0	2	2
3	2026-08-04 07:54:00+10	1	3	4
3	2026-08-04 07:56:00+10	2	5	7
3	2026-08-04 07:58:00+10	0	1	1
3	2026-08-04 08:02:00+10	0	4	4
3	2026-08-04 08:03:00+10	1	3	4
3	2026-08-04 08:07:00+10	2	4	6
3	2026-08-04 08:10:00+10	2	10	12
3	2026-08-04 08:11:00+10	3	11	14
3	2026-08-04 08:12:00+10	11	4	15
3	2026-08-04 08:13:00+10	10	4	14
3	2026-08-04 08:16:00+10	0	1	1
3	2026-08-04 08:18:00+10	14	2	16
3	2026-08-04 08:19:00+10	7	3	10
3	2026-08-04 08:20:00+10	0	8	8
3	2026-08-04 08:22:00+10	2	2	4
3	2026-08-04 08:23:00+10	0	8	8
3	2026-08-04 08:24:00+10	8	7	15
3	2026-08-04 08:25:00+10	2	6	8
3	2026-08-04 08:27:00+10	5	14	19
3	2026-08-04 08:33:00+10	8	6	14
3	2026-08-04 08:38:00+10	1	5	6
3	2026-08-04 08:39:00+10	7	9	16
3	2026-08-04 08:41:00+10	1	6	7
3	2026-08-04 08:44:00+10	0	5	5
3	2026-08-04 08:46:00+10	8	5	13
3	2026-08-04 08:54:00+10	7	4	11
3	2026-08-04 08:55:00+10	1	1	2
3	2026-08-04 08:57:00+10	0	3	3
3	2026-08-04 08:58:00+10	3	15	18
3	2026-08-04 09:01:00+10	3	8	11
3	2026-08-04 09:03:00+10	2	9	11
3	2026-08-04 09:04:00+10	8	5	13
3	2026-08-04 09:09:00+10	7	5	12
3	2026-08-04 09:10:00+10	0	5	5
3	2026-08-04 09:11:00+10	5	4	9
3	2026-08-04 09:13:00+10	3	3	6
3	2026-08-04 09:15:00+10	6	10	16
3	2026-08-04 09:18:00+10	4	10	14
3	2026-08-04 09:20:00+10	9	4	13
3	2026-08-04 09:21:00+10	3	9	12
3	2026-08-04 09:25:00+10	5	8	13
3	2026-08-04 09:28:00+10	1	4	5
3	2026-08-04 09:30:00+10	5	5	10
3	2026-08-04 09:33:00+10	4	11	15
3	2026-08-04 09:34:00+10	4	9	13
3	2026-08-04 09:35:00+10	6	2	8
3	2026-08-04 09:38:00+10	0	3	3
3	2026-08-04 09:39:00+10	10	7	17
3	2026-08-04 09:40:00+10	2	9	11
3	2026-08-04 09:42:00+10	10	3	13
3	2026-08-04 09:47:00+10	1	3	4
3	2026-08-04 09:50:00+10	8	15	23
3	2026-08-04 09:51:00+10	4	7	11
3	2026-08-04 10:04:00+10	5	4	9
3	2026-08-04 10:06:00+10	10	9	19
3	2026-08-04 10:09:00+10	3	14	17
3	2026-08-04 10:12:00+10	6	4	10
3	2026-08-04 10:23:00+10	1	6	7
3	2026-08-04 10:26:00+10	12	9	21
3	2026-08-04 10:29:00+10	6	1	7
3	2026-08-04 10:30:00+10	7	5	12
3	2026-08-04 10:35:00+10	6	4	10
3	2026-08-04 10:37:00+10	9	10	19
3	2026-08-04 10:38:00+10	5	6	11
3	2026-08-04 10:39:00+10	5	13	18
3	2026-08-04 10:50:00+10	3	13	16
3	2026-08-04 10:51:00+10	9	17	26
3	2026-08-04 10:58:00+10	1	15	16
3	2026-08-04 10:59:00+10	5	6	11
3	2026-08-04 11:01:00+10	2	5	7
3	2026-08-04 11:02:00+10	2	11	13
3	2026-08-04 11:04:00+10	7	8	15
3	2026-08-04 11:06:00+10	10	8	18
3	2026-08-04 11:07:00+10	10	16	26
3	2026-08-04 11:10:00+10	10	18	28
3	2026-08-04 11:11:00+10	5	13	18
3	2026-08-04 11:15:00+10	14	8	22
3	2026-08-04 11:17:00+10	3	17	20
3	2026-08-04 11:18:00+10	7	14	21
3	2026-08-04 11:19:00+10	9	13	22
3	2026-08-04 11:22:00+10	16	5	21
3	2026-08-04 11:23:00+10	8	16	24
3	2026-08-04 11:25:00+10	8	9	17
3	2026-08-04 11:27:00+10	8	19	27
3	2026-08-04 11:29:00+10	6	8	14
3	2026-08-04 11:36:00+10	8	5	13
3	2026-08-04 11:39:00+10	6	7	13
3	2026-08-04 11:40:00+10	8	2	10
3	2026-08-04 11:44:00+10	7	2	9
3	2026-08-04 11:45:00+10	6	9	15
3	2026-08-04 11:47:00+10	10	4	14
3	2026-08-04 11:49:00+10	9	3	12
3	2026-08-04 11:50:00+10	3	7	10
3	2026-08-04 12:02:00+10	18	7	25
3	2026-08-04 12:04:00+10	4	15	19
3	2026-08-04 12:07:00+10	8	12	20
3	2026-08-04 12:16:00+10	20	12	32
3	2026-08-04 12:17:00+10	12	14	26
3	2026-08-04 12:19:00+10	6	24	30
3	2026-08-04 12:20:00+10	16	14	30
3	2026-08-04 12:22:00+10	15	12	27
3	2026-08-04 12:29:00+10	3	25	28
3	2026-08-04 12:31:00+10	12	16	28
3	2026-08-04 12:32:00+10	17	19	36
3	2026-08-04 12:35:00+10	13	13	26
3	2026-08-04 12:36:00+10	21	16	37
3	2026-08-04 12:38:00+10	38	41	79
3	2026-08-04 12:39:00+10	23	15	38
3	2026-08-04 12:40:00+10	18	14	32
3	2026-08-04 12:42:00+10	31	17	48
3	2026-08-04 12:44:00+10	19	16	35
3	2026-08-04 12:45:00+10	29	21	50
3	2026-08-04 12:46:00+10	10	13	23
3	2026-08-04 12:55:00+10	15	22	37
3	2026-08-04 12:57:00+10	14	7	21
3	2026-08-04 13:03:00+10	23	21	44
3	2026-08-04 13:06:00+10	21	29	50
3	2026-08-04 13:07:00+10	15	16	31
3	2026-08-04 13:14:00+10	12	12	24
3	2026-08-04 13:17:00+10	14	19	33
3	2026-08-04 13:20:00+10	5	27	32
3	2026-08-04 13:24:00+10	21	15	36
3	2026-08-04 13:27:00+10	29	11	40
3	2026-08-04 13:29:00+10	29	16	45
3	2026-08-04 13:31:00+10	11	19	30
3	2026-08-04 13:33:00+10	27	9	36
3	2026-08-04 13:37:00+10	15	12	27
3	2026-08-04 13:38:00+10	23	21	44
3	2026-08-04 13:43:00+10	13	15	28
3	2026-08-04 13:50:00+10	16	19	35
3	2026-08-04 13:54:00+10	25	23	48
3	2026-08-04 13:55:00+10	16	19	35
3	2026-08-04 13:56:00+10	13	17	30
3	2026-08-04 14:04:00+10	11	13	24
3	2026-08-04 14:05:00+10	14	13	27
3	2026-08-04 14:07:00+10	16	11	27
3	2026-08-04 14:08:00+10	9	20	29
3	2026-08-04 14:12:00+10	12	27	39
3	2026-08-04 14:19:00+10	15	11	26
3	2026-08-04 14:21:00+10	24	16	40
3	2026-08-04 14:23:00+10	11	27	38
4	2026-08-04 00:00:00+10	0	2	2
4	2026-08-04 00:04:00+10	3	2	5
4	2026-08-04 00:09:00+10	2	2	4
4	2026-08-04 00:11:00+10	1	0	1
4	2026-08-04 00:13:00+10	0	1	1
4	2026-08-04 00:15:00+10	0	3	3
4	2026-08-04 00:17:00+10	1	0	1
4	2026-08-04 00:18:00+10	3	0	3
4	2026-08-04 00:21:00+10	5	2	7
4	2026-08-04 00:22:00+10	0	1	1
4	2026-08-04 00:24:00+10	4	0	4
4	2026-08-04 00:36:00+10	1	0	1
4	2026-08-04 00:40:00+10	1	0	1
4	2026-08-04 00:45:00+10	1	1	2
4	2026-08-04 00:47:00+10	0	2	2
4	2026-08-04 00:52:00+10	1	1	2
4	2026-08-04 00:56:00+10	3	2	5
4	2026-08-04 00:59:00+10	0	2	2
4	2026-08-04 01:08:00+10	0	1	1
4	2026-08-04 01:50:00+10	2	0	2
4	2026-08-04 01:51:00+10	0	1	1
4	2026-08-04 01:52:00+10	0	1	1
4	2026-08-04 01:54:00+10	1	1	2
4	2026-08-04 02:01:00+10	1	0	1
4	2026-08-04 02:13:00+10	4	0	4
4	2026-08-04 02:35:00+10	0	4	4
4	2026-08-04 02:36:00+10	0	3	3
4	2026-08-04 02:44:00+10	0	1	1
4	2026-08-04 02:47:00+10	1	1	2
4	2026-08-04 02:53:00+10	2	0	2
4	2026-08-04 02:58:00+10	1	0	1
4	2026-08-04 03:20:00+10	0	2	2
4	2026-08-04 03:28:00+10	0	1	1
4	2026-08-04 03:48:00+10	1	0	1
4	2026-08-04 03:49:00+10	1	0	1
4	2026-08-04 04:06:00+10	0	1	1
4	2026-08-04 04:10:00+10	2	0	2
4	2026-08-04 04:11:00+10	0	1	1
4	2026-08-04 04:25:00+10	1	0	1
4	2026-08-04 04:28:00+10	1	0	1
4	2026-08-04 04:31:00+10	1	0	1
4	2026-08-04 04:49:00+10	0	3	3
4	2026-08-04 05:03:00+10	1	0	1
4	2026-08-04 05:06:00+10	1	0	1
4	2026-08-04 05:15:00+10	0	1	1
4	2026-08-04 05:33:00+10	1	0	1
4	2026-08-04 05:36:00+10	1	3	4
4	2026-08-04 05:38:00+10	0	1	1
4	2026-08-04 05:40:00+10	2	1	3
4	2026-08-04 05:42:00+10	0	1	1
4	2026-08-04 05:43:00+10	0	1	1
4	2026-08-04 05:54:00+10	3	1	4
4	2026-08-04 05:58:00+10	3	0	3
4	2026-08-04 05:59:00+10	1	0	1
4	2026-08-04 06:13:00+10	1	0	1
4	2026-08-04 06:15:00+10	1	1	2
4	2026-08-04 06:17:00+10	3	0	3
4	2026-08-04 06:18:00+10	2	2	4
4	2026-08-04 06:19:00+10	2	2	4
4	2026-08-04 06:22:00+10	4	2	6
4	2026-08-04 06:27:00+10	2	4	6
4	2026-08-04 06:29:00+10	0	1	1
4	2026-08-04 06:30:00+10	1	1	2
4	2026-08-04 06:35:00+10	4	1	5
4	2026-08-04 06:38:00+10	4	2	6
4	2026-08-04 06:39:00+10	2	1	3
4	2026-08-04 06:40:00+10	3	0	3
4	2026-08-04 06:42:00+10	3	2	5
4	2026-08-04 06:47:00+10	3	2	5
4	2026-08-04 06:50:00+10	0	1	1
4	2026-08-04 06:51:00+10	2	0	2
4	2026-08-04 06:57:00+10	2	1	3
4	2026-08-04 06:58:00+10	2	2	4
4	2026-08-04 07:02:00+10	1	2	3
4	2026-08-04 07:03:00+10	4	1	5
4	2026-08-04 07:04:00+10	1	1	2
4	2026-08-04 07:07:00+10	6	1	7
4	2026-08-04 07:09:00+10	5	1	6
4	2026-08-04 07:11:00+10	1	2	3
4	2026-08-04 07:12:00+10	0	4	4
4	2026-08-04 07:17:00+10	1	1	2
4	2026-08-04 07:18:00+10	3	3	6
4	2026-08-04 07:20:00+10	3	1	4
4	2026-08-04 07:21:00+10	4	2	6
4	2026-08-04 07:24:00+10	6	1	7
4	2026-08-04 07:29:00+10	6	1	7
4	2026-08-04 07:32:00+10	5	0	5
4	2026-08-04 07:39:00+10	8	2	10
4	2026-08-04 07:40:00+10	3	3	6
4	2026-08-04 07:42:00+10	10	2	12
4	2026-08-04 07:43:00+10	4	4	8
4	2026-08-04 07:44:00+10	7	5	12
4	2026-08-04 07:46:00+10	6	2	8
4	2026-08-04 07:55:00+10	12	3	15
4	2026-08-04 08:01:00+10	9	4	13
4	2026-08-04 08:12:00+10	2	5	7
4	2026-08-04 08:17:00+10	7	2	9
4	2026-08-04 08:18:00+10	5	4	9
4	2026-08-04 08:19:00+10	13	5	18
4	2026-08-04 08:20:00+10	6	4	10
4	2026-08-04 08:22:00+10	17	11	28
4	2026-08-04 08:28:00+10	13	6	19
4	2026-08-04 08:29:00+10	10	5	15
4	2026-08-04 08:30:00+10	11	5	16
4	2026-08-04 08:31:00+10	6	2	8
4	2026-08-04 08:34:00+10	12	5	17
4	2026-08-04 08:43:00+10	14	5	19
4	2026-08-04 08:48:00+10	16	10	26
4	2026-08-04 08:50:00+10	11	3	14
4	2026-08-04 08:53:00+10	13	9	22
4	2026-08-04 08:57:00+10	20	4	24
4	2026-08-04 08:58:00+10	17	6	23
4	2026-08-04 08:59:00+10	8	7	15
4	2026-08-04 09:01:00+10	18	5	23
4	2026-08-04 09:03:00+10	7	6	13
4	2026-08-04 09:08:00+10	24	4	28
4	2026-08-04 09:09:00+10	8	7	15
4	2026-08-04 09:12:00+10	11	3	14
4	2026-08-04 09:16:00+10	13	4	17
4	2026-08-04 09:21:00+10	9	4	13
4	2026-08-04 09:24:00+10	8	2	10
4	2026-08-04 09:32:00+10	5	4	9
4	2026-08-04 09:33:00+10	3	11	14
4	2026-08-04 09:37:00+10	9	3	12
4	2026-08-04 09:40:00+10	12	9	21
4	2026-08-04 09:41:00+10	7	6	13
4	2026-08-04 09:43:00+10	7	0	7
4	2026-08-04 09:44:00+10	12	2	14
4	2026-08-04 09:46:00+10	15	12	27
4	2026-08-04 09:47:00+10	9	7	16
4	2026-08-04 09:48:00+10	16	11	27
4	2026-08-04 09:49:00+10	12	8	20
4	2026-08-04 09:50:00+10	8	7	15
4	2026-08-04 09:52:00+10	19	7	26
4	2026-08-04 09:55:00+10	22	2	24
4	2026-08-04 09:56:00+10	12	5	17
4	2026-08-04 10:00:00+10	4	7	11
4	2026-08-04 10:02:00+10	14	13	27
4	2026-08-04 10:03:00+10	11	11	22
4	2026-08-04 10:08:00+10	33	19	52
4	2026-08-04 10:11:00+10	8	5	13
4	2026-08-04 10:13:00+10	10	11	21
4	2026-08-04 10:17:00+10	18	7	25
4	2026-08-04 10:19:00+10	38	6	44
4	2026-08-04 10:25:00+10	10	6	16
4	2026-08-04 10:30:00+10	12	11	23
4	2026-08-04 10:36:00+10	25	14	39
4	2026-08-04 10:38:00+10	10	9	19
4	2026-08-04 10:40:00+10	18	10	28
4	2026-08-04 10:44:00+10	6	20	26
4	2026-08-04 10:49:00+10	13	8	21
4	2026-08-04 10:52:00+10	21	13	34
4	2026-08-04 10:54:00+10	20	12	32
4	2026-08-04 10:55:00+10	7	10	17
4	2026-08-04 10:56:00+10	10	8	18
4	2026-08-04 10:58:00+10	8	6	14
4	2026-08-04 11:00:00+10	12	7	19
4	2026-08-04 11:06:00+10	9	16	25
4	2026-08-04 11:07:00+10	13	11	24
4	2026-08-04 11:08:00+10	19	7	26
4	2026-08-04 11:13:00+10	10	15	25
4	2026-08-04 11:20:00+10	11	3	14
4	2026-08-04 11:28:00+10	22	20	42
4	2026-08-04 11:34:00+10	15	10	25
4	2026-08-04 11:37:00+10	15	19	34
4	2026-08-04 11:38:00+10	16	17	33
4	2026-08-04 11:39:00+10	16	8	24
4	2026-08-04 11:41:00+10	21	7	28
4	2026-08-04 11:43:00+10	18	11	29
4	2026-08-04 11:46:00+10	22	13	35
4	2026-08-04 11:53:00+10	20	14	34
4	2026-08-04 11:57:00+10	13	14	27
4	2026-08-04 11:59:00+10	20	11	31
4	2026-08-04 12:03:00+10	12	16	28
4	2026-08-04 12:13:00+10	27	8	35
4	2026-08-04 12:21:00+10	31	17	48
4	2026-08-04 12:23:00+10	35	11	46
4	2026-08-04 12:26:00+10	22	23	45
4	2026-08-04 12:32:00+10	24	17	41
4	2026-08-04 12:33:00+10	21	11	32
4	2026-08-04 12:36:00+10	26	8	34
4	2026-08-04 12:37:00+10	32	26	58
4	2026-08-04 12:39:00+10	23	11	34
4	2026-08-04 12:41:00+10	18	18	36
4	2026-08-04 12:43:00+10	20	14	34
4	2026-08-04 12:44:00+10	12	25	37
4	2026-08-04 12:45:00+10	33	17	50
4	2026-08-04 12:54:00+10	16	25	41
4	2026-08-04 12:57:00+10	41	29	70
4	2026-08-04 12:59:00+10	34	19	53
4	2026-08-04 13:00:00+10	19	14	33
4	2026-08-04 13:03:00+10	28	19	47
4	2026-08-04 13:05:00+10	36	24	60
4	2026-08-04 13:10:00+10	24	31	55
4	2026-08-04 13:11:00+10	38	13	51
4	2026-08-04 13:14:00+10	21	16	37
4	2026-08-04 13:15:00+10	20	18	38
4	2026-08-04 13:16:00+10	20	25	45
4	2026-08-04 13:24:00+10	24	12	36
4	2026-08-04 13:26:00+10	37	22	59
4	2026-08-04 13:28:00+10	29	22	51
4	2026-08-04 13:29:00+10	31	18	49
4	2026-08-04 13:34:00+10	18	11	29
4	2026-08-04 13:35:00+10	17	18	35
4	2026-08-04 13:36:00+10	32	19	51
4	2026-08-04 13:37:00+10	23	22	45
4	2026-08-04 13:39:00+10	21	21	42
4	2026-08-04 13:40:00+10	23	33	56
4	2026-08-04 13:42:00+10	16	13	29
4	2026-08-04 13:43:00+10	13	13	26
4	2026-08-04 13:45:00+10	29	21	50
4	2026-08-04 13:46:00+10	20	21	41
4	2026-08-04 13:47:00+10	14	20	34
4	2026-08-04 13:49:00+10	30	21	51
4	2026-08-04 13:50:00+10	21	28	49
4	2026-08-04 13:53:00+10	22	16	38
4	2026-08-04 13:55:00+10	18	18	36
4	2026-08-04 13:57:00+10	23	22	45
4	2026-08-04 13:59:00+10	19	12	31
4	2026-08-04 14:02:00+10	29	15	44
4	2026-08-04 14:04:00+10	40	18	58
4	2026-08-04 14:12:00+10	30	24	54
4	2026-08-04 14:14:00+10	14	18	32
4	2026-08-04 14:20:00+10	14	13	27
4	2026-08-04 14:23:00+10	23	24	47
4	2026-08-04 14:24:00+10	12	15	27
5	2026-08-04 00:05:00+10	0	5	5
5	2026-08-04 00:10:00+10	0	1	1
5	2026-08-04 00:45:00+10	4	3	7
5	2026-08-04 01:00:00+10	0	4	4
5	2026-08-04 01:10:00+10	1	1	2
5	2026-08-04 01:15:00+10	0	3	3
5	2026-08-04 01:20:00+10	1	0	1
5	2026-08-04 01:25:00+10	1	1	2
5	2026-08-04 01:55:00+10	0	4	4
5	2026-08-04 02:00:00+10	0	1	1
5	2026-08-04 02:05:00+10	1	0	1
5	2026-08-04 02:45:00+10	1	4	5
5	2026-08-04 03:00:00+10	0	3	3
5	2026-08-04 03:05:00+10	1	1	2
5	2026-08-04 03:15:00+10	0	2	2
5	2026-08-04 03:45:00+10	2	0	2
5	2026-08-04 04:30:00+10	1	0	1
5	2026-08-04 04:50:00+10	3	1	4
5	2026-08-04 04:55:00+10	1	0	1
5	2026-08-04 05:15:00+10	2	3	5
5	2026-08-04 05:25:00+10	3	5	8
5	2026-08-04 05:30:00+10	0	4	4
5	2026-08-04 05:40:00+10	4	5	9
5	2026-08-04 06:05:00+10	4	15	19
5	2026-08-04 06:10:00+10	5	8	13
5	2026-08-04 06:50:00+10	8	19	27
5	2026-08-04 06:55:00+10	7	12	19
5	2026-08-04 07:10:00+10	8	15	23
5	2026-08-04 07:15:00+10	9	30	39
5	2026-08-04 07:25:00+10	15	10	25
5	2026-08-04 07:30:00+10	12	33	45
5	2026-08-04 07:50:00+10	23	37	60
5	2026-08-04 08:10:00+10	31	63	94
5	2026-08-04 08:15:00+10	30	48	78
5	2026-08-04 08:25:00+10	43	66	109
5	2026-08-04 08:45:00+10	44	90	134
5	2026-08-04 08:50:00+10	28	82	110
5	2026-08-04 09:05:00+10	21	59	80
5	2026-08-04 09:10:00+10	11	69	80
5	2026-08-04 09:20:00+10	33	31	64
5	2026-08-04 09:30:00+10	18	45	63
5	2026-08-04 09:50:00+10	17	80	97
5	2026-08-04 10:45:00+10	23	50	73
5	2026-08-04 10:50:00+10	29	36	65
5	2026-08-04 10:55:00+10	20	55	75
5	2026-08-04 11:40:00+10	15	37	52
5	2026-08-04 11:45:00+10	12	13	25
5	2026-08-04 11:50:00+10	10	19	29
5	2026-08-04 11:55:00+10	9	14	23
5	2026-08-04 12:15:00+10	36	52	88
5	2026-08-04 12:45:00+10	41	59	100
5	2026-08-04 12:50:00+10	61	71	132
5	2026-08-04 13:20:00+10	61	35	96
5	2026-08-04 13:45:00+10	41	69	110
5	2026-08-04 14:05:00+10	48	42	90
5	2026-08-04 14:10:00+10	46	42	88
6	2026-08-03 23:57:00+10	1	0	1
6	2026-08-03 23:58:00+10	1	0	1
6	2026-08-04 00:05:00+10	0	2	2
6	2026-08-04 00:15:00+10	1	0	1
6	2026-08-04 00:21:00+10	1	0	1
6	2026-08-04 00:39:00+10	1	0	1
6	2026-08-04 02:10:00+10	0	1	1
6	2026-08-04 04:11:00+10	2	0	2
6	2026-08-04 04:21:00+10	1	0	1
6	2026-08-04 04:35:00+10	1	0	1
6	2026-08-04 04:40:00+10	0	1	1
6	2026-08-04 04:46:00+10	1	0	1
6	2026-08-04 04:48:00+10	1	0	1
6	2026-08-04 04:49:00+10	1	0	1
6	2026-08-04 04:52:00+10	1	0	1
6	2026-08-04 04:57:00+10	0	3	3
6	2026-08-04 04:59:00+10	1	0	1
6	2026-08-04 05:09:00+10	0	1	1
6	2026-08-04 05:21:00+10	2	1	3
6	2026-08-04 05:24:00+10	1	2	3
6	2026-08-04 05:34:00+10	1	1	2
6	2026-08-04 05:36:00+10	1	13	14
6	2026-08-04 05:37:00+10	0	1	1
6	2026-08-04 05:39:00+10	0	3	3
6	2026-08-04 05:40:00+10	0	1	1
6	2026-08-04 05:42:00+10	0	5	5
6	2026-08-04 05:43:00+10	0	1	1
6	2026-08-04 05:44:00+10	0	1	1
6	2026-08-04 05:45:00+10	1	1	2
6	2026-08-04 05:53:00+10	3	2	5
6	2026-08-04 05:58:00+10	0	7	7
6	2026-08-04 06:00:00+10	1	2	3
6	2026-08-04 06:01:00+10	1	0	1
6	2026-08-04 06:07:00+10	1	3	4
6	2026-08-04 06:10:00+10	2	0	2
6	2026-08-04 06:11:00+10	3	1	4
6	2026-08-04 06:12:00+10	2	7	9
6	2026-08-04 06:15:00+10	1	6	7
6	2026-08-04 06:16:00+10	1	0	1
6	2026-08-04 06:25:00+10	1	2	3
6	2026-08-04 06:26:00+10	1	0	1
6	2026-08-04 06:29:00+10	0	4	4
6	2026-08-04 06:30:00+10	1	0	1
6	2026-08-04 06:37:00+10	1	1	2
6	2026-08-04 06:47:00+10	1	1	2
6	2026-08-04 06:49:00+10	2	22	24
6	2026-08-04 06:52:00+10	5	1	6
6	2026-08-04 06:53:00+10	0	13	13
6	2026-08-04 06:56:00+10	0	2	2
6	2026-08-04 07:01:00+10	1	6	7
6	2026-08-04 07:03:00+10	4	8	12
6	2026-08-04 07:11:00+10	6	2	8
6	2026-08-04 07:12:00+10	5	10	15
6	2026-08-04 07:13:00+10	2	2	4
6	2026-08-04 07:16:00+10	3	4	7
6	2026-08-04 07:18:00+10	2	3	5
6	2026-08-04 07:19:00+10	1	4	5
6	2026-08-04 07:20:00+10	2	7	9
6	2026-08-04 07:26:00+10	3	8	11
6	2026-08-04 07:27:00+10	5	2	7
6	2026-08-04 07:30:00+10	8	25	33
6	2026-08-04 07:31:00+10	6	25	31
6	2026-08-04 07:34:00+10	1	6	7
6	2026-08-04 07:37:00+10	1	6	7
6	2026-08-04 07:38:00+10	3	5	8
6	2026-08-04 07:39:00+10	3	2	5
6	2026-08-04 07:41:00+10	2	15	17
6	2026-08-04 07:43:00+10	4	30	34
6	2026-08-04 07:49:00+10	1	11	12
6	2026-08-04 07:52:00+10	5	13	18
6	2026-08-04 07:57:00+10	1	15	16
6	2026-08-04 07:58:00+10	3	10	13
6	2026-08-04 08:00:00+10	5	8	13
6	2026-08-04 08:04:00+10	0	53	53
6	2026-08-04 08:06:00+10	7	14	21
6	2026-08-04 08:10:00+10	1	36	37
6	2026-08-04 08:11:00+10	4	36	40
6	2026-08-04 08:14:00+10	8	21	29
6	2026-08-04 08:18:00+10	3	54	57
6	2026-08-04 08:19:00+10	4	48	52
6	2026-08-04 08:24:00+10	6	15	21
6	2026-08-04 08:25:00+10	5	13	18
6	2026-08-04 08:26:00+10	4	7	11
6	2026-08-04 08:29:00+10	8	41	49
6	2026-08-04 08:30:00+10	0	47	47
6	2026-08-04 08:33:00+10	6	48	54
6	2026-08-04 08:39:00+10	5	45	50
6	2026-08-04 08:40:00+10	4	39	43
6	2026-08-04 08:44:00+10	3	27	30
6	2026-08-04 08:49:00+10	3	36	39
6	2026-08-04 08:55:00+10	1	50	51
6	2026-08-04 08:58:00+10	2	16	18
6	2026-08-04 09:01:00+10	2	32	34
6	2026-08-04 09:06:00+10	5	24	29
6	2026-08-04 09:07:00+10	7	50	57
6	2026-08-04 09:09:00+10	2	17	19
6	2026-08-04 09:10:00+10	2	9	11
6	2026-08-04 09:11:00+10	2	12	14
6	2026-08-04 09:14:00+10	3	19	22
6	2026-08-04 09:19:00+10	3	16	19
6	2026-08-04 09:20:00+10	2	7	9
6	2026-08-04 09:21:00+10	1	9	10
6	2026-08-04 09:27:00+10	4	17	21
6	2026-08-04 09:43:00+10	1	2	3
6	2026-08-04 09:52:00+10	0	4	4
6	2026-08-04 09:53:00+10	1	6	7
6	2026-08-04 09:55:00+10	2	2	4
6	2026-08-04 09:57:00+10	2	11	13
6	2026-08-04 09:58:00+10	2	4	6
6	2026-08-04 10:00:00+10	1	5	6
6	2026-08-04 10:02:00+10	0	8	8
6	2026-08-04 10:08:00+10	1	0	1
6	2026-08-04 10:09:00+10	1	3	4
6	2026-08-04 10:10:00+10	2	7	9
6	2026-08-04 10:15:00+10	1	0	1
6	2026-08-04 10:19:00+10	1	6	7
6	2026-08-04 10:20:00+10	0	5	5
6	2026-08-04 10:22:00+10	3	3	6
6	2026-08-04 10:34:00+10	0	1	1
6	2026-08-04 10:35:00+10	2	1	3
6	2026-08-04 10:37:00+10	1	0	1
6	2026-08-04 10:40:00+10	0	2	2
6	2026-08-04 10:41:00+10	0	1	1
6	2026-08-04 10:51:00+10	1	3	4
6	2026-08-04 10:58:00+10	0	5	5
6	2026-08-04 10:59:00+10	2	0	2
6	2026-08-04 11:00:00+10	1	2	3
6	2026-08-04 11:01:00+10	1	0	1
6	2026-08-04 11:04:00+10	1	4	5
6	2026-08-04 11:06:00+10	0	2	2
6	2026-08-04 11:09:00+10	1	2	3
6	2026-08-04 11:10:00+10	1	1	2
6	2026-08-04 11:11:00+10	1	0	1
6	2026-08-04 11:13:00+10	0	4	4
6	2026-08-04 11:14:00+10	3	2	5
6	2026-08-04 11:39:00+10	0	4	4
6	2026-08-04 11:40:00+10	1	4	5
6	2026-08-04 11:41:00+10	3	1	4
6	2026-08-04 11:45:00+10	3	7	10
6	2026-08-04 11:48:00+10	1	1	2
6	2026-08-04 11:50:00+10	1	1	2
6	2026-08-04 11:53:00+10	1	0	1
6	2026-08-04 11:54:00+10	3	2	5
6	2026-08-04 11:56:00+10	4	2	6
6	2026-08-04 12:00:00+10	0	1	1
6	2026-08-04 12:03:00+10	1	1	2
6	2026-08-04 12:06:00+10	3	6	9
6	2026-08-04 12:07:00+10	10	1	11
6	2026-08-04 12:09:00+10	5	4	9
6	2026-08-04 12:11:00+10	4	0	4
6	2026-08-04 12:14:00+10	1	0	1
6	2026-08-04 12:17:00+10	2	0	2
6	2026-08-04 12:23:00+10	0	3	3
6	2026-08-04 12:25:00+10	2	3	5
6	2026-08-04 12:26:00+10	0	1	1
6	2026-08-04 12:31:00+10	4	1	5
6	2026-08-04 12:32:00+10	0	9	9
6	2026-08-04 12:35:00+10	1	1	2
6	2026-08-04 12:37:00+10	0	1	1
6	2026-08-04 12:43:00+10	1	3	4
6	2026-08-04 12:48:00+10	3	1	4
6	2026-08-04 12:50:00+10	1	0	1
6	2026-08-04 12:53:00+10	1	1	2
6	2026-08-04 12:56:00+10	1	10	11
6	2026-08-04 12:58:00+10	0	1	1
6	2026-08-04 13:01:00+10	1	1	2
6	2026-08-04 13:09:00+10	2	7	9
6	2026-08-04 13:12:00+10	0	5	5
6	2026-08-04 13:13:00+10	1	1	2
6	2026-08-04 13:14:00+10	5	0	5
6	2026-08-04 13:16:00+10	2	0	2
6	2026-08-04 13:17:00+10	6	0	6
6	2026-08-04 13:18:00+10	0	1	1
6	2026-08-04 13:21:00+10	1	0	1
6	2026-08-04 13:25:00+10	3	1	4
6	2026-08-04 13:26:00+10	0	3	3
6	2026-08-04 13:36:00+10	9	1	10
6	2026-08-04 13:46:00+10	1	1	2
6	2026-08-04 13:50:00+10	2	0	2
6	2026-08-04 13:56:00+10	5	1	6
6	2026-08-04 13:58:00+10	2	0	2
6	2026-08-04 14:02:00+10	1	1	2
6	2026-08-04 14:07:00+10	4	1	5
6	2026-08-04 14:08:00+10	2	5	7
6	2026-08-04 14:11:00+10	2	0	2
6	2026-08-04 14:12:00+10	2	1	3
6	2026-08-04 14:23:00+10	4	3	7
8	2026-08-03 23:56:00+10	0	1	1
8	2026-08-04 07:01:00+10	1	1	2
8	2026-08-04 07:03:00+10	1	0	1
8	2026-08-04 07:05:00+10	6	1	7
8	2026-08-04 07:09:00+10	3	3	6
8	2026-08-04 07:16:00+10	1	2	3
8	2026-08-04 07:17:00+10	3	1	4
8	2026-08-04 07:18:00+10	3	5	8
8	2026-08-04 07:28:00+10	8	0	8
8	2026-08-04 07:29:00+10	2	3	5
8	2026-08-04 07:32:00+10	3	0	3
8	2026-08-04 07:37:00+10	1	2	3
8	2026-08-04 07:38:00+10	5	3	8
8	2026-08-04 07:41:00+10	1	0	1
8	2026-08-04 07:42:00+10	0	2	2
8	2026-08-04 07:46:00+10	4	1	5
8	2026-08-04 07:47:00+10	9	3	12
8	2026-08-04 07:48:00+10	4	3	7
8	2026-08-04 07:49:00+10	4	2	6
8	2026-08-04 07:50:00+10	6	1	7
8	2026-08-04 07:51:00+10	4	1	5
8	2026-08-04 07:55:00+10	4	3	7
8	2026-08-04 07:56:00+10	7	5	12
8	2026-08-04 07:58:00+10	9	7	16
8	2026-08-04 07:59:00+10	1	0	1
8	2026-08-04 08:00:00+10	2	3	5
8	2026-08-04 08:01:00+10	1	2	3
8	2026-08-04 08:02:00+10	7	1	8
8	2026-08-04 08:06:00+10	5	2	7
8	2026-08-04 08:15:00+10	3	4	7
8	2026-08-04 08:17:00+10	6	3	9
8	2026-08-04 08:18:00+10	2	3	5
8	2026-08-04 08:19:00+10	6	4	10
8	2026-08-04 08:24:00+10	4	4	8
8	2026-08-04 08:27:00+10	4	6	10
8	2026-08-04 08:33:00+10	2	0	2
8	2026-08-04 08:37:00+10	3	4	7
8	2026-08-04 08:40:00+10	5	1	6
8	2026-08-04 08:44:00+10	7	3	10
8	2026-08-04 08:46:00+10	3	4	7
8	2026-08-04 08:53:00+10	5	5	10
8	2026-08-04 08:55:00+10	4	0	4
8	2026-08-04 08:57:00+10	1	2	3
8	2026-08-04 08:58:00+10	7	2	9
8	2026-08-04 09:00:00+10	3	2	5
8	2026-08-04 09:02:00+10	1	3	4
8	2026-08-04 09:23:00+10	5	2	7
8	2026-08-04 09:24:00+10	1	2	3
8	2026-08-04 09:25:00+10	3	0	3
8	2026-08-04 09:27:00+10	3	1	4
8	2026-08-04 09:31:00+10	5	3	8
8	2026-08-04 09:34:00+10	1	0	1
8	2026-08-04 09:38:00+10	3	1	4
8	2026-08-04 09:39:00+10	7	2	9
8	2026-08-04 09:41:00+10	5	1	6
8	2026-08-04 09:46:00+10	3	2	5
8	2026-08-04 09:49:00+10	1	1	2
8	2026-08-04 09:51:00+10	3	0	3
8	2026-08-04 09:52:00+10	7	1	8
8	2026-08-04 09:59:00+10	2	2	4
8	2026-08-04 10:04:00+10	3	2	5
8	2026-08-04 10:08:00+10	1	0	1
8	2026-08-04 10:09:00+10	2	0	2
8	2026-08-04 10:10:00+10	4	3	7
8	2026-08-04 10:13:00+10	3	2	5
8	2026-08-04 10:16:00+10	3	6	9
8	2026-08-04 10:18:00+10	0	1	1
8	2026-08-04 10:20:00+10	1	1	2
8	2026-08-04 10:21:00+10	4	5	9
8	2026-08-04 10:22:00+10	6	3	9
8	2026-08-04 10:26:00+10	1	1	2
8	2026-08-04 10:29:00+10	1	2	3
8	2026-08-04 10:30:00+10	1	3	4
8	2026-08-04 10:39:00+10	2	0	2
8	2026-08-04 10:43:00+10	0	2	2
8	2026-08-04 11:06:00+10	5	1	6
8	2026-08-04 11:11:00+10	1	2	3
8	2026-08-04 11:17:00+10	1	1	2
8	2026-08-04 11:18:00+10	0	3	3
8	2026-08-04 11:19:00+10	2	1	3
8	2026-08-04 11:24:00+10	1	1	2
8	2026-08-04 11:25:00+10	3	4	7
8	2026-08-04 11:29:00+10	2	1	3
8	2026-08-04 11:32:00+10	2	8	10
8	2026-08-04 11:50:00+10	0	3	3
8	2026-08-04 11:53:00+10	2	1	3
8	2026-08-04 11:58:00+10	0	3	3
8	2026-08-04 12:02:00+10	0	1	1
8	2026-08-04 12:05:00+10	1	2	3
8	2026-08-04 12:10:00+10	2	2	4
8	2026-08-04 12:11:00+10	1	4	5
8	2026-08-04 12:19:00+10	0	6	6
8	2026-08-04 12:20:00+10	3	2	5
8	2026-08-04 12:22:00+10	0	3	3
8	2026-08-04 12:26:00+10	0	5	5
8	2026-08-04 12:27:00+10	2	3	5
8	2026-08-04 12:29:00+10	3	6	9
8	2026-08-04 12:33:00+10	3	5	8
8	2026-08-04 12:37:00+10	0	4	4
8	2026-08-04 12:38:00+10	0	6	6
8	2026-08-04 12:41:00+10	1	11	12
8	2026-08-04 12:43:00+10	1	3	4
8	2026-08-04 12:45:00+10	2	10	12
8	2026-08-04 12:52:00+10	2	7	9
8	2026-08-04 12:54:00+10	11	4	15
8	2026-08-04 12:58:00+10	5	4	9
8	2026-08-04 13:01:00+10	7	7	14
8	2026-08-04 13:04:00+10	1	0	1
8	2026-08-04 13:07:00+10	3	6	9
8	2026-08-04 13:08:00+10	6	6	12
8	2026-08-04 13:09:00+10	5	1	6
8	2026-08-04 13:10:00+10	2	9	11
8	2026-08-04 13:14:00+10	8	2	10
8	2026-08-04 13:16:00+10	0	9	9
8	2026-08-04 13:24:00+10	3	4	7
8	2026-08-04 13:29:00+10	6	1	7
8	2026-08-04 13:34:00+10	3	6	9
8	2026-08-04 13:35:00+10	5	1	6
8	2026-08-04 13:40:00+10	2	1	3
8	2026-08-04 13:41:00+10	1	1	2
8	2026-08-04 13:46:00+10	0	7	7
8	2026-08-04 13:54:00+10	2	5	7
8	2026-08-04 13:56:00+10	2	0	2
8	2026-08-04 14:02:00+10	2	8	10
8	2026-08-04 14:04:00+10	5	2	7
8	2026-08-04 14:05:00+10	0	4	4
8	2026-08-04 14:06:00+10	3	8	11
8	2026-08-04 14:10:00+10	0	4	4
8	2026-08-04 14:11:00+10	1	6	7
8	2026-08-04 14:12:00+10	1	2	3
8	2026-08-04 14:13:00+10	1	2	3
8	2026-08-04 14:16:00+10	6	1	7
8	2026-08-04 14:21:00+10	2	2	4
9	2026-08-04 00:08:00+10	1	0	1
9	2026-08-04 00:17:00+10	0	2	2
9	2026-08-04 00:33:00+10	0	1	1
9	2026-08-04 00:42:00+10	0	1	1
9	2026-08-04 01:27:00+10	2	0	2
9	2026-08-04 01:47:00+10	0	1	1
9	2026-08-04 01:52:00+10	0	1	1
9	2026-08-04 03:33:00+10	1	0	1
9	2026-08-04 05:17:00+10	0	4	4
9	2026-08-04 05:20:00+10	1	0	1
9	2026-08-04 05:24:00+10	0	1	1
9	2026-08-04 05:29:00+10	0	1	1
9	2026-08-04 05:30:00+10	1	0	1
9	2026-08-04 05:31:00+10	0	1	1
9	2026-08-04 05:46:00+10	0	1	1
9	2026-08-04 05:47:00+10	0	2	2
9	2026-08-04 05:48:00+10	0	2	2
9	2026-08-04 05:49:00+10	0	1	1
9	2026-08-04 05:50:00+10	0	5	5
9	2026-08-04 05:56:00+10	0	8	8
9	2026-08-04 06:03:00+10	1	0	1
9	2026-08-04 06:07:00+10	1	1	2
9	2026-08-04 06:08:00+10	0	2	2
9	2026-08-04 06:14:00+10	0	1	1
9	2026-08-04 06:17:00+10	0	11	11
9	2026-08-04 06:20:00+10	0	10	10
9	2026-08-04 06:34:00+10	0	15	15
9	2026-08-04 06:36:00+10	0	8	8
9	2026-08-04 06:37:00+10	0	7	7
9	2026-08-04 06:39:00+10	0	4	4
9	2026-08-04 06:40:00+10	0	3	3
9	2026-08-04 06:41:00+10	0	2	2
9	2026-08-04 06:50:00+10	0	2	2
9	2026-08-04 06:51:00+10	1	9	10
9	2026-08-04 06:55:00+10	1	18	19
9	2026-08-04 06:59:00+10	1	12	13
9	2026-08-04 07:00:00+10	2	2	4
9	2026-08-04 07:01:00+10	0	13	13
9	2026-08-04 07:04:00+10	2	4	6
9	2026-08-04 07:10:00+10	0	33	33
9	2026-08-04 07:11:00+10	1	18	19
9	2026-08-04 07:12:00+10	1	27	28
9	2026-08-04 07:16:00+10	1	24	25
9	2026-08-04 07:20:00+10	1	24	25
9	2026-08-04 07:24:00+10	0	1	1
9	2026-08-04 07:25:00+10	4	4	8
9	2026-08-04 07:26:00+10	0	11	11
9	2026-08-04 07:30:00+10	0	15	15
9	2026-08-04 07:31:00+10	0	10	10
9	2026-08-04 07:32:00+10	0	19	19
9	2026-08-04 07:34:00+10	2	37	39
9	2026-08-04 07:37:00+10	2	20	22
9	2026-08-04 07:40:00+10	1	27	28
9	2026-08-04 07:46:00+10	2	32	34
9	2026-08-04 07:48:00+10	0	56	56
9	2026-08-04 07:51:00+10	0	37	37
9	2026-08-04 07:55:00+10	2	8	10
9	2026-08-04 07:57:00+10	0	52	52
9	2026-08-04 07:58:00+10	1	27	28
9	2026-08-04 08:01:00+10	3	29	32
9	2026-08-04 08:06:00+10	2	40	42
9	2026-08-04 08:07:00+10	1	19	20
9	2026-08-04 08:14:00+10	1	42	43
9	2026-08-04 08:21:00+10	3	39	42
9	2026-08-04 08:25:00+10	2	24	26
9	2026-08-04 08:28:00+10	2	49	51
9	2026-08-04 08:29:00+10	1	39	40
9	2026-08-04 08:32:00+10	2	70	72
9	2026-08-04 08:35:00+10	1	68	69
9	2026-08-04 08:36:00+10	2	79	81
9	2026-08-04 08:37:00+10	5	73	78
9	2026-08-04 08:43:00+10	7	75	82
9	2026-08-04 08:44:00+10	5	50	55
9	2026-08-04 08:46:00+10	6	76	82
9	2026-08-04 08:48:00+10	2	40	42
9	2026-08-04 08:52:00+10	1	80	81
9	2026-08-04 08:57:00+10	2	78	80
9	2026-08-04 08:58:00+10	0	70	70
9	2026-08-04 08:59:00+10	0	56	56
9	2026-08-04 09:04:00+10	4	51	55
9	2026-08-04 09:07:00+10	4	52	56
9	2026-08-04 09:08:00+10	2	48	50
9	2026-08-04 09:13:00+10	3	47	50
9	2026-08-04 09:14:00+10	1	49	50
9	2026-08-04 09:17:00+10	0	29	29
9	2026-08-04 09:21:00+10	1	32	33
9	2026-08-04 09:22:00+10	2	40	42
9	2026-08-04 09:23:00+10	4	18	22
9	2026-08-04 09:28:00+10	5	19	24
9	2026-08-04 09:30:00+10	1	19	20
9	2026-08-04 09:34:00+10	4	3	7
9	2026-08-04 09:35:00+10	1	5	6
9	2026-08-04 09:36:00+10	2	15	17
9	2026-08-04 09:42:00+10	5	22	27
9	2026-08-04 09:49:00+10	1	9	10
9	2026-08-04 09:52:00+10	1	13	14
9	2026-08-04 09:53:00+10	1	17	18
9	2026-08-04 09:54:00+10	3	18	21
9	2026-08-04 09:55:00+10	0	5	5
9	2026-08-04 09:56:00+10	0	8	8
9	2026-08-04 09:57:00+10	2	18	20
9	2026-08-04 10:02:00+10	2	11	13
9	2026-08-04 10:03:00+10	2	10	12
9	2026-08-04 10:08:00+10	2	3	5
9	2026-08-04 10:20:00+10	0	9	9
9	2026-08-04 10:21:00+10	0	10	10
9	2026-08-04 10:22:00+10	4	3	7
9	2026-08-04 10:23:00+10	3	13	16
9	2026-08-04 10:24:00+10	0	3	3
9	2026-08-04 10:25:00+10	5	11	16
9	2026-08-04 10:26:00+10	1	12	13
9	2026-08-04 10:27:00+10	1	1	2
9	2026-08-04 10:35:00+10	0	2	2
9	2026-08-04 10:36:00+10	4	8	12
9	2026-08-04 10:37:00+10	2	6	8
9	2026-08-04 10:38:00+10	3	6	9
9	2026-08-04 10:39:00+10	2	7	9
9	2026-08-04 10:41:00+10	0	7	7
9	2026-08-04 10:44:00+10	3	7	10
9	2026-08-04 10:54:00+10	3	4	7
9	2026-08-04 10:57:00+10	2	2	4
9	2026-08-04 11:04:00+10	2	2	4
9	2026-08-04 11:07:00+10	2	5	7
9	2026-08-04 11:08:00+10	1	2	3
9	2026-08-04 11:11:00+10	5	1	6
9	2026-08-04 11:16:00+10	0	8	8
9	2026-08-04 11:18:00+10	0	3	3
9	2026-08-04 11:21:00+10	2	2	4
9	2026-08-04 11:24:00+10	0	1	1
9	2026-08-04 11:27:00+10	2	2	4
9	2026-08-04 11:30:00+10	0	3	3
9	2026-08-04 11:38:00+10	5	3	8
9	2026-08-04 11:42:00+10	7	2	9
9	2026-08-04 11:45:00+10	7	0	7
9	2026-08-04 11:55:00+10	5	4	9
9	2026-08-04 11:58:00+10	1	4	5
9	2026-08-04 11:59:00+10	2	3	5
9	2026-08-04 12:00:00+10	10	2	12
9	2026-08-04 12:01:00+10	1	0	1
9	2026-08-04 12:07:00+10	7	5	12
9	2026-08-04 12:15:00+10	8	11	19
9	2026-08-04 12:16:00+10	17	5	22
9	2026-08-04 12:17:00+10	5	6	11
9	2026-08-04 12:19:00+10	8	10	18
9	2026-08-04 12:20:00+10	10	10	20
9	2026-08-04 12:22:00+10	5	4	9
9	2026-08-04 12:25:00+10	7	4	11
9	2026-08-04 12:28:00+10	11	6	17
9	2026-08-04 12:31:00+10	11	6	17
9	2026-08-04 12:32:00+10	8	5	13
9	2026-08-04 12:34:00+10	8	5	13
9	2026-08-04 12:36:00+10	8	2	10
9	2026-08-04 12:38:00+10	5	10	15
9	2026-08-04 12:39:00+10	11	6	17
9	2026-08-04 12:40:00+10	15	6	21
9	2026-08-04 12:45:00+10	1	1	2
9	2026-08-04 12:50:00+10	8	7	15
9	2026-08-04 12:58:00+10	4	6	10
9	2026-08-04 12:59:00+10	11	11	22
9	2026-08-04 13:00:00+10	4	16	20
9	2026-08-04 13:03:00+10	7	8	15
9	2026-08-04 13:06:00+10	7	3	10
9	2026-08-04 13:07:00+10	9	5	14
9	2026-08-04 13:08:00+10	6	8	14
9	2026-08-04 13:11:00+10	10	6	16
9	2026-08-04 13:12:00+10	5	6	11
9	2026-08-04 13:19:00+10	6	8	14
9	2026-08-04 13:21:00+10	8	9	17
9	2026-08-04 13:22:00+10	5	21	26
9	2026-08-04 13:23:00+10	6	2	8
9	2026-08-04 13:24:00+10	4	10	14
9	2026-08-04 13:26:00+10	5	5	10
9	2026-08-04 13:27:00+10	5	5	10
9	2026-08-04 13:30:00+10	9	5	14
9	2026-08-04 13:31:00+10	8	12	20
9	2026-08-04 13:41:00+10	3	3	6
9	2026-08-04 13:42:00+10	2	6	8
9	2026-08-04 13:48:00+10	4	10	14
9	2026-08-04 13:51:00+10	14	8	22
9	2026-08-04 13:54:00+10	3	4	7
9	2026-08-04 13:58:00+10	3	6	9
9	2026-08-04 14:00:00+10	13	2	15
9	2026-08-04 14:08:00+10	4	4	8
9	2026-08-04 14:09:00+10	5	1	6
9	2026-08-04 14:11:00+10	8	6	14
9	2026-08-04 14:13:00+10	7	1	8
9	2026-08-04 14:16:00+10	3	0	3
9	2026-08-04 14:22:00+10	4	5	9
9	2026-08-04 14:23:00+10	5	2	7
9	2026-08-04 14:24:00+10	14	2	16
9	2026-08-04 14:29:00+10	3	2	5
9	2026-08-04 14:33:00+10	4	0	4
9	2026-08-04 14:34:00+10	8	4	12
9	2026-08-04 14:35:00+10	6	4	10
9	2026-08-04 14:38:00+10	9	1	10
9	2026-08-04 14:39:00+10	6	0	6
10	2026-08-04 00:01:00+10	1	0	1
10	2026-08-04 05:45:00+10	0	3	3
10	2026-08-04 05:55:00+10	0	1	1
10	2026-08-04 06:04:00+10	0	1	1
10	2026-08-04 06:24:00+10	1	0	1
10	2026-08-04 06:28:00+10	0	2	2
10	2026-08-04 06:31:00+10	0	2	2
10	2026-08-04 06:32:00+10	0	1	1
10	2026-08-04 06:34:00+10	0	1	1
10	2026-08-04 06:44:00+10	0	2	2
10	2026-08-04 06:45:00+10	0	1	1
10	2026-08-04 06:46:00+10	0	2	2
10	2026-08-04 06:54:00+10	0	1	1
10	2026-08-04 06:59:00+10	0	3	3
10	2026-08-04 07:05:00+10	0	1	1
10	2026-08-04 07:09:00+10	0	1	1
10	2026-08-04 07:10:00+10	1	0	1
10	2026-08-04 07:15:00+10	1	5	6
10	2026-08-04 07:16:00+10	1	3	4
10	2026-08-04 07:18:00+10	0	1	1
10	2026-08-04 07:20:00+10	0	4	4
10	2026-08-04 07:21:00+10	0	1	1
10	2026-08-04 07:22:00+10	0	1	1
10	2026-08-04 07:36:00+10	1	2	3
10	2026-08-04 07:42:00+10	1	0	1
10	2026-08-04 07:47:00+10	0	1	1
10	2026-08-04 07:48:00+10	2	0	2
10	2026-08-04 07:49:00+10	1	4	5
10	2026-08-04 07:52:00+10	1	3	4
10	2026-08-04 07:54:00+10	0	4	4
10	2026-08-04 07:56:00+10	0	3	3
10	2026-08-04 08:01:00+10	0	4	4
10	2026-08-04 08:02:00+10	1	2	3
10	2026-08-04 08:06:00+10	1	1	2
10	2026-08-04 08:12:00+10	1	1	2
10	2026-08-04 08:18:00+10	0	1	1
10	2026-08-04 08:19:00+10	0	1	1
10	2026-08-04 08:21:00+10	0	1	1
10	2026-08-04 08:24:00+10	1	3	4
10	2026-08-04 08:27:00+10	1	1	2
10	2026-08-04 08:39:00+10	0	2	2
10	2026-08-04 08:40:00+10	0	5	5
10	2026-08-04 08:41:00+10	0	2	2
10	2026-08-04 08:42:00+10	1	2	3
10	2026-08-04 08:43:00+10	2	2	4
10	2026-08-04 08:47:00+10	0	6	6
10	2026-08-04 08:52:00+10	0	6	6
10	2026-08-04 08:53:00+10	0	5	5
10	2026-08-04 08:55:00+10	2	4	6
10	2026-08-04 08:57:00+10	2	2	4
10	2026-08-04 09:01:00+10	4	0	4
10	2026-08-04 09:03:00+10	2	3	5
10	2026-08-04 09:07:00+10	2	2	4
10	2026-08-04 09:14:00+10	0	2	2
10	2026-08-04 09:16:00+10	2	1	3
10	2026-08-04 09:17:00+10	2	0	2
10	2026-08-04 09:19:00+10	0	3	3
10	2026-08-04 09:23:00+10	1	0	1
10	2026-08-04 09:29:00+10	0	3	3
10	2026-08-04 09:30:00+10	1	1	2
10	2026-08-04 09:34:00+10	1	1	2
10	2026-08-04 09:37:00+10	0	3	3
10	2026-08-04 09:43:00+10	3	1	4
10	2026-08-04 09:45:00+10	0	1	1
10	2026-08-04 09:57:00+10	4	3	7
10	2026-08-04 09:58:00+10	1	1	2
10	2026-08-04 10:08:00+10	3	0	3
10	2026-08-04 10:10:00+10	2	1	3
10	2026-08-04 10:11:00+10	0	1	1
10	2026-08-04 10:17:00+10	1	0	1
10	2026-08-04 10:18:00+10	1	0	1
10	2026-08-04 10:22:00+10	2	1	3
10	2026-08-04 10:27:00+10	0	1	1
10	2026-08-04 10:43:00+10	1	0	1
10	2026-08-04 10:47:00+10	1	2	3
10	2026-08-04 10:49:00+10	1	0	1
10	2026-08-04 10:53:00+10	1	1	2
10	2026-08-04 10:59:00+10	1	1	2
10	2026-08-04 11:01:00+10	1	0	1
10	2026-08-04 11:18:00+10	0	1	1
10	2026-08-04 11:20:00+10	3	1	4
10	2026-08-04 11:24:00+10	2	2	4
10	2026-08-04 11:26:00+10	1	1	2
10	2026-08-04 11:32:00+10	1	0	1
10	2026-08-04 11:37:00+10	1	1	2
10	2026-08-04 11:38:00+10	1	0	1
10	2026-08-04 11:45:00+10	0	1	1
10	2026-08-04 11:48:00+10	1	0	1
10	2026-08-04 11:51:00+10	1	0	1
10	2026-08-04 11:57:00+10	0	1	1
10	2026-08-04 12:01:00+10	2	0	2
10	2026-08-04 12:05:00+10	8	0	8
10	2026-08-04 12:09:00+10	0	4	4
10	2026-08-04 12:10:00+10	11	0	11
10	2026-08-04 12:11:00+10	2	4	6
10	2026-08-04 12:17:00+10	7	1	8
10	2026-08-04 12:19:00+10	1	2	3
10	2026-08-04 12:20:00+10	8	1	9
10	2026-08-04 12:24:00+10	3	0	3
10	2026-08-04 12:25:00+10	3	1	4
10	2026-08-04 12:26:00+10	0	2	2
10	2026-08-04 12:31:00+10	4	0	4
10	2026-08-04 12:33:00+10	3	1	4
10	2026-08-04 12:36:00+10	6	1	7
10	2026-08-04 12:37:00+10	3	0	3
10	2026-08-04 12:45:00+10	3	4	7
10	2026-08-04 12:51:00+10	12	1	13
10	2026-08-04 12:53:00+10	2	2	4
10	2026-08-04 12:55:00+10	0	3	3
10	2026-08-04 12:57:00+10	2	1	3
10	2026-08-04 12:59:00+10	1	7	8
10	2026-08-04 13:00:00+10	0	4	4
10	2026-08-04 13:05:00+10	1	3	4
10	2026-08-04 13:11:00+10	5	0	5
10	2026-08-04 13:12:00+10	1	6	7
10	2026-08-04 13:18:00+10	0	1	1
10	2026-08-04 13:22:00+10	0	1	1
10	2026-08-04 13:30:00+10	0	3	3
10	2026-08-04 13:38:00+10	2	0	2
10	2026-08-04 13:43:00+10	1	2	3
10	2026-08-04 13:48:00+10	1	1	2
10	2026-08-04 13:50:00+10	1	1	2
10	2026-08-04 13:51:00+10	1	2	3
10	2026-08-04 13:53:00+10	1	0	1
10	2026-08-04 13:56:00+10	4	0	4
10	2026-08-04 14:01:00+10	2	0	2
10	2026-08-04 14:02:00+10	1	3	4
10	2026-08-04 14:05:00+10	5	0	5
10	2026-08-04 14:15:00+10	2	1	3
10	2026-08-04 14:17:00+10	4	0	4
10	2026-08-04 14:26:00+10	1	0	1
10	2026-08-04 14:29:00+10	1	0	1
10	2026-08-04 14:30:00+10	2	1	3
10	2026-08-04 14:31:00+10	1	2	3
10	2026-08-04 14:35:00+10	7	1	8
10	2026-08-04 14:37:00+10	2	1	3
11	2026-08-03 23:58:00+10	1	0	1
11	2026-08-04 00:05:00+10	0	1	1
11	2026-08-04 00:15:00+10	1	2	3
11	2026-08-04 00:45:00+10	1	0	1
11	2026-08-04 01:05:00+10	0	1	1
11	2026-08-04 01:27:00+10	0	2	2
11	2026-08-04 01:35:00+10	0	1	1
11	2026-08-04 03:35:00+10	0	2	2
11	2026-08-04 03:47:00+10	1	0	1
11	2026-08-04 05:55:00+10	0	1	1
11	2026-08-04 06:20:00+10	1	1	2
11	2026-08-04 06:24:00+10	1	0	1
11	2026-08-04 06:32:00+10	0	1	1
11	2026-08-04 06:34:00+10	1	0	1
11	2026-08-04 06:35:00+10	1	0	1
11	2026-08-04 06:46:00+10	1	1	2
11	2026-08-04 06:50:00+10	2	2	4
11	2026-08-04 06:57:00+10	1	0	1
11	2026-08-04 07:09:00+10	1	0	1
11	2026-08-04 07:18:00+10	1	0	1
11	2026-08-04 07:42:00+10	1	0	1
11	2026-08-04 07:44:00+10	1	0	1
11	2026-08-04 07:45:00+10	5	2	7
11	2026-08-04 07:53:00+10	0	1	1
11	2026-08-04 07:55:00+10	3	1	4
11	2026-08-04 08:03:00+10	1	0	1
11	2026-08-04 08:11:00+10	0	1	1
11	2026-08-04 08:16:00+10	0	1	1
11	2026-08-04 08:25:00+10	5	4	9
11	2026-08-04 08:29:00+10	0	1	1
11	2026-08-04 08:34:00+10	0	3	3
11	2026-08-04 08:35:00+10	2	2	4
11	2026-08-04 08:39:00+10	1	0	1
11	2026-08-04 08:40:00+10	4	7	11
11	2026-08-04 08:44:00+10	1	1	2
11	2026-08-04 08:49:00+10	1	0	1
11	2026-08-04 08:50:00+10	3	6	9
11	2026-08-04 08:57:00+10	2	2	4
11	2026-08-04 09:00:00+10	1	4	5
11	2026-08-04 09:01:00+10	0	1	1
11	2026-08-04 09:04:00+10	1	0	1
11	2026-08-04 09:07:00+10	0	1	1
11	2026-08-04 09:09:00+10	1	2	3
11	2026-08-04 09:10:00+10	4	3	7
11	2026-08-04 09:19:00+10	1	0	1
11	2026-08-04 09:33:00+10	1	0	1
11	2026-08-04 09:39:00+10	0	3	3
11	2026-08-04 09:40:00+10	3	3	6
11	2026-08-04 09:45:00+10	2	0	2
11	2026-08-04 09:47:00+10	1	0	1
11	2026-08-04 09:51:00+10	0	1	1
11	2026-08-04 09:56:00+10	0	2	2
11	2026-08-04 10:00:00+10	1	1	2
11	2026-08-04 10:02:00+10	0	1	1
11	2026-08-04 10:30:00+10	0	2	2
11	2026-08-04 10:36:00+10	2	0	2
11	2026-08-04 10:38:00+10	1	0	1
11	2026-08-04 10:44:00+10	1	0	1
11	2026-08-04 10:48:00+10	0	1	1
11	2026-08-04 10:50:00+10	3	1	4
11	2026-08-04 10:52:00+10	0	1	1
11	2026-08-04 10:59:00+10	0	1	1
11	2026-08-04 11:00:00+10	2	3	5
11	2026-08-04 11:04:00+10	1	0	1
11	2026-08-04 11:05:00+10	2	1	3
11	2026-08-04 11:11:00+10	1	0	1
11	2026-08-04 11:12:00+10	0	1	1
11	2026-08-04 11:23:00+10	0	1	1
11	2026-08-04 11:28:00+10	1	0	1
11	2026-08-04 11:34:00+10	0	1	1
11	2026-08-04 11:35:00+10	2	0	2
11	2026-08-04 11:36:00+10	1	0	1
11	2026-08-04 11:42:00+10	1	0	1
11	2026-08-04 11:50:00+10	1	0	1
11	2026-08-04 12:00:00+10	0	2	2
11	2026-08-04 12:04:00+10	1	0	1
11	2026-08-04 12:13:00+10	1	0	1
11	2026-08-04 12:20:00+10	0	2	2
11	2026-08-04 12:24:00+10	1	0	1
11	2026-08-04 12:36:00+10	1	1	2
11	2026-08-04 12:40:00+10	9	3	12
11	2026-08-04 12:44:00+10	2	0	2
11	2026-08-04 12:48:00+10	0	2	2
11	2026-08-04 12:51:00+10	1	1	2
11	2026-08-04 12:53:00+10	2	0	2
11	2026-08-04 12:55:00+10	7	2	9
11	2026-08-04 13:02:00+10	2	0	2
11	2026-08-04 13:05:00+10	4	3	7
11	2026-08-04 13:08:00+10	1	0	1
11	2026-08-04 13:12:00+10	4	0	4
11	2026-08-04 13:13:00+10	1	0	1
11	2026-08-04 13:14:00+10	1	2	3
11	2026-08-04 13:18:00+10	0	8	8
11	2026-08-04 13:19:00+10	0	1	1
11	2026-08-04 13:21:00+10	2	0	2
11	2026-08-04 13:23:00+10	1	0	1
11	2026-08-04 13:26:00+10	1	1	2
11	2026-08-04 13:28:00+10	4	0	4
11	2026-08-04 13:32:00+10	0	1	1
11	2026-08-04 13:37:00+10	0	2	2
11	2026-08-04 13:58:00+10	1	0	1
11	2026-08-04 14:05:00+10	1	5	6
11	2026-08-04 14:19:00+10	0	1	1
11	2026-08-04 14:23:00+10	0	1	1
11	2026-08-04 14:30:00+10	2	0	2
11	2026-08-04 14:32:00+10	1	0	1
11	2026-08-04 14:38:00+10	3	0	3
11	2026-08-04 14:39:00+10	1	0	1
12	2026-08-04 01:17:00+10	0	1	1
12	2026-08-04 01:24:00+10	0	1	1
12	2026-08-04 05:56:00+10	1	0	1
12	2026-08-04 06:17:00+10	2	0	2
12	2026-08-04 06:46:00+10	0	1	1
12	2026-08-04 07:01:00+10	1	0	1
12	2026-08-04 07:06:00+10	1	0	1
12	2026-08-04 07:07:00+10	1	0	1
12	2026-08-04 07:08:00+10	1	0	1
12	2026-08-04 07:16:00+10	1	0	1
12	2026-08-04 07:17:00+10	1	0	1
12	2026-08-04 07:21:00+10	1	0	1
12	2026-08-04 07:23:00+10	1	0	1
12	2026-08-04 07:26:00+10	0	2	2
12	2026-08-04 07:30:00+10	1	3	4
12	2026-08-04 07:35:00+10	1	0	1
12	2026-08-04 07:37:00+10	3	0	3
12	2026-08-04 07:41:00+10	0	1	1
12	2026-08-04 07:45:00+10	3	0	3
12	2026-08-04 07:46:00+10	5	0	5
12	2026-08-04 07:48:00+10	4	1	5
12	2026-08-04 07:53:00+10	1	1	2
12	2026-08-04 07:57:00+10	2	4	6
12	2026-08-04 08:00:00+10	0	3	3
12	2026-08-04 08:01:00+10	1	0	1
12	2026-08-04 08:06:00+10	3	3	6
12	2026-08-04 08:10:00+10	0	1	1
12	2026-08-04 08:11:00+10	0	3	3
12	2026-08-04 08:16:00+10	4	1	5
12	2026-08-04 08:19:00+10	4	0	4
12	2026-08-04 08:25:00+10	3	1	4
12	2026-08-04 08:26:00+10	3	2	5
12	2026-08-04 08:27:00+10	4	3	7
12	2026-08-04 08:28:00+10	3	4	7
12	2026-08-04 08:29:00+10	5	1	6
12	2026-08-04 08:30:00+10	4	2	6
12	2026-08-04 08:32:00+10	0	3	3
12	2026-08-04 08:35:00+10	1	0	1
12	2026-08-04 08:38:00+10	1	2	3
12	2026-08-04 08:40:00+10	3	1	4
12	2026-08-04 08:42:00+10	0	1	1
12	2026-08-04 08:43:00+10	3	5	8
12	2026-08-04 08:46:00+10	2	0	2
12	2026-08-04 08:47:00+10	3	8	11
12	2026-08-04 08:49:00+10	1	7	8
12	2026-08-04 08:52:00+10	2	3	5
12	2026-08-04 08:53:00+10	4	1	5
12	2026-08-04 08:54:00+10	3	1	4
12	2026-08-04 08:56:00+10	0	5	5
12	2026-08-04 08:57:00+10	3	2	5
12	2026-08-04 09:04:00+10	4	1	5
12	2026-08-04 09:05:00+10	2	3	5
12	2026-08-04 09:10:00+10	1	0	1
12	2026-08-04 09:17:00+10	7	4	11
12	2026-08-04 09:18:00+10	0	1	1
12	2026-08-04 09:19:00+10	1	0	1
12	2026-08-04 09:26:00+10	2	1	3
12	2026-08-04 09:29:00+10	3	1	4
12	2026-08-04 09:30:00+10	4	1	5
12	2026-08-04 09:35:00+10	1	1	2
12	2026-08-04 09:37:00+10	2	0	2
12	2026-08-04 09:38:00+10	1	1	2
12	2026-08-04 09:40:00+10	1	2	3
12	2026-08-04 09:43:00+10	2	0	2
12	2026-08-04 09:46:00+10	2	0	2
12	2026-08-04 09:49:00+10	0	1	1
12	2026-08-04 09:53:00+10	1	0	1
12	2026-08-04 09:56:00+10	1	0	1
12	2026-08-04 09:59:00+10	1	0	1
12	2026-08-04 10:01:00+10	3	0	3
12	2026-08-04 10:04:00+10	2	0	2
12	2026-08-04 10:06:00+10	1	3	4
12	2026-08-04 10:07:00+10	1	3	4
12	2026-08-04 10:09:00+10	0	3	3
12	2026-08-04 10:12:00+10	1	0	1
12	2026-08-04 10:16:00+10	1	0	1
12	2026-08-04 10:19:00+10	1	0	1
12	2026-08-04 10:32:00+10	0	2	2
12	2026-08-04 10:35:00+10	1	2	3
12	2026-08-04 10:38:00+10	1	1	2
12	2026-08-04 10:41:00+10	1	0	1
12	2026-08-04 10:44:00+10	2	0	2
12	2026-08-04 10:46:00+10	3	1	4
12	2026-08-04 10:47:00+10	1	1	2
12	2026-08-04 10:48:00+10	1	2	3
12	2026-08-04 10:51:00+10	2	1	3
12	2026-08-04 10:59:00+10	1	3	4
12	2026-08-04 11:00:00+10	1	1	2
12	2026-08-04 11:03:00+10	3	3	6
12	2026-08-04 11:06:00+10	2	0	2
12	2026-08-04 11:10:00+10	0	2	2
12	2026-08-04 11:11:00+10	1	2	3
12	2026-08-04 11:12:00+10	1	0	1
12	2026-08-04 11:15:00+10	2	1	3
12	2026-08-04 11:17:00+10	1	1	2
12	2026-08-04 11:20:00+10	1	0	1
12	2026-08-04 11:25:00+10	1	0	1
12	2026-08-04 11:27:00+10	1	1	2
12	2026-08-04 11:30:00+10	3	0	3
12	2026-08-04 11:38:00+10	2	0	2
12	2026-08-04 12:01:00+10	1	0	1
12	2026-08-04 12:03:00+10	0	1	1
12	2026-08-04 12:04:00+10	1	2	3
12	2026-08-04 12:06:00+10	0	3	3
12	2026-08-04 12:07:00+10	8	1	9
12	2026-08-04 12:13:00+10	0	2	2
12	2026-08-04 12:15:00+10	0	2	2
12	2026-08-04 12:19:00+10	1	8	9
12	2026-08-04 12:22:00+10	1	3	4
12	2026-08-04 12:23:00+10	2	2	4
12	2026-08-04 12:25:00+10	2	4	6
12	2026-08-04 12:28:00+10	0	3	3
12	2026-08-04 12:35:00+10	2	4	6
12	2026-08-04 12:38:00+10	4	0	4
12	2026-08-04 12:40:00+10	5	3	8
12	2026-08-04 12:41:00+10	1	2	3
12	2026-08-04 12:50:00+10	0	1	1
12	2026-08-04 12:52:00+10	0	6	6
12	2026-08-04 12:54:00+10	0	1	1
12	2026-08-04 13:11:00+10	1	1	2
12	2026-08-04 13:12:00+10	4	2	6
12	2026-08-04 13:16:00+10	0	47	47
12	2026-08-04 13:19:00+10	4	1	5
12	2026-08-04 13:22:00+10	0	2	2
12	2026-08-04 13:23:00+10	2	2	4
12	2026-08-04 13:24:00+10	6	2	8
12	2026-08-04 13:25:00+10	1	2	3
12	2026-08-04 13:26:00+10	4	1	5
12	2026-08-04 13:28:00+10	1	3	4
12	2026-08-04 13:29:00+10	0	1	1
12	2026-08-04 13:33:00+10	1	6	7
12	2026-08-04 13:34:00+10	3	3	6
12	2026-08-04 13:36:00+10	0	1	1
12	2026-08-04 13:38:00+10	0	1	1
12	2026-08-04 13:41:00+10	1	0	1
12	2026-08-04 13:43:00+10	2	8	10
12	2026-08-04 13:49:00+10	2	0	2
12	2026-08-04 13:50:00+10	2	0	2
12	2026-08-04 13:52:00+10	0	1	1
12	2026-08-04 13:56:00+10	0	2	2
12	2026-08-04 14:04:00+10	3	3	6
12	2026-08-04 14:06:00+10	2	2	4
12	2026-08-04 14:08:00+10	3	0	3
12	2026-08-04 14:15:00+10	2	0	2
12	2026-08-04 14:20:00+10	2	1	3
12	2026-08-04 14:21:00+10	2	7	9
12	2026-08-04 14:23:00+10	4	0	4
12	2026-08-04 14:24:00+10	1	1	2
12	2026-08-04 14:30:00+10	6	1	7
12	2026-08-04 14:32:00+10	1	1	2
12	2026-08-04 14:35:00+10	2	0	2
12	2026-08-04 14:36:00+10	4	1	5
14	2026-08-04 14:05:00+10	2	0	2
14	2026-08-04 14:06:00+10	2	0	2
14	2026-08-04 14:07:00+10	3	0	3
14	2026-08-04 14:08:00+10	3	2	5
14	2026-08-04 14:09:00+10	13	7	20
14	2026-08-04 14:10:00+10	6	0	6
14	2026-08-04 14:14:00+10	1	1	2
14	2026-08-04 14:15:00+10	3	0	3
14	2026-08-04 14:24:00+10	5	3	8
17	2026-08-04 00:05:00+10	0	1	1
17	2026-08-04 00:09:00+10	0	1	1
17	2026-08-04 00:14:00+10	0	1	1
17	2026-08-04 00:15:00+10	1	2	3
17	2026-08-04 00:29:00+10	1	3	4
17	2026-08-04 00:34:00+10	1	0	1
17	2026-08-04 00:46:00+10	1	0	1
17	2026-08-04 00:55:00+10	0	2	2
17	2026-08-04 01:29:00+10	0	2	2
17	2026-08-04 01:55:00+10	0	2	2
17	2026-08-04 02:11:00+10	1	0	1
17	2026-08-04 02:25:00+10	0	2	2
17	2026-08-04 02:28:00+10	2	1	3
17	2026-08-04 04:08:00+10	0	1	1
17	2026-08-04 04:09:00+10	0	1	1
17	2026-08-04 04:17:00+10	1	0	1
17	2026-08-04 04:23:00+10	1	0	1
17	2026-08-04 04:49:00+10	0	1	1
17	2026-08-04 04:50:00+10	1	0	1
17	2026-08-04 04:52:00+10	0	1	1
17	2026-08-04 05:10:00+10	0	1	1
17	2026-08-04 05:14:00+10	1	0	1
17	2026-08-04 05:23:00+10	0	1	1
17	2026-08-04 05:24:00+10	0	2	2
17	2026-08-04 05:32:00+10	0	1	1
17	2026-08-04 05:44:00+10	1	0	1
17	2026-08-04 05:50:00+10	0	1	1
17	2026-08-04 05:51:00+10	3	0	3
17	2026-08-04 05:52:00+10	1	0	1
17	2026-08-04 05:53:00+10	3	0	3
17	2026-08-04 05:55:00+10	0	1	1
17	2026-08-04 06:00:00+10	1	0	1
17	2026-08-04 06:04:00+10	2	0	2
17	2026-08-04 06:06:00+10	0	1	1
17	2026-08-04 06:07:00+10	0	4	4
17	2026-08-04 06:08:00+10	1	0	1
17	2026-08-04 06:10:00+10	3	0	3
17	2026-08-04 06:12:00+10	1	0	1
17	2026-08-04 06:16:00+10	1	0	1
17	2026-08-04 06:19:00+10	1	0	1
17	2026-08-04 06:21:00+10	1	1	2
17	2026-08-04 06:22:00+10	1	3	4
17	2026-08-04 06:29:00+10	2	1	3
17	2026-08-04 06:30:00+10	3	0	3
17	2026-08-04 06:31:00+10	1	1	2
17	2026-08-04 06:36:00+10	1	1	2
17	2026-08-04 06:38:00+10	1	0	1
17	2026-08-04 06:40:00+10	2	0	2
17	2026-08-04 06:44:00+10	2	1	3
17	2026-08-04 06:51:00+10	4	0	4
17	2026-08-04 06:52:00+10	3	1	4
17	2026-08-04 06:53:00+10	2	0	2
17	2026-08-04 07:02:00+10	2	0	2
17	2026-08-04 07:10:00+10	3	0	3
17	2026-08-04 07:17:00+10	4	1	5
17	2026-08-04 07:18:00+10	2	1	3
17	2026-08-04 07:19:00+10	1	0	1
17	2026-08-04 07:20:00+10	3	1	4
17	2026-08-04 07:21:00+10	9	3	12
17	2026-08-04 07:29:00+10	5	0	5
17	2026-08-04 07:32:00+10	8	1	9
17	2026-08-04 07:40:00+10	11	0	11
17	2026-08-04 07:43:00+10	15	3	18
17	2026-08-04 07:44:00+10	9	4	13
17	2026-08-04 07:49:00+10	4	1	5
17	2026-08-04 07:50:00+10	12	2	14
17	2026-08-04 07:53:00+10	8	1	9
17	2026-08-04 07:55:00+10	15	1	16
17	2026-08-04 07:56:00+10	14	2	16
17	2026-08-04 08:00:00+10	10	2	12
17	2026-08-04 08:01:00+10	14	3	17
17	2026-08-04 08:02:00+10	10	0	10
17	2026-08-04 08:06:00+10	20	3	23
17	2026-08-04 08:07:00+10	13	4	17
17	2026-08-04 08:09:00+10	15	1	16
17	2026-08-04 08:10:00+10	17	3	20
17	2026-08-04 08:12:00+10	31	3	34
17	2026-08-04 08:13:00+10	26	2	28
17	2026-08-04 08:14:00+10	35	5	40
17	2026-08-04 08:15:00+10	12	2	14
17	2026-08-04 08:18:00+10	24	3	27
17	2026-08-04 08:19:00+10	16	3	19
17	2026-08-04 08:21:00+10	47	0	47
17	2026-08-04 08:24:00+10	15	6	21
17	2026-08-04 08:27:00+10	21	4	25
17	2026-08-04 08:31:00+10	17	9	26
17	2026-08-04 08:33:00+10	16	3	19
17	2026-08-04 08:35:00+10	16	3	19
17	2026-08-04 08:39:00+10	48	2	50
17	2026-08-04 08:41:00+10	51	4	55
17	2026-08-04 08:43:00+10	18	5	23
17	2026-08-04 08:44:00+10	25	2	27
17	2026-08-04 08:45:00+10	18	9	27
17	2026-08-04 08:48:00+10	33	1	34
17	2026-08-04 08:49:00+10	20	6	26
17	2026-08-04 08:55:00+10	19	9	28
17	2026-08-04 08:57:00+10	41	0	41
17	2026-08-04 08:58:00+10	16	5	21
17	2026-08-04 09:01:00+10	14	2	16
17	2026-08-04 09:02:00+10	24	11	35
17	2026-08-04 09:04:00+10	17	10	27
17	2026-08-04 09:08:00+10	20	5	25
17	2026-08-04 09:09:00+10	26	13	39
17	2026-08-04 09:10:00+10	39	6	45
17	2026-08-04 09:13:00+10	27	5	32
17	2026-08-04 09:15:00+10	15	4	19
17	2026-08-04 09:20:00+10	15	1	16
17	2026-08-04 09:21:00+10	9	6	15
17	2026-08-04 09:24:00+10	8	25	33
17	2026-08-04 09:27:00+10	9	10	19
17	2026-08-04 09:30:00+10	11	5	16
17	2026-08-04 09:32:00+10	7	1	8
17	2026-08-04 09:33:00+10	20	8	28
17	2026-08-04 09:40:00+10	18	4	22
17	2026-08-04 09:41:00+10	18	4	22
17	2026-08-04 09:43:00+10	10	6	16
17	2026-08-04 09:52:00+10	2	4	6
17	2026-08-04 09:53:00+10	8	7	15
17	2026-08-04 09:54:00+10	15	2	17
17	2026-08-04 10:00:00+10	12	9	21
17	2026-08-04 10:01:00+10	13	8	21
17	2026-08-04 10:03:00+10	9	8	17
17	2026-08-04 10:04:00+10	3	9	12
17	2026-08-04 10:05:00+10	6	6	12
17	2026-08-04 10:11:00+10	7	3	10
17	2026-08-04 10:12:00+10	4	5	9
17	2026-08-04 10:13:00+10	10	2	12
17	2026-08-04 10:23:00+10	2	2	4
17	2026-08-04 10:25:00+10	7	5	12
17	2026-08-04 10:26:00+10	9	5	14
17	2026-08-04 10:28:00+10	7	3	10
17	2026-08-04 10:30:00+10	10	5	15
17	2026-08-04 10:34:00+10	10	5	15
17	2026-08-04 10:35:00+10	4	4	8
17	2026-08-04 10:36:00+10	3	3	6
17	2026-08-04 10:37:00+10	4	4	8
17	2026-08-04 10:39:00+10	7	2	9
17	2026-08-04 10:40:00+10	3	4	7
17	2026-08-04 10:42:00+10	3	4	7
17	2026-08-04 10:52:00+10	2	6	8
17	2026-08-04 10:53:00+10	15	5	20
17	2026-08-04 10:57:00+10	2	3	5
17	2026-08-04 11:03:00+10	5	6	11
17	2026-08-04 11:08:00+10	5	7	12
17	2026-08-04 11:14:00+10	9	3	12
17	2026-08-04 11:16:00+10	7	5	12
17	2026-08-04 11:18:00+10	9	2	11
17	2026-08-04 11:22:00+10	4	2	6
17	2026-08-04 11:23:00+10	9	2	11
17	2026-08-04 11:26:00+10	11	9	20
17	2026-08-04 11:27:00+10	4	4	8
17	2026-08-04 11:28:00+10	9	2	11
17	2026-08-04 11:30:00+10	4	6	10
17	2026-08-04 11:32:00+10	8	4	12
17	2026-08-04 11:34:00+10	10	4	14
17	2026-08-04 11:35:00+10	4	3	7
17	2026-08-04 11:37:00+10	24	4	28
17	2026-08-04 11:41:00+10	2	1	3
17	2026-08-04 11:42:00+10	1	5	6
17	2026-08-04 11:44:00+10	7	2	9
17	2026-08-04 11:46:00+10	7	1	8
17	2026-08-04 11:48:00+10	5	9	14
17	2026-08-04 11:51:00+10	6	0	6
17	2026-08-04 11:53:00+10	3	5	8
17	2026-08-04 11:54:00+10	5	4	9
17	2026-08-04 11:55:00+10	1	3	4
17	2026-08-04 11:57:00+10	9	3	12
17	2026-08-04 11:58:00+10	6	1	7
17	2026-08-04 12:00:00+10	2	2	4
17	2026-08-04 12:05:00+10	11	5	16
17	2026-08-04 12:06:00+10	4	5	9
17	2026-08-04 12:08:00+10	4	3	7
17	2026-08-04 12:10:00+10	8	7	15
17	2026-08-04 12:14:00+10	20	12	32
17	2026-08-04 12:15:00+10	8	3	11
17	2026-08-04 12:20:00+10	17	15	32
17	2026-08-04 12:24:00+10	3	8	11
17	2026-08-04 12:29:00+10	8	6	14
17	2026-08-04 12:32:00+10	4	6	10
17	2026-08-04 12:45:00+10	23	18	41
17	2026-08-04 12:46:00+10	16	11	27
17	2026-08-04 12:54:00+10	10	6	16
17	2026-08-04 12:55:00+10	15	14	29
17	2026-08-04 12:57:00+10	6	16	22
17	2026-08-04 13:00:00+10	20	12	32
17	2026-08-04 13:06:00+10	12	15	27
17	2026-08-04 13:07:00+10	14	15	29
17	2026-08-04 13:09:00+10	7	20	27
17	2026-08-04 13:20:00+10	7	10	17
17	2026-08-04 13:26:00+10	12	14	26
17	2026-08-04 13:28:00+10	8	11	19
17	2026-08-04 13:32:00+10	8	12	20
17	2026-08-04 13:38:00+10	5	9	14
17	2026-08-04 13:39:00+10	12	12	24
17	2026-08-04 13:42:00+10	6	6	12
17	2026-08-04 13:43:00+10	16	8	24
17	2026-08-04 13:47:00+10	11	8	19
17	2026-08-04 13:48:00+10	11	5	16
17	2026-08-04 13:49:00+10	11	5	16
17	2026-08-04 13:53:00+10	3	8	11
17	2026-08-04 13:55:00+10	18	5	23
17	2026-08-04 13:57:00+10	7	11	18
17	2026-08-04 13:58:00+10	2	6	8
17	2026-08-04 13:59:00+10	4	6	10
17	2026-08-04 14:00:00+10	5	6	11
17	2026-08-04 14:02:00+10	8	15	23
17	2026-08-04 14:04:00+10	5	8	13
17	2026-08-04 14:05:00+10	8	6	14
17	2026-08-04 14:09:00+10	5	7	12
17	2026-08-04 14:13:00+10	6	4	10
17	2026-08-04 14:15:00+10	5	3	8
17	2026-08-04 14:16:00+10	8	9	17
17	2026-08-04 14:17:00+10	5	6	11
17	2026-08-04 14:23:00+10	5	10	15
17	2026-08-04 14:25:00+10	5	9	14
17	2026-08-04 14:27:00+10	4	4	8
17	2026-08-04 14:28:00+10	9	6	15
17	2026-08-04 14:31:00+10	6	8	14
17	2026-08-04 14:33:00+10	5	8	13
17	2026-08-04 14:37:00+10	7	6	13
18	2026-08-04 05:52:00+10	0	1	1
18	2026-08-04 05:56:00+10	0	2	2
18	2026-08-04 06:14:00+10	0	1	1
18	2026-08-04 06:28:00+10	0	1	1
18	2026-08-04 06:37:00+10	0	2	2
18	2026-08-04 06:49:00+10	0	1	1
18	2026-08-04 06:58:00+10	0	1	1
18	2026-08-04 07:06:00+10	0	1	1
18	2026-08-04 07:09:00+10	0	2	2
18	2026-08-04 07:12:00+10	1	1	2
18	2026-08-04 07:25:00+10	0	5	5
18	2026-08-04 07:28:00+10	0	6	6
18	2026-08-04 07:29:00+10	1	6	7
18	2026-08-04 07:31:00+10	2	7	9
18	2026-08-04 07:32:00+10	0	9	9
18	2026-08-04 07:38:00+10	0	3	3
18	2026-08-04 07:40:00+10	1	3	4
18	2026-08-04 07:42:00+10	0	11	11
18	2026-08-04 07:47:00+10	0	13	13
18	2026-08-04 07:48:00+10	1	4	5
18	2026-08-04 07:51:00+10	0	18	18
18	2026-08-04 07:52:00+10	0	9	9
18	2026-08-04 07:57:00+10	0	4	4
18	2026-08-04 07:58:00+10	0	3	3
18	2026-08-04 08:02:00+10	2	22	24
18	2026-08-04 08:13:00+10	0	33	33
18	2026-08-04 08:14:00+10	1	9	10
18	2026-08-04 08:15:00+10	4	8	12
18	2026-08-04 08:17:00+10	0	4	4
18	2026-08-04 08:19:00+10	0	30	30
18	2026-08-04 08:21:00+10	0	48	48
18	2026-08-04 08:28:00+10	1	28	29
18	2026-08-04 08:30:00+10	1	40	41
18	2026-08-04 08:32:00+10	1	32	33
18	2026-08-04 08:35:00+10	0	7	7
18	2026-08-04 08:41:00+10	2	19	21
18	2026-08-04 08:50:00+10	2	18	20
18	2026-08-04 08:54:00+10	2	38	40
18	2026-08-04 08:55:00+10	2	25	27
18	2026-08-04 09:01:00+10	2	19	21
18	2026-08-04 09:09:00+10	1	36	37
18	2026-08-04 09:14:00+10	1	13	14
18	2026-08-04 09:15:00+10	0	5	5
18	2026-08-04 09:17:00+10	1	0	1
18	2026-08-04 09:18:00+10	1	2	3
18	2026-08-04 09:23:00+10	2	20	22
18	2026-08-04 09:26:00+10	0	14	14
18	2026-08-04 09:28:00+10	2	12	14
18	2026-08-04 09:29:00+10	2	3	5
18	2026-08-04 09:34:00+10	9	4	13
18	2026-08-04 09:37:00+10	0	9	9
18	2026-08-04 09:38:00+10	0	3	3
18	2026-08-04 09:41:00+10	5	5	10
18	2026-08-04 09:43:00+10	2	7	9
18	2026-08-04 09:49:00+10	3	3	6
18	2026-08-04 09:51:00+10	0	3	3
18	2026-08-04 09:52:00+10	3	9	12
18	2026-08-04 09:54:00+10	0	8	8
18	2026-08-04 09:56:00+10	0	4	4
18	2026-08-04 10:09:00+10	2	5	7
18	2026-08-04 10:10:00+10	3	6	9
18	2026-08-04 10:16:00+10	4	1	5
18	2026-08-04 10:17:00+10	3	1	4
18	2026-08-04 10:21:00+10	0	2	2
18	2026-08-04 10:23:00+10	1	5	6
18	2026-08-04 10:24:00+10	2	2	4
18	2026-08-04 10:26:00+10	1	0	1
18	2026-08-04 10:31:00+10	0	1	1
18	2026-08-04 10:32:00+10	1	7	8
18	2026-08-04 10:33:00+10	2	3	5
18	2026-08-04 10:34:00+10	2	3	5
18	2026-08-04 10:35:00+10	2	3	5
18	2026-08-04 10:37:00+10	0	8	8
18	2026-08-04 10:38:00+10	1	0	1
18	2026-08-04 10:41:00+10	2	1	3
18	2026-08-04 10:45:00+10	4	4	8
18	2026-08-04 10:46:00+10	1	2	3
18	2026-08-04 10:47:00+10	0	5	5
18	2026-08-04 10:51:00+10	2	2	4
18	2026-08-04 10:53:00+10	4	4	8
18	2026-08-04 11:01:00+10	1	2	3
18	2026-08-04 11:05:00+10	3	2	5
18	2026-08-04 11:07:00+10	4	1	5
18	2026-08-04 11:08:00+10	0	3	3
18	2026-08-04 11:12:00+10	1	0	1
18	2026-08-04 11:15:00+10	1	1	2
18	2026-08-04 11:25:00+10	3	4	7
18	2026-08-04 11:27:00+10	1	4	5
18	2026-08-04 11:31:00+10	20	1	21
18	2026-08-04 11:33:00+10	0	2	2
18	2026-08-04 11:37:00+10	2	4	6
18	2026-08-04 11:42:00+10	0	2	2
18	2026-08-04 11:44:00+10	3	2	5
18	2026-08-04 11:53:00+10	1	0	1
18	2026-08-04 12:02:00+10	1	0	1
18	2026-08-04 12:03:00+10	3	2	5
18	2026-08-04 12:06:00+10	1	3	4
18	2026-08-04 12:12:00+10	1	6	7
18	2026-08-04 12:13:00+10	1	2	3
18	2026-08-04 12:14:00+10	1	4	5
18	2026-08-04 12:17:00+10	2	1	3
18	2026-08-04 12:18:00+10	0	5	5
18	2026-08-04 12:21:00+10	2	1	3
18	2026-08-04 12:34:00+10	2	3	5
18	2026-08-04 12:36:00+10	1	1	2
18	2026-08-04 12:38:00+10	5	4	9
18	2026-08-04 12:42:00+10	1	1	2
18	2026-08-04 12:44:00+10	0	1	1
18	2026-08-04 12:47:00+10	4	3	7
18	2026-08-04 12:48:00+10	0	5	5
18	2026-08-04 12:50:00+10	5	1	6
18	2026-08-04 12:59:00+10	11	4	15
18	2026-08-04 13:00:00+10	3	2	5
18	2026-08-04 13:02:00+10	2	0	2
18	2026-08-04 13:05:00+10	1	1	2
18	2026-08-04 13:18:00+10	9	4	13
18	2026-08-04 13:20:00+10	4	6	10
18	2026-08-04 13:21:00+10	2	4	6
18	2026-08-04 13:22:00+10	7	4	11
18	2026-08-04 13:28:00+10	2	4	6
18	2026-08-04 13:29:00+10	6	5	11
18	2026-08-04 13:32:00+10	5	2	7
18	2026-08-04 13:33:00+10	5	3	8
18	2026-08-04 13:34:00+10	1	4	5
18	2026-08-04 13:38:00+10	2	4	6
18	2026-08-04 13:40:00+10	6	1	7
18	2026-08-04 13:41:00+10	1	1	2
18	2026-08-04 13:46:00+10	6	5	11
18	2026-08-04 13:48:00+10	8	3	11
18	2026-08-04 13:50:00+10	4	5	9
18	2026-08-04 13:51:00+10	5	3	8
18	2026-08-04 13:53:00+10	1	5	6
18	2026-08-04 13:56:00+10	2	2	4
18	2026-08-04 14:05:00+10	2	4	6
18	2026-08-04 14:09:00+10	6	4	10
18	2026-08-04 14:12:00+10	6	3	9
18	2026-08-04 14:13:00+10	1	1	2
18	2026-08-04 14:14:00+10	1	2	3
18	2026-08-04 14:16:00+10	4	1	5
18	2026-08-04 14:23:00+10	3	1	4
18	2026-08-04 14:25:00+10	1	5	6
18	2026-08-04 14:33:00+10	8	2	10
18	2026-08-04 14:34:00+10	5	4	9
18	2026-08-04 14:36:00+10	4	3	7
19	2026-08-04 00:00:00+10	0	1	1
19	2026-08-04 00:01:00+10	0	1	1
19	2026-08-04 00:04:00+10	0	1	1
19	2026-08-04 00:09:00+10	0	2	2
19	2026-08-04 00:13:00+10	1	0	1
19	2026-08-04 00:14:00+10	0	5	5
19	2026-08-04 00:25:00+10	1	1	2
19	2026-08-04 00:34:00+10	2	2	4
19	2026-08-04 00:40:00+10	1	0	1
19	2026-08-04 00:41:00+10	1	0	1
19	2026-08-04 00:50:00+10	2	1	3
19	2026-08-04 00:57:00+10	0	2	2
19	2026-08-04 01:00:00+10	2	0	2
19	2026-08-04 01:11:00+10	0	2	2
19	2026-08-04 01:12:00+10	2	0	2
19	2026-08-04 01:14:00+10	0	1	1
19	2026-08-04 01:24:00+10	1	0	1
19	2026-08-04 01:27:00+10	0	1	1
19	2026-08-04 01:35:00+10	2	0	2
19	2026-08-04 01:52:00+10	2	0	2
19	2026-08-04 01:55:00+10	1	2	3
19	2026-08-04 01:58:00+10	2	0	2
19	2026-08-04 02:39:00+10	4	0	4
19	2026-08-04 04:01:00+10	0	1	1
19	2026-08-04 04:14:00+10	0	1	1
19	2026-08-04 04:18:00+10	0	1	1
19	2026-08-04 04:26:00+10	1	1	2
19	2026-08-04 04:40:00+10	0	1	1
19	2026-08-04 05:46:00+10	1	0	1
19	2026-08-04 06:07:00+10	0	1	1
19	2026-08-04 06:11:00+10	0	1	1
19	2026-08-04 06:12:00+10	1	0	1
19	2026-08-04 06:16:00+10	1	0	1
19	2026-08-04 06:19:00+10	2	0	2
19	2026-08-04 06:24:00+10	0	1	1
19	2026-08-04 06:29:00+10	1	0	1
19	2026-08-04 06:39:00+10	0	1	1
19	2026-08-04 06:43:00+10	1	0	1
19	2026-08-04 06:45:00+10	3	0	3
19	2026-08-04 06:59:00+10	2	1	3
19	2026-08-04 07:02:00+10	1	0	1
19	2026-08-04 07:07:00+10	0	1	1
19	2026-08-04 07:13:00+10	1	0	1
19	2026-08-04 07:20:00+10	0	1	1
19	2026-08-04 07:27:00+10	3	0	3
19	2026-08-04 07:44:00+10	1	1	2
19	2026-08-04 07:47:00+10	1	0	1
19	2026-08-04 07:50:00+10	0	2	2
19	2026-08-04 07:52:00+10	1	0	1
19	2026-08-04 08:02:00+10	0	1	1
19	2026-08-04 08:06:00+10	1	1	2
19	2026-08-04 08:10:00+10	2	0	2
19	2026-08-04 08:15:00+10	2	0	2
19	2026-08-04 08:20:00+10	2	2	4
19	2026-08-04 08:30:00+10	1	0	1
19	2026-08-04 08:39:00+10	1	1	2
19	2026-08-04 08:40:00+10	1	2	3
19	2026-08-04 08:43:00+10	0	2	2
19	2026-08-04 08:44:00+10	2	2	4
19	2026-08-04 08:46:00+10	3	0	3
19	2026-08-04 08:51:00+10	1	1	2
19	2026-08-04 08:52:00+10	1	1	2
19	2026-08-04 08:55:00+10	1	0	1
19	2026-08-04 08:56:00+10	1	0	1
19	2026-08-04 08:59:00+10	1	0	1
19	2026-08-04 09:00:00+10	0	1	1
19	2026-08-04 09:01:00+10	1	1	2
19	2026-08-04 09:02:00+10	1	0	1
19	2026-08-04 09:03:00+10	4	0	4
19	2026-08-04 09:05:00+10	4	0	4
19	2026-08-04 09:10:00+10	4	1	5
19	2026-08-04 09:12:00+10	3	0	3
19	2026-08-04 09:13:00+10	4	1	5
19	2026-08-04 09:15:00+10	1	1	2
19	2026-08-04 09:16:00+10	1	1	2
19	2026-08-04 09:17:00+10	0	2	2
19	2026-08-04 09:19:00+10	1	0	1
19	2026-08-04 09:21:00+10	2	3	5
19	2026-08-04 09:23:00+10	1	0	1
19	2026-08-04 09:24:00+10	1	0	1
19	2026-08-04 09:32:00+10	2	2	4
19	2026-08-04 09:33:00+10	0	2	2
19	2026-08-04 09:35:00+10	3	1	4
19	2026-08-04 09:36:00+10	3	0	3
19	2026-08-04 09:40:00+10	2	1	3
19	2026-08-04 09:41:00+10	3	2	5
19	2026-08-04 09:46:00+10	1	0	1
19	2026-08-04 09:49:00+10	3	1	4
19	2026-08-04 09:53:00+10	1	4	5
19	2026-08-04 09:55:00+10	3	2	5
19	2026-08-04 10:04:00+10	6	1	7
19	2026-08-04 10:10:00+10	0	3	3
19	2026-08-04 10:16:00+10	4	0	4
19	2026-08-04 10:20:00+10	3	0	3
19	2026-08-04 10:23:00+10	2	0	2
19	2026-08-04 10:28:00+10	1	0	1
19	2026-08-04 10:29:00+10	1	3	4
19	2026-08-04 10:32:00+10	0	1	1
19	2026-08-04 10:33:00+10	2	1	3
19	2026-08-04 10:37:00+10	4	0	4
19	2026-08-04 10:38:00+10	1	0	1
19	2026-08-04 10:39:00+10	4	1	5
19	2026-08-04 10:42:00+10	3	4	7
19	2026-08-04 10:43:00+10	3	2	5
19	2026-08-04 10:44:00+10	4	1	5
19	2026-08-04 10:47:00+10	12	0	12
19	2026-08-04 10:50:00+10	2	2	4
19	2026-08-04 10:52:00+10	5	4	9
19	2026-08-04 11:01:00+10	5	2	7
19	2026-08-04 11:06:00+10	6	3	9
19	2026-08-04 11:14:00+10	1	4	5
19	2026-08-04 11:15:00+10	6	7	13
19	2026-08-04 11:16:00+10	5	2	7
19	2026-08-04 11:19:00+10	8	6	14
19	2026-08-04 11:21:00+10	2	0	2
19	2026-08-04 11:24:00+10	4	3	7
19	2026-08-04 11:29:00+10	1	6	7
19	2026-08-04 11:31:00+10	6	5	11
19	2026-08-04 11:36:00+10	3	1	4
19	2026-08-04 11:37:00+10	5	6	11
19	2026-08-04 11:39:00+10	6	1	7
19	2026-08-04 11:42:00+10	0	4	4
19	2026-08-04 11:45:00+10	4	8	12
19	2026-08-04 11:48:00+10	17	5	22
19	2026-08-04 11:51:00+10	7	9	16
19	2026-08-04 11:55:00+10	5	10	15
19	2026-08-04 11:56:00+10	1	4	5
19	2026-08-04 11:58:00+10	9	4	13
19	2026-08-04 12:00:00+10	9	9	18
19	2026-08-04 12:02:00+10	0	7	7
19	2026-08-04 12:03:00+10	2	5	7
19	2026-08-04 12:06:00+10	2	1	3
19	2026-08-04 12:13:00+10	14	6	20
19	2026-08-04 12:19:00+10	4	3	7
19	2026-08-04 12:21:00+10	10	2	12
19	2026-08-04 12:23:00+10	6	13	19
19	2026-08-04 12:24:00+10	9	1	10
19	2026-08-04 12:25:00+10	9	7	16
19	2026-08-04 12:26:00+10	6	5	11
19	2026-08-04 12:32:00+10	4	7	11
19	2026-08-04 12:35:00+10	8	10	18
19	2026-08-04 12:36:00+10	2	5	7
19	2026-08-04 12:41:00+10	4	11	15
19	2026-08-04 12:42:00+10	2	5	7
19	2026-08-04 12:43:00+10	6	5	11
19	2026-08-04 12:44:00+10	4	8	12
19	2026-08-04 12:48:00+10	11	7	18
19	2026-08-04 12:52:00+10	5	15	20
19	2026-08-04 12:53:00+10	8	5	13
19	2026-08-04 12:56:00+10	0	10	10
19	2026-08-04 12:58:00+10	4	10	14
19	2026-08-04 13:02:00+10	9	10	19
19	2026-08-04 13:03:00+10	2	3	5
19	2026-08-04 13:05:00+10	15	6	21
19	2026-08-04 13:07:00+10	4	8	12
19	2026-08-04 13:10:00+10	7	5	12
19	2026-08-04 13:14:00+10	4	6	10
19	2026-08-04 13:21:00+10	10	10	20
19	2026-08-04 13:29:00+10	7	1	8
19	2026-08-04 13:32:00+10	0	7	7
19	2026-08-04 13:34:00+10	7	11	18
19	2026-08-04 13:35:00+10	2	5	7
19	2026-08-04 13:38:00+10	5	8	13
19	2026-08-04 13:51:00+10	12	6	18
19	2026-08-04 13:52:00+10	1	9	10
19	2026-08-04 13:53:00+10	5	1	6
19	2026-08-04 13:54:00+10	7	5	12
19	2026-08-04 13:55:00+10	4	5	9
19	2026-08-04 14:00:00+10	14	4	18
19	2026-08-04 14:01:00+10	5	8	13
19	2026-08-04 14:02:00+10	3	14	17
19	2026-08-04 14:08:00+10	0	11	11
19	2026-08-04 14:10:00+10	10	8	18
19	2026-08-04 14:15:00+10	1	9	10
19	2026-08-04 14:16:00+10	5	4	9
19	2026-08-04 14:17:00+10	11	5	16
19	2026-08-04 14:20:00+10	10	14	24
19	2026-08-04 14:22:00+10	0	1	1
19	2026-08-04 14:26:00+10	8	6	14
19	2026-08-04 14:28:00+10	2	9	11
19	2026-08-04 14:30:00+10	5	4	9
19	2026-08-04 14:32:00+10	16	4	20
19	2026-08-04 14:33:00+10	7	8	15
19	2026-08-04 14:36:00+10	6	8	14
19	2026-08-04 14:39:00+10	14	9	23
20	2026-08-04 00:03:00+10	1	0	1
20	2026-08-04 00:05:00+10	0	3	3
20	2026-08-04 00:16:00+10	0	1	1
20	2026-08-04 00:21:00+10	0	3	3
20	2026-08-04 00:30:00+10	0	2	2
20	2026-08-04 00:56:00+10	1	0	1
20	2026-08-04 01:29:00+10	1	0	1
20	2026-08-04 01:42:00+10	1	0	1
20	2026-08-04 01:43:00+10	0	2	2
20	2026-08-04 01:52:00+10	0	1	1
20	2026-08-04 02:51:00+10	0	1	1
20	2026-08-04 02:53:00+10	0	1	1
20	2026-08-04 03:19:00+10	0	2	2
20	2026-08-04 05:16:00+10	0	1	1
20	2026-08-04 05:45:00+10	0	1	1
20	2026-08-04 05:57:00+10	1	0	1
20	2026-08-04 06:22:00+10	0	1	1
20	2026-08-04 06:28:00+10	0	2	2
20	2026-08-04 06:50:00+10	2	0	2
20	2026-08-04 06:54:00+10	1	0	1
20	2026-08-04 07:00:00+10	0	2	2
20	2026-08-04 07:03:00+10	0	3	3
20	2026-08-04 07:04:00+10	0	3	3
20	2026-08-04 07:16:00+10	2	0	2
20	2026-08-04 07:20:00+10	0	1	1
20	2026-08-04 07:21:00+10	0	1	1
20	2026-08-04 07:32:00+10	1	0	1
20	2026-08-04 07:34:00+10	0	1	1
20	2026-08-04 07:35:00+10	1	0	1
20	2026-08-04 07:36:00+10	0	1	1
20	2026-08-04 07:40:00+10	0	1	1
20	2026-08-04 07:41:00+10	0	1	1
20	2026-08-04 07:53:00+10	0	3	3
20	2026-08-04 07:58:00+10	0	1	1
20	2026-08-04 08:00:00+10	2	1	3
20	2026-08-04 08:09:00+10	1	1	2
20	2026-08-04 08:16:00+10	0	1	1
20	2026-08-04 08:17:00+10	0	4	4
20	2026-08-04 08:25:00+10	0	2	2
20	2026-08-04 08:26:00+10	0	1	1
20	2026-08-04 08:32:00+10	3	1	4
20	2026-08-04 08:33:00+10	1	0	1
20	2026-08-04 08:35:00+10	0	1	1
20	2026-08-04 08:37:00+10	0	1	1
20	2026-08-04 08:44:00+10	0	1	1
20	2026-08-04 08:45:00+10	0	1	1
20	2026-08-04 08:48:00+10	0	1	1
20	2026-08-04 08:49:00+10	0	4	4
20	2026-08-04 08:50:00+10	1	0	1
20	2026-08-04 08:52:00+10	3	1	4
20	2026-08-04 08:53:00+10	3	0	3
20	2026-08-04 08:54:00+10	1	1	2
20	2026-08-04 08:55:00+10	2	1	3
20	2026-08-04 08:58:00+10	1	2	3
20	2026-08-04 09:04:00+10	1	0	1
20	2026-08-04 09:10:00+10	3	0	3
20	2026-08-04 09:15:00+10	1	0	1
20	2026-08-04 09:17:00+10	1	1	2
20	2026-08-04 09:19:00+10	0	1	1
20	2026-08-04 09:25:00+10	2	1	3
20	2026-08-04 09:34:00+10	1	0	1
20	2026-08-04 09:41:00+10	3	0	3
20	2026-08-04 09:42:00+10	2	1	3
20	2026-08-04 09:49:00+10	2	0	2
20	2026-08-04 09:50:00+10	2	1	3
20	2026-08-04 09:55:00+10	2	5	7
20	2026-08-04 09:58:00+10	0	1	1
20	2026-08-04 10:12:00+10	1	1	2
20	2026-08-04 10:24:00+10	1	3	4
20	2026-08-04 10:29:00+10	3	0	3
20	2026-08-04 10:35:00+10	1	2	3
20	2026-08-04 10:37:00+10	0	2	2
20	2026-08-04 10:38:00+10	1	0	1
20	2026-08-04 10:40:00+10	2	2	4
20	2026-08-04 10:44:00+10	1	0	1
20	2026-08-04 10:45:00+10	2	2	4
20	2026-08-04 10:46:00+10	4	2	6
20	2026-08-04 10:47:00+10	1	2	3
20	2026-08-04 10:51:00+10	0	6	6
20	2026-08-04 10:52:00+10	5	3	8
20	2026-08-04 10:54:00+10	1	2	3
20	2026-08-04 10:55:00+10	2	0	2
20	2026-08-04 11:02:00+10	0	3	3
20	2026-08-04 11:09:00+10	1	1	2
20	2026-08-04 11:10:00+10	1	2	3
20	2026-08-04 11:13:00+10	3	1	4
20	2026-08-04 11:16:00+10	1	6	7
20	2026-08-04 11:21:00+10	0	4	4
20	2026-08-04 11:30:00+10	0	4	4
20	2026-08-04 11:32:00+10	9	0	9
20	2026-08-04 11:40:00+10	4	2	6
20	2026-08-04 11:42:00+10	0	1	1
20	2026-08-04 11:44:00+10	4	1	5
20	2026-08-04 11:48:00+10	2	1	3
20	2026-08-04 11:49:00+10	2	0	2
20	2026-08-04 11:58:00+10	1	1	2
20	2026-08-04 11:59:00+10	2	5	7
20	2026-08-04 12:01:00+10	14	2	16
20	2026-08-04 12:08:00+10	4	0	4
20	2026-08-04 12:11:00+10	5	0	5
20	2026-08-04 12:17:00+10	4	1	5
20	2026-08-04 12:18:00+10	2	2	4
20	2026-08-04 12:25:00+10	6	3	9
20	2026-08-04 12:27:00+10	0	6	6
20	2026-08-04 12:34:00+10	3	7	10
20	2026-08-04 12:35:00+10	1	3	4
20	2026-08-04 12:37:00+10	2	5	7
20	2026-08-04 12:41:00+10	6	7	13
20	2026-08-04 12:42:00+10	2	5	7
20	2026-08-04 12:50:00+10	4	3	7
20	2026-08-04 12:51:00+10	3	4	7
20	2026-08-04 12:54:00+10	3	5	8
20	2026-08-04 12:55:00+10	5	4	9
20	2026-08-04 12:57:00+10	11	1	12
20	2026-08-04 13:00:00+10	1	2	3
20	2026-08-04 13:03:00+10	7	1	8
20	2026-08-04 13:07:00+10	3	12	15
20	2026-08-04 13:10:00+10	4	0	4
20	2026-08-04 13:15:00+10	6	4	10
20	2026-08-04 13:16:00+10	4	4	8
20	2026-08-04 13:22:00+10	5	1	6
20	2026-08-04 13:26:00+10	6	1	7
20	2026-08-04 13:30:00+10	2	7	9
20	2026-08-04 13:32:00+10	1	3	4
20	2026-08-04 13:34:00+10	22	0	22
20	2026-08-04 13:36:00+10	4	6	10
20	2026-08-04 13:40:00+10	2	7	9
20	2026-08-04 13:42:00+10	9	7	16
20	2026-08-04 13:44:00+10	3	6	9
20	2026-08-04 13:45:00+10	5	8	13
20	2026-08-04 13:46:00+10	0	5	5
20	2026-08-04 13:52:00+10	1	3	4
20	2026-08-04 13:55:00+10	0	6	6
20	2026-08-04 13:57:00+10	5	1	6
20	2026-08-04 13:59:00+10	3	4	7
20	2026-08-04 14:00:00+10	1	5	6
20	2026-08-04 14:04:00+10	5	1	6
20	2026-08-04 14:06:00+10	1	7	8
20	2026-08-04 14:08:00+10	1	1	2
20	2026-08-04 14:09:00+10	1	1	2
20	2026-08-04 14:14:00+10	1	4	5
20	2026-08-04 14:18:00+10	8	1	9
20	2026-08-04 14:21:00+10	1	3	4
20	2026-08-04 14:25:00+10	2	1	3
20	2026-08-04 14:31:00+10	0	4	4
20	2026-08-04 14:35:00+10	0	1	1
21	2026-08-03 23:55:00+10	1	0	1
21	2026-08-04 00:20:00+10	2	5	7
21	2026-08-04 00:45:00+10	1	2	3
21	2026-08-04 01:20:00+10	0	2	2
21	2026-08-04 01:50:00+10	0	1	1
21	2026-08-04 03:10:00+10	3	0	3
21	2026-08-04 06:40:00+10	0	2	2
21	2026-08-04 06:45:00+10	1	2	3
21	2026-08-04 06:50:00+10	0	5	5
21	2026-08-04 07:00:00+10	0	4	4
21	2026-08-04 07:15:00+10	2	2	4
21	2026-08-04 07:25:00+10	1	4	5
21	2026-08-04 07:55:00+10	2	6	8
21	2026-08-04 08:20:00+10	7	12	19
21	2026-08-04 08:25:00+10	9	10	19
21	2026-08-04 08:30:00+10	9	9	18
21	2026-08-04 08:45:00+10	11	15	26
21	2026-08-04 09:00:00+10	7	2	9
21	2026-08-04 09:05:00+10	14	6	20
21	2026-08-04 09:15:00+10	4	5	9
21	2026-08-04 09:25:00+10	5	8	13
21	2026-08-04 09:50:00+10	8	8	16
21	2026-08-04 10:05:00+10	4	8	12
21	2026-08-04 10:25:00+10	13	16	29
21	2026-08-04 10:35:00+10	18	2	20
21	2026-08-04 10:45:00+10	12	11	23
21	2026-08-04 10:55:00+10	25	13	38
21	2026-08-04 11:00:00+10	19	14	33
21	2026-08-04 11:10:00+10	27	20	47
21	2026-08-04 11:20:00+10	32	22	54
21	2026-08-04 11:30:00+10	10	27	37
21	2026-08-04 11:55:00+10	15	10	25
21	2026-08-04 12:00:00+10	22	22	44
21	2026-08-04 12:10:00+10	52	25	77
21	2026-08-04 12:25:00+10	32	39	71
21	2026-08-04 12:40:00+10	40	44	84
21	2026-08-04 12:45:00+10	43	61	104
21	2026-08-04 13:30:00+10	28	47	75
21	2026-08-04 13:35:00+10	46	60	106
21	2026-08-04 14:00:00+10	26	45	71
21	2026-08-04 14:05:00+10	30	29	59
21	2026-08-04 14:20:00+10	40	25	65
23	2026-08-04 00:05:00+10	0	2	2
23	2026-08-04 00:15:00+10	1	1	2
23	2026-08-04 00:25:00+10	4	4	8
23	2026-08-04 00:35:00+10	0	3	3
23	2026-08-04 00:45:00+10	0	1	1
23	2026-08-04 02:15:00+10	0	1	1
23	2026-08-04 03:15:00+10	1	0	1
23	2026-08-04 03:25:00+10	0	1	1
23	2026-08-04 04:20:00+10	1	0	1
23	2026-08-04 05:05:00+10	0	1	1
23	2026-08-04 05:35:00+10	2	0	2
23	2026-08-04 05:40:00+10	3	1	4
23	2026-08-04 05:55:00+10	5	3	8
23	2026-08-04 06:00:00+10	3	5	8
23	2026-08-04 06:15:00+10	6	6	12
23	2026-08-04 06:20:00+10	4	6	10
23	2026-08-04 06:45:00+10	3	8	11
23	2026-08-04 06:50:00+10	14	7	21
23	2026-08-04 07:05:00+10	12	19	31
23	2026-08-04 07:20:00+10	25	13	38
23	2026-08-04 07:25:00+10	25	8	33
23	2026-08-04 07:30:00+10	41	16	57
23	2026-08-04 07:55:00+10	42	18	60
23	2026-08-04 08:05:00+10	34	28	62
23	2026-08-04 08:10:00+10	73	27	100
23	2026-08-04 08:30:00+10	89	45	134
23	2026-08-04 08:35:00+10	83	23	106
23	2026-08-04 08:40:00+10	82	33	115
23	2026-08-04 08:45:00+10	91	45	136
23	2026-08-04 08:50:00+10	29	11	40
23	2026-08-04 09:10:00+10	68	24	92
23	2026-08-04 09:15:00+10	47	33	80
23	2026-08-04 09:30:00+10	26	12	38
23	2026-08-04 09:35:00+10	38	15	53
23	2026-08-04 09:40:00+10	41	13	54
23	2026-08-04 09:50:00+10	37	24	61
23	2026-08-04 09:55:00+10	21	19	40
23	2026-08-04 10:00:00+10	17	20	37
23	2026-08-04 10:05:00+10	14	17	31
23	2026-08-04 10:10:00+10	28	11	39
23	2026-08-04 10:20:00+10	20	24	44
23	2026-08-04 11:20:00+10	11	14	25
23	2026-08-04 11:25:00+10	7	19	26
23	2026-08-04 11:40:00+10	6	39	45
23	2026-08-04 11:55:00+10	7	9	16
23	2026-08-04 12:20:00+10	37	31	68
23	2026-08-04 12:25:00+10	46	34	80
23	2026-08-04 12:35:00+10	33	46	79
23	2026-08-04 12:45:00+10	43	71	114
23	2026-08-04 13:15:00+10	41	31	72
23	2026-08-04 13:30:00+10	20	52	72
23	2026-08-04 13:45:00+10	20	42	62
23	2026-08-04 14:20:00+10	6	24	30
23	2026-08-04 14:35:00+10	14	17	31
24	2026-08-03 23:56:00+10	0	1	1
24	2026-08-04 00:00:00+10	2	0	2
24	2026-08-04 00:04:00+10	1	0	1
24	2026-08-04 00:07:00+10	0	2	2
24	2026-08-04 00:08:00+10	1	0	1
24	2026-08-04 00:14:00+10	0	3	3
24	2026-08-04 00:21:00+10	1	2	3
24	2026-08-04 00:29:00+10	3	0	3
24	2026-08-04 00:34:00+10	0	1	1
24	2026-08-04 00:35:00+10	0	2	2
24	2026-08-04 00:36:00+10	0	9	9
24	2026-08-04 00:37:00+10	5	1	6
24	2026-08-04 00:40:00+10	2	0	2
24	2026-08-04 00:44:00+10	3	1	4
24	2026-08-04 00:50:00+10	1	0	1
24	2026-08-04 00:53:00+10	0	4	4
24	2026-08-04 01:12:00+10	2	0	2
24	2026-08-04 01:15:00+10	0	1	1
24	2026-08-04 01:24:00+10	1	0	1
24	2026-08-04 01:50:00+10	1	0	1
24	2026-08-04 01:53:00+10	0	2	2
24	2026-08-04 02:33:00+10	0	1	1
24	2026-08-04 02:34:00+10	2	2	4
24	2026-08-04 02:36:00+10	0	1	1
24	2026-08-04 02:53:00+10	1	0	1
24	2026-08-04 02:58:00+10	2	3	5
24	2026-08-04 03:10:00+10	6	0	6
24	2026-08-04 04:02:00+10	4	0	4
24	2026-08-04 04:48:00+10	1	0	1
24	2026-08-04 04:51:00+10	0	3	3
24	2026-08-04 04:59:00+10	1	0	1
24	2026-08-04 05:05:00+10	0	1	1
24	2026-08-04 05:07:00+10	8	0	8
24	2026-08-04 05:08:00+10	0	1	1
24	2026-08-04 05:19:00+10	1	0	1
24	2026-08-04 05:21:00+10	2	0	2
24	2026-08-04 05:23:00+10	0	4	4
24	2026-08-04 05:28:00+10	0	1	1
24	2026-08-04 05:32:00+10	1	5	6
24	2026-08-04 05:42:00+10	2	0	2
24	2026-08-04 05:44:00+10	0	2	2
24	2026-08-04 05:58:00+10	9	3	12
24	2026-08-04 06:01:00+10	2	0	2
24	2026-08-04 06:05:00+10	1	2	3
24	2026-08-04 06:06:00+10	5	3	8
24	2026-08-04 06:07:00+10	1	6	7
24	2026-08-04 06:09:00+10	3	0	3
24	2026-08-04 06:10:00+10	14	0	14
24	2026-08-04 06:12:00+10	3	0	3
24	2026-08-04 06:14:00+10	1	7	8
24	2026-08-04 06:17:00+10	7	1	8
24	2026-08-04 06:18:00+10	3	0	3
24	2026-08-04 06:19:00+10	2	0	2
24	2026-08-04 06:21:00+10	3	7	10
24	2026-08-04 06:24:00+10	9	0	9
24	2026-08-04 06:25:00+10	7	6	13
24	2026-08-04 06:37:00+10	19	1	20
24	2026-08-04 06:40:00+10	5	0	5
24	2026-08-04 06:47:00+10	6	9	15
24	2026-08-04 06:48:00+10	5	0	5
24	2026-08-04 06:49:00+10	11	4	15
24	2026-08-04 06:51:00+10	7	9	16
24	2026-08-04 06:54:00+10	17	1	18
24	2026-08-04 06:59:00+10	17	2	19
24	2026-08-04 07:03:00+10	16	2	18
24	2026-08-04 07:05:00+10	4	1	5
24	2026-08-04 07:07:00+10	4	1	5
24	2026-08-04 07:12:00+10	18	3	21
24	2026-08-04 07:13:00+10	21	0	21
24	2026-08-04 07:21:00+10	3	1	4
24	2026-08-04 07:24:00+10	8	3	11
24	2026-08-04 07:32:00+10	35	0	35
24	2026-08-04 07:34:00+10	20	4	24
24	2026-08-04 07:40:00+10	47	1	48
24	2026-08-04 07:44:00+10	25	9	34
24	2026-08-04 07:46:00+10	12	0	12
24	2026-08-04 07:47:00+10	41	4	45
24	2026-08-04 08:00:00+10	35	7	42
24	2026-08-04 08:01:00+10	21	4	25
24	2026-08-04 08:03:00+10	43	7	50
24	2026-08-04 08:04:00+10	14	0	14
24	2026-08-04 08:09:00+10	21	3	24
24	2026-08-04 08:10:00+10	67	4	71
24	2026-08-04 08:15:00+10	53	0	53
24	2026-08-04 08:18:00+10	34	15	49
24	2026-08-04 08:19:00+10	28	5	33
24	2026-08-04 08:24:00+10	11	2	13
24	2026-08-04 08:25:00+10	21	1	22
24	2026-08-04 08:27:00+10	52	2	54
24	2026-08-04 08:29:00+10	28	2	30
24	2026-08-04 08:31:00+10	23	7	30
24	2026-08-04 08:36:00+10	26	6	32
24	2026-08-04 08:37:00+10	89	2	91
24	2026-08-04 08:40:00+10	51	0	51
24	2026-08-04 08:48:00+10	27	0	27
24	2026-08-04 08:49:00+10	24	13	37
24	2026-08-04 08:51:00+10	25	10	35
24	2026-08-04 08:53:00+10	71	1	72
24	2026-08-04 08:54:00+10	41	6	47
24	2026-08-04 08:55:00+10	70	1	71
24	2026-08-04 08:57:00+10	36	2	38
24	2026-08-04 08:58:00+10	74	1	75
24	2026-08-04 08:59:00+10	29	0	29
24	2026-08-04 09:01:00+10	56	1	57
24	2026-08-04 09:02:00+10	64	4	68
24	2026-08-04 09:03:00+10	41	4	45
24	2026-08-04 09:04:00+10	26	8	34
24	2026-08-04 09:08:00+10	36	0	36
24	2026-08-04 09:09:00+10	17	6	23
24	2026-08-04 09:10:00+10	47	3	50
24	2026-08-04 09:12:00+10	39	2	41
24	2026-08-04 09:17:00+10	44	7	51
24	2026-08-04 09:18:00+10	2	106	108
24	2026-08-04 09:27:00+10	29	1	30
24	2026-08-04 09:30:00+10	23	1	24
24	2026-08-04 09:33:00+10	17	8	25
24	2026-08-04 09:41:00+10	4	2	6
24	2026-08-04 09:42:00+10	21	2	23
24	2026-08-04 09:46:00+10	16	0	16
24	2026-08-04 09:47:00+10	14	5	19
24	2026-08-04 09:58:00+10	20	7	27
24	2026-08-04 09:59:00+10	1	1	2
24	2026-08-04 10:02:00+10	13	1	14
24	2026-08-04 10:06:00+10	6	2	8
24	2026-08-04 10:07:00+10	20	1	21
24	2026-08-04 10:15:00+10	21	1	22
24	2026-08-04 10:16:00+10	10	1	11
24	2026-08-04 10:17:00+10	10	9	19
24	2026-08-04 10:20:00+10	31	4	35
24	2026-08-04 10:27:00+10	6	7	13
24	2026-08-04 10:29:00+10	7	3	10
24	2026-08-04 10:32:00+10	20	3	23
24	2026-08-04 10:34:00+10	9	1	10
24	2026-08-04 10:39:00+10	19	4	23
24	2026-08-04 10:41:00+10	5	1	6
24	2026-08-04 10:42:00+10	10	4	14
24	2026-08-04 10:44:00+10	7	10	17
24	2026-08-04 10:48:00+10	3	1	4
24	2026-08-04 10:49:00+10	3	11	14
24	2026-08-04 10:52:00+10	4	8	12
24	2026-08-04 10:53:00+10	6	21	27
24	2026-08-04 10:55:00+10	13	2	15
24	2026-08-04 10:57:00+10	10	0	10
24	2026-08-04 10:58:00+10	11	4	15
24	2026-08-04 10:59:00+10	5	12	17
24	2026-08-04 11:03:00+10	12	2	14
24	2026-08-04 11:05:00+10	29	6	35
24	2026-08-04 11:08:00+10	18	3	21
24	2026-08-04 11:10:00+10	12	5	17
24	2026-08-04 11:14:00+10	2	5	7
24	2026-08-04 11:15:00+10	13	11	24
24	2026-08-04 11:16:00+10	7	8	15
24	2026-08-04 11:23:00+10	5	5	10
24	2026-08-04 11:26:00+10	9	3	12
24	2026-08-04 11:31:00+10	14	3	17
24	2026-08-04 11:33:00+10	16	5	21
24	2026-08-04 11:34:00+10	5	5	10
24	2026-08-04 11:35:00+10	8	31	39
24	2026-08-04 11:42:00+10	8	5	13
24	2026-08-04 11:43:00+10	18	8	26
24	2026-08-04 11:46:00+10	8	11	19
24	2026-08-04 11:51:00+10	23	8	31
24	2026-08-04 11:56:00+10	14	11	25
24	2026-08-04 11:58:00+10	11	1	12
24	2026-08-04 12:00:00+10	15	3	18
24	2026-08-04 12:05:00+10	4	13	17
24	2026-08-04 12:06:00+10	23	9	32
24	2026-08-04 12:07:00+10	8	13	21
24	2026-08-04 12:08:00+10	7	16	23
24	2026-08-04 12:09:00+10	11	17	28
24	2026-08-04 12:10:00+10	6	5	11
24	2026-08-04 12:14:00+10	18	14	32
24	2026-08-04 12:16:00+10	9	10	19
24	2026-08-04 12:18:00+10	15	5	20
24	2026-08-04 12:22:00+10	18	8	26
24	2026-08-04 12:23:00+10	12	7	19
24	2026-08-04 12:25:00+10	2	10	12
24	2026-08-04 12:29:00+10	19	22	41
24	2026-08-04 12:33:00+10	14	11	25
24	2026-08-04 12:34:00+10	12	14	26
24	2026-08-04 12:36:00+10	18	10	28
24	2026-08-04 12:37:00+10	11	7	18
24	2026-08-04 12:39:00+10	6	2	8
24	2026-08-04 12:40:00+10	5	9	14
24	2026-08-04 12:41:00+10	13	13	26
24	2026-08-04 12:44:00+10	11	17	28
24	2026-08-04 12:45:00+10	4	17	21
24	2026-08-04 12:46:00+10	11	18	29
24	2026-08-04 12:55:00+10	11	10	21
24	2026-08-04 12:56:00+10	15	10	25
24	2026-08-04 12:57:00+10	26	10	36
24	2026-08-04 13:01:00+10	17	9	26
24	2026-08-04 13:07:00+10	16	16	32
24	2026-08-04 13:08:00+10	17	16	33
24	2026-08-04 13:14:00+10	15	7	22
24	2026-08-04 13:25:00+10	6	23	29
24	2026-08-04 13:26:00+10	5	10	15
24	2026-08-04 13:27:00+10	27	4	31
24	2026-08-04 13:28:00+10	8	9	17
24	2026-08-04 13:30:00+10	23	11	34
24	2026-08-04 13:31:00+10	2	18	20
24	2026-08-04 13:32:00+10	16	11	27
24	2026-08-04 13:36:00+10	6	12	18
24	2026-08-04 13:37:00+10	17	6	23
24	2026-08-04 13:38:00+10	14	11	25
24	2026-08-04 13:40:00+10	17	2	19
24	2026-08-04 13:41:00+10	4	7	11
24	2026-08-04 13:44:00+10	10	36	46
24	2026-08-04 13:45:00+10	16	17	33
24	2026-08-04 13:55:00+10	9	8	17
24	2026-08-04 13:56:00+10	2	7	9
24	2026-08-04 13:57:00+10	7	8	15
24	2026-08-04 13:59:00+10	4	6	10
24	2026-08-04 14:03:00+10	3	8	11
24	2026-08-04 14:07:00+10	12	7	19
24	2026-08-04 14:09:00+10	2	22	24
24	2026-08-04 14:12:00+10	6	12	18
24	2026-08-04 14:13:00+10	7	13	20
24	2026-08-04 14:17:00+10	8	10	18
24	2026-08-04 14:23:00+10	6	18	24
24	2026-08-04 14:29:00+10	11	4	15
24	2026-08-04 14:31:00+10	4	20	24
24	2026-08-04 14:32:00+10	13	20	33
24	2026-08-04 14:34:00+10	10	16	26
24	2026-08-04 14:39:00+10	4	7	11
25	2026-08-04 01:00:00+10	0	3	3
25	2026-08-04 01:30:00+10	0	1	1
25	2026-08-04 04:40:00+10	0	1	1
25	2026-08-04 04:45:00+10	1	0	1
25	2026-08-04 05:15:00+10	1	0	1
25	2026-08-04 05:30:00+10	2	0	2
25	2026-08-04 05:35:00+10	3	3	6
25	2026-08-04 06:00:00+10	0	7	7
25	2026-08-04 06:10:00+10	6	5	11
25	2026-08-04 06:20:00+10	1	5	6
25	2026-08-04 06:35:00+10	6	10	16
25	2026-08-04 06:45:00+10	10	11	21
25	2026-08-04 06:50:00+10	6	10	16
25	2026-08-04 07:40:00+10	12	24	36
25	2026-08-04 08:00:00+10	20	28	48
25	2026-08-04 08:20:00+10	20	43	63
25	2026-08-04 08:30:00+10	18	30	48
25	2026-08-04 09:20:00+10	12	55	67
25	2026-08-04 09:35:00+10	11	32	43
25	2026-08-04 10:10:00+10	9	27	36
25	2026-08-04 10:20:00+10	11	26	37
25	2026-08-04 10:30:00+10	5	12	17
25	2026-08-04 11:05:00+10	10	22	32
25	2026-08-04 11:20:00+10	10	15	25
25	2026-08-04 11:25:00+10	10	37	47
25	2026-08-04 11:30:00+10	6	22	28
25	2026-08-04 11:40:00+10	17	9	26
25	2026-08-04 11:45:00+10	11	21	32
25	2026-08-04 11:50:00+10	10	2	12
25	2026-08-04 12:25:00+10	30	16	46
25	2026-08-04 12:45:00+10	43	38	81
25	2026-08-04 13:30:00+10	17	23	40
25	2026-08-04 14:05:00+10	33	14	47
25	2026-08-04 14:35:00+10	30	24	54
27	2026-08-04 00:05:00+10	2	0	2
27	2026-08-04 01:35:00+10	0	1	1
27	2026-08-04 02:20:00+10	0	1	1
27	2026-08-04 03:20:00+10	1	0	1
27	2026-08-04 04:55:00+10	0	1	1
27	2026-08-04 06:05:00+10	0	1	1
27	2026-08-04 06:10:00+10	1	0	1
27	2026-08-04 06:15:00+10	1	1	2
27	2026-08-04 06:40:00+10	1	2	3
27	2026-08-04 06:55:00+10	1	0	1
27	2026-08-04 07:05:00+10	4	1	5
27	2026-08-04 07:40:00+10	4	6	10
27	2026-08-04 08:00:00+10	6	1	7
27	2026-08-04 08:15:00+10	6	5	11
27	2026-08-04 08:20:00+10	10	1	11
27	2026-08-04 08:35:00+10	15	6	21
27	2026-08-04 08:40:00+10	8	7	15
27	2026-08-04 09:00:00+10	6	1	7
27	2026-08-04 09:05:00+10	11	8	19
27	2026-08-04 09:15:00+10	5	5	10
27	2026-08-04 09:30:00+10	13	6	19
27	2026-08-04 09:45:00+10	8	7	15
27	2026-08-04 09:55:00+10	5	3	8
27	2026-08-04 10:00:00+10	6	5	11
27	2026-08-04 10:05:00+10	5	6	11
27	2026-08-04 10:10:00+10	7	4	11
27	2026-08-04 10:20:00+10	9	6	15
27	2026-08-04 10:25:00+10	8	4	12
27	2026-08-04 10:35:00+10	34	3	37
27	2026-08-04 10:40:00+10	8	14	22
27	2026-08-04 10:50:00+10	13	13	26
27	2026-08-04 10:55:00+10	14	14	28
27	2026-08-04 11:05:00+10	15	2	17
27	2026-08-04 11:10:00+10	22	11	33
27	2026-08-04 11:15:00+10	3	11	14
27	2026-08-04 11:20:00+10	13	11	24
27	2026-08-04 11:25:00+10	17	9	26
27	2026-08-04 11:35:00+10	9	7	16
27	2026-08-04 11:45:00+10	10	5	15
27	2026-08-04 11:50:00+10	4	5	9
27	2026-08-04 12:00:00+10	8	4	12
27	2026-08-04 12:10:00+10	11	21	32
27	2026-08-04 12:25:00+10	18	25	43
27	2026-08-04 13:00:00+10	12	20	32
27	2026-08-04 13:05:00+10	13	12	25
27	2026-08-04 13:20:00+10	18	18	36
27	2026-08-04 13:45:00+10	7	5	12
27	2026-08-04 14:00:00+10	16	9	25
27	2026-08-04 14:05:00+10	4	11	15
27	2026-08-04 14:20:00+10	7	10	17
27	2026-08-04 14:25:00+10	15	6	21
29	2026-08-04 00:13:00+10	0	2	2
29	2026-08-04 00:54:00+10	1	0	1
29	2026-08-04 00:55:00+10	0	1	1
29	2026-08-04 01:19:00+10	1	0	1
29	2026-08-04 04:46:00+10	1	0	1
29	2026-08-04 04:55:00+10	1	0	1
29	2026-08-04 05:20:00+10	0	1	1
29	2026-08-04 05:31:00+10	0	1	1
29	2026-08-04 05:50:00+10	0	1	1
29	2026-08-04 05:51:00+10	1	0	1
29	2026-08-04 05:57:00+10	0	2	2
29	2026-08-04 05:58:00+10	2	1	3
29	2026-08-04 06:01:00+10	0	2	2
29	2026-08-04 06:09:00+10	0	1	1
29	2026-08-04 06:10:00+10	0	1	1
29	2026-08-04 06:20:00+10	0	2	2
29	2026-08-04 06:23:00+10	1	1	2
29	2026-08-04 06:29:00+10	0	1	1
29	2026-08-04 06:31:00+10	1	2	3
29	2026-08-04 06:33:00+10	1	8	9
29	2026-08-04 06:35:00+10	0	1	1
29	2026-08-04 06:37:00+10	0	4	4
29	2026-08-04 06:41:00+10	0	1	1
29	2026-08-04 06:46:00+10	4	1	5
29	2026-08-04 06:48:00+10	0	2	2
29	2026-08-04 06:51:00+10	1	0	1
29	2026-08-04 06:53:00+10	0	3	3
29	2026-08-04 07:11:00+10	1	2	3
29	2026-08-04 07:16:00+10	2	1	3
29	2026-08-04 07:17:00+10	3	2	5
29	2026-08-04 07:23:00+10	2	2	4
29	2026-08-04 07:25:00+10	1	0	1
29	2026-08-04 07:33:00+10	1	1	2
29	2026-08-04 07:36:00+10	2	0	2
29	2026-08-04 07:43:00+10	1	1	2
29	2026-08-04 07:48:00+10	1	0	1
29	2026-08-04 07:51:00+10	4	0	4
29	2026-08-04 07:53:00+10	2	1	3
29	2026-08-04 07:54:00+10	0	3	3
29	2026-08-04 07:57:00+10	2	3	5
29	2026-08-04 08:00:00+10	3	0	3
29	2026-08-04 08:04:00+10	4	1	5
29	2026-08-04 08:07:00+10	2	3	5
29	2026-08-04 08:12:00+10	1	3	4
29	2026-08-04 08:16:00+10	3	2	5
29	2026-08-04 08:19:00+10	7	1	8
29	2026-08-04 08:22:00+10	2	0	2
29	2026-08-04 08:23:00+10	3	0	3
29	2026-08-04 08:24:00+10	2	1	3
29	2026-08-04 08:35:00+10	1	1	2
29	2026-08-04 08:39:00+10	1	2	3
29	2026-08-04 08:42:00+10	6	0	6
29	2026-08-04 08:45:00+10	3	0	3
29	2026-08-04 08:47:00+10	1	1	2
29	2026-08-04 08:48:00+10	2	0	2
29	2026-08-04 08:52:00+10	0	1	1
29	2026-08-04 08:54:00+10	1	2	3
29	2026-08-04 08:55:00+10	3	4	7
29	2026-08-04 08:58:00+10	0	2	2
29	2026-08-04 08:59:00+10	1	0	1
29	2026-08-04 09:01:00+10	3	1	4
29	2026-08-04 09:02:00+10	2	2	4
29	2026-08-04 09:06:00+10	3	0	3
29	2026-08-04 09:07:00+10	1	0	1
29	2026-08-04 09:08:00+10	1	4	5
29	2026-08-04 09:10:00+10	1	2	3
29	2026-08-04 09:15:00+10	1	1	2
29	2026-08-04 09:27:00+10	0	1	1
29	2026-08-04 09:31:00+10	1	5	6
29	2026-08-04 09:45:00+10	0	1	1
29	2026-08-04 09:54:00+10	1	1	2
29	2026-08-04 09:56:00+10	2	0	2
29	2026-08-04 09:57:00+10	1	2	3
29	2026-08-04 09:58:00+10	1	4	5
29	2026-08-04 10:02:00+10	0	4	4
29	2026-08-04 10:03:00+10	1	1	2
29	2026-08-04 10:09:00+10	4	6	10
29	2026-08-04 10:10:00+10	6	4	10
29	2026-08-04 10:15:00+10	0	6	6
29	2026-08-04 10:17:00+10	2	6	8
29	2026-08-04 10:24:00+10	2	0	2
29	2026-08-04 10:28:00+10	0	7	7
29	2026-08-04 10:29:00+10	0	18	18
29	2026-08-04 10:34:00+10	1	1	2
29	2026-08-04 10:35:00+10	1	0	1
29	2026-08-04 10:36:00+10	0	4	4
29	2026-08-04 10:41:00+10	1	0	1
29	2026-08-04 10:43:00+10	0	3	3
29	2026-08-04 10:45:00+10	1	1	2
29	2026-08-04 10:49:00+10	2	7	9
29	2026-08-04 10:51:00+10	3	15	18
29	2026-08-04 10:52:00+10	0	2	2
29	2026-08-04 10:53:00+10	3	0	3
29	2026-08-04 11:01:00+10	3	4	7
29	2026-08-04 11:02:00+10	0	7	7
29	2026-08-04 11:11:00+10	3	1	4
29	2026-08-04 11:16:00+10	2	4	6
29	2026-08-04 11:19:00+10	3	1	4
29	2026-08-04 11:21:00+10	3	2	5
29	2026-08-04 11:23:00+10	5	3	8
29	2026-08-04 11:28:00+10	2	6	8
29	2026-08-04 11:30:00+10	2	2	4
29	2026-08-04 11:33:00+10	0	4	4
29	2026-08-04 11:34:00+10	0	3	3
29	2026-08-04 11:38:00+10	0	1	1
29	2026-08-04 11:41:00+10	0	1	1
29	2026-08-04 11:42:00+10	1	0	1
29	2026-08-04 11:43:00+10	0	1	1
29	2026-08-04 11:51:00+10	1	0	1
29	2026-08-04 12:03:00+10	0	3	3
29	2026-08-04 12:04:00+10	1	0	1
29	2026-08-04 12:07:00+10	0	2	2
29	2026-08-04 12:08:00+10	1	0	1
29	2026-08-04 12:10:00+10	2	3	5
29	2026-08-04 12:11:00+10	0	2	2
29	2026-08-04 13:37:00+10	23	1	24
29	2026-08-04 13:41:00+10	1	0	1
29	2026-08-04 13:44:00+10	2	0	2
29	2026-08-04 13:45:00+10	1	0	1
29	2026-08-04 13:48:00+10	0	1	1
29	2026-08-04 13:53:00+10	0	3	3
29	2026-08-04 13:55:00+10	0	2	2
29	2026-08-04 13:57:00+10	3	2	5
29	2026-08-04 13:58:00+10	1	0	1
29	2026-08-04 13:59:00+10	1	1	2
29	2026-08-04 14:01:00+10	3	0	3
29	2026-08-04 14:08:00+10	1	0	1
29	2026-08-04 14:10:00+10	3	4	7
29	2026-08-04 14:12:00+10	3	5	8
29	2026-08-04 14:13:00+10	1	3	4
29	2026-08-04 14:14:00+10	3	1	4
29	2026-08-04 14:15:00+10	0	1	1
29	2026-08-04 14:16:00+10	0	3	3
29	2026-08-04 14:18:00+10	0	5	5
29	2026-08-04 14:20:00+10	1	0	1
29	2026-08-04 14:24:00+10	0	6	6
30	2026-08-03 23:55:00+10	2	1	3
30	2026-08-04 00:00:00+10	0	2	2
30	2026-08-04 01:10:00+10	0	1	1
30	2026-08-04 01:20:00+10	0	4	4
30	2026-08-04 01:45:00+10	1	1	2
30	2026-08-04 02:10:00+10	2	0	2
30	2026-08-04 02:15:00+10	0	1	1
30	2026-08-04 02:40:00+10	1	0	1
30	2026-08-04 03:05:00+10	1	0	1
30	2026-08-04 05:50:00+10	2	0	2
30	2026-08-04 05:55:00+10	1	0	1
30	2026-08-04 06:35:00+10	2	3	5
30	2026-08-04 06:55:00+10	3	2	5
30	2026-08-04 07:05:00+10	2	1	3
30	2026-08-04 07:25:00+10	2	3	5
30	2026-08-04 07:40:00+10	7	6	13
30	2026-08-04 08:00:00+10	3	6	9
30	2026-08-04 08:30:00+10	11	5	16
30	2026-08-04 08:45:00+10	9	6	15
30	2026-08-04 08:55:00+10	11	7	18
30	2026-08-04 09:20:00+10	4	6	10
30	2026-08-04 09:25:00+10	5	13	18
30	2026-08-04 09:35:00+10	7	15	22
30	2026-08-04 09:45:00+10	6	10	16
30	2026-08-04 10:00:00+10	4	9	13
30	2026-08-04 10:05:00+10	9	21	30
30	2026-08-04 10:10:00+10	12	9	21
30	2026-08-04 10:20:00+10	27	6	33
30	2026-08-04 10:30:00+10	5	10	15
30	2026-08-04 10:55:00+10	13	13	26
30	2026-08-04 11:05:00+10	6	14	20
30	2026-08-04 12:45:00+10	37	33	70
30	2026-08-04 13:45:00+10	37	35	72
30	2026-08-04 14:00:00+10	20	37	57
30	2026-08-04 14:05:00+10	10	28	38
30	2026-08-04 14:10:00+10	28	26	54
30	2026-08-04 14:15:00+10	19	32	51
30	2026-08-04 14:35:00+10	20	30	50
31	2026-08-04 00:10:00+10	0	1	1
31	2026-08-04 00:19:00+10	2	0	2
31	2026-08-04 01:06:00+10	1	0	1
31	2026-08-04 01:07:00+10	0	1	1
31	2026-08-04 01:20:00+10	3	0	3
31	2026-08-04 01:34:00+10	0	1	1
31	2026-08-04 02:14:00+10	1	0	1
31	2026-08-04 02:24:00+10	1	0	1
31	2026-08-04 03:34:00+10	1	0	1
31	2026-08-04 05:23:00+10	0	1	1
31	2026-08-04 06:20:00+10	0	1	1
31	2026-08-04 06:26:00+10	1	0	1
31	2026-08-04 06:30:00+10	0	2	2
31	2026-08-04 06:31:00+10	1	0	1
31	2026-08-04 06:43:00+10	0	2	2
31	2026-08-04 07:05:00+10	1	0	1
31	2026-08-04 07:18:00+10	0	1	1
31	2026-08-04 07:22:00+10	1	0	1
31	2026-08-04 07:29:00+10	1	0	1
31	2026-08-04 07:53:00+10	2	0	2
31	2026-08-04 08:06:00+10	0	1	1
31	2026-08-04 08:09:00+10	1	0	1
31	2026-08-04 08:13:00+10	0	2	2
31	2026-08-04 08:14:00+10	0	3	3
31	2026-08-04 08:17:00+10	0	1	1
31	2026-08-04 08:19:00+10	1	0	1
31	2026-08-04 08:22:00+10	1	0	1
31	2026-08-04 08:29:00+10	0	1	1
31	2026-08-04 08:30:00+10	1	1	2
31	2026-08-04 08:35:00+10	0	1	1
31	2026-08-04 08:36:00+10	3	1	4
31	2026-08-04 08:40:00+10	1	2	3
31	2026-08-04 08:43:00+10	1	1	2
31	2026-08-04 08:45:00+10	2	2	4
31	2026-08-04 08:52:00+10	1	1	2
31	2026-08-04 08:54:00+10	5	0	5
31	2026-08-04 09:08:00+10	1	1	2
31	2026-08-04 09:11:00+10	2	0	2
31	2026-08-04 09:13:00+10	1	0	1
31	2026-08-04 09:14:00+10	2	2	4
31	2026-08-04 09:15:00+10	1	0	1
31	2026-08-04 09:20:00+10	0	5	5
31	2026-08-04 09:23:00+10	3	0	3
31	2026-08-04 09:24:00+10	1	1	2
31	2026-08-04 09:27:00+10	1	1	2
31	2026-08-04 09:32:00+10	2	1	3
31	2026-08-04 09:36:00+10	3	2	5
31	2026-08-04 09:42:00+10	0	2	2
31	2026-08-04 09:44:00+10	0	1	1
31	2026-08-04 09:46:00+10	1	3	4
31	2026-08-04 09:52:00+10	2	1	3
31	2026-08-04 09:55:00+10	3	0	3
31	2026-08-04 09:56:00+10	0	1	1
31	2026-08-04 09:58:00+10	2	5	7
31	2026-08-04 09:59:00+10	1	1	2
31	2026-08-04 10:05:00+10	3	2	5
31	2026-08-04 10:11:00+10	3	0	3
31	2026-08-04 10:24:00+10	2	2	4
31	2026-08-04 10:33:00+10	2	2	4
31	2026-08-04 10:41:00+10	2	2	4
31	2026-08-04 10:42:00+10	0	2	2
31	2026-08-04 10:45:00+10	1	2	3
31	2026-08-04 10:46:00+10	0	1	1
31	2026-08-04 10:48:00+10	2	2	4
31	2026-08-04 10:50:00+10	2	1	3
31	2026-08-04 10:59:00+10	1	2	3
31	2026-08-04 11:09:00+10	0	4	4
31	2026-08-04 11:16:00+10	0	4	4
31	2026-08-04 11:22:00+10	0	3	3
31	2026-08-04 11:23:00+10	1	1	2
31	2026-08-04 11:25:00+10	1	3	4
31	2026-08-04 11:27:00+10	2	2	4
31	2026-08-04 11:31:00+10	2	1	3
31	2026-08-04 11:33:00+10	12	4	16
31	2026-08-04 11:36:00+10	3	2	5
31	2026-08-04 11:38:00+10	2	3	5
31	2026-08-04 11:40:00+10	0	3	3
31	2026-08-04 11:42:00+10	1	6	7
31	2026-08-04 11:46:00+10	2	0	2
31	2026-08-04 11:50:00+10	3	0	3
31	2026-08-04 11:56:00+10	3	0	3
31	2026-08-04 12:07:00+10	1	0	1
31	2026-08-04 12:08:00+10	0	1	1
31	2026-08-04 12:09:00+10	1	3	4
31	2026-08-04 12:14:00+10	4	5	9
31	2026-08-04 12:21:00+10	5	0	5
31	2026-08-04 12:25:00+10	2	2	4
31	2026-08-04 12:27:00+10	2	1	3
31	2026-08-04 12:29:00+10	4	0	4
31	2026-08-04 12:31:00+10	0	2	2
31	2026-08-04 12:32:00+10	2	1	3
31	2026-08-04 12:36:00+10	7	4	11
31	2026-08-04 12:47:00+10	3	0	3
31	2026-08-04 12:51:00+10	3	0	3
31	2026-08-04 12:59:00+10	4	2	6
31	2026-08-04 13:07:00+10	8	5	13
31	2026-08-04 13:09:00+10	3	1	4
31	2026-08-04 13:10:00+10	3	3	6
31	2026-08-04 13:13:00+10	4	10	14
31	2026-08-04 13:28:00+10	3	2	5
31	2026-08-04 13:31:00+10	2	4	6
31	2026-08-04 13:32:00+10	5	2	7
31	2026-08-04 13:33:00+10	2	4	6
31	2026-08-04 13:36:00+10	2	4	6
31	2026-08-04 13:39:00+10	5	4	9
31	2026-08-04 13:40:00+10	8	4	12
31	2026-08-04 13:43:00+10	2	6	8
31	2026-08-04 13:48:00+10	1	4	5
31	2026-08-04 13:52:00+10	3	1	4
31	2026-08-04 13:54:00+10	0	1	1
31	2026-08-04 13:56:00+10	1	3	4
31	2026-08-04 13:57:00+10	5	3	8
31	2026-08-04 14:09:00+10	2	2	4
31	2026-08-04 14:12:00+10	1	3	4
31	2026-08-04 14:13:00+10	3	0	3
31	2026-08-04 14:14:00+10	0	4	4
31	2026-08-04 14:20:00+10	0	4	4
31	2026-08-04 14:23:00+10	2	0	2
31	2026-08-04 14:24:00+10	2	4	6
35	2026-08-03 23:56:00+10	1	0	1
35	2026-08-03 23:57:00+10	0	1	1
35	2026-08-04 00:02:00+10	0	2	2
35	2026-08-04 00:14:00+10	0	2	2
35	2026-08-04 00:17:00+10	1	0	1
35	2026-08-04 00:32:00+10	2	0	2
35	2026-08-04 00:40:00+10	1	0	1
35	2026-08-04 00:46:00+10	1	0	1
35	2026-08-04 00:48:00+10	1	0	1
35	2026-08-04 00:57:00+10	1	0	1
35	2026-08-04 00:59:00+10	0	1	1
35	2026-08-04 01:14:00+10	0	1	1
35	2026-08-04 02:07:00+10	0	1	1
35	2026-08-04 02:56:00+10	0	1	1
35	2026-08-04 04:13:00+10	0	1	1
35	2026-08-04 04:30:00+10	0	1	1
35	2026-08-04 04:47:00+10	1	0	1
35	2026-08-04 04:50:00+10	1	0	1
35	2026-08-04 05:08:00+10	1	1	2
35	2026-08-04 05:11:00+10	0	1	1
35	2026-08-04 05:25:00+10	1	0	1
35	2026-08-04 05:28:00+10	1	0	1
35	2026-08-04 05:30:00+10	0	1	1
35	2026-08-04 05:33:00+10	1	0	1
35	2026-08-04 05:35:00+10	0	2	2
35	2026-08-04 05:37:00+10	0	1	1
35	2026-08-04 05:39:00+10	1	1	2
35	2026-08-04 05:42:00+10	4	1	5
35	2026-08-04 05:47:00+10	3	2	5
35	2026-08-04 05:52:00+10	3	0	3
35	2026-08-04 05:54:00+10	1	3	4
35	2026-08-04 06:04:00+10	0	4	4
35	2026-08-04 06:05:00+10	1	1	2
35	2026-08-04 06:08:00+10	2	0	2
35	2026-08-04 06:18:00+10	2	2	4
35	2026-08-04 06:19:00+10	0	5	5
35	2026-08-04 06:20:00+10	1	3	4
35	2026-08-04 06:24:00+10	2	0	2
35	2026-08-04 06:27:00+10	2	3	5
35	2026-08-04 06:28:00+10	1	0	1
35	2026-08-04 06:36:00+10	2	10	12
35	2026-08-04 06:44:00+10	3	0	3
35	2026-08-04 06:47:00+10	6	3	9
35	2026-08-04 06:50:00+10	4	5	9
35	2026-08-04 06:52:00+10	3	8	11
35	2026-08-04 06:54:00+10	2	3	5
35	2026-08-04 06:55:00+10	3	5	8
35	2026-08-04 06:56:00+10	3	4	7
35	2026-08-04 06:58:00+10	6	6	12
35	2026-08-04 07:03:00+10	1	6	7
35	2026-08-04 07:04:00+10	8	11	19
35	2026-08-04 07:05:00+10	7	15	22
35	2026-08-04 07:08:00+10	5	3	8
35	2026-08-04 07:10:00+10	6	6	12
35	2026-08-04 07:11:00+10	6	12	18
35	2026-08-04 07:16:00+10	4	6	10
35	2026-08-04 07:18:00+10	4	3	7
35	2026-08-04 07:19:00+10	19	9	28
35	2026-08-04 07:21:00+10	6	7	13
35	2026-08-04 07:23:00+10	6	11	17
35	2026-08-04 07:24:00+10	6	6	12
35	2026-08-04 07:26:00+10	8	16	24
35	2026-08-04 07:27:00+10	6	3	9
35	2026-08-04 07:28:00+10	6	6	12
35	2026-08-04 07:29:00+10	7	5	12
35	2026-08-04 07:35:00+10	6	19	25
35	2026-08-04 07:38:00+10	6	20	26
35	2026-08-04 07:43:00+10	15	18	33
35	2026-08-04 07:44:00+10	6	21	27
35	2026-08-04 07:45:00+10	19	25	44
35	2026-08-04 07:47:00+10	8	20	28
35	2026-08-04 08:03:00+10	3	16	19
35	2026-08-04 08:04:00+10	12	22	34
35	2026-08-04 08:06:00+10	18	31	49
35	2026-08-04 08:10:00+10	6	17	23
35	2026-08-04 08:13:00+10	11	36	47
35	2026-08-04 08:15:00+10	6	36	42
35	2026-08-04 08:17:00+10	5	20	25
35	2026-08-04 08:18:00+10	17	12	29
35	2026-08-04 08:21:00+10	11	57	68
35	2026-08-04 08:22:00+10	13	13	26
35	2026-08-04 08:24:00+10	13	33	46
35	2026-08-04 08:32:00+10	10	34	44
35	2026-08-04 08:35:00+10	10	45	55
35	2026-08-04 08:36:00+10	12	65	77
35	2026-08-04 08:37:00+10	12	40	52
35	2026-08-04 08:38:00+10	10	21	31
35	2026-08-04 08:53:00+10	14	45	59
35	2026-08-04 08:55:00+10	15	52	67
35	2026-08-04 08:58:00+10	6	58	64
35	2026-08-04 08:59:00+10	4	33	37
35	2026-08-04 09:01:00+10	4	39	43
35	2026-08-04 09:03:00+10	8	35	43
35	2026-08-04 09:07:00+10	6	23	29
35	2026-08-04 09:15:00+10	8	24	32
35	2026-08-04 09:16:00+10	7	22	29
35	2026-08-04 09:22:00+10	11	10	21
35	2026-08-04 09:25:00+10	5	11	16
35	2026-08-04 09:35:00+10	6	4	10
35	2026-08-04 09:38:00+10	10	24	34
35	2026-08-04 09:40:00+10	13	5	18
35	2026-08-04 09:49:00+10	11	25	36
35	2026-08-04 09:55:00+10	10	7	17
35	2026-08-04 09:56:00+10	4	5	9
35	2026-08-04 09:59:00+10	4	5	9
35	2026-08-04 10:16:00+10	3	8	11
35	2026-08-04 10:19:00+10	10	5	15
35	2026-08-04 10:21:00+10	8	5	13
35	2026-08-04 10:22:00+10	8	9	17
35	2026-08-04 10:24:00+10	11	5	16
35	2026-08-04 10:31:00+10	5	2	7
35	2026-08-04 10:35:00+10	2	3	5
35	2026-08-04 10:36:00+10	9	6	15
35	2026-08-04 10:44:00+10	4	4	8
35	2026-08-04 10:45:00+10	2	2	4
35	2026-08-04 10:46:00+10	9	7	16
35	2026-08-04 10:48:00+10	7	8	15
35	2026-08-04 10:49:00+10	2	7	9
35	2026-08-04 10:53:00+10	4	6	10
35	2026-08-04 10:59:00+10	11	8	19
35	2026-08-04 11:05:00+10	6	3	9
35	2026-08-04 11:07:00+10	8	1	9
35	2026-08-04 11:10:00+10	8	6	14
35	2026-08-04 11:17:00+10	2	8	10
35	2026-08-04 11:18:00+10	7	2	9
35	2026-08-04 11:22:00+10	3	6	9
35	2026-08-04 11:26:00+10	10	7	17
35	2026-08-04 11:28:00+10	6	10	16
35	2026-08-04 11:29:00+10	8	9	17
35	2026-08-04 11:33:00+10	8	3	11
35	2026-08-04 11:35:00+10	2	3	5
35	2026-08-04 11:36:00+10	3	2	5
35	2026-08-04 11:37:00+10	3	1	4
35	2026-08-04 11:41:00+10	1	8	9
35	2026-08-04 11:46:00+10	2	7	9
35	2026-08-04 11:48:00+10	1	3	4
35	2026-08-04 11:57:00+10	2	2	4
35	2026-08-04 11:58:00+10	2	4	6
35	2026-08-04 12:03:00+10	3	3	6
35	2026-08-04 12:04:00+10	10	3	13
35	2026-08-04 12:07:00+10	6	5	11
35	2026-08-04 12:12:00+10	11	12	23
35	2026-08-04 12:13:00+10	14	5	19
35	2026-08-04 12:15:00+10	9	6	15
35	2026-08-04 12:16:00+10	7	11	18
35	2026-08-04 12:17:00+10	10	7	17
35	2026-08-04 12:19:00+10	8	9	17
35	2026-08-04 12:20:00+10	8	8	16
35	2026-08-04 12:21:00+10	9	15	24
35	2026-08-04 12:23:00+10	16	11	27
35	2026-08-04 12:25:00+10	6	11	17
35	2026-08-04 12:27:00+10	5	8	13
35	2026-08-04 12:28:00+10	10	8	18
35	2026-08-04 12:33:00+10	12	10	22
35	2026-08-04 12:36:00+10	20	9	29
35	2026-08-04 12:37:00+10	14	15	29
35	2026-08-04 12:45:00+10	16	15	31
35	2026-08-04 12:46:00+10	17	20	37
35	2026-08-04 12:47:00+10	11	20	31
35	2026-08-04 12:50:00+10	26	12	38
35	2026-08-04 12:53:00+10	20	18	38
35	2026-08-04 12:54:00+10	17	18	35
35	2026-08-04 12:56:00+10	18	16	34
35	2026-08-04 12:59:00+10	13	10	23
35	2026-08-04 13:01:00+10	8	18	26
35	2026-08-04 13:03:00+10	22	19	41
35	2026-08-04 13:04:00+10	7	18	25
35	2026-08-04 13:07:00+10	15	16	31
35	2026-08-04 13:09:00+10	15	17	32
35	2026-08-04 13:12:00+10	14	13	27
35	2026-08-04 13:16:00+10	15	22	37
35	2026-08-04 13:17:00+10	17	13	30
35	2026-08-04 13:19:00+10	8	16	24
35	2026-08-04 13:22:00+10	8	10	18
35	2026-08-04 13:25:00+10	2	17	19
35	2026-08-04 13:28:00+10	15	10	25
35	2026-08-04 13:29:00+10	9	15	24
35	2026-08-04 13:30:00+10	12	8	20
35	2026-08-04 13:34:00+10	9	17	26
35	2026-08-04 13:39:00+10	15	2	17
35	2026-08-04 13:40:00+10	5	23	28
35	2026-08-04 13:44:00+10	5	6	11
35	2026-08-04 13:48:00+10	11	13	24
35	2026-08-04 13:54:00+10	15	12	27
35	2026-08-04 13:57:00+10	14	17	31
35	2026-08-04 13:59:00+10	5	17	22
35	2026-08-04 14:01:00+10	7	19	26
35	2026-08-04 14:02:00+10	8	11	19
35	2026-08-04 14:04:00+10	7	12	19
35	2026-08-04 14:09:00+10	15	11	26
35	2026-08-04 14:10:00+10	11	8	19
35	2026-08-04 14:13:00+10	16	15	31
35	2026-08-04 14:18:00+10	10	6	16
35	2026-08-04 14:20:00+10	8	12	20
35	2026-08-04 14:22:00+10	9	12	21
35	2026-08-04 14:23:00+10	4	17	21
35	2026-08-04 14:25:00+10	10	10	20
35	2026-08-04 14:26:00+10	3	14	17
35	2026-08-04 14:32:00+10	6	9	15
36	2026-08-03 23:57:00+10	0	1	1
36	2026-08-04 00:17:00+10	2	0	2
36	2026-08-04 02:52:00+10	1	0	1
36	2026-08-04 03:00:00+10	4	1	5
36	2026-08-04 03:13:00+10	2	0	2
36	2026-08-04 05:25:00+10	1	0	1
36	2026-08-04 05:31:00+10	0	1	1
36	2026-08-04 05:42:00+10	1	0	1
36	2026-08-04 05:43:00+10	1	0	1
36	2026-08-04 05:45:00+10	1	0	1
36	2026-08-04 05:47:00+10	1	1	2
36	2026-08-04 05:49:00+10	1	0	1
36	2026-08-04 05:59:00+10	2	1	3
36	2026-08-04 06:03:00+10	1	0	1
36	2026-08-04 06:07:00+10	1	0	1
36	2026-08-04 06:09:00+10	1	0	1
36	2026-08-04 06:31:00+10	1	0	1
36	2026-08-04 06:34:00+10	1	0	1
36	2026-08-04 06:38:00+10	1	0	1
36	2026-08-04 06:40:00+10	2	0	2
36	2026-08-04 06:45:00+10	0	1	1
36	2026-08-04 07:04:00+10	1	0	1
36	2026-08-04 07:11:00+10	1	1	2
36	2026-08-04 07:15:00+10	1	0	1
36	2026-08-04 07:16:00+10	1	0	1
36	2026-08-04 07:20:00+10	5	0	5
36	2026-08-04 07:22:00+10	1	1	2
36	2026-08-04 07:26:00+10	2	0	2
36	2026-08-04 07:29:00+10	1	0	1
36	2026-08-04 07:33:00+10	0	1	1
36	2026-08-04 07:38:00+10	4	0	4
36	2026-08-04 07:39:00+10	1	0	1
36	2026-08-04 07:43:00+10	1	0	1
36	2026-08-04 07:45:00+10	3	4	7
36	2026-08-04 07:47:00+10	0	1	1
36	2026-08-04 07:51:00+10	3	1	4
36	2026-08-04 07:52:00+10	6	2	8
36	2026-08-04 07:53:00+10	1	0	1
36	2026-08-04 07:59:00+10	1	0	1
36	2026-08-04 08:04:00+10	1	1	2
36	2026-08-04 08:05:00+10	3	0	3
36	2026-08-04 08:06:00+10	5	2	7
36	2026-08-04 08:07:00+10	4	0	4
36	2026-08-04 08:08:00+10	3	3	6
36	2026-08-04 08:09:00+10	4	2	6
36	2026-08-04 08:10:00+10	2	0	2
36	2026-08-04 08:14:00+10	5	4	9
36	2026-08-04 08:16:00+10	4	1	5
36	2026-08-04 08:17:00+10	3	2	5
36	2026-08-04 08:18:00+10	6	1	7
36	2026-08-04 08:24:00+10	5	7	12
36	2026-08-04 08:37:00+10	0	3	3
36	2026-08-04 08:40:00+10	5	1	6
36	2026-08-04 08:42:00+10	6	5	11
36	2026-08-04 08:50:00+10	2	1	3
36	2026-08-04 08:54:00+10	8	1	9
36	2026-08-04 08:56:00+10	2	4	6
36	2026-08-04 09:10:00+10	1	5	6
36	2026-08-04 09:16:00+10	1	5	6
36	2026-08-04 09:17:00+10	2	6	8
36	2026-08-04 09:19:00+10	1	1	2
36	2026-08-04 09:20:00+10	0	1	1
36	2026-08-04 09:22:00+10	1	1	2
36	2026-08-04 09:25:00+10	1	2	3
36	2026-08-04 09:26:00+10	3	6	9
36	2026-08-04 09:27:00+10	4	0	4
36	2026-08-04 09:29:00+10	3	0	3
36	2026-08-04 09:41:00+10	2	1	3
36	2026-08-04 09:42:00+10	1	2	3
36	2026-08-04 09:44:00+10	4	0	4
36	2026-08-04 09:45:00+10	5	6	11
36	2026-08-04 09:48:00+10	3	3	6
36	2026-08-04 09:49:00+10	5	0	5
36	2026-08-04 09:50:00+10	2	3	5
36	2026-08-04 09:54:00+10	4	5	9
36	2026-08-04 09:55:00+10	3	0	3
36	2026-08-04 09:56:00+10	3	1	4
36	2026-08-04 09:59:00+10	2	2	4
36	2026-08-04 10:01:00+10	2	2	4
36	2026-08-04 10:06:00+10	0	6	6
36	2026-08-04 10:08:00+10	2	1	3
36	2026-08-04 10:09:00+10	4	2	6
36	2026-08-04 10:11:00+10	3	4	7
36	2026-08-04 10:13:00+10	1	1	2
36	2026-08-04 10:14:00+10	4	1	5
36	2026-08-04 10:16:00+10	4	1	5
36	2026-08-04 10:17:00+10	7	4	11
36	2026-08-04 10:28:00+10	2	0	2
36	2026-08-04 10:30:00+10	6	1	7
36	2026-08-04 10:31:00+10	1	2	3
36	2026-08-04 10:32:00+10	2	1	3
36	2026-08-04 10:36:00+10	3	1	4
36	2026-08-04 10:37:00+10	3	3	6
36	2026-08-04 10:44:00+10	4	3	7
36	2026-08-04 10:45:00+10	6	0	6
36	2026-08-04 10:51:00+10	6	2	8
36	2026-08-04 10:54:00+10	5	1	6
36	2026-08-04 11:04:00+10	1	1	2
36	2026-08-04 11:09:00+10	1	0	1
36	2026-08-04 11:12:00+10	4	2	6
36	2026-08-04 11:13:00+10	4	2	6
36	2026-08-04 11:15:00+10	0	2	2
36	2026-08-04 11:18:00+10	3	3	6
36	2026-08-04 11:22:00+10	2	1	3
36	2026-08-04 11:33:00+10	2	0	2
36	2026-08-04 11:34:00+10	2	1	3
36	2026-08-04 11:43:00+10	7	3	10
36	2026-08-04 11:46:00+10	1	2	3
36	2026-08-04 11:56:00+10	4	2	6
36	2026-08-04 11:58:00+10	9	0	9
36	2026-08-04 12:08:00+10	5	4	9
36	2026-08-04 12:10:00+10	6	5	11
36	2026-08-04 12:12:00+10	6	4	10
36	2026-08-04 12:13:00+10	0	6	6
36	2026-08-04 12:14:00+10	11	3	14
36	2026-08-04 12:17:00+10	7	4	11
36	2026-08-04 12:18:00+10	5	5	10
36	2026-08-04 12:24:00+10	7	13	20
36	2026-08-04 12:25:00+10	5	6	11
36	2026-08-04 12:30:00+10	5	10	15
36	2026-08-04 12:37:00+10	5	10	15
36	2026-08-04 12:39:00+10	5	9	14
36	2026-08-04 12:45:00+10	5	7	12
36	2026-08-04 12:54:00+10	4	6	10
36	2026-08-04 13:06:00+10	5	6	11
36	2026-08-04 13:08:00+10	9	3	12
36	2026-08-04 13:19:00+10	6	4	10
36	2026-08-04 13:24:00+10	13	6	19
36	2026-08-04 13:25:00+10	8	7	15
36	2026-08-04 13:27:00+10	4	5	9
36	2026-08-04 13:31:00+10	5	5	10
36	2026-08-04 13:32:00+10	1	3	4
36	2026-08-04 13:33:00+10	3	9	12
36	2026-08-04 13:35:00+10	1	8	9
36	2026-08-04 13:41:00+10	2	6	8
36	2026-08-04 13:56:00+10	5	7	12
36	2026-08-04 13:58:00+10	8	4	12
36	2026-08-04 13:59:00+10	4	2	6
36	2026-08-04 14:00:00+10	2	0	2
36	2026-08-04 14:03:00+10	6	2	8
36	2026-08-04 14:04:00+10	4	2	6
36	2026-08-04 14:06:00+10	2	2	4
36	2026-08-04 14:07:00+10	3	2	5
36	2026-08-04 14:09:00+10	5	10	15
36	2026-08-04 14:12:00+10	6	6	12
36	2026-08-04 14:13:00+10	6	3	9
36	2026-08-04 14:17:00+10	7	4	11
36	2026-08-04 14:18:00+10	0	3	3
36	2026-08-04 14:22:00+10	3	3	6
37	2026-08-04 00:10:00+10	0	3	3
37	2026-08-04 00:30:00+10	2	6	8
37	2026-08-04 00:55:00+10	0	1	1
37	2026-08-04 01:10:00+10	0	1	1
37	2026-08-04 01:30:00+10	2	0	2
37	2026-08-04 02:50:00+10	1	0	1
37	2026-08-04 03:35:00+10	1	0	1
37	2026-08-04 05:45:00+10	0	2	2
37	2026-08-04 06:30:00+10	1	1	2
37	2026-08-04 06:35:00+10	4	0	4
37	2026-08-04 06:45:00+10	1	0	1
37	2026-08-04 07:40:00+10	0	1	1
37	2026-08-04 08:00:00+10	1	2	3
37	2026-08-04 08:05:00+10	2	3	5
37	2026-08-04 08:10:00+10	3	8	11
37	2026-08-04 08:25:00+10	2	4	6
37	2026-08-04 09:30:00+10	3	5	8
37	2026-08-04 09:35:00+10	5	6	11
37	2026-08-04 09:50:00+10	1	3	4
37	2026-08-04 10:05:00+10	5	2	7
37	2026-08-04 10:15:00+10	4	3	7
37	2026-08-04 10:20:00+10	2	3	5
37	2026-08-04 11:05:00+10	2	2	4
37	2026-08-04 11:20:00+10	4	7	11
37	2026-08-04 11:30:00+10	6	5	11
37	2026-08-04 12:20:00+10	5	31	36
37	2026-08-04 12:25:00+10	11	1	12
37	2026-08-04 12:55:00+10	6	18	24
37	2026-08-04 13:20:00+10	9	4	13
37	2026-08-04 13:25:00+10	4	10	14
37	2026-08-04 13:45:00+10	5	13	18
37	2026-08-04 14:20:00+10	6	14	20
39	2026-08-04 02:01:00+10	1	0	1
39	2026-08-04 04:01:00+10	0	1	1
39	2026-08-04 04:04:00+10	1	0	1
39	2026-08-04 06:08:00+10	1	0	1
39	2026-08-04 06:21:00+10	1	1	2
39	2026-08-04 06:27:00+10	3	0	3
39	2026-08-04 06:41:00+10	1	0	1
39	2026-08-04 06:50:00+10	1	0	1
39	2026-08-04 06:55:00+10	3	0	3
39	2026-08-04 06:58:00+10	0	1	1
39	2026-08-04 07:00:00+10	1	0	1
39	2026-08-04 07:03:00+10	2	0	2
39	2026-08-04 07:08:00+10	0	2	2
39	2026-08-04 07:10:00+10	2	0	2
39	2026-08-04 07:32:00+10	0	1	1
39	2026-08-04 07:41:00+10	3	0	3
39	2026-08-04 07:47:00+10	0	2	2
39	2026-08-04 07:48:00+10	2	1	3
39	2026-08-04 07:50:00+10	1	2	3
39	2026-08-04 07:51:00+10	1	2	3
39	2026-08-04 08:02:00+10	2	2	4
39	2026-08-04 08:06:00+10	0	1	1
39	2026-08-04 08:16:00+10	0	1	1
39	2026-08-04 08:18:00+10	1	0	1
39	2026-08-04 08:19:00+10	3	3	6
39	2026-08-04 08:20:00+10	3	0	3
39	2026-08-04 08:23:00+10	0	1	1
39	2026-08-04 08:24:00+10	3	0	3
39	2026-08-04 08:25:00+10	0	1	1
39	2026-08-04 08:27:00+10	0	2	2
39	2026-08-04 08:28:00+10	0	1	1
39	2026-08-04 08:31:00+10	2	1	3
39	2026-08-04 08:32:00+10	2	4	6
39	2026-08-04 08:35:00+10	2	3	5
39	2026-08-04 08:40:00+10	2	3	5
39	2026-08-04 08:42:00+10	1	1	2
39	2026-08-04 08:44:00+10	5	3	8
39	2026-08-04 08:46:00+10	1	0	1
39	2026-08-04 08:47:00+10	5	2	7
39	2026-08-04 08:59:00+10	5	2	7
39	2026-08-04 09:08:00+10	1	2	3
39	2026-08-04 09:12:00+10	6	2	8
39	2026-08-04 09:17:00+10	3	3	6
39	2026-08-04 09:18:00+10	1	3	4
39	2026-08-04 09:20:00+10	5	2	7
39	2026-08-04 09:24:00+10	1	1	2
39	2026-08-04 09:26:00+10	1	1	2
39	2026-08-04 09:27:00+10	8	2	10
39	2026-08-04 09:28:00+10	2	1	3
39	2026-08-04 09:29:00+10	5	0	5
39	2026-08-04 09:30:00+10	3	2	5
39	2026-08-04 09:33:00+10	0	1	1
39	2026-08-04 09:38:00+10	0	1	1
39	2026-08-04 09:42:00+10	0	2	2
39	2026-08-04 09:45:00+10	4	3	7
39	2026-08-04 09:47:00+10	3	0	3
39	2026-08-04 09:49:00+10	2	1	3
39	2026-08-04 09:50:00+10	2	11	13
39	2026-08-04 09:53:00+10	5	2	7
39	2026-08-04 09:54:00+10	4	0	4
39	2026-08-04 09:56:00+10	3	3	6
39	2026-08-04 10:01:00+10	4	1	5
39	2026-08-04 10:05:00+10	2	1	3
39	2026-08-04 10:07:00+10	4	1	5
39	2026-08-04 10:11:00+10	2	0	2
39	2026-08-04 10:21:00+10	0	1	1
39	2026-08-04 10:23:00+10	3	0	3
39	2026-08-04 10:28:00+10	1	0	1
39	2026-08-04 10:34:00+10	0	1	1
39	2026-08-04 10:35:00+10	0	2	2
39	2026-08-04 10:44:00+10	0	3	3
39	2026-08-04 10:47:00+10	2	0	2
39	2026-08-04 10:50:00+10	2	2	4
39	2026-08-04 10:55:00+10	2	1	3
39	2026-08-04 10:58:00+10	2	0	2
39	2026-08-04 11:00:00+10	1	1	2
39	2026-08-04 11:06:00+10	3	4	7
39	2026-08-04 11:17:00+10	4	1	5
39	2026-08-04 11:19:00+10	1	0	1
39	2026-08-04 11:21:00+10	2	1	3
39	2026-08-04 11:24:00+10	1	1	2
39	2026-08-04 11:28:00+10	4	1	5
39	2026-08-04 11:29:00+10	4	0	4
39	2026-08-04 11:31:00+10	1	1	2
39	2026-08-04 11:33:00+10	1	0	1
39	2026-08-04 11:34:00+10	0	8	8
39	2026-08-04 11:38:00+10	3	0	3
39	2026-08-04 11:39:00+10	5	0	5
39	2026-08-04 11:45:00+10	0	1	1
39	2026-08-04 11:51:00+10	0	2	2
39	2026-08-04 11:53:00+10	1	0	1
39	2026-08-04 11:56:00+10	2	0	2
39	2026-08-04 11:57:00+10	1	1	2
39	2026-08-04 12:00:00+10	1	1	2
39	2026-08-04 12:03:00+10	1	0	1
39	2026-08-04 12:06:00+10	2	1	3
39	2026-08-04 12:09:00+10	5	3	8
39	2026-08-04 12:11:00+10	11	0	11
39	2026-08-04 12:24:00+10	10	3	13
39	2026-08-04 12:26:00+10	2	1	3
39	2026-08-04 12:27:00+10	3	3	6
39	2026-08-04 12:33:00+10	3	1	4
39	2026-08-04 12:34:00+10	8	9	17
39	2026-08-04 12:37:00+10	10	6	16
39	2026-08-04 12:42:00+10	2	5	7
39	2026-08-04 12:48:00+10	2	5	7
39	2026-08-04 12:51:00+10	1	1	2
39	2026-08-04 12:52:00+10	2	2	4
39	2026-08-04 12:53:00+10	5	1	6
39	2026-08-04 12:55:00+10	6	4	10
39	2026-08-04 12:59:00+10	2	2	4
39	2026-08-04 13:00:00+10	3	5	8
39	2026-08-04 13:05:00+10	7	2	9
39	2026-08-04 13:12:00+10	7	4	11
39	2026-08-04 13:15:00+10	3	5	8
39	2026-08-04 13:18:00+10	6	3	9
39	2026-08-04 13:19:00+10	2	5	7
39	2026-08-04 13:28:00+10	2	4	6
39	2026-08-04 13:36:00+10	0	5	5
39	2026-08-04 13:39:00+10	2	8	10
39	2026-08-04 13:40:00+10	2	1	3
39	2026-08-04 13:41:00+10	3	6	9
39	2026-08-04 13:42:00+10	1	2	3
39	2026-08-04 13:44:00+10	0	3	3
39	2026-08-04 13:48:00+10	4	2	6
39	2026-08-04 13:52:00+10	3	5	8
39	2026-08-04 13:53:00+10	0	2	2
39	2026-08-04 13:56:00+10	1	1	2
39	2026-08-04 13:57:00+10	4	3	7
39	2026-08-04 13:58:00+10	2	9	11
39	2026-08-04 14:00:00+10	2	5	7
39	2026-08-04 14:02:00+10	1	3	4
39	2026-08-04 14:06:00+10	0	6	6
39	2026-08-04 14:15:00+10	3	1	4
39	2026-08-04 14:16:00+10	2	1	3
39	2026-08-04 14:17:00+10	0	5	5
39	2026-08-04 14:23:00+10	0	2	2
40	2026-08-04 00:05:00+10	2	0	2
40	2026-08-04 00:06:00+10	1	0	1
40	2026-08-04 00:55:00+10	1	0	1
40	2026-08-04 01:48:00+10	1	0	1
40	2026-08-04 02:53:00+10	1	0	1
40	2026-08-04 03:26:00+10	0	1	1
40	2026-08-04 04:05:00+10	0	1	1
40	2026-08-04 05:37:00+10	1	0	1
40	2026-08-04 06:08:00+10	0	1	1
40	2026-08-04 06:16:00+10	0	1	1
40	2026-08-04 06:18:00+10	2	0	2
40	2026-08-04 06:21:00+10	1	0	1
40	2026-08-04 06:25:00+10	1	0	1
40	2026-08-04 06:30:00+10	1	2	3
40	2026-08-04 06:38:00+10	1	0	1
40	2026-08-04 06:46:00+10	3	0	3
40	2026-08-04 06:47:00+10	0	1	1
40	2026-08-04 06:51:00+10	3	2	5
40	2026-08-04 06:58:00+10	0	3	3
40	2026-08-04 07:03:00+10	1	2	3
40	2026-08-04 07:04:00+10	2	2	4
40	2026-08-04 07:14:00+10	2	3	5
40	2026-08-04 07:16:00+10	1	2	3
40	2026-08-04 07:27:00+10	0	2	2
40	2026-08-04 07:28:00+10	4	2	6
40	2026-08-04 07:29:00+10	1	0	1
40	2026-08-04 07:33:00+10	7	3	10
40	2026-08-04 07:35:00+10	0	1	1
40	2026-08-04 07:38:00+10	1	4	5
40	2026-08-04 07:42:00+10	1	3	4
40	2026-08-04 07:44:00+10	3	5	8
40	2026-08-04 07:50:00+10	1	2	3
40	2026-08-04 07:51:00+10	0	2	2
40	2026-08-04 07:52:00+10	0	2	2
40	2026-08-04 07:54:00+10	1	2	3
40	2026-08-04 07:57:00+10	0	1	1
40	2026-08-04 08:04:00+10	2	1	3
40	2026-08-04 08:09:00+10	1	1	2
40	2026-08-04 08:11:00+10	1	0	1
40	2026-08-04 08:18:00+10	0	2	2
40	2026-08-04 08:19:00+10	0	2	2
40	2026-08-04 08:26:00+10	0	1	1
40	2026-08-04 08:27:00+10	0	3	3
40	2026-08-04 08:30:00+10	0	4	4
40	2026-08-04 08:31:00+10	1	6	7
40	2026-08-04 08:37:00+10	0	7	7
40	2026-08-04 08:38:00+10	0	6	6
40	2026-08-04 08:39:00+10	1	9	10
40	2026-08-04 08:40:00+10	2	2	4
40	2026-08-04 08:47:00+10	1	8	9
40	2026-08-04 08:49:00+10	0	16	16
40	2026-08-04 08:51:00+10	1	3	4
40	2026-08-04 08:58:00+10	0	3	3
40	2026-08-04 09:02:00+10	0	5	5
40	2026-08-04 09:03:00+10	0	1	1
40	2026-08-04 09:11:00+10	0	1	1
40	2026-08-04 09:12:00+10	1	4	5
40	2026-08-04 09:14:00+10	0	1	1
40	2026-08-04 09:16:00+10	1	2	3
40	2026-08-04 09:21:00+10	1	5	6
40	2026-08-04 09:23:00+10	0	4	4
40	2026-08-04 09:28:00+10	1	2	3
40	2026-08-04 09:31:00+10	0	1	1
40	2026-08-04 09:36:00+10	0	1	1
40	2026-08-04 09:42:00+10	0	1	1
40	2026-08-04 09:45:00+10	1	2	3
40	2026-08-04 09:47:00+10	0	1	1
40	2026-08-04 09:53:00+10	0	2	2
40	2026-08-04 09:54:00+10	2	4	6
40	2026-08-04 09:55:00+10	4	2	6
40	2026-08-04 09:57:00+10	0	1	1
40	2026-08-04 10:00:00+10	2	1	3
40	2026-08-04 10:04:00+10	2	2	4
40	2026-08-04 10:07:00+10	0	2	2
40	2026-08-04 10:12:00+10	4	3	7
40	2026-08-04 10:14:00+10	8	4	12
40	2026-08-04 10:19:00+10	4	7	11
40	2026-08-04 10:20:00+10	2	0	2
40	2026-08-04 10:21:00+10	0	3	3
40	2026-08-04 10:22:00+10	1	1	2
40	2026-08-04 10:26:00+10	1	7	8
40	2026-08-04 10:27:00+10	0	6	6
40	2026-08-04 10:30:00+10	1	4	5
40	2026-08-04 10:33:00+10	1	2	3
40	2026-08-04 10:37:00+10	2	3	5
40	2026-08-04 10:41:00+10	2	3	5
40	2026-08-04 10:44:00+10	2	4	6
40	2026-08-04 10:46:00+10	0	3	3
40	2026-08-04 10:49:00+10	1	1	2
40	2026-08-04 10:51:00+10	4	2	6
40	2026-08-04 10:55:00+10	3	1	4
40	2026-08-04 10:58:00+10	1	2	3
40	2026-08-04 11:07:00+10	2	0	2
40	2026-08-04 11:13:00+10	3	0	3
40	2026-08-04 11:14:00+10	3	7	10
40	2026-08-04 11:18:00+10	4	0	4
40	2026-08-04 11:26:00+10	0	9	9
40	2026-08-04 11:32:00+10	4	2	6
40	2026-08-04 11:33:00+10	5	5	10
40	2026-08-04 11:38:00+10	1	0	1
40	2026-08-04 11:41:00+10	1	4	5
40	2026-08-04 11:45:00+10	3	0	3
40	2026-08-04 11:59:00+10	3	2	5
40	2026-08-04 12:02:00+10	3	6	9
40	2026-08-04 12:07:00+10	2	11	13
40	2026-08-04 12:20:00+10	9	5	14
40	2026-08-04 12:24:00+10	4	9	13
40	2026-08-04 12:26:00+10	6	6	12
40	2026-08-04 12:28:00+10	2	8	10
40	2026-08-04 12:32:00+10	7	15	22
40	2026-08-04 12:36:00+10	3	17	20
40	2026-08-04 12:37:00+10	7	10	17
40	2026-08-04 12:38:00+10	3	4	7
40	2026-08-04 12:39:00+10	8	12	20
40	2026-08-04 12:42:00+10	4	4	8
40	2026-08-04 12:44:00+10	8	9	17
40	2026-08-04 12:49:00+10	8	2	10
40	2026-08-04 12:53:00+10	12	7	19
40	2026-08-04 12:58:00+10	4	6	10
40	2026-08-04 13:02:00+10	6	9	15
40	2026-08-04 13:05:00+10	7	14	21
40	2026-08-04 13:08:00+10	2	0	2
40	2026-08-04 13:09:00+10	5	14	19
40	2026-08-04 13:11:00+10	4	1	5
40	2026-08-04 13:20:00+10	11	1	12
40	2026-08-04 13:24:00+10	2	4	6
40	2026-08-04 13:28:00+10	1	1	2
40	2026-08-04 13:33:00+10	5	7	12
40	2026-08-04 13:35:00+10	4	7	11
40	2026-08-04 13:37:00+10	5	3	8
40	2026-08-04 13:43:00+10	6	1	7
40	2026-08-04 13:44:00+10	6	3	9
40	2026-08-04 13:45:00+10	5	5	10
40	2026-08-04 13:49:00+10	6	3	9
40	2026-08-04 13:54:00+10	4	3	7
40	2026-08-04 14:01:00+10	4	3	7
40	2026-08-04 14:04:00+10	1	3	4
40	2026-08-04 14:08:00+10	1	3	4
40	2026-08-04 14:12:00+10	10	4	14
40	2026-08-04 14:13:00+10	1	3	4
40	2026-08-04 14:14:00+10	3	5	8
40	2026-08-04 14:15:00+10	0	2	2
40	2026-08-04 14:22:00+10	2	3	5
40	2026-08-04 14:24:00+10	2	6	8
40	2026-08-04 14:25:00+10	3	4	7
40	2026-08-04 14:26:00+10	2	1	3
40	2026-08-04 14:27:00+10	13	6	19
40	2026-08-04 14:38:00+10	3	2	5
40	2026-08-04 14:39:00+10	2	1	3
41	2026-08-03 23:58:00+10	0	1	1
41	2026-08-04 00:04:00+10	0	2	2
41	2026-08-04 00:07:00+10	0	3	3
41	2026-08-04 00:08:00+10	1	3	4
41	2026-08-04 00:09:00+10	1	2	3
41	2026-08-04 00:12:00+10	2	4	6
41	2026-08-04 00:15:00+10	4	1	5
41	2026-08-04 00:16:00+10	0	1	1
41	2026-08-04 00:18:00+10	2	0	2
41	2026-08-04 00:23:00+10	0	4	4
41	2026-08-04 00:31:00+10	1	0	1
41	2026-08-04 00:33:00+10	1	4	5
41	2026-08-04 00:36:00+10	2	0	2
41	2026-08-04 00:39:00+10	0	1	1
41	2026-08-04 00:50:00+10	0	2	2
41	2026-08-04 00:53:00+10	0	1	1
41	2026-08-04 00:54:00+10	0	1	1
41	2026-08-04 00:55:00+10	8	1	9
41	2026-08-04 00:56:00+10	5	3	8
41	2026-08-04 00:58:00+10	0	3	3
41	2026-08-04 01:02:00+10	3	5	8
41	2026-08-04 01:05:00+10	1	0	1
41	2026-08-04 01:08:00+10	0	4	4
41	2026-08-04 01:10:00+10	0	1	1
41	2026-08-04 01:15:00+10	2	0	2
41	2026-08-04 01:20:00+10	1	0	1
41	2026-08-04 01:23:00+10	2	0	2
41	2026-08-04 01:24:00+10	2	1	3
41	2026-08-04 01:25:00+10	0	1	1
41	2026-08-04 01:26:00+10	1	0	1
41	2026-08-04 01:28:00+10	0	1	1
41	2026-08-04 01:36:00+10	3	0	3
41	2026-08-04 01:42:00+10	0	1	1
41	2026-08-04 01:44:00+10	2	0	2
41	2026-08-04 01:45:00+10	0	2	2
41	2026-08-04 02:02:00+10	0	2	2
41	2026-08-04 02:06:00+10	6	0	6
41	2026-08-04 02:09:00+10	0	2	2
41	2026-08-04 02:15:00+10	1	2	3
41	2026-08-04 02:20:00+10	0	1	1
41	2026-08-04 02:21:00+10	1	0	1
41	2026-08-04 02:28:00+10	3	0	3
41	2026-08-04 02:30:00+10	0	2	2
41	2026-08-04 02:32:00+10	0	2	2
41	2026-08-04 02:36:00+10	1	0	1
41	2026-08-04 02:42:00+10	0	1	1
41	2026-08-04 02:45:00+10	0	2	2
41	2026-08-04 02:51:00+10	1	0	1
41	2026-08-04 02:52:00+10	0	1	1
41	2026-08-04 02:53:00+10	2	0	2
41	2026-08-04 02:54:00+10	2	0	2
41	2026-08-04 02:57:00+10	0	2	2
41	2026-08-04 03:19:00+10	1	1	2
41	2026-08-04 03:31:00+10	0	1	1
41	2026-08-04 03:38:00+10	2	0	2
41	2026-08-04 03:42:00+10	1	0	1
41	2026-08-04 03:54:00+10	1	0	1
41	2026-08-04 04:02:00+10	0	1	1
41	2026-08-04 04:08:00+10	4	0	4
41	2026-08-04 04:17:00+10	1	1	2
41	2026-08-04 04:24:00+10	2	0	2
41	2026-08-04 04:25:00+10	0	2	2
41	2026-08-04 04:27:00+10	1	0	1
41	2026-08-04 04:28:00+10	0	1	1
41	2026-08-04 04:29:00+10	0	2	2
41	2026-08-04 04:32:00+10	0	4	4
41	2026-08-04 04:35:00+10	0	1	1
41	2026-08-04 04:40:00+10	1	1	2
41	2026-08-04 04:41:00+10	3	0	3
41	2026-08-04 04:44:00+10	0	1	1
41	2026-08-04 04:45:00+10	2	0	2
41	2026-08-04 04:48:00+10	1	7	8
41	2026-08-04 04:51:00+10	0	2	2
41	2026-08-04 04:52:00+10	0	2	2
41	2026-08-04 04:57:00+10	1	0	1
41	2026-08-04 04:59:00+10	1	0	1
41	2026-08-04 05:09:00+10	0	2	2
41	2026-08-04 05:26:00+10	1	0	1
41	2026-08-04 05:30:00+10	1	1	2
41	2026-08-04 05:31:00+10	2	1	3
41	2026-08-04 05:32:00+10	2	2	4
41	2026-08-04 05:33:00+10	3	1	4
41	2026-08-04 05:38:00+10	7	3	10
41	2026-08-04 05:45:00+10	3	3	6
41	2026-08-04 05:46:00+10	2	2	4
41	2026-08-04 05:47:00+10	3	3	6
41	2026-08-04 05:59:00+10	3	0	3
41	2026-08-04 06:00:00+10	1	3	4
41	2026-08-04 06:02:00+10	5	5	10
41	2026-08-04 06:06:00+10	4	0	4
41	2026-08-04 06:07:00+10	0	2	2
41	2026-08-04 06:09:00+10	4	1	5
41	2026-08-04 06:12:00+10	0	3	3
41	2026-08-04 06:14:00+10	3	3	6
41	2026-08-04 06:26:00+10	5	1	6
41	2026-08-04 06:28:00+10	0	3	3
41	2026-08-04 06:30:00+10	4	2	6
41	2026-08-04 06:34:00+10	10	1	11
41	2026-08-04 06:48:00+10	2	4	6
41	2026-08-04 06:54:00+10	2	1	3
41	2026-08-04 06:56:00+10	5	9	14
41	2026-08-04 06:57:00+10	4	6	10
41	2026-08-04 07:00:00+10	14	5	19
41	2026-08-04 07:04:00+10	5	1	6
41	2026-08-04 07:05:00+10	15	2	17
41	2026-08-04 07:09:00+10	7	1	8
41	2026-08-04 07:11:00+10	7	2	9
41	2026-08-04 07:12:00+10	11	0	11
41	2026-08-04 07:16:00+10	8	6	14
41	2026-08-04 07:17:00+10	3	4	7
41	2026-08-04 07:27:00+10	4	1	5
41	2026-08-04 07:29:00+10	3	2	5
41	2026-08-04 07:30:00+10	2	1	3
41	2026-08-04 07:34:00+10	11	4	15
41	2026-08-04 07:37:00+10	13	3	16
41	2026-08-04 07:38:00+10	12	3	15
41	2026-08-04 07:42:00+10	9	5	14
41	2026-08-04 07:44:00+10	10	11	21
41	2026-08-04 07:47:00+10	17	4	21
41	2026-08-04 07:48:00+10	16	3	19
41	2026-08-04 07:49:00+10	16	7	23
41	2026-08-04 07:51:00+10	7	1	8
41	2026-08-04 07:52:00+10	9	11	20
41	2026-08-04 07:54:00+10	8	5	13
41	2026-08-04 07:55:00+10	13	7	20
41	2026-08-04 07:56:00+10	27	4	31
41	2026-08-04 07:57:00+10	36	3	39
41	2026-08-04 08:37:00+10	28	4	32
41	2026-08-04 08:39:00+10	17	5	22
41	2026-08-04 08:40:00+10	31	6	37
41	2026-08-04 08:45:00+10	39	15	54
41	2026-08-04 08:46:00+10	36	9	45
41	2026-08-04 08:53:00+10	53	6	59
41	2026-08-04 09:04:00+10	21	9	30
41	2026-08-04 09:09:00+10	20	9	29
41	2026-08-04 09:13:00+10	25	10	35
41	2026-08-04 09:15:00+10	15	6	21
41	2026-08-04 09:22:00+10	12	7	19
41	2026-08-04 09:23:00+10	13	8	21
41	2026-08-04 09:28:00+10	15	5	20
41	2026-08-04 09:29:00+10	30	12	42
41	2026-08-04 09:30:00+10	20	7	27
41	2026-08-04 09:32:00+10	40	7	47
41	2026-08-04 09:36:00+10	19	0	19
41	2026-08-04 09:38:00+10	36	9	45
41	2026-08-04 09:39:00+10	24	3	27
41	2026-08-04 09:41:00+10	21	6	27
41	2026-08-04 09:42:00+10	7	3	10
41	2026-08-04 09:44:00+10	17	13	30
41	2026-08-04 09:46:00+10	3	5	8
41	2026-08-04 09:50:00+10	14	6	20
41	2026-08-04 09:56:00+10	17	16	33
41	2026-08-04 09:59:00+10	26	5	31
41	2026-08-04 10:01:00+10	4	5	9
41	2026-08-04 10:02:00+10	10	9	19
41	2026-08-04 10:09:00+10	17	14	31
41	2026-08-04 10:15:00+10	23	7	30
41	2026-08-04 10:17:00+10	12	15	27
41	2026-08-04 10:19:00+10	17	12	29
41	2026-08-04 10:20:00+10	50	7	57
41	2026-08-04 10:26:00+10	12	15	27
41	2026-08-04 10:27:00+10	8	12	20
41	2026-08-04 10:28:00+10	8	29	37
41	2026-08-04 10:30:00+10	11	14	25
41	2026-08-04 10:31:00+10	12	12	24
41	2026-08-04 10:32:00+10	27	6	33
41	2026-08-04 10:35:00+10	19	10	29
41	2026-08-04 10:36:00+10	12	6	18
41	2026-08-04 10:40:00+10	8	13	21
41	2026-08-04 10:41:00+10	16	14	30
41	2026-08-04 10:44:00+10	34	11	45
41	2026-08-04 10:46:00+10	18	14	32
41	2026-08-04 10:47:00+10	9	13	22
41	2026-08-04 10:49:00+10	10	18	28
41	2026-08-04 10:50:00+10	13	15	28
41	2026-08-04 10:52:00+10	10	14	24
41	2026-08-04 10:55:00+10	19	16	35
41	2026-08-04 10:57:00+10	15	15	30
41	2026-08-04 10:59:00+10	26	11	37
41	2026-08-04 11:00:00+10	9	8	17
41	2026-08-04 11:01:00+10	16	14	30
41	2026-08-04 11:02:00+10	13	12	25
41	2026-08-04 11:05:00+10	17	19	36
41	2026-08-04 11:06:00+10	16	10	26
41	2026-08-04 11:08:00+10	14	16	30
41	2026-08-04 11:10:00+10	8	12	20
41	2026-08-04 11:11:00+10	24	14	38
41	2026-08-04 11:15:00+10	15	14	29
41	2026-08-04 11:17:00+10	22	7	29
41	2026-08-04 11:20:00+10	21	11	32
41	2026-08-04 11:29:00+10	18	11	29
41	2026-08-04 11:35:00+10	12	15	27
41	2026-08-04 11:36:00+10	13	7	20
41	2026-08-04 11:38:00+10	13	12	25
41	2026-08-04 11:39:00+10	10	14	24
41	2026-08-04 11:41:00+10	18	20	38
41	2026-08-04 11:42:00+10	16	10	26
41	2026-08-04 11:44:00+10	18	11	29
41	2026-08-04 11:45:00+10	12	11	23
41	2026-08-04 11:47:00+10	11	14	25
41	2026-08-04 11:49:00+10	19	12	31
41	2026-08-04 11:51:00+10	16	17	33
41	2026-08-04 11:52:00+10	17	9	26
41	2026-08-04 11:54:00+10	9	17	26
41	2026-08-04 11:58:00+10	13	20	33
41	2026-08-04 11:59:00+10	13	12	25
41	2026-08-04 12:04:00+10	17	15	32
41	2026-08-04 12:13:00+10	18	11	29
41	2026-08-04 12:14:00+10	16	17	33
41	2026-08-04 12:16:00+10	19	12	31
41	2026-08-04 12:20:00+10	21	7	28
41	2026-08-04 12:22:00+10	21	24	45
41	2026-08-04 12:26:00+10	23	24	47
41	2026-08-04 12:27:00+10	17	15	32
41	2026-08-04 12:31:00+10	30	16	46
41	2026-08-04 12:33:00+10	9	13	22
41	2026-08-04 12:35:00+10	28	25	53
41	2026-08-04 12:37:00+10	33	18	51
41	2026-08-04 12:38:00+10	10	16	26
41	2026-08-04 12:40:00+10	16	7	23
41	2026-08-04 12:41:00+10	13	9	22
41	2026-08-04 12:46:00+10	21	10	31
41	2026-08-04 12:47:00+10	24	13	37
41	2026-08-04 12:50:00+10	19	10	29
41	2026-08-04 12:54:00+10	12	19	31
41	2026-08-04 12:57:00+10	26	9	35
41	2026-08-04 13:03:00+10	28	42	70
41	2026-08-04 13:07:00+10	13	20	33
41	2026-08-04 13:11:00+10	38	22	60
41	2026-08-04 13:19:00+10	15	23	38
41	2026-08-04 13:23:00+10	13	16	29
41	2026-08-04 13:25:00+10	36	16	52
41	2026-08-04 13:29:00+10	28	26	54
41	2026-08-04 13:31:00+10	14	16	30
41	2026-08-04 13:32:00+10	23	14	37
41	2026-08-04 13:33:00+10	25	27	52
41	2026-08-04 13:35:00+10	33	20	53
41	2026-08-04 13:37:00+10	16	15	31
41	2026-08-04 13:43:00+10	20	15	35
41	2026-08-04 13:45:00+10	22	18	40
41	2026-08-04 13:46:00+10	28	14	42
41	2026-08-04 13:49:00+10	18	20	38
41	2026-08-04 13:52:00+10	27	11	38
41	2026-08-04 14:02:00+10	12	7	19
41	2026-08-04 14:04:00+10	18	18	36
41	2026-08-04 14:09:00+10	9	17	26
41	2026-08-04 14:11:00+10	24	9	33
41	2026-08-04 14:17:00+10	27	20	47
41	2026-08-04 14:22:00+10	22	8	30
41	2026-08-04 14:23:00+10	16	16	32
41	2026-08-04 14:24:00+10	9	27	36
41	2026-08-04 14:25:00+10	11	19	30
41	2026-08-04 14:26:00+10	20	13	33
41	2026-08-04 14:29:00+10	24	21	45
41	2026-08-04 14:35:00+10	13	17	30
42	2026-08-04 00:31:00+10	0	1	1
42	2026-08-04 02:10:00+10	0	2	2
42	2026-08-04 02:17:00+10	1	0	1
42	2026-08-04 03:17:00+10	0	1	1
42	2026-08-04 04:23:00+10	1	0	1
42	2026-08-04 04:32:00+10	1	0	1
42	2026-08-04 06:15:00+10	2	0	2
42	2026-08-04 06:36:00+10	0	2	2
42	2026-08-04 06:47:00+10	2	0	2
42	2026-08-04 07:05:00+10	1	0	1
42	2026-08-04 07:16:00+10	1	0	1
42	2026-08-04 07:20:00+10	1	0	1
42	2026-08-04 07:23:00+10	2	1	3
42	2026-08-04 07:26:00+10	0	1	1
42	2026-08-04 07:29:00+10	3	0	3
42	2026-08-04 07:32:00+10	2	0	2
42	2026-08-04 07:34:00+10	0	2	2
42	2026-08-04 07:36:00+10	0	1	1
42	2026-08-04 07:40:00+10	2	3	5
42	2026-08-04 07:45:00+10	0	3	3
42	2026-08-04 07:49:00+10	0	1	1
42	2026-08-04 07:53:00+10	0	1	1
42	2026-08-04 07:54:00+10	3	1	4
42	2026-08-04 07:55:00+10	1	7	8
42	2026-08-04 07:59:00+10	1	3	4
42	2026-08-04 08:06:00+10	5	1	6
42	2026-08-04 08:11:00+10	1	0	1
42	2026-08-04 08:13:00+10	2	2	4
42	2026-08-04 08:17:00+10	1	1	2
42	2026-08-04 08:18:00+10	0	4	4
42	2026-08-04 08:19:00+10	2	5	7
42	2026-08-04 08:27:00+10	1	1	2
42	2026-08-04 08:30:00+10	4	2	6
42	2026-08-04 08:34:00+10	3	0	3
42	2026-08-04 08:38:00+10	1	1	2
42	2026-08-04 08:48:00+10	12	2	14
42	2026-08-04 08:56:00+10	15	3	18
42	2026-08-04 08:57:00+10	10	3	13
42	2026-08-04 08:58:00+10	16	1	17
42	2026-08-04 08:59:00+10	11	6	17
42	2026-08-04 09:06:00+10	0	2	2
42	2026-08-04 09:08:00+10	3	1	4
42	2026-08-04 09:13:00+10	3	1	4
42	2026-08-04 09:15:00+10	2	3	5
42	2026-08-04 09:21:00+10	1	0	1
42	2026-08-04 09:24:00+10	2	1	3
42	2026-08-04 09:27:00+10	4	2	6
42	2026-08-04 09:29:00+10	1	1	2
42	2026-08-04 09:30:00+10	0	3	3
42	2026-08-04 09:31:00+10	3	3	6
42	2026-08-04 09:32:00+10	0	7	7
42	2026-08-04 09:36:00+10	2	1	3
42	2026-08-04 09:43:00+10	6	3	9
42	2026-08-04 09:44:00+10	2	7	9
42	2026-08-04 09:48:00+10	11	3	14
42	2026-08-04 09:50:00+10	18	5	23
42	2026-08-04 09:51:00+10	9	2	11
42	2026-08-04 10:06:00+10	2	13	15
42	2026-08-04 10:09:00+10	5	5	10
42	2026-08-04 10:13:00+10	4	5	9
42	2026-08-04 10:16:00+10	0	2	2
42	2026-08-04 10:17:00+10	1	1	2
42	2026-08-04 10:23:00+10	5	3	8
42	2026-08-04 10:29:00+10	4	6	10
42	2026-08-04 10:33:00+10	0	1	1
42	2026-08-04 10:43:00+10	2	1	3
42	2026-08-04 10:47:00+10	5	2	7
42	2026-08-04 10:51:00+10	5	7	12
42	2026-08-04 10:54:00+10	8	4	12
42	2026-08-04 11:05:00+10	5	9	14
42	2026-08-04 11:09:00+10	4	4	8
42	2026-08-04 11:15:00+10	2	2	4
42	2026-08-04 11:18:00+10	5	4	9
42	2026-08-04 11:22:00+10	2	3	5
42	2026-08-04 11:26:00+10	4	5	9
42	2026-08-04 11:33:00+10	4	2	6
42	2026-08-04 11:35:00+10	0	1	1
42	2026-08-04 11:37:00+10	3	11	14
42	2026-08-04 11:42:00+10	0	2	2
42	2026-08-04 11:46:00+10	5	0	5
42	2026-08-04 11:53:00+10	1	3	4
42	2026-08-04 11:54:00+10	2	10	12
42	2026-08-04 12:10:00+10	2	16	18
42	2026-08-04 12:11:00+10	6	20	26
42	2026-08-04 12:15:00+10	3	5	8
42	2026-08-04 12:16:00+10	2	17	19
42	2026-08-04 12:19:00+10	3	4	7
42	2026-08-04 12:21:00+10	3	16	19
42	2026-08-04 12:23:00+10	2	5	7
42	2026-08-04 12:31:00+10	6	4	10
42	2026-08-04 12:32:00+10	6	7	13
42	2026-08-04 12:34:00+10	13	19	32
42	2026-08-04 12:36:00+10	5	3	8
42	2026-08-04 12:39:00+10	4	22	26
42	2026-08-04 12:42:00+10	7	6	13
42	2026-08-04 12:44:00+10	3	17	20
42	2026-08-04 12:45:00+10	9	11	20
42	2026-08-04 12:51:00+10	3	15	18
42	2026-08-04 12:53:00+10	9	11	20
42	2026-08-04 12:54:00+10	10	11	21
42	2026-08-04 12:57:00+10	6	8	14
42	2026-08-04 12:58:00+10	18	7	25
42	2026-08-04 13:06:00+10	7	16	23
42	2026-08-04 13:07:00+10	13	8	21
42	2026-08-04 13:10:00+10	6	3	9
42	2026-08-04 13:13:00+10	3	7	10
42	2026-08-04 13:14:00+10	15	8	23
42	2026-08-04 13:20:00+10	10	2	12
42	2026-08-04 13:26:00+10	13	5	18
42	2026-08-04 13:28:00+10	26	10	36
42	2026-08-04 13:29:00+10	9	8	17
42	2026-08-04 13:36:00+10	6	4	10
42	2026-08-04 13:37:00+10	13	7	20
42	2026-08-04 13:50:00+10	24	10	34
42	2026-08-04 13:51:00+10	7	7	14
42	2026-08-04 13:52:00+10	7	6	13
42	2026-08-04 13:56:00+10	17	5	22
42	2026-08-04 13:58:00+10	10	4	14
42	2026-08-04 14:06:00+10	8	15	23
42	2026-08-04 14:09:00+10	14	6	20
42	2026-08-04 14:12:00+10	9	5	14
42	2026-08-04 14:13:00+10	6	12	18
42	2026-08-04 14:18:00+10	6	5	11
42	2026-08-04 14:21:00+10	3	6	9
42	2026-08-04 14:24:00+10	0	1	1
42	2026-08-04 14:30:00+10	4	4	8
42	2026-08-04 14:34:00+10	3	8	11
42	2026-08-04 14:35:00+10	2	5	7
42	2026-08-04 14:38:00+10	4	4	8
43	2026-08-04 00:25:00+10	1	0	1
43	2026-08-04 01:25:00+10	1	0	1
43	2026-08-04 01:30:00+10	1	0	1
43	2026-08-04 01:40:00+10	3	0	3
43	2026-08-04 02:05:00+10	0	1	1
43	2026-08-04 03:10:00+10	0	1	1
43	2026-08-04 04:15:00+10	0	1	1
43	2026-08-04 04:20:00+10	1	0	1
43	2026-08-04 05:10:00+10	0	1	1
43	2026-08-04 05:45:00+10	0	1	1
43	2026-08-04 05:55:00+10	0	3	3
43	2026-08-04 06:35:00+10	1	1	2
43	2026-08-04 07:20:00+10	2	1	3
43	2026-08-04 07:25:00+10	3	1	4
43	2026-08-04 07:30:00+10	4	2	6
43	2026-08-04 07:45:00+10	10	4	14
43	2026-08-04 07:55:00+10	9	1	10
43	2026-08-04 08:10:00+10	5	7	12
43	2026-08-04 08:20:00+10	12	8	20
43	2026-08-04 08:40:00+10	22	8	30
43	2026-08-04 09:10:00+10	27	6	33
43	2026-08-04 09:30:00+10	6	5	11
43	2026-08-04 09:35:00+10	19	11	30
43	2026-08-04 09:40:00+10	22	16	38
43	2026-08-04 09:50:00+10	54	5	59
43	2026-08-04 09:55:00+10	56	22	78
43	2026-08-04 10:55:00+10	36	47	83
43	2026-08-04 11:00:00+10	42	59	101
43	2026-08-04 12:00:00+10	13	49	62
43	2026-08-04 12:30:00+10	18	30	48
43	2026-08-04 13:10:00+10	23	26	49
43	2026-08-04 13:20:00+10	24	23	47
43	2026-08-04 13:30:00+10	43	23	66
43	2026-08-04 13:50:00+10	39	32	71
43	2026-08-04 14:05:00+10	28	64	92
44	2026-08-04 00:00:00+10	1	0	1
44	2026-08-04 00:20:00+10	1	0	1
44	2026-08-04 00:35:00+10	1	0	1
44	2026-08-04 01:00:00+10	0	1	1
44	2026-08-04 01:30:00+10	1	0	1
44	2026-08-04 01:40:00+10	3	0	3
44	2026-08-04 02:20:00+10	1	0	1
44	2026-08-04 03:10:00+10	0	1	1
44	2026-08-04 04:15:00+10	0	1	1
44	2026-08-04 06:05:00+10	0	1	1
44	2026-08-04 06:50:00+10	2	0	2
44	2026-08-04 07:10:00+10	2	1	3
44	2026-08-04 07:30:00+10	3	2	5
44	2026-08-04 07:55:00+10	0	2	2
44	2026-08-04 08:15:00+10	1	7	8
44	2026-08-04 08:35:00+10	5	5	10
44	2026-08-04 08:45:00+10	11	12	23
44	2026-08-04 08:55:00+10	7	24	31
44	2026-08-04 09:00:00+10	13	14	27
44	2026-08-04 09:05:00+10	2	7	9
44	2026-08-04 09:25:00+10	2	7	9
44	2026-08-04 09:50:00+10	8	10	18
44	2026-08-04 09:55:00+10	14	15	29
44	2026-08-04 10:00:00+10	13	11	24
44	2026-08-04 10:05:00+10	9	11	20
44	2026-08-04 10:10:00+10	5	6	11
44	2026-08-04 10:45:00+10	1	7	8
44	2026-08-04 10:50:00+10	12	10	22
44	2026-08-04 11:00:00+10	18	15	33
44	2026-08-04 12:15:00+10	14	16	30
44	2026-08-04 12:25:00+10	14	9	23
44	2026-08-04 12:30:00+10	6	8	14
44	2026-08-04 12:35:00+10	4	17	21
44	2026-08-04 12:40:00+10	8	15	23
44	2026-08-04 13:05:00+10	7	15	22
44	2026-08-04 13:10:00+10	24	4	28
44	2026-08-04 13:15:00+10	9	16	25
44	2026-08-04 13:30:00+10	29	5	34
44	2026-08-04 13:50:00+10	13	16	29
44	2026-08-04 13:55:00+10	13	10	23
45	2026-08-03 23:55:00+10	1	2	3
45	2026-08-04 00:15:00+10	2	1	3
45	2026-08-04 01:20:00+10	1	1	2
45	2026-08-04 01:45:00+10	2	3	5
45	2026-08-04 02:40:00+10	1	0	1
45	2026-08-04 04:35:00+10	0	2	2
45	2026-08-04 05:05:00+10	1	0	1
45	2026-08-04 06:00:00+10	3	10	13
45	2026-08-04 06:55:00+10	4	11	15
45	2026-08-04 07:05:00+10	13	8	21
45	2026-08-04 07:30:00+10	7	7	14
45	2026-08-04 07:40:00+10	18	8	26
45	2026-08-04 07:45:00+10	17	10	27
45	2026-08-04 07:50:00+10	12	17	29
45	2026-08-04 08:05:00+10	28	18	46
45	2026-08-04 08:25:00+10	46	26	72
45	2026-08-04 08:30:00+10	49	24	73
45	2026-08-04 08:55:00+10	55	29	84
45	2026-08-04 09:45:00+10	14	23	37
45	2026-08-04 09:50:00+10	25	19	44
45	2026-08-04 10:05:00+10	20	12	32
45	2026-08-04 10:20:00+10	26	36	62
45	2026-08-04 11:00:00+10	30	29	59
45	2026-08-04 11:20:00+10	23	69	92
45	2026-08-04 11:25:00+10	46	35	81
45	2026-08-04 11:30:00+10	71	43	114
45	2026-08-04 12:05:00+10	48	40	88
45	2026-08-04 12:10:00+10	34	35	69
45	2026-08-04 12:40:00+10	46	67	113
45	2026-08-04 13:00:00+10	49	82	131
45	2026-08-04 13:20:00+10	43	74	117
45	2026-08-04 13:35:00+10	36	73	109
45	2026-08-04 14:05:00+10	49	68	117
45	2026-08-04 14:15:00+10	37	51	88
45	2026-08-04 14:20:00+10	46	74	120
45	2026-08-04 14:35:00+10	40	78	118
46	2026-08-04 06:45:00+10	1	0	1
46	2026-08-04 06:50:00+10	2	1	3
46	2026-08-04 06:55:00+10	5	4	9
46	2026-08-04 07:15:00+10	2	0	2
46	2026-08-04 07:40:00+10	5	4	9
46	2026-08-04 07:55:00+10	3	0	3
46	2026-08-04 08:10:00+10	0	2	2
46	2026-08-04 08:30:00+10	9	4	13
46	2026-08-04 08:40:00+10	17	8	25
46	2026-08-04 09:20:00+10	10	5	15
46	2026-08-04 09:25:00+10	18	2	20
46	2026-08-04 09:35:00+10	6	3	9
46	2026-08-04 09:50:00+10	7	3	10
46	2026-08-04 10:00:00+10	11	7	18
46	2026-08-04 10:05:00+10	9	9	18
46	2026-08-04 10:20:00+10	7	1	8
46	2026-08-04 10:25:00+10	6	2	8
46	2026-08-04 10:30:00+10	3	5	8
46	2026-08-04 11:05:00+10	1	2	3
46	2026-08-04 11:35:00+10	0	1	1
46	2026-08-04 11:40:00+10	2	8	10
46	2026-08-04 12:25:00+10	12	4	16
46	2026-08-04 13:10:00+10	2	2	4
46	2026-08-04 13:15:00+10	1	8	9
46	2026-08-04 13:20:00+10	1	15	16
46	2026-08-04 13:35:00+10	0	1	1
46	2026-08-04 13:45:00+10	12	8	20
46	2026-08-04 14:30:00+10	20	3	23
47	2026-08-04 00:00:00+10	6	5	11
47	2026-08-04 00:20:00+10	1	3	4
47	2026-08-04 00:25:00+10	8	1	9
47	2026-08-04 00:50:00+10	2	0	2
47	2026-08-04 01:15:00+10	0	3	3
47	2026-08-04 02:20:00+10	0	3	3
47	2026-08-04 03:00:00+10	1	0	1
47	2026-08-04 03:25:00+10	2	1	3
47	2026-08-04 04:05:00+10	1	0	1
47	2026-08-04 04:20:00+10	0	1	1
47	2026-08-04 04:30:00+10	0	1	1
47	2026-08-04 04:35:00+10	0	1	1
47	2026-08-04 05:25:00+10	1	2	3
47	2026-08-04 05:40:00+10	1	4	5
47	2026-08-04 05:55:00+10	3	7	10
47	2026-08-04 06:00:00+10	1	5	6
47	2026-08-04 06:10:00+10	1	8	9
47	2026-08-04 06:25:00+10	1	6	7
47	2026-08-04 06:30:00+10	3	14	17
47	2026-08-04 07:00:00+10	6	7	13
47	2026-08-04 07:05:00+10	7	13	20
47	2026-08-04 07:10:00+10	7	11	18
47	2026-08-04 07:20:00+10	4	11	15
47	2026-08-04 07:30:00+10	7	34	41
47	2026-08-04 07:35:00+10	6	26	32
47	2026-08-04 07:40:00+10	9	21	30
47	2026-08-04 08:10:00+10	29	46	75
47	2026-08-04 08:15:00+10	24	56	80
47	2026-08-04 08:20:00+10	19	47	66
47	2026-08-04 08:40:00+10	24	52	76
47	2026-08-04 08:50:00+10	21	67	88
47	2026-08-04 08:55:00+10	17	55	72
47	2026-08-04 09:10:00+10	11	12	23
47	2026-08-04 09:40:00+10	18	36	54
47	2026-08-04 09:50:00+10	23	36	59
47	2026-08-04 10:15:00+10	35	26	61
47	2026-08-04 10:20:00+10	24	45	69
47	2026-08-04 11:25:00+10	39	40	79
47	2026-08-04 11:30:00+10	30	44	74
47	2026-08-04 11:35:00+10	26	27	53
47	2026-08-04 11:50:00+10	17	28	45
47	2026-08-04 12:05:00+10	39	43	82
47	2026-08-04 12:20:00+10	51	60	111
47	2026-08-04 12:55:00+10	43	50	93
47	2026-08-04 13:05:00+10	52	81	133
47	2026-08-04 13:55:00+10	39	58	97
47	2026-08-04 14:10:00+10	48	57	105
47	2026-08-04 14:15:00+10	35	68	103
47	2026-08-04 14:35:00+10	54	73	127
48	2026-08-04 00:10:00+10	0	3	3
48	2026-08-04 00:20:00+10	0	2	2
48	2026-08-04 00:45:00+10	2	0	2
48	2026-08-04 01:00:00+10	1	2	3
48	2026-08-04 01:55:00+10	1	0	1
48	2026-08-04 02:00:00+10	0	1	1
48	2026-08-04 02:05:00+10	2	0	2
48	2026-08-04 02:15:00+10	0	1	1
48	2026-08-04 02:45:00+10	0	1	1
48	2026-08-04 03:55:00+10	1	0	1
48	2026-08-04 04:55:00+10	0	1	1
48	2026-08-04 05:00:00+10	1	0	1
48	2026-08-04 05:15:00+10	1	0	1
48	2026-08-04 05:40:00+10	1	1	2
48	2026-08-04 06:00:00+10	0	2	2
48	2026-08-04 06:15:00+10	2	1	3
48	2026-08-04 06:25:00+10	2	1	3
48	2026-08-04 07:00:00+10	2	4	6
48	2026-08-04 07:10:00+10	10	5	15
48	2026-08-04 07:20:00+10	3	2	5
48	2026-08-04 07:25:00+10	7	3	10
48	2026-08-04 07:35:00+10	5	4	9
48	2026-08-04 07:40:00+10	2	4	6
48	2026-08-04 07:55:00+10	9	3	12
48	2026-08-04 08:00:00+10	7	6	13
48	2026-08-04 08:05:00+10	13	6	19
48	2026-08-04 08:35:00+10	14	11	25
48	2026-08-04 08:55:00+10	28	12	40
48	2026-08-04 09:10:00+10	16	12	28
48	2026-08-04 09:20:00+10	9	5	14
48	2026-08-04 09:25:00+10	10	8	18
48	2026-08-04 10:05:00+10	12	11	23
48	2026-08-04 10:15:00+10	22	14	36
48	2026-08-04 10:30:00+10	15	11	26
48	2026-08-04 10:45:00+10	22	15	37
48	2026-08-04 11:10:00+10	33	15	48
48	2026-08-04 11:15:00+10	12	20	32
48	2026-08-04 11:30:00+10	28	6	34
48	2026-08-04 12:05:00+10	35	14	49
48	2026-08-04 12:35:00+10	24	16	40
48	2026-08-04 12:45:00+10	19	11	30
48	2026-08-04 12:50:00+10	29	19	48
48	2026-08-04 13:20:00+10	31	30	61
48	2026-08-04 13:25:00+10	21	11	32
48	2026-08-04 14:20:00+10	32	25	57
49	2026-08-04 00:00:00+10	2	4	6
49	2026-08-04 00:05:00+10	4	1	5
49	2026-08-04 00:10:00+10	3	3	6
49	2026-08-04 00:15:00+10	1	1	2
49	2026-08-04 00:25:00+10	1	3	4
49	2026-08-04 00:30:00+10	4	4	8
49	2026-08-04 00:35:00+10	3	0	3
49	2026-08-04 00:40:00+10	2	1	3
49	2026-08-04 01:00:00+10	0	2	2
49	2026-08-04 01:10:00+10	5	2	7
49	2026-08-04 01:20:00+10	5	9	14
49	2026-08-04 01:30:00+10	2	0	2
49	2026-08-04 01:35:00+10	4	0	4
49	2026-08-04 01:55:00+10	0	2	2
49	2026-08-04 02:10:00+10	7	5	12
49	2026-08-04 02:15:00+10	1	0	1
49	2026-08-04 02:25:00+10	0	1	1
49	2026-08-04 02:50:00+10	3	0	3
49	2026-08-04 02:55:00+10	0	1	1
49	2026-08-04 03:15:00+10	2	0	2
49	2026-08-04 03:40:00+10	1	1	2
49	2026-08-04 04:55:00+10	1	1	2
49	2026-08-04 05:05:00+10	0	1	1
49	2026-08-04 05:10:00+10	1	1	2
49	2026-08-04 05:35:00+10	2	0	2
49	2026-08-04 05:40:00+10	1	1	2
49	2026-08-04 05:45:00+10	1	3	4
49	2026-08-04 06:00:00+10	1	1	2
49	2026-08-04 06:15:00+10	0	1	1
49	2026-08-04 06:25:00+10	1	2	3
49	2026-08-04 06:40:00+10	2	1	3
49	2026-08-04 06:45:00+10	1	3	4
49	2026-08-04 06:55:00+10	4	8	12
49	2026-08-04 07:10:00+10	1	4	5
49	2026-08-04 07:20:00+10	5	6	11
49	2026-08-04 07:25:00+10	8	7	15
49	2026-08-04 07:40:00+10	8	4	12
49	2026-08-04 07:50:00+10	1	4	5
49	2026-08-04 08:05:00+10	14	10	24
49	2026-08-04 08:10:00+10	12	7	19
49	2026-08-04 08:20:00+10	13	7	20
49	2026-08-04 09:10:00+10	18	19	37
49	2026-08-04 09:30:00+10	19	20	39
49	2026-08-04 10:05:00+10	18	18	36
49	2026-08-04 10:15:00+10	27	24	51
49	2026-08-04 10:40:00+10	22	29	51
49	2026-08-04 10:55:00+10	43	12	55
49	2026-08-04 11:20:00+10	39	26	65
49	2026-08-04 11:25:00+10	33	21	54
49	2026-08-04 11:30:00+10	34	21	55
49	2026-08-04 11:40:00+10	10	13	23
49	2026-08-04 12:20:00+10	47	35	82
49	2026-08-04 12:30:00+10	55	45	100
49	2026-08-04 12:50:00+10	48	28	76
49	2026-08-04 13:00:00+10	43	25	68
49	2026-08-04 13:15:00+10	53	37	90
49	2026-08-04 14:15:00+10	48	37	85
49	2026-08-04 14:25:00+10	40	26	66
49	2026-08-04 14:30:00+10	53	14	67
50	2026-08-03 23:55:00+10	1	0	1
50	2026-08-04 02:46:00+10	0	1	1
50	2026-08-04 03:46:00+10	1	0	1
50	2026-08-04 06:07:00+10	1	0	1
50	2026-08-04 06:10:00+10	1	0	1
50	2026-08-04 06:26:00+10	1	0	1
50	2026-08-04 06:31:00+10	3	0	3
50	2026-08-04 06:32:00+10	1	0	1
50	2026-08-04 06:46:00+10	0	1	1
50	2026-08-04 06:49:00+10	3	1	4
50	2026-08-04 06:51:00+10	1	2	3
50	2026-08-04 06:53:00+10	1	0	1
50	2026-08-04 06:54:00+10	0	1	1
50	2026-08-04 07:20:00+10	1	0	1
50	2026-08-04 07:28:00+10	1	0	1
50	2026-08-04 07:33:00+10	1	0	1
50	2026-08-04 07:41:00+10	1	0	1
50	2026-08-04 07:43:00+10	0	1	1
50	2026-08-04 07:50:00+10	1	0	1
50	2026-08-04 07:55:00+10	1	0	1
50	2026-08-04 08:11:00+10	1	0	1
50	2026-08-04 08:17:00+10	2	1	3
50	2026-08-04 08:19:00+10	2	1	3
50	2026-08-04 08:20:00+10	0	1	1
50	2026-08-04 08:22:00+10	8	2	10
50	2026-08-04 08:29:00+10	3	1	4
50	2026-08-04 08:32:00+10	1	0	1
50	2026-08-04 08:34:00+10	2	1	3
50	2026-08-04 08:35:00+10	4	0	4
50	2026-08-04 08:37:00+10	1	0	1
50	2026-08-04 08:43:00+10	0	1	1
50	2026-08-04 08:48:00+10	1	0	1
50	2026-08-04 08:49:00+10	3	2	5
50	2026-08-04 08:53:00+10	0	1	1
50	2026-08-04 09:06:00+10	1	1	2
50	2026-08-04 09:07:00+10	1	1	2
50	2026-08-04 09:08:00+10	3	0	3
50	2026-08-04 09:09:00+10	2	1	3
50	2026-08-04 09:12:00+10	1	3	4
50	2026-08-04 09:15:00+10	5	0	5
50	2026-08-04 09:17:00+10	2	1	3
50	2026-08-04 09:19:00+10	4	1	5
50	2026-08-04 09:25:00+10	1	0	1
50	2026-08-04 09:30:00+10	1	1	2
50	2026-08-04 09:32:00+10	1	0	1
50	2026-08-04 09:34:00+10	2	1	3
50	2026-08-04 09:41:00+10	1	3	4
50	2026-08-04 09:43:00+10	1	4	5
50	2026-08-04 09:44:00+10	1	0	1
50	2026-08-04 09:45:00+10	1	0	1
50	2026-08-04 09:47:00+10	1	2	3
50	2026-08-04 09:48:00+10	1	0	1
50	2026-08-04 09:50:00+10	8	1	9
50	2026-08-04 09:52:00+10	4	1	5
50	2026-08-04 09:53:00+10	1	3	4
50	2026-08-04 09:55:00+10	4	0	4
50	2026-08-04 09:59:00+10	5	2	7
50	2026-08-04 10:10:00+10	2	2	4
50	2026-08-04 10:11:00+10	2	0	2
50	2026-08-04 10:15:00+10	1	3	4
50	2026-08-04 10:17:00+10	2	1	3
50	2026-08-04 10:18:00+10	1	1	2
50	2026-08-04 10:21:00+10	2	2	4
50	2026-08-04 10:22:00+10	5	1	6
50	2026-08-04 10:23:00+10	0	2	2
50	2026-08-04 10:25:00+10	2	2	4
50	2026-08-04 10:29:00+10	1	2	3
50	2026-08-04 10:33:00+10	0	1	1
50	2026-08-04 10:42:00+10	4	0	4
50	2026-08-04 10:45:00+10	6	2	8
50	2026-08-04 10:49:00+10	3	9	12
50	2026-08-04 10:54:00+10	3	0	3
50	2026-08-04 11:03:00+10	4	1	5
50	2026-08-04 11:09:00+10	5	2	7
50	2026-08-04 11:10:00+10	2	4	6
50	2026-08-04 11:15:00+10	1	1	2
50	2026-08-04 11:16:00+10	4	0	4
50	2026-08-04 11:17:00+10	1	2	3
50	2026-08-04 11:25:00+10	2	1	3
50	2026-08-04 11:26:00+10	1	3	4
50	2026-08-04 11:28:00+10	7	0	7
50	2026-08-04 11:32:00+10	4	1	5
50	2026-08-04 11:33:00+10	4	4	8
50	2026-08-04 11:37:00+10	4	4	8
50	2026-08-04 11:40:00+10	5	1	6
50	2026-08-04 11:45:00+10	2	4	6
50	2026-08-04 11:46:00+10	1	0	1
50	2026-08-04 11:47:00+10	2	2	4
50	2026-08-04 11:48:00+10	0	3	3
50	2026-08-04 11:50:00+10	0	6	6
50	2026-08-04 11:51:00+10	7	1	8
50	2026-08-04 11:52:00+10	5	7	12
50	2026-08-04 11:54:00+10	10	3	13
50	2026-08-04 11:56:00+10	0	4	4
50	2026-08-04 11:58:00+10	4	0	4
50	2026-08-04 12:05:00+10	3	2	5
50	2026-08-04 12:07:00+10	3	0	3
50	2026-08-04 12:13:00+10	3	6	9
50	2026-08-04 12:19:00+10	0	8	8
50	2026-08-04 12:25:00+10	0	10	10
50	2026-08-04 12:26:00+10	2	3	5
50	2026-08-04 12:29:00+10	12	1	13
50	2026-08-04 12:35:00+10	5	7	12
50	2026-08-04 12:38:00+10	3	4	7
50	2026-08-04 12:39:00+10	4	2	6
50	2026-08-04 12:47:00+10	2	10	12
50	2026-08-04 12:59:00+10	1	3	4
50	2026-08-04 13:05:00+10	7	3	10
50	2026-08-04 13:06:00+10	2	1	3
50	2026-08-04 13:08:00+10	5	2	7
50	2026-08-04 13:09:00+10	3	1	4
50	2026-08-04 13:13:00+10	3	8	11
50	2026-08-04 13:16:00+10	4	2	6
50	2026-08-04 13:19:00+10	3	4	7
50	2026-08-04 13:20:00+10	8	8	16
50	2026-08-04 13:21:00+10	3	7	10
50	2026-08-04 13:22:00+10	11	3	14
50	2026-08-04 13:27:00+10	6	1	7
50	2026-08-04 13:28:00+10	3	2	5
50	2026-08-04 13:29:00+10	4	8	12
50	2026-08-04 13:30:00+10	7	7	14
50	2026-08-04 13:31:00+10	7	3	10
50	2026-08-04 13:33:00+10	2	5	7
50	2026-08-04 13:34:00+10	4	8	12
50	2026-08-04 13:37:00+10	1	6	7
50	2026-08-04 13:39:00+10	2	6	8
50	2026-08-04 13:45:00+10	3	2	5
50	2026-08-04 13:47:00+10	2	1	3
50	2026-08-04 13:48:00+10	2	2	4
50	2026-08-04 13:51:00+10	4	4	8
50	2026-08-04 13:55:00+10	12	3	15
50	2026-08-04 14:06:00+10	6	2	8
50	2026-08-04 14:07:00+10	5	5	10
50	2026-08-04 14:09:00+10	3	4	7
50	2026-08-04 14:11:00+10	2	2	4
50	2026-08-04 14:13:00+10	10	1	11
50	2026-08-04 14:23:00+10	4	1	5
50	2026-08-04 14:25:00+10	5	4	9
50	2026-08-04 14:27:00+10	4	2	6
50	2026-08-04 14:28:00+10	3	0	3
50	2026-08-04 14:30:00+10	3	4	7
50	2026-08-04 14:34:00+10	3	3	6
50	2026-08-04 14:35:00+10	0	5	5
50	2026-08-04 14:36:00+10	5	0	5
50	2026-08-04 14:37:00+10	3	5	8
50	2026-08-04 14:39:00+10	5	3	8
51	2026-08-03 23:55:00+10	0	2	2
51	2026-08-04 00:12:00+10	1	0	1
51	2026-08-04 00:14:00+10	1	0	1
51	2026-08-04 00:15:00+10	0	1	1
51	2026-08-04 01:30:00+10	1	1	2
51	2026-08-04 01:33:00+10	0	2	2
51	2026-08-04 02:08:00+10	1	0	1
51	2026-08-04 02:40:00+10	0	1	1
51	2026-08-04 03:41:00+10	1	0	1
51	2026-08-04 03:50:00+10	1	2	3
51	2026-08-04 04:58:00+10	0	1	1
51	2026-08-04 05:35:00+10	0	1	1
51	2026-08-04 05:47:00+10	0	1	1
51	2026-08-04 05:49:00+10	0	1	1
51	2026-08-04 05:58:00+10	1	0	1
51	2026-08-04 06:07:00+10	4	0	4
51	2026-08-04 06:16:00+10	2	0	2
51	2026-08-04 06:18:00+10	1	0	1
51	2026-08-04 06:23:00+10	1	0	1
51	2026-08-04 06:35:00+10	1	0	1
51	2026-08-04 06:38:00+10	0	1	1
51	2026-08-04 06:51:00+10	1	0	1
51	2026-08-04 06:59:00+10	0	1	1
51	2026-08-04 07:00:00+10	2	0	2
51	2026-08-04 07:01:00+10	1	0	1
51	2026-08-04 07:08:00+10	2	0	2
51	2026-08-04 07:09:00+10	1	3	4
51	2026-08-04 07:14:00+10	2	0	2
51	2026-08-04 07:15:00+10	1	0	1
51	2026-08-04 07:18:00+10	0	2	2
51	2026-08-04 07:27:00+10	0	1	1
51	2026-08-04 07:31:00+10	1	0	1
51	2026-08-04 07:32:00+10	2	0	2
51	2026-08-04 07:39:00+10	0	4	4
51	2026-08-04 07:44:00+10	0	2	2
51	2026-08-04 07:50:00+10	2	0	2
51	2026-08-04 07:58:00+10	1	0	1
51	2026-08-04 07:59:00+10	0	2	2
51	2026-08-04 08:21:00+10	1	0	1
51	2026-08-04 08:22:00+10	0	2	2
51	2026-08-04 08:25:00+10	1	0	1
51	2026-08-04 08:41:00+10	0	1	1
51	2026-08-04 08:43:00+10	0	1	1
51	2026-08-04 08:46:00+10	4	1	5
51	2026-08-04 08:48:00+10	2	0	2
51	2026-08-04 08:51:00+10	1	1	2
51	2026-08-04 09:03:00+10	2	1	3
51	2026-08-04 09:04:00+10	0	2	2
51	2026-08-04 09:05:00+10	1	0	1
51	2026-08-04 09:09:00+10	1	0	1
51	2026-08-04 09:11:00+10	1	0	1
51	2026-08-04 09:23:00+10	0	2	2
51	2026-08-04 09:30:00+10	1	1	2
51	2026-08-04 09:37:00+10	1	0	1
51	2026-08-04 09:42:00+10	0	1	1
51	2026-08-04 09:46:00+10	0	3	3
51	2026-08-04 10:01:00+10	1	3	4
51	2026-08-04 10:02:00+10	1	1	2
51	2026-08-04 10:03:00+10	2	3	5
51	2026-08-04 10:04:00+10	2	1	3
51	2026-08-04 10:07:00+10	1	2	3
51	2026-08-04 10:15:00+10	1	2	3
51	2026-08-04 10:17:00+10	2	1	3
51	2026-08-04 10:23:00+10	1	0	1
51	2026-08-04 10:29:00+10	5	0	5
51	2026-08-04 10:32:00+10	2	0	2
51	2026-08-04 10:36:00+10	0	1	1
51	2026-08-04 10:39:00+10	1	0	1
51	2026-08-04 10:42:00+10	3	2	5
51	2026-08-04 10:54:00+10	1	0	1
51	2026-08-04 10:58:00+10	0	2	2
51	2026-08-04 11:02:00+10	3	1	4
51	2026-08-04 11:17:00+10	0	1	1
51	2026-08-04 11:18:00+10	2	0	2
51	2026-08-04 11:24:00+10	1	0	1
51	2026-08-04 11:26:00+10	1	3	4
51	2026-08-04 11:27:00+10	1	1	2
51	2026-08-04 11:35:00+10	2	0	2
51	2026-08-04 11:38:00+10	3	0	3
51	2026-08-04 11:46:00+10	1	0	1
51	2026-08-04 11:48:00+10	2	0	2
51	2026-08-04 11:53:00+10	3	2	5
51	2026-08-04 11:59:00+10	0	2	2
51	2026-08-04 12:01:00+10	2	0	2
51	2026-08-04 12:02:00+10	0	2	2
51	2026-08-04 12:11:00+10	1	1	2
51	2026-08-04 12:17:00+10	0	2	2
51	2026-08-04 12:22:00+10	1	0	1
51	2026-08-04 12:24:00+10	1	1	2
51	2026-08-04 12:30:00+10	1	1	2
51	2026-08-04 12:34:00+10	0	3	3
51	2026-08-04 12:38:00+10	1	0	1
51	2026-08-04 12:56:00+10	0	1	1
51	2026-08-04 12:57:00+10	2	0	2
51	2026-08-04 13:08:00+10	1	0	1
51	2026-08-04 13:09:00+10	1	1	2
51	2026-08-04 13:10:00+10	0	1	1
51	2026-08-04 13:13:00+10	2	0	2
51	2026-08-04 13:14:00+10	1	0	1
51	2026-08-04 13:16:00+10	0	2	2
51	2026-08-04 13:18:00+10	1	0	1
51	2026-08-04 13:23:00+10	0	1	1
51	2026-08-04 13:28:00+10	0	3	3
51	2026-08-04 13:36:00+10	2	0	2
51	2026-08-04 13:52:00+10	2	3	5
51	2026-08-04 13:53:00+10	2	0	2
51	2026-08-04 14:00:00+10	2	1	3
51	2026-08-04 14:03:00+10	3	1	4
51	2026-08-04 14:05:00+10	1	0	1
51	2026-08-04 14:06:00+10	1	0	1
51	2026-08-04 14:08:00+10	3	0	3
51	2026-08-04 14:12:00+10	1	1	2
51	2026-08-04 14:16:00+10	2	1	3
51	2026-08-04 14:17:00+10	1	2	3
51	2026-08-04 14:21:00+10	2	1	3
51	2026-08-04 14:22:00+10	1	3	4
51	2026-08-04 14:25:00+10	1	0	1
51	2026-08-04 14:26:00+10	3	1	4
51	2026-08-04 14:28:00+10	3	1	4
51	2026-08-04 14:31:00+10	1	0	1
51	2026-08-04 14:34:00+10	2	2	4
51	2026-08-04 14:35:00+10	1	0	1
51	2026-08-04 14:36:00+10	0	1	1
51	2026-08-04 14:37:00+10	1	0	1
51	2026-08-04 14:39:00+10	4	0	4
52	2026-08-04 00:14:00+10	1	0	1
52	2026-08-04 00:15:00+10	1	0	1
52	2026-08-04 00:41:00+10	0	2	2
52	2026-08-04 00:49:00+10	1	0	1
52	2026-08-04 00:56:00+10	1	0	1
52	2026-08-04 01:13:00+10	1	0	1
52	2026-08-04 01:14:00+10	0	2	2
52	2026-08-04 03:35:00+10	1	0	1
52	2026-08-04 06:23:00+10	0	1	1
52	2026-08-04 06:33:00+10	0	1	1
52	2026-08-04 06:56:00+10	1	0	1
52	2026-08-04 07:15:00+10	1	0	1
52	2026-08-04 07:17:00+10	1	0	1
52	2026-08-04 07:21:00+10	1	0	1
52	2026-08-04 07:27:00+10	1	1	2
52	2026-08-04 07:28:00+10	4	3	7
52	2026-08-04 07:29:00+10	3	0	3
52	2026-08-04 07:30:00+10	0	1	1
52	2026-08-04 07:31:00+10	2	0	2
52	2026-08-04 07:37:00+10	1	0	1
52	2026-08-04 07:41:00+10	3	0	3
52	2026-08-04 07:45:00+10	0	1	1
52	2026-08-04 07:47:00+10	4	0	4
52	2026-08-04 07:49:00+10	3	3	6
52	2026-08-04 07:51:00+10	2	2	4
52	2026-08-04 07:53:00+10	3	1	4
52	2026-08-04 07:57:00+10	3	1	4
52	2026-08-04 08:08:00+10	5	1	6
52	2026-08-04 08:09:00+10	1	1	2
52	2026-08-04 08:10:00+10	3	6	9
52	2026-08-04 08:19:00+10	9	4	13
52	2026-08-04 08:23:00+10	5	3	8
52	2026-08-04 08:26:00+10	4	0	4
52	2026-08-04 08:27:00+10	10	1	11
52	2026-08-04 08:32:00+10	9	6	15
52	2026-08-04 08:33:00+10	16	4	20
52	2026-08-04 08:37:00+10	16	1	17
52	2026-08-04 08:38:00+10	10	0	10
52	2026-08-04 08:40:00+10	6	5	11
52	2026-08-04 08:42:00+10	10	1	11
52	2026-08-04 08:50:00+10	10	7	17
52	2026-08-04 08:54:00+10	5	5	10
52	2026-08-04 08:56:00+10	6	1	7
52	2026-08-04 08:59:00+10	7	2	9
52	2026-08-04 09:08:00+10	5	1	6
52	2026-08-04 09:10:00+10	6	3	9
52	2026-08-04 09:16:00+10	6	2	8
52	2026-08-04 09:18:00+10	2	0	2
52	2026-08-04 09:22:00+10	9	5	14
52	2026-08-04 09:28:00+10	7	1	8
52	2026-08-04 09:36:00+10	4	5	9
52	2026-08-04 09:41:00+10	6	0	6
52	2026-08-04 09:44:00+10	1	4	5
52	2026-08-04 09:46:00+10	0	1	1
52	2026-08-04 09:48:00+10	2	4	6
52	2026-08-04 09:51:00+10	2	1	3
52	2026-08-04 09:53:00+10	6	0	6
52	2026-08-04 09:55:00+10	6	4	10
52	2026-08-04 09:59:00+10	1	0	1
52	2026-08-04 10:10:00+10	7	2	9
52	2026-08-04 10:11:00+10	5	2	7
52	2026-08-04 10:14:00+10	3	5	8
52	2026-08-04 10:17:00+10	3	3	6
52	2026-08-04 10:18:00+10	1	0	1
52	2026-08-04 10:19:00+10	6	6	12
52	2026-08-04 10:20:00+10	0	4	4
52	2026-08-04 10:21:00+10	1	0	1
52	2026-08-04 10:22:00+10	5	1	6
52	2026-08-04 10:23:00+10	5	5	10
52	2026-08-04 10:24:00+10	1	3	4
52	2026-08-04 10:26:00+10	2	2	4
52	2026-08-04 10:36:00+10	1	1	2
52	2026-08-04 10:40:00+10	6	3	9
52	2026-08-04 10:46:00+10	7	2	9
52	2026-08-04 10:48:00+10	2	10	12
52	2026-08-04 10:51:00+10	4	8	12
52	2026-08-04 10:52:00+10	10	8	18
52	2026-08-04 10:55:00+10	4	3	7
52	2026-08-04 10:57:00+10	4	3	7
52	2026-08-04 11:07:00+10	2	3	5
52	2026-08-04 11:08:00+10	5	10	15
52	2026-08-04 11:12:00+10	3	10	13
52	2026-08-04 11:16:00+10	3	9	12
52	2026-08-04 11:17:00+10	1	4	5
52	2026-08-04 11:24:00+10	6	1	7
52	2026-08-04 11:29:00+10	0	2	2
52	2026-08-04 11:31:00+10	8	0	8
52	2026-08-04 11:33:00+10	0	5	5
52	2026-08-04 11:34:00+10	7	8	15
52	2026-08-04 11:35:00+10	2	0	2
52	2026-08-04 11:39:00+10	2	0	2
52	2026-08-04 11:48:00+10	3	12	15
52	2026-08-04 11:50:00+10	0	4	4
52	2026-08-04 11:56:00+10	10	1	11
52	2026-08-04 11:57:00+10	0	6	6
52	2026-08-04 12:13:00+10	2	6	8
52	2026-08-04 12:15:00+10	3	13	16
52	2026-08-04 12:16:00+10	6	2	8
52	2026-08-04 12:22:00+10	8	8	16
52	2026-08-04 12:23:00+10	4	2	6
52	2026-08-04 12:25:00+10	14	14	28
52	2026-08-04 12:26:00+10	11	6	17
52	2026-08-04 12:34:00+10	22	8	30
52	2026-08-04 12:37:00+10	10	11	21
52	2026-08-04 12:39:00+10	3	9	12
52	2026-08-04 12:41:00+10	3	7	10
52	2026-08-04 12:46:00+10	15	9	24
52	2026-08-04 12:49:00+10	15	12	27
52	2026-08-04 12:52:00+10	7	19	26
52	2026-08-04 12:56:00+10	12	8	20
52	2026-08-04 12:58:00+10	9	3	12
52	2026-08-04 13:05:00+10	12	1	13
52	2026-08-04 13:08:00+10	4	19	23
52	2026-08-04 13:11:00+10	13	10	23
52	2026-08-04 13:21:00+10	5	17	22
52	2026-08-04 13:22:00+10	11	10	21
52	2026-08-04 13:23:00+10	8	4	12
52	2026-08-04 13:34:00+10	8	10	18
52	2026-08-04 13:44:00+10	9	6	15
52	2026-08-04 13:49:00+10	5	16	21
52	2026-08-04 13:55:00+10	15	13	28
52	2026-08-04 14:09:00+10	0	11	11
52	2026-08-04 14:11:00+10	3	6	9
52	2026-08-04 14:13:00+10	5	16	21
52	2026-08-04 14:14:00+10	10	12	22
52	2026-08-04 14:18:00+10	6	6	12
52	2026-08-04 14:19:00+10	17	0	17
52	2026-08-04 14:31:00+10	2	4	6
52	2026-08-04 14:33:00+10	3	6	9
52	2026-08-04 14:34:00+10	1	11	12
52	2026-08-04 14:36:00+10	5	12	17
52	2026-08-04 14:37:00+10	11	5	16
52	2026-08-04 14:39:00+10	2	13	15
53	2026-08-03 23:59:00+10	1	0	1
53	2026-08-04 00:06:00+10	0	1	1
53	2026-08-04 00:11:00+10	0	1	1
53	2026-08-04 00:12:00+10	1	0	1
53	2026-08-04 00:16:00+10	3	0	3
53	2026-08-04 00:38:00+10	1	0	1
53	2026-08-04 01:03:00+10	0	3	3
53	2026-08-04 01:07:00+10	2	0	2
53	2026-08-04 01:59:00+10	1	0	1
53	2026-08-04 02:26:00+10	1	0	1
53	2026-08-04 02:28:00+10	0	3	3
53	2026-08-04 02:44:00+10	1	0	1
53	2026-08-04 03:56:00+10	1	0	1
53	2026-08-04 04:08:00+10	0	1	1
53	2026-08-04 04:21:00+10	1	0	1
53	2026-08-04 04:44:00+10	1	0	1
53	2026-08-04 05:21:00+10	1	0	1
53	2026-08-04 05:36:00+10	0	1	1
53	2026-08-04 05:38:00+10	1	0	1
53	2026-08-04 05:42:00+10	0	1	1
53	2026-08-04 05:44:00+10	0	2	2
53	2026-08-04 05:46:00+10	2	4	6
53	2026-08-04 05:47:00+10	0	1	1
53	2026-08-04 05:52:00+10	0	1	1
53	2026-08-04 05:57:00+10	0	1	1
53	2026-08-04 06:03:00+10	1	2	3
53	2026-08-04 06:10:00+10	1	0	1
53	2026-08-04 06:12:00+10	4	0	4
53	2026-08-04 06:41:00+10	2	0	2
53	2026-08-04 06:42:00+10	1	0	1
53	2026-08-04 06:46:00+10	0	5	5
53	2026-08-04 06:48:00+10	1	1	2
53	2026-08-04 06:50:00+10	0	7	7
53	2026-08-04 06:53:00+10	0	1	1
53	2026-08-04 06:56:00+10	0	1	1
53	2026-08-04 06:57:00+10	2	0	2
53	2026-08-04 06:58:00+10	1	1	2
53	2026-08-04 07:00:00+10	2	1	3
53	2026-08-04 07:01:00+10	2	5	7
53	2026-08-04 07:04:00+10	1	1	2
53	2026-08-04 07:06:00+10	1	2	3
53	2026-08-04 07:10:00+10	1	4	5
53	2026-08-04 07:12:00+10	0	2	2
53	2026-08-04 07:13:00+10	1	5	6
53	2026-08-04 07:14:00+10	2	2	4
53	2026-08-04 07:25:00+10	1	2	3
53	2026-08-04 07:29:00+10	2	1	3
53	2026-08-04 07:33:00+10	0	3	3
53	2026-08-04 07:37:00+10	2	4	6
53	2026-08-04 07:39:00+10	3	9	12
53	2026-08-04 07:40:00+10	2	2	4
53	2026-08-04 07:46:00+10	5	9	14
53	2026-08-04 07:47:00+10	4	5	9
53	2026-08-04 07:48:00+10	1	4	5
53	2026-08-04 07:56:00+10	1	4	5
53	2026-08-04 07:58:00+10	3	10	13
53	2026-08-04 08:02:00+10	3	7	10
53	2026-08-04 08:03:00+10	5	6	11
53	2026-08-04 08:04:00+10	1	7	8
53	2026-08-04 08:16:00+10	9	10	19
53	2026-08-04 08:25:00+10	22	17	39
53	2026-08-04 08:27:00+10	9	23	32
53	2026-08-04 08:28:00+10	1	15	16
53	2026-08-04 08:29:00+10	2	15	17
53	2026-08-04 08:31:00+10	6	15	21
53	2026-08-04 08:34:00+10	15	17	32
53	2026-08-04 08:36:00+10	7	7	14
53	2026-08-04 08:45:00+10	2	16	18
53	2026-08-04 08:46:00+10	8	16	24
53	2026-08-04 08:49:00+10	5	11	16
53	2026-08-04 08:55:00+10	5	4	9
53	2026-08-04 08:56:00+10	1	20	21
53	2026-08-04 09:01:00+10	4	17	21
53	2026-08-04 09:04:00+10	4	9	13
53	2026-08-04 09:09:00+10	1	11	12
53	2026-08-04 09:11:00+10	2	8	10
53	2026-08-04 09:12:00+10	7	5	12
53	2026-08-04 09:13:00+10	10	15	25
53	2026-08-04 09:15:00+10	1	5	6
53	2026-08-04 09:20:00+10	3	9	12
53	2026-08-04 09:21:00+10	4	5	9
53	2026-08-04 09:24:00+10	7	6	13
53	2026-08-04 09:28:00+10	7	11	18
53	2026-08-04 09:30:00+10	8	7	15
53	2026-08-04 09:31:00+10	6	4	10
53	2026-08-04 09:36:00+10	2	6	8
53	2026-08-04 09:41:00+10	8	5	13
53	2026-08-04 09:42:00+10	6	9	15
53	2026-08-04 09:43:00+10	3	4	7
53	2026-08-04 09:48:00+10	8	14	22
53	2026-08-04 09:51:00+10	8	3	11
53	2026-08-04 09:52:00+10	4	2	6
53	2026-08-04 09:54:00+10	6	6	12
53	2026-08-04 09:58:00+10	6	4	10
53	2026-08-04 10:00:00+10	4	9	13
53	2026-08-04 10:01:00+10	6	5	11
53	2026-08-04 10:11:00+10	35	5	40
53	2026-08-04 10:12:00+10	11	2	13
53	2026-08-04 10:18:00+10	4	7	11
53	2026-08-04 10:20:00+10	5	6	11
53	2026-08-04 10:22:00+10	11	10	21
53	2026-08-04 10:24:00+10	8	12	20
53	2026-08-04 10:26:00+10	4	7	11
53	2026-08-04 10:28:00+10	5	12	17
53	2026-08-04 10:29:00+10	3	6	9
53	2026-08-04 10:30:00+10	9	1	10
53	2026-08-04 10:33:00+10	9	3	12
53	2026-08-04 10:34:00+10	3	7	10
53	2026-08-04 10:36:00+10	4	1	5
53	2026-08-04 10:37:00+10	4	6	10
53	2026-08-04 10:41:00+10	14	3	17
53	2026-08-04 10:43:00+10	10	5	15
53	2026-08-04 10:46:00+10	16	5	21
53	2026-08-04 10:51:00+10	12	9	21
53	2026-08-04 10:53:00+10	5	7	12
53	2026-08-04 10:54:00+10	8	7	15
53	2026-08-04 11:04:00+10	11	7	18
53	2026-08-04 11:06:00+10	3	6	9
53	2026-08-04 11:07:00+10	14	13	27
53	2026-08-04 11:11:00+10	11	3	14
53	2026-08-04 11:13:00+10	8	6	14
53	2026-08-04 11:14:00+10	18	3	21
53	2026-08-04 11:17:00+10	11	7	18
53	2026-08-04 11:22:00+10	15	3	18
53	2026-08-04 11:24:00+10	9	6	15
53	2026-08-04 11:25:00+10	19	8	27
53	2026-08-04 11:27:00+10	7	8	15
53	2026-08-04 11:31:00+10	3	4	7
53	2026-08-04 11:37:00+10	4	7	11
53	2026-08-04 11:39:00+10	9	6	15
53	2026-08-04 11:40:00+10	9	6	15
53	2026-08-04 11:41:00+10	10	16	26
53	2026-08-04 11:49:00+10	4	5	9
53	2026-08-04 11:50:00+10	12	7	19
53	2026-08-04 11:51:00+10	8	8	16
53	2026-08-04 11:52:00+10	3	6	9
53	2026-08-04 11:57:00+10	6	4	10
53	2026-08-04 12:00:00+10	8	12	20
53	2026-08-04 12:06:00+10	14	4	18
53	2026-08-04 12:07:00+10	7	7	14
53	2026-08-04 12:08:00+10	16	14	30
53	2026-08-04 12:13:00+10	7	9	16
53	2026-08-04 12:19:00+10	13	8	21
53	2026-08-04 12:20:00+10	11	1	12
53	2026-08-04 12:25:00+10	19	10	29
53	2026-08-04 12:29:00+10	9	16	25
53	2026-08-04 12:33:00+10	11	3	14
53	2026-08-04 12:36:00+10	7	15	22
53	2026-08-04 12:40:00+10	20	9	29
53	2026-08-04 12:42:00+10	11	11	22
53	2026-08-04 12:45:00+10	12	7	19
53	2026-08-04 12:51:00+10	11	14	25
53	2026-08-04 12:54:00+10	19	17	36
53	2026-08-04 13:01:00+10	10	10	20
53	2026-08-04 13:02:00+10	18	17	35
53	2026-08-04 13:03:00+10	15	14	29
53	2026-08-04 13:04:00+10	10	11	21
53	2026-08-04 13:08:00+10	5	14	19
53	2026-08-04 13:18:00+10	28	13	41
53	2026-08-04 13:21:00+10	18	18	36
53	2026-08-04 13:27:00+10	10	11	21
53	2026-08-04 13:30:00+10	16	7	23
53	2026-08-04 13:37:00+10	10	9	19
53	2026-08-04 13:43:00+10	12	7	19
53	2026-08-04 13:44:00+10	8	15	23
53	2026-08-04 13:45:00+10	20	7	27
53	2026-08-04 13:46:00+10	6	17	23
53	2026-08-04 13:52:00+10	12	14	26
53	2026-08-04 13:54:00+10	10	13	23
53	2026-08-04 13:56:00+10	15	10	25
53	2026-08-04 13:58:00+10	12	8	20
53	2026-08-04 14:04:00+10	9	8	17
53	2026-08-04 14:13:00+10	6	15	21
53	2026-08-04 14:17:00+10	9	16	25
53	2026-08-04 14:22:00+10	4	3	7
53	2026-08-04 14:24:00+10	10	7	17
53	2026-08-04 14:28:00+10	9	3	12
53	2026-08-04 14:30:00+10	7	14	21
53	2026-08-04 14:31:00+10	15	12	27
53	2026-08-04 14:36:00+10	14	3	17
53	2026-08-04 14:38:00+10	12	8	20
53	2026-08-04 14:39:00+10	9	4	13
54	2026-08-03 23:55:00+10	6	2	8
54	2026-08-04 00:05:00+10	0	3	3
54	2026-08-04 00:15:00+10	6	1	7
54	2026-08-04 00:20:00+10	1	1	2
54	2026-08-04 00:30:00+10	1	1	2
54	2026-08-04 00:35:00+10	0	1	1
54	2026-08-04 00:45:00+10	1	0	1
54	2026-08-04 00:50:00+10	2	1	3
54	2026-08-04 01:10:00+10	6	0	6
54	2026-08-04 01:25:00+10	6	0	6
54	2026-08-04 01:45:00+10	1	0	1
54	2026-08-04 01:50:00+10	12	0	12
54	2026-08-04 03:25:00+10	2	0	2
54	2026-08-04 03:30:00+10	0	1	1
54	2026-08-04 04:10:00+10	2	0	2
54	2026-08-04 04:20:00+10	0	1	1
54	2026-08-04 05:15:00+10	1	0	1
54	2026-08-04 05:40:00+10	2	0	2
54	2026-08-04 06:20:00+10	1	0	1
54	2026-08-04 06:45:00+10	1	1	2
54	2026-08-04 06:55:00+10	0	1	1
54	2026-08-04 07:00:00+10	1	0	1
54	2026-08-04 07:15:00+10	1	1	2
54	2026-08-04 07:40:00+10	2	3	5
54	2026-08-04 08:10:00+10	9	4	13
54	2026-08-04 08:15:00+10	7	3	10
54	2026-08-04 08:45:00+10	33	3	36
54	2026-08-04 08:55:00+10	34	4	38
54	2026-08-04 09:00:00+10	31	4	35
54	2026-08-04 09:05:00+10	16	3	19
54	2026-08-04 09:15:00+10	5	3	8
54	2026-08-04 09:40:00+10	27	6	33
54	2026-08-04 09:45:00+10	31	4	35
54	2026-08-04 09:55:00+10	17	4	21
54	2026-08-04 10:10:00+10	11	14	25
54	2026-08-04 10:15:00+10	4	10	14
54	2026-08-04 10:25:00+10	6	7	13
54	2026-08-04 10:30:00+10	6	4	10
54	2026-08-04 10:40:00+10	19	2	21
54	2026-08-04 10:45:00+10	14	6	20
54	2026-08-04 10:50:00+10	22	9	31
54	2026-08-04 10:55:00+10	13	9	22
54	2026-08-04 11:00:00+10	10	15	25
54	2026-08-04 11:15:00+10	10	16	26
54	2026-08-04 11:25:00+10	12	9	21
54	2026-08-04 11:50:00+10	4	6	10
54	2026-08-04 12:00:00+10	6	7	13
54	2026-08-04 12:05:00+10	11	16	27
54	2026-08-04 12:10:00+10	7	11	18
54	2026-08-04 12:20:00+10	17	21	38
54	2026-08-04 12:25:00+10	15	14	29
54	2026-08-04 13:15:00+10	19	15	34
54	2026-08-04 13:25:00+10	13	17	30
54	2026-08-04 13:40:00+10	37	16	53
54	2026-08-04 14:05:00+10	13	32	45
54	2026-08-04 14:15:00+10	12	23	35
54	2026-08-04 14:25:00+10	10	16	26
56	2026-08-03 23:55:00+10	1	0	1
56	2026-08-03 23:58:00+10	0	1	1
56	2026-08-04 00:07:00+10	0	1	1
56	2026-08-04 00:11:00+10	1	1	2
56	2026-08-04 00:21:00+10	3	0	3
56	2026-08-04 00:24:00+10	1	0	1
56	2026-08-04 00:35:00+10	3	0	3
56	2026-08-04 00:42:00+10	0	1	1
56	2026-08-04 00:45:00+10	0	1	1
56	2026-08-04 00:47:00+10	2	4	6
56	2026-08-04 01:09:00+10	2	0	2
56	2026-08-04 01:10:00+10	7	0	7
56	2026-08-04 01:13:00+10	0	1	1
56	2026-08-04 01:25:00+10	2	0	2
56	2026-08-04 01:44:00+10	1	0	1
56	2026-08-04 02:12:00+10	0	2	2
56	2026-08-04 02:41:00+10	1	0	1
56	2026-08-04 02:47:00+10	0	2	2
56	2026-08-04 05:38:00+10	1	1	2
56	2026-08-04 05:44:00+10	1	0	1
56	2026-08-04 05:52:00+10	1	1	2
56	2026-08-04 05:53:00+10	0	1	1
56	2026-08-04 06:05:00+10	1	0	1
56	2026-08-04 06:13:00+10	1	0	1
56	2026-08-04 06:27:00+10	2	0	2
56	2026-08-04 06:34:00+10	1	1	2
56	2026-08-04 06:36:00+10	1	0	1
56	2026-08-04 06:43:00+10	0	1	1
56	2026-08-04 06:50:00+10	0	1	1
56	2026-08-04 07:06:00+10	2	0	2
56	2026-08-04 07:13:00+10	1	1	2
56	2026-08-04 07:15:00+10	1	1	2
56	2026-08-04 07:19:00+10	2	0	2
56	2026-08-04 07:21:00+10	1	0	1
56	2026-08-04 07:23:00+10	2	2	4
56	2026-08-04 07:28:00+10	2	0	2
56	2026-08-04 07:30:00+10	4	0	4
56	2026-08-04 07:40:00+10	1	0	1
56	2026-08-04 07:41:00+10	1	1	2
56	2026-08-04 07:43:00+10	1	4	5
56	2026-08-04 07:45:00+10	1	0	1
56	2026-08-04 07:47:00+10	0	1	1
56	2026-08-04 07:56:00+10	3	1	4
56	2026-08-04 07:58:00+10	1	1	2
56	2026-08-04 08:06:00+10	3	0	3
56	2026-08-04 08:12:00+10	2	2	4
56	2026-08-04 08:15:00+10	2	1	3
56	2026-08-04 08:19:00+10	1	4	5
56	2026-08-04 08:20:00+10	1	3	4
56	2026-08-04 08:21:00+10	5	0	5
56	2026-08-04 08:22:00+10	3	2	5
56	2026-08-04 08:26:00+10	3	2	5
56	2026-08-04 08:31:00+10	3	6	9
56	2026-08-04 08:36:00+10	4	4	8
56	2026-08-04 08:37:00+10	4	1	5
56	2026-08-04 08:40:00+10	4	8	12
56	2026-08-04 08:44:00+10	7	8	15
56	2026-08-04 08:49:00+10	4	4	8
56	2026-08-04 08:50:00+10	2	6	8
56	2026-08-04 08:52:00+10	0	7	7
56	2026-08-04 09:07:00+10	1	1	2
56	2026-08-04 09:11:00+10	1	2	3
56	2026-08-04 09:13:00+10	0	7	7
56	2026-08-04 09:27:00+10	1	7	8
56	2026-08-04 09:28:00+10	4	1	5
56	2026-08-04 09:30:00+10	2	3	5
56	2026-08-04 09:37:00+10	3	2	5
56	2026-08-04 09:38:00+10	1	4	5
56	2026-08-04 09:40:00+10	4	3	7
56	2026-08-04 09:43:00+10	0	1	1
56	2026-08-04 09:53:00+10	6	4	10
56	2026-08-04 09:56:00+10	4	4	8
56	2026-08-04 09:58:00+10	4	4	8
56	2026-08-04 09:59:00+10	1	7	8
56	2026-08-04 10:08:00+10	6	1	7
56	2026-08-04 10:10:00+10	6	5	11
56	2026-08-04 10:12:00+10	9	0	9
56	2026-08-04 10:17:00+10	2	2	4
56	2026-08-04 10:20:00+10	0	7	7
56	2026-08-04 10:22:00+10	2	2	4
56	2026-08-04 10:35:00+10	4	1	5
56	2026-08-04 10:36:00+10	0	1	1
56	2026-08-04 10:40:00+10	1	2	3
56	2026-08-04 10:45:00+10	3	1	4
56	2026-08-04 10:47:00+10	7	5	12
56	2026-08-04 10:48:00+10	3	3	6
56	2026-08-04 10:49:00+10	5	0	5
56	2026-08-04 10:54:00+10	2	3	5
56	2026-08-04 10:56:00+10	1	1	2
56	2026-08-04 10:57:00+10	7	3	10
56	2026-08-04 10:58:00+10	4	5	9
56	2026-08-04 10:59:00+10	2	2	4
56	2026-08-04 11:12:00+10	3	2	5
56	2026-08-04 11:16:00+10	15	1	16
56	2026-08-04 11:18:00+10	3	5	8
56	2026-08-04 11:19:00+10	4	3	7
56	2026-08-04 11:20:00+10	1	2	3
56	2026-08-04 11:24:00+10	3	6	9
56	2026-08-04 11:25:00+10	7	0	7
56	2026-08-04 11:26:00+10	1	5	6
56	2026-08-04 11:29:00+10	8	1	9
56	2026-08-04 11:30:00+10	11	0	11
56	2026-08-04 11:37:00+10	2	0	2
56	2026-08-04 11:38:00+10	3	3	6
56	2026-08-04 11:43:00+10	6	4	10
56	2026-08-04 11:44:00+10	5	2	7
56	2026-08-04 11:50:00+10	3	1	4
56	2026-08-04 11:51:00+10	1	1	2
56	2026-08-04 11:54:00+10	1	2	3
56	2026-08-04 11:55:00+10	1	1	2
56	2026-08-04 11:59:00+10	1	0	1
56	2026-08-04 12:05:00+10	4	5	9
56	2026-08-04 12:11:00+10	8	2	10
56	2026-08-04 12:13:00+10	4	6	10
56	2026-08-04 12:17:00+10	8	2	10
56	2026-08-04 12:18:00+10	14	3	17
56	2026-08-04 12:19:00+10	10	4	14
56	2026-08-04 12:20:00+10	7	9	16
56	2026-08-04 12:21:00+10	9	7	16
56	2026-08-04 12:31:00+10	4	10	14
56	2026-08-04 12:38:00+10	12	4	16
56	2026-08-04 12:42:00+10	5	4	9
56	2026-08-04 12:52:00+10	7	7	14
56	2026-08-04 12:54:00+10	3	3	6
56	2026-08-04 12:56:00+10	4	6	10
56	2026-08-04 12:58:00+10	10	3	13
56	2026-08-04 13:06:00+10	9	2	11
56	2026-08-04 13:08:00+10	10	3	13
56	2026-08-04 13:13:00+10	13	1	14
56	2026-08-04 13:19:00+10	4	3	7
56	2026-08-04 13:25:00+10	2	0	2
56	2026-08-04 13:26:00+10	13	1	14
56	2026-08-04 13:27:00+10	3	8	11
56	2026-08-04 13:29:00+10	3	6	9
56	2026-08-04 13:32:00+10	3	4	7
56	2026-08-04 13:34:00+10	11	6	17
56	2026-08-04 13:36:00+10	6	11	17
56	2026-08-04 13:37:00+10	6	9	15
56	2026-08-04 13:43:00+10	7	5	12
56	2026-08-04 13:44:00+10	5	5	10
56	2026-08-04 13:49:00+10	5	4	9
56	2026-08-04 13:51:00+10	9	3	12
56	2026-08-04 13:55:00+10	6	3	9
56	2026-08-04 13:58:00+10	3	3	6
56	2026-08-04 14:06:00+10	8	7	15
56	2026-08-04 14:11:00+10	3	8	11
56	2026-08-04 14:12:00+10	2	13	15
56	2026-08-04 14:13:00+10	7	5	12
56	2026-08-04 14:14:00+10	6	4	10
56	2026-08-04 14:17:00+10	11	7	18
56	2026-08-04 14:18:00+10	3	8	11
56	2026-08-04 14:20:00+10	3	4	7
56	2026-08-04 14:21:00+10	7	2	9
56	2026-08-04 14:24:00+10	5	3	8
56	2026-08-04 14:28:00+10	21	7	28
56	2026-08-04 14:30:00+10	4	8	12
56	2026-08-04 14:34:00+10	10	6	16
56	2026-08-04 14:35:00+10	6	0	6
56	2026-08-04 14:36:00+10	6	2	8
56	2026-08-04 14:38:00+10	3	3	6
58	2026-08-04 00:00:00+10	8	1	9
58	2026-08-04 00:10:00+10	3	0	3
58	2026-08-04 00:15:00+10	10	8	18
58	2026-08-04 00:20:00+10	3	1	4
58	2026-08-04 00:30:00+10	0	7	7
58	2026-08-04 01:15:00+10	6	2	8
58	2026-08-04 01:35:00+10	1	3	4
58	2026-08-04 01:50:00+10	2	3	5
58	2026-08-04 02:05:00+10	1	1	2
58	2026-08-04 02:20:00+10	1	2	3
58	2026-08-04 02:45:00+10	2	1	3
58	2026-08-04 02:50:00+10	0	1	1
58	2026-08-04 03:05:00+10	0	1	1
58	2026-08-04 03:10:00+10	0	3	3
58	2026-08-04 03:25:00+10	0	1	1
58	2026-08-04 03:40:00+10	0	1	1
58	2026-08-04 04:05:00+10	0	1	1
58	2026-08-04 04:35:00+10	2	0	2
58	2026-08-04 04:45:00+10	1	0	1
58	2026-08-04 05:10:00+10	0	9	9
58	2026-08-04 05:15:00+10	0	3	3
58	2026-08-04 05:20:00+10	7	1	8
58	2026-08-04 05:25:00+10	3	0	3
58	2026-08-04 05:45:00+10	7	1	8
58	2026-08-04 06:05:00+10	10	2	12
58	2026-08-04 06:15:00+10	11	6	17
58	2026-08-04 06:20:00+10	11	0	11
58	2026-08-04 06:25:00+10	9	4	13
58	2026-08-04 06:30:00+10	39	2	41
58	2026-08-04 06:35:00+10	17	4	21
58	2026-08-04 06:40:00+10	11	3	14
58	2026-08-04 06:50:00+10	7	9	16
58	2026-08-04 06:55:00+10	49	2	51
58	2026-08-04 07:00:00+10	39	7	46
58	2026-08-04 07:05:00+10	19	5	24
58	2026-08-04 07:15:00+10	46	6	52
58	2026-08-04 07:20:00+10	2	1	3
58	2026-08-04 07:30:00+10	80	8	88
58	2026-08-04 07:35:00+10	87	17	104
58	2026-08-04 08:05:00+10	93	11	104
58	2026-08-04 08:15:00+10	83	20	103
58	2026-08-04 08:35:00+10	178	14	192
58	2026-08-04 08:50:00+10	195	26	221
58	2026-08-04 09:10:00+10	113	11	124
58	2026-08-04 09:15:00+10	146	5	151
58	2026-08-04 09:25:00+10	59	13	72
58	2026-08-04 09:30:00+10	75	14	89
58	2026-08-04 09:35:00+10	45	17	62
58	2026-08-04 10:00:00+10	67	13	80
58	2026-08-04 10:05:00+10	59	11	70
58	2026-08-04 10:15:00+10	80	12	92
58	2026-08-04 10:35:00+10	39	9	48
58	2026-08-04 11:00:00+10	44	11	55
58	2026-08-04 11:05:00+10	66	10	76
58	2026-08-04 11:10:00+10	44	17	61
58	2026-08-04 11:15:00+10	55	16	71
58	2026-08-04 11:25:00+10	47	15	62
58	2026-08-04 11:50:00+10	27	12	39
58	2026-08-04 12:40:00+10	66	21	87
58	2026-08-04 12:45:00+10	70	32	102
58	2026-08-04 13:10:00+10	60	39	99
58	2026-08-04 13:35:00+10	55	29	84
58	2026-08-04 13:55:00+10	44	38	82
58	2026-08-04 14:00:00+10	32	45	77
58	2026-08-04 14:10:00+10	46	34	80
58	2026-08-04 14:25:00+10	39	29	68
59	2026-08-03 23:55:00+10	8	0	8
59	2026-08-04 00:05:00+10	2	4	6
59	2026-08-04 00:15:00+10	12	1	13
59	2026-08-04 00:50:00+10	5	3	8
59	2026-08-04 01:00:00+10	4	0	4
59	2026-08-04 01:10:00+10	2	5	7
59	2026-08-04 01:30:00+10	2	1	3
59	2026-08-04 01:35:00+10	2	0	2
59	2026-08-04 01:45:00+10	1	0	1
59	2026-08-04 01:55:00+10	6	0	6
59	2026-08-04 02:10:00+10	1	1	2
59	2026-08-04 02:15:00+10	4	3	7
59	2026-08-04 02:25:00+10	1	3	4
59	2026-08-04 02:35:00+10	1	2	3
59	2026-08-04 02:40:00+10	0	2	2
59	2026-08-04 03:25:00+10	0	1	1
59	2026-08-04 03:35:00+10	1	2	3
59	2026-08-04 03:40:00+10	2	1	3
59	2026-08-04 04:00:00+10	0	1	1
59	2026-08-04 04:15:00+10	1	0	1
59	2026-08-04 04:40:00+10	1	0	1
59	2026-08-04 05:25:00+10	0	1	1
59	2026-08-04 06:35:00+10	4	2	6
59	2026-08-04 06:40:00+10	6	1	7
59	2026-08-04 06:45:00+10	6	8	14
59	2026-08-04 07:00:00+10	2	4	6
59	2026-08-04 07:30:00+10	14	11	25
59	2026-08-04 07:35:00+10	22	14	36
59	2026-08-04 07:50:00+10	59	7	66
59	2026-08-04 08:10:00+10	131	20	151
59	2026-08-04 08:45:00+10	149	20	169
59	2026-08-04 08:55:00+10	146	22	168
59	2026-08-04 09:05:00+10	129	17	146
59	2026-08-04 09:20:00+10	131	25	156
59	2026-08-04 09:25:00+10	133	52	185
59	2026-08-04 09:35:00+10	74	29	103
59	2026-08-04 09:45:00+10	134	34	168
59	2026-08-04 09:50:00+10	86	34	120
59	2026-08-04 09:55:00+10	81	64	145
59	2026-08-04 10:05:00+10	113	86	199
59	2026-08-04 10:20:00+10	184	140	324
59	2026-08-04 10:45:00+10	125	70	195
59	2026-08-04 11:00:00+10	102	57	159
59	2026-08-04 11:10:00+10	82	61	143
59	2026-08-04 11:20:00+10	113	69	182
59	2026-08-04 11:45:00+10	72	69	141
59	2026-08-04 12:05:00+10	98	191	289
59	2026-08-04 12:10:00+10	139	160	299
59	2026-08-04 12:30:00+10	198	235	433
59	2026-08-04 12:35:00+10	136	125	261
59	2026-08-04 12:40:00+10	153	125	278
59	2026-08-04 13:00:00+10	152	91	243
59	2026-08-04 13:50:00+10	126	102	228
59	2026-08-04 14:05:00+10	103	178	281
59	2026-08-04 14:25:00+10	199	330	529
59	2026-08-04 14:30:00+10	190	180	370
61	2026-08-03 23:59:00+10	0	2	2
61	2026-08-04 00:01:00+10	0	2	2
61	2026-08-04 00:05:00+10	2	1	3
61	2026-08-04 00:16:00+10	1	0	1
61	2026-08-04 00:21:00+10	0	1	1
61	2026-08-04 00:35:00+10	1	0	1
61	2026-08-04 01:21:00+10	0	2	2
61	2026-08-04 01:23:00+10	0	6	6
61	2026-08-04 01:24:00+10	1	0	1
61	2026-08-04 01:25:00+10	2	0	2
61	2026-08-04 01:28:00+10	1	0	1
61	2026-08-04 02:03:00+10	0	1	1
61	2026-08-04 02:07:00+10	1	1	2
61	2026-08-04 02:17:00+10	0	1	1
61	2026-08-04 02:24:00+10	0	1	1
61	2026-08-04 02:25:00+10	1	0	1
61	2026-08-04 02:45:00+10	4	0	4
61	2026-08-04 03:24:00+10	1	0	1
61	2026-08-04 03:39:00+10	1	0	1
61	2026-08-04 03:51:00+10	1	0	1
61	2026-08-04 04:08:00+10	1	0	1
61	2026-08-04 04:29:00+10	0	1	1
61	2026-08-04 05:27:00+10	0	1	1
61	2026-08-04 05:32:00+10	0	1	1
61	2026-08-04 05:39:00+10	0	1	1
61	2026-08-04 05:52:00+10	0	1	1
61	2026-08-04 05:57:00+10	0	1	1
61	2026-08-04 06:01:00+10	1	0	1
61	2026-08-04 06:16:00+10	0	1	1
61	2026-08-04 06:21:00+10	0	1	1
61	2026-08-04 06:25:00+10	0	1	1
61	2026-08-04 06:38:00+10	1	0	1
61	2026-08-04 06:40:00+10	0	3	3
61	2026-08-04 06:45:00+10	0	1	1
61	2026-08-04 06:54:00+10	2	1	3
61	2026-08-04 06:55:00+10	1	0	1
61	2026-08-04 07:04:00+10	1	0	1
61	2026-08-04 07:13:00+10	0	2	2
61	2026-08-04 07:15:00+10	8	3	11
61	2026-08-04 07:20:00+10	1	3	4
61	2026-08-04 07:21:00+10	2	0	2
61	2026-08-04 07:25:00+10	3	1	4
61	2026-08-04 07:30:00+10	1	0	1
61	2026-08-04 07:36:00+10	2	1	3
61	2026-08-04 07:37:00+10	1	5	6
61	2026-08-04 07:41:00+10	2	2	4
61	2026-08-04 07:42:00+10	2	4	6
61	2026-08-04 07:44:00+10	3	2	5
61	2026-08-04 07:45:00+10	2	1	3
61	2026-08-04 07:49:00+10	2	4	6
61	2026-08-04 07:51:00+10	5	3	8
61	2026-08-04 07:53:00+10	5	1	6
61	2026-08-04 07:54:00+10	1	4	5
61	2026-08-04 07:58:00+10	3	5	8
61	2026-08-04 07:59:00+10	5	6	11
61	2026-08-04 08:06:00+10	9	14	23
61	2026-08-04 08:13:00+10	13	19	32
61	2026-08-04 08:22:00+10	5	15	20
61	2026-08-04 08:25:00+10	4	23	27
61	2026-08-04 08:27:00+10	4	20	24
61	2026-08-04 08:29:00+10	9	10	19
61	2026-08-04 08:37:00+10	9	4	13
61	2026-08-04 08:38:00+10	8	8	16
61	2026-08-04 08:50:00+10	3	8	11
61	2026-08-04 08:52:00+10	8	7	15
61	2026-08-04 08:58:00+10	7	4	11
61	2026-08-04 08:59:00+10	2	8	10
61	2026-08-04 09:02:00+10	5	5	10
61	2026-08-04 09:03:00+10	4	6	10
61	2026-08-04 09:05:00+10	2	9	11
61	2026-08-04 09:07:00+10	5	3	8
61	2026-08-04 09:12:00+10	9	7	16
61	2026-08-04 09:16:00+10	4	5	9
61	2026-08-04 09:25:00+10	7	14	21
61	2026-08-04 09:26:00+10	8	11	19
61	2026-08-04 09:31:00+10	6	2	8
61	2026-08-04 09:32:00+10	7	7	14
61	2026-08-04 09:35:00+10	7	9	16
61	2026-08-04 09:41:00+10	2	7	9
61	2026-08-04 09:43:00+10	1	11	12
61	2026-08-04 09:46:00+10	9	8	17
61	2026-08-04 09:49:00+10	8	13	21
61	2026-08-04 09:51:00+10	2	6	8
61	2026-08-04 09:52:00+10	3	17	20
61	2026-08-04 09:55:00+10	6	7	13
61	2026-08-04 09:56:00+10	8	7	15
61	2026-08-04 09:57:00+10	0	6	6
61	2026-08-04 09:58:00+10	13	4	17
61	2026-08-04 10:00:00+10	3	8	11
61	2026-08-04 10:01:00+10	4	12	16
61	2026-08-04 10:04:00+10	6	11	17
61	2026-08-04 10:06:00+10	4	8	12
61	2026-08-04 10:08:00+10	8	21	29
61	2026-08-04 10:13:00+10	10	8	18
61	2026-08-04 10:15:00+10	2	11	13
61	2026-08-04 10:18:00+10	8	11	19
61	2026-08-04 10:19:00+10	5	17	22
61	2026-08-04 10:20:00+10	2	14	16
61	2026-08-04 10:24:00+10	12	23	35
61	2026-08-04 10:25:00+10	3	15	18
61	2026-08-04 10:26:00+10	6	18	24
61	2026-08-04 10:30:00+10	7	13	20
61	2026-08-04 10:31:00+10	8	21	29
61	2026-08-04 10:35:00+10	9	8	17
61	2026-08-04 10:39:00+10	7	14	21
61	2026-08-04 10:40:00+10	10	6	16
61	2026-08-04 10:44:00+10	3	9	12
61	2026-08-04 10:49:00+10	4	10	14
61	2026-08-04 10:50:00+10	9	6	15
61	2026-08-04 10:52:00+10	9	8	17
61	2026-08-04 10:54:00+10	12	6	18
61	2026-08-04 10:55:00+10	9	15	24
61	2026-08-04 10:57:00+10	8	10	18
61	2026-08-04 11:00:00+10	8	5	13
61	2026-08-04 11:01:00+10	7	10	17
61	2026-08-04 11:02:00+10	9	8	17
61	2026-08-04 11:03:00+10	7	6	13
61	2026-08-04 11:05:00+10	3	13	16
61	2026-08-04 11:08:00+10	6	14	20
61	2026-08-04 11:09:00+10	7	18	25
61	2026-08-04 11:13:00+10	7	2	9
61	2026-08-04 11:15:00+10	7	10	17
61	2026-08-04 11:18:00+10	6	13	19
61	2026-08-04 11:20:00+10	6	9	15
61	2026-08-04 11:23:00+10	13	9	22
61	2026-08-04 11:24:00+10	6	13	19
61	2026-08-04 11:25:00+10	7	19	26
61	2026-08-04 11:29:00+10	10	13	23
61	2026-08-04 11:32:00+10	4	12	16
61	2026-08-04 11:35:00+10	5	7	12
61	2026-08-04 11:36:00+10	2	12	14
61	2026-08-04 11:41:00+10	5	10	15
61	2026-08-04 11:47:00+10	7	7	14
61	2026-08-04 11:49:00+10	3	6	9
61	2026-08-04 11:53:00+10	3	15	18
61	2026-08-04 11:58:00+10	6	4	10
61	2026-08-04 12:02:00+10	6	15	21
61	2026-08-04 12:03:00+10	3	7	10
61	2026-08-04 12:06:00+10	6	7	13
61	2026-08-04 12:11:00+10	17	15	32
61	2026-08-04 12:12:00+10	14	7	21
61	2026-08-04 12:15:00+10	15	11	26
61	2026-08-04 12:17:00+10	18	14	32
61	2026-08-04 12:18:00+10	13	7	20
61	2026-08-04 12:19:00+10	14	31	45
61	2026-08-04 12:20:00+10	14	22	36
61	2026-08-04 12:21:00+10	13	33	46
61	2026-08-04 12:25:00+10	10	19	29
61	2026-08-04 12:26:00+10	15	16	31
61	2026-08-04 12:27:00+10	12	13	25
61	2026-08-04 12:29:00+10	15	16	31
61	2026-08-04 12:31:00+10	9	17	26
61	2026-08-04 12:46:00+10	12	15	27
61	2026-08-04 12:49:00+10	20	18	38
61	2026-08-04 12:50:00+10	14	16	30
61	2026-08-04 12:51:00+10	7	10	17
61	2026-08-04 12:52:00+10	5	5	10
61	2026-08-04 12:54:00+10	10	9	19
61	2026-08-04 12:58:00+10	10	28	38
61	2026-08-04 13:05:00+10	14	16	30
61	2026-08-04 13:06:00+10	7	7	14
61	2026-08-04 13:10:00+10	18	26	44
61	2026-08-04 13:15:00+10	8	5	13
61	2026-08-04 13:16:00+10	16	18	34
61	2026-08-04 13:18:00+10	14	17	31
61	2026-08-04 13:21:00+10	15	9	24
61	2026-08-04 13:26:00+10	9	11	20
61	2026-08-04 13:28:00+10	8	12	20
61	2026-08-04 13:29:00+10	10	19	29
61	2026-08-04 13:31:00+10	11	19	30
61	2026-08-04 13:32:00+10	14	24	38
61	2026-08-04 13:35:00+10	12	12	24
61	2026-08-04 13:36:00+10	10	33	43
61	2026-08-04 13:37:00+10	16	15	31
61	2026-08-04 13:38:00+10	17	15	32
61	2026-08-04 13:41:00+10	19	8	27
61	2026-08-04 13:47:00+10	10	3	13
61	2026-08-04 13:59:00+10	16	20	36
61	2026-08-04 14:06:00+10	9	24	33
61	2026-08-04 14:10:00+10	8	18	26
61	2026-08-04 14:13:00+10	17	8	25
61	2026-08-04 14:19:00+10	16	37	53
61	2026-08-04 14:21:00+10	16	13	29
61	2026-08-04 14:22:00+10	16	23	39
61	2026-08-04 14:23:00+10	15	13	28
61	2026-08-04 14:27:00+10	12	12	24
61	2026-08-04 14:29:00+10	12	22	34
61	2026-08-04 14:33:00+10	15	14	29
61	2026-08-04 14:35:00+10	8	18	26
61	2026-08-04 14:39:00+10	12	13	25
62	2026-08-03 23:55:00+10	0	2	2
62	2026-08-03 23:56:00+10	1	0	1
62	2026-08-03 23:59:00+10	1	0	1
62	2026-08-04 00:06:00+10	5	0	5
62	2026-08-04 00:07:00+10	0	1	1
62	2026-08-04 00:09:00+10	2	1	3
62	2026-08-04 00:16:00+10	1	0	1
62	2026-08-04 00:19:00+10	2	0	2
62	2026-08-04 00:29:00+10	0	3	3
62	2026-08-04 00:32:00+10	0	5	5
62	2026-08-04 00:33:00+10	2	0	2
62	2026-08-04 00:35:00+10	3	0	3
62	2026-08-04 00:36:00+10	1	0	1
62	2026-08-04 00:38:00+10	0	1	1
62	2026-08-04 00:45:00+10	2	0	2
62	2026-08-04 00:52:00+10	1	0	1
62	2026-08-04 01:06:00+10	0	1	1
62	2026-08-04 01:16:00+10	0	2	2
62	2026-08-04 01:30:00+10	1	1	2
62	2026-08-04 01:36:00+10	1	0	1
62	2026-08-04 01:41:00+10	1	0	1
62	2026-08-04 01:45:00+10	1	0	1
62	2026-08-04 01:56:00+10	1	0	1
62	2026-08-04 01:58:00+10	6	0	6
62	2026-08-04 01:59:00+10	3	0	3
62	2026-08-04 02:30:00+10	1	0	1
62	2026-08-04 02:31:00+10	0	1	1
62	2026-08-04 02:46:00+10	1	0	1
62	2026-08-04 02:48:00+10	1	0	1
62	2026-08-04 03:04:00+10	2	0	2
62	2026-08-04 03:05:00+10	0	1	1
62	2026-08-04 03:16:00+10	0	2	2
62	2026-08-04 03:54:00+10	1	0	1
62	2026-08-04 04:01:00+10	1	0	1
62	2026-08-04 04:14:00+10	1	0	1
62	2026-08-04 05:09:00+10	1	0	1
62	2026-08-04 05:32:00+10	0	1	1
62	2026-08-04 05:33:00+10	0	2	2
62	2026-08-04 05:52:00+10	1	0	1
62	2026-08-04 05:56:00+10	0	1	1
62	2026-08-04 06:26:00+10	0	1	1
62	2026-08-04 06:27:00+10	3	0	3
62	2026-08-04 06:35:00+10	2	0	2
62	2026-08-04 06:38:00+10	0	1	1
62	2026-08-04 06:40:00+10	2	1	3
62	2026-08-04 06:41:00+10	1	0	1
62	2026-08-04 06:50:00+10	1	0	1
62	2026-08-04 06:52:00+10	2	1	3
62	2026-08-04 06:53:00+10	1	2	3
62	2026-08-04 06:57:00+10	3	1	4
62	2026-08-04 07:02:00+10	1	0	1
62	2026-08-04 07:03:00+10	1	0	1
62	2026-08-04 07:06:00+10	0	1	1
62	2026-08-04 07:09:00+10	0	1	1
62	2026-08-04 07:20:00+10	1	0	1
62	2026-08-04 07:24:00+10	0	2	2
62	2026-08-04 07:40:00+10	0	1	1
62	2026-08-04 07:50:00+10	0	1	1
62	2026-08-04 07:53:00+10	1	0	1
62	2026-08-04 07:58:00+10	0	1	1
62	2026-08-04 08:02:00+10	2	1	3
62	2026-08-04 08:11:00+10	1	0	1
62	2026-08-04 08:15:00+10	1	0	1
62	2026-08-04 08:18:00+10	1	3	4
62	2026-08-04 08:20:00+10	1	0	1
62	2026-08-04 08:24:00+10	3	1	4
62	2026-08-04 08:28:00+10	2	0	2
62	2026-08-04 08:31:00+10	2	3	5
62	2026-08-04 08:33:00+10	1	1	2
62	2026-08-04 08:37:00+10	0	2	2
62	2026-08-04 08:39:00+10	3	0	3
62	2026-08-04 08:40:00+10	2	2	4
62	2026-08-04 08:41:00+10	3	4	7
62	2026-08-04 08:48:00+10	2	4	6
62	2026-08-04 08:53:00+10	2	3	5
62	2026-08-04 08:55:00+10	1	0	1
62	2026-08-04 08:56:00+10	1	2	3
62	2026-08-04 08:58:00+10	1	1	2
62	2026-08-04 09:02:00+10	2	1	3
62	2026-08-04 09:10:00+10	3	1	4
62	2026-08-04 09:11:00+10	4	2	6
62	2026-08-04 09:14:00+10	0	1	1
62	2026-08-04 09:22:00+10	2	2	4
62	2026-08-04 09:27:00+10	1	1	2
62	2026-08-04 09:28:00+10	1	2	3
62	2026-08-04 09:33:00+10	3	5	8
62	2026-08-04 09:34:00+10	3	0	3
62	2026-08-04 09:35:00+10	0	1	1
62	2026-08-04 09:39:00+10	7	6	13
62	2026-08-04 09:43:00+10	2	1	3
62	2026-08-04 09:44:00+10	0	1	1
62	2026-08-04 09:45:00+10	1	1	2
62	2026-08-04 09:47:00+10	3	0	3
62	2026-08-04 09:49:00+10	0	2	2
62	2026-08-04 09:52:00+10	3	1	4
62	2026-08-04 09:53:00+10	0	3	3
62	2026-08-04 10:00:00+10	3	1	4
62	2026-08-04 10:05:00+10	3	0	3
62	2026-08-04 10:06:00+10	2	3	5
62	2026-08-04 10:10:00+10	3	7	10
62	2026-08-04 10:13:00+10	5	1	6
62	2026-08-04 10:15:00+10	4	0	4
62	2026-08-04 10:17:00+10	2	1	3
62	2026-08-04 10:18:00+10	3	0	3
62	2026-08-04 10:19:00+10	4	2	6
62	2026-08-04 10:24:00+10	5	1	6
62	2026-08-04 10:27:00+10	1	0	1
62	2026-08-04 10:29:00+10	4	1	5
62	2026-08-04 10:31:00+10	1	0	1
62	2026-08-04 10:34:00+10	0	1	1
62	2026-08-04 10:37:00+10	2	1	3
62	2026-08-04 10:43:00+10	4	2	6
62	2026-08-04 10:45:00+10	4	1	5
62	2026-08-04 10:50:00+10	7	2	9
62	2026-08-04 10:52:00+10	16	2	18
62	2026-08-04 10:55:00+10	2	0	2
62	2026-08-04 10:58:00+10	4	2	6
62	2026-08-04 11:00:00+10	2	2	4
62	2026-08-04 11:02:00+10	5	2	7
62	2026-08-04 11:04:00+10	1	2	3
62	2026-08-04 11:08:00+10	8	0	8
62	2026-08-04 11:12:00+10	5	0	5
62	2026-08-04 11:13:00+10	3	3	6
62	2026-08-04 11:15:00+10	7	2	9
62	2026-08-04 11:16:00+10	2	2	4
62	2026-08-04 11:20:00+10	6	0	6
62	2026-08-04 11:21:00+10	5	1	6
62	2026-08-04 11:25:00+10	2	1	3
62	2026-08-04 11:27:00+10	1	3	4
62	2026-08-04 11:28:00+10	5	3	8
62	2026-08-04 11:30:00+10	3	1	4
62	2026-08-04 11:31:00+10	4	2	6
62	2026-08-04 11:32:00+10	2	0	2
62	2026-08-04 11:33:00+10	0	2	2
62	2026-08-04 11:36:00+10	2	5	7
62	2026-08-04 11:40:00+10	3	3	6
62	2026-08-04 11:45:00+10	3	3	6
62	2026-08-04 11:46:00+10	1	4	5
62	2026-08-04 11:49:00+10	0	1	1
62	2026-08-04 11:50:00+10	1	2	3
62	2026-08-04 11:52:00+10	2	1	3
62	2026-08-04 11:58:00+10	2	2	4
62	2026-08-04 12:06:00+10	3	2	5
62	2026-08-04 12:07:00+10	2	1	3
62	2026-08-04 12:14:00+10	8	0	8
62	2026-08-04 12:15:00+10	4	0	4
62	2026-08-04 12:17:00+10	3	7	10
62	2026-08-04 12:19:00+10	4	2	6
62	2026-08-04 12:23:00+10	4	3	7
62	2026-08-04 12:24:00+10	5	2	7
62	2026-08-04 12:25:00+10	1	0	1
62	2026-08-04 12:26:00+10	7	3	10
62	2026-08-04 12:29:00+10	7	0	7
62	2026-08-04 12:34:00+10	5	2	7
62	2026-08-04 12:37:00+10	9	1	10
62	2026-08-04 12:41:00+10	13	3	16
62	2026-08-04 12:42:00+10	12	2	14
62	2026-08-04 12:45:00+10	9	6	15
62	2026-08-04 12:46:00+10	2	1	3
62	2026-08-04 12:47:00+10	8	3	11
62	2026-08-04 12:50:00+10	3	7	10
62	2026-08-04 12:54:00+10	13	1	14
62	2026-08-04 12:56:00+10	5	3	8
62	2026-08-04 12:59:00+10	11	4	15
62	2026-08-04 13:00:00+10	3	1	4
62	2026-08-04 13:04:00+10	10	1	11
62	2026-08-04 13:10:00+10	7	2	9
62	2026-08-04 13:12:00+10	8	1	9
62	2026-08-04 13:13:00+10	5	10	15
62	2026-08-04 13:14:00+10	5	2	7
62	2026-08-04 13:21:00+10	6	3	9
62	2026-08-04 13:23:00+10	7	9	16
62	2026-08-04 13:24:00+10	7	2	9
62	2026-08-04 13:26:00+10	5	2	7
62	2026-08-04 13:31:00+10	2	0	2
62	2026-08-04 13:33:00+10	3	4	7
62	2026-08-04 13:35:00+10	3	4	7
62	2026-08-04 13:36:00+10	8	0	8
62	2026-08-04 13:37:00+10	13	2	15
62	2026-08-04 13:41:00+10	3	2	5
62	2026-08-04 13:44:00+10	0	1	1
62	2026-08-04 13:47:00+10	2	5	7
62	2026-08-04 13:49:00+10	7	1	8
62	2026-08-04 13:50:00+10	8	3	11
62	2026-08-04 13:52:00+10	4	9	13
62	2026-08-04 13:58:00+10	6	3	9
62	2026-08-04 14:02:00+10	2	3	5
62	2026-08-04 14:05:00+10	4	0	4
62	2026-08-04 14:06:00+10	8	1	9
62	2026-08-04 14:08:00+10	6	0	6
62	2026-08-04 14:10:00+10	9	1	10
62	2026-08-04 14:12:00+10	5	1	6
62	2026-08-04 14:17:00+10	6	4	10
62	2026-08-04 14:24:00+10	7	4	11
62	2026-08-04 14:25:00+10	7	1	8
62	2026-08-04 14:26:00+10	6	1	7
62	2026-08-04 14:28:00+10	8	2	10
62	2026-08-04 14:30:00+10	3	1	4
63	2026-08-03 23:56:00+10	0	4	4
63	2026-08-03 23:58:00+10	1	1	2
63	2026-08-04 00:10:00+10	1	2	3
63	2026-08-04 00:11:00+10	2	0	2
63	2026-08-04 00:17:00+10	0	1	1
63	2026-08-04 00:31:00+10	1	0	1
63	2026-08-04 00:39:00+10	2	2	4
63	2026-08-04 00:42:00+10	0	1	1
63	2026-08-04 00:56:00+10	0	1	1
63	2026-08-04 01:07:00+10	0	2	2
63	2026-08-04 01:36:00+10	1	0	1
63	2026-08-04 01:46:00+10	0	2	2
63	2026-08-04 01:48:00+10	0	2	2
63	2026-08-04 02:07:00+10	0	2	2
63	2026-08-04 02:41:00+10	0	2	2
63	2026-08-04 02:46:00+10	1	0	1
63	2026-08-04 02:55:00+10	0	2	2
63	2026-08-04 03:05:00+10	1	0	1
63	2026-08-04 03:10:00+10	3	0	3
63	2026-08-04 04:36:00+10	0	1	1
63	2026-08-04 04:54:00+10	1	0	1
63	2026-08-04 05:33:00+10	0	1	1
63	2026-08-04 05:43:00+10	0	2	2
63	2026-08-04 05:45:00+10	0	2	2
63	2026-08-04 05:56:00+10	1	0	1
63	2026-08-04 06:01:00+10	1	2	3
63	2026-08-04 06:21:00+10	0	1	1
63	2026-08-04 06:28:00+10	1	2	3
63	2026-08-04 06:32:00+10	0	1	1
63	2026-08-04 06:40:00+10	2	4	6
63	2026-08-04 06:41:00+10	3	1	4
63	2026-08-04 06:42:00+10	2	3	5
63	2026-08-04 06:44:00+10	0	5	5
63	2026-08-04 06:50:00+10	0	2	2
63	2026-08-04 06:52:00+10	0	3	3
63	2026-08-04 06:55:00+10	1	2	3
63	2026-08-04 06:57:00+10	1	2	3
63	2026-08-04 07:02:00+10	1	1	2
63	2026-08-04 07:03:00+10	1	4	5
63	2026-08-04 07:09:00+10	0	4	4
63	2026-08-04 07:18:00+10	2	2	4
63	2026-08-04 07:20:00+10	0	1	1
63	2026-08-04 07:29:00+10	3	2	5
63	2026-08-04 07:32:00+10	1	0	1
63	2026-08-04 07:36:00+10	4	1	5
63	2026-08-04 07:52:00+10	4	0	4
63	2026-08-04 07:55:00+10	4	4	8
63	2026-08-04 07:56:00+10	3	4	7
63	2026-08-04 07:58:00+10	1	4	5
63	2026-08-04 08:01:00+10	2	0	2
63	2026-08-04 08:03:00+10	0	2	2
63	2026-08-04 08:08:00+10	1	2	3
63	2026-08-04 08:13:00+10	2	3	5
63	2026-08-04 08:17:00+10	3	3	6
63	2026-08-04 08:19:00+10	2	3	5
63	2026-08-04 08:23:00+10	3	2	5
63	2026-08-04 08:25:00+10	3	7	10
63	2026-08-04 08:27:00+10	3	1	4
63	2026-08-04 08:30:00+10	4	3	7
63	2026-08-04 08:34:00+10	6	7	13
63	2026-08-04 08:35:00+10	5	3	8
63	2026-08-04 08:38:00+10	2	1	3
63	2026-08-04 08:40:00+10	6	5	11
63	2026-08-04 08:43:00+10	6	2	8
63	2026-08-04 08:44:00+10	6	5	11
63	2026-08-04 08:45:00+10	4	1	5
63	2026-08-04 08:46:00+10	5	5	10
63	2026-08-04 08:48:00+10	2	3	5
63	2026-08-04 08:49:00+10	5	3	8
63	2026-08-04 08:52:00+10	3	6	9
63	2026-08-04 08:59:00+10	4	3	7
63	2026-08-04 09:01:00+10	3	4	7
63	2026-08-04 09:02:00+10	2	4	6
63	2026-08-04 09:03:00+10	7	8	15
63	2026-08-04 09:06:00+10	4	10	14
63	2026-08-04 09:11:00+10	5	1	6
63	2026-08-04 09:15:00+10	3	4	7
63	2026-08-04 09:18:00+10	5	2	7
63	2026-08-04 09:21:00+10	6	1	7
63	2026-08-04 09:23:00+10	1	1	2
63	2026-08-04 09:24:00+10	1	2	3
63	2026-08-04 09:28:00+10	3	5	8
63	2026-08-04 09:29:00+10	7	3	10
63	2026-08-04 09:36:00+10	0	1	1
63	2026-08-04 09:37:00+10	1	3	4
63	2026-08-04 09:50:00+10	5	4	9
63	2026-08-04 09:55:00+10	2	9	11
63	2026-08-04 09:58:00+10	1	2	3
63	2026-08-04 10:02:00+10	1	2	3
63	2026-08-04 10:03:00+10	2	4	6
63	2026-08-04 10:04:00+10	5	9	14
63	2026-08-04 10:08:00+10	1	3	4
63	2026-08-04 10:09:00+10	2	4	6
63	2026-08-04 10:11:00+10	4	8	12
63	2026-08-04 10:12:00+10	5	2	7
63	2026-08-04 10:13:00+10	1	6	7
63	2026-08-04 10:15:00+10	8	3	11
63	2026-08-04 10:17:00+10	1	1	2
63	2026-08-04 10:18:00+10	3	10	13
63	2026-08-04 10:19:00+10	1	1	2
63	2026-08-04 10:23:00+10	1	4	5
63	2026-08-04 10:28:00+10	3	1	4
63	2026-08-04 10:33:00+10	7	3	10
63	2026-08-04 10:35:00+10	1	2	3
63	2026-08-04 10:36:00+10	1	1	2
63	2026-08-04 10:38:00+10	10	4	14
63	2026-08-04 10:42:00+10	2	3	5
63	2026-08-04 10:43:00+10	0	8	8
63	2026-08-04 10:46:00+10	4	8	12
63	2026-08-04 10:47:00+10	2	3	5
63	2026-08-04 10:49:00+10	2	0	2
63	2026-08-04 10:51:00+10	5	1	6
63	2026-08-04 10:52:00+10	1	4	5
63	2026-08-04 10:54:00+10	4	2	6
63	2026-08-04 10:58:00+10	5	3	8
63	2026-08-04 11:00:00+10	4	2	6
63	2026-08-04 11:02:00+10	2	8	10
63	2026-08-04 11:05:00+10	1	1	2
63	2026-08-04 11:06:00+10	2	3	5
63	2026-08-04 11:08:00+10	8	6	14
63	2026-08-04 11:09:00+10	3	7	10
63	2026-08-04 11:14:00+10	4	8	12
63	2026-08-04 11:15:00+10	5	3	8
63	2026-08-04 11:18:00+10	0	9	9
63	2026-08-04 11:20:00+10	1	6	7
63	2026-08-04 11:24:00+10	4	6	10
63	2026-08-04 11:26:00+10	4	3	7
63	2026-08-04 11:32:00+10	6	5	11
63	2026-08-04 11:35:00+10	13	3	16
63	2026-08-04 11:36:00+10	9	3	12
63	2026-08-04 11:40:00+10	10	4	14
63	2026-08-04 11:48:00+10	5	3	8
63	2026-08-04 11:50:00+10	2	2	4
63	2026-08-04 11:53:00+10	2	2	4
63	2026-08-04 12:04:00+10	4	6	10
63	2026-08-04 12:09:00+10	7	11	18
63	2026-08-04 12:10:00+10	4	11	15
63	2026-08-04 12:11:00+10	0	12	12
63	2026-08-04 12:13:00+10	3	6	9
63	2026-08-04 12:14:00+10	2	10	12
63	2026-08-04 12:16:00+10	8	8	16
63	2026-08-04 12:18:00+10	11	10	21
63	2026-08-04 12:21:00+10	5	3	8
63	2026-08-04 12:23:00+10	7	7	14
63	2026-08-04 12:24:00+10	6	7	13
63	2026-08-04 12:29:00+10	22	12	34
63	2026-08-04 12:35:00+10	17	8	25
63	2026-08-04 12:38:00+10	7	15	22
63	2026-08-04 12:39:00+10	18	8	26
63	2026-08-04 12:41:00+10	16	14	30
63	2026-08-04 12:43:00+10	7	15	22
63	2026-08-04 12:44:00+10	4	12	16
63	2026-08-04 12:50:00+10	9	13	22
63	2026-08-04 12:52:00+10	10	2	12
63	2026-08-04 12:57:00+10	5	9	14
63	2026-08-04 12:58:00+10	6	10	16
63	2026-08-04 13:02:00+10	8	19	27
63	2026-08-04 13:04:00+10	8	12	20
63	2026-08-04 13:10:00+10	17	7	24
63	2026-08-04 13:13:00+10	11	9	20
63	2026-08-04 13:18:00+10	9	14	23
63	2026-08-04 13:19:00+10	8	7	15
63	2026-08-04 13:20:00+10	10	12	22
63	2026-08-04 13:23:00+10	12	4	16
63	2026-08-04 13:24:00+10	3	8	11
63	2026-08-04 13:30:00+10	8	12	20
63	2026-08-04 13:31:00+10	11	9	20
63	2026-08-04 13:32:00+10	3	4	7
63	2026-08-04 13:38:00+10	4	6	10
63	2026-08-04 13:39:00+10	12	20	32
63	2026-08-04 13:40:00+10	8	13	21
63	2026-08-04 13:45:00+10	8	6	14
63	2026-08-04 13:47:00+10	10	9	19
63	2026-08-04 13:52:00+10	1	6	7
63	2026-08-04 13:58:00+10	2	9	11
63	2026-08-04 14:01:00+10	5	7	12
63	2026-08-04 14:05:00+10	4	11	15
63	2026-08-04 14:08:00+10	7	2	9
63	2026-08-04 14:11:00+10	4	12	16
63	2026-08-04 14:14:00+10	1	6	7
63	2026-08-04 14:16:00+10	11	6	17
63	2026-08-04 14:19:00+10	8	12	20
63	2026-08-04 14:21:00+10	1	3	4
63	2026-08-04 14:26:00+10	6	3	9
63	2026-08-04 14:27:00+10	5	10	15
63	2026-08-04 14:28:00+10	10	0	10
63	2026-08-04 14:30:00+10	6	8	14
63	2026-08-04 14:31:00+10	6	9	15
63	2026-08-04 14:36:00+10	9	10	19
63	2026-08-04 14:38:00+10	3	2	5
66	2026-08-03 23:57:00+10	1	0	1
66	2026-08-03 23:58:00+10	5	1	6
66	2026-08-03 23:59:00+10	0	2	2
66	2026-08-04 00:04:00+10	0	2	2
66	2026-08-04 00:07:00+10	0	1	1
66	2026-08-04 00:20:00+10	1	0	1
66	2026-08-04 00:25:00+10	0	3	3
66	2026-08-04 00:31:00+10	0	2	2
66	2026-08-04 00:34:00+10	1	0	1
66	2026-08-04 00:41:00+10	0	2	2
66	2026-08-04 00:47:00+10	1	2	3
66	2026-08-04 00:49:00+10	2	1	3
66	2026-08-04 00:54:00+10	4	0	4
66	2026-08-04 01:00:00+10	5	1	6
66	2026-08-04 01:09:00+10	0	2	2
66	2026-08-04 01:12:00+10	0	2	2
66	2026-08-04 01:15:00+10	0	2	2
66	2026-08-04 01:16:00+10	0	1	1
66	2026-08-04 01:17:00+10	1	0	1
66	2026-08-04 01:28:00+10	0	1	1
66	2026-08-04 01:30:00+10	0	1	1
66	2026-08-04 01:41:00+10	0	2	2
66	2026-08-04 01:42:00+10	0	1	1
66	2026-08-04 01:46:00+10	1	0	1
66	2026-08-04 01:58:00+10	1	0	1
66	2026-08-04 02:52:00+10	1	0	1
66	2026-08-04 03:09:00+10	0	1	1
66	2026-08-04 03:17:00+10	0	1	1
66	2026-08-04 04:10:00+10	3	0	3
66	2026-08-04 04:52:00+10	0	1	1
66	2026-08-04 05:13:00+10	0	3	3
66	2026-08-04 05:16:00+10	0	1	1
66	2026-08-04 05:35:00+10	0	2	2
66	2026-08-04 05:36:00+10	0	1	1
66	2026-08-04 05:51:00+10	1	1	2
66	2026-08-04 05:52:00+10	1	0	1
66	2026-08-04 06:00:00+10	1	1	2
66	2026-08-04 06:04:00+10	0	1	1
66	2026-08-04 06:08:00+10	0	2	2
66	2026-08-04 06:09:00+10	1	0	1
66	2026-08-04 06:12:00+10	1	1	2
66	2026-08-04 06:22:00+10	1	1	2
66	2026-08-04 06:25:00+10	1	1	2
66	2026-08-04 06:28:00+10	1	0	1
66	2026-08-04 06:39:00+10	1	1	2
66	2026-08-04 06:40:00+10	0	3	3
66	2026-08-04 06:42:00+10	1	3	4
66	2026-08-04 06:49:00+10	0	2	2
66	2026-08-04 06:52:00+10	1	0	1
66	2026-08-04 06:54:00+10	1	2	3
66	2026-08-04 07:05:00+10	0	2	2
66	2026-08-04 07:09:00+10	0	2	2
66	2026-08-04 07:10:00+10	4	5	9
66	2026-08-04 07:18:00+10	1	1	2
66	2026-08-04 07:19:00+10	0	2	2
66	2026-08-04 07:23:00+10	1	2	3
66	2026-08-04 07:24:00+10	1	0	1
66	2026-08-04 07:26:00+10	0	4	4
66	2026-08-04 07:28:00+10	1	6	7
66	2026-08-04 07:29:00+10	2	6	8
66	2026-08-04 07:31:00+10	1	3	4
66	2026-08-04 07:32:00+10	4	4	8
66	2026-08-04 07:33:00+10	0	3	3
66	2026-08-04 07:35:00+10	1	3	4
66	2026-08-04 07:36:00+10	0	1	1
66	2026-08-04 07:39:00+10	0	2	2
66	2026-08-04 07:42:00+10	0	5	5
66	2026-08-04 07:43:00+10	2	10	12
66	2026-08-04 07:49:00+10	3	7	10
66	2026-08-04 07:50:00+10	0	10	10
66	2026-08-04 07:53:00+10	2	5	7
66	2026-08-04 07:55:00+10	2	8	10
66	2026-08-04 07:58:00+10	4	6	10
66	2026-08-04 08:02:00+10	2	5	7
66	2026-08-04 08:12:00+10	4	7	11
66	2026-08-04 08:13:00+10	4	8	12
66	2026-08-04 08:16:00+10	8	8	16
66	2026-08-04 08:17:00+10	5	20	25
66	2026-08-04 08:23:00+10	2	13	15
66	2026-08-04 08:26:00+10	4	14	18
66	2026-08-04 08:30:00+10	5	18	23
66	2026-08-04 08:31:00+10	5	4	9
66	2026-08-04 08:38:00+10	2	22	24
66	2026-08-04 08:40:00+10	3	10	13
66	2026-08-04 08:41:00+10	1	8	9
66	2026-08-04 08:42:00+10	3	16	19
66	2026-08-04 08:45:00+10	1	11	12
66	2026-08-04 08:46:00+10	4	9	13
66	2026-08-04 08:56:00+10	4	17	21
66	2026-08-04 08:58:00+10	1	8	9
66	2026-08-04 09:06:00+10	1	12	13
66	2026-08-04 09:16:00+10	6	7	13
66	2026-08-04 09:18:00+10	1	11	12
66	2026-08-04 09:21:00+10	4	15	19
66	2026-08-04 09:23:00+10	6	12	18
66	2026-08-04 09:24:00+10	2	6	8
66	2026-08-04 09:26:00+10	3	11	14
66	2026-08-04 09:29:00+10	7	8	15
66	2026-08-04 09:32:00+10	5	9	14
66	2026-08-04 09:37:00+10	6	5	11
66	2026-08-04 09:39:00+10	9	16	25
66	2026-08-04 09:41:00+10	10	17	27
66	2026-08-04 09:44:00+10	7	9	16
66	2026-08-04 09:47:00+10	9	11	20
66	2026-08-04 09:49:00+10	9	6	15
66	2026-08-04 09:51:00+10	8	5	13
66	2026-08-04 09:52:00+10	7	9	16
66	2026-08-04 09:54:00+10	2	7	9
66	2026-08-04 09:59:00+10	29	14	43
66	2026-08-04 10:00:00+10	6	4	10
66	2026-08-04 10:03:00+10	2	6	8
66	2026-08-04 10:04:00+10	11	6	17
66	2026-08-04 10:12:00+10	7	8	15
66	2026-08-04 10:17:00+10	3	9	12
66	2026-08-04 10:18:00+10	9	12	21
66	2026-08-04 10:19:00+10	17	2	19
66	2026-08-04 10:22:00+10	6	11	17
66	2026-08-04 10:23:00+10	7	18	25
66	2026-08-04 10:27:00+10	3	8	11
66	2026-08-04 10:32:00+10	6	6	12
66	2026-08-04 10:34:00+10	4	2	6
66	2026-08-04 10:36:00+10	6	13	19
66	2026-08-04 10:37:00+10	6	11	17
66	2026-08-04 10:38:00+10	12	11	23
66	2026-08-04 10:39:00+10	4	11	15
66	2026-08-04 10:43:00+10	8	10	18
66	2026-08-04 10:47:00+10	11	10	21
66	2026-08-04 10:49:00+10	8	6	14
66	2026-08-04 10:50:00+10	5	10	15
66	2026-08-04 10:51:00+10	7	7	14
66	2026-08-04 10:54:00+10	8	9	17
66	2026-08-04 11:05:00+10	3	16	19
66	2026-08-04 11:16:00+10	20	9	29
66	2026-08-04 11:18:00+10	5	9	14
66	2026-08-04 11:21:00+10	4	10	14
66	2026-08-04 11:23:00+10	13	14	27
66	2026-08-04 11:27:00+10	2	9	11
66	2026-08-04 11:30:00+10	6	18	24
66	2026-08-04 11:32:00+10	11	13	24
66	2026-08-04 11:35:00+10	8	17	25
66	2026-08-04 11:36:00+10	12	11	23
66	2026-08-04 11:37:00+10	3	11	14
66	2026-08-04 11:39:00+10	10	9	19
66	2026-08-04 11:40:00+10	6	6	12
66	2026-08-04 11:41:00+10	13	15	28
66	2026-08-04 11:43:00+10	5	13	18
66	2026-08-04 11:44:00+10	9	10	19
66	2026-08-04 11:46:00+10	13	4	17
66	2026-08-04 11:47:00+10	5	13	18
66	2026-08-04 11:53:00+10	7	17	24
66	2026-08-04 11:56:00+10	15	11	26
66	2026-08-04 11:57:00+10	1	11	12
66	2026-08-04 12:01:00+10	4	11	15
66	2026-08-04 12:02:00+10	3	16	19
66	2026-08-04 12:04:00+10	8	7	15
66	2026-08-04 12:05:00+10	13	7	20
66	2026-08-04 12:07:00+10	25	18	43
66	2026-08-04 12:10:00+10	11	11	22
66	2026-08-04 12:14:00+10	9	34	43
66	2026-08-04 12:18:00+10	14	18	32
66	2026-08-04 12:19:00+10	12	17	29
66	2026-08-04 12:20:00+10	8	17	25
66	2026-08-04 12:21:00+10	15	11	26
66	2026-08-04 12:24:00+10	12	14	26
66	2026-08-04 12:31:00+10	9	21	30
66	2026-08-04 12:35:00+10	16	26	42
66	2026-08-04 12:38:00+10	27	27	54
66	2026-08-04 12:42:00+10	19	25	44
66	2026-08-04 12:46:00+10	18	33	51
66	2026-08-04 12:48:00+10	13	24	37
66	2026-08-04 12:49:00+10	22	25	47
66	2026-08-04 12:51:00+10	14	32	46
66	2026-08-04 12:56:00+10	16	30	46
66	2026-08-04 12:57:00+10	13	24	37
66	2026-08-04 12:58:00+10	25	8	33
66	2026-08-04 13:00:00+10	12	34	46
66	2026-08-04 13:08:00+10	13	33	46
66	2026-08-04 13:19:00+10	21	14	35
66	2026-08-04 13:21:00+10	20	19	39
66	2026-08-04 13:22:00+10	27	23	50
66	2026-08-04 13:26:00+10	9	24	33
66	2026-08-04 13:28:00+10	29	29	58
66	2026-08-04 13:31:00+10	50	23	73
66	2026-08-04 13:32:00+10	20	20	40
66	2026-08-04 13:33:00+10	12	10	22
66	2026-08-04 13:35:00+10	18	15	33
66	2026-08-04 13:36:00+10	12	15	27
66	2026-08-04 13:37:00+10	20	26	46
66	2026-08-04 13:38:00+10	14	23	37
66	2026-08-04 13:39:00+10	11	23	34
66	2026-08-04 13:40:00+10	20	10	30
66	2026-08-04 13:42:00+10	19	21	40
66	2026-08-04 13:43:00+10	28	19	47
66	2026-08-04 13:53:00+10	15	34	49
66	2026-08-04 13:54:00+10	8	14	22
66	2026-08-04 13:55:00+10	26	22	48
66	2026-08-04 13:57:00+10	19	5	24
66	2026-08-04 13:58:00+10	23	33	56
66	2026-08-04 14:02:00+10	27	21	48
66	2026-08-04 14:05:00+10	9	19	28
66	2026-08-04 14:07:00+10	17	18	35
66	2026-08-04 14:09:00+10	10	16	26
66	2026-08-04 14:13:00+10	18	21	39
66	2026-08-04 14:16:00+10	25	22	47
66	2026-08-04 14:18:00+10	22	16	38
66	2026-08-04 14:20:00+10	19	24	43
66	2026-08-04 14:21:00+10	18	22	40
66	2026-08-04 14:23:00+10	18	33	51
66	2026-08-04 14:26:00+10	21	32	53
66	2026-08-04 14:28:00+10	32	24	56
66	2026-08-04 14:34:00+10	20	16	36
66	2026-08-04 14:39:00+10	8	24	32
67	2026-08-04 00:12:00+10	0	1	1
67	2026-08-04 00:39:00+10	1	1	2
67	2026-08-04 01:05:00+10	0	1	1
67	2026-08-04 02:13:00+10	2	0	2
67	2026-08-04 02:41:00+10	0	1	1
67	2026-08-04 03:51:00+10	1	0	1
67	2026-08-04 03:59:00+10	0	1	1
67	2026-08-04 05:06:00+10	1	0	1
67	2026-08-04 05:25:00+10	1	1	2
67	2026-08-04 05:45:00+10	0	2	2
67	2026-08-04 05:48:00+10	1	1	2
67	2026-08-04 05:56:00+10	0	4	4
67	2026-08-04 05:59:00+10	1	0	1
67	2026-08-04 06:04:00+10	0	1	1
67	2026-08-04 06:05:00+10	1	2	3
67	2026-08-04 06:09:00+10	1	0	1
67	2026-08-04 06:22:00+10	1	0	1
67	2026-08-04 06:23:00+10	0	1	1
67	2026-08-04 06:28:00+10	1	0	1
67	2026-08-04 06:29:00+10	2	0	2
67	2026-08-04 06:30:00+10	0	4	4
67	2026-08-04 06:31:00+10	1	4	5
67	2026-08-04 06:33:00+10	0	1	1
67	2026-08-04 06:34:00+10	2	0	2
67	2026-08-04 06:41:00+10	0	1	1
67	2026-08-04 06:45:00+10	1	1	2
67	2026-08-04 06:48:00+10	1	4	5
67	2026-08-04 06:51:00+10	2	1	3
67	2026-08-04 06:53:00+10	1	3	4
67	2026-08-04 06:54:00+10	3	1	4
67	2026-08-04 06:57:00+10	4	0	4
67	2026-08-04 07:01:00+10	1	4	5
67	2026-08-04 07:02:00+10	1	0	1
67	2026-08-04 07:06:00+10	3	3	6
67	2026-08-04 07:08:00+10	4	1	5
67	2026-08-04 07:15:00+10	0	6	6
67	2026-08-04 07:18:00+10	1	3	4
67	2026-08-04 07:20:00+10	3	2	5
67	2026-08-04 07:21:00+10	3	5	8
67	2026-08-04 07:23:00+10	3	7	10
67	2026-08-04 07:27:00+10	2	4	6
67	2026-08-04 07:28:00+10	3	6	9
67	2026-08-04 07:30:00+10	2	1	3
67	2026-08-04 07:40:00+10	1	5	6
67	2026-08-04 07:41:00+10	6	2	8
67	2026-08-04 07:44:00+10	4	3	7
67	2026-08-04 07:47:00+10	2	7	9
67	2026-08-04 07:53:00+10	3	6	9
67	2026-08-04 07:56:00+10	3	8	11
67	2026-08-04 07:59:00+10	1	6	7
67	2026-08-04 08:00:00+10	1	7	8
67	2026-08-04 08:04:00+10	7	7	14
67	2026-08-04 08:06:00+10	3	5	8
67	2026-08-04 08:07:00+10	6	7	13
67	2026-08-04 08:12:00+10	4	10	14
67	2026-08-04 08:17:00+10	3	1	4
67	2026-08-04 08:20:00+10	8	9	17
67	2026-08-04 08:27:00+10	2	20	22
67	2026-08-04 08:28:00+10	7	8	15
67	2026-08-04 08:33:00+10	3	10	13
67	2026-08-04 08:37:00+10	12	11	23
67	2026-08-04 08:38:00+10	10	4	14
67	2026-08-04 08:42:00+10	1	13	14
67	2026-08-04 08:44:00+10	3	25	28
67	2026-08-04 08:52:00+10	8	9	17
67	2026-08-04 08:53:00+10	3	7	10
67	2026-08-04 08:57:00+10	3	13	16
67	2026-08-04 08:59:00+10	6	11	17
67	2026-08-04 09:00:00+10	5	4	9
67	2026-08-04 09:02:00+10	5	4	9
67	2026-08-04 09:05:00+10	0	4	4
67	2026-08-04 09:08:00+10	3	12	15
67	2026-08-04 09:10:00+10	4	5	9
67	2026-08-04 09:17:00+10	8	6	14
67	2026-08-04 09:24:00+10	4	11	15
67	2026-08-04 09:27:00+10	4	9	13
67	2026-08-04 09:28:00+10	4	11	15
67	2026-08-04 09:30:00+10	6	8	14
67	2026-08-04 09:31:00+10	6	3	9
67	2026-08-04 09:33:00+10	0	5	5
67	2026-08-04 09:36:00+10	2	7	9
67	2026-08-04 09:43:00+10	6	5	11
67	2026-08-04 09:44:00+10	5	1	6
67	2026-08-04 09:45:00+10	4	5	9
67	2026-08-04 09:52:00+10	13	13	26
67	2026-08-04 09:53:00+10	5	7	12
67	2026-08-04 09:54:00+10	11	2	13
67	2026-08-04 09:55:00+10	2	7	9
67	2026-08-04 09:56:00+10	4	4	8
67	2026-08-04 09:59:00+10	9	9	18
67	2026-08-04 10:02:00+10	5	1	6
67	2026-08-04 10:03:00+10	6	2	8
67	2026-08-04 10:05:00+10	7	5	12
67	2026-08-04 10:07:00+10	4	11	15
67	2026-08-04 10:08:00+10	2	6	8
67	2026-08-04 10:10:00+10	2	3	5
67	2026-08-04 10:11:00+10	0	6	6
67	2026-08-04 10:14:00+10	0	7	7
67	2026-08-04 10:17:00+10	1	6	7
67	2026-08-04 10:20:00+10	3	2	5
67	2026-08-04 10:34:00+10	5	1	6
67	2026-08-04 10:35:00+10	1	3	4
67	2026-08-04 10:42:00+10	5	2	7
67	2026-08-04 10:43:00+10	4	7	11
67	2026-08-04 10:47:00+10	6	3	9
67	2026-08-04 10:48:00+10	6	11	17
67	2026-08-04 10:50:00+10	2	8	10
67	2026-08-04 10:51:00+10	9	4	13
67	2026-08-04 10:52:00+10	7	8	15
67	2026-08-04 10:54:00+10	8	8	16
67	2026-08-04 10:57:00+10	8	6	14
67	2026-08-04 11:04:00+10	2	2	4
67	2026-08-04 11:05:00+10	7	7	14
67	2026-08-04 11:11:00+10	12	8	20
67	2026-08-04 11:14:00+10	4	7	11
67	2026-08-04 11:15:00+10	6	6	12
67	2026-08-04 11:16:00+10	2	4	6
67	2026-08-04 11:18:00+10	11	4	15
67	2026-08-04 11:22:00+10	4	7	11
67	2026-08-04 11:23:00+10	8	4	12
67	2026-08-04 11:24:00+10	4	3	7
67	2026-08-04 11:26:00+10	5	3	8
67	2026-08-04 11:29:00+10	3	8	11
67	2026-08-04 11:32:00+10	4	9	13
67	2026-08-04 11:33:00+10	2	5	7
67	2026-08-04 11:35:00+10	6	3	9
67	2026-08-04 11:40:00+10	7	4	11
67	2026-08-04 11:42:00+10	2	5	7
67	2026-08-04 11:44:00+10	9	4	13
67	2026-08-04 11:46:00+10	3	3	6
67	2026-08-04 11:51:00+10	3	4	7
67	2026-08-04 11:52:00+10	8	5	13
67	2026-08-04 11:53:00+10	5	5	10
67	2026-08-04 11:54:00+10	2	1	3
67	2026-08-04 12:04:00+10	7	4	11
67	2026-08-04 12:08:00+10	9	7	16
67	2026-08-04 12:12:00+10	8	2	10
67	2026-08-04 12:13:00+10	9	5	14
67	2026-08-04 12:14:00+10	6	8	14
67	2026-08-04 12:17:00+10	3	6	9
67	2026-08-04 12:18:00+10	10	11	21
67	2026-08-04 12:20:00+10	6	6	12
67	2026-08-04 12:24:00+10	16	5	21
67	2026-08-04 12:26:00+10	2	6	8
67	2026-08-04 12:30:00+10	14	7	21
67	2026-08-04 12:31:00+10	9	8	17
67	2026-08-04 12:34:00+10	9	6	15
67	2026-08-04 12:38:00+10	10	6	16
67	2026-08-04 12:39:00+10	4	9	13
67	2026-08-04 12:41:00+10	15	12	27
67	2026-08-04 12:43:00+10	8	6	14
67	2026-08-04 12:48:00+10	11	4	15
67	2026-08-04 12:49:00+10	13	10	23
67	2026-08-04 12:50:00+10	8	8	16
67	2026-08-04 12:52:00+10	3	4	7
67	2026-08-04 12:56:00+10	11	12	23
67	2026-08-04 12:59:00+10	5	11	16
67	2026-08-04 13:00:00+10	9	16	25
67	2026-08-04 13:02:00+10	4	12	16
67	2026-08-04 13:03:00+10	17	6	23
67	2026-08-04 13:08:00+10	2	14	16
67	2026-08-04 13:11:00+10	13	14	27
67	2026-08-04 13:20:00+10	7	13	20
67	2026-08-04 13:25:00+10	6	7	13
67	2026-08-04 13:26:00+10	10	17	27
67	2026-08-04 13:29:00+10	3	8	11
67	2026-08-04 13:38:00+10	5	23	28
67	2026-08-04 13:39:00+10	6	5	11
67	2026-08-04 13:40:00+10	5	7	12
67	2026-08-04 13:49:00+10	3	5	8
67	2026-08-04 13:52:00+10	2	5	7
67	2026-08-04 13:55:00+10	6	7	13
67	2026-08-04 14:01:00+10	3	9	12
67	2026-08-04 14:02:00+10	6	15	21
67	2026-08-04 14:03:00+10	15	8	23
67	2026-08-04 14:06:00+10	6	4	10
67	2026-08-04 14:07:00+10	6	5	11
67	2026-08-04 14:12:00+10	9	8	17
67	2026-08-04 14:14:00+10	4	12	16
67	2026-08-04 14:15:00+10	8	6	14
67	2026-08-04 14:17:00+10	13	7	20
67	2026-08-04 14:18:00+10	5	6	11
67	2026-08-04 14:20:00+10	14	6	20
67	2026-08-04 14:23:00+10	6	2	8
67	2026-08-04 14:27:00+10	3	8	11
67	2026-08-04 14:31:00+10	1	8	9
67	2026-08-04 14:33:00+10	4	4	8
67	2026-08-04 14:35:00+10	4	6	10
67	2026-08-04 14:36:00+10	3	16	19
67	2026-08-04 14:38:00+10	9	11	20
67	2026-08-04 14:39:00+10	4	4	8
68	2026-08-04 00:03:00+10	0	1	1
68	2026-08-04 00:26:00+10	1	0	1
68	2026-08-04 01:36:00+10	1	0	1
68	2026-08-04 01:46:00+10	2	0	2
68	2026-08-04 02:32:00+10	1	0	1
68	2026-08-04 06:00:00+10	1	1	2
68	2026-08-04 06:17:00+10	2	1	3
68	2026-08-04 06:49:00+10	1	0	1
68	2026-08-04 06:55:00+10	1	0	1
68	2026-08-04 06:58:00+10	1	0	1
68	2026-08-04 07:01:00+10	1	1	2
68	2026-08-04 07:04:00+10	1	0	1
68	2026-08-04 07:05:00+10	1	1	2
68	2026-08-04 07:13:00+10	2	2	4
68	2026-08-04 07:25:00+10	2	1	3
68	2026-08-04 07:28:00+10	2	2	4
68	2026-08-04 07:32:00+10	0	1	1
68	2026-08-04 07:37:00+10	1	1	2
68	2026-08-04 07:39:00+10	1	0	1
68	2026-08-04 07:41:00+10	2	4	6
68	2026-08-04 07:46:00+10	1	2	3
68	2026-08-04 07:47:00+10	3	3	6
68	2026-08-04 07:51:00+10	2	5	7
68	2026-08-04 07:56:00+10	1	4	5
68	2026-08-04 08:01:00+10	2	4	6
68	2026-08-04 08:04:00+10	1	7	8
68	2026-08-04 08:05:00+10	3	5	8
68	2026-08-04 08:13:00+10	3	2	5
68	2026-08-04 08:15:00+10	3	10	13
68	2026-08-04 08:16:00+10	3	6	9
68	2026-08-04 08:21:00+10	3	4	7
68	2026-08-04 08:23:00+10	2	10	12
68	2026-08-04 08:31:00+10	7	6	13
68	2026-08-04 08:32:00+10	4	4	8
68	2026-08-04 08:36:00+10	3	5	8
68	2026-08-04 08:39:00+10	2	4	6
68	2026-08-04 08:46:00+10	1	9	10
68	2026-08-04 08:49:00+10	4	7	11
68	2026-08-04 08:52:00+10	5	2	7
68	2026-08-04 08:59:00+10	5	5	10
68	2026-08-04 09:01:00+10	6	5	11
68	2026-08-04 09:06:00+10	3	7	10
68	2026-08-04 09:12:00+10	3	3	6
68	2026-08-04 09:14:00+10	2	2	4
68	2026-08-04 09:16:00+10	1	7	8
68	2026-08-04 09:18:00+10	0	6	6
68	2026-08-04 09:19:00+10	5	2	7
68	2026-08-04 09:22:00+10	3	2	5
68	2026-08-04 09:24:00+10	5	7	12
68	2026-08-04 09:25:00+10	0	5	5
68	2026-08-04 09:26:00+10	3	4	7
68	2026-08-04 09:27:00+10	4	2	6
68	2026-08-04 09:28:00+10	4	4	8
68	2026-08-04 09:29:00+10	4	4	8
68	2026-08-04 09:33:00+10	3	2	5
68	2026-08-04 09:37:00+10	2	7	9
68	2026-08-04 09:38:00+10	3	6	9
68	2026-08-04 09:42:00+10	4	11	15
68	2026-08-04 09:43:00+10	5	6	11
68	2026-08-04 09:44:00+10	1	1	2
68	2026-08-04 09:48:00+10	2	6	8
68	2026-08-04 09:50:00+10	2	9	11
68	2026-08-04 09:53:00+10	2	2	4
68	2026-08-04 09:56:00+10	1	1	2
68	2026-08-04 09:57:00+10	2	4	6
68	2026-08-04 09:58:00+10	7	6	13
68	2026-08-04 09:59:00+10	4	2	6
68	2026-08-04 10:00:00+10	4	5	9
68	2026-08-04 10:03:00+10	2	5	7
68	2026-08-04 10:04:00+10	2	3	5
68	2026-08-04 10:09:00+10	4	2	6
68	2026-08-04 10:10:00+10	5	3	8
68	2026-08-04 10:13:00+10	3	1	4
68	2026-08-04 10:15:00+10	1	2	3
68	2026-08-04 10:16:00+10	5	2	7
68	2026-08-04 10:19:00+10	4	1	5
68	2026-08-04 10:25:00+10	2	1	3
68	2026-08-04 10:29:00+10	3	2	5
68	2026-08-04 10:34:00+10	3	1	4
68	2026-08-04 10:36:00+10	2	5	7
68	2026-08-04 10:37:00+10	1	3	4
68	2026-08-04 10:48:00+10	2	4	6
68	2026-08-04 10:49:00+10	4	3	7
68	2026-08-04 10:51:00+10	4	5	9
68	2026-08-04 10:54:00+10	1	5	6
68	2026-08-04 10:55:00+10	3	2	5
68	2026-08-04 10:58:00+10	2	3	5
68	2026-08-04 10:59:00+10	2	3	5
68	2026-08-04 11:05:00+10	1	5	6
68	2026-08-04 11:08:00+10	2	4	6
68	2026-08-04 11:09:00+10	2	2	4
68	2026-08-04 11:14:00+10	1	5	6
68	2026-08-04 11:15:00+10	2	5	7
68	2026-08-04 11:17:00+10	0	4	4
68	2026-08-04 11:20:00+10	1	4	5
68	2026-08-04 11:26:00+10	3	3	6
68	2026-08-04 11:30:00+10	7	2	9
68	2026-08-04 11:31:00+10	0	5	5
68	2026-08-04 11:36:00+10	5	1	6
68	2026-08-04 11:37:00+10	7	1	8
68	2026-08-04 11:45:00+10	1	4	5
68	2026-08-04 11:46:00+10	4	3	7
68	2026-08-04 11:47:00+10	4	1	5
68	2026-08-04 11:58:00+10	2	2	4
68	2026-08-04 12:00:00+10	1	5	6
68	2026-08-04 12:03:00+10	1	2	3
68	2026-08-04 12:07:00+10	8	5	13
68	2026-08-04 12:15:00+10	5	2	7
68	2026-08-04 12:17:00+10	7	11	18
68	2026-08-04 12:22:00+10	5	4	9
68	2026-08-04 12:25:00+10	6	3	9
68	2026-08-04 12:26:00+10	4	5	9
68	2026-08-04 12:29:00+10	6	6	12
68	2026-08-04 12:32:00+10	8	13	21
68	2026-08-04 12:33:00+10	5	7	12
68	2026-08-04 12:36:00+10	5	9	14
68	2026-08-04 12:41:00+10	12	6	18
68	2026-08-04 12:43:00+10	6	11	17
68	2026-08-04 12:49:00+10	4	4	8
68	2026-08-04 13:00:00+10	11	13	24
68	2026-08-04 13:01:00+10	12	9	21
68	2026-08-04 13:05:00+10	8	6	14
68	2026-08-04 13:07:00+10	18	11	29
68	2026-08-04 13:11:00+10	16	11	27
68	2026-08-04 13:14:00+10	9	6	15
68	2026-08-04 13:20:00+10	6	6	12
68	2026-08-04 13:30:00+10	7	9	16
68	2026-08-04 13:33:00+10	3	9	12
68	2026-08-04 13:36:00+10	13	8	21
68	2026-08-04 13:40:00+10	7	5	12
68	2026-08-04 13:41:00+10	3	5	8
68	2026-08-04 13:42:00+10	3	1	4
68	2026-08-04 13:44:00+10	4	1	5
68	2026-08-04 13:47:00+10	7	7	14
68	2026-08-04 13:49:00+10	6	4	10
68	2026-08-04 13:50:00+10	10	7	17
68	2026-08-04 13:56:00+10	7	2	9
68	2026-08-04 13:57:00+10	1	8	9
68	2026-08-04 14:01:00+10	9	5	14
68	2026-08-04 14:02:00+10	5	10	15
68	2026-08-04 14:04:00+10	6	6	12
68	2026-08-04 14:05:00+10	4	1	5
68	2026-08-04 14:06:00+10	10	8	18
68	2026-08-04 14:09:00+10	8	4	12
68	2026-08-04 14:11:00+10	7	8	15
68	2026-08-04 14:14:00+10	13	1	14
68	2026-08-04 14:15:00+10	6	6	12
68	2026-08-04 14:17:00+10	7	4	11
68	2026-08-04 14:18:00+10	8	8	16
68	2026-08-04 14:21:00+10	3	2	5
68	2026-08-04 14:39:00+10	3	5	8
69	2026-08-04 00:40:00+10	1	0	1
69	2026-08-04 01:17:00+10	2	0	2
69	2026-08-04 01:37:00+10	0	2	2
69	2026-08-04 05:57:00+10	0	1	1
69	2026-08-04 06:01:00+10	1	1	2
69	2026-08-04 06:06:00+10	1	0	1
69	2026-08-04 06:18:00+10	3	0	3
69	2026-08-04 06:20:00+10	1	1	2
69	2026-08-04 06:51:00+10	1	0	1
69	2026-08-04 06:56:00+10	0	1	1
69	2026-08-04 07:00:00+10	3	0	3
69	2026-08-04 07:02:00+10	2	0	2
69	2026-08-04 07:03:00+10	1	0	1
69	2026-08-04 07:06:00+10	3	0	3
69	2026-08-04 07:07:00+10	1	0	1
69	2026-08-04 07:08:00+10	0	1	1
69	2026-08-04 07:21:00+10	3	0	3
69	2026-08-04 07:24:00+10	4	1	5
69	2026-08-04 07:26:00+10	1	0	1
69	2026-08-04 07:27:00+10	1	0	1
69	2026-08-04 07:30:00+10	1	0	1
69	2026-08-04 07:31:00+10	1	0	1
69	2026-08-04 07:33:00+10	5	0	5
69	2026-08-04 07:34:00+10	4	0	4
69	2026-08-04 07:44:00+10	7	1	8
69	2026-08-04 07:47:00+10	2	1	3
69	2026-08-04 07:48:00+10	2	1	3
69	2026-08-04 07:49:00+10	3	2	5
69	2026-08-04 07:52:00+10	7	2	9
69	2026-08-04 07:54:00+10	10	0	10
69	2026-08-04 07:56:00+10	3	0	3
69	2026-08-04 07:57:00+10	16	1	17
69	2026-08-04 07:58:00+10	6	2	8
69	2026-08-04 07:59:00+10	2	0	2
69	2026-08-04 08:01:00+10	2	0	2
69	2026-08-04 08:02:00+10	5	0	5
69	2026-08-04 08:04:00+10	5	3	8
69	2026-08-04 08:12:00+10	13	1	14
69	2026-08-04 08:14:00+10	6	0	6
69	2026-08-04 08:17:00+10	3	2	5
69	2026-08-04 08:25:00+10	11	2	13
69	2026-08-04 08:37:00+10	7	1	8
69	2026-08-04 08:43:00+10	8	0	8
69	2026-08-04 08:46:00+10	11	1	12
69	2026-08-04 08:48:00+10	15	2	17
69	2026-08-04 08:50:00+10	2	3	5
69	2026-08-04 08:53:00+10	9	2	11
69	2026-08-04 08:54:00+10	12	0	12
69	2026-08-04 08:55:00+10	16	1	17
69	2026-08-04 08:59:00+10	16	4	20
69	2026-08-04 09:01:00+10	13	2	15
69	2026-08-04 09:04:00+10	10	2	12
69	2026-08-04 09:05:00+10	4	2	6
69	2026-08-04 09:08:00+10	0	1	1
69	2026-08-04 09:09:00+10	18	5	23
69	2026-08-04 09:10:00+10	4	1	5
69	2026-08-04 09:12:00+10	5	2	7
69	2026-08-04 09:13:00+10	6	5	11
69	2026-08-04 09:16:00+10	5	1	6
69	2026-08-04 09:19:00+10	5	2	7
69	2026-08-04 09:22:00+10	4	1	5
69	2026-08-04 09:23:00+10	3	0	3
69	2026-08-04 09:24:00+10	7	4	11
69	2026-08-04 09:26:00+10	5	2	7
69	2026-08-04 09:28:00+10	5	0	5
69	2026-08-04 09:31:00+10	3	0	3
69	2026-08-04 09:34:00+10	1	1	2
69	2026-08-04 09:35:00+10	3	1	4
69	2026-08-04 09:37:00+10	7	1	8
69	2026-08-04 09:40:00+10	2	0	2
69	2026-08-04 09:43:00+10	3	1	4
69	2026-08-04 09:48:00+10	6	2	8
69	2026-08-04 09:50:00+10	2	2	4
69	2026-08-04 09:52:00+10	3	2	5
69	2026-08-04 09:53:00+10	3	4	7
69	2026-08-04 10:13:00+10	7	0	7
69	2026-08-04 10:19:00+10	5	5	10
69	2026-08-04 10:20:00+10	6	1	7
69	2026-08-04 10:22:00+10	0	2	2
69	2026-08-04 10:26:00+10	6	1	7
69	2026-08-04 10:27:00+10	2	2	4
69	2026-08-04 10:29:00+10	1	1	2
69	2026-08-04 10:33:00+10	1	3	4
69	2026-08-04 10:42:00+10	0	6	6
69	2026-08-04 10:47:00+10	6	4	10
69	2026-08-04 10:48:00+10	4	1	5
69	2026-08-04 10:49:00+10	1	1	2
69	2026-08-04 10:51:00+10	7	2	9
69	2026-08-04 10:55:00+10	1	7	8
69	2026-08-04 10:57:00+10	0	1	1
69	2026-08-04 10:58:00+10	10	0	10
69	2026-08-04 11:00:00+10	2	2	4
69	2026-08-04 11:04:00+10	7	4	11
69	2026-08-04 11:07:00+10	4	1	5
69	2026-08-04 11:08:00+10	2	11	13
69	2026-08-04 11:09:00+10	1	0	1
69	2026-08-04 11:13:00+10	1	3	4
69	2026-08-04 11:14:00+10	3	2	5
69	2026-08-04 11:15:00+10	5	4	9
69	2026-08-04 11:20:00+10	2	3	5
69	2026-08-04 11:24:00+10	2	5	7
69	2026-08-04 11:28:00+10	6	1	7
69	2026-08-04 11:31:00+10	4	1	5
69	2026-08-04 11:32:00+10	5	2	7
69	2026-08-04 11:38:00+10	7	1	8
69	2026-08-04 11:39:00+10	1	4	5
69	2026-08-04 11:40:00+10	2	1	3
69	2026-08-04 11:41:00+10	3	3	6
69	2026-08-04 11:43:00+10	3	1	4
69	2026-08-04 11:45:00+10	3	4	7
69	2026-08-04 11:46:00+10	3	1	4
69	2026-08-04 11:47:00+10	2	5	7
69	2026-08-04 11:48:00+10	3	4	7
69	2026-08-04 11:49:00+10	4	3	7
69	2026-08-04 11:50:00+10	4	2	6
69	2026-08-04 11:51:00+10	5	0	5
69	2026-08-04 11:55:00+10	0	3	3
69	2026-08-04 11:58:00+10	5	1	6
69	2026-08-04 11:59:00+10	1	1	2
69	2026-08-04 12:05:00+10	2	1	3
69	2026-08-04 12:10:00+10	5	11	16
69	2026-08-04 12:12:00+10	0	7	7
69	2026-08-04 12:13:00+10	2	4	6
69	2026-08-04 12:16:00+10	3	2	5
69	2026-08-04 12:17:00+10	4	8	12
69	2026-08-04 12:18:00+10	4	6	10
69	2026-08-04 12:21:00+10	5	7	12
69	2026-08-04 12:22:00+10	7	3	10
69	2026-08-04 12:26:00+10	2	5	7
69	2026-08-04 12:28:00+10	4	3	7
69	2026-08-04 12:41:00+10	6	1	7
69	2026-08-04 12:43:00+10	7	3	10
69	2026-08-04 12:44:00+10	12	4	16
69	2026-08-04 12:50:00+10	4	7	11
69	2026-08-04 12:52:00+10	5	3	8
69	2026-08-04 12:53:00+10	2	10	12
69	2026-08-04 12:59:00+10	7	4	11
69	2026-08-04 13:04:00+10	6	7	13
69	2026-08-04 13:05:00+10	1	11	12
69	2026-08-04 13:07:00+10	9	8	17
69	2026-08-04 13:08:00+10	4	4	8
69	2026-08-04 13:10:00+10	2	13	15
69	2026-08-04 13:12:00+10	9	18	27
69	2026-08-04 13:19:00+10	1	7	8
69	2026-08-04 13:20:00+10	4	2	6
69	2026-08-04 13:21:00+10	3	2	5
69	2026-08-04 13:23:00+10	4	3	7
69	2026-08-04 13:24:00+10	2	5	7
69	2026-08-04 13:26:00+10	5	4	9
69	2026-08-04 13:28:00+10	6	2	8
69	2026-08-04 13:33:00+10	5	5	10
69	2026-08-04 13:34:00+10	3	2	5
69	2026-08-04 13:38:00+10	3	3	6
69	2026-08-04 13:40:00+10	4	1	5
69	2026-08-04 13:44:00+10	4	4	8
69	2026-08-04 13:45:00+10	2	4	6
69	2026-08-04 13:47:00+10	4	5	9
69	2026-08-04 13:49:00+10	3	2	5
69	2026-08-04 13:51:00+10	1	3	4
69	2026-08-04 13:58:00+10	2	5	7
69	2026-08-04 14:01:00+10	8	2	10
69	2026-08-04 14:05:00+10	6	4	10
69	2026-08-04 14:07:00+10	3	7	10
69	2026-08-04 14:08:00+10	11	3	14
69	2026-08-04 14:11:00+10	1	5	6
69	2026-08-04 14:12:00+10	3	4	7
69	2026-08-04 14:13:00+10	6	11	17
69	2026-08-04 14:14:00+10	5	3	8
69	2026-08-04 14:15:00+10	8	8	16
69	2026-08-04 14:18:00+10	1	7	8
69	2026-08-04 14:26:00+10	4	3	7
69	2026-08-04 14:29:00+10	6	4	10
69	2026-08-04 14:31:00+10	6	3	9
69	2026-08-04 14:34:00+10	1	4	5
69	2026-08-04 14:36:00+10	1	1	2
69	2026-08-04 14:37:00+10	1	5	6
69	2026-08-04 14:39:00+10	0	3	3
70	2026-08-04 01:04:00+10	1	1	2
70	2026-08-04 06:40:00+10	0	1	1
70	2026-08-04 06:46:00+10	1	0	1
70	2026-08-04 06:52:00+10	1	0	1
70	2026-08-04 06:55:00+10	0	1	1
70	2026-08-04 07:11:00+10	0	1	1
70	2026-08-04 07:14:00+10	1	0	1
70	2026-08-04 07:17:00+10	0	1	1
70	2026-08-04 07:23:00+10	1	0	1
70	2026-08-04 07:28:00+10	0	1	1
70	2026-08-04 07:31:00+10	0	1	1
70	2026-08-04 07:45:00+10	0	1	1
70	2026-08-04 07:48:00+10	1	3	4
70	2026-08-04 07:49:00+10	0	1	1
70	2026-08-04 07:55:00+10	0	1	1
70	2026-08-04 07:56:00+10	0	2	2
70	2026-08-04 07:57:00+10	1	1	2
70	2026-08-04 07:59:00+10	1	0	1
70	2026-08-04 08:01:00+10	3	1	4
70	2026-08-04 08:03:00+10	2	1	3
70	2026-08-04 08:16:00+10	1	1	2
70	2026-08-04 08:20:00+10	0	1	1
70	2026-08-04 08:28:00+10	1	0	1
70	2026-08-04 08:29:00+10	1	2	3
70	2026-08-04 08:33:00+10	0	1	1
70	2026-08-04 08:34:00+10	1	2	3
70	2026-08-04 08:35:00+10	1	0	1
70	2026-08-04 08:39:00+10	2	0	2
70	2026-08-04 08:40:00+10	3	0	3
70	2026-08-04 08:41:00+10	1	1	2
70	2026-08-04 08:43:00+10	3	0	3
70	2026-08-04 08:44:00+10	4	2	6
70	2026-08-04 08:46:00+10	5	1	6
70	2026-08-04 08:49:00+10	0	4	4
70	2026-08-04 08:50:00+10	2	2	4
70	2026-08-04 08:54:00+10	1	0	1
70	2026-08-04 08:55:00+10	3	0	3
70	2026-08-04 08:58:00+10	0	6	6
70	2026-08-04 09:01:00+10	5	2	7
70	2026-08-04 09:02:00+10	1	0	1
70	2026-08-04 09:03:00+10	0	1	1
70	2026-08-04 09:08:00+10	2	1	3
70	2026-08-04 09:09:00+10	0	1	1
70	2026-08-04 09:13:00+10	1	0	1
70	2026-08-04 09:15:00+10	1	1	2
70	2026-08-04 09:20:00+10	3	0	3
70	2026-08-04 09:21:00+10	2	0	2
70	2026-08-04 09:25:00+10	0	1	1
70	2026-08-04 09:28:00+10	0	3	3
70	2026-08-04 09:37:00+10	1	1	2
70	2026-08-04 09:48:00+10	1	0	1
70	2026-08-04 09:55:00+10	2	0	2
70	2026-08-04 09:57:00+10	2	0	2
70	2026-08-04 09:58:00+10	0	2	2
70	2026-08-04 09:59:00+10	1	1	2
70	2026-08-04 10:00:00+10	1	5	6
70	2026-08-04 10:08:00+10	2	4	6
70	2026-08-04 10:17:00+10	5	2	7
70	2026-08-04 10:20:00+10	1	2	3
70	2026-08-04 10:22:00+10	0	2	2
70	2026-08-04 10:28:00+10	2	3	5
70	2026-08-04 10:31:00+10	2	0	2
70	2026-08-04 10:32:00+10	0	1	1
70	2026-08-04 10:36:00+10	1	0	1
70	2026-08-04 10:37:00+10	0	4	4
70	2026-08-04 10:39:00+10	1	0	1
70	2026-08-04 10:40:00+10	1	0	1
70	2026-08-04 10:42:00+10	1	1	2
70	2026-08-04 10:45:00+10	2	1	3
70	2026-08-04 10:47:00+10	3	0	3
70	2026-08-04 10:48:00+10	1	1	2
70	2026-08-04 10:49:00+10	2	0	2
70	2026-08-04 10:52:00+10	5	1	6
70	2026-08-04 11:02:00+10	0	5	5
70	2026-08-04 11:05:00+10	4	3	7
70	2026-08-04 11:13:00+10	0	1	1
70	2026-08-04 11:16:00+10	2	2	4
70	2026-08-04 11:17:00+10	3	2	5
70	2026-08-04 11:19:00+10	1	1	2
70	2026-08-04 11:21:00+10	1	0	1
70	2026-08-04 11:24:00+10	1	2	3
70	2026-08-04 11:25:00+10	1	0	1
70	2026-08-04 11:33:00+10	0	2	2
70	2026-08-04 11:35:00+10	0	2	2
70	2026-08-04 11:42:00+10	0	2	2
70	2026-08-04 11:47:00+10	0	1	1
70	2026-08-04 11:51:00+10	5	0	5
70	2026-08-04 11:54:00+10	0	2	2
70	2026-08-04 11:57:00+10	1	1	2
70	2026-08-04 11:58:00+10	3	4	7
70	2026-08-04 12:03:00+10	0	2	2
70	2026-08-04 12:06:00+10	3	3	6
70	2026-08-04 12:08:00+10	1	5	6
70	2026-08-04 12:10:00+10	4	0	4
70	2026-08-04 12:12:00+10	2	0	2
70	2026-08-04 12:15:00+10	2	3	5
70	2026-08-04 12:16:00+10	3	1	4
70	2026-08-04 12:20:00+10	2	4	6
70	2026-08-04 12:21:00+10	1	1	2
70	2026-08-04 12:23:00+10	1	1	2
70	2026-08-04 12:24:00+10	6	1	7
70	2026-08-04 12:28:00+10	1	5	6
70	2026-08-04 12:29:00+10	4	1	5
70	2026-08-04 12:32:00+10	2	1	3
70	2026-08-04 12:33:00+10	1	1	2
70	2026-08-04 12:34:00+10	0	1	1
70	2026-08-04 12:35:00+10	3	1	4
70	2026-08-04 12:36:00+10	5	2	7
70	2026-08-04 12:39:00+10	6	1	7
70	2026-08-04 12:40:00+10	3	2	5
70	2026-08-04 12:42:00+10	0	3	3
70	2026-08-04 12:43:00+10	1	2	3
70	2026-08-04 12:45:00+10	4	2	6
70	2026-08-04 12:47:00+10	2	0	2
70	2026-08-04 12:55:00+10	2	4	6
70	2026-08-04 12:56:00+10	3	1	4
70	2026-08-04 12:57:00+10	7	8	15
70	2026-08-04 12:58:00+10	5	2	7
70	2026-08-04 12:59:00+10	1	2	3
70	2026-08-04 13:01:00+10	1	0	1
70	2026-08-04 13:05:00+10	5	3	8
70	2026-08-04 13:07:00+10	0	7	7
70	2026-08-04 13:13:00+10	4	5	9
70	2026-08-04 13:17:00+10	1	1	2
70	2026-08-04 13:21:00+10	2	1	3
70	2026-08-04 13:29:00+10	1	2	3
70	2026-08-04 13:33:00+10	4	2	6
70	2026-08-04 13:36:00+10	1	4	5
70	2026-08-04 13:47:00+10	2	0	2
70	2026-08-04 13:48:00+10	2	1	3
70	2026-08-04 13:49:00+10	0	2	2
70	2026-08-04 13:53:00+10	1	3	4
70	2026-08-04 13:56:00+10	2	1	3
70	2026-08-04 13:59:00+10	0	1	1
70	2026-08-04 14:01:00+10	0	1	1
70	2026-08-04 14:03:00+10	0	1	1
70	2026-08-04 14:06:00+10	4	2	6
70	2026-08-04 14:07:00+10	0	3	3
70	2026-08-04 14:09:00+10	5	3	8
70	2026-08-04 14:10:00+10	0	2	2
70	2026-08-04 14:13:00+10	1	1	2
70	2026-08-04 14:14:00+10	1	1	2
70	2026-08-04 14:21:00+10	2	1	3
70	2026-08-04 14:26:00+10	5	0	5
70	2026-08-04 14:29:00+10	0	4	4
70	2026-08-04 14:34:00+10	1	1	2
71	2026-08-04 00:00:00+10	2	0	2
71	2026-08-04 06:36:00+10	1	0	1
71	2026-08-04 06:51:00+10	1	1	2
71	2026-08-04 06:59:00+10	1	0	1
71	2026-08-04 07:00:00+10	0	1	1
71	2026-08-04 07:03:00+10	0	1	1
71	2026-08-04 07:12:00+10	1	0	1
71	2026-08-04 07:13:00+10	0	2	2
71	2026-08-04 07:17:00+10	1	0	1
71	2026-08-04 07:50:00+10	1	1	2
71	2026-08-04 07:51:00+10	1	0	1
71	2026-08-04 07:53:00+10	0	1	1
71	2026-08-04 08:05:00+10	0	1	1
71	2026-08-04 08:06:00+10	2	0	2
71	2026-08-04 08:12:00+10	1	0	1
71	2026-08-04 08:13:00+10	1	0	1
71	2026-08-04 08:15:00+10	0	1	1
71	2026-08-04 08:17:00+10	1	0	1
71	2026-08-04 08:20:00+10	0	1	1
71	2026-08-04 08:21:00+10	1	0	1
71	2026-08-04 08:23:00+10	0	1	1
71	2026-08-04 08:30:00+10	0	1	1
71	2026-08-04 08:31:00+10	1	0	1
71	2026-08-04 08:34:00+10	0	1	1
71	2026-08-04 08:39:00+10	1	1	2
71	2026-08-04 08:55:00+10	0	1	1
71	2026-08-04 08:56:00+10	1	1	2
71	2026-08-04 08:59:00+10	2	0	2
71	2026-08-04 09:00:00+10	1	2	3
71	2026-08-04 09:01:00+10	2	0	2
71	2026-08-04 09:04:00+10	1	0	1
71	2026-08-04 09:14:00+10	1	1	2
71	2026-08-04 09:18:00+10	2	0	2
71	2026-08-04 09:21:00+10	1	0	1
71	2026-08-04 09:24:00+10	1	0	1
71	2026-08-04 09:26:00+10	1	0	1
71	2026-08-04 09:33:00+10	1	0	1
71	2026-08-04 09:53:00+10	0	1	1
71	2026-08-04 09:59:00+10	0	1	1
71	2026-08-04 10:00:00+10	2	0	2
71	2026-08-04 10:06:00+10	1	0	1
71	2026-08-04 10:07:00+10	0	1	1
71	2026-08-04 10:10:00+10	1	0	1
71	2026-08-04 10:12:00+10	1	0	1
71	2026-08-04 10:30:00+10	0	1	1
71	2026-08-04 10:39:00+10	3	1	4
71	2026-08-04 10:47:00+10	0	1	1
71	2026-08-04 10:53:00+10	0	1	1
71	2026-08-04 11:08:00+10	1	0	1
71	2026-08-04 11:11:00+10	2	0	2
71	2026-08-04 11:12:00+10	0	2	2
71	2026-08-04 11:14:00+10	1	0	1
71	2026-08-04 11:17:00+10	1	1	2
71	2026-08-04 11:24:00+10	1	0	1
71	2026-08-04 11:27:00+10	1	0	1
71	2026-08-04 11:33:00+10	1	0	1
71	2026-08-04 11:36:00+10	0	1	1
71	2026-08-04 11:39:00+10	3	0	3
71	2026-08-04 11:40:00+10	3	0	3
71	2026-08-04 11:46:00+10	4	1	5
71	2026-08-04 11:48:00+10	1	1	2
71	2026-08-04 12:08:00+10	1	1	2
71	2026-08-04 12:12:00+10	2	1	3
71	2026-08-04 12:14:00+10	3	0	3
71	2026-08-04 12:18:00+10	0	5	5
71	2026-08-04 12:19:00+10	2	3	5
71	2026-08-04 12:22:00+10	0	1	1
71	2026-08-04 12:27:00+10	1	0	1
71	2026-08-04 12:29:00+10	0	1	1
71	2026-08-04 12:33:00+10	1	2	3
71	2026-08-04 12:34:00+10	1	0	1
71	2026-08-04 12:36:00+10	2	0	2
71	2026-08-04 12:39:00+10	2	1	3
71	2026-08-04 12:46:00+10	0	2	2
71	2026-08-04 12:48:00+10	1	1	2
71	2026-08-04 12:50:00+10	0	1	1
71	2026-08-04 12:51:00+10	1	1	2
71	2026-08-04 12:53:00+10	1	1	2
71	2026-08-04 13:03:00+10	2	0	2
71	2026-08-04 13:05:00+10	0	1	1
71	2026-08-04 13:10:00+10	0	2	2
71	2026-08-04 13:11:00+10	1	1	2
71	2026-08-04 13:13:00+10	1	0	1
71	2026-08-04 13:16:00+10	1	0	1
71	2026-08-04 13:20:00+10	0	1	1
71	2026-08-04 13:25:00+10	0	1	1
71	2026-08-04 13:39:00+10	1	0	1
71	2026-08-04 13:40:00+10	2	0	2
71	2026-08-04 13:41:00+10	3	1	4
71	2026-08-04 13:45:00+10	1	0	1
71	2026-08-04 13:51:00+10	1	1	2
71	2026-08-04 14:04:00+10	1	0	1
71	2026-08-04 14:05:00+10	0	3	3
71	2026-08-04 14:30:00+10	1	1	2
72	2026-08-04 00:01:00+10	3	0	3
72	2026-08-04 00:09:00+10	2	0	2
72	2026-08-04 03:03:00+10	1	0	1
72	2026-08-04 05:11:00+10	0	2	2
72	2026-08-04 05:33:00+10	0	1	1
72	2026-08-04 05:42:00+10	2	0	2
72	2026-08-04 05:44:00+10	3	0	3
72	2026-08-04 05:47:00+10	1	0	1
72	2026-08-04 05:48:00+10	0	1	1
72	2026-08-04 05:59:00+10	1	0	1
72	2026-08-04 06:05:00+10	0	1	1
72	2026-08-04 06:07:00+10	0	1	1
72	2026-08-04 06:17:00+10	0	1	1
72	2026-08-04 06:22:00+10	1	0	1
72	2026-08-04 06:27:00+10	1	0	1
72	2026-08-04 06:30:00+10	0	1	1
72	2026-08-04 06:32:00+10	0	1	1
72	2026-08-04 06:33:00+10	2	0	2
72	2026-08-04 06:36:00+10	2	0	2
72	2026-08-04 06:40:00+10	1	1	2
72	2026-08-04 06:41:00+10	1	0	1
72	2026-08-04 06:48:00+10	5	0	5
72	2026-08-04 06:50:00+10	2	0	2
72	2026-08-04 07:00:00+10	6	3	9
72	2026-08-04 07:03:00+10	1	0	1
72	2026-08-04 07:07:00+10	2	0	2
72	2026-08-04 07:20:00+10	1	0	1
72	2026-08-04 07:25:00+10	1	0	1
72	2026-08-04 07:32:00+10	8	1	9
72	2026-08-04 07:33:00+10	2	0	2
72	2026-08-04 07:34:00+10	1	2	3
72	2026-08-04 07:36:00+10	1	3	4
72	2026-08-04 07:45:00+10	0	1	1
72	2026-08-04 07:46:00+10	4	3	7
72	2026-08-04 07:48:00+10	4	0	4
72	2026-08-04 07:55:00+10	5	2	7
72	2026-08-04 07:58:00+10	12	1	13
72	2026-08-04 08:09:00+10	5	0	5
72	2026-08-04 08:10:00+10	1	0	1
72	2026-08-04 08:13:00+10	8	0	8
72	2026-08-04 08:15:00+10	12	0	12
72	2026-08-04 08:16:00+10	7	0	7
72	2026-08-04 08:19:00+10	7	1	8
72	2026-08-04 08:21:00+10	5	1	6
72	2026-08-04 08:23:00+10	8	0	8
72	2026-08-04 08:27:00+10	5	3	8
72	2026-08-04 08:33:00+10	7	6	13
72	2026-08-04 08:37:00+10	19	2	21
72	2026-08-04 08:38:00+10	3	2	5
72	2026-08-04 08:40:00+10	9	1	10
72	2026-08-04 08:44:00+10	9	1	10
72	2026-08-04 08:49:00+10	5	1	6
72	2026-08-04 08:50:00+10	3	3	6
72	2026-08-04 08:56:00+10	9	1	10
72	2026-08-04 08:57:00+10	7	1	8
72	2026-08-04 08:59:00+10	12	1	13
72	2026-08-04 09:01:00+10	2	0	2
72	2026-08-04 09:06:00+10	7	1	8
72	2026-08-04 09:08:00+10	3	1	4
72	2026-08-04 09:10:00+10	3	2	5
72	2026-08-04 09:17:00+10	3	0	3
72	2026-08-04 09:25:00+10	1	0	1
72	2026-08-04 09:27:00+10	7	0	7
72	2026-08-04 09:31:00+10	1	2	3
72	2026-08-04 09:40:00+10	0	2	2
72	2026-08-04 09:42:00+10	6	1	7
72	2026-08-04 09:45:00+10	2	0	2
72	2026-08-04 09:46:00+10	23	0	23
72	2026-08-04 09:48:00+10	8	2	10
72	2026-08-04 09:49:00+10	1	0	1
72	2026-08-04 09:50:00+10	4	1	5
72	2026-08-04 09:51:00+10	1	2	3
72	2026-08-04 09:52:00+10	0	2	2
72	2026-08-04 09:55:00+10	2	1	3
72	2026-08-04 10:00:00+10	1	2	3
72	2026-08-04 10:06:00+10	1	3	4
72	2026-08-04 10:09:00+10	1	0	1
72	2026-08-04 10:11:00+10	1	0	1
72	2026-08-04 10:12:00+10	1	0	1
72	2026-08-04 10:16:00+10	0	1	1
72	2026-08-04 10:18:00+10	5	0	5
72	2026-08-04 10:19:00+10	11	0	11
72	2026-08-04 10:21:00+10	1	0	1
72	2026-08-04 10:22:00+10	0	1	1
72	2026-08-04 10:23:00+10	7	0	7
72	2026-08-04 10:25:00+10	2	7	9
72	2026-08-04 10:31:00+10	2	0	2
72	2026-08-04 10:33:00+10	6	1	7
72	2026-08-04 10:35:00+10	2	0	2
72	2026-08-04 10:36:00+10	3	1	4
72	2026-08-04 10:42:00+10	0	1	1
72	2026-08-04 10:43:00+10	1	0	1
72	2026-08-04 10:54:00+10	2	7	9
72	2026-08-04 10:55:00+10	1	2	3
72	2026-08-04 10:56:00+10	2	3	5
72	2026-08-04 11:02:00+10	2	2	4
72	2026-08-04 11:05:00+10	2	1	3
72	2026-08-04 11:11:00+10	0	7	7
72	2026-08-04 11:16:00+10	4	1	5
72	2026-08-04 11:19:00+10	0	1	1
72	2026-08-04 11:22:00+10	4	1	5
72	2026-08-04 11:26:00+10	2	0	2
72	2026-08-04 11:29:00+10	8	0	8
72	2026-08-04 11:30:00+10	2	4	6
72	2026-08-04 11:33:00+10	0	1	1
72	2026-08-04 11:35:00+10	3	0	3
72	2026-08-04 11:39:00+10	0	1	1
72	2026-08-04 11:50:00+10	1	0	1
72	2026-08-04 11:52:00+10	0	1	1
72	2026-08-04 11:55:00+10	1	0	1
72	2026-08-04 12:04:00+10	0	2	2
72	2026-08-04 12:10:00+10	0	3	3
72	2026-08-04 12:14:00+10	1	1	2
72	2026-08-04 12:16:00+10	5	1	6
72	2026-08-04 12:18:00+10	0	1	1
72	2026-08-04 12:24:00+10	6	2	8
72	2026-08-04 12:29:00+10	0	2	2
72	2026-08-04 12:32:00+10	5	2	7
72	2026-08-04 12:34:00+10	0	5	5
72	2026-08-04 12:35:00+10	3	2	5
72	2026-08-04 12:36:00+10	4	14	18
72	2026-08-04 12:41:00+10	1	2	3
72	2026-08-04 12:44:00+10	2	2	4
72	2026-08-04 12:46:00+10	0	4	4
72	2026-08-04 12:47:00+10	2	1	3
72	2026-08-04 12:49:00+10	4	1	5
72	2026-08-04 12:50:00+10	3	5	8
72	2026-08-04 12:51:00+10	2	3	5
72	2026-08-04 12:58:00+10	2	2	4
72	2026-08-04 13:02:00+10	2	0	2
72	2026-08-04 13:06:00+10	0	1	1
72	2026-08-04 13:09:00+10	3	6	9
72	2026-08-04 13:13:00+10	1	4	5
72	2026-08-04 13:15:00+10	3	2	5
72	2026-08-04 13:18:00+10	1	6	7
72	2026-08-04 13:22:00+10	2	6	8
72	2026-08-04 13:23:00+10	7	6	13
72	2026-08-04 13:26:00+10	0	1	1
72	2026-08-04 13:27:00+10	1	2	3
72	2026-08-04 13:29:00+10	2	1	3
72	2026-08-04 13:31:00+10	1	0	1
72	2026-08-04 13:33:00+10	1	1	2
72	2026-08-04 13:34:00+10	1	3	4
72	2026-08-04 13:36:00+10	8	2	10
72	2026-08-04 13:38:00+10	2	0	2
72	2026-08-04 13:39:00+10	2	2	4
72	2026-08-04 13:42:00+10	0	3	3
72	2026-08-04 13:43:00+10	6	0	6
72	2026-08-04 13:50:00+10	5	2	7
72	2026-08-04 13:51:00+10	3	1	4
72	2026-08-04 13:58:00+10	3	6	9
72	2026-08-04 13:59:00+10	5	3	8
72	2026-08-04 14:05:00+10	1	1	2
72	2026-08-04 14:06:00+10	1	0	1
72	2026-08-04 14:11:00+10	6	1	7
72	2026-08-04 14:21:00+10	24	2	26
72	2026-08-04 14:23:00+10	2	4	6
72	2026-08-04 14:24:00+10	2	2	4
72	2026-08-04 14:27:00+10	0	3	3
72	2026-08-04 14:30:00+10	2	2	4
72	2026-08-04 14:35:00+10	0	1	1
75	2026-08-04 02:47:00+10	1	0	1
75	2026-08-04 05:24:00+10	0	1	1
75	2026-08-04 06:04:00+10	0	2	2
75	2026-08-04 06:15:00+10	0	1	1
75	2026-08-04 06:23:00+10	0	1	1
75	2026-08-04 06:31:00+10	0	1	1
75	2026-08-04 06:51:00+10	2	0	2
75	2026-08-04 06:57:00+10	1	0	1
75	2026-08-04 06:58:00+10	0	2	2
75	2026-08-04 06:59:00+10	1	0	1
75	2026-08-04 07:07:00+10	0	2	2
75	2026-08-04 07:08:00+10	1	1	2
75	2026-08-04 07:13:00+10	0	1	1
75	2026-08-04 07:17:00+10	1	0	1
75	2026-08-04 07:18:00+10	1	1	2
75	2026-08-04 07:21:00+10	1	2	3
75	2026-08-04 07:26:00+10	2	1	3
75	2026-08-04 07:27:00+10	1	0	1
75	2026-08-04 07:29:00+10	0	1	1
75	2026-08-04 07:31:00+10	0	1	1
75	2026-08-04 07:32:00+10	1	1	2
75	2026-08-04 07:33:00+10	0	2	2
75	2026-08-04 07:34:00+10	2	0	2
75	2026-08-04 07:38:00+10	0	2	2
75	2026-08-04 07:42:00+10	0	1	1
75	2026-08-04 07:45:00+10	9	1	10
75	2026-08-04 07:48:00+10	1	1	2
75	2026-08-04 07:49:00+10	0	1	1
75	2026-08-04 08:00:00+10	0	1	1
75	2026-08-04 08:28:00+10	0	1	1
75	2026-08-04 08:29:00+10	2	3	5
75	2026-08-04 08:33:00+10	1	1	2
75	2026-08-04 08:38:00+10	0	1	1
75	2026-08-04 08:40:00+10	2	1	3
75	2026-08-04 08:54:00+10	1	0	1
75	2026-08-04 08:57:00+10	2	0	2
75	2026-08-04 09:04:00+10	2	1	3
75	2026-08-04 09:09:00+10	1	0	1
75	2026-08-04 09:13:00+10	0	1	1
75	2026-08-04 09:24:00+10	2	1	3
75	2026-08-04 09:28:00+10	1	1	2
75	2026-08-04 09:29:00+10	0	1	1
75	2026-08-04 09:32:00+10	2	0	2
75	2026-08-04 09:39:00+10	1	0	1
75	2026-08-04 09:51:00+10	1	0	1
75	2026-08-04 09:54:00+10	0	1	1
75	2026-08-04 09:59:00+10	2	0	2
75	2026-08-04 10:15:00+10	0	1	1
75	2026-08-04 10:17:00+10	0	1	1
75	2026-08-04 10:37:00+10	0	1	1
75	2026-08-04 10:40:00+10	2	0	2
75	2026-08-04 10:45:00+10	1	0	1
75	2026-08-04 10:46:00+10	2	1	3
75	2026-08-04 10:47:00+10	2	1	3
75	2026-08-04 10:48:00+10	3	0	3
75	2026-08-04 10:49:00+10	2	0	2
75	2026-08-04 10:50:00+10	1	0	1
75	2026-08-04 10:51:00+10	1	0	1
75	2026-08-04 10:52:00+10	2	2	4
75	2026-08-04 10:57:00+10	2	0	2
75	2026-08-04 11:12:00+10	1	1	2
75	2026-08-04 11:17:00+10	3	0	3
75	2026-08-04 11:23:00+10	1	0	1
75	2026-08-04 11:24:00+10	0	1	1
75	2026-08-04 11:34:00+10	2	3	5
75	2026-08-04 11:41:00+10	0	4	4
75	2026-08-04 11:49:00+10	0	2	2
75	2026-08-04 11:50:00+10	2	0	2
75	2026-08-04 11:58:00+10	2	0	2
75	2026-08-04 12:13:00+10	0	3	3
75	2026-08-04 12:16:00+10	1	0	1
75	2026-08-04 12:24:00+10	0	1	1
75	2026-08-04 12:30:00+10	0	3	3
75	2026-08-04 12:32:00+10	1	0	1
75	2026-08-04 12:33:00+10	4	0	4
75	2026-08-04 12:34:00+10	0	2	2
75	2026-08-04 12:37:00+10	1	1	2
75	2026-08-04 12:41:00+10	1	5	6
75	2026-08-04 12:54:00+10	1	1	2
75	2026-08-04 12:59:00+10	5	1	6
75	2026-08-04 13:00:00+10	6	0	6
75	2026-08-04 13:07:00+10	0	1	1
75	2026-08-04 13:13:00+10	2	0	2
75	2026-08-04 13:17:00+10	1	3	4
75	2026-08-04 13:19:00+10	0	1	1
75	2026-08-04 13:22:00+10	1	1	2
75	2026-08-04 13:26:00+10	1	0	1
75	2026-08-04 13:32:00+10	0	1	1
75	2026-08-04 13:45:00+10	3	0	3
75	2026-08-04 13:57:00+10	0	2	2
75	2026-08-04 14:04:00+10	0	1	1
75	2026-08-04 14:06:00+10	0	2	2
75	2026-08-04 14:07:00+10	3	0	3
75	2026-08-04 14:08:00+10	1	0	1
75	2026-08-04 14:10:00+10	0	2	2
75	2026-08-04 14:14:00+10	1	0	1
75	2026-08-04 14:15:00+10	4	0	4
75	2026-08-04 14:21:00+10	0	2	2
75	2026-08-04 14:27:00+10	1	0	1
75	2026-08-04 14:28:00+10	2	2	4
75	2026-08-04 14:29:00+10	0	2	2
75	2026-08-04 14:32:00+10	1	1	2
76	2026-08-04 06:28:00+10	1	0	1
76	2026-08-04 06:37:00+10	0	1	1
76	2026-08-04 06:38:00+10	1	0	1
76	2026-08-04 06:41:00+10	1	1	2
76	2026-08-04 06:49:00+10	0	1	1
76	2026-08-04 06:55:00+10	1	0	1
76	2026-08-04 06:58:00+10	0	1	1
76	2026-08-04 07:01:00+10	1	5	6
76	2026-08-04 07:04:00+10	1	0	1
76	2026-08-04 07:09:00+10	1	0	1
76	2026-08-04 07:12:00+10	1	0	1
76	2026-08-04 07:21:00+10	1	0	1
76	2026-08-04 07:31:00+10	1	0	1
76	2026-08-04 07:41:00+10	1	1	2
76	2026-08-04 07:42:00+10	4	0	4
76	2026-08-04 07:44:00+10	1	1	2
76	2026-08-04 07:53:00+10	3	4	7
76	2026-08-04 07:57:00+10	1	0	1
76	2026-08-04 07:58:00+10	0	1	1
76	2026-08-04 08:02:00+10	0	1	1
76	2026-08-04 08:04:00+10	1	0	1
76	2026-08-04 08:06:00+10	4	1	5
76	2026-08-04 08:07:00+10	2	1	3
76	2026-08-04 08:09:00+10	2	0	2
76	2026-08-04 08:11:00+10	1	0	1
76	2026-08-04 08:13:00+10	1	1	2
76	2026-08-04 08:27:00+10	3	0	3
76	2026-08-04 08:31:00+10	3	0	3
76	2026-08-04 08:36:00+10	5	0	5
76	2026-08-04 08:38:00+10	2	0	2
76	2026-08-04 08:47:00+10	0	1	1
76	2026-08-04 08:51:00+10	2	0	2
76	2026-08-04 08:58:00+10	1	1	2
76	2026-08-04 08:59:00+10	0	2	2
76	2026-08-04 09:00:00+10	0	1	1
76	2026-08-04 09:04:00+10	3	1	4
76	2026-08-04 09:14:00+10	2	0	2
76	2026-08-04 09:18:00+10	1	1	2
76	2026-08-04 09:19:00+10	0	1	1
76	2026-08-04 09:22:00+10	1	0	1
76	2026-08-04 09:28:00+10	0	1	1
76	2026-08-04 09:38:00+10	2	1	3
76	2026-08-04 09:41:00+10	0	1	1
76	2026-08-04 09:43:00+10	1	0	1
76	2026-08-04 09:47:00+10	2	0	2
76	2026-08-04 09:50:00+10	5	1	6
76	2026-08-04 09:52:00+10	0	1	1
76	2026-08-04 09:53:00+10	1	1	2
76	2026-08-04 09:55:00+10	3	0	3
76	2026-08-04 09:58:00+10	0	2	2
76	2026-08-04 10:04:00+10	1	0	1
76	2026-08-04 10:08:00+10	2	0	2
76	2026-08-04 10:09:00+10	4	2	6
76	2026-08-04 10:26:00+10	1	0	1
76	2026-08-04 10:28:00+10	2	0	2
76	2026-08-04 10:32:00+10	2	0	2
76	2026-08-04 10:33:00+10	3	1	4
76	2026-08-04 10:35:00+10	3	0	3
76	2026-08-04 10:39:00+10	0	1	1
76	2026-08-04 10:41:00+10	2	0	2
76	2026-08-04 10:45:00+10	2	2	4
76	2026-08-04 10:47:00+10	2	0	2
76	2026-08-04 10:48:00+10	2	0	2
76	2026-08-04 10:52:00+10	1	0	1
76	2026-08-04 11:01:00+10	1	0	1
76	2026-08-04 11:03:00+10	1	0	1
76	2026-08-04 11:20:00+10	0	1	1
76	2026-08-04 11:22:00+10	0	1	1
76	2026-08-04 11:27:00+10	1	0	1
76	2026-08-04 11:31:00+10	1	0	1
76	2026-08-04 11:32:00+10	1	2	3
76	2026-08-04 11:36:00+10	0	1	1
76	2026-08-04 11:41:00+10	2	0	2
76	2026-08-04 11:45:00+10	2	1	3
76	2026-08-04 11:57:00+10	2	0	2
76	2026-08-04 12:02:00+10	0	1	1
76	2026-08-04 12:07:00+10	7	1	8
76	2026-08-04 12:11:00+10	2	1	3
76	2026-08-04 12:15:00+10	0	2	2
76	2026-08-04 12:22:00+10	1	0	1
76	2026-08-04 12:30:00+10	2	4	6
76	2026-08-04 12:31:00+10	2	1	3
76	2026-08-04 12:33:00+10	2	0	2
76	2026-08-04 12:37:00+10	1	0	1
76	2026-08-04 12:39:00+10	0	1	1
76	2026-08-04 12:40:00+10	2	0	2
76	2026-08-04 12:42:00+10	0	1	1
76	2026-08-04 12:45:00+10	0	2	2
76	2026-08-04 12:50:00+10	0	1	1
76	2026-08-04 12:53:00+10	2	0	2
76	2026-08-04 12:56:00+10	2	0	2
76	2026-08-04 12:59:00+10	1	1	2
76	2026-08-04 13:20:00+10	1	2	3
76	2026-08-04 13:26:00+10	4	1	5
76	2026-08-04 13:27:00+10	0	2	2
76	2026-08-04 13:31:00+10	3	1	4
76	2026-08-04 13:33:00+10	1	0	1
76	2026-08-04 13:34:00+10	0	2	2
76	2026-08-04 13:35:00+10	1	1	2
76	2026-08-04 13:41:00+10	1	1	2
76	2026-08-04 13:50:00+10	1	1	2
76	2026-08-04 13:51:00+10	1	1	2
76	2026-08-04 13:54:00+10	1	1	2
76	2026-08-04 13:55:00+10	2	1	3
76	2026-08-04 14:02:00+10	1	0	1
76	2026-08-04 14:08:00+10	1	0	1
76	2026-08-04 14:10:00+10	2	0	2
76	2026-08-04 14:11:00+10	2	1	3
76	2026-08-04 14:15:00+10	1	0	1
76	2026-08-04 14:18:00+10	1	0	1
76	2026-08-04 14:28:00+10	0	3	3
77	2026-08-04 00:35:00+10	3	1	4
77	2026-08-04 01:20:00+10	6	0	6
77	2026-08-04 02:30:00+10	1	0	1
77	2026-08-04 02:40:00+10	0	1	1
77	2026-08-04 03:45:00+10	1	0	1
77	2026-08-04 05:30:00+10	1	1	2
77	2026-08-04 06:15:00+10	0	6	6
77	2026-08-04 06:35:00+10	2	6	8
77	2026-08-04 06:40:00+10	5	2	7
77	2026-08-04 07:05:00+10	2	3	5
77	2026-08-04 07:10:00+10	5	22	27
77	2026-08-04 07:20:00+10	8	7	15
77	2026-08-04 07:25:00+10	7	6	13
77	2026-08-04 07:55:00+10	6	9	15
77	2026-08-04 08:20:00+10	10	5	15
77	2026-08-04 08:30:00+10	6	10	16
77	2026-08-04 08:35:00+10	11	10	21
77	2026-08-04 08:45:00+10	14	12	26
77	2026-08-04 08:50:00+10	14	13	27
77	2026-08-04 08:55:00+10	11	19	30
77	2026-08-04 09:00:00+10	7	27	34
77	2026-08-04 09:35:00+10	8	4	12
77	2026-08-04 10:05:00+10	6	2	8
77	2026-08-04 10:15:00+10	5	3	8
77	2026-08-04 10:35:00+10	4	2	6
77	2026-08-04 10:40:00+10	6	3	9
77	2026-08-04 10:55:00+10	4	1	5
77	2026-08-04 11:15:00+10	3	8	11
77	2026-08-04 11:25:00+10	8	2	10
77	2026-08-04 11:35:00+10	2	3	5
77	2026-08-04 11:40:00+10	2	3	5
77	2026-08-04 12:05:00+10	2	2	4
77	2026-08-04 13:00:00+10	12	6	18
77	2026-08-04 13:05:00+10	13	55	68
77	2026-08-04 13:50:00+10	5	6	11
77	2026-08-04 14:00:00+10	11	4	15
77	2026-08-04 14:10:00+10	6	4	10
77	2026-08-04 14:25:00+10	10	5	15
77	2026-08-04 14:30:00+10	6	5	11
79	2026-08-03 23:57:00+10	1	0	1
79	2026-08-04 00:08:00+10	0	1	1
79	2026-08-04 00:25:00+10	1	0	1
79	2026-08-04 00:36:00+10	0	1	1
79	2026-08-04 00:48:00+10	1	0	1
79	2026-08-04 01:04:00+10	0	1	1
79	2026-08-04 01:05:00+10	0	2	2
79	2026-08-04 01:25:00+10	3	0	3
79	2026-08-04 01:29:00+10	0	1	1
79	2026-08-04 01:39:00+10	3	0	3
79	2026-08-04 01:49:00+10	1	0	1
79	2026-08-04 01:51:00+10	0	1	1
79	2026-08-04 02:42:00+10	0	1	1
79	2026-08-04 02:51:00+10	1	1	2
79	2026-08-04 02:55:00+10	0	1	1
79	2026-08-04 03:00:00+10	0	1	1
79	2026-08-04 03:01:00+10	1	0	1
79	2026-08-04 03:04:00+10	2	1	3
79	2026-08-04 03:14:00+10	0	2	2
79	2026-08-04 03:16:00+10	2	0	2
79	2026-08-04 03:20:00+10	0	1	1
79	2026-08-04 03:22:00+10	1	2	3
79	2026-08-04 03:46:00+10	2	0	2
79	2026-08-04 03:52:00+10	0	1	1
79	2026-08-04 04:08:00+10	0	1	1
79	2026-08-04 04:09:00+10	1	0	1
79	2026-08-04 04:12:00+10	1	0	1
79	2026-08-04 04:19:00+10	1	0	1
79	2026-08-04 04:29:00+10	1	0	1
79	2026-08-04 04:53:00+10	0	1	1
79	2026-08-04 04:56:00+10	3	0	3
79	2026-08-04 05:02:00+10	1	1	2
79	2026-08-04 05:03:00+10	0	1	1
79	2026-08-04 05:14:00+10	0	2	2
79	2026-08-04 05:16:00+10	1	1	2
79	2026-08-04 05:17:00+10	2	0	2
79	2026-08-04 05:18:00+10	1	0	1
79	2026-08-04 05:19:00+10	0	1	1
79	2026-08-04 05:28:00+10	1	0	1
79	2026-08-04 05:30:00+10	2	0	2
79	2026-08-04 05:39:00+10	2	0	2
79	2026-08-04 05:41:00+10	2	0	2
79	2026-08-04 05:50:00+10	1	1	2
79	2026-08-04 05:55:00+10	1	0	1
79	2026-08-04 06:01:00+10	1	1	2
79	2026-08-04 06:05:00+10	0	1	1
79	2026-08-04 06:19:00+10	1	2	3
79	2026-08-04 06:21:00+10	1	1	2
79	2026-08-04 06:27:00+10	3	1	4
79	2026-08-04 06:28:00+10	2	0	2
79	2026-08-04 06:36:00+10	1	0	1
79	2026-08-04 06:37:00+10	1	1	2
79	2026-08-04 06:40:00+10	0	2	2
79	2026-08-04 06:45:00+10	2	3	5
79	2026-08-04 06:46:00+10	1	1	2
79	2026-08-04 06:48:00+10	0	2	2
79	2026-08-04 06:53:00+10	2	2	4
79	2026-08-04 06:54:00+10	3	0	3
79	2026-08-04 07:01:00+10	1	2	3
79	2026-08-04 07:06:00+10	1	2	3
79	2026-08-04 07:08:00+10	2	2	4
79	2026-08-04 07:09:00+10	2	0	2
79	2026-08-04 07:12:00+10	2	0	2
79	2026-08-04 07:13:00+10	1	0	1
79	2026-08-04 07:15:00+10	3	1	4
79	2026-08-04 07:16:00+10	3	0	3
79	2026-08-04 07:21:00+10	3	2	5
79	2026-08-04 07:22:00+10	2	0	2
79	2026-08-04 07:26:00+10	0	3	3
79	2026-08-04 07:35:00+10	3	4	7
79	2026-08-04 07:37:00+10	1	0	1
79	2026-08-04 07:38:00+10	0	4	4
79	2026-08-04 07:40:00+10	1	1	2
79	2026-08-04 07:41:00+10	0	1	1
79	2026-08-04 07:44:00+10	3	4	7
79	2026-08-04 07:48:00+10	3	1	4
79	2026-08-04 07:53:00+10	5	0	5
79	2026-08-04 07:54:00+10	2	5	7
79	2026-08-04 07:57:00+10	0	5	5
79	2026-08-04 08:00:00+10	4	1	5
79	2026-08-04 08:04:00+10	6	5	11
79	2026-08-04 08:09:00+10	7	3	10
79	2026-08-04 08:11:00+10	11	4	15
79	2026-08-04 08:16:00+10	4	1	5
79	2026-08-04 08:25:00+10	1	2	3
79	2026-08-04 08:28:00+10	4	4	8
79	2026-08-04 08:29:00+10	1	3	4
79	2026-08-04 08:31:00+10	3	1	4
79	2026-08-04 08:32:00+10	5	7	12
79	2026-08-04 08:40:00+10	4	7	11
79	2026-08-04 08:42:00+10	15	6	21
79	2026-08-04 08:43:00+10	5	0	5
79	2026-08-04 08:46:00+10	11	4	15
79	2026-08-04 08:47:00+10	5	3	8
79	2026-08-04 08:48:00+10	18	6	24
79	2026-08-04 08:49:00+10	11	4	15
79	2026-08-04 08:52:00+10	6	6	12
79	2026-08-04 08:53:00+10	5	4	9
79	2026-08-04 08:55:00+10	18	2	20
79	2026-08-04 08:59:00+10	5	3	8
79	2026-08-04 09:02:00+10	6	0	6
79	2026-08-04 09:07:00+10	0	4	4
79	2026-08-04 09:14:00+10	9	1	10
79	2026-08-04 09:18:00+10	8	3	11
79	2026-08-04 09:19:00+10	3	2	5
79	2026-08-04 09:20:00+10	2	2	4
79	2026-08-04 09:23:00+10	0	1	1
79	2026-08-04 09:26:00+10	0	6	6
79	2026-08-04 09:28:00+10	0	4	4
79	2026-08-04 09:29:00+10	9	3	12
79	2026-08-04 09:34:00+10	1	2	3
79	2026-08-04 09:38:00+10	3	1	4
79	2026-08-04 09:39:00+10	6	1	7
79	2026-08-04 09:40:00+10	1	3	4
79	2026-08-04 09:41:00+10	4	1	5
79	2026-08-04 09:45:00+10	5	3	8
79	2026-08-04 09:46:00+10	3	1	4
79	2026-08-04 09:47:00+10	2	1	3
79	2026-08-04 09:52:00+10	4	2	6
79	2026-08-04 09:54:00+10	0	1	1
79	2026-08-04 09:56:00+10	3	3	6
79	2026-08-04 09:58:00+10	0	2	2
79	2026-08-04 09:59:00+10	2	3	5
79	2026-08-04 10:00:00+10	1	1	2
79	2026-08-04 10:04:00+10	2	4	6
79	2026-08-04 10:05:00+10	5	3	8
79	2026-08-04 10:06:00+10	3	4	7
79	2026-08-04 10:11:00+10	2	0	2
79	2026-08-04 10:17:00+10	11	1	12
79	2026-08-04 10:19:00+10	10	3	13
79	2026-08-04 10:20:00+10	0	4	4
79	2026-08-04 10:22:00+10	2	4	6
79	2026-08-04 10:23:00+10	7	3	10
79	2026-08-04 10:29:00+10	16	0	16
79	2026-08-04 10:31:00+10	4	0	4
79	2026-08-04 10:33:00+10	1	11	12
79	2026-08-04 10:34:00+10	9	0	9
79	2026-08-04 10:40:00+10	3	2	5
79	2026-08-04 10:43:00+10	2	6	8
79	2026-08-04 10:44:00+10	5	3	8
79	2026-08-04 10:45:00+10	5	4	9
79	2026-08-04 10:46:00+10	4	10	14
79	2026-08-04 10:52:00+10	2	2	4
79	2026-08-04 10:57:00+10	11	2	13
79	2026-08-04 11:06:00+10	1	3	4
79	2026-08-04 11:07:00+10	2	1	3
79	2026-08-04 11:15:00+10	2	4	6
79	2026-08-04 11:20:00+10	5	0	5
79	2026-08-04 11:22:00+10	5	4	9
79	2026-08-04 11:29:00+10	4	5	9
79	2026-08-04 11:31:00+10	3	2	5
79	2026-08-04 11:32:00+10	6	3	9
79	2026-08-04 11:35:00+10	4	2	6
79	2026-08-04 11:37:00+10	6	5	11
79	2026-08-04 11:38:00+10	6	3	9
79	2026-08-04 11:39:00+10	9	5	14
79	2026-08-04 11:42:00+10	7	0	7
79	2026-08-04 11:44:00+10	0	4	4
79	2026-08-04 11:47:00+10	1	8	9
79	2026-08-04 11:52:00+10	2	2	4
79	2026-08-04 11:55:00+10	13	6	19
79	2026-08-04 11:56:00+10	4	4	8
79	2026-08-04 11:57:00+10	5	7	12
79	2026-08-04 12:00:00+10	5	2	7
79	2026-08-04 12:03:00+10	5	6	11
79	2026-08-04 12:10:00+10	3	6	9
79	2026-08-04 12:13:00+10	3	8	11
79	2026-08-04 12:17:00+10	7	1	8
79	2026-08-04 12:18:00+10	2	5	7
79	2026-08-04 12:19:00+10	1	4	5
79	2026-08-04 12:24:00+10	2	12	14
79	2026-08-04 12:25:00+10	1	2	3
79	2026-08-04 12:26:00+10	2	9	11
79	2026-08-04 12:27:00+10	0	4	4
79	2026-08-04 12:33:00+10	2	0	2
79	2026-08-04 12:41:00+10	5	3	8
79	2026-08-04 12:44:00+10	5	5	10
79	2026-08-04 12:45:00+10	2	4	6
79	2026-08-04 12:46:00+10	5	3	8
79	2026-08-04 12:54:00+10	14	6	20
79	2026-08-04 12:55:00+10	4	6	10
79	2026-08-04 12:56:00+10	7	4	11
79	2026-08-04 13:00:00+10	6	7	13
79	2026-08-04 13:01:00+10	4	5	9
79	2026-08-04 13:06:00+10	9	2	11
79	2026-08-04 13:10:00+10	5	11	16
79	2026-08-04 13:18:00+10	2	2	4
79	2026-08-04 13:24:00+10	0	6	6
79	2026-08-04 13:25:00+10	3	6	9
79	2026-08-04 13:28:00+10	15	3	18
79	2026-08-04 13:29:00+10	4	9	13
79	2026-08-04 13:31:00+10	11	5	16
79	2026-08-04 13:35:00+10	9	1	10
79	2026-08-04 13:37:00+10	4	1	5
79	2026-08-04 13:39:00+10	8	6	14
79	2026-08-04 13:45:00+10	3	0	3
79	2026-08-04 13:56:00+10	1	7	8
79	2026-08-04 13:58:00+10	7	6	13
79	2026-08-04 13:59:00+10	5	6	11
79	2026-08-04 14:04:00+10	2	4	6
79	2026-08-04 14:06:00+10	2	5	7
79	2026-08-04 14:08:00+10	3	4	7
79	2026-08-04 14:12:00+10	13	8	21
79	2026-08-04 14:13:00+10	2	5	7
79	2026-08-04 14:19:00+10	7	7	14
79	2026-08-04 14:20:00+10	6	7	13
79	2026-08-04 14:25:00+10	4	1	5
79	2026-08-04 14:29:00+10	5	4	9
79	2026-08-04 14:30:00+10	6	7	13
79	2026-08-04 14:33:00+10	3	1	4
79	2026-08-04 14:34:00+10	0	4	4
79	2026-08-04 14:36:00+10	4	2	6
79	2026-08-04 14:39:00+10	4	3	7
84	2026-08-03 23:55:00+10	3	7	10
84	2026-08-04 00:10:00+10	1	1	2
84	2026-08-04 00:20:00+10	8	5	13
84	2026-08-04 00:30:00+10	4	2	6
84	2026-08-04 00:35:00+10	3	1	4
84	2026-08-04 01:10:00+10	0	1	1
84	2026-08-04 01:20:00+10	1	4	5
84	2026-08-04 01:55:00+10	4	3	7
84	2026-08-04 02:10:00+10	1	4	5
84	2026-08-04 03:05:00+10	1	1	2
84	2026-08-04 04:35:00+10	0	3	3
84	2026-08-04 05:15:00+10	4	2	6
84	2026-08-04 05:25:00+10	1	2	3
84	2026-08-04 05:45:00+10	0	1	1
84	2026-08-04 06:10:00+10	9	3	12
84	2026-08-04 06:35:00+10	19	8	27
84	2026-08-04 06:40:00+10	8	7	15
84	2026-08-04 06:50:00+10	16	6	22
84	2026-08-04 06:55:00+10	24	11	35
84	2026-08-04 08:10:00+10	103	29	132
84	2026-08-04 08:15:00+10	76	28	104
84	2026-08-04 08:20:00+10	97	22	119
84	2026-08-04 08:50:00+10	100	29	129
84	2026-08-04 09:05:00+10	97	16	113
84	2026-08-04 09:40:00+10	50	31	81
84	2026-08-04 10:05:00+10	40	19	59
84	2026-08-04 10:25:00+10	38	43	81
84	2026-08-04 10:30:00+10	74	35	109
84	2026-08-04 11:05:00+10	38	34	72
84	2026-08-04 11:20:00+10	31	49	80
84	2026-08-04 11:25:00+10	33	44	77
84	2026-08-04 12:00:00+10	38	54	92
84	2026-08-04 12:05:00+10	62	70	132
84	2026-08-04 12:30:00+10	59	79	138
84	2026-08-04 12:50:00+10	62	100	162
84	2026-08-04 13:05:00+10	74	80	154
84	2026-08-04 13:20:00+10	54	70	124
84	2026-08-04 13:30:00+10	38	94	132
84	2026-08-04 13:40:00+10	88	57	145
84	2026-08-04 14:10:00+10	63	57	120
85	2026-08-04 05:05:00+10	0	2	2
85	2026-08-04 05:55:00+10	1	0	1
85	2026-08-04 06:01:00+10	1	0	1
85	2026-08-04 06:05:00+10	0	1	1
85	2026-08-04 06:27:00+10	1	0	1
85	2026-08-04 06:40:00+10	2	0	2
85	2026-08-04 06:47:00+10	0	1	1
85	2026-08-04 06:57:00+10	0	2	2
85	2026-08-04 07:13:00+10	2	0	2
85	2026-08-04 07:16:00+10	6	1	7
85	2026-08-04 07:18:00+10	2	0	2
85	2026-08-04 07:19:00+10	1	1	2
85	2026-08-04 07:21:00+10	2	1	3
85	2026-08-04 07:24:00+10	2	2	4
85	2026-08-04 07:29:00+10	4	0	4
85	2026-08-04 07:30:00+10	1	1	2
85	2026-08-04 07:31:00+10	2	0	2
85	2026-08-04 07:34:00+10	1	0	1
85	2026-08-04 07:36:00+10	4	0	4
85	2026-08-04 07:46:00+10	3	0	3
85	2026-08-04 07:47:00+10	0	2	2
85	2026-08-04 07:52:00+10	3	2	5
85	2026-08-04 07:55:00+10	2	0	2
85	2026-08-04 07:57:00+10	2	0	2
85	2026-08-04 07:59:00+10	4	0	4
85	2026-08-04 08:04:00+10	5	0	5
85	2026-08-04 08:18:00+10	4	0	4
85	2026-08-04 08:21:00+10	7	0	7
85	2026-08-04 08:22:00+10	5	0	5
85	2026-08-04 08:36:00+10	3	2	5
85	2026-08-04 08:37:00+10	5	0	5
85	2026-08-04 08:39:00+10	3	3	6
85	2026-08-04 08:43:00+10	1	2	3
85	2026-08-04 08:47:00+10	0	2	2
85	2026-08-04 08:50:00+10	3	1	4
85	2026-08-04 08:54:00+10	6	3	9
85	2026-08-04 08:55:00+10	0	1	1
85	2026-08-04 08:56:00+10	2	0	2
85	2026-08-04 09:08:00+10	4	4	8
85	2026-08-04 09:10:00+10	3	0	3
85	2026-08-04 09:11:00+10	2	2	4
85	2026-08-04 09:15:00+10	0	1	1
85	2026-08-04 09:24:00+10	1	1	2
85	2026-08-04 09:30:00+10	2	1	3
85	2026-08-04 09:32:00+10	2	0	2
85	2026-08-04 09:39:00+10	1	5	6
85	2026-08-04 09:45:00+10	1	0	1
85	2026-08-04 09:46:00+10	1	0	1
85	2026-08-04 09:49:00+10	1	0	1
85	2026-08-04 09:52:00+10	2	0	2
85	2026-08-04 10:00:00+10	1	1	2
85	2026-08-04 10:02:00+10	1	0	1
85	2026-08-04 10:06:00+10	1	1	2
85	2026-08-04 10:08:00+10	1	0	1
85	2026-08-04 10:09:00+10	1	0	1
85	2026-08-04 10:12:00+10	1	1	2
85	2026-08-04 10:17:00+10	1	4	5
85	2026-08-04 10:19:00+10	1	1	2
85	2026-08-04 10:20:00+10	3	4	7
85	2026-08-04 10:27:00+10	1	0	1
85	2026-08-04 10:31:00+10	3	4	7
85	2026-08-04 10:33:00+10	0	2	2
85	2026-08-04 10:34:00+10	0	4	4
85	2026-08-04 10:46:00+10	0	1	1
85	2026-08-04 10:51:00+10	0	4	4
85	2026-08-04 10:53:00+10	3	2	5
85	2026-08-04 10:54:00+10	1	2	3
85	2026-08-04 10:55:00+10	1	2	3
85	2026-08-04 10:58:00+10	0	2	2
85	2026-08-04 11:00:00+10	5	0	5
85	2026-08-04 11:05:00+10	0	1	1
85	2026-08-04 11:12:00+10	3	0	3
85	2026-08-04 11:15:00+10	2	0	2
85	2026-08-04 11:16:00+10	2	3	5
85	2026-08-04 11:20:00+10	1	0	1
85	2026-08-04 11:22:00+10	1	0	1
85	2026-08-04 11:23:00+10	3	0	3
85	2026-08-04 11:25:00+10	3	1	4
85	2026-08-04 11:30:00+10	1	1	2
85	2026-08-04 11:32:00+10	0	1	1
85	2026-08-04 11:35:00+10	2	4	6
85	2026-08-04 11:37:00+10	2	0	2
85	2026-08-04 11:38:00+10	1	0	1
85	2026-08-04 11:40:00+10	0	1	1
85	2026-08-04 11:41:00+10	1	2	3
85	2026-08-04 11:43:00+10	3	1	4
85	2026-08-04 11:46:00+10	1	1	2
85	2026-08-04 11:47:00+10	0	2	2
85	2026-08-04 11:54:00+10	0	2	2
85	2026-08-04 11:55:00+10	0	1	1
85	2026-08-04 11:57:00+10	1	0	1
85	2026-08-04 12:02:00+10	2	1	3
85	2026-08-04 12:07:00+10	1	0	1
85	2026-08-04 12:10:00+10	2	0	2
85	2026-08-04 12:11:00+10	0	1	1
85	2026-08-04 12:14:00+10	1	0	1
85	2026-08-04 12:16:00+10	1	3	4
85	2026-08-04 12:20:00+10	1	1	2
85	2026-08-04 12:26:00+10	1	3	4
85	2026-08-04 12:28:00+10	3	0	3
85	2026-08-04 12:29:00+10	1	1	2
85	2026-08-04 12:34:00+10	1	2	3
85	2026-08-04 12:38:00+10	0	2	2
85	2026-08-04 12:40:00+10	0	3	3
85	2026-08-04 12:44:00+10	2	1	3
85	2026-08-04 12:45:00+10	2	0	2
85	2026-08-04 12:47:00+10	0	1	1
85	2026-08-04 12:51:00+10	1	0	1
85	2026-08-04 12:56:00+10	5	3	8
85	2026-08-04 13:00:00+10	1	0	1
85	2026-08-04 13:01:00+10	1	0	1
85	2026-08-04 13:05:00+10	0	1	1
85	2026-08-04 13:09:00+10	1	2	3
85	2026-08-04 13:20:00+10	0	2	2
85	2026-08-04 13:26:00+10	2	0	2
85	2026-08-04 13:27:00+10	0	1	1
85	2026-08-04 13:28:00+10	0	1	1
85	2026-08-04 13:32:00+10	1	0	1
85	2026-08-04 13:37:00+10	3	1	4
85	2026-08-04 13:41:00+10	2	3	5
85	2026-08-04 13:46:00+10	0	1	1
85	2026-08-04 13:49:00+10	3	0	3
85	2026-08-04 13:52:00+10	0	1	1
85	2026-08-04 13:58:00+10	1	0	1
85	2026-08-04 14:02:00+10	2	1	3
85	2026-08-04 14:06:00+10	1	1	2
85	2026-08-04 14:09:00+10	1	1	2
85	2026-08-04 14:18:00+10	1	1	2
85	2026-08-04 14:20:00+10	0	1	1
85	2026-08-04 14:31:00+10	2	1	3
85	2026-08-04 14:32:00+10	1	0	1
85	2026-08-04 14:38:00+10	3	0	3
86	2026-08-04 06:25:00+10	1	0	1
86	2026-08-04 06:55:00+10	1	0	1
86	2026-08-04 07:01:00+10	0	1	1
86	2026-08-04 07:02:00+10	2	0	2
86	2026-08-04 07:11:00+10	1	0	1
86	2026-08-04 07:17:00+10	1	0	1
86	2026-08-04 07:18:00+10	3	0	3
86	2026-08-04 07:30:00+10	0	2	2
86	2026-08-04 07:49:00+10	1	0	1
86	2026-08-04 07:52:00+10	2	0	2
86	2026-08-04 07:53:00+10	0	2	2
86	2026-08-04 07:58:00+10	1	0	1
86	2026-08-04 08:05:00+10	1	0	1
86	2026-08-04 08:16:00+10	1	0	1
86	2026-08-04 08:17:00+10	1	0	1
86	2026-08-04 08:19:00+10	1	0	1
86	2026-08-04 08:20:00+10	2	0	2
86	2026-08-04 08:22:00+10	2	0	2
86	2026-08-04 08:23:00+10	1	0	1
86	2026-08-04 08:28:00+10	2	0	2
86	2026-08-04 08:29:00+10	3	0	3
86	2026-08-04 08:31:00+10	2	0	2
86	2026-08-04 08:35:00+10	2	1	3
86	2026-08-04 08:37:00+10	2	0	2
86	2026-08-04 08:39:00+10	0	1	1
86	2026-08-04 08:40:00+10	1	0	1
86	2026-08-04 08:42:00+10	4	1	5
86	2026-08-04 08:44:00+10	2	0	2
86	2026-08-04 08:48:00+10	2	0	2
86	2026-08-04 08:49:00+10	2	3	5
86	2026-08-04 08:59:00+10	0	1	1
86	2026-08-04 09:05:00+10	1	0	1
86	2026-08-04 09:08:00+10	2	2	4
86	2026-08-04 09:09:00+10	0	1	1
86	2026-08-04 09:23:00+10	0	1	1
86	2026-08-04 09:33:00+10	1	1	2
86	2026-08-04 09:36:00+10	1	0	1
86	2026-08-04 09:55:00+10	0	2	2
86	2026-08-04 09:56:00+10	2	0	2
86	2026-08-04 10:09:00+10	1	1	2
86	2026-08-04 10:15:00+10	1	1	2
86	2026-08-04 10:16:00+10	0	1	1
86	2026-08-04 10:23:00+10	1	0	1
86	2026-08-04 10:25:00+10	1	0	1
86	2026-08-04 10:26:00+10	1	0	1
86	2026-08-04 10:40:00+10	0	2	2
86	2026-08-04 10:47:00+10	1	1	2
86	2026-08-04 10:48:00+10	1	2	3
86	2026-08-04 10:54:00+10	0	1	1
86	2026-08-04 10:59:00+10	1	2	3
86	2026-08-04 11:04:00+10	1	1	2
86	2026-08-04 11:10:00+10	0	1	1
86	2026-08-04 11:12:00+10	0	1	1
86	2026-08-04 11:14:00+10	1	1	2
86	2026-08-04 11:17:00+10	0	1	1
86	2026-08-04 11:23:00+10	0	1	1
86	2026-08-04 11:37:00+10	3	1	4
86	2026-08-04 11:41:00+10	0	1	1
86	2026-08-04 11:45:00+10	1	0	1
86	2026-08-04 11:49:00+10	1	2	3
86	2026-08-04 11:50:00+10	1	0	1
86	2026-08-04 11:51:00+10	2	0	2
86	2026-08-04 11:54:00+10	2	1	3
86	2026-08-04 11:55:00+10	0	1	1
86	2026-08-04 12:00:00+10	2	0	2
86	2026-08-04 12:14:00+10	1	1	2
86	2026-08-04 12:17:00+10	1	0	1
86	2026-08-04 12:25:00+10	2	5	7
86	2026-08-04 12:27:00+10	2	0	2
86	2026-08-04 12:37:00+10	2	0	2
86	2026-08-04 12:38:00+10	2	1	3
86	2026-08-04 12:41:00+10	1	0	1
86	2026-08-04 12:44:00+10	2	2	4
86	2026-08-04 12:47:00+10	1	0	1
86	2026-08-04 12:49:00+10	1	0	1
86	2026-08-04 12:50:00+10	1	2	3
86	2026-08-04 12:51:00+10	2	1	3
86	2026-08-04 12:54:00+10	2	0	2
86	2026-08-04 12:56:00+10	0	1	1
86	2026-08-04 12:59:00+10	0	2	2
86	2026-08-04 13:00:00+10	0	1	1
86	2026-08-04 13:10:00+10	1	0	1
86	2026-08-04 13:17:00+10	3	0	3
86	2026-08-04 13:18:00+10	1	2	3
86	2026-08-04 13:26:00+10	1	0	1
86	2026-08-04 13:27:00+10	3	0	3
86	2026-08-04 13:34:00+10	1	2	3
86	2026-08-04 13:44:00+10	1	2	3
86	2026-08-04 13:46:00+10	0	1	1
86	2026-08-04 13:56:00+10	1	0	1
86	2026-08-04 13:57:00+10	0	2	2
86	2026-08-04 13:59:00+10	0	3	3
86	2026-08-04 14:10:00+10	4	1	5
86	2026-08-04 14:11:00+10	1	0	1
86	2026-08-04 14:15:00+10	1	3	4
86	2026-08-04 14:19:00+10	2	0	2
86	2026-08-04 14:22:00+10	2	1	3
86	2026-08-04 14:24:00+10	1	2	3
86	2026-08-04 14:36:00+10	1	0	1
87	2026-08-04 00:24:00+10	0	1	1
87	2026-08-04 00:44:00+10	1	0	1
87	2026-08-04 05:00:00+10	1	0	1
87	2026-08-04 05:14:00+10	1	1	2
87	2026-08-04 06:00:00+10	2	0	2
87	2026-08-04 06:39:00+10	0	1	1
87	2026-08-04 06:40:00+10	0	1	1
87	2026-08-04 06:44:00+10	1	0	1
87	2026-08-04 06:53:00+10	0	1	1
87	2026-08-04 07:07:00+10	0	1	1
87	2026-08-04 07:15:00+10	0	1	1
87	2026-08-04 07:21:00+10	1	0	1
87	2026-08-04 07:26:00+10	1	0	1
87	2026-08-04 07:38:00+10	1	0	1
87	2026-08-04 07:43:00+10	1	0	1
87	2026-08-04 07:45:00+10	1	0	1
87	2026-08-04 07:50:00+10	1	0	1
87	2026-08-04 07:52:00+10	0	1	1
87	2026-08-04 07:55:00+10	1	0	1
87	2026-08-04 07:57:00+10	0	1	1
87	2026-08-04 08:03:00+10	2	1	3
87	2026-08-04 08:14:00+10	1	1	2
87	2026-08-04 08:22:00+10	1	1	2
87	2026-08-04 08:23:00+10	0	2	2
87	2026-08-04 08:33:00+10	1	1	2
87	2026-08-04 08:34:00+10	2	2	4
87	2026-08-04 08:35:00+10	3	3	6
87	2026-08-04 08:38:00+10	1	0	1
87	2026-08-04 08:46:00+10	1	2	3
87	2026-08-04 08:54:00+10	2	1	3
87	2026-08-04 08:56:00+10	2	4	6
87	2026-08-04 09:00:00+10	3	1	4
87	2026-08-04 09:01:00+10	1	0	1
87	2026-08-04 09:05:00+10	3	3	6
87	2026-08-04 09:12:00+10	1	0	1
87	2026-08-04 09:15:00+10	3	0	3
87	2026-08-04 09:18:00+10	0	1	1
87	2026-08-04 09:20:00+10	1	2	3
87	2026-08-04 09:29:00+10	3	0	3
87	2026-08-04 09:32:00+10	2	2	4
87	2026-08-04 09:39:00+10	2	2	4
87	2026-08-04 09:48:00+10	3	0	3
87	2026-08-04 09:54:00+10	2	4	6
87	2026-08-04 09:57:00+10	2	2	4
87	2026-08-04 09:59:00+10	1	0	1
87	2026-08-04 10:00:00+10	1	1	2
87	2026-08-04 10:01:00+10	0	1	1
87	2026-08-04 10:11:00+10	4	3	7
87	2026-08-04 10:13:00+10	2	1	3
87	2026-08-04 10:17:00+10	7	0	7
87	2026-08-04 10:28:00+10	2	4	6
87	2026-08-04 10:30:00+10	2	1	3
87	2026-08-04 10:33:00+10	3	4	7
87	2026-08-04 10:43:00+10	8	4	12
87	2026-08-04 10:45:00+10	2	2	4
87	2026-08-04 10:46:00+10	2	1	3
87	2026-08-04 10:52:00+10	1	2	3
87	2026-08-04 10:54:00+10	0	3	3
87	2026-08-04 10:56:00+10	1	0	1
87	2026-08-04 10:58:00+10	1	0	1
87	2026-08-04 10:59:00+10	0	1	1
87	2026-08-04 11:05:00+10	2	0	2
87	2026-08-04 11:06:00+10	0	1	1
87	2026-08-04 11:15:00+10	1	0	1
87	2026-08-04 11:16:00+10	1	0	1
87	2026-08-04 11:17:00+10	1	0	1
87	2026-08-04 11:18:00+10	4	1	5
87	2026-08-04 11:29:00+10	0	3	3
87	2026-08-04 11:32:00+10	1	0	1
87	2026-08-04 11:35:00+10	4	0	4
87	2026-08-04 11:40:00+10	1	1	2
87	2026-08-04 11:42:00+10	1	0	1
87	2026-08-04 11:44:00+10	2	0	2
87	2026-08-04 11:47:00+10	1	2	3
87	2026-08-04 11:48:00+10	1	0	1
87	2026-08-04 11:49:00+10	0	2	2
87	2026-08-04 11:52:00+10	5	0	5
87	2026-08-04 11:55:00+10	1	0	1
87	2026-08-04 12:04:00+10	2	0	2
87	2026-08-04 12:05:00+10	10	4	14
87	2026-08-04 12:08:00+10	5	2	7
87	2026-08-04 12:10:00+10	2	0	2
87	2026-08-04 12:12:00+10	2	1	3
87	2026-08-04 12:25:00+10	4	1	5
87	2026-08-04 12:26:00+10	6	1	7
87	2026-08-04 12:30:00+10	4	1	5
87	2026-08-04 12:32:00+10	2	4	6
87	2026-08-04 12:33:00+10	8	2	10
87	2026-08-04 12:34:00+10	2	1	3
87	2026-08-04 12:42:00+10	2	1	3
87	2026-08-04 12:47:00+10	1	3	4
87	2026-08-04 12:49:00+10	0	8	8
87	2026-08-04 12:52:00+10	1	1	2
87	2026-08-04 12:54:00+10	5	3	8
87	2026-08-04 12:56:00+10	2	1	3
87	2026-08-04 12:59:00+10	1	1	2
87	2026-08-04 13:00:00+10	4	10	14
87	2026-08-04 13:05:00+10	3	7	10
87	2026-08-04 13:09:00+10	3	1	4
87	2026-08-04 13:10:00+10	0	2	2
87	2026-08-04 13:12:00+10	3	3	6
87	2026-08-04 13:15:00+10	3	1	4
87	2026-08-04 13:16:00+10	1	2	3
87	2026-08-04 13:18:00+10	0	1	1
87	2026-08-04 13:25:00+10	0	1	1
87	2026-08-04 13:26:00+10	0	2	2
87	2026-08-04 13:27:00+10	2	4	6
87	2026-08-04 13:29:00+10	1	1	2
87	2026-08-04 13:30:00+10	2	1	3
87	2026-08-04 13:33:00+10	2	1	3
87	2026-08-04 13:41:00+10	1	2	3
87	2026-08-04 13:42:00+10	2	0	2
87	2026-08-04 13:43:00+10	0	2	2
87	2026-08-04 13:46:00+10	2	1	3
87	2026-08-04 13:51:00+10	2	2	4
87	2026-08-04 13:52:00+10	1	3	4
87	2026-08-04 13:54:00+10	1	1	2
87	2026-08-04 14:01:00+10	1	3	4
87	2026-08-04 14:05:00+10	5	1	6
87	2026-08-04 14:16:00+10	2	2	4
87	2026-08-04 14:17:00+10	2	5	7
87	2026-08-04 14:22:00+10	6	4	10
87	2026-08-04 14:26:00+10	0	1	1
87	2026-08-04 14:31:00+10	1	0	1
87	2026-08-04 14:35:00+10	2	1	3
87	2026-08-04 14:38:00+10	2	1	3
87	2026-08-04 14:39:00+10	3	1	4
107	2026-08-04 00:00:00+10	2	0	2
107	2026-08-04 00:25:00+10	1	2	3
107	2026-08-04 00:35:00+10	0	2	2
107	2026-08-04 01:05:00+10	1	1	2
107	2026-08-04 01:10:00+10	1	0	1
107	2026-08-04 02:10:00+10	0	1	1
107	2026-08-04 02:15:00+10	3	0	3
107	2026-08-04 05:15:00+10	1	1	2
107	2026-08-04 05:50:00+10	0	2	2
107	2026-08-04 05:55:00+10	0	1	1
107	2026-08-04 06:30:00+10	0	3	3
107	2026-08-04 06:45:00+10	0	4	4
107	2026-08-04 06:50:00+10	0	1	1
107	2026-08-04 07:05:00+10	0	5	5
107	2026-08-04 07:10:00+10	1	6	7
107	2026-08-04 07:20:00+10	0	6	6
107	2026-08-04 07:30:00+10	1	13	14
107	2026-08-04 07:35:00+10	2	8	10
107	2026-08-04 07:40:00+10	7	15	22
107	2026-08-04 07:55:00+10	4	15	19
107	2026-08-04 08:15:00+10	2	12	14
107	2026-08-04 08:30:00+10	7	20	27
107	2026-08-04 09:10:00+10	10	16	26
107	2026-08-04 09:15:00+10	11	16	27
107	2026-08-04 09:30:00+10	2	14	16
107	2026-08-04 09:50:00+10	3	15	18
107	2026-08-04 10:00:00+10	9	16	25
107	2026-08-04 10:10:00+10	13	16	29
107	2026-08-04 10:20:00+10	5	10	15
107	2026-08-04 10:25:00+10	1	9	10
107	2026-08-04 10:30:00+10	2	5	7
107	2026-08-04 10:55:00+10	5	12	17
107	2026-08-04 11:00:00+10	19	5	24
107	2026-08-04 11:05:00+10	6	13	19
107	2026-08-04 11:10:00+10	3	4	7
107	2026-08-04 11:15:00+10	11	7	18
107	2026-08-04 11:30:00+10	9	8	17
107	2026-08-04 11:40:00+10	4	10	14
107	2026-08-04 12:00:00+10	5	2	7
107	2026-08-04 13:20:00+10	17	14	31
107	2026-08-04 13:25:00+10	26	15	41
107	2026-08-04 13:35:00+10	9	31	40
107	2026-08-04 13:45:00+10	12	12	24
107	2026-08-04 14:05:00+10	11	21	32
107	2026-08-04 14:15:00+10	9	11	20
109	2026-08-03 23:55:00+10	1	0	1
109	2026-08-04 00:20:00+10	0	3	3
109	2026-08-04 00:40:00+10	1	1	2
109	2026-08-04 00:45:00+10	1	1	2
109	2026-08-04 01:10:00+10	6	1	7
109	2026-08-04 01:30:00+10	3	0	3
109	2026-08-04 01:40:00+10	0	1	1
109	2026-08-04 03:55:00+10	0	1	1
109	2026-08-04 05:15:00+10	1	0	1
109	2026-08-04 05:20:00+10	0	1	1
109	2026-08-04 05:25:00+10	1	2	3
109	2026-08-04 05:30:00+10	2	1	3
109	2026-08-04 05:55:00+10	2	1	3
109	2026-08-04 06:55:00+10	1	15	16
109	2026-08-04 07:00:00+10	1	4	5
109	2026-08-04 07:15:00+10	1	23	24
109	2026-08-04 07:25:00+10	4	24	28
109	2026-08-04 07:35:00+10	1	17	18
109	2026-08-04 07:40:00+10	8	32	40
109	2026-08-04 08:00:00+10	3	18	21
109	2026-08-04 08:10:00+10	8	40	48
109	2026-08-04 08:15:00+10	10	42	52
109	2026-08-04 08:20:00+10	8	56	64
109	2026-08-04 08:40:00+10	9	71	80
109	2026-08-04 08:55:00+10	6	58	64
109	2026-08-04 09:00:00+10	10	74	84
109	2026-08-04 09:15:00+10	5	38	43
109	2026-08-04 09:30:00+10	3	17	20
109	2026-08-04 09:55:00+10	6	25	31
109	2026-08-04 10:15:00+10	1	15	16
109	2026-08-04 10:20:00+10	8	7	15
109	2026-08-04 10:55:00+10	4	14	18
109	2026-08-04 11:05:00+10	11	6	17
109	2026-08-04 11:30:00+10	10	8	18
109	2026-08-04 11:35:00+10	8	5	13
109	2026-08-04 11:45:00+10	8	10	18
109	2026-08-04 11:50:00+10	4	2	6
109	2026-08-04 12:00:00+10	15	9	24
109	2026-08-04 12:10:00+10	13	9	22
109	2026-08-04 12:20:00+10	11	14	25
109	2026-08-04 12:25:00+10	31	17	48
109	2026-08-04 12:55:00+10	27	18	45
109	2026-08-04 13:10:00+10	17	11	28
109	2026-08-04 13:20:00+10	19	15	34
109	2026-08-04 13:30:00+10	33	8	41
109	2026-08-04 13:40:00+10	12	13	25
109	2026-08-04 13:45:00+10	14	12	26
109	2026-08-04 14:00:00+10	16	12	28
109	2026-08-04 14:05:00+10	17	14	31
109	2026-08-04 14:20:00+10	10	10	20
117	2026-08-04 00:30:00+10	1	2	3
117	2026-08-04 00:55:00+10	1	0	1
117	2026-08-04 02:35:00+10	1	0	1
117	2026-08-04 05:00:00+10	0	1	1
117	2026-08-04 05:25:00+10	0	1	1
117	2026-08-04 05:35:00+10	2	1	3
117	2026-08-04 05:40:00+10	3	0	3
117	2026-08-04 05:45:00+10	1	0	1
117	2026-08-04 05:50:00+10	0	1	1
117	2026-08-04 06:05:00+10	3	0	3
117	2026-08-04 06:10:00+10	1	0	1
117	2026-08-04 06:15:00+10	1	1	2
117	2026-08-04 06:30:00+10	6	1	7
117	2026-08-04 06:40:00+10	5	1	6
117	2026-08-04 07:00:00+10	3	0	3
117	2026-08-04 07:05:00+10	9	0	9
117	2026-08-04 07:40:00+10	15	5	20
117	2026-08-04 07:50:00+10	13	2	15
117	2026-08-04 08:00:00+10	22	5	27
117	2026-08-04 08:35:00+10	45	7	52
117	2026-08-04 08:40:00+10	37	9	46
117	2026-08-04 09:00:00+10	30	13	43
117	2026-08-04 09:15:00+10	19	6	25
117	2026-08-04 09:25:00+10	10	8	18
117	2026-08-04 09:30:00+10	16	7	23
117	2026-08-04 09:35:00+10	8	5	13
117	2026-08-04 09:40:00+10	11	10	21
117	2026-08-04 09:45:00+10	11	3	14
117	2026-08-04 09:50:00+10	13	10	23
117	2026-08-04 09:55:00+10	5	3	8
117	2026-08-04 10:05:00+10	5	5	10
117	2026-08-04 10:35:00+10	10	7	17
117	2026-08-04 10:40:00+10	9	10	19
117	2026-08-04 10:45:00+10	10	7	17
117	2026-08-04 10:50:00+10	16	6	22
117	2026-08-04 11:05:00+10	4	6	10
117	2026-08-04 11:15:00+10	22	6	28
117	2026-08-04 11:30:00+10	5	11	16
117	2026-08-04 11:45:00+10	5	1	6
117	2026-08-04 12:15:00+10	8	23	31
117	2026-08-04 13:00:00+10	18	11	29
117	2026-08-04 13:05:00+10	11	13	24
117	2026-08-04 13:20:00+10	15	14	29
117	2026-08-04 13:30:00+10	16	14	30
117	2026-08-04 13:50:00+10	12	5	17
117	2026-08-04 13:55:00+10	14	8	22
117	2026-08-04 14:05:00+10	5	10	15
117	2026-08-04 14:10:00+10	9	10	19
117	2026-08-04 14:15:00+10	10	9	19
118	2026-08-04 01:40:00+10	1	0	1
118	2026-08-04 05:00:00+10	0	1	1
118	2026-08-04 07:20:00+10	1	1	2
118	2026-08-04 07:25:00+10	2	0	2
118	2026-08-04 07:40:00+10	0	1	1
118	2026-08-04 08:10:00+10	3	2	5
118	2026-08-04 08:15:00+10	0	1	1
118	2026-08-04 08:40:00+10	2	0	2
118	2026-08-04 08:45:00+10	5	1	6
118	2026-08-04 08:50:00+10	3	1	4
118	2026-08-04 09:05:00+10	6	1	7
118	2026-08-04 09:10:00+10	0	1	1
118	2026-08-04 09:45:00+10	1	0	1
118	2026-08-04 10:00:00+10	0	2	2
118	2026-08-04 10:15:00+10	0	1	1
118	2026-08-04 10:25:00+10	3	0	3
118	2026-08-04 10:35:00+10	2	0	2
118	2026-08-04 10:40:00+10	2	1	3
118	2026-08-04 11:10:00+10	2	2	4
118	2026-08-04 11:35:00+10	0	1	1
118	2026-08-04 11:40:00+10	1	3	4
118	2026-08-04 11:45:00+10	1	0	1
118	2026-08-04 12:15:00+10	0	3	3
118	2026-08-04 12:20:00+10	0	1	1
118	2026-08-04 13:00:00+10	0	2	2
118	2026-08-04 13:20:00+10	2	1	3
118	2026-08-04 13:25:00+10	0	1	1
118	2026-08-04 13:45:00+10	1	1	2
118	2026-08-04 14:30:00+10	0	1	1
118	2026-08-04 14:35:00+10	4	0	4
123	2026-08-04 07:00:00+10	4	0	4
123	2026-08-04 07:15:00+10	4	2	6
123	2026-08-04 07:40:00+10	4	5	9
123	2026-08-04 07:50:00+10	6	2	8
123	2026-08-04 08:20:00+10	6	1	7
123	2026-08-04 08:25:00+10	3	3	6
123	2026-08-04 08:50:00+10	4	0	4
123	2026-08-04 09:30:00+10	4	1	5
123	2026-08-04 09:45:00+10	2	1	3
123	2026-08-04 09:50:00+10	1	2	3
123	2026-08-04 10:00:00+10	1	0	1
123	2026-08-04 10:10:00+10	1	0	1
123	2026-08-04 10:25:00+10	1	1	2
123	2026-08-04 11:40:00+10	0	1	1
123	2026-08-04 11:55:00+10	1	1	2
123	2026-08-04 12:00:00+10	0	2	2
123	2026-08-04 12:05:00+10	0	1	1
123	2026-08-04 12:10:00+10	0	7	7
123	2026-08-04 12:20:00+10	0	2	2
123	2026-08-04 13:05:00+10	7	5	12
123	2026-08-04 13:10:00+10	11	6	17
123	2026-08-04 13:35:00+10	6	0	6
123	2026-08-04 13:40:00+10	5	6	11
123	2026-08-04 13:50:00+10	2	0	2
123	2026-08-04 13:55:00+10	2	2	4
123	2026-08-04 14:25:00+10	7	1	8
130	2026-08-04 05:55:00+10	1	0	1
130	2026-08-04 06:20:00+10	2	0	2
130	2026-08-04 06:35:00+10	1	0	1
130	2026-08-04 06:55:00+10	2	0	2
130	2026-08-04 07:00:00+10	4	1	5
130	2026-08-04 07:05:00+10	3	1	4
130	2026-08-04 07:20:00+10	2	1	3
130	2026-08-04 07:50:00+10	4	2	6
130	2026-08-04 08:00:00+10	1	0	1
130	2026-08-04 08:25:00+10	2	1	3
130	2026-08-04 09:15:00+10	3	2	5
130	2026-08-04 09:20:00+10	4	6	10
130	2026-08-04 09:25:00+10	8	2	10
130	2026-08-04 09:50:00+10	7	1	8
130	2026-08-04 10:00:00+10	9	3	12
130	2026-08-04 10:25:00+10	5	4	9
130	2026-08-04 10:30:00+10	5	8	13
130	2026-08-04 10:55:00+10	3	2	5
130	2026-08-04 11:00:00+10	8	2	10
130	2026-08-04 11:25:00+10	13	9	22
130	2026-08-04 11:35:00+10	0	4	4
130	2026-08-04 11:45:00+10	1	0	1
130	2026-08-04 12:15:00+10	3	2	5
130	2026-08-04 12:50:00+10	16	8	24
130	2026-08-04 12:55:00+10	9	4	13
130	2026-08-04 13:00:00+10	12	7	19
130	2026-08-04 13:05:00+10	4	3	7
130	2026-08-04 13:15:00+10	7	7	14
130	2026-08-04 13:40:00+10	6	5	11
130	2026-08-04 13:45:00+10	10	7	17
130	2026-08-04 13:55:00+10	9	0	9
130	2026-08-04 14:15:00+10	7	7	14
131	2026-08-04 00:00:00+10	0	4	4
131	2026-08-04 00:05:00+10	1	1	2
131	2026-08-04 00:15:00+10	0	2	2
131	2026-08-04 00:30:00+10	1	0	1
131	2026-08-04 00:35:00+10	0	3	3
131	2026-08-04 00:40:00+10	3	1	4
131	2026-08-04 01:50:00+10	0	1	1
131	2026-08-04 02:35:00+10	0	2	2
131	2026-08-04 04:35:00+10	1	0	1
131	2026-08-04 05:30:00+10	1	0	1
131	2026-08-04 05:40:00+10	1	0	1
131	2026-08-04 05:45:00+10	2	0	2
131	2026-08-04 06:10:00+10	2	2	4
131	2026-08-04 06:20:00+10	2	0	2
131	2026-08-04 06:40:00+10	1	0	1
131	2026-08-04 06:45:00+10	0	1	1
131	2026-08-04 07:10:00+10	2	3	5
131	2026-08-04 07:55:00+10	6	2	8
131	2026-08-04 08:05:00+10	8	2	10
131	2026-08-04 08:10:00+10	13	2	15
131	2026-08-04 08:30:00+10	21	11	32
131	2026-08-04 08:55:00+10	6	8	14
131	2026-08-04 09:15:00+10	7	1	8
131	2026-08-04 09:35:00+10	10	4	14
131	2026-08-04 10:00:00+10	1	13	14
131	2026-08-04 10:30:00+10	3	8	11
131	2026-08-04 10:40:00+10	1	13	14
131	2026-08-04 10:50:00+10	10	2	12
131	2026-08-04 11:05:00+10	5	8	13
131	2026-08-04 11:15:00+10	7	2	9
131	2026-08-04 11:25:00+10	9	15	24
131	2026-08-04 11:30:00+10	6	4	10
131	2026-08-04 12:15:00+10	7	6	13
131	2026-08-04 12:35:00+10	13	18	31
131	2026-08-04 12:55:00+10	18	13	31
131	2026-08-04 13:05:00+10	1	4	5
131	2026-08-04 13:15:00+10	11	4	15
131	2026-08-04 13:30:00+10	11	11	22
131	2026-08-04 13:35:00+10	24	21	45
131	2026-08-04 13:55:00+10	15	11	26
131	2026-08-04 14:10:00+10	9	6	15
132	2026-08-03 23:55:00+10	3	0	3
132	2026-08-04 00:00:00+10	1	1	2
132	2026-08-04 00:50:00+10	1	0	1
132	2026-08-04 00:55:00+10	5	7	12
132	2026-08-04 01:05:00+10	1	1	2
132	2026-08-04 01:10:00+10	1	0	1
132	2026-08-04 01:30:00+10	0	8	8
132	2026-08-04 01:45:00+10	5	0	5
132	2026-08-04 01:50:00+10	0	1	1
132	2026-08-04 01:55:00+10	5	0	5
132	2026-08-04 02:20:00+10	4	1	5
132	2026-08-04 02:40:00+10	1	0	1
132	2026-08-04 03:40:00+10	0	1	1
132	2026-08-04 03:50:00+10	0	2	2
132	2026-08-04 04:15:00+10	2	0	2
132	2026-08-04 04:40:00+10	2	0	2
132	2026-08-04 05:15:00+10	0	3	3
132	2026-08-04 05:25:00+10	1	2	3
132	2026-08-04 05:35:00+10	4	1	5
132	2026-08-04 05:50:00+10	2	3	5
132	2026-08-04 06:05:00+10	2	2	4
132	2026-08-04 06:15:00+10	4	1	5
132	2026-08-04 06:35:00+10	2	3	5
132	2026-08-04 06:45:00+10	3	4	7
132	2026-08-04 07:10:00+10	1	1	2
132	2026-08-04 07:25:00+10	4	4	8
132	2026-08-04 07:35:00+10	4	4	8
132	2026-08-04 07:50:00+10	4	4	8
132	2026-08-04 07:55:00+10	14	4	18
132	2026-08-04 08:00:00+10	13	7	20
132	2026-08-04 08:10:00+10	10	12	22
132	2026-08-04 08:15:00+10	14	18	32
132	2026-08-04 08:30:00+10	11	4	15
132	2026-08-04 08:40:00+10	21	14	35
132	2026-08-04 08:45:00+10	13	8	21
132	2026-08-04 09:05:00+10	6	9	15
132	2026-08-04 09:20:00+10	16	8	24
132	2026-08-04 09:45:00+10	12	9	21
132	2026-08-04 09:55:00+10	6	3	9
132	2026-08-04 10:00:00+10	14	3	17
132	2026-08-04 10:10:00+10	11	3	14
132	2026-08-04 10:15:00+10	24	7	31
132	2026-08-04 10:20:00+10	8	8	16
132	2026-08-04 10:40:00+10	9	9	18
132	2026-08-04 11:15:00+10	17	4	21
132	2026-08-04 11:25:00+10	9	6	15
132	2026-08-04 11:45:00+10	6	8	14
132	2026-08-04 11:50:00+10	4	1	5
132	2026-08-04 12:00:00+10	7	6	13
132	2026-08-04 12:30:00+10	20	14	34
132	2026-08-04 12:35:00+10	15	10	25
132	2026-08-04 13:00:00+10	18	10	28
132	2026-08-04 13:05:00+10	25	23	48
132	2026-08-04 13:25:00+10	13	15	28
132	2026-08-04 13:45:00+10	9	7	16
132	2026-08-04 13:50:00+10	13	8	21
132	2026-08-04 13:55:00+10	5	15	20
132	2026-08-04 14:15:00+10	16	12	28
132	2026-08-04 14:25:00+10	15	14	29
133	2026-08-04 00:00:00+10	4	5	9
133	2026-08-04 00:05:00+10	4	2	6
133	2026-08-04 00:20:00+10	2	1	3
133	2026-08-04 00:25:00+10	7	5	12
133	2026-08-04 00:30:00+10	0	4	4
133	2026-08-04 00:35:00+10	6	3	9
133	2026-08-04 00:40:00+10	5	3	8
133	2026-08-04 01:10:00+10	0	4	4
133	2026-08-04 01:30:00+10	8	0	8
133	2026-08-04 01:45:00+10	1	1	2
133	2026-08-04 01:55:00+10	1	0	1
133	2026-08-04 02:00:00+10	1	0	1
133	2026-08-04 02:30:00+10	2	0	2
133	2026-08-04 02:45:00+10	0	1	1
133	2026-08-04 02:50:00+10	0	3	3
133	2026-08-04 02:55:00+10	2	2	4
133	2026-08-04 03:45:00+10	0	2	2
133	2026-08-04 03:50:00+10	2	1	3
133	2026-08-04 03:55:00+10	0	1	1
133	2026-08-04 04:15:00+10	0	2	2
133	2026-08-04 04:40:00+10	0	1	1
133	2026-08-04 04:55:00+10	1	0	1
133	2026-08-04 05:25:00+10	4	4	8
133	2026-08-04 05:40:00+10	23	6	29
133	2026-08-04 05:45:00+10	14	9	23
133	2026-08-04 05:50:00+10	18	4	22
133	2026-08-04 06:05:00+10	18	10	28
133	2026-08-04 06:30:00+10	31	18	49
133	2026-08-04 06:35:00+10	34	21	55
133	2026-08-04 06:45:00+10	38	11	49
133	2026-08-04 07:00:00+10	49	26	75
133	2026-08-04 07:10:00+10	63	21	84
133	2026-08-04 07:15:00+10	57	36	93
133	2026-08-04 07:20:00+10	47	18	65
133	2026-08-04 07:25:00+10	34	30	64
133	2026-08-04 07:30:00+10	88	25	113
133	2026-08-04 07:35:00+10	75	41	116
133	2026-08-04 08:10:00+10	30	33	63
133	2026-08-04 08:40:00+10	49	33	82
133	2026-08-04 09:25:00+10	32	29	61
133	2026-08-04 09:35:00+10	41	36	77
133	2026-08-04 09:40:00+10	29	32	61
133	2026-08-04 10:10:00+10	26	24	50
133	2026-08-04 10:55:00+10	24	31	55
133	2026-08-04 11:05:00+10	35	22	57
133	2026-08-04 11:20:00+10	20	29	49
133	2026-08-04 11:40:00+10	25	23	48
133	2026-08-04 11:45:00+10	29	31	60
133	2026-08-04 11:55:00+10	18	22	40
133	2026-08-04 12:10:00+10	30	25	55
133	2026-08-04 12:25:00+10	42	33	75
133	2026-08-04 12:40:00+10	34	42	76
133	2026-08-04 12:50:00+10	48	51	99
133	2026-08-04 13:10:00+10	59	34	93
133	2026-08-04 13:20:00+10	55	28	83
133	2026-08-04 13:45:00+10	46	26	72
133	2026-08-04 14:15:00+10	40	39	79
133	2026-08-04 14:25:00+10	24	29	53
133	2026-08-04 14:30:00+10	40	33	73
133	2026-08-04 14:35:00+10	44	44	88
134	2026-08-04 00:05:00+10	1	4	5
134	2026-08-04 00:15:00+10	6	9	15
134	2026-08-04 00:20:00+10	1	6	7
134	2026-08-04 00:50:00+10	2	7	9
134	2026-08-04 01:00:00+10	0	2	2
134	2026-08-04 01:05:00+10	0	4	4
134	2026-08-04 01:10:00+10	4	8	12
134	2026-08-04 01:15:00+10	0	2	2
134	2026-08-04 01:20:00+10	2	0	2
134	2026-08-04 01:50:00+10	2	1	3
134	2026-08-04 01:55:00+10	2	2	4
134	2026-08-04 02:00:00+10	1	0	1
134	2026-08-04 02:05:00+10	1	5	6
134	2026-08-04 02:10:00+10	1	0	1
134	2026-08-04 02:30:00+10	1	1	2
134	2026-08-04 03:15:00+10	1	0	1
134	2026-08-04 03:40:00+10	1	1	2
134	2026-08-04 03:45:00+10	0	1	1
134	2026-08-04 03:50:00+10	3	0	3
134	2026-08-04 03:55:00+10	1	2	3
134	2026-08-04 04:05:00+10	5	3	8
134	2026-08-04 04:35:00+10	0	1	1
134	2026-08-04 05:00:00+10	1	3	4
134	2026-08-04 05:10:00+10	1	0	1
134	2026-08-04 05:20:00+10	1	4	5
134	2026-08-04 05:35:00+10	3	1	4
134	2026-08-04 05:40:00+10	4	6	10
134	2026-08-04 06:20:00+10	12	6	18
134	2026-08-04 07:00:00+10	10	20	30
134	2026-08-04 07:15:00+10	14	15	29
134	2026-08-04 07:20:00+10	19	14	33
134	2026-08-04 07:30:00+10	26	16	42
134	2026-08-04 07:50:00+10	23	26	49
134	2026-08-04 08:05:00+10	9	22	31
134	2026-08-04 08:20:00+10	32	28	60
134	2026-08-04 08:25:00+10	18	16	34
134	2026-08-04 09:05:00+10	34	29	63
134	2026-08-04 09:10:00+10	14	45	59
134	2026-08-04 09:15:00+10	17	7	24
134	2026-08-04 09:20:00+10	13	23	36
134	2026-08-04 09:35:00+10	23	23	46
134	2026-08-04 10:20:00+10	26	17	43
134	2026-08-04 10:30:00+10	14	17	31
134	2026-08-04 10:35:00+10	17	14	31
134	2026-08-04 10:40:00+10	18	18	36
134	2026-08-04 11:10:00+10	18	27	45
134	2026-08-04 11:30:00+10	19	21	40
134	2026-08-04 12:00:00+10	17	22	39
134	2026-08-04 12:10:00+10	23	12	35
134	2026-08-04 12:45:00+10	21	35	56
134	2026-08-04 12:50:00+10	24	31	55
134	2026-08-04 13:10:00+10	28	44	72
134	2026-08-04 13:15:00+10	39	41	80
134	2026-08-04 13:30:00+10	18	29	47
134	2026-08-04 13:35:00+10	17	44	61
134	2026-08-04 14:00:00+10	29	42	71
134	2026-08-04 14:05:00+10	30	15	45
134	2026-08-04 14:10:00+10	30	32	62
135	2026-08-03 23:55:00+10	2	2	4
135	2026-08-04 00:25:00+10	0	4	4
135	2026-08-04 00:35:00+10	0	4	4
135	2026-08-04 00:45:00+10	2	2	4
135	2026-08-04 01:50:00+10	0	2	2
135	2026-08-04 02:30:00+10	2	1	3
135	2026-08-04 03:40:00+10	1	0	1
135	2026-08-04 04:00:00+10	0	1	1
135	2026-08-04 04:15:00+10	0	5	5
135	2026-08-04 04:25:00+10	1	1	2
135	2026-08-04 04:30:00+10	0	1	1
135	2026-08-04 04:45:00+10	2	1	3
135	2026-08-04 04:50:00+10	0	1	1
135	2026-08-04 05:20:00+10	0	1	1
135	2026-08-04 05:25:00+10	5	5	10
135	2026-08-04 05:35:00+10	0	1	1
135	2026-08-04 05:45:00+10	2	1	3
135	2026-08-04 06:10:00+10	5	1	6
135	2026-08-04 06:20:00+10	5	11	16
135	2026-08-04 06:25:00+10	6	9	15
135	2026-08-04 06:45:00+10	4	7	11
135	2026-08-04 06:50:00+10	5	5	10
135	2026-08-04 07:00:00+10	5	9	14
135	2026-08-04 07:05:00+10	6	7	13
135	2026-08-04 07:25:00+10	11	14	25
135	2026-08-04 07:40:00+10	16	22	38
135	2026-08-04 08:00:00+10	17	12	29
135	2026-08-04 08:05:00+10	19	26	45
135	2026-08-04 08:25:00+10	25	21	46
135	2026-08-04 08:40:00+10	20	34	54
135	2026-08-04 09:00:00+10	20	32	52
135	2026-08-04 09:10:00+10	14	22	36
135	2026-08-04 09:25:00+10	33	18	51
135	2026-08-04 09:45:00+10	7	16	23
135	2026-08-04 09:50:00+10	29	33	62
135	2026-08-04 10:10:00+10	24	21	45
135	2026-08-04 10:15:00+10	21	28	49
135	2026-08-04 10:25:00+10	29	15	44
135	2026-08-04 10:40:00+10	20	25	45
135	2026-08-04 10:45:00+10	21	17	38
135	2026-08-04 10:55:00+10	26	18	44
135	2026-08-04 11:00:00+10	22	30	52
135	2026-08-04 11:05:00+10	20	21	41
135	2026-08-04 11:40:00+10	19	18	37
135	2026-08-04 11:45:00+10	24	10	34
135	2026-08-04 11:55:00+10	25	11	36
135	2026-08-04 12:00:00+10	28	23	51
135	2026-08-04 12:10:00+10	14	22	36
135	2026-08-04 12:30:00+10	29	25	54
135	2026-08-04 12:45:00+10	30	29	59
135	2026-08-04 13:00:00+10	36	42	78
135	2026-08-04 13:30:00+10	29	26	55
135	2026-08-04 13:35:00+10	26	51	77
135	2026-08-04 13:50:00+10	31	32	63
135	2026-08-04 13:55:00+10	15	28	43
135	2026-08-04 14:15:00+10	8	10	18
135	2026-08-04 14:20:00+10	17	24	41
136	2026-08-04 05:30:00+10	1	0	1
136	2026-08-04 06:00:00+10	1	0	1
136	2026-08-04 06:35:00+10	0	1	1
136	2026-08-04 07:00:00+10	1	2	3
136	2026-08-04 07:25:00+10	2	2	4
136	2026-08-04 07:30:00+10	4	5	9
136	2026-08-04 07:50:00+10	2	6	8
136	2026-08-04 08:30:00+10	4	6	10
136	2026-08-04 09:00:00+10	6	1	7
136	2026-08-04 09:10:00+10	5	6	11
136	2026-08-04 09:15:00+10	1	4	5
136	2026-08-04 09:20:00+10	2	5	7
136	2026-08-04 09:25:00+10	1	1	2
136	2026-08-04 09:30:00+10	3	0	3
136	2026-08-04 09:40:00+10	37	4	41
136	2026-08-04 09:50:00+10	1	3	4
136	2026-08-04 09:55:00+10	1	2	3
136	2026-08-04 10:00:00+10	1	1	2
136	2026-08-04 10:05:00+10	0	1	1
136	2026-08-04 10:15:00+10	35	0	35
136	2026-08-04 10:30:00+10	1	0	1
136	2026-08-04 10:40:00+10	0	1	1
136	2026-08-04 10:50:00+10	1	1	2
136	2026-08-04 11:10:00+10	1	0	1
136	2026-08-04 11:50:00+10	4	0	4
136	2026-08-04 12:10:00+10	2	0	2
136	2026-08-04 12:15:00+10	2	0	2
136	2026-08-04 12:35:00+10	3	1	4
136	2026-08-04 12:45:00+10	4	2	6
136	2026-08-04 13:00:00+10	8	4	12
136	2026-08-04 13:30:00+10	8	2	10
136	2026-08-04 14:05:00+10	2	1	3
137	2026-08-04 00:50:00+10	1	0	1
137	2026-08-04 05:50:00+10	1	0	1
137	2026-08-04 06:10:00+10	1	0	1
137	2026-08-04 06:35:00+10	3	0	3
137	2026-08-04 06:40:00+10	2	1	3
137	2026-08-04 06:45:00+10	1	0	1
137	2026-08-04 06:55:00+10	11	1	12
137	2026-08-04 07:05:00+10	6	1	7
137	2026-08-04 07:15:00+10	20	1	21
137	2026-08-04 07:40:00+10	9	4	13
137	2026-08-04 07:50:00+10	33	1	34
137	2026-08-04 08:15:00+10	24	2	26
137	2026-08-04 08:20:00+10	24	0	24
137	2026-08-04 08:30:00+10	25	5	30
137	2026-08-04 09:00:00+10	26	4	30
137	2026-08-04 09:10:00+10	34	4	38
137	2026-08-04 09:20:00+10	15	8	23
137	2026-08-04 09:25:00+10	12	5	17
137	2026-08-04 09:45:00+10	15	4	19
137	2026-08-04 09:55:00+10	11	3	14
137	2026-08-04 10:15:00+10	1	3	4
137	2026-08-04 10:20:00+10	9	8	17
137	2026-08-04 10:30:00+10	1	9	10
137	2026-08-04 10:50:00+10	2	4	6
137	2026-08-04 10:55:00+10	3	8	11
137	2026-08-04 11:00:00+10	5	4	9
137	2026-08-04 11:20:00+10	6	7	13
137	2026-08-04 11:35:00+10	2	3	5
137	2026-08-04 11:45:00+10	3	4	7
137	2026-08-04 11:55:00+10	1	5	6
137	2026-08-04 12:35:00+10	5	7	12
137	2026-08-04 12:45:00+10	13	19	32
137	2026-08-04 13:05:00+10	15	8	23
137	2026-08-04 13:10:00+10	7	7	14
137	2026-08-04 13:20:00+10	4	3	7
137	2026-08-04 13:35:00+10	6	7	13
137	2026-08-04 13:50:00+10	1	3	4
137	2026-08-04 14:00:00+10	4	12	16
137	2026-08-04 14:15:00+10	3	11	14
138	2026-08-04 07:25:00+10	0	4	4
138	2026-08-04 08:00:00+10	0	1	1
138	2026-08-04 08:40:00+10	1	0	1
138	2026-08-04 09:35:00+10	1	0	1
138	2026-08-04 10:15:00+10	0	2	2
138	2026-08-04 11:20:00+10	0	2	2
138	2026-08-04 11:25:00+10	0	1	1
138	2026-08-04 11:30:00+10	0	2	2
138	2026-08-04 12:10:00+10	0	1	1
138	2026-08-04 12:15:00+10	4	0	4
138	2026-08-04 12:20:00+10	1	0	1
138	2026-08-04 12:40:00+10	2	0	2
138	2026-08-04 12:55:00+10	3	0	3
138	2026-08-04 13:45:00+10	1	0	1
138	2026-08-04 13:50:00+10	2	0	2
138	2026-08-04 14:00:00+10	0	4	4
139	2026-08-04 00:50:00+10	2	0	2
139	2026-08-04 00:55:00+10	0	1	1
139	2026-08-04 01:40:00+10	0	1	1
139	2026-08-04 02:05:00+10	0	2	2
139	2026-08-04 06:00:00+10	1	1	2
139	2026-08-04 06:20:00+10	1	0	1
139	2026-08-04 06:45:00+10	0	6	6
139	2026-08-04 06:50:00+10	2	5	7
139	2026-08-04 07:10:00+10	0	7	7
139	2026-08-04 07:15:00+10	3	2	5
139	2026-08-04 07:20:00+10	0	6	6
139	2026-08-04 07:30:00+10	1	11	12
139	2026-08-04 07:35:00+10	1	8	9
139	2026-08-04 08:15:00+10	1	8	9
139	2026-08-04 08:20:00+10	0	35	35
139	2026-08-04 08:25:00+10	1	37	38
139	2026-08-04 08:30:00+10	2	21	23
139	2026-08-04 08:55:00+10	3	35	38
139	2026-08-04 09:00:00+10	0	12	12
139	2026-08-04 09:05:00+10	1	21	22
139	2026-08-04 09:25:00+10	1	8	9
139	2026-08-04 09:30:00+10	1	7	8
139	2026-08-04 09:40:00+10	4	0	4
139	2026-08-04 10:10:00+10	0	1	1
139	2026-08-04 10:20:00+10	0	3	3
139	2026-08-04 10:25:00+10	0	1	1
139	2026-08-04 11:25:00+10	0	7	7
139	2026-08-04 11:40:00+10	1	0	1
139	2026-08-04 12:25:00+10	4	6	10
139	2026-08-04 12:50:00+10	2	3	5
139	2026-08-04 12:55:00+10	1	4	5
139	2026-08-04 13:00:00+10	2	6	8
139	2026-08-04 13:25:00+10	1	4	5
139	2026-08-04 13:30:00+10	9	5	14
139	2026-08-04 13:35:00+10	3	37	40
139	2026-08-04 14:05:00+10	3	8	11
139	2026-08-04 14:10:00+10	3	5	8
140	2026-08-04 07:05:00+10	3	2	5
140	2026-08-04 07:15:00+10	7	0	7
140	2026-08-04 07:20:00+10	3	4	7
140	2026-08-04 07:25:00+10	2	3	5
140	2026-08-04 08:05:00+10	16	0	16
140	2026-08-04 08:10:00+10	8	0	8
140	2026-08-04 08:15:00+10	15	1	16
140	2026-08-04 08:35:00+10	21	2	23
140	2026-08-04 08:45:00+10	12	4	16
140	2026-08-04 09:15:00+10	6	10	16
140	2026-08-04 09:25:00+10	6	4	10
140	2026-08-04 09:40:00+10	7	4	11
140	2026-08-04 10:10:00+10	13	5	18
140	2026-08-04 10:15:00+10	10	3	13
140	2026-08-04 10:25:00+10	6	3	9
140	2026-08-04 10:30:00+10	2	5	7
140	2026-08-04 10:35:00+10	8	4	12
140	2026-08-04 10:45:00+10	5	1	6
140	2026-08-04 10:50:00+10	6	3	9
140	2026-08-04 11:15:00+10	8	8	16
140	2026-08-04 11:25:00+10	6	4	10
140	2026-08-04 11:45:00+10	2	0	2
140	2026-08-04 11:55:00+10	1	0	1
140	2026-08-04 12:00:00+10	5	0	5
140	2026-08-04 12:05:00+10	5	1	6
140	2026-08-04 12:25:00+10	3	1	4
140	2026-08-04 12:30:00+10	9	4	13
140	2026-08-04 12:45:00+10	9	1	10
140	2026-08-04 12:50:00+10	5	1	6
140	2026-08-04 13:10:00+10	4	3	7
140	2026-08-04 13:15:00+10	10	7	17
140	2026-08-04 13:25:00+10	7	14	21
140	2026-08-04 14:05:00+10	7	14	21
140	2026-08-04 14:25:00+10	9	5	14
140	2026-08-04 14:30:00+10	7	4	11
140	2026-08-04 14:35:00+10	7	4	11
141	2026-08-04 00:05:00+10	0	2	2
141	2026-08-04 00:10:00+10	1	0	1
141	2026-08-04 00:15:00+10	0	5	5
141	2026-08-04 00:50:00+10	1	0	1
141	2026-08-04 01:00:00+10	3	0	3
141	2026-08-04 01:10:00+10	2	1	3
141	2026-08-04 01:25:00+10	2	1	3
141	2026-08-04 02:10:00+10	1	0	1
141	2026-08-04 02:20:00+10	0	2	2
141	2026-08-04 02:30:00+10	1	2	3
141	2026-08-04 02:45:00+10	1	0	1
141	2026-08-04 03:00:00+10	2	0	2
141	2026-08-04 03:10:00+10	0	2	2
141	2026-08-04 03:15:00+10	0	2	2
141	2026-08-04 04:10:00+10	2	0	2
141	2026-08-04 04:15:00+10	2	0	2
141	2026-08-04 04:55:00+10	1	0	1
141	2026-08-04 05:15:00+10	1	0	1
141	2026-08-04 05:30:00+10	1	0	1
141	2026-08-04 05:45:00+10	1	0	1
141	2026-08-04 05:50:00+10	3	2	5
141	2026-08-04 05:55:00+10	1	0	1
141	2026-08-04 06:30:00+10	1	3	4
141	2026-08-04 06:50:00+10	2	2	4
141	2026-08-04 06:55:00+10	4	2	6
141	2026-08-04 07:00:00+10	7	2	9
141	2026-08-04 07:05:00+10	6	6	12
141	2026-08-04 07:25:00+10	1	3	4
141	2026-08-04 07:50:00+10	7	7	14
141	2026-08-04 07:55:00+10	6	5	11
141	2026-08-04 08:00:00+10	3	6	9
141	2026-08-04 08:40:00+10	16	11	27
141	2026-08-04 09:10:00+10	10	9	19
141	2026-08-04 09:15:00+10	17	0	17
141	2026-08-04 09:30:00+10	6	4	10
141	2026-08-04 09:45:00+10	6	4	10
141	2026-08-04 10:10:00+10	8	13	21
141	2026-08-04 10:25:00+10	9	11	20
141	2026-08-04 10:30:00+10	15	12	27
141	2026-08-04 10:40:00+10	9	12	21
141	2026-08-04 11:00:00+10	15	3	18
141	2026-08-04 11:10:00+10	13	11	24
141	2026-08-04 11:15:00+10	12	17	29
141	2026-08-04 11:30:00+10	8	10	18
141	2026-08-04 11:35:00+10	9	1	10
141	2026-08-04 11:45:00+10	4	8	12
141	2026-08-04 11:55:00+10	4	8	12
141	2026-08-04 12:10:00+10	19	26	45
141	2026-08-04 12:25:00+10	14	13	27
141	2026-08-04 12:35:00+10	13	23	36
141	2026-08-04 12:40:00+10	16	32	48
141	2026-08-04 12:45:00+10	15	16	31
141	2026-08-04 13:05:00+10	2	3	5
141	2026-08-04 13:10:00+10	25	18	43
141	2026-08-04 13:20:00+10	13	12	25
141	2026-08-04 13:25:00+10	13	12	25
141	2026-08-04 13:45:00+10	18	6	24
141	2026-08-04 13:55:00+10	13	11	24
141	2026-08-04 14:00:00+10	8	9	17
141	2026-08-04 14:10:00+10	4	8	12
141	2026-08-04 14:20:00+10	7	9	16
142	2026-08-04 00:10:00+10	0	6	6
142	2026-08-04 00:40:00+10	1	0	1
142	2026-08-04 00:50:00+10	2	0	2
142	2026-08-04 01:00:00+10	1	1	2
142	2026-08-04 01:35:00+10	1	0	1
142	2026-08-04 05:15:00+10	3	0	3
142	2026-08-04 05:35:00+10	2	0	2
142	2026-08-04 05:40:00+10	1	0	1
142	2026-08-04 05:45:00+10	7	0	7
142	2026-08-04 05:55:00+10	4	1	5
142	2026-08-04 06:10:00+10	6	2	8
142	2026-08-04 06:15:00+10	6	1	7
142	2026-08-04 06:45:00+10	2	1	3
142	2026-08-04 07:00:00+10	10	11	21
142	2026-08-04 07:10:00+10	18	16	34
142	2026-08-04 07:20:00+10	32	16	48
142	2026-08-04 07:35:00+10	15	28	43
142	2026-08-04 07:45:00+10	36	26	62
142	2026-08-04 07:55:00+10	16	28	44
142	2026-08-04 08:00:00+10	24	30	54
142	2026-08-04 08:10:00+10	13	48	61
142	2026-08-04 08:15:00+10	28	32	60
142	2026-08-04 08:20:00+10	32	26	58
142	2026-08-04 08:35:00+10	25	20	45
142	2026-08-04 08:40:00+10	22	43	65
142	2026-08-04 09:05:00+10	17	21	38
142	2026-08-04 09:35:00+10	18	14	32
142	2026-08-04 11:00:00+10	13	7	20
142	2026-08-04 11:10:00+10	16	5	21
142	2026-08-04 11:25:00+10	17	9	26
142	2026-08-04 11:35:00+10	7	1	8
142	2026-08-04 11:45:00+10	1	2	3
142	2026-08-04 11:50:00+10	7	3	10
142	2026-08-04 12:00:00+10	6	6	12
142	2026-08-04 12:10:00+10	16	13	29
142	2026-08-04 12:40:00+10	39	27	66
142	2026-08-04 12:55:00+10	47	29	76
142	2026-08-04 13:10:00+10	28	41	69
142	2026-08-04 13:25:00+10	34	16	50
142	2026-08-04 13:30:00+10	26	21	47
142	2026-08-04 13:35:00+10	26	22	48
142	2026-08-04 13:45:00+10	15	18	33
142	2026-08-04 14:05:00+10	21	23	44
143	2026-08-04 00:00:00+10	1	2	3
143	2026-08-04 00:05:00+10	0	2	2
143	2026-08-04 00:15:00+10	1	0	1
143	2026-08-04 00:25:00+10	2	1	3
143	2026-08-04 00:40:00+10	3	1	4
143	2026-08-04 01:20:00+10	2	4	6
143	2026-08-04 01:40:00+10	2	0	2
143	2026-08-04 01:45:00+10	3	1	4
143	2026-08-04 02:00:00+10	3	0	3
143	2026-08-04 02:05:00+10	1	0	1
143	2026-08-04 02:15:00+10	1	0	1
143	2026-08-04 02:25:00+10	1	1	2
143	2026-08-04 02:45:00+10	2	0	2
143	2026-08-04 03:00:00+10	1	0	1
143	2026-08-04 03:05:00+10	1	0	1
143	2026-08-04 03:15:00+10	1	3	4
143	2026-08-04 03:25:00+10	2	0	2
143	2026-08-04 03:40:00+10	1	1	2
143	2026-08-04 03:50:00+10	1	0	1
143	2026-08-04 04:00:00+10	0	1	1
143	2026-08-04 04:15:00+10	6	1	7
143	2026-08-04 04:20:00+10	3	0	3
143	2026-08-04 04:35:00+10	3	0	3
143	2026-08-04 04:45:00+10	3	0	3
143	2026-08-04 04:55:00+10	1	0	1
143	2026-08-04 05:25:00+10	3	2	5
143	2026-08-04 05:35:00+10	2	5	7
143	2026-08-04 06:10:00+10	1	7	8
143	2026-08-04 06:15:00+10	8	7	15
143	2026-08-04 06:35:00+10	1	15	16
143	2026-08-04 06:40:00+10	6	8	14
143	2026-08-04 06:45:00+10	4	12	16
143	2026-08-04 07:00:00+10	3	11	14
143	2026-08-04 07:05:00+10	3	9	12
143	2026-08-04 07:15:00+10	7	11	18
143	2026-08-04 07:30:00+10	15	14	29
143	2026-08-04 07:35:00+10	9	14	23
143	2026-08-04 07:40:00+10	10	17	27
143	2026-08-04 07:55:00+10	13	23	36
143	2026-08-04 08:05:00+10	7	11	18
143	2026-08-04 08:30:00+10	19	15	34
143	2026-08-04 08:40:00+10	11	24	35
143	2026-08-04 09:00:00+10	10	13	23
143	2026-08-04 09:10:00+10	8	26	34
143	2026-08-04 09:15:00+10	2	24	26
143	2026-08-04 09:20:00+10	8	18	26
143	2026-08-04 09:30:00+10	3	27	30
143	2026-08-04 09:40:00+10	3	14	17
143	2026-08-04 09:50:00+10	7	8	15
143	2026-08-04 09:55:00+10	4	11	15
143	2026-08-04 10:20:00+10	4	7	11
143	2026-08-04 11:05:00+10	8	12	20
143	2026-08-04 12:00:00+10	0	1	1
143	2026-08-04 12:20:00+10	11	5	16
143	2026-08-04 12:25:00+10	10	8	18
143	2026-08-04 12:30:00+10	5	20	25
143	2026-08-04 12:35:00+10	7	8	15
143	2026-08-04 13:40:00+10	4	14	18
143	2026-08-04 14:10:00+10	10	7	17
143	2026-08-04 14:15:00+10	8	10	18
143	2026-08-04 14:20:00+10	10	4	14
143	2026-08-04 14:25:00+10	25	13	38
161	2026-08-04 02:25:00+10	1	0	1
161	2026-08-04 02:50:00+10	0	1	1
161	2026-08-04 03:45:00+10	0	1	1
161	2026-08-04 05:05:00+10	0	1	1
161	2026-08-04 05:15:00+10	0	1	1
161	2026-08-04 06:15:00+10	1	1	2
161	2026-08-04 06:30:00+10	2	1	3
161	2026-08-04 06:50:00+10	3	1	4
161	2026-08-04 07:00:00+10	4	5	9
161	2026-08-04 07:10:00+10	2	4	6
161	2026-08-04 07:15:00+10	5	6	11
161	2026-08-04 07:25:00+10	3	5	8
161	2026-08-04 08:05:00+10	5	9	14
161	2026-08-04 08:20:00+10	6	15	21
161	2026-08-04 08:30:00+10	7	20	27
161	2026-08-04 08:35:00+10	5	13	18
161	2026-08-04 08:40:00+10	7	14	21
161	2026-08-04 08:55:00+10	7	16	23
161	2026-08-04 09:00:00+10	5	8	13
161	2026-08-04 09:05:00+10	3	6	9
161	2026-08-04 09:10:00+10	5	9	14
161	2026-08-04 09:20:00+10	2	7	9
161	2026-08-04 09:30:00+10	6	3	9
161	2026-08-04 09:40:00+10	6	5	11
161	2026-08-04 09:45:00+10	5	5	10
161	2026-08-04 09:55:00+10	2	3	5
161	2026-08-04 10:10:00+10	3	6	9
161	2026-08-04 10:15:00+10	1	4	5
161	2026-08-04 10:40:00+10	0	5	5
161	2026-08-04 10:45:00+10	6	22	28
161	2026-08-04 11:00:00+10	6	4	10
161	2026-08-04 11:10:00+10	2	3	5
161	2026-08-04 11:20:00+10	0	11	11
161	2026-08-04 11:30:00+10	1	6	7
161	2026-08-04 11:35:00+10	2	7	9
161	2026-08-04 11:50:00+10	5	0	5
161	2026-08-04 12:05:00+10	1	1	2
161	2026-08-04 12:10:00+10	6	1	7
161	2026-08-04 12:15:00+10	5	1	6
161	2026-08-04 12:30:00+10	1	0	1
161	2026-08-04 12:40:00+10	7	3	10
161	2026-08-04 12:45:00+10	11	10	21
161	2026-08-04 12:50:00+10	5	4	9
161	2026-08-04 13:10:00+10	30	9	39
161	2026-08-04 13:25:00+10	11	6	17
161	2026-08-04 13:40:00+10	9	5	14
161	2026-08-04 14:00:00+10	2	2	4
161	2026-08-04 14:05:00+10	2	1	3
161	2026-08-04 14:10:00+10	1	4	5
162	2026-08-04 00:10:00+10	3	1	4
162	2026-08-04 00:15:00+10	2	2	4
162	2026-08-04 00:20:00+10	5	3	8
162	2026-08-04 00:35:00+10	6	4	10
162	2026-08-04 00:45:00+10	1	3	4
162	2026-08-04 01:00:00+10	2	0	2
162	2026-08-04 01:20:00+10	3	4	7
162	2026-08-04 01:40:00+10	5	3	8
162	2026-08-04 02:00:00+10	7	0	7
162	2026-08-04 02:10:00+10	4	4	8
162	2026-08-04 03:00:00+10	2	2	4
162	2026-08-04 03:05:00+10	0	2	2
162	2026-08-04 04:15:00+10	2	0	2
162	2026-08-04 04:25:00+10	1	0	1
162	2026-08-04 04:45:00+10	2	0	2
162	2026-08-04 05:15:00+10	0	1	1
162	2026-08-04 05:45:00+10	3	0	3
162	2026-08-04 06:25:00+10	6	1	7
162	2026-08-04 06:30:00+10	5	1	6
162	2026-08-04 06:35:00+10	4	2	6
162	2026-08-04 06:45:00+10	4	2	6
162	2026-08-04 06:50:00+10	10	3	13
162	2026-08-04 06:55:00+10	4	2	6
162	2026-08-04 07:15:00+10	13	7	20
162	2026-08-04 07:25:00+10	7	7	14
162	2026-08-04 07:55:00+10	11	7	18
162	2026-08-04 08:05:00+10	22	14	36
162	2026-08-04 08:10:00+10	13	15	28
162	2026-08-04 08:50:00+10	33	15	48
162	2026-08-04 08:55:00+10	18	17	35
162	2026-08-04 09:10:00+10	23	14	37
162	2026-08-04 09:30:00+10	25	8	33
162	2026-08-04 09:50:00+10	45	16	61
162	2026-08-04 10:15:00+10	24	21	45
162	2026-08-04 10:35:00+10	26	29	55
162	2026-08-04 10:40:00+10	36	35	71
162	2026-08-04 10:50:00+10	29	43	72
162	2026-08-04 10:55:00+10	38	43	81
162	2026-08-04 11:00:00+10	29	34	63
162	2026-08-04 11:10:00+10	30	36	66
162	2026-08-04 11:25:00+10	36	42	78
162	2026-08-04 11:30:00+10	30	52	82
162	2026-08-04 12:15:00+10	60	60	120
162	2026-08-04 12:20:00+10	38	67	105
162	2026-08-04 12:50:00+10	52	69	121
162	2026-08-04 12:55:00+10	51	64	115
162	2026-08-04 13:30:00+10	48	48	96
162	2026-08-04 13:40:00+10	48	54	102
162	2026-08-04 13:45:00+10	59	55	114
162	2026-08-04 13:50:00+10	60	47	107
162	2026-08-04 13:55:00+10	44	54	98
162	2026-08-04 14:00:00+10	27	50	77
162	2026-08-04 14:05:00+10	43	47	90
162	2026-08-04 14:10:00+10	34	63	97
162	2026-08-04 14:30:00+10	33	53	86
162	2026-08-04 14:35:00+10	53	49	102
164	2026-08-04 00:45:00+10	1	0	1
164	2026-08-04 01:05:00+10	2	0	2
164	2026-08-04 01:25:00+10	1	2	3
164	2026-08-04 02:00:00+10	0	1	1
164	2026-08-04 02:45:00+10	1	0	1
164	2026-08-04 05:00:00+10	0	1	1
164	2026-08-04 05:05:00+10	1	0	1
164	2026-08-04 05:20:00+10	0	2	2
164	2026-08-04 05:35:00+10	1	0	1
164	2026-08-04 05:55:00+10	1	1	2
164	2026-08-04 06:05:00+10	0	2	2
164	2026-08-04 06:20:00+10	0	4	4
164	2026-08-04 06:25:00+10	2	4	6
164	2026-08-04 06:30:00+10	4	0	4
164	2026-08-04 07:05:00+10	2	4	6
164	2026-08-04 07:15:00+10	2	17	19
164	2026-08-04 07:20:00+10	3	6	9
164	2026-08-04 07:50:00+10	9	9	18
164	2026-08-04 08:15:00+10	14	6	20
164	2026-08-04 08:30:00+10	12	9	21
164	2026-08-04 08:45:00+10	14	5	19
164	2026-08-04 08:50:00+10	14	9	23
164	2026-08-04 08:55:00+10	10	11	21
164	2026-08-04 09:05:00+10	10	4	14
164	2026-08-04 09:15:00+10	5	5	10
164	2026-08-04 09:40:00+10	13	4	17
164	2026-08-04 09:45:00+10	2	4	6
164	2026-08-04 10:15:00+10	5	1	6
164	2026-08-04 10:55:00+10	6	0	6
164	2026-08-04 11:05:00+10	4	2	6
164	2026-08-04 11:15:00+10	10	2	12
164	2026-08-04 12:20:00+10	6	6	12
164	2026-08-04 12:30:00+10	6	10	16
164	2026-08-04 12:35:00+10	14	10	24
164	2026-08-04 12:45:00+10	12	4	16
164	2026-08-04 12:50:00+10	10	5	15
164	2026-08-04 12:55:00+10	14	8	22
164	2026-08-04 13:20:00+10	7	9	16
164	2026-08-04 13:40:00+10	8	3	11
164	2026-08-04 13:50:00+10	8	8	16
164	2026-08-04 14:10:00+10	9	2	11
165	2026-08-04 06:10:00+10	0	1	1
165	2026-08-04 06:35:00+10	0	2	2
165	2026-08-04 06:50:00+10	0	2	2
165	2026-08-04 07:10:00+10	0	1	1
165	2026-08-04 07:55:00+10	1	3	4
165	2026-08-04 08:00:00+10	0	3	3
165	2026-08-04 08:25:00+10	3	4	7
165	2026-08-04 08:30:00+10	2	2	4
165	2026-08-04 08:45:00+10	2	3	5
165	2026-08-04 09:05:00+10	1	5	6
165	2026-08-04 09:40:00+10	1	4	5
165	2026-08-04 10:35:00+10	1	0	1
165	2026-08-04 10:55:00+10	2	2	4
165	2026-08-04 11:15:00+10	0	2	2
165	2026-08-04 11:45:00+10	1	0	1
165	2026-08-04 12:30:00+10	3	5	8
165	2026-08-04 12:35:00+10	2	2	4
165	2026-08-04 12:50:00+10	2	3	5
165	2026-08-04 13:15:00+10	4	3	7
165	2026-08-04 13:25:00+10	2	2	4
165	2026-08-04 13:50:00+10	0	1	1
165	2026-08-04 14:05:00+10	3	1	4
165	2026-08-04 14:25:00+10	1	2	3
165	2026-08-04 14:30:00+10	2	2	4
165	2026-08-04 14:35:00+10	2	0	2
166	2026-08-03 23:55:00+10	0	1	1
166	2026-08-04 05:45:00+10	1	0	1
166	2026-08-04 06:10:00+10	1	2	3
166	2026-08-04 06:40:00+10	0	1	1
166	2026-08-04 06:45:00+10	0	1	1
166	2026-08-04 07:10:00+10	1	1	2
166	2026-08-04 07:50:00+10	2	2	4
166	2026-08-04 07:55:00+10	2	1	3
166	2026-08-04 08:20:00+10	1	3	4
166	2026-08-04 08:30:00+10	2	3	5
166	2026-08-04 09:15:00+10	0	1	1
166	2026-08-04 09:25:00+10	0	7	7
166	2026-08-04 09:30:00+10	4	1	5
166	2026-08-04 09:35:00+10	0	4	4
166	2026-08-04 10:25:00+10	0	2	2
166	2026-08-04 10:30:00+10	1	2	3
166	2026-08-04 10:35:00+10	1	0	1
166	2026-08-04 11:15:00+10	2	2	4
166	2026-08-04 11:30:00+10	3	2	5
166	2026-08-04 12:10:00+10	4	1	5
166	2026-08-04 12:40:00+10	4	5	9
166	2026-08-04 13:00:00+10	5	9	14
166	2026-08-04 13:35:00+10	7	5	12
166	2026-08-04 13:40:00+10	2	8	10
166	2026-08-04 13:50:00+10	0	5	5
166	2026-08-04 14:05:00+10	7	0	7
166	2026-08-04 14:15:00+10	3	4	7
166	2026-08-04 14:35:00+10	5	1	6
167	2026-08-04 00:35:00+10	0	1	1
167	2026-08-04 00:50:00+10	0	1	1
167	2026-08-04 00:55:00+10	0	1	1
167	2026-08-04 01:25:00+10	0	2	2
167	2026-08-04 06:05:00+10	0	1	1
167	2026-08-04 07:10:00+10	1	2	3
167	2026-08-04 07:25:00+10	2	2	4
167	2026-08-04 07:55:00+10	0	2	2
167	2026-08-04 08:00:00+10	2	1	3
167	2026-08-04 08:10:00+10	1	4	5
167	2026-08-04 08:15:00+10	3	7	10
167	2026-08-04 08:20:00+10	1	6	7
167	2026-08-04 08:25:00+10	1	8	9
167	2026-08-04 08:50:00+10	0	7	7
167	2026-08-04 08:55:00+10	2	5	7
167	2026-08-04 09:00:00+10	1	8	9
167	2026-08-04 09:10:00+10	2	6	8
167	2026-08-04 09:15:00+10	0	7	7
167	2026-08-04 09:20:00+10	1	4	5
167	2026-08-04 09:30:00+10	1	3	4
167	2026-08-04 09:55:00+10	0	4	4
167	2026-08-04 10:05:00+10	1	0	1
167	2026-08-04 10:30:00+10	11	2	13
167	2026-08-04 10:45:00+10	1	1	2
167	2026-08-04 10:55:00+10	1	2	3
167	2026-08-04 11:15:00+10	4	3	7
167	2026-08-04 11:30:00+10	2	2	4
167	2026-08-04 11:40:00+10	1	2	3
167	2026-08-04 11:55:00+10	0	1	1
167	2026-08-04 12:00:00+10	1	1	2
167	2026-08-04 12:05:00+10	2	5	7
167	2026-08-04 12:10:00+10	2	2	4
167	2026-08-04 12:15:00+10	1	4	5
167	2026-08-04 12:20:00+10	1	1	2
167	2026-08-04 12:30:00+10	0	1	1
167	2026-08-04 12:35:00+10	2	6	8
167	2026-08-04 12:45:00+10	2	4	6
167	2026-08-04 13:00:00+10	3	1	4
167	2026-08-04 13:20:00+10	1	5	6
167	2026-08-04 13:25:00+10	0	3	3
167	2026-08-04 13:30:00+10	2	5	7
167	2026-08-04 13:40:00+10	2	3	5
167	2026-08-04 13:45:00+10	2	4	6
167	2026-08-04 14:15:00+10	1	2	3
167	2026-08-04 14:20:00+10	1	6	7
179	2026-08-04 00:05:00+10	0	3	3
179	2026-08-04 05:55:00+10	3	0	3
179	2026-08-04 06:10:00+10	3	0	3
179	2026-08-04 06:55:00+10	3	2	5
179	2026-08-04 07:10:00+10	2	1	3
179	2026-08-04 07:20:00+10	5	0	5
179	2026-08-04 07:45:00+10	6	3	9
179	2026-08-04 08:00:00+10	2	2	4
179	2026-08-04 08:05:00+10	6	3	9
179	2026-08-04 08:20:00+10	4	2	6
179	2026-08-04 08:30:00+10	8	2	10
179	2026-08-04 08:35:00+10	6	2	8
179	2026-08-04 08:50:00+10	2	5	7
179	2026-08-04 08:55:00+10	2	2	4
179	2026-08-04 09:05:00+10	3	0	3
179	2026-08-04 09:10:00+10	3	3	6
179	2026-08-04 09:30:00+10	1	4	5
179	2026-08-04 10:00:00+10	1	1	2
179	2026-08-04 10:45:00+10	2	8	10
179	2026-08-04 11:00:00+10	3	2	5
179	2026-08-04 11:35:00+10	3	3	6
179	2026-08-04 12:05:00+10	3	2	5
179	2026-08-04 12:10:00+10	2	3	5
179	2026-08-04 12:20:00+10	2	4	6
179	2026-08-04 12:35:00+10	6	2	8
179	2026-08-04 12:40:00+10	5	2	7
179	2026-08-04 13:00:00+10	7	5	12
179	2026-08-04 13:35:00+10	3	4	7
179	2026-08-04 14:05:00+10	2	3	5
179	2026-08-04 14:10:00+10	5	12	17
180	2026-08-04 06:12:00+10	1	0	1
180	2026-08-04 06:21:00+10	0	1	1
180	2026-08-04 06:39:00+10	1	0	1
180	2026-08-04 06:53:00+10	1	0	1
180	2026-08-04 07:06:00+10	2	0	2
180	2026-08-04 07:12:00+10	2	0	2
180	2026-08-04 07:19:00+10	0	2	2
180	2026-08-04 07:24:00+10	1	0	1
180	2026-08-04 07:25:00+10	2	0	2
180	2026-08-04 07:26:00+10	2	0	2
180	2026-08-04 07:31:00+10	2	0	2
180	2026-08-04 07:33:00+10	1	0	1
180	2026-08-04 07:35:00+10	0	2	2
180	2026-08-04 07:41:00+10	1	0	1
180	2026-08-04 07:44:00+10	10	0	10
180	2026-08-04 07:45:00+10	5	1	6
180	2026-08-04 07:57:00+10	3	2	5
180	2026-08-04 08:05:00+10	3	0	3
180	2026-08-04 08:07:00+10	2	2	4
180	2026-08-04 08:10:00+10	1	0	1
180	2026-08-04 08:14:00+10	4	3	7
180	2026-08-04 08:15:00+10	1	0	1
180	2026-08-04 08:18:00+10	2	0	2
180	2026-08-04 08:21:00+10	4	2	6
180	2026-08-04 08:22:00+10	5	0	5
180	2026-08-04 08:25:00+10	5	2	7
180	2026-08-04 08:28:00+10	0	1	1
180	2026-08-04 08:31:00+10	2	3	5
180	2026-08-04 08:34:00+10	5	0	5
180	2026-08-04 08:42:00+10	1	1	2
180	2026-08-04 08:45:00+10	0	1	1
180	2026-08-04 08:46:00+10	2	3	5
180	2026-08-04 08:51:00+10	1	1	2
180	2026-08-04 08:56:00+10	1	3	4
180	2026-08-04 08:57:00+10	4	1	5
180	2026-08-04 08:59:00+10	2	0	2
180	2026-08-04 09:06:00+10	1	1	2
180	2026-08-04 09:12:00+10	0	4	4
180	2026-08-04 09:13:00+10	0	1	1
180	2026-08-04 09:15:00+10	3	3	6
180	2026-08-04 09:23:00+10	1	1	2
180	2026-08-04 09:25:00+10	3	1	4
180	2026-08-04 09:26:00+10	3	0	3
180	2026-08-04 09:29:00+10	0	3	3
180	2026-08-04 09:39:00+10	1	0	1
180	2026-08-04 09:41:00+10	1	0	1
180	2026-08-04 09:43:00+10	1	0	1
180	2026-08-04 09:45:00+10	0	3	3
180	2026-08-04 09:58:00+10	3	1	4
180	2026-08-04 10:06:00+10	2	0	2
180	2026-08-04 10:07:00+10	0	2	2
180	2026-08-04 10:13:00+10	1	0	1
180	2026-08-04 10:14:00+10	4	0	4
180	2026-08-04 10:16:00+10	0	1	1
180	2026-08-04 10:18:00+10	1	0	1
180	2026-08-04 10:24:00+10	0	1	1
180	2026-08-04 10:28:00+10	2	0	2
180	2026-08-04 10:29:00+10	2	0	2
180	2026-08-04 10:30:00+10	1	0	1
180	2026-08-04 10:31:00+10	3	0	3
180	2026-08-04 10:36:00+10	3	0	3
180	2026-08-04 10:38:00+10	1	0	1
180	2026-08-04 10:51:00+10	3	0	3
180	2026-08-04 10:52:00+10	3	0	3
180	2026-08-04 10:53:00+10	2	0	2
180	2026-08-04 10:55:00+10	1	0	1
180	2026-08-04 10:58:00+10	1	0	1
180	2026-08-04 11:12:00+10	1	0	1
180	2026-08-04 11:15:00+10	1	0	1
180	2026-08-04 11:19:00+10	1	1	2
180	2026-08-04 11:20:00+10	1	0	1
180	2026-08-04 11:32:00+10	4	0	4
180	2026-08-04 11:40:00+10	0	1	1
180	2026-08-04 11:53:00+10	0	1	1
180	2026-08-04 12:15:00+10	1	3	4
180	2026-08-04 12:27:00+10	1	0	1
180	2026-08-04 12:30:00+10	1	0	1
180	2026-08-04 12:32:00+10	0	2	2
180	2026-08-04 12:33:00+10	1	0	1
180	2026-08-04 12:35:00+10	3	0	3
180	2026-08-04 12:53:00+10	1	1	2
180	2026-08-04 12:54:00+10	1	3	4
180	2026-08-04 12:59:00+10	0	3	3
180	2026-08-04 13:10:00+10	1	0	1
180	2026-08-04 13:14:00+10	3	0	3
180	2026-08-04 13:15:00+10	1	2	3
180	2026-08-04 13:17:00+10	2	4	6
180	2026-08-04 13:19:00+10	2	1	3
180	2026-08-04 13:24:00+10	1	0	1
180	2026-08-04 13:29:00+10	1	0	1
180	2026-08-04 13:32:00+10	6	1	7
180	2026-08-04 13:33:00+10	2	0	2
180	2026-08-04 13:36:00+10	0	1	1
180	2026-08-04 13:39:00+10	0	3	3
180	2026-08-04 13:48:00+10	0	1	1
180	2026-08-04 13:58:00+10	1	2	3
180	2026-08-04 14:05:00+10	1	1	2
180	2026-08-04 14:09:00+10	1	0	1
180	2026-08-04 14:12:00+10	1	0	1
180	2026-08-04 14:13:00+10	2	0	2
180	2026-08-04 14:18:00+10	1	2	3
180	2026-08-04 14:19:00+10	2	1	3
181	2026-08-03 23:55:00+10	3	1	4
181	2026-08-04 00:02:00+10	2	2	4
181	2026-08-04 00:03:00+10	1	2	3
181	2026-08-04 00:07:00+10	4	3	7
181	2026-08-04 00:11:00+10	2	7	9
181	2026-08-04 00:13:00+10	9	0	9
181	2026-08-04 00:16:00+10	2	1	3
181	2026-08-04 00:19:00+10	9	2	11
181	2026-08-04 00:21:00+10	3	0	3
181	2026-08-04 00:27:00+10	2	1	3
181	2026-08-04 00:33:00+10	1	3	4
181	2026-08-04 00:49:00+10	2	0	2
181	2026-08-04 00:52:00+10	1	0	1
181	2026-08-04 00:56:00+10	2	0	2
181	2026-08-04 01:01:00+10	0	2	2
181	2026-08-04 01:02:00+10	0	1	1
181	2026-08-04 01:08:00+10	0	2	2
181	2026-08-04 01:14:00+10	1	0	1
181	2026-08-04 01:17:00+10	1	1	2
181	2026-08-04 01:18:00+10	0	1	1
181	2026-08-04 01:20:00+10	1	1	2
181	2026-08-04 01:25:00+10	6	0	6
181	2026-08-04 01:29:00+10	0	2	2
181	2026-08-04 01:40:00+10	3	1	4
181	2026-08-04 01:45:00+10	2	2	4
181	2026-08-04 01:46:00+10	2	1	3
181	2026-08-04 01:47:00+10	1	0	1
181	2026-08-04 01:50:00+10	2	0	2
181	2026-08-04 01:55:00+10	1	1	2
181	2026-08-04 01:57:00+10	1	0	1
181	2026-08-04 02:00:00+10	3	0	3
181	2026-08-04 02:01:00+10	0	2	2
181	2026-08-04 02:04:00+10	0	1	1
181	2026-08-04 02:29:00+10	0	6	6
181	2026-08-04 02:33:00+10	0	1	1
181	2026-08-04 02:35:00+10	2	0	2
181	2026-08-04 02:38:00+10	0	1	1
181	2026-08-04 02:43:00+10	0	1	1
181	2026-08-04 02:51:00+10	7	0	7
181	2026-08-04 02:56:00+10	2	0	2
181	2026-08-04 03:02:00+10	2	0	2
181	2026-08-04 03:03:00+10	2	0	2
181	2026-08-04 03:15:00+10	2	1	3
181	2026-08-04 04:04:00+10	0	5	5
181	2026-08-04 04:12:00+10	2	0	2
181	2026-08-04 04:18:00+10	1	0	1
181	2026-08-04 04:39:00+10	1	1	2
181	2026-08-04 04:47:00+10	0	2	2
181	2026-08-04 04:48:00+10	1	0	1
181	2026-08-04 04:50:00+10	0	1	1
181	2026-08-04 04:55:00+10	1	0	1
181	2026-08-04 04:58:00+10	0	2	2
181	2026-08-04 05:00:00+10	0	1	1
181	2026-08-04 05:01:00+10	2	0	2
181	2026-08-04 05:05:00+10	1	0	1
181	2026-08-04 05:06:00+10	0	1	1
181	2026-08-04 05:17:00+10	0	1	1
181	2026-08-04 05:26:00+10	1	0	1
181	2026-08-04 05:30:00+10	1	0	1
181	2026-08-04 05:37:00+10	0	1	1
181	2026-08-04 05:42:00+10	0	1	1
181	2026-08-04 05:43:00+10	0	1	1
181	2026-08-04 05:45:00+10	0	1	1
181	2026-08-04 05:46:00+10	0	2	2
181	2026-08-04 05:49:00+10	1	2	3
181	2026-08-04 05:51:00+10	2	1	3
181	2026-08-04 05:53:00+10	0	1	1
181	2026-08-04 05:54:00+10	1	1	2
181	2026-08-04 06:05:00+10	0	1	1
181	2026-08-04 06:09:00+10	3	0	3
181	2026-08-04 06:12:00+10	0	2	2
181	2026-08-04 06:14:00+10	1	3	4
181	2026-08-04 06:15:00+10	0	3	3
181	2026-08-04 06:17:00+10	0	1	1
181	2026-08-04 06:25:00+10	1	1	2
181	2026-08-04 06:26:00+10	0	1	1
181	2026-08-04 06:28:00+10	2	0	2
181	2026-08-04 06:32:00+10	5	3	8
181	2026-08-04 06:34:00+10	3	0	3
181	2026-08-04 06:37:00+10	1	4	5
181	2026-08-04 06:42:00+10	1	2	3
181	2026-08-04 06:46:00+10	1	2	3
181	2026-08-04 06:47:00+10	0	2	2
181	2026-08-04 06:48:00+10	5	2	7
181	2026-08-04 06:51:00+10	1	2	3
181	2026-08-04 06:58:00+10	3	0	3
181	2026-08-04 06:59:00+10	2	1	3
181	2026-08-04 07:02:00+10	2	2	4
181	2026-08-04 07:04:00+10	1	1	2
181	2026-08-04 07:11:00+10	1	3	4
181	2026-08-04 07:14:00+10	2	1	3
181	2026-08-04 07:24:00+10	0	5	5
181	2026-08-04 07:27:00+10	0	3	3
181	2026-08-04 07:32:00+10	2	4	6
181	2026-08-04 07:36:00+10	3	4	7
181	2026-08-04 07:38:00+10	3	2	5
181	2026-08-04 07:39:00+10	1	10	11
181	2026-08-04 07:42:00+10	2	5	7
181	2026-08-04 07:45:00+10	8	3	11
181	2026-08-04 07:47:00+10	2	6	8
181	2026-08-04 07:49:00+10	4	6	10
181	2026-08-04 07:51:00+10	2	1	3
181	2026-08-04 07:52:00+10	9	7	16
181	2026-08-04 07:53:00+10	1	5	6
181	2026-08-04 07:55:00+10	8	7	15
181	2026-08-04 07:59:00+10	2	10	12
181	2026-08-04 08:00:00+10	6	5	11
181	2026-08-04 08:02:00+10	0	6	6
181	2026-08-04 08:03:00+10	7	2	9
181	2026-08-04 08:05:00+10	0	6	6
181	2026-08-04 08:08:00+10	1	10	11
181	2026-08-04 08:12:00+10	7	3	10
181	2026-08-04 08:13:00+10	8	4	12
181	2026-08-04 08:14:00+10	3	8	11
181	2026-08-04 08:18:00+10	3	10	13
181	2026-08-04 08:21:00+10	11	2	13
181	2026-08-04 08:23:00+10	5	4	9
181	2026-08-04 08:31:00+10	10	5	15
181	2026-08-04 08:34:00+10	6	3	9
181	2026-08-04 08:38:00+10	1	7	8
181	2026-08-04 08:42:00+10	6	4	10
181	2026-08-04 08:45:00+10	15	7	22
181	2026-08-04 08:46:00+10	8	8	16
181	2026-08-04 08:51:00+10	13	10	23
181	2026-08-04 08:52:00+10	15	5	20
181	2026-08-04 08:55:00+10	7	6	13
181	2026-08-04 08:58:00+10	8	6	14
181	2026-08-04 09:00:00+10	7	2	9
181	2026-08-04 09:02:00+10	3	4	7
181	2026-08-04 09:07:00+10	10	5	15
181	2026-08-04 09:10:00+10	7	10	17
181	2026-08-04 09:11:00+10	1	8	9
181	2026-08-04 09:16:00+10	3	9	12
181	2026-08-04 09:18:00+10	6	6	12
181	2026-08-04 09:26:00+10	4	9	13
181	2026-08-04 09:28:00+10	8	14	22
181	2026-08-04 09:29:00+10	3	9	12
181	2026-08-04 09:33:00+10	9	9	18
181	2026-08-04 09:42:00+10	7	4	11
181	2026-08-04 09:49:00+10	6	6	12
181	2026-08-04 09:50:00+10	1	8	9
181	2026-08-04 09:52:00+10	7	4	11
181	2026-08-04 09:55:00+10	4	5	9
181	2026-08-04 09:56:00+10	2	8	10
181	2026-08-04 09:58:00+10	10	8	18
181	2026-08-04 09:59:00+10	4	11	15
181	2026-08-04 10:10:00+10	6	4	10
181	2026-08-04 10:12:00+10	8	6	14
181	2026-08-04 10:14:00+10	7	6	13
181	2026-08-04 10:17:00+10	5	16	21
181	2026-08-04 10:23:00+10	4	12	16
181	2026-08-04 10:29:00+10	5	10	15
181	2026-08-04 10:32:00+10	0	6	6
181	2026-08-04 10:33:00+10	5	4	9
181	2026-08-04 10:37:00+10	4	5	9
181	2026-08-04 10:38:00+10	1	14	15
181	2026-08-04 10:42:00+10	5	12	17
181	2026-08-04 10:43:00+10	8	10	18
181	2026-08-04 10:45:00+10	4	12	16
181	2026-08-04 10:49:00+10	18	9	27
181	2026-08-04 10:51:00+10	6	16	22
181	2026-08-04 10:52:00+10	6	6	12
181	2026-08-04 10:58:00+10	5	5	10
181	2026-08-04 11:01:00+10	5	13	18
181	2026-08-04 11:02:00+10	6	5	11
181	2026-08-04 11:05:00+10	1	10	11
181	2026-08-04 11:12:00+10	14	5	19
181	2026-08-04 11:18:00+10	6	7	13
181	2026-08-04 11:21:00+10	14	14	28
181	2026-08-04 11:22:00+10	8	9	17
181	2026-08-04 11:25:00+10	15	16	31
181	2026-08-04 11:29:00+10	3	9	12
181	2026-08-04 11:30:00+10	12	6	18
181	2026-08-04 11:31:00+10	18	15	33
181	2026-08-04 11:32:00+10	4	8	12
181	2026-08-04 11:34:00+10	15	8	23
181	2026-08-04 11:37:00+10	8	11	19
181	2026-08-04 11:40:00+10	9	8	17
181	2026-08-04 11:41:00+10	5	6	11
181	2026-08-04 11:44:00+10	3	7	10
181	2026-08-04 11:54:00+10	12	7	19
181	2026-08-04 11:55:00+10	3	5	8
181	2026-08-04 11:59:00+10	4	15	19
181	2026-08-04 12:02:00+10	5	8	13
181	2026-08-04 12:06:00+10	8	3	11
181	2026-08-04 12:07:00+10	15	18	33
181	2026-08-04 12:08:00+10	6	11	17
181	2026-08-04 12:10:00+10	13	16	29
181	2026-08-04 12:12:00+10	21	9	30
181	2026-08-04 12:17:00+10	6	20	26
181	2026-08-04 12:18:00+10	8	6	14
181	2026-08-04 12:25:00+10	13	13	26
181	2026-08-04 12:27:00+10	11	16	27
181	2026-08-04 12:28:00+10	14	14	28
181	2026-08-04 12:35:00+10	6	19	25
181	2026-08-04 12:40:00+10	17	18	35
181	2026-08-04 12:41:00+10	2	17	19
181	2026-08-04 12:44:00+10	4	31	35
181	2026-08-04 12:46:00+10	9	10	19
181	2026-08-04 12:47:00+10	6	18	24
181	2026-08-04 12:49:00+10	24	13	37
181	2026-08-04 12:51:00+10	19	12	31
181	2026-08-04 12:52:00+10	12	22	34
181	2026-08-04 12:56:00+10	3	15	18
181	2026-08-04 13:02:00+10	8	19	27
181	2026-08-04 13:03:00+10	17	4	21
181	2026-08-04 13:04:00+10	13	28	41
181	2026-08-04 13:05:00+10	2	24	26
181	2026-08-04 13:08:00+10	5	22	27
181	2026-08-04 13:14:00+10	5	23	28
181	2026-08-04 13:15:00+10	34	16	50
181	2026-08-04 13:18:00+10	19	10	29
181	2026-08-04 13:21:00+10	27	13	40
181	2026-08-04 13:22:00+10	20	23	43
181	2026-08-04 13:23:00+10	2	17	19
181	2026-08-04 13:25:00+10	22	20	42
181	2026-08-04 13:26:00+10	12	18	30
181	2026-08-04 13:27:00+10	14	9	23
181	2026-08-04 13:29:00+10	2	11	13
181	2026-08-04 13:30:00+10	12	7	19
181	2026-08-04 13:35:00+10	11	24	35
181	2026-08-04 13:38:00+10	12	2	14
181	2026-08-04 13:48:00+10	22	9	31
181	2026-08-04 13:51:00+10	9	11	20
181	2026-08-04 13:54:00+10	16	19	35
181	2026-08-04 13:55:00+10	29	18	47
181	2026-08-04 13:59:00+10	4	15	19
181	2026-08-04 14:00:00+10	11	12	23
181	2026-08-04 14:02:00+10	6	22	28
181	2026-08-04 14:04:00+10	6	16	22
181	2026-08-04 14:13:00+10	13	17	30
181	2026-08-04 14:14:00+10	1	10	11
181	2026-08-04 14:15:00+10	10	23	33
181	2026-08-04 14:20:00+10	3	25	28
181	2026-08-04 14:21:00+10	12	15	27
181	2026-08-04 14:22:00+10	17	20	37
181	2026-08-04 14:26:00+10	5	21	26
181	2026-08-04 14:30:00+10	14	18	32
181	2026-08-04 14:31:00+10	12	14	26
181	2026-08-04 14:32:00+10	2	23	25
181	2026-08-04 14:37:00+10	10	13	23
182	2026-08-03 23:55:00+10	1	5	6
182	2026-08-04 00:00:00+10	1	4	5
182	2026-08-04 00:10:00+10	0	1	1
182	2026-08-04 00:40:00+10	1	1	2
182	2026-08-04 01:05:00+10	4	1	5
182	2026-08-04 01:15:00+10	3	3	6
182	2026-08-04 01:25:00+10	0	1	1
182	2026-08-04 01:30:00+10	5	2	7
182	2026-08-04 01:40:00+10	2	2	4
182	2026-08-04 02:00:00+10	5	4	9
182	2026-08-04 02:05:00+10	1	5	6
182	2026-08-04 02:35:00+10	1	0	1
182	2026-08-04 02:50:00+10	3	5	8
182	2026-08-04 03:05:00+10	1	3	4
182	2026-08-04 03:10:00+10	1	1	2
182	2026-08-04 03:20:00+10	2	2	4
182	2026-08-04 03:35:00+10	1	1	2
182	2026-08-04 04:45:00+10	0	2	2
182	2026-08-04 05:35:00+10	1	1	2
182	2026-08-04 05:45:00+10	1	3	4
182	2026-08-04 05:50:00+10	2	3	5
182	2026-08-04 06:00:00+10	0	2	2
182	2026-08-04 06:35:00+10	3	5	8
182	2026-08-04 06:55:00+10	3	8	11
182	2026-08-04 07:00:00+10	2	3	5
182	2026-08-04 07:10:00+10	5	6	11
182	2026-08-04 07:45:00+10	7	5	12
182	2026-08-04 07:50:00+10	5	9	14
182	2026-08-04 08:00:00+10	3	14	17
182	2026-08-04 08:10:00+10	5	13	18
182	2026-08-04 08:25:00+10	5	37	42
182	2026-08-04 08:30:00+10	6	31	37
182	2026-08-04 09:00:00+10	7	16	23
182	2026-08-04 09:20:00+10	1	3	4
182	2026-08-04 09:30:00+10	8	8	16
182	2026-08-04 09:45:00+10	4	16	20
182	2026-08-04 10:05:00+10	11	12	23
182	2026-08-04 10:15:00+10	4	12	16
182	2026-08-04 10:55:00+10	9	8	17
182	2026-08-04 11:20:00+10	13	4	17
182	2026-08-04 11:30:00+10	6	8	14
182	2026-08-04 11:55:00+10	9	6	15
182	2026-08-04 12:00:00+10	14	4	18
182	2026-08-04 12:25:00+10	33	25	58
182	2026-08-04 12:40:00+10	22	20	42
182	2026-08-04 12:45:00+10	22	25	47
182	2026-08-04 13:10:00+10	34	23	57
182	2026-08-04 13:15:00+10	29	35	64
182	2026-08-04 14:10:00+10	8	24	32
182	2026-08-04 14:35:00+10	19	8	27
184	2026-08-03 23:55:00+10	3	4	7
184	2026-08-04 00:30:00+10	0	2	2
184	2026-08-04 00:45:00+10	2	6	8
184	2026-08-04 01:20:00+10	1	2	3
184	2026-08-04 01:30:00+10	0	1	1
184	2026-08-04 01:35:00+10	1	1	2
184	2026-08-04 01:40:00+10	0	1	1
184	2026-08-04 01:50:00+10	0	3	3
184	2026-08-04 01:55:00+10	0	1	1
184	2026-08-04 02:00:00+10	0	1	1
184	2026-08-04 02:05:00+10	0	1	1
184	2026-08-04 02:10:00+10	4	5	9
184	2026-08-04 02:15:00+10	0	2	2
184	2026-08-04 02:20:00+10	0	2	2
184	2026-08-04 03:15:00+10	2	0	2
184	2026-08-04 03:30:00+10	1	0	1
184	2026-08-04 03:40:00+10	0	1	1
184	2026-08-04 03:50:00+10	1	1	2
184	2026-08-04 04:15:00+10	0	2	2
184	2026-08-04 04:30:00+10	0	1	1
184	2026-08-04 05:15:00+10	2	2	4
184	2026-08-04 05:20:00+10	1	1	2
184	2026-08-04 05:30:00+10	1	2	3
184	2026-08-04 05:35:00+10	3	2	5
184	2026-08-04 06:05:00+10	1	5	6
184	2026-08-04 06:20:00+10	4	8	12
184	2026-08-04 06:30:00+10	2	5	7
184	2026-08-04 06:45:00+10	5	2	7
184	2026-08-04 06:50:00+10	5	2	7
184	2026-08-04 07:00:00+10	6	5	11
184	2026-08-04 07:20:00+10	3	6	9
184	2026-08-04 07:25:00+10	7	7	14
184	2026-08-04 07:40:00+10	14	14	28
184	2026-08-04 08:05:00+10	23	20	43
184	2026-08-04 08:15:00+10	29	25	54
184	2026-08-04 08:25:00+10	26	25	51
184	2026-08-04 08:30:00+10	18	31	49
184	2026-08-04 08:35:00+10	26	15	41
184	2026-08-04 08:45:00+10	41	31	72
184	2026-08-04 08:55:00+10	34	38	72
184	2026-08-04 09:10:00+10	23	36	59
184	2026-08-04 09:15:00+10	19	31	50
184	2026-08-04 09:20:00+10	22	35	57
184	2026-08-04 09:35:00+10	23	28	51
184	2026-08-04 09:45:00+10	25	45	70
184	2026-08-04 09:55:00+10	35	34	69
184	2026-08-04 10:00:00+10	27	30	57
184	2026-08-04 10:15:00+10	39	26	65
184	2026-08-04 10:20:00+10	29	43	72
184	2026-08-04 10:35:00+10	51	31	82
184	2026-08-04 10:55:00+10	39	36	75
184	2026-08-04 11:05:00+10	26	47	73
184	2026-08-04 11:20:00+10	35	31	66
184	2026-08-04 11:25:00+10	38	55	93
184	2026-08-04 11:50:00+10	45	44	89
184	2026-08-04 11:55:00+10	23	64	87
184	2026-08-04 13:10:00+10	79	108	187
184	2026-08-04 13:50:00+10	64	92	156
184	2026-08-04 14:20:00+10	57	67	124
184	2026-08-04 14:30:00+10	46	94	140
185	2026-08-04 00:20:00+10	5	2	7
185	2026-08-04 00:45:00+10	6	10	16
185	2026-08-04 00:50:00+10	5	1	6
185	2026-08-04 01:10:00+10	2	0	2
185	2026-08-04 01:50:00+10	0	1	1
185	2026-08-04 02:20:00+10	0	2	2
185	2026-08-04 02:40:00+10	1	1	2
185	2026-08-04 03:15:00+10	1	0	1
185	2026-08-04 03:45:00+10	0	1	1
185	2026-08-04 04:55:00+10	1	0	1
185	2026-08-04 05:00:00+10	0	1	1
185	2026-08-04 05:10:00+10	1	2	3
185	2026-08-04 05:25:00+10	0	1	1
185	2026-08-04 06:15:00+10	2	9	11
185	2026-08-04 06:55:00+10	7	6	13
185	2026-08-04 07:40:00+10	10	21	31
185	2026-08-04 07:45:00+10	9	56	65
185	2026-08-04 08:05:00+10	16	68	84
185	2026-08-04 08:20:00+10	18	39	57
185	2026-08-04 08:30:00+10	19	69	88
185	2026-08-04 08:35:00+10	12	63	75
185	2026-08-04 08:45:00+10	23	86	109
185	2026-08-04 08:50:00+10	17	75	92
185	2026-08-04 09:00:00+10	19	55	74
185	2026-08-04 09:10:00+10	23	53	76
185	2026-08-04 09:20:00+10	20	40	60
185	2026-08-04 10:10:00+10	19	23	42
185	2026-08-04 10:15:00+10	26	25	51
185	2026-08-04 10:25:00+10	28	25	53
185	2026-08-04 11:00:00+10	33	35	68
185	2026-08-04 11:15:00+10	29	36	65
185	2026-08-04 11:20:00+10	32	39	71
185	2026-08-04 11:25:00+10	23	30	53
185	2026-08-04 11:30:00+10	35	35	70
185	2026-08-04 11:50:00+10	22	27	49
185	2026-08-04 11:55:00+10	21	24	45
185	2026-08-04 12:15:00+10	67	50	117
185	2026-08-04 12:25:00+10	59	52	111
185	2026-08-04 12:55:00+10	70	63	133
185	2026-08-04 13:25:00+10	62	98	160
185	2026-08-04 14:20:00+10	48	42	90
187	2026-08-04 00:07:00+10	1	0	1
187	2026-08-04 00:10:00+10	1	0	1
187	2026-08-04 00:15:00+10	1	0	1
187	2026-08-04 00:16:00+10	0	2	2
187	2026-08-04 00:19:00+10	1	0	1
187	2026-08-04 00:35:00+10	1	0	1
187	2026-08-04 00:39:00+10	0	1	1
187	2026-08-04 00:55:00+10	0	1	1
187	2026-08-04 01:40:00+10	0	1	1
187	2026-08-04 02:05:00+10	0	1	1
187	2026-08-04 02:43:00+10	0	2	2
187	2026-08-04 02:53:00+10	1	0	1
187	2026-08-04 03:38:00+10	0	1	1
187	2026-08-04 04:39:00+10	0	1	1
187	2026-08-04 05:48:00+10	1	0	1
187	2026-08-04 05:51:00+10	1	0	1
187	2026-08-04 06:07:00+10	0	1	1
187	2026-08-04 06:11:00+10	0	1	1
187	2026-08-04 06:19:00+10	1	0	1
187	2026-08-04 06:20:00+10	1	0	1
187	2026-08-04 06:24:00+10	0	1	1
187	2026-08-04 06:53:00+10	0	1	1
187	2026-08-04 07:15:00+10	1	1	2
187	2026-08-04 07:19:00+10	1	1	2
187	2026-08-04 07:21:00+10	3	3	6
187	2026-08-04 07:22:00+10	2	3	5
187	2026-08-04 07:23:00+10	1	3	4
187	2026-08-04 07:24:00+10	3	0	3
187	2026-08-04 07:26:00+10	9	4	13
187	2026-08-04 07:29:00+10	2	1	3
187	2026-08-04 07:30:00+10	4	1	5
187	2026-08-04 07:31:00+10	0	2	2
187	2026-08-04 07:32:00+10	12	0	12
187	2026-08-04 07:40:00+10	12	2	14
187	2026-08-04 07:41:00+10	3	1	4
187	2026-08-04 07:44:00+10	8	6	14
187	2026-08-04 07:45:00+10	9	1	10
187	2026-08-04 07:46:00+10	0	2	2
187	2026-08-04 07:59:00+10	10	1	11
187	2026-08-04 08:09:00+10	15	4	19
187	2026-08-04 08:12:00+10	15	6	21
187	2026-08-04 08:17:00+10	10	2	12
187	2026-08-04 08:18:00+10	11	3	14
187	2026-08-04 08:19:00+10	4	4	8
187	2026-08-04 08:21:00+10	11	4	15
187	2026-08-04 08:22:00+10	3	20	23
187	2026-08-04 08:23:00+10	11	5	16
187	2026-08-04 08:24:00+10	14	3	17
187	2026-08-04 08:36:00+10	13	2	15
187	2026-08-04 08:37:00+10	10	3	13
187	2026-08-04 08:41:00+10	21	5	26
187	2026-08-04 08:42:00+10	16	7	23
187	2026-08-04 08:43:00+10	2	5	7
187	2026-08-04 08:44:00+10	21	3	24
187	2026-08-04 08:48:00+10	9	4	13
187	2026-08-04 08:54:00+10	5	2	7
187	2026-08-04 08:57:00+10	14	8	22
187	2026-08-04 08:59:00+10	17	1	18
187	2026-08-04 09:13:00+10	7	3	10
187	2026-08-04 09:14:00+10	11	1	12
187	2026-08-04 09:16:00+10	4	4	8
187	2026-08-04 09:21:00+10	20	1	21
187	2026-08-04 09:22:00+10	9	3	12
187	2026-08-04 09:24:00+10	14	14	28
187	2026-08-04 09:25:00+10	9	4	13
187	2026-08-04 09:28:00+10	6	1	7
187	2026-08-04 09:32:00+10	14	3	17
187	2026-08-04 09:33:00+10	8	6	14
187	2026-08-04 09:37:00+10	6	4	10
187	2026-08-04 09:38:00+10	4	3	7
187	2026-08-04 09:40:00+10	6	0	6
187	2026-08-04 09:42:00+10	9	3	12
187	2026-08-04 09:43:00+10	6	6	12
187	2026-08-04 09:44:00+10	5	2	7
187	2026-08-04 09:46:00+10	7	0	7
187	2026-08-04 09:47:00+10	6	2	8
187	2026-08-04 09:49:00+10	3	1	4
187	2026-08-04 09:51:00+10	4	1	5
187	2026-08-04 09:54:00+10	5	0	5
187	2026-08-04 09:55:00+10	1	3	4
187	2026-08-04 10:07:00+10	3	5	8
187	2026-08-04 10:18:00+10	8	1	9
187	2026-08-04 10:21:00+10	6	5	11
187	2026-08-04 10:22:00+10	8	8	16
187	2026-08-04 10:23:00+10	5	14	19
187	2026-08-04 10:35:00+10	4	3	7
187	2026-08-04 10:36:00+10	1	4	5
187	2026-08-04 10:41:00+10	4	6	10
187	2026-08-04 10:45:00+10	1	0	1
187	2026-08-04 10:46:00+10	1	5	6
187	2026-08-04 10:47:00+10	8	6	14
187	2026-08-04 10:48:00+10	1	3	4
187	2026-08-04 10:53:00+10	6	8	14
187	2026-08-04 10:54:00+10	4	1	5
187	2026-08-04 10:57:00+10	3	2	5
187	2026-08-04 10:58:00+10	9	1	10
187	2026-08-04 11:05:00+10	3	2	5
187	2026-08-04 11:08:00+10	2	1	3
187	2026-08-04 11:11:00+10	3	7	10
187	2026-08-04 11:15:00+10	6	2	8
187	2026-08-04 11:20:00+10	8	3	11
187	2026-08-04 11:21:00+10	5	7	12
187	2026-08-04 11:23:00+10	4	15	19
187	2026-08-04 11:24:00+10	4	7	11
187	2026-08-04 11:34:00+10	0	10	10
187	2026-08-04 11:37:00+10	0	4	4
187	2026-08-04 11:38:00+10	3	0	3
187	2026-08-04 11:39:00+10	3	6	9
187	2026-08-04 11:40:00+10	1	1	2
187	2026-08-04 11:41:00+10	2	1	3
187	2026-08-04 11:58:00+10	0	1	1
187	2026-08-04 11:59:00+10	4	1	5
187	2026-08-04 12:05:00+10	5	5	10
187	2026-08-04 12:18:00+10	8	7	15
187	2026-08-04 12:20:00+10	9	5	14
187	2026-08-04 12:25:00+10	2	5	7
187	2026-08-04 12:28:00+10	4	15	19
187	2026-08-04 12:30:00+10	10	7	17
187	2026-08-04 12:31:00+10	1	10	11
187	2026-08-04 12:37:00+10	12	8	20
187	2026-08-04 12:40:00+10	4	27	31
187	2026-08-04 12:42:00+10	5	9	14
187	2026-08-04 12:50:00+10	9	10	19
187	2026-08-04 12:54:00+10	9	19	28
187	2026-08-04 13:05:00+10	12	3	15
187	2026-08-04 13:07:00+10	7	11	18
187	2026-08-04 13:08:00+10	7	5	12
187	2026-08-04 13:11:00+10	9	16	25
187	2026-08-04 13:18:00+10	7	3	10
187	2026-08-04 13:19:00+10	9	4	13
187	2026-08-04 13:25:00+10	6	9	15
187	2026-08-04 13:28:00+10	3	16	19
187	2026-08-04 13:29:00+10	2	5	7
187	2026-08-04 13:33:00+10	12	10	22
187	2026-08-04 13:34:00+10	4	10	14
187	2026-08-04 13:40:00+10	4	2	6
187	2026-08-04 13:43:00+10	5	2	7
187	2026-08-04 13:46:00+10	2	4	6
187	2026-08-04 13:47:00+10	3	6	9
187	2026-08-04 13:50:00+10	4	3	7
187	2026-08-04 13:52:00+10	5	2	7
187	2026-08-04 13:58:00+10	2	12	14
187	2026-08-04 14:05:00+10	3	2	5
187	2026-08-04 14:07:00+10	1	3	4
187	2026-08-04 14:10:00+10	7	5	12
187	2026-08-04 14:16:00+10	8	4	12
187	2026-08-04 14:17:00+10	7	2	9
187	2026-08-04 14:20:00+10	10	7	17
187	2026-08-04 14:22:00+10	10	0	10
187	2026-08-04 14:24:00+10	5	6	11
188	2026-08-04 07:10:00+10	4	3	7
188	2026-08-04 07:45:00+10	12	3	15
188	2026-08-04 07:55:00+10	9	3	12
188	2026-08-04 08:00:00+10	25	5	30
188	2026-08-04 08:05:00+10	18	3	21
188	2026-08-04 08:25:00+10	39	18	57
188	2026-08-04 08:35:00+10	19	12	31
188	2026-08-04 09:35:00+10	13	5	18
188	2026-08-04 09:45:00+10	5	9	14
188	2026-08-04 10:00:00+10	32	20	52
188	2026-08-04 10:20:00+10	27	36	63
188	2026-08-04 10:25:00+10	43	24	67
188	2026-08-04 10:30:00+10	36	19	55
188	2026-08-04 10:40:00+10	12	19	31
188	2026-08-04 10:55:00+10	13	7	20
188	2026-08-04 11:00:00+10	17	2	19
188	2026-08-04 11:40:00+10	4	10	14
188	2026-08-04 12:05:00+10	24	12	36
188	2026-08-04 13:30:00+10	28	31	59
188	2026-08-04 13:35:00+10	12	25	37
188	2026-08-04 13:40:00+10	22	22	44
188	2026-08-04 13:45:00+10	18	12	30
188	2026-08-04 13:50:00+10	15	19	34
188	2026-08-04 14:00:00+10	9	19	28
209	2026-08-03 23:57:00+10	0	1	1
209	2026-08-04 00:06:00+10	1	0	1
209	2026-08-04 00:08:00+10	1	1	2
209	2026-08-04 00:09:00+10	1	0	1
209	2026-08-04 00:12:00+10	0	2	2
209	2026-08-04 00:13:00+10	0	2	2
209	2026-08-04 00:21:00+10	0	2	2
209	2026-08-04 00:26:00+10	0	4	4
209	2026-08-04 00:35:00+10	2	1	3
209	2026-08-04 00:39:00+10	11	0	11
209	2026-08-04 00:41:00+10	0	1	1
209	2026-08-04 00:49:00+10	1	0	1
209	2026-08-04 01:33:00+10	3	0	3
209	2026-08-04 02:00:00+10	1	0	1
209	2026-08-04 02:06:00+10	1	1	2
209	2026-08-04 03:10:00+10	1	0	1
209	2026-08-04 03:27:00+10	3	0	3
209	2026-08-04 04:17:00+10	1	0	1
209	2026-08-04 04:39:00+10	0	1	1
209	2026-08-04 04:57:00+10	1	3	4
209	2026-08-04 05:08:00+10	1	0	1
209	2026-08-04 05:12:00+10	0	1	1
209	2026-08-04 05:21:00+10	1	0	1
209	2026-08-04 05:24:00+10	0	2	2
209	2026-08-04 05:35:00+10	0	1	1
209	2026-08-04 05:42:00+10	0	1	1
209	2026-08-04 05:52:00+10	1	3	4
209	2026-08-04 05:57:00+10	0	1	1
209	2026-08-04 06:09:00+10	1	0	1
209	2026-08-04 06:20:00+10	0	4	4
209	2026-08-04 06:21:00+10	1	0	1
209	2026-08-04 06:23:00+10	2	0	2
209	2026-08-04 06:25:00+10	0	1	1
209	2026-08-04 06:29:00+10	3	1	4
209	2026-08-04 06:30:00+10	0	2	2
209	2026-08-04 06:36:00+10	1	3	4
209	2026-08-04 06:47:00+10	2	0	2
209	2026-08-04 06:50:00+10	0	6	6
209	2026-08-04 06:52:00+10	1	2	3
209	2026-08-04 06:57:00+10	0	3	3
209	2026-08-04 06:58:00+10	2	0	2
209	2026-08-04 07:03:00+10	4	4	8
209	2026-08-04 07:07:00+10	3	0	3
209	2026-08-04 07:08:00+10	0	6	6
209	2026-08-04 07:20:00+10	6	3	9
209	2026-08-04 07:22:00+10	1	3	4
209	2026-08-04 07:28:00+10	6	4	10
209	2026-08-04 07:31:00+10	8	3	11
209	2026-08-04 07:33:00+10	4	3	7
209	2026-08-04 07:34:00+10	3	2	5
209	2026-08-04 07:38:00+10	4	1	5
209	2026-08-04 07:39:00+10	6	2	8
209	2026-08-04 07:40:00+10	4	6	10
209	2026-08-04 07:44:00+10	3	9	12
209	2026-08-04 07:48:00+10	8	3	11
209	2026-08-04 07:52:00+10	9	2	11
209	2026-08-04 07:56:00+10	1	7	8
209	2026-08-04 07:57:00+10	4	4	8
209	2026-08-04 07:58:00+10	4	4	8
209	2026-08-04 07:59:00+10	3	7	10
209	2026-08-04 08:03:00+10	8	7	15
209	2026-08-04 08:05:00+10	2	4	6
209	2026-08-04 08:06:00+10	6	8	14
209	2026-08-04 08:18:00+10	9	12	21
209	2026-08-04 08:24:00+10	7	12	19
209	2026-08-04 08:25:00+10	10	6	16
209	2026-08-04 08:27:00+10	15	5	20
209	2026-08-04 08:28:00+10	8	15	23
209	2026-08-04 08:30:00+10	3	14	17
209	2026-08-04 08:31:00+10	9	19	28
209	2026-08-04 08:35:00+10	13	10	23
209	2026-08-04 08:38:00+10	9	23	32
209	2026-08-04 08:41:00+10	11	10	21
209	2026-08-04 08:44:00+10	20	12	32
209	2026-08-04 08:46:00+10	9	9	18
209	2026-08-04 08:50:00+10	11	13	24
209	2026-08-04 08:51:00+10	14	3	17
209	2026-08-04 08:54:00+10	8	12	20
209	2026-08-04 09:00:00+10	3	12	15
209	2026-08-04 09:03:00+10	5	4	9
209	2026-08-04 09:14:00+10	5	6	11
209	2026-08-04 09:15:00+10	4	8	12
209	2026-08-04 09:19:00+10	5	3	8
209	2026-08-04 09:20:00+10	5	4	9
209	2026-08-04 09:21:00+10	6	4	10
209	2026-08-04 09:23:00+10	4	3	7
209	2026-08-04 09:26:00+10	9	1	10
209	2026-08-04 09:28:00+10	3	2	5
209	2026-08-04 09:30:00+10	3	5	8
209	2026-08-04 09:38:00+10	4	1	5
209	2026-08-04 09:42:00+10	11	9	20
209	2026-08-04 09:43:00+10	7	1	8
209	2026-08-04 09:45:00+10	5	4	9
209	2026-08-04 09:53:00+10	6	3	9
209	2026-08-04 09:54:00+10	2	3	5
209	2026-08-04 09:57:00+10	2	3	5
209	2026-08-04 10:00:00+10	8	0	8
209	2026-08-04 10:01:00+10	3	1	4
209	2026-08-04 10:02:00+10	9	11	20
209	2026-08-04 10:04:00+10	4	2	6
209	2026-08-04 10:08:00+10	5	0	5
209	2026-08-04 10:10:00+10	2	2	4
209	2026-08-04 10:12:00+10	1	8	9
209	2026-08-04 10:21:00+10	4	3	7
209	2026-08-04 10:22:00+10	5	3	8
209	2026-08-04 10:24:00+10	4	0	4
209	2026-08-04 10:26:00+10	11	2	13
209	2026-08-04 10:29:00+10	8	6	14
209	2026-08-04 10:31:00+10	10	2	12
209	2026-08-04 10:35:00+10	3	2	5
209	2026-08-04 10:39:00+10	7	2	9
209	2026-08-04 10:40:00+10	5	3	8
209	2026-08-04 10:43:00+10	4	7	11
209	2026-08-04 10:44:00+10	3	2	5
209	2026-08-04 10:48:00+10	4	3	7
209	2026-08-04 10:50:00+10	2	2	4
209	2026-08-04 10:51:00+10	2	5	7
209	2026-08-04 10:54:00+10	3	4	7
209	2026-08-04 10:57:00+10	7	6	13
209	2026-08-04 10:59:00+10	6	4	10
209	2026-08-04 11:02:00+10	5	3	8
209	2026-08-04 11:04:00+10	2	0	2
209	2026-08-04 11:08:00+10	8	4	12
209	2026-08-04 11:11:00+10	5	1	6
209	2026-08-04 11:12:00+10	4	8	12
209	2026-08-04 11:14:00+10	5	4	9
209	2026-08-04 11:18:00+10	12	0	12
209	2026-08-04 11:19:00+10	7	8	15
209	2026-08-04 11:24:00+10	2	7	9
209	2026-08-04 11:37:00+10	7	2	9
209	2026-08-04 11:39:00+10	3	1	4
209	2026-08-04 11:42:00+10	5	0	5
209	2026-08-04 11:43:00+10	2	4	6
209	2026-08-04 11:44:00+10	3	1	4
209	2026-08-04 11:47:00+10	7	7	14
209	2026-08-04 11:54:00+10	4	3	7
209	2026-08-04 11:55:00+10	1	1	2
209	2026-08-04 12:01:00+10	4	4	8
209	2026-08-04 12:04:00+10	12	4	16
209	2026-08-04 12:09:00+10	6	2	8
209	2026-08-04 12:10:00+10	9	9	18
209	2026-08-04 12:11:00+10	9	4	13
209	2026-08-04 12:13:00+10	8	6	14
209	2026-08-04 12:14:00+10	9	3	12
209	2026-08-04 12:16:00+10	10	0	10
209	2026-08-04 12:17:00+10	7	6	13
209	2026-08-04 12:20:00+10	10	1	11
209	2026-08-04 12:22:00+10	1	4	5
209	2026-08-04 12:24:00+10	10	2	12
209	2026-08-04 12:29:00+10	5	11	16
209	2026-08-04 12:34:00+10	9	8	17
209	2026-08-04 12:38:00+10	5	8	13
209	2026-08-04 12:40:00+10	13	9	22
209	2026-08-04 12:41:00+10	18	5	23
209	2026-08-04 12:43:00+10	17	8	25
209	2026-08-04 12:44:00+10	12	22	34
209	2026-08-04 12:45:00+10	5	4	9
209	2026-08-04 12:46:00+10	15	3	18
209	2026-08-04 12:48:00+10	11	2	13
209	2026-08-04 12:50:00+10	10	21	31
209	2026-08-04 12:58:00+10	9	10	19
209	2026-08-04 13:00:00+10	3	3	6
209	2026-08-04 13:10:00+10	12	7	19
209	2026-08-04 13:13:00+10	4	6	10
209	2026-08-04 13:25:00+10	6	5	11
209	2026-08-04 13:26:00+10	1	3	4
209	2026-08-04 13:29:00+10	8	9	17
209	2026-08-04 13:30:00+10	9	5	14
209	2026-08-04 13:32:00+10	6	16	22
209	2026-08-04 13:34:00+10	5	15	20
209	2026-08-04 13:35:00+10	8	10	18
209	2026-08-04 13:38:00+10	8	8	16
209	2026-08-04 13:48:00+10	7	6	13
209	2026-08-04 13:59:00+10	0	12	12
209	2026-08-04 14:01:00+10	8	2	10
209	2026-08-04 14:04:00+10	10	9	19
209	2026-08-04 14:05:00+10	10	15	25
209	2026-08-04 14:09:00+10	6	8	14
209	2026-08-04 14:15:00+10	1	5	6
209	2026-08-04 14:22:00+10	5	6	11
209	2026-08-04 14:23:00+10	4	6	10
209	2026-08-04 14:25:00+10	4	8	12
209	2026-08-04 14:26:00+10	2	5	7
209	2026-08-04 14:29:00+10	7	6	13
209	2026-08-04 14:30:00+10	2	7	9
209	2026-08-04 14:33:00+10	2	2	4
209	2026-08-04 14:34:00+10	1	6	7
209	2026-08-04 14:35:00+10	6	12	18
209	2026-08-04 14:37:00+10	15	3	18
209	2026-08-04 14:38:00+10	7	8	15
\.


--
-- Data for Name: refuge; Type: TABLE DATA; Schema: serving; Owner: -
--

COPY serving.refuge (location_id, landmark_id, feature_name, theme_name, sub_theme, sensory_load, latitude, longitude, walk_m, walk_minutes, straight_m, detour_ratio, distance_reliable) FROM stdin;
1	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	458.82	5.7	299.20	1.53	t
1	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	386.00	4.8	243.37	1.59	t
1	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	527.39	6.6	444.36	1.19	t
1	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	481.93	6.0	289.42	1.67	t
1	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	699.44	8.7	588.98	1.19	t
1	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	441.70	5.5	356.01	1.24	t
1	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	678.04	8.5	572.68	1.18	t
1	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	763.86	9.5	608.73	1.25	t
1	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	655.37	8.2	455.80	1.44	t
1	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	464.22	5.8	321.54	1.44	t
1	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	547.19	6.8	366.85	1.49	t
1	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	612.65	7.7	469.40	1.31	t
2	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	353.58	4.4	221.83	1.59	t
2	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	446.31	5.6	322.15	1.39	t
2	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	494.97	6.2	413.93	1.20	t
2	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	449.51	5.6	273.87	1.64	t
2	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	665.98	8.3	559.96	1.19	t
2	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	644.58	8.1	544.48	1.18	t
2	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	730.40	9.1	582.98	1.25	t
2	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	455.55	5.7	389.59	1.17	t
2	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	448.34	5.6	309.11	1.45	t
2	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	669.22	8.4	483.87	1.38	t
2	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	531.31	6.6	357.81	1.48	t
2	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	626.50	7.8	491.69	1.27	t
3	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	100.60	1.3	72.05	1.40	t
3	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	283.46	3.5	190.79	1.49	t
3	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	500.54	6.3	375.80	1.33	t
3	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	467.22	5.8	353.33	1.32	t
3	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	485.50	6.1	393.55	1.23	t
3	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	545.03	6.8	434.74	1.25	t
3	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	713.44	8.9	527.33	1.35	t
3	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	653.38	8.2	504.52	1.30	t
3	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	690.37	8.6	544.02	1.27	t
3	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	794.77	9.9	724.42	1.10	t
3	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	773.34	9.7	569.31	1.36	t
4	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	192.74	2.4	105.68	1.82	t
4	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	334.13	4.2	269.89	1.24	t
4	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	288.67	3.6	175.41	1.65	t
4	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	505.14	6.3	415.97	1.21	t
4	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	483.74	6.0	401.04	1.21	t
4	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	569.56	7.1	442.54	1.29	t
4	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	378.23	4.7	276.62	1.37	t
4	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	595.69	7.4	463.21	1.29	t
4	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	351.26	4.4	219.11	1.60	t
4	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	561.18	7.0	528.91	1.06	t
4	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	773.37	9.7	555.95	1.39	t
4	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	730.65	9.1	534.17	1.37	t
5	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	163.93	2.0	137.52	1.19	t
5	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	285.97	3.6	163.70	1.75	t
5	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	494.07	6.2	458.66	1.08	t
5	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	371.79	4.6	226.15	1.64	t
5	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	516.91	6.5	253.27	2.04	t
5	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	533.56	6.7	401.76	1.33	t
5	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	530.94	6.6	425.88	1.25	t
5	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	464.59	5.8	371.42	1.25	t
5	177688366	Riverslide Skate Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820789	144.972952	626.67	7.8	500.53	1.25	t
5	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	288.85	3.6	199.44	1.45	t
5	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	573.34	7.2	469.07	1.22	t
5	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	719.70	9.0	656.21	1.10	t
5	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	810.08	10.1	772.84	1.05	t
5	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	632.43	7.9	467.78	1.35	t
5	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	657.65	8.2	497.69	1.32	t
5	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	517.77	6.5	431.85	1.20	t
5	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	613.70	7.7	449.67	1.36	t
6	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	298.33	3.7	259.02	1.15	t
6	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	435.69	5.4	247.79	1.76	t
6	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	383.51	4.8	326.91	1.17	t
6	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	721.56	9.0	572.01	1.26	t
6	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	718.94	9.0	558.77	1.29	t
6	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	779.45	9.7	674.24	1.16	t
6	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	652.59	8.2	432.89	1.51	t
6	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	505.55	6.3	347.13	1.46	t
6	177688366	Riverslide Skate Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820789	144.972952	814.67	10.2	675.12	1.21	t
6	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	591.37	7.4	418.68	1.41	t
6	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	447.05	5.6	299.40	1.49	t
6	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	684.05	8.6	567.78	1.20	t
6	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	579.45	7.2	452.70	1.28	t
6	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	635.34	7.9	489.36	1.30	t
6	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	731.27	9.1	533.29	1.37	t
6	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	788.01	9.9	564.88	1.40	t
8	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	244.09	3.1	218.35	1.12	t
8	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	366.49	4.6	208.83	1.75	t
8	221051412	Point Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.823352	144.942102	724.19	9.1	447.99	1.62	t
8	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	782.69	9.8	608.23	1.29	t
8	131854732	Polly Woodside	Place Of Assembly	Art Gallery/Museum	low	-37.824257	144.953478	720.32	9.0	572.80	1.26	t
9	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	639.28	8.0	463.02	1.38	t
9	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	459.35	5.7	394.68	1.16	t
9	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	345.01	4.3	280.75	1.23	t
9	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	712.76	8.9	374.96	1.90	t
9	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	753.52	9.4	543.76	1.39	t
10	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	399.29	5.0	249.69	1.60	t
10	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	393.88	4.9	314.82	1.25	t
10	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	792.41	9.9	709.88	1.12	t
11	192139557	New Quay	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.815218	144.941618	181.09	2.3	172.02	1.05	t
12	192139557	New Quay	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.815218	144.941618	155.67	1.9	134.89	1.15	t
14	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	14.84	0.2	8.96	1.66	t
14	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	631.64	7.9	380.40	1.66	t
14	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	631.31	7.9	320.09	1.97	t
14	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	544.45	6.8	242.19	2.25	t
14	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	651.48	8.1	587.45	1.11	t
14	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	773.52	9.7	607.67	1.27	t
14	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	738.86	9.2	546.14	1.35	t
17	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	315.81	3.9	253.63	1.25	t
17	108214342	St Patricks Cathedral	Place of Worship	Church	low	-37.810114	144.975902	523.20	6.5	455.26	1.15	t
17	201248849	St Peter's Eastern Hill	Place of Worship	Church	low	-37.809709	144.975259	561.91	7.0	470.31	1.19	t
17	67137549	Lutheran Trinity Church	Place of Worship	Church	low	-37.810976	144.975729	446.04	5.6	367.05	1.22	t
17	58576798	Sinclair's Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814541	144.980555	806.38	10.1	650.95	1.24	t
17	232951634	Fire Services Museum Victoria	Place Of Assembly	Art Gallery/Museum	low	-37.808576	144.975374	710.29	8.9	592.01	1.20	t
17	197026447	Cooks' Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814460	144.979471	660.51	8.3	555.52	1.19	t
17	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	696.18	8.7	493.32	1.41	t
17	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	406.18	5.1	366.70	1.11	t
17	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	482.99	6.0	424.73	1.14	t
17	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	509.90	6.4	469.14	1.09	t
17	204541358	Parliament Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.809853	144.973462	663.58	8.3	419.90	1.58	t
17	76200894	East Melbourne Synagogue	Place of Worship	Synagogue	low	-37.809114	144.974222	705.03	8.8	509.02	1.39	t
17	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	587.89	7.3	540.73	1.09	t
17	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	709.42	8.9	612.48	1.16	t
17	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	679.42	8.5	473.76	1.43	t
17	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	815.75	10.2	588.92	1.39	t
18	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	347.72	4.3	275.62	1.26	t
18	108214342	St Patricks Cathedral	Place of Worship	Church	low	-37.810114	144.975902	555.11	6.9	447.34	1.24	t
18	201248849	St Peter's Eastern Hill	Place of Worship	Church	low	-37.809709	144.975259	593.82	7.4	458.77	1.29	t
18	67137549	Lutheran Trinity Church	Place of Worship	Church	low	-37.810976	144.975729	477.95	6.0	361.71	1.32	t
18	232951634	Fire Services Museum Victoria	Place Of Assembly	Art Gallery/Museum	low	-37.808576	144.975374	742.20	9.3	578.91	1.28	t
18	197026447	Cooks' Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814460	144.979471	692.42	8.7	574.80	1.20	t
18	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	375.67	4.7	356.37	1.05	t
18	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	715.12	8.9	512.90	1.39	t
18	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	452.48	5.7	414.71	1.09	t
18	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	479.39	6.0	459.25	1.04	t
18	204541358	Parliament Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.809853	144.973462	645.35	8.1	401.46	1.61	t
18	76200894	East Melbourne Synagogue	Place of Worship	Synagogue	low	-37.809114	144.974222	686.80	8.6	492.83	1.39	t
18	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	557.38	7.0	530.87	1.05	t
18	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	645.79	8.1	448.79	1.44	t
18	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	722.07	9.0	612.10	1.18	t
18	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	782.12	9.8	564.04	1.39	t
19	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	303.75	3.8	256.48	1.18	t
19	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	640.29	8.0	512.40	1.25	t
19	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	380.68	4.8	276.28	1.38	t
19	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	527.55	6.6	343.27	1.54	t
19	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	467.49	5.8	320.48	1.46	t
19	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	504.48	6.3	362.19	1.39	t
19	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	608.88	7.6	544.25	1.12	t
19	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	587.45	7.3	392.26	1.50	t
19	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	499.68	6.2	339.49	1.47	t
19	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	689.06	8.6	539.19	1.28	t
19	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	782.91	9.8	680.83	1.15	t
19	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	761.51	9.5	661.31	1.15	t
19	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	496.86	6.2	372.78	1.33	t
20	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	297.91	3.7	174.83	1.70	t
20	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	484.18	6.1	408.33	1.19	t
20	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	188.00	2.4	137.52	1.37	t
20	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	402.22	5.0	316.92	1.27	t
20	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	474.56	5.9	330.83	1.43	t
20	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	431.77	5.4	306.35	1.41	t
20	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	634.14	7.9	511.92	1.24	t
20	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	734.04	9.2	583.22	1.26	t
20	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	546.54	6.8	504.14	1.08	t
20	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	550.29	6.9	360.95	1.52	t
20	204541358	Parliament Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.809853	144.973462	688.44	8.6	503.39	1.37	t
20	201248849	St Peter's Eastern Hill	Place of Worship	Church	low	-37.809709	144.975259	790.33	9.9	655.67	1.21	t
20	76200894	East Melbourne Synagogue	Place of Worship	Synagogue	low	-37.809114	144.974222	729.89	9.1	600.06	1.22	t
21	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	233.27	2.9	218.84	1.07	t
21	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	305.61	3.8	226.11	1.35	t
21	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	315.28	3.9	221.59	1.42	t
21	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	565.09	7.1	476.46	1.19	t
21	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	408.38	5.1	280.77	1.45	t
21	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	348.91	4.4	242.71	1.44	t
21	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	810.63	10.1	583.66	1.39	t
21	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	795.03	9.9	558.89	1.42	t
21	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	381.34	4.8	251.51	1.52	t
21	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	542.25	6.8	429.06	1.26	t
21	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	604.64	7.6	585.76	1.03	t
21	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	677.17	8.5	487.58	1.39	t
23	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	470.79	5.9	350.11	1.34	t
23	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	455.75	5.7	359.18	1.27	t
23	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	589.17	7.4	435.32	1.35	t
23	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	418.54	5.2	237.45	1.76	t
23	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	637.91	8.0	587.26	1.09	t
23	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	756.49	9.5	712.45	1.06	t
23	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	716.51	9.0	518.34	1.38	t
23	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	783.54	9.8	636.21	1.23	t
24	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	356.29	4.5	214.42	1.66	t
24	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	491.21	6.1	373.29	1.32	t
24	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	476.17	6.0	381.10	1.25	t
24	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	759.00	9.5	522.39	1.45	t
24	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	635.47	7.9	445.56	1.43	t
24	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	653.37	8.2	595.15	1.10	t
24	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	771.95	9.6	716.94	1.08	t
24	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	764.11	9.6	612.37	1.25	t
25	131854732	Polly Woodside	Place Of Assembly	Art Gallery/Museum	low	-37.824257	144.953478	257.99	3.2	226.94	1.14	t
25	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	330.73	4.1	247.62	1.34	t
25	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	368.19	4.6	266.54	1.38	t
25	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	613.90	7.7	509.84	1.20	t
25	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	794.69	9.9	661.52	1.20	t
25	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	736.74	9.2	744.16	0.99	t
27	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	679.32	8.5	582.54	1.17	t
27	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	763.03	9.5	572.44	1.33	t
27	58817347	St Mary's Anglican Church	Place of Worship	Church	low	-37.803166	144.953762	581.08	7.3	399.81	1.45	t
27	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	796.82	10.0	570.82	1.40	t
29	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	330.18	4.1	278.16	1.19	t
29	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	299.17	3.7	237.74	1.26	t
29	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	327.56	4.1	274.72	1.19	t
29	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	261.21	3.3	224.04	1.17	t
29	177688366	Riverslide Skate Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820789	144.972952	423.29	5.3	381.64	1.11	t
29	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	680.15	8.5	442.97	1.54	t
29	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	421.21	5.3	265.34	1.59	t
29	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	665.87	8.3	505.35	1.32	t
29	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	426.25	5.3	348.93	1.22	t
29	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	507.03	6.3	296.27	1.71	t
29	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	357.13	4.5	176.91	2.02	t
29	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	769.83	9.6	602.10	1.28	t
29	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	795.05	9.9	623.58	1.27	t
29	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	655.17	8.2	580.56	1.13	t
29	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	751.10	9.4	590.05	1.27	t
30	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	355.45	4.4	250.32	1.42	t
30	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	261.42	3.3	183.51	1.42	t
30	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	456.84	5.7	396.23	1.15	t
30	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	283.96	3.5	239.49	1.19	t
30	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	435.57	5.4	371.58	1.17	t
30	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	490.77	6.1	411.22	1.19	t
30	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	541.25	6.8	409.10	1.32	t
30	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	572.78	7.2	419.93	1.36	t
30	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	535.30	6.7	412.67	1.30	t
30	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	801.55	10.0	645.28	1.24	t
30	204541358	Parliament Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.809853	144.973462	730.43	9.1	624.39	1.17	t
30	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	743.95	9.3	594.36	1.25	t
30	76200894	East Melbourne Synagogue	Place of Worship	Synagogue	low	-37.809114	144.974222	771.88	9.6	711.97	1.08	t
31	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	223.47	2.8	111.18	2.01	t
31	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	293.08	3.7	176.99	1.66	t
31	61193100	Our Lady of Lebanon Church	Place of Worship	Church	low	-37.802577	144.969335	502.01	6.3	260.35	1.93	t
31	143298187	Carlton Gardens North	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.801769	144.971998	675.60	8.4	475.30	1.42	t
31	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	574.21	7.2	357.68	1.61	t
31	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	464.91	5.8	394.51	1.18	t
31	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	695.40	8.7	681.82	1.02	t
31	223409774	Macarthur Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798332	144.971514	795.39	9.9	572.06	1.39	t
31	128223805	Murchinson Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.800274	144.973059	785.60	9.8	590.07	1.33	t
31	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	786.23	9.8	676.30	1.16	t
35	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	271.28	3.4	197.47	1.37	t
35	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	366.88	4.6	184.81	1.99	t
35	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	688.93	8.6	591.30	1.17	t
35	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	686.31	8.6	548.22	1.25	t
35	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	524.08	6.6	428.38	1.22	t
35	177688366	Riverslide Skate Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820789	144.972952	782.04	9.8	694.25	1.13	t
35	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	795.12	9.9	510.16	1.56	t
35	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	708.26	8.9	424.19	1.67	t
35	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	646.12	8.1	452.30	1.43	t
35	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	731.94	9.1	518.85	1.41	t
35	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	568.54	7.1	386.04	1.47	t
35	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	611.46	7.6	425.67	1.44	t
35	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	799.75	10.0	620.48	1.29	t
36	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	491.22	6.1	303.15	1.62	t
36	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	621.38	7.8	443.57	1.40	t
36	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	776.64	9.7	570.43	1.36	t
36	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	635.85	7.9	564.32	1.13	t
36	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	676.43	8.5	526.81	1.28	t
36	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	731.78	9.1	635.90	1.15	t
36	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	796.03	10.0	680.46	1.17	t
36	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	742.59	9.3	559.93	1.33	t
37	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	334.82	4.2	191.36	1.75	t
37	143298187	Carlton Gardens North	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.801769	144.971998	576.73	7.2	441.95	1.30	t
37	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	392.15	4.9	257.07	1.53	t
37	61193100	Our Lady of Lebanon Church	Place of Worship	Church	low	-37.802577	144.969335	411.51	5.1	261.70	1.57	t
37	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	702.88	8.8	422.32	1.66	t
37	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	510.24	6.4	462.60	1.10	t
37	223409774	Macarthur Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798332	144.971514	696.52	8.7	496.86	1.40	t
37	128223805	Murchinson Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.800274	144.973059	686.73	8.6	535.69	1.28	t
37	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	793.91	9.9	757.09	1.05	t
37	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	688.61	8.6	597.89	1.15	t
39	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	238.86	3.0	94.90	2.52	t
39	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	250.39	3.1	150.41	1.66	t
39	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	331.68	4.1	193.71	1.71	t
39	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	579.97	7.2	404.04	1.44	t
39	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	482.29	6.0	342.64	1.41	t
39	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	739.43	9.2	550.75	1.34	t
39	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	772.52	9.7	459.26	1.68	t
39	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	809.91	10.1	431.20	1.88	t
39	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	753.02	9.4	530.86	1.42	t
39	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	617.44	7.7	434.09	1.42	t
39	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	408.79	5.1	263.65	1.55	t
39	67137549	Lutheran Trinity Church	Place of Worship	Church	low	-37.810976	144.975729	808.20	10.1	596.23	1.36	t
39	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	803.09	10.0	649.99	1.24	t
40	204541358	Parliament Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.809853	144.973462	272.01	3.4	105.35	2.58	t
40	201248849	St Peter's Eastern Hill	Place of Worship	Church	low	-37.809709	144.975259	373.90	4.7	263.95	1.42	t
40	76200894	East Melbourne Synagogue	Place of Worship	Synagogue	low	-37.809114	144.974222	313.46	3.9	196.92	1.59	t
40	108214342	St Patricks Cathedral	Place of Worship	Church	low	-37.810114	144.975902	433.41	5.4	318.83	1.36	t
40	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	403.61	5.0	280.82	1.44	t
40	213062595	Royal Exhibition Building	Place Of Assembly	Art Gallery/Museum	low	-37.804603	144.971522	678.43	8.5	602.99	1.13	f
40	232951634	Fire Services Museum Victoria	Place Of Assembly	Art Gallery/Museum	low	-37.808576	144.975374	479.70	6.0	314.48	1.53	t
40	194468052	Carlton Gardens South	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.806068	144.971266	508.09	6.4	445.37	1.14	t
40	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	472.58	5.9	361.35	1.31	t
40	67137549	Lutheran Trinity Church	Place of Worship	Church	low	-37.810976	144.975729	602.59	7.5	322.43	1.87	t
40	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	658.26	8.2	586.78	1.12	t
40	153834867	Greek Orthodox Church	Place of Worship	Church	low	-37.808806	144.978259	731.79	9.1	541.93	1.35	t
40	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	775.35	9.7	559.25	1.39	t
40	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	798.52	10.0	604.97	1.32	t
41	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	191.54	2.4	75.16	2.55	t
41	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	294.42	3.7	223.11	1.32	t
41	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	273.02	3.4	216.83	1.26	t
41	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	358.84	4.5	278.19	1.29	t
41	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	740.28	9.3	473.43	1.56	t
41	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	756.93	9.5	612.43	1.24	t
41	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	754.31	9.4	660.51	1.14	t
41	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	687.96	8.6	614.44	1.12	t
41	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	409.11	5.1	276.63	1.48	t
41	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	434.33	5.4	324.76	1.34	t
41	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	771.04	9.6	569.90	1.35	t
41	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	278.38	3.5	203.12	1.37	t
41	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	704.88	8.8	518.57	1.36	t
41	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	374.31	4.7	243.66	1.54	t
41	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	809.87	10.1	662.91	1.22	t
41	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	770.65	9.6	632.38	1.22	t
41	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	775.36	9.7	741.84	1.05	t
42	263126126	The Ian Potter Museum Of Art	Place Of Assembly	Art Gallery/Museum	low	-37.797394	144.964157	739.46	9.2	300.44	2.46	t
42	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	445.65	5.6	316.11	1.41	t
42	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	567.69	7.1	379.08	1.50	t
42	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	617.76	7.7	322.27	1.92	t
42	203392393	University Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.800411	144.960398	693.09	8.7	306.66	2.26	t
42	61193100	Our Lady of Lebanon Church	Place of Worship	Church	low	-37.802577	144.969335	723.44	9.0	554.77	1.30	t
43	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	629.44	7.9	497.85	1.26	t
43	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	751.48	9.4	542.51	1.39	t
43	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	784.37	9.8	477.93	1.64	t
43	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	700.66	8.8	511.52	1.37	t
44	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	797.11	10.0	661.60	1.20	t
44	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	553.62	6.9	418.66	1.32	t
44	223409774	Macarthur Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798332	144.971514	723.54	9.0	641.60	1.13	t
45	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	253.93	3.2	133.86	1.90	t
45	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	395.32	4.9	342.59	1.15	t
45	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	349.86	4.4	184.58	1.90	t
45	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	569.35	7.1	483.56	1.18	t
45	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	547.95	6.8	466.07	1.18	t
45	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	633.77	7.9	499.81	1.27	t
45	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	331.50	4.1	221.02	1.50	t
45	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	564.42	7.1	408.56	1.38	t
45	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	414.47	5.2	271.92	1.52	t
45	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	502.09	6.3	453.63	1.11	t
45	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	673.43	8.4	478.90	1.41	t
45	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	630.71	7.9	465.48	1.35	t
46	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	229.77	2.9	113.30	2.03	t
46	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	577.51	7.2	377.58	1.53	t
46	203392393	University Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.800411	144.960398	642.00	8.0	244.56	2.63	t
46	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	660.69	8.3	377.63	1.75	t
47	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	86.64	1.1	79.02	1.10	t
47	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	460.27	5.8	336.05	1.37	t
47	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	752.14	9.4	593.00	1.27	t
47	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	702.86	8.8	486.69	1.44	t
47	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	358.63	4.5	263.66	1.36	t
47	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	798.79	10.0	536.92	1.49	t
47	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	671.62	8.4	560.34	1.20	t
47	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	782.60	9.8	569.19	1.37	t
47	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	694.16	8.7	618.60	1.12	t
48	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	755.83	9.4	638.19	1.18	t
48	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	690.80	8.6	618.46	1.12	t
48	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	735.02	9.2	531.90	1.38	t
48	58817347	St Mary's Anglican Church	Place of Worship	Church	low	-37.803166	144.953762	760.42	9.5	555.33	1.37	t
48	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	805.81	10.1	701.67	1.15	t
48	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	811.67	10.1	649.59	1.25	t
48	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	646.92	8.1	471.51	1.37	t
49	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	638.14	8.0	521.14	1.22	t
49	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	702.02	8.8	574.82	1.22	t
49	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	500.42	6.3	351.00	1.43	t
49	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	660.58	8.3	568.35	1.16	t
49	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	666.44	8.3	517.04	1.29	t
50	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	386.36	4.8	286.74	1.35	t
50	61193100	Our Lady of Lebanon Church	Place of Worship	Church	low	-37.802577	144.969335	722.16	9.0	533.55	1.35	t
50	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	624.94	7.8	507.04	1.23	t
50	223409774	Macarthur Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798332	144.971514	556.28	7.0	379.18	1.47	t
50	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	694.55	8.7	577.52	1.20	t
50	143298187	Carlton Gardens North	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.801769	144.971998	792.29	9.9	587.41	1.35	t
50	128223805	Murchinson Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.800274	144.973059	716.29	9.0	568.78	1.26	t
51	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	481.24	6.0	236.68	2.03	t
51	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	643.19	8.0	487.42	1.32	t
51	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	709.54	8.9	567.02	1.25	t
51	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	641.53	8.0	485.54	1.32	t
51	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	647.39	8.1	480.52	1.35	t
52	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	107.02	1.3	82.57	1.30	t
52	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	772.52	9.7	612.98	1.26	t
52	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	430.41	5.4	293.52	1.47	t
52	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	379.01	4.7	286.87	1.32	t
52	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	776.71	9.7	538.57	1.44	t
52	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	692.24	8.7	606.99	1.14	t
52	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	714.78	8.9	669.75	1.07	t
53	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	211.06	2.6	178.45	1.18	t
53	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	352.45	4.4	241.01	1.46	t
53	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	306.99	3.8	249.07	1.23	t
53	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	517.70	6.5	391.19	1.32	t
53	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	371.24	4.6	293.45	1.27	t
53	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	496.30	6.2	382.53	1.30	t
53	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	582.12	7.3	437.37	1.33	t
53	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	396.55	5.0	351.78	1.13	t
53	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	737.85	9.2	550.54	1.34	t
53	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	594.88	7.4	497.53	1.20	t
53	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	789.75	9.9	594.36	1.33	t
53	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	703.25	8.8	594.18	1.18	t
54	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	217.64	2.7	139.90	1.56	t
54	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	482.14	6.0	368.15	1.31	t
54	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	635.92	7.9	465.47	1.37	t
54	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	426.62	5.3	254.57	1.68	t
54	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	569.18	7.1	296.19	1.92	t
54	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	790.38	9.9	718.25	1.10	t
56	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	108.25	1.4	93.61	1.16	t
56	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	773.75	9.7	615.69	1.26	t
56	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	375.91	4.7	295.44	1.27	t
56	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	421.14	5.3	256.71	1.64	t
56	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	693.68	8.7	631.69	1.10	t
56	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	784.16	9.8	669.29	1.17	t
56	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	815.63	10.2	615.89	1.32	t
56	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	769.10	9.6	698.93	1.10	t
58	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	167.29	2.1	113.22	1.48	t
58	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	740.02	9.3	597.03	1.24	t
58	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	529.42	6.6	388.50	1.36	t
58	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	725.47	9.1	617.00	1.18	t
58	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	794.20	9.9	645.62	1.23	t
59	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	394.83	4.9	219.10	1.80	t
59	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	314.76	3.9	255.09	1.23	t
59	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	554.00	6.9	407.26	1.36	t
59	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	650.96	8.1	608.10	1.07	t
59	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	701.51	8.8	482.47	1.45	t
59	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	511.60	6.4	370.48	1.38	t
59	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	679.85	8.5	496.96	1.37	t
59	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	803.39	10.0	610.99	1.31	t
59	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	746.89	9.3	615.93	1.21	t
61	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	293.46	3.7	208.71	1.41	t
61	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	593.45	7.4	524.56	1.13	t
61	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	393.54	4.9	316.65	1.24	t
61	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	632.78	7.9	471.79	1.34	t
61	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	619.82	7.7	436.98	1.42	t
61	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	608.20	7.6	543.74	1.12	t
61	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	612.97	7.7	418.33	1.47	t
61	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	783.65	9.8	623.21	1.26	t
61	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	792.72	9.9	640.00	1.24	t
61	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	665.20	8.3	555.35	1.20	t
62	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	326.03	4.1	214.69	1.52	t
62	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	235.32	2.9	208.39	1.13	t
62	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	468.81	5.9	379.33	1.24	t
62	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	294.59	3.7	160.84	1.83	t
62	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	732.20	9.2	668.64	1.10	t
62	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	659.68	8.2	527.80	1.25	t
62	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	783.22	9.8	627.41	1.25	t
63	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	263.78	3.3	179.18	1.47	t
63	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	314.81	3.9	191.23	1.65	t
63	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	296.37	3.7	209.32	1.42	t
63	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	379.34	4.7	242.60	1.56	t
63	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	540.34	6.8	411.10	1.31	t
63	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	575.67	7.2	413.20	1.39	t
63	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	552.81	6.9	373.99	1.48	t
63	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	748.31	9.4	629.34	1.19	t
63	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	714.37	8.9	538.83	1.33	t
63	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	692.97	8.7	517.51	1.34	t
63	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	778.79	9.7	537.94	1.45	t
63	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	513.34	6.4	407.33	1.26	t
63	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	494.60	6.2	358.53	1.38	t
66	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	77.34	1.0	50.64	1.53	t
66	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	435.06	5.4	325.50	1.34	t
66	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	401.74	5.0	330.55	1.22	t
66	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	341.04	4.3	229.37	1.49	t
66	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	490.32	6.1	421.42	1.16	t
66	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	466.59	5.8	401.73	1.16	t
66	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	701.55	8.8	571.99	1.23	t
66	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	730.47	9.1	558.40	1.31	t
66	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	670.41	8.4	540.43	1.24	t
66	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	783.56	9.8	593.23	1.32	t
66	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	811.80	10.1	764.05	1.06	t
67	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	354.66	4.4	266.36	1.33	t
67	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	291.66	3.6	180.75	1.61	t
67	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	450.59	5.6	324.51	1.39	t
67	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	420.98	5.3	312.19	1.35	t
67	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	588.61	7.4	433.19	1.36	t
67	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	405.83	5.1	313.02	1.30	t
67	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	491.65	6.1	381.13	1.29	t
67	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	725.97	9.1	469.31	1.55	t
67	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	507.33	6.3	364.02	1.39	t
67	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	532.55	6.7	417.85	1.27	t
67	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	812.58	10.2	634.06	1.28	t
67	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	680.88	8.5	623.41	1.09	t
67	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	774.69	9.7	668.93	1.16	t
67	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	646.75	8.1	522.98	1.24	t
68	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	358.63	4.5	264.03	1.36	t
68	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	295.63	3.7	183.45	1.61	t
68	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	454.56	5.7	322.84	1.41	t
68	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	424.95	5.3	316.05	1.34	t
68	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	592.58	7.4	435.64	1.36	t
68	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	409.80	5.1	316.56	1.29	t
68	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	495.62	6.2	384.34	1.29	t
68	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	729.94	9.1	474.27	1.54	t
68	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	511.30	6.4	362.64	1.41	t
68	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	536.52	6.7	416.75	1.29	t
68	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	816.55	10.2	639.14	1.28	t
68	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	778.66	9.7	669.36	1.16	t
68	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	650.72	8.1	523.03	1.24	t
68	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	684.49	8.6	618.33	1.11	t
69	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	355.92	4.4	266.58	1.34	t
69	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	292.92	3.7	183.91	1.59	t
69	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	451.85	5.6	325.23	1.39	t
69	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	419.72	5.2	315.69	1.33	t
69	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	587.35	7.3	433.05	1.36	t
69	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	404.57	5.1	316.45	1.28	t
69	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	490.39	6.1	384.47	1.28	t
69	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	724.71	9.1	471.88	1.54	t
69	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	508.59	6.4	364.95	1.39	t
69	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	533.81	6.7	418.97	1.27	t
69	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	811.32	10.1	637.02	1.27	t
69	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	679.62	8.5	620.44	1.10	t
69	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	773.43	9.7	667.36	1.16	t
69	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	645.49	8.1	521.17	1.24	t
70	250823061	North Melbourne Uniting	Place of Worship	Church	low	-37.803554	144.947672	378.43	4.7	193.64	1.95	t
70	58817347	St Mary's Anglican Church	Place of Worship	Church	low	-37.803166	144.953762	553.46	6.9	408.77	1.35	t
71	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	493.62	6.2	296.67	1.66	t
71	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	597.34	7.5	389.63	1.53	t
71	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	384.59	4.8	257.74	1.49	t
71	201248849	St Peter's Eastern Hill	Place of Worship	Church	low	-37.809709	144.975259	581.73	7.3	451.09	1.29	t
71	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	516.79	6.5	348.95	1.48	t
71	108214342	St Patricks Cathedral	Place of Worship	Church	low	-37.810114	144.975902	641.24	8.0	469.86	1.36	t
71	204541358	Parliament Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.809853	144.973462	555.82	6.9	333.71	1.67	t
71	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	520.92	6.5	372.78	1.40	t
71	232951634	Fire Services Museum Victoria	Place Of Assembly	Art Gallery/Museum	low	-37.808576	144.975374	738.29	9.2	548.25	1.35	t
71	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	666.56	8.3	462.08	1.44	t
71	76200894	East Melbourne Synagogue	Place of Worship	Synagogue	low	-37.809114	144.974222	597.27	7.5	439.19	1.36	t
71	67137549	Lutheran Trinity Church	Place of Worship	Church	low	-37.810976	144.975729	719.74	9.0	412.61	1.74	t
71	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	675.19	8.4	455.42	1.48	t
72	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	171.92	2.1	68.70	2.50	t
72	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	222.05	2.8	48.99	4.53	f
72	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	307.87	3.8	105.73	2.91	t
72	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	244.73	3.1	98.06	2.50	t
72	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	556.68	7.0	398.18	1.40	t
72	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	689.28	8.6	432.54	1.59	t
72	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	705.93	8.8	459.04	1.54	t
72	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	703.31	8.8	527.50	1.33	t
72	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	636.96	8.0	526.26	1.21	t
72	177688366	Riverslide Skate Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820789	144.972952	799.04	10.0	539.80	1.48	t
72	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	734.58	9.2	599.79	1.22	t
72	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	754.67	9.4	710.00	1.06	t
72	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	469.14	5.9	299.96	1.56	t
72	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	440.80	5.5	322.41	1.37	t
72	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	496.05	6.2	290.65	1.71	t
72	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	473.65	5.9	292.91	1.62	t
75	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	171.56	2.1	139.91	1.23	t
75	197026447	Cooks' Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814460	144.979471	516.19	6.5	428.11	1.21	t
75	15165478	Fitzroy Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.812962	144.980456	639.16	8.0	563.09	1.14	t
75	58576798	Sinclair's Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814541	144.980555	661.52	8.3	520.81	1.27	t
75	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	556.11	7.0	350.17	1.59	t
75	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	756.02	9.5	584.73	1.29	t
75	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	814.94	10.2	563.28	1.45	t
75	108214342	St Patricks Cathedral	Place of Worship	Church	low	-37.810114	144.975902	664.92	8.3	570.55	1.17	t
75	201248849	St Peter's Eastern Hill	Place of Worship	Church	low	-37.809709	144.975259	703.63	8.8	607.50	1.16	t
75	67137549	Lutheran Trinity Church	Place of Worship	Church	low	-37.810976	144.975729	587.76	7.3	473.57	1.24	t
75	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	625.02	7.8	490.89	1.27	t
75	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	697.68	8.7	542.03	1.29	t
75	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	697.58	8.7	646.30	1.08	t
75	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	724.59	9.1	582.38	1.24	t
75	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	802.58	10.0	649.49	1.24	t
76	84626667	Holy Rosary	Place of Worship	Church	low	-37.794809	144.928362	223.05	2.8	178.30	1.25	t
76	95918746	Christ Church Kensington	Place of Worship	Church	low	-37.793211	144.927296	385.53	4.8	307.17	1.26	t
77	192139557	New Quay	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.815218	144.941618	371.58	4.6	254.45	1.46	t
79	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	489.50	6.1	374.35	1.31	t
79	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	289.84	3.6	245.88	1.18	t
79	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	261.08	3.3	172.35	1.51	t
79	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	626.86	7.8	343.95	1.82	t
79	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	320.72	4.0	257.61	1.24	t
79	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	406.54	5.1	331.73	1.23	t
79	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	766.46	9.6	613.27	1.25	t
79	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	750.41	9.4	576.44	1.30	t
79	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	747.79	9.3	594.18	1.26	t
79	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	681.44	8.5	508.24	1.34	t
79	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	604.66	7.6	429.37	1.41	t
79	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	690.18	8.6	655.73	1.05	t
79	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	629.88	7.9	475.43	1.32	t
79	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	480.78	6.0	353.65	1.36	t
79	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	585.58	7.3	522.71	1.12	t
79	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	576.71	7.2	397.14	1.45	t
79	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	808.79	10.1	749.32	1.08	t
80	131888455	Australian Centre for Contemporary Art	Place Of Assembly	Art Gallery/Museum	low	-37.826605	144.967253	765.10	9.6	537.19	1.42	t
80	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	775.94	9.7	605.24	1.28	t
80	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	776.36	9.7	715.96	1.08	t
81	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	701.54	8.8	651.99	1.08	t
82	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	593.55	7.4	490.38	1.21	t
82	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	637.77	8.0	492.56	1.29	t
82	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	689.67	8.6	615.83	1.12	t
82	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	695.53	8.7	538.57	1.29	t
82	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	578.34	7.2	420.18	1.38	t
83	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	595.43	7.4	489.20	1.22	t
83	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	639.65	8.0	498.62	1.28	t
83	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	676.53	8.5	609.70	1.11	t
83	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	682.39	8.5	533.65	1.28	t
83	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	565.20	7.1	413.50	1.37	t
84	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	422.42	5.3	303.56	1.39	t
84	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	559.78	7.0	376.74	1.49	t
84	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	817.00	10.2	661.81	1.23	t
84	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	814.38	10.2	666.85	1.22	t
84	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	748.03	9.4	557.59	1.34	t
84	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	408.50	5.1	345.50	1.18	t
84	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	608.50	7.6	563.21	1.08	t
84	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	340.51	4.3	259.02	1.31	t
84	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	480.56	6.0	426.11	1.13	t
84	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	400.15	5.0	356.89	1.12	t
84	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	485.97	6.1	430.90	1.13	t
84	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	518.29	6.5	397.07	1.31	t
84	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	614.22	7.7	451.84	1.36	t
84	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	673.84	8.4	489.18	1.38	t
84	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	699.06	8.7	540.42	1.29	t
84	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	722.95	9.0	715.49	1.01	t
85	84626667	Holy Rosary	Place of Worship	Church	low	-37.794809	144.928362	244.55	3.1	132.07	1.85	t
85	95918746	Christ Church Kensington	Place of Worship	Church	low	-37.793211	144.927296	312.21	3.9	247.40	1.26	t
85	183252251	J.J Holland Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798236	144.923837	803.56	10.0	676.53	1.19	t
86	250823061	North Melbourne Uniting	Place of Worship	Church	low	-37.803554	144.947672	214.10	2.7	133.69	1.60	t
86	58817347	St Mary's Anglican Church	Place of Worship	Church	low	-37.803166	144.953762	454.21	5.7	411.33	1.10	t
87	250823061	North Melbourne Uniting	Place of Worship	Church	low	-37.803554	144.947672	393.89	4.9	175.25	2.25	t
87	58817347	St Mary's Anglican Church	Place of Worship	Church	low	-37.803166	144.953762	568.92	7.1	427.73	1.33	t
89	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	344.03	4.3	252.68	1.36	t
89	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	589.64	7.4	447.41	1.32	t
89	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	727.00	9.1	466.88	1.56	t
89	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	281.03	3.5	159.87	1.76	t
89	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	439.96	5.5	308.52	1.43	t
89	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	418.76	5.2	293.64	1.43	t
89	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	397.36	5.0	293.57	1.35	t
89	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	483.18	6.0	360.97	1.34	t
89	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	496.70	6.2	347.17	1.43	t
89	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	775.72	9.7	688.28	1.13	t
89	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	521.92	6.5	400.22	1.30	t
89	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	812.30	10.2	627.80	1.29	t
89	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	647.78	8.1	542.96	1.19	t
89	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	700.63	8.8	630.48	1.11	t
91	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	777.20	9.7	579.72	1.34	t
92	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	782.44	9.8	568.52	1.38	t
93	200784492	National Sports Museum	Place Of Assembly	Art Gallery/Museum	low	-37.818954	144.984670	585.51	7.3	466.53	1.26	t
93	263974868	Thoroughbred Racing Gallery	Place Of Assembly	Art Gallery/Museum	low	-37.818866	144.983970	697.51	8.7	481.09	1.45	f
93	264158889	Holy Trinity	Place of Worship	Church	low	-37.814067	144.983197	446.13	5.6	298.28	1.50	t
93	146699441	Powlett Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811693	144.987276	681.06	8.5	374.16	1.82	t
93	151790818	Darling Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.812992	144.989063	673.33	8.4	322.92	2.09	t
93	182570196	Melbourne Unitarian Church	Place of Worship	Church	low	-37.811449	144.984665	657.66	8.2	421.21	1.56	t
94	15165478	Fitzroy Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.812962	144.980456	209.18	2.6	222.05	0.94	t
94	197026447	Cooks' Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814460	144.979471	144.17	1.8	86.98	1.66	t
94	58576798	Sinclair's Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814541	144.980555	356.67	4.5	181.85	1.96	t
94	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	389.13	4.9	226.15	1.72	t
94	264158889	Holy Trinity	Place of Worship	Church	low	-37.814067	144.983197	517.32	6.5	411.41	1.26	t
94	182570196	Melbourne Unitarian Church	Place of Worship	Church	low	-37.811449	144.984665	683.21	8.5	623.02	1.10	t
94	67137549	Lutheran Trinity Church	Place of Worship	Church	low	-37.810976	144.975729	612.78	7.7	438.41	1.40	t
94	153834867	Greek Orthodox Church	Place of Worship	Church	low	-37.808806	144.978259	674.27	8.4	605.22	1.11	t
94	108214342	St Patricks Cathedral	Place of Worship	Church	low	-37.810114	144.975902	746.99	9.3	513.66	1.45	t
94	201248849	St Peter's Eastern Hill	Place of Worship	Church	low	-37.809709	144.975259	785.70	9.8	580.01	1.35	t
95	15165478	Fitzroy Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.812962	144.980456	400.61	5.0	237.81	1.68	t
95	58576798	Sinclair's Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814541	144.980555	279.83	3.5	119.45	2.34	t
95	197026447	Cooks' Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814460	144.979471	500.61	6.3	50.36	9.94	f
95	263974868	Thoroughbred Racing Gallery	Place Of Assembly	Art Gallery/Museum	low	-37.818866	144.983970	761.06	9.5	605.71	1.26	f
95	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	519.23	6.5	296.05	1.75	t
95	200784492	National Sports Museum	Place Of Assembly	Art Gallery/Museum	low	-37.818954	144.984670	825.58	10.3	655.93	1.26	t
95	264158889	Holy Trinity	Place of Worship	Church	low	-37.814067	144.983197	575.54	7.2	357.04	1.61	t
96	15165478	Fitzroy Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.812962	144.980456	400.61	5.0	249.82	1.60	t
96	58576798	Sinclair's Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814541	144.980555	279.83	3.5	125.27	2.23	t
96	197026447	Cooks' Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814460	144.979471	500.61	6.3	62.76	7.98	f
96	263974868	Thoroughbred Racing Gallery	Place Of Assembly	Art Gallery/Museum	low	-37.818866	144.983970	761.06	9.5	597.42	1.27	f
96	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	519.23	6.5	297.33	1.75	t
96	200784492	National Sports Museum	Place Of Assembly	Art Gallery/Museum	low	-37.818954	144.984670	825.58	10.3	648.22	1.27	t
96	264158889	Holy Trinity	Place of Worship	Church	low	-37.814067	144.983197	575.54	7.2	361.73	1.59	t
99	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	199.04	2.5	97.50	2.04	t
99	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	340.43	4.3	289.06	1.18	t
99	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	294.97	3.7	161.79	1.82	t
99	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	514.46	6.4	432.00	1.19	t
99	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	493.06	6.2	415.50	1.19	t
99	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	578.88	7.2	452.75	1.28	t
99	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	600.09	7.5	452.30	1.33	t
99	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	300.72	3.8	203.70	1.48	t
99	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	383.69	4.8	259.68	1.48	t
99	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	552.38	6.9	507.25	1.09	t
99	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	723.72	9.0	524.57	1.38	t
99	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	681.00	8.5	502.95	1.35	t
102	250823061	North Melbourne Uniting	Place of Worship	Church	low	-37.803554	144.947672	297.80	3.7	185.07	1.61	t
102	58817347	St Mary's Anglican Church	Place of Worship	Church	low	-37.803166	144.953762	415.33	5.2	351.73	1.18	t
103	101149284	Newmarket Reserve	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.787847	144.922972	675.37	8.4	522.64	1.29	t
103	95918746	Christ Church Kensington	Place of Worship	Church	low	-37.793211	144.927296	522.35	6.5	444.17	1.18	t
103	84626667	Holy Rosary	Place of Worship	Church	low	-37.794809	144.928362	773.13	9.7	607.06	1.27	t
104	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	686.01	8.6	432.73	1.59	t
104	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	773.35	9.7	520.30	1.49	t
104	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	712.58	8.9	502.31	1.42	t
104	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	580.89	7.3	431.27	1.35	t
104	61193100	Our Lady of Lebanon Church	Place of Worship	Church	low	-37.802577	144.969335	786.72	9.8	553.75	1.42	t
104	223409774	Macarthur Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798332	144.971514	701.67	8.8	531.07	1.32	t
105	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	709.33	8.9	436.42	1.63	t
105	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	796.67	10.0	514.31	1.55	t
105	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	735.90	9.2	505.46	1.46	t
105	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	604.21	7.6	442.54	1.37	t
105	61193100	Our Lady of Lebanon Church	Place of Worship	Church	low	-37.802577	144.969335	810.04	10.1	566.16	1.43	t
105	223409774	Macarthur Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798332	144.971514	724.99	9.1	548.40	1.32	t
106	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	722.58	9.0	510.25	1.42	t
106	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	693.29	8.7	441.00	1.57	t
106	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	719.86	9.0	509.50	1.41	t
106	61193100	Our Lady of Lebanon Church	Place of Worship	Church	low	-37.802577	144.969335	794.00	9.9	577.85	1.37	t
106	209365524	All Nations Uniting Church	Place of Worship	Church	low	-37.795916	144.968981	631.88	7.9	452.20	1.40	t
106	223409774	Macarthur Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.798332	144.971514	752.66	9.4	563.52	1.34	t
107	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	327.10	4.1	244.52	1.34	t
107	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	494.68	6.2	343.98	1.44	t
107	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	306.49	3.8	272.49	1.12	t
107	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	752.84	9.4	532.65	1.41	t
107	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	599.20	7.5	489.24	1.22	t
107	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	694.35	8.7	468.05	1.48	t
107	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	694.19	8.7	653.26	1.06	t
108	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	329.89	4.1	274.69	1.20	t
108	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	548.29	6.9	389.03	1.41	t
108	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	291.51	3.6	247.06	1.18	t
108	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	701.63	8.8	477.53	1.47	t
108	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	602.42	7.5	509.19	1.18	t
108	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	696.46	8.7	492.93	1.41	t
108	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	732.28	9.2	683.21	1.07	t
109	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	207.37	2.6	161.01	1.29	t
109	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	347.41	4.3	250.40	1.39	t
109	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	428.57	5.4	361.81	1.18	t
109	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	571.72	7.1	385.39	1.48	t
109	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	730.83	9.1	694.41	1.05	t
109	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	710.86	8.9	545.74	1.30	t
116	15165478	Fitzroy Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.812962	144.980456	400.61	5.0	241.07	1.66	t
116	58576798	Sinclair's Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814541	144.980555	279.83	3.5	116.76	2.40	t
116	197026447	Cooks' Cottage	Place Of Assembly	Art Gallery/Museum	low	-37.814460	144.979471	500.61	6.3	54.59	9.17	f
116	263974868	Thoroughbred Racing Gallery	Place Of Assembly	Art Gallery/Museum	low	-37.818866	144.983970	761.06	9.5	597.85	1.27	f
116	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	519.23	6.5	302.19	1.72	t
116	200784492	National Sports Museum	Place Of Assembly	Art Gallery/Museum	low	-37.818954	144.984670	825.58	10.3	648.10	1.27	t
116	264158889	Holy Trinity	Place of Worship	Church	low	-37.814067	144.983197	575.54	7.2	353.71	1.63	t
117	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	403.08	5.0	243.40	1.66	t
117	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	462.00	5.8	218.11	2.12	t
117	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	547.82	6.8	159.31	3.44	f
117	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	440.53	5.5	278.02	1.58	t
117	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	388.71	4.9	282.23	1.38	t
117	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	360.37	4.5	261.23	1.38	t
117	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	519.96	6.5	490.51	1.06	t
117	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	415.62	5.2	305.68	1.36	t
117	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	341.36	4.3	292.87	1.17	t
117	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	493.61	6.2	354.24	1.39	t
118	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	402.10	5.0	240.39	1.67	t
118	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	461.02	5.8	215.25	2.14	t
118	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	546.84	6.8	155.89	3.51	f
118	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	439.55	5.5	275.53	1.60	t
118	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	387.73	4.8	284.63	1.36	t
118	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	359.39	4.5	264.20	1.36	t
118	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	518.98	6.5	492.51	1.05	t
118	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	414.64	5.2	307.67	1.35	t
118	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	340.38	4.3	291.57	1.17	t
118	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	492.63	6.2	355.66	1.39	t
123	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	78.24	1.0	59.74	1.31	t
123	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	524.61	6.6	382.22	1.37	t
123	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	710.50	8.9	371.39	1.91	t
123	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	796.32	10.0	298.54	2.67	t
123	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	639.65	8.0	419.70	1.52	t
123	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	697.17	8.7	497.45	1.40	t
123	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	629.13	7.9	503.99	1.25	t
123	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	701.79	8.8	531.72	1.32	t
123	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	728.70	9.1	556.87	1.31	t
124	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	75.17	0.9	55.77	1.35	t
124	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	521.54	6.5	382.04	1.37	t
124	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	707.43	8.8	371.50	1.90	t
124	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	793.25	9.9	298.83	2.65	t
124	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	642.72	8.0	423.02	1.52	t
124	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	700.24	8.8	498.18	1.41	t
124	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	632.20	7.9	506.99	1.25	t
124	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	704.86	8.8	534.42	1.32	t
124	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	731.77	9.1	559.35	1.31	t
130	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	672.70	8.4	487.93	1.38	t
130	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	767.84	9.6	642.98	1.19	t
131	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	210.29	2.6	149.03	1.41	t
131	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	321.57	4.0	269.24	1.19	t
131	131854732	Polly Woodside	Place Of Assembly	Art Gallery/Museum	low	-37.824257	144.953478	797.60	10.0	587.24	1.36	t
131	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	450.76	5.6	211.25	2.13	t
131	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	772.64	9.7	473.89	1.63	t
131	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	618.65	7.7	421.21	1.47	t
131	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	494.77	6.2	391.16	1.26	t
132	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	199.49	2.5	187.62	1.06	t
132	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	116.18	1.5	80.14	1.45	t
132	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	340.88	4.3	308.69	1.10	t
132	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	659.80	8.2	583.12	1.13	t
132	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	625.49	7.8	485.89	1.29	t
133	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	637.90	8.0	512.24	1.25	t
133	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	394.98	4.9	263.89	1.50	t
133	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	399.38	5.0	292.56	1.37	t
133	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	753.93	9.4	576.90	1.31	t
134	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	229.02	2.9	160.17	1.43	t
134	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	688.95	8.6	593.22	1.16	t
134	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	565.61	7.1	404.95	1.40	t
134	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	728.97	9.1	631.55	1.15	t
135	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	198.96	2.5	150.83	1.32	t
135	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	650.13	8.1	553.46	1.17	t
135	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	783.96	9.8	613.70	1.28	t
135	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	690.89	8.6	591.83	1.17	t
135	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	604.43	7.6	439.96	1.37	t
136	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	76.41	1.0	54.60	1.40	t
136	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	510.22	6.4	410.17	1.24	t
136	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	696.11	8.7	406.01	1.71	t
136	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	781.93	9.8	339.42	2.30	t
136	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	733.81	9.2	542.80	1.35	t
136	217373317	Treasury Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.814399	144.975952	756.52	9.5	492.71	1.54	t
136	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	746.00	9.3	591.97	1.26	t
137	37487911	Docklands Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820996	144.946782	360.66	4.5	234.97	1.53	t
137	122779140	Fox Classic Car Collection	Place Of Assembly	Art Gallery/Museum	low	-37.821374	144.948497	431.10	5.4	340.96	1.26	t
138	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	91.10	1.1	54.55	1.67	t
138	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	144.13	1.8	102.51	1.41	t
138	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	546.73	6.8	279.08	1.96	t
138	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	561.71	7.0	346.77	1.62	t
138	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	633.96	7.9	565.75	1.12	t
139	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	154.13	1.9	69.43	2.22	t
139	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	550.73	6.9	368.62	1.49	t
139	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	570.57	7.1	535.49	1.07	t
139	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	770.43	9.6	358.38	2.15	t
139	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	683.57	8.5	255.16	2.68	t
139	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	692.61	8.7	554.31	1.25	t
139	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	778.43	9.7	626.97	1.24	t
139	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	657.95	8.2	485.54	1.36	t
140	131888455	Australian Centre for Contemporary Art	Place Of Assembly	Art Gallery/Museum	low	-37.826605	144.967253	692.73	8.7	479.93	1.44	t
141	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	255.12	3.2	85.67	2.98	t
141	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	247.41	3.1	202.71	1.22	t
141	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	698.48	8.7	407.49	1.71	t
141	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	501.66	6.3	255.40	1.96	t
141	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	669.55	8.4	452.79	1.48	t
141	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	545.67	6.8	453.40	1.20	t
142	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	248.52	3.1	265.90	0.93	t
142	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	532.04	6.7	346.28	1.54	t
142	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	709.93	8.9	351.68	2.02	t
142	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	491.26	6.1	155.53	3.16	f
142	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	678.92	8.5	224.43	3.03	f
142	177688366	Riverslide Skate Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820789	144.972952	803.04	10.0	454.94	1.77	t
142	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	800.96	10.0	252.74	3.17	f
142	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	806.00	10.1	306.96	2.63	t
143	122245631	Batman Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821846	144.956666	122.86	1.5	97.16	1.26	t
143	183583367	Victoria Police Museum	Place Of Assembly	Art Gallery/Museum	low	-37.822218	144.954040	279.45	3.5	145.01	1.93	t
143	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	449.84	5.6	366.76	1.23	t
143	131854732	Polly Woodside	Place Of Assembly	Art Gallery/Museum	low	-37.824257	144.953478	515.62	6.4	335.92	1.53	t
143	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	630.63	7.9	512.13	1.23	t
143	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	709.27	8.9	532.27	1.33	t
144	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	557.28	7.0	334.30	1.67	t
144	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	687.71	8.6	521.62	1.32	t
144	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	730.12	9.1	600.81	1.22	t
144	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	794.00	9.9	646.92	1.23	t
144	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	771.72	9.6	580.89	1.33	t
144	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	777.58	9.7	560.08	1.39	t
145	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	545.37	6.8	334.61	1.63	t
145	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	675.80	8.4	511.94	1.32	t
145	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	741.87	9.3	611.34	1.21	t
145	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	805.75	10.1	655.86	1.23	t
145	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	783.47	9.8	584.17	1.34	t
145	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	789.33	9.9	566.91	1.39	t
146	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	521.96	6.5	334.81	1.56	t
146	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	652.39	8.2	503.64	1.30	t
146	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	750.82	9.4	620.15	1.21	t
146	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	814.70	10.2	663.68	1.23	t
146	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	792.42	9.9	586.77	1.35	t
146	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	798.28	10.0	572.52	1.39	t
147	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	519.39	6.5	334.81	1.55	t
147	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	649.82	8.1	496.36	1.31	t
147	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	760.81	9.5	627.57	1.21	t
147	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	824.69	10.3	670.64	1.23	t
147	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	802.41	10.0	588.74	1.36	t
147	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	808.27	10.1	577.10	1.40	t
148	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	519.39	6.5	335.54	1.55	t
148	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	649.82	8.1	489.48	1.33	t
148	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	760.81	9.5	635.10	1.20	t
148	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	824.69	10.3	677.22	1.22	t
148	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	802.41	10.0	591.30	1.36	t
148	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	808.27	10.1	582.12	1.39	t
149	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	492.21	6.2	327.03	1.51	t
149	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	622.64	7.8	481.06	1.29	t
149	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	794.29	9.9	636.25	1.25	t
150	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	486.21	6.1	317.95	1.53	t
150	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	616.64	7.7	471.40	1.31	t
150	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	799.76	10.0	638.28	1.25	t
151	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	551.43	6.9	322.99	1.71	t
151	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	681.86	8.5	512.36	1.33	t
151	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	736.11	9.2	600.93	1.22	t
151	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	799.99	10.0	657.18	1.22	t
151	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	777.71	9.7	571.21	1.36	t
151	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	783.57	9.8	553.62	1.42	t
152	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	521.96	6.5	323.60	1.61	t
152	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	652.39	8.2	497.35	1.31	t
152	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	750.82	9.4	617.07	1.22	t
152	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	814.70	10.2	670.92	1.21	t
152	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	792.42	9.9	576.29	1.38	t
152	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	798.28	10.0	564.17	1.41	t
153	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	492.21	6.2	324.93	1.51	t
153	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	622.64	7.8	486.06	1.28	t
153	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	794.29	9.9	629.56	1.26	t
154	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	551.43	6.9	315.77	1.75	t
154	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	681.86	8.5	507.04	1.34	t
154	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	736.11	9.2	600.56	1.23	t
154	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	799.99	10.0	663.30	1.21	t
154	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	777.71	9.7	564.88	1.38	t
154	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	783.57	9.8	549.20	1.43	t
155	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	490.98	6.1	316.61	1.55	t
155	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	621.41	7.8	492.54	1.26	t
155	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	781.80	9.8	616.24	1.27	t
155	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	823.40	10.3	570.02	1.44	t
158	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	595.90	7.4	491.98	1.21	t
158	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	640.12	8.0	482.54	1.33	t
158	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	583.85	7.3	431.01	1.35	t
158	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	692.19	8.7	625.58	1.11	t
158	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	698.05	8.7	546.27	1.28	t
159	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	561.60	7.0	493.02	1.14	t
159	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	605.82	7.6	476.44	1.27	t
159	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	606.15	7.6	437.59	1.39	t
159	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	714.49	8.9	631.52	1.13	t
159	58817347	St Mary's Anglican Church	Place of Worship	Church	low	-37.803166	144.953762	826.61	10.3	668.40	1.24	t
159	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	690.62	8.6	550.98	1.25	t
160	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	303.44	3.8	227.69	1.33	t
160	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	683.67	8.5	570.01	1.20	t
160	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	483.76	6.0	391.21	1.24	t
160	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	723.00	9.0	546.63	1.32	t
160	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	594.18	7.4	396.63	1.50	t
160	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	517.98	6.5	468.10	1.11	t
160	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	681.08	8.5	475.30	1.43	t
160	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	614.16	7.7	489.09	1.26	t
160	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	756.72	9.5	555.52	1.36	t
161	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	316.99	4.0	219.04	1.45	t
161	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	502.88	6.3	221.08	2.27	t
161	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	588.70	7.4	168.95	3.48	f
161	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	229.96	2.9	168.76	1.36	t
161	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	763.72	9.5	456.52	1.67	t
161	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	780.37	9.8	236.46	3.30	f
161	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	777.75	9.7	348.25	2.23	t
161	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	711.40	8.9	444.08	1.60	t
161	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	540.58	6.8	362.96	1.49	t
161	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	708.18	8.9	501.19	1.41	t
161	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	679.84	8.5	495.98	1.37	t
161	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	735.09	9.2	510.61	1.44	t
161	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	769.50	9.6	536.17	1.44	t
162	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	633.40	7.9	492.28	1.29	t
162	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	697.28	8.7	571.93	1.22	t
162	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	460.26	5.8	338.48	1.36	t
162	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	816.70	10.2	615.01	1.33	t
162	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	620.42	7.8	546.09	1.14	t
162	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	626.28	7.8	488.85	1.28	t
164	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	365.16	4.6	342.96	1.06	t
164	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	330.69	4.1	217.09	1.52	t
164	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	478.75	6.0	328.81	1.46	t
164	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	646.29	8.1	526.01	1.23	t
165	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	719.41	9.0	498.45	1.44	t
165	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	446.51	5.6	278.44	1.60	t
165	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	774.35	9.7	591.08	1.31	t
166	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	484.49	6.1	305.52	1.59	t
166	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	752.25	9.4	529.83	1.42	t
166	250823061	North Melbourne Uniting	Place of Worship	Church	low	-37.803554	144.947672	743.91	9.3	619.01	1.20	t
167	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	318.72	4.0	220.15	1.45	t
167	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	377.13	4.7	348.46	1.08	t
167	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	467.32	5.8	333.61	1.40	t
167	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	634.32	7.9	524.78	1.21	t
179	131888455	Australian Centre for Contemporary Art	Place Of Assembly	Art Gallery/Museum	low	-37.826605	144.967253	555.10	6.9	478.13	1.16	t
179	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	709.99	8.9	555.99	1.28	t
179	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	643.95	8.0	416.76	1.55	t
179	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	569.10	7.1	491.23	1.16	t
180	8971320	St Alban Anglican Church	Place of Worship	Church	low	-37.794217	144.941615	730.38	9.1	560.92	1.30	t
180	84626667	Holy Rosary	Place of Worship	Church	low	-37.794809	144.928362	706.38	8.8	610.15	1.16	t
181	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	265.47	3.3	217.28	1.22	t
181	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	174.76	2.2	142.39	1.23	t
181	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	271.33	3.4	219.55	1.24	t
181	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	537.25	6.7	438.99	1.22	t
181	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	671.64	8.4	602.58	1.11	t
181	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	701.45	8.8	591.88	1.19	t
181	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	790.03	9.9	689.57	1.15	t
182	97129269	St Augustines Church	Place of Worship	Church	low	-37.816974	144.954862	192.63	2.4	96.08	2.00	t
182	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	684.95	8.6	548.85	1.25	t
182	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	766.14	9.6	539.69	1.42	t
182	243925173	Koorie Heritage Trust Inc	Place Of Assembly	Art Gallery/Museum	low	-37.813385	144.954028	378.12	4.7	346.56	1.09	t
182	147837436	Flagstaff Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.811122	144.954696	642.90	8.0	577.38	1.11	t
182	237282471	St James Church	Place of Worship	Church	low	-37.810128	144.952469	785.12	9.8	733.70	1.07	t
184	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	384.41	4.8	377.75	1.02	t
184	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	415.87	5.2	314.80	1.32	t
184	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	557.26	7.0	403.21	1.38	t
184	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	511.80	6.4	385.18	1.33	t
184	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	760.96	9.5	565.49	1.35	t
184	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	601.36	7.5	486.10	1.24	t
184	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	709.64	8.9	551.55	1.29	t
184	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	694.31	8.7	545.28	1.27	t
184	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	780.13	9.8	602.84	1.29	t
184	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	782.12	9.8	535.80	1.46	t
184	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	637.18	8.0	519.71	1.23	t
184	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	755.44	9.4	620.12	1.22	t
184	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	530.15	6.6	428.84	1.24	t
185	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	236.45	3.0	209.07	1.13	t
185	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	489.22	6.1	379.42	1.29	t
185	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	606.57	7.6	417.55	1.45	t
185	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	559.90	7.0	445.97	1.26	t
185	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	747.96	9.3	560.45	1.33	t
185	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	702.50	8.8	478.39	1.47	t
185	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	801.17	10.0	620.25	1.29	t
185	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	705.70	8.8	516.70	1.37	t
185	14179167	St Michael's Uniting Church	Place of Worship	Church	low	-37.814385	144.969174	788.67	9.9	567.72	1.39	t
185	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	785.09	9.8	657.89	1.19	t
187	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	305.20	3.8	227.44	1.34	t
187	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	179.52	2.2	114.23	1.57	t
187	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	418.76	5.2	304.76	1.37	t
187	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	491.42	6.1	378.95	1.30	t
187	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	732.64	9.2	537.12	1.36	t
187	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	403.99	5.0	376.18	1.07	t
187	194468052	Carlton Gardens South	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.806068	144.971266	820.25	10.3	742.94	1.10	t
187	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	621.87	7.8	487.21	1.28	t
187	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	827.28	10.3	745.09	1.11	t
188	206981176	Old Melbourne Gaol Crime & Justice Experience	Place Of Assembly	Art Gallery/Museum	low	-37.807764	144.965464	196.27	2.5	148.55	1.32	t
188	79304111	Romanian Orthodox	Place of Worship	Church	low	-37.805231	144.966986	432.80	5.4	263.57	1.64	t
188	141815454	Wesley Church	Place of Worship	Church	low	-37.810158	144.968168	594.81	7.4	503.84	1.18	t
188	84606166	Church of Christ	Place of Worship	Church	low	-37.810452	144.963889	580.56	7.3	428.91	1.35	t
188	213062595	Royal Exhibition Building	Place Of Assembly	Art Gallery/Museum	low	-37.804603	144.971522	790.70	9.9	651.43	1.21	f
188	152114315	St Francis Church	Place of Worship	Church	low	-37.811885	144.962423	819.80	10.2	613.70	1.34	t
188	194468052	Carlton Gardens South	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.806068	144.971266	721.36	9.0	591.95	1.22	t
188	241223283	Lincoln Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802792	144.962761	616.85	7.7	455.49	1.35	t
188	238281578	Piazza Italia	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.802516	144.965863	596.63	7.5	471.65	1.26	t
188	67946834	Welsh Presbyterian Church	Place of Worship	Church	low	-37.810448	144.959873	780.31	9.8	591.63	1.32	t
188	125398371	Argyle Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.803148	144.965761	482.57	6.0	401.38	1.20	t
188	126684859	The Museum Of Australian Chinese History	Place Of Assembly	Art Gallery/Museum	low	-37.810769	144.969234	794.08	9.9	616.27	1.29	t
209	19089017	Sandridge Rail Bridge	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820176	144.962981	298.33	3.7	251.84	1.18	t
209	73577526	St Johns Lutheran Church	Place of Worship	Church	low	-37.820940	144.967121	435.69	5.4	250.33	1.74	t
209	22355420	Federation Square	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.817852	144.968964	383.51	4.8	334.21	1.15	t
209	37212179	Alexandra Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820605	144.971796	721.56	9.0	578.37	1.25	t
209	98625024	Queen Victoria Gardens	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.821638	144.971050	718.94	9.0	564.08	1.27	t
209	261032609	Birrarung Marr	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.818061	144.973147	779.45	9.7	681.64	1.14	t
209	219963907	Victorian Arts Centre	Place Of Assembly	Art Gallery/Museum	low	-37.821995	144.968837	652.59	8.2	436.36	1.50	t
209	48112085	Australian Centre For The Moving Image (ACMI)	Place Of Assembly	Art Gallery/Museum	low	-37.817611	144.969070	505.55	6.3	354.33	1.43	t
209	177688366	Riverslide Skate Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820789	144.972952	814.67	10.2	681.54	1.20	t
209	61421159	The Ian Potter Centre: NGV Australia	Place Of Assembly	Art Gallery/Museum	low	-37.817483	144.969899	591.37	7.4	425.96	1.39	t
209	62596990	St Pauls Cathedral	Place of Worship	Church	low	-37.816955	144.967682	447.05	5.6	305.28	1.46	t
209	78771235	Enterprize Park	Leisure/Recreation	Informal Outdoor Facility (Park/Garden/Reserve)	low	-37.820210	144.959277	684.05	8.6	560.37	1.22	t
209	172239967	Immigration Museum	Place Of Assembly	Art Gallery/Museum	low	-37.819180	144.960427	579.45	7.2	445.45	1.30	t
209	170340965	The Melbourne Athenaeum Library	Place Of Assembly	Library	low	-37.814886	144.967291	635.34	7.9	493.31	1.29	t
209	71247568	Collins Street Baptist Church	Place of Worship	Church	low	-37.814701	144.968072	731.27	9.1	537.90	1.36	t
209	77738101	Scots Church	Place of Worship	Church	low	-37.814569	144.968551	788.01	9.9	569.81	1.38	t
\.


--
-- Data for Name: sensor; Type: TABLE DATA; Schema: serving; Owner: -
--

COPY serving.sensor (location_id, display_name, device_code, latitude, longitude, is_cbd, is_active, direction_1, direction_2) FROM stdin;
82	512 Elizabeth Street	Eli512_T	-37.806672	144.960056	t	t	\N	\N
1	Bourke Street Mall (North)	Bou292_T	-37.813494	144.965153	t	t	East	West
2	Bourke Street Mall (South)	Bou283_T	-37.813807	144.965167	t	t	East	West
3	Melbourne Central	Swa295_T	-37.811015	144.964295	t	t	North	South
4	Town Hall (West)	Swa123_T	-37.814880	144.966088	t	t	North	South
5	Princes Bridge	PriNW_T	-37.818742	144.967877	t	t	North	South
6	Flinders Underpass - Myki Barriers	FliS_T	-37.819074	144.965579	t	t	North	South
8	Webb Bridge	WebBN_T	-37.822935	144.947175	t	t	North	South
9	Southern Cross Station	Col700_T	-37.819830	144.951026	t	t	East	West
10	Victoria Point	BouHbr_T	-37.818765	144.947105	t	t	East	West
11	Docklands Waterfront City Building Side	WatCit_T	-37.815667	144.939744	t	t	East	West
12	New Quay	NewQ_T	-37.814580	144.942924	t	t	East	West
14	Sandridge Bridge	SanBri_T	-37.820112	144.962919	t	t	North	South
17	Collins Place (South)	Col15_T	-37.813625	144.973236	t	t	East	West
18	Collins Place (North)	Col12_T	-37.813449	144.973054	t	t	East	West
19	Chinatown-Swanston St (North)	LtB210_T	-37.812372	144.965507	t	t	East	West
20	Chinatown-Lt Bourke St (South)	LtB170_T	-37.811729	144.968247	t	t	East	West
21	155-161 Russell Street	Bourke155_T	-37.812673	144.967883	t	t	North	South
23	Spencer St-Collins St (South)	Col623_T	-37.819093	144.954527	t	t	East	West
24	Spencer St-Collins St (North)	Col620_T	-37.818880	144.954492	t	t	East	West
25	Melbourne Convention Exhibition Centre	MCEC_T	-37.824018	144.956044	t	t	East	West
27	QV Market-Peel St	Vic_T	-37.806069	144.956447	t	t	East	West
29	St Kilda Rd-Alexandra Gardens	AG_T	-37.819982	144.968729	t	t	North	South
30	Lonsdale St (South)	Lon189_T	-37.811219	144.966568	t	t	East	West
31	Lygon St (West)	Lyg161_T	-37.801697	144.966589	t	t	North	South
35	Southbank Promenade	SouthB_T	-37.820187	144.965085	t	t	East	West
36	Queen St (West)	Que85_T	-37.816525	144.961211	t	t	North	South
37	Lygon St (East)	Lyg260_T	-37.801071	144.967046	t	t	North	South
39	Alfred Place	AlfPl_T	-37.813797	144.969957	t	t	North	South
40	Lonsdale St-Spring St (West)	Spr201_T	-37.809993	144.972276	t	t	North	South
41	Flinders La-Swanston St (West)	Swa31	-37.816686	144.966897	t	t	North	South
42	Grattan St-Swanston St (West)	UM1_T	-37.800086	144.963864	t	t	North	South
43	Monash Rd-Swanston St (West)	UM2_T	-37.798445	144.964118	t	t	North	South
44	Tin Alley-Swanston St (West)	UM3_T	-37.796987	144.964413	t	t	North	South
45	Little Collins St-Swanston St (East)	Swa148_T	-37.814141	144.966094	t	t	North	South
46	Pelham St (South)	Pel147_T	-37.802407	144.961567	t	t	East	West
47	Melbourne Central-Elizabeth St (East)	Eli250_T	-37.812585	144.962578	t	t	North	South
48	QVM-Queen St (East)	QVMQ_T	-37.806316	144.958667	t	t	East	West
49	QVM-Therry St (South)	Eli501_T	-37.807301	144.959561	t	t	East	West
50	Faraday St-Lygon St (West)	Lyg309_T	-37.798082	144.967210	t	t	North	South
51	QVM-Franklin St (North)	Fra118_T	-37.808418	144.959063	t	t	East	West
52	Elizabeth St-Lonsdale St (South)	Eli263_T	-37.812522	144.961940	t	t	East	West
53	Collins Street (North)	Col254_T	-37.815642	144.965499	t	t	East	West
54	Lincoln-Swanston (West)	Swa607_T	-37.804024	144.963084	t	t	North	South
56	Lonsdale St - Elizabeth St (North)	Lon364_T	-37.812348	144.961533	t	t	East	West
58	Bourke St - Spencer St (North)	Bou688_T	-37.816861	144.953581	t	t	East	West
59	Building 80 RMIT	RMIT_T	-37.808256	144.963049	t	t	North	South
61	RMIT Building 14	RMIT14_T	-37.807675	144.963091	t	t	North	South
62	La Trobe St (North)	Lat224_T	-37.809965	144.962165	t	t	East	West
63	231 Bourke St	Bou231_T	-37.813331	144.966756	t	t	East	West
66	QV2 Apartments, 300 Swanston Street	QVN_T	-37.810578	144.964443	t	t	North	South
67	Flinders Ln -Degraves St (South)	FLDegS_T	-37.816888	144.965626	t	t	East	West
68	Flinders Ln -Degraves St (North)	FLDegN_T	-37.816848	144.965598	t	t	East	West
69	Flinders Ln -Degraves St (Crossing)	FLDegC_T	-37.816872	144.965591	t	t	North	South
70	Errol Street (East)	Errol20_T	-37.804570	144.949462	t	t	North	South
71	Westwood Place	WestWP_T	-37.812358	144.971370	t	t	North	South
72	Flinders St- ACMI	ACMI_T	-37.817263	144.968728	t	t	East	West
75	Spring St- Flinders st (West)	SprFli_T	-37.815153	144.974677	t	t	North	South
76	Macaulay Rd- Bellair St	KenMac_T	-37.794538	144.930362	f	t	East	West
77	Harbour Esplanade (West) - Pedestrian path	HarEsP_T	-37.814414	144.944330	t	t	North	South
79	Flinders St (South)	FliSS_T	-37.817940	144.966167	t	t	East	West
80	Boyd Commuinty - Rear door	BoCoR_T	-37.825457	144.961312	t	t	\N	\N
81	Boyd Commuinty - Front door	BoCoF_T	-37.825791	144.960843	t	t	\N	\N
83	510 Elizabeth Street	Eli510_T	-37.806732	144.960051	t	t	\N	\N
84	Elizabeth St - Flinders St (East) - New footpath	ElFi_T	-37.817980	144.965034	t	t	North	South
85	Macaulay Rd (North)	488Mac_T	-37.794324	144.929734	f	t	East	West
86	Queensberry St - Errol St (South)	574Qub_T	-37.803100	144.949081	t	t	East	West
87	Errol St (West)	Errol23_T	-37.804549	144.949219	t	t	North	South
89	City Library	CityLi_T	-37.816860	144.965866	t	t	\N	\N
90	Boyd Community Hub- Library	BoCoL_T	-37.825562	144.961154	t	t	\N	\N
91	Library at The Dock-North side	DocLib1_T	-37.820019	144.940299	t	t	\N	\N
92	Library at The Dock-South side	DocLib2_T	-37.820163	144.940396	t	t	\N	\N
93	East Melbourne Library	EastLib_T	-37.814984	144.986388	f	t	\N	\N
94	Fitzroy Garden- The Conservatory	FitConVis_T	-37.814245	144.978519	t	t	\N	\N
95	Fitzroy Garden Visitor Centre External	FitGarExtVisExt_T	-37.814883	144.979266	t	t	\N	\N
96	Fitzroy Garden Visitor Centre Internal	FitGarVisIInt_T	-37.814997	144.979251	t	t	\N	\N
99	Town Hall Visitor Centre	TownVis_T	-37.814621	144.966233	t	t	\N	\N
102	North Melbourne Library	NtMelLib_T	-37.803405	144.949770	t	t	\N	\N
103	Kensington Town Hall	KenTown_T	-37.789353	144.928606	f	t	\N	\N
104	Kathleen Syme Library Main	KatLib1_T	-37.798636	144.965482	t	t	\N	\N
105	Kathleen Syme Library Lib	KatLib2_T	-37.798618	144.965283	t	t	\N	\N
106	Kathleen Syme Library Cafe	KatLib3_T	-37.798595	144.965109	t	t	\N	\N
107	Royal Mint 280 William St	280Will_T	-37.812463	144.956902	t	t	North	South
108	William St - Little Lonsdale St (West)	261Will_T	-37.812958	144.956788	t	t	North	South
109	La Trobe St- William St (South)	LatWill_T	-37.811937	144.956211	t	t	East	West
116	Fitzroy Garden Visitor Centre Cafe Verandah	FitCafVis_T	-37.814937	144.979324	t	t	\N	\N
117	114 Flinders Street Car Park Footpath	Fli114F_T	-37.816293	144.970909	t	t	East	West
118	114 Flinders Street Car Park Crossing	Fli114C_T	-37.816328	144.970905	t	t	North	South
123	Birrarung Marr East - Batman Ave Bridge Entry	BirBridge_T	-37.817537	144.973297	t	t	East	West
124	Birrarung Marr East - Batman Ave Bridge Entry	BirBridge_T	-37.817574	144.973299	t	t	North	South
130	I-Hub 892 Bourke Street	Bou892T	-37.820464	144.941268	t	t	East	West
131	I-Hub Corner of King Street and Flinders Street (2-6 King)	King2_T	-37.820091	144.957587	t	t	North	South
132	I-Hub Corner of King Street and Latrobe Street (317-335 King)	King335_T	-37.812676	144.953864	t	t	North	South
133	I-Hub Southern Cross Station - Lonsdale Street Entrance - South	Spen229_T	-37.815314	144.952278	t	t	North	South
134	I-Hub Southern Cross Station - Bourke Street Entrance - North	Spen201_T	-37.816942	144.953039	t	t	North	South
135	I-Hub Southern Cross Station - Bourke Street Entrance - South	Spen161_T	-37.817286	144.953191	t	t	North	South
136	COM Pole 1120 - Towards the City, Near Federation Square Bridge	BirFed1120_T	-37.818414	144.973579	t	t	East	West
137	COM Pole 2353 - Towards the city, NAB Building	BouHbr2353_T	-37.818948	144.946123	t	t	East	West
138	COM Pole 1671 - Enterprize Park, Queens Bridge	EntPark1671_T	-37.819965	144.959815	t	t	East	West
139	COM Pole 1647 - Sandridge Bridge Signal Box	Signal1647_T	-37.819599	144.963283	t	t	East	West
140	COM Pole 2837 - Boyd Park	Boyd2837_T	-37.825910	144.961860	t	t	North	South
141	Awning of Nationwide Parking 474 Flinders Street	474Fl_T	-37.819973	144.958349	t	t	East	West
142	COM Pole 1584 - Hammer Hall Entrance	Hammer1584_T	-37.819707	144.967957	t	t	East	West
143	Mounted on Toilet - Spencer Street, Batman Park	Spencer_T	-37.821728	144.955570	t	t	North	South
144	narrm ngarrgu Library - Level 1 - Lift 1	narrLibL1L1_T	-37.807607	144.958628	t	t	\N	\N
145	narrm ngarrgu Library - Level 1 - Lift 2	narrLibL1L2_T	-37.807639	144.958507	t	t	\N	\N
146	narrm ngarrgu Library - Level 1 - Lift 3	narrLibL1L3_T	-37.807669	144.958406	t	t	\N	\N
147	narrm ngarrgu Library - Level 1 - Meeting Room Lift 1	narrLibMRL1_T	-37.807698	144.958321	t	t	\N	\N
148	narrm ngarrgu Library - Level 1 - Meeting Room Lift 2	narrLibMRL2_T	-37.807722	144.958235	t	t	\N	\N
149	narrm ngarrgu Library - Level 1 Main Stairs A	narrLibL1MA_T	-37.807812	144.958222	t	t	\N	\N
150	narrm ngarrgu Library - Level 1 Main Stairs B	narrLibL1MB_T	-37.807912	144.958201	t	t	\N	\N
151	narrm ngarrgu Library - Level 2 - Collections Stairs A	narrLibL2CA_T	-37.807716	144.958624	t	t	\N	\N
152	narrm ngarrgu Library - Level 2 - Study Area Lifts 1	narrLibL2S1_T	-37.807767	144.958440	t	t	\N	\N
153	narrm ngarrgu Library - Level 2 - Study Area Lifts 2	narrLibL2S2_T	-37.807804	144.958298	t	t	\N	\N
154	narrm ngarrgu Library - Level 3 Children's Library Door 1	narrLibL3C1_T	-37.807784	144.958628	t	t	\N	\N
155	narrm ngarrgu Library - Level 3 Children's Library Door 2	narrLibL#C2_T	-37.807832	144.958450	t	t	\N	\N
158	514 Elizebeth Street	Eli514_T	-37.806575	144.960070	t	t	\N	\N
159	516 Elizeberth Street	Eli516_T	-37.806516	144.960079	t	t	\N	\N
160	City Baths, 420 Swanston Street - Main Entry	Swa420_T	-37.806995	144.963062	t	t	\N	\N
161	Birrarung Marr - COM - Pole 1109	BirArt1109_T	-37.818513	144.971313	t	t	East	West
162	iHub 489 Elizabeth Street	Eli489_T	-37.807404	144.959879	t	t	North	South
164	I-Hub 526 La Trobe Street (Footpath)	Lat526_T	-37.813005	144.951604	t	t	East	West
165	475 Spencer Street	Spen475_T	-37.809534	144.949390	t	t	North	South
166	484 Spencer Street	Spen484_T	-37.808967	144.949317	t	t	North	South
167	I-Hub 526 La Trobe Street (Crossing)	Lat526_T	-37.813041	144.951560	t	t	North	South
179	61-67 Power Street Southbank	Pow61_T	-37.823924	144.962997	t	t	North	South
180	Pumping Station No.2, 330 Macaulay Road	Mac330_T	-37.794971	144.935303	f	t	East	West
181	368 Elizabeth Street	Eli368_T	-37.810095	144.961431	t	t	North	South
182	163 King Street	King163_T	-37.816275	144.955505	t	t	North	South
184	124 Elizabeth Street	Eli124_T	-37.815124	144.963720	t	t	North	South
185	197 Elizabeth Street	Eli197_T	-37.813746	144.962762	t	t	North	South
187	RMIT Building 22 - 330 Swanston Street	Swa330_T	-37.809426	144.963955	t	t	East	West
188	RMIT Building 51 - 80-92 Victoria Street	RMIT51_T	-37.806632	144.964566	t	t	North	South
209	Flinders Underpass - Walkway	FliS_T	-37.819090	144.965497	t	t	North	South
\.


--
-- Data for Name: sensor_network; Type: TABLE DATA; Schema: serving; Owner: -
--

COPY serving.sensor_network (location_id, walkable_m_within_400m, nodes_within_400m, node_degree, low_sensory_within_800m, nearest_low_sensory_m, network_snap_reliable) FROM stdin;
82	20509.42	1123	2	5	578.34	t
1	28472.67	2355	2	12	386.00	t
2	30377.57	2475	3	12	353.58	t
3	35571.32	2103	2	11	100.60	t
4	30865.06	2298	2	12	192.74	t
5	19923.17	832	3	17	163.93	t
6	19328.53	922	2	16	298.33	t
8	10525.26	270	1	5	244.09	f
9	10579.70	378	2	5	345.01	t
10	10982.71	427	2	3	393.88	t
11	14763.67	578	3	1	181.09	t
12	9048.56	394	3	1	155.67	t
14	3894.02	127	2	7	14.84	t
17	14612.43	883	3	17	315.81	t
18	15297.66	916	3	16	347.72	t
19	37160.82	2441	4	13	303.75	t
20	32609.25	2254	3	13	188.00	t
21	31171.98	2251	3	12	233.27	t
23	12629.89	690	3	8	418.54	t
24	12677.35	691	4	8	356.29	t
25	8843.31	255	5	6	257.99	f
27	24078.21	1657	2	4	581.08	t
29	14057.93	325	4	15	261.21	t
30	30385.27	2184	2	13	261.42	t
31	19200.37	1607	2	10	223.47	t
35	11304.88	493	4	13	271.28	t
36	20981.02	1520	2	8	491.22	t
37	20812.84	1750	2	10	334.82	t
39	20176.98	1507	1	13	238.86	t
40	14556.58	978	3	14	272.01	t
41	29271.78	1706	2	17	191.54	t
42	14145.05	896	3	6	445.65	t
43	12266.07	1072	2	4	629.44	t
44	12292.60	1065	2	3	553.62	t
45	29461.33	2294	2	12	253.93	t
46	11480.93	668	2	4	229.77	t
47	33253.75	2448	2	9	86.64	t
48	21729.09	1329	2	7	646.92	t
49	19986.69	1073	1	5	500.42	t
50	23205.95	2125	2	7	386.36	t
51	15350.35	819	2	5	481.24	t
52	30176.47	2163	2	7	107.02	t
53	29933.78	2127	2	12	211.06	t
54	13099.63	878	2	6	217.64	t
56	27325.46	1931	2	8	108.25	t
58	15357.36	690	2	5	167.29	t
59	21823.11	1213	3	9	314.76	t
61	17596.22	1086	3	10	293.46	t
62	24963.25	1533	3	7	235.32	t
63	27907.71	2033	4	13	263.78	t
66	37541.41	2161	3	11	77.34	t
67	31900.52	1906	3	14	291.66	t
68	31724.45	1894	2	14	295.63	t
69	31905.02	1902	2	14	292.92	t
70	22643.07	2078	3	2	378.43	t
71	14842.52	1205	1	13	384.59	t
72	19615.81	905	3	16	171.92	t
75	9432.66	476	3	15	171.56	t
76	23489.79	2139	2	2	223.05	t
77	8314.62	372	2	1	371.58	t
79	25360.04	1304	2	17	261.08	t
80	9690.93	522	3	3	765.10	t
81	10572.47	564	2	1	701.54	t
83	20691.90	1134	2	5	565.20	t
84	25872.95	1447	3	16	340.51	t
85	21769.87	2056	3	3	244.55	t
86	24435.52	2359	2	2	214.10	t
87	21119.54	1941	2	2	393.89	t
89	30777.32	1851	2	14	281.03	t
90	8306.20	450	1	0	\N	t
91	8576.93	324	2	1	777.20	t
92	8398.74	320	2	1	782.44	t
93	11761.72	862	1	6	446.13	t
94	5300.31	87	2	10	144.17	t
95	3154.92	133	1	7	279.83	t
96	3154.92	133	1	7	279.83	t
99	30819.19	2327	2	12	199.04	t
102	23398.98	2231	2	2	297.80	t
103	15500.88	1243	5	3	522.35	t
104	16615.70	1461	2	6	580.89	t
105	14084.74	1259	1	6	604.21	t
106	14513.92	1291	2	6	631.88	t
107	15890.88	1033	3	7	306.49	t
108	15536.46	952	2	7	291.51	t
109	14841.97	902	2	6	207.37	t
116	3154.92	133	1	7	279.83	t
117	12925.63	739	2	10	341.36	t
118	12936.91	741	3	10	340.38	t
123	5398.31	200	2	9	78.24	t
124	5357.67	194	2	9	75.17	t
130	10554.20	395	2	2	672.70	t
131	12190.92	607	1	7	210.29	t
132	15039.16	935	4	5	116.18	t
133	13654.27	665	2	4	394.98	t
134	14854.18	626	3	4	229.02	t
135	15042.31	627	2	5	198.96	t
136	4361.01	82	4	7	76.41	t
137	12776.24	571	2	2	360.66	t
138	11948.68	665	3	5	91.10	t
139	4857.63	175	3	8	154.13	t
140	7751.19	424	3	1	692.73	t
141	12372.24	607	3	6	247.41	t
142	1547.10	50	1	8	248.52	f
143	10258.57	463	2	6	122.86	t
144	18701.37	1026	2	6	557.28	t
145	18776.30	1038	2	6	545.37	t
146	19292.95	1074	2	6	521.96	t
147	19588.00	1093	2	6	519.39	t
148	19588.00	1093	2	6	519.39	t
149	19112.67	1061	2	3	492.21	t
150	19045.23	1060	2	3	486.21	t
151	18794.85	1032	6	6	551.43	t
152	19292.95	1074	2	6	521.96	t
153	19112.67	1061	2	3	492.21	t
154	18794.85	1032	6	6	551.43	t
155	18914.80	1046	11	4	490.98	t
158	20495.15	1123	2	5	583.85	t
159	21509.88	1175	2	6	561.60	t
160	18095.85	1080	2	9	303.44	t
161	5291.08	98	3	13	229.96	t
162	21123.32	1162	3	6	460.26	t
164	12991.54	700	3	4	330.69	t
165	12278.25	912	2	3	446.51	t
166	12662.87	968	2	3	484.49	t
167	13091.24	721	4	4	318.72	t
179	11426.38	568	2	4	555.10	t
180	9476.30	678	1	2	706.38	t
181	28066.99	1767	2	7	174.76	t
182	18225.35	1048	2	6	192.63	t
184	30680.34	2438	3	13	384.41	t
185	26937.84	2344	3	10	236.45	t
187	34947.47	1700	2	9	179.52	t
188	17605.36	1048	3	12	196.27	t
209	19328.53	922	2	16	298.33	t
\.


--
-- Name: density_band density_band_pkey; Type: CONSTRAINT; Schema: serving; Owner: -
--

ALTER TABLE ONLY serving.density_band
    ADD CONSTRAINT density_band_pkey PRIMARY KEY (band_name);


--
-- Name: hourly_profile hourly_profile_pkey; Type: CONSTRAINT; Schema: serving; Owner: -
--

ALTER TABLE ONLY serving.hourly_profile
    ADD CONSTRAINT hourly_profile_pkey PRIMARY KEY (location_id, hour_day);


--
-- Name: minute_count minute_count_pkey; Type: CONSTRAINT; Schema: serving; Owner: -
--

ALTER TABLE ONLY serving.minute_count
    ADD CONSTRAINT minute_count_pkey PRIMARY KEY (location_id, sensing_datetime);


--
-- Name: refuge refuge_pkey; Type: CONSTRAINT; Schema: serving; Owner: -
--

ALTER TABLE ONLY serving.refuge
    ADD CONSTRAINT refuge_pkey PRIMARY KEY (location_id, landmark_id);


--
-- Name: sensor_network sensor_network_pkey; Type: CONSTRAINT; Schema: serving; Owner: -
--

ALTER TABLE ONLY serving.sensor_network
    ADD CONSTRAINT sensor_network_pkey PRIMARY KEY (location_id);


--
-- Name: sensor sensor_pkey; Type: CONSTRAINT; Schema: serving; Owner: -
--

ALTER TABLE ONLY serving.sensor
    ADD CONSTRAINT sensor_pkey PRIMARY KEY (location_id);


--
-- Name: idx_serving_minute_dt; Type: INDEX; Schema: serving; Owner: -
--

CREATE INDEX idx_serving_minute_dt ON serving.minute_count USING btree (sensing_datetime DESC);


--
-- Name: idx_serving_minute_loc_dt; Type: INDEX; Schema: serving; Owner: -
--

CREATE INDEX idx_serving_minute_loc_dt ON serving.minute_count USING btree (location_id, sensing_datetime DESC);


--
-- Name: idx_serving_refuge_loc; Type: INDEX; Schema: serving; Owner: -
--

CREATE INDEX idx_serving_refuge_loc ON serving.refuge USING btree (location_id, walk_m);


--
-- Name: minute_count minute_count_location_id_fkey; Type: FK CONSTRAINT; Schema: serving; Owner: -
--

ALTER TABLE ONLY serving.minute_count
    ADD CONSTRAINT minute_count_location_id_fkey FOREIGN KEY (location_id) REFERENCES serving.sensor(location_id);


--
-- PostgreSQL database dump complete
--

\unrestrict EcNEQnl2xxOLQRlOWmhmPGJdjVzQe10FQHVeuiCYSGTWArRF164rCBxEdRUSKnQ

