-- ============================================================================
-- 09_fix_sensory_classification.sql
--
-- Two fixes prompted by the real sub_theme list.
--
-- BUG 1 - "Carpark" contains "park".
--   My keyword regex in 07 matched the substring 'park', so
--   "Retail/Office/Carpark" and "Retail/Office/Residential/Carpark" were
--   classified LOW sensory. A multi-storey carpark is close to the worst
--   possible recommendation for someone with sensory sensitivities.
--   Fixed with word boundaries (\m ... \M).
--
-- BUG 2 - Too much left 'unrated'.
--   57 sub_themes, most unrated, meant the recommendation feature had almost
--   nothing to work with. Ratings below are deliberate and defensible.
--
-- IMPORTANT: these are still my judgements, not measurements. Your group
-- should review the final table and agree it. Saying "we classified 57
-- sub-themes against criteria X, Y, Z" is a strength in the report; silently
-- inheriting someone else's keyword guess is not.
-- ============================================================================

SET search_path TO hush, public;

-- ---------------------------------------------------------------------------
-- Reclassify everything from scratch, so this is repeatable.
--
-- Criteria used:
--   low     - quiet by design or convention: libraries, galleries, places of
--             worship, parks and gardens, cemeteries
--   medium  - public but not typically crowded or loud
--   high    - crowds, noise, queueing, or continuous vehicle movement
-- ---------------------------------------------------------------------------
-- NOTE: each pattern must stay on ONE line. A line break inside a regex
-- literal becomes part of the pattern and silently breaks that alternative.
UPDATE landmark_category SET sensory_load =
    CASE
        -- HIGH first, so a carpark inside a mixed-use name cannot fall through
        -- to the 'park' rule below.
        WHEN sub_theme ~* 'carpark|railway station|transport terminal|shopping centre|department store|casino|stadium|major sports|nightclub|market|construction site|fire station|police station|observation tower|aquarium|zoo'
            THEN 'high'

        -- LOW: quiet by design. \m and \M are word boundaries, so \mpark\M
        -- matches "Park" but never "Carpark".
        WHEN sub_theme ~* '\mlibrar|gallery|museum|\mchurch|cathedral|synagogue|mosque|\mtemple|place of worship|cemetery|\mpark\M|\mgarden|\mreserve'
            THEN 'low'

        -- MEDIUM: public, usually calm, but not guaranteed.
        WHEN sub_theme ~* 'community centre|visitor centre|public building|government building|office|hospital|medical|education|school|tertiary|university|cinema|theatre|library'
            THEN 'medium'

        ELSE 'unrated'
    END;

-- ---------------------------------------------------------------------------
-- Targeted overrides where the keyword rules still get it wrong.
-- ---------------------------------------------------------------------------

-- "Informal Outdoor Facility (Park/Garden/Reserve)" is the biggest low-sensory
-- group in the dataset (37 landmarks) -- exactly what the app should recommend.
UPDATE landmark_category SET sensory_load = 'low'
 WHERE sub_theme ILIKE '%Informal Outdoor Facility%';

-- Live theatre and cinema: dark, loud, crowded at session times.
UPDATE landmark_category SET sensory_load = 'high'
 WHERE sub_theme IN ('Theatre Live', 'Cinema',
                     'Function/Conference/Exhibition Centre');

-- Hospitals are stressful environments, not quiet retreats.
UPDATE landmark_category SET sensory_load = 'high'
 WHERE sub_theme ILIKE '%Hospital%';

-- Mixed-use buildings are unpredictable; do not recommend them either way.
UPDATE landmark_category SET sensory_load = 'unrated'
 WHERE sub_theme ILIKE 'Retail/Office%' OR sub_theme ILIKE '%Residential%';

-- Industrial and vacant land are not destinations at all.
UPDATE landmark_category SET sensory_load = 'unrated'
 WHERE sub_theme ILIKE '%Vacant Land%' OR sub_theme ILIKE '%Industrial%'
    OR sub_theme ILIKE '%Store Yard%';


-- ---------------------------------------------------------------------------
-- Review the result. This table goes in your report.
-- ---------------------------------------------------------------------------
SELECT c.sensory_load,
       COUNT(DISTINCT c.category_id) AS sub_themes,
       COUNT(l.landmark_id)          AS landmarks
FROM landmark_category c
LEFT JOIN landmark l ON l.category_id = c.category_id
GROUP BY c.sensory_load
ORDER BY CASE c.sensory_load WHEN 'low' THEN 1 WHEN 'medium' THEN 2
                             WHEN 'high' THEN 3 ELSE 4 END;

-- Full detail, sorted so the recommendable places are at the top.
SELECT t.theme_name, c.sub_theme, c.sensory_load, COUNT(l.landmark_id) AS landmarks
FROM landmark_category c
JOIN theme t ON t.theme_id = c.theme_id
LEFT JOIN landmark l ON l.category_id = c.category_id
GROUP BY t.theme_name, c.sub_theme, c.sensory_load
ORDER BY CASE c.sensory_load WHEN 'low' THEN 1 WHEN 'medium' THEN 2
                             WHEN 'high' THEN 3 ELSE 4 END,
         landmarks DESC;

-- Sanity check: no carpark should ever be rated low.
SELECT sub_theme, sensory_load
FROM landmark_category
WHERE sub_theme ILIKE '%carpark%';
