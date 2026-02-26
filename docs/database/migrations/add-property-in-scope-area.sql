-- In-scope area (tenant footprint area, e.g. m²) at property level.
-- Used by the Floors in Scope tile so the user can enter the total in-scope area
-- (e.g. when occupancy is partial), consistent with the property page.
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS in_scope_area numeric;
