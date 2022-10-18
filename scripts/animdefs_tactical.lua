local commondefs = include( "sim/unitdefs/commondefs" )

local Layer = commondefs.Layer
local BoundType = commondefs.BoundType

-------------------------------------------------------------------
-- Data for anim definitions.
--
-- For items that do not in fact provide cover, or block sight, custom anims are substituted for tactical view.

local animdefs_tactical =
{
	-- Non-cover and Sightblock tactical DECOR --

	-- this glass wall incorrectly has cover icons in vanilla
    publicterminal_glasswall1 =
    {
        build = { "data/anims/Unique_publicterminal/publicterminal_glasswall1.abld" },
        anims = { "data/anims/Unique_publicterminal/publicterminal_glasswall1.adef" },
        anim = "idle",
        scale = 0.25,
        boundType = BoundType.Wall,
    }, 
	
	-- FTM OFFICE --------------------------------------------------------------------------------------------
	
	ftm_hall_plant1=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1plant1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1plant1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

	ftm_hall_plant2=
	{
		build = { "data/anims/FTM_hall/ftm_hall_object_1x1plant2.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/FTM_hall/ftm_hall_object_1x1plant2.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

-- FTM LAB -----------------------------------------------------------------------------------------------

	ftm_lab_closet1=
	{
		build = { "data/anims/FTM_lab/ftm_lab_object_1x1closet1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/FTM_lab/ftm_lab_object_1x1closet1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_med_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

-- FTM SECURITY ------------------------------------------------------------------------------------------

	ftm_security_1x1locker=
	{
		build = { "data/anims/FTM_security/ftm_security_object_1x1locker.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/FTM_security/ftm_security_object_1x1locker.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		symbol = "character",
		scale = 0.25,
		layer = Layer.Object,
		boundType = BoundType.bound_1x1_tall_med,
		filterSymbols = {{symbol="icon",filter="default"}},
	},

-- KO OFFICE ---------------------------------------------------------------------------------------------

	decor_ko_office_flag1 =
	{
		build = { "data/anims/KO_office/ko_office_decor_flag1.abld", "data/anims/hek/mf_noncoverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_flag1.adef", "data/anims/hek/mf_noncoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_ko_office_lamp =
	{
		build = { "data/anims/KO_office/ko_office_decor_lamp1.abld", "data/anims/hek/mf_noncoverpieces_1x1.abld" },
		anims = { "data/anims/KO_office/ko_office_decor_lamp1.adef", "data/anims/hek/mf_noncoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_ko_office_bookshelf1 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1bookshelf1.abld", "data/anims/bcl/mf_tallcoverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1bookshelf1.adef", "data/anims/bcl/mf_tallcoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},

	decor_ko_office_bookshelf2 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1bookshelf2.abld", "data/anims/bcl/mf_tallcoverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1bookshelf2.adef", "data/anims/bcl/mf_tallcoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},

	decor_ko_office_cabinet1 =
	{
		build = { "data/anims/KO_office/ko_office_object_2x1tvcabinet1.abld", "data/anims/bcl/mf_tallcoverpieces_1x2.abld" },
		anims = { "data/anims/KO_office/ko_office_object_2x1tvcabinet1.adef", "data/anims/bcl/mf_tallcoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	-- KO LAB ---------------------------------------------------------------------------------------------

	decor_ko_lab_tallcase1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_1x1tallcase1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_1x1tallcase1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},		

	decor_ko_lab_pit1 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x3pit1.abld", "data/anims/hek/mf_noncoverpieces_2x3.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x3pit1.adef", "data/anims/hek/mf_noncoverpieces_2x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
	},	

	decor_ko_lab_pit2 =
	{
		build = { "data/anims/KO_lab/ko_lab_object_2x3pit2.abld", "data/anims/hek/mf_noncoverpieces_2x3.abld" },
		anims = { "data/anims/KO_lab/ko_lab_object_2x3pit2.adef", "data/anims/hek/mf_noncoverpieces_2x3.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Floor_2x3,
	},	

	-- KO BARRACKS ---------------------------------------------------------------------------------------------

	decor_ko_barracks_fridge1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1fridge1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1fridge1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},		

	decor_ko_barracks_vendingmachine1 =
	{
		build = { "data/anims/KO_Barracks/ko_barracks_object_1x1vendingmachine1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/KO_Barracks/ko_barracks_object_1x1vendingmachine1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	-- KO HALL ---------------------------------------------------------------------------------------------

	decor_ko_hall_bookshelf1 =
	{
		build = { "data/anims/KO_Hall/ko_hall_object_2x1bookshelf1.abld", "data/anims/bcl/mf_tallcoverpieces_1x2.abld" },
		anims = { "data/anims/KO_Hall/ko_hall_object_2x1bookshelf1.adef", "data/anims/bcl/mf_tallcoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	-- SEIKAKU LAB ---------------------------------------------------------------------------------------------

	decor_sk_office_shelf1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1shelf1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1shelf1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_sk_office_walldivider1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.abld", "data/anims/bcl/mf_tallnoncoverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_1x1walldivider.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_sk_office_tv1 =
	{
		build = { "data/anims/Seikaku_office/seikaku_office_object_2x1tv.abld", "data/anims/bcl/mf_tallcoverpieces_1x2.abld" },
		anims = { "data/anims/Seikaku_office/seikaku_office_object_2x1tv.adef", "data/anims/bcl/mf_tallcoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	decor_sk_bay_tallcrate1 =
	{
		build = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1tallcrate.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/Seikaku_robobay/seikaku_robobay_object_1x1tallcrate.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},

	decor_plastek_psilab_cabinet1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1cabinet1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_1x1cabinet1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},	

	decor_plastek_psilab_bookshelf1 =
	{
		build = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1bookshelf1.abld", "data/anims/bcl/mf_tallcoverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_psilab/plastek_psilab_object_2x1bookshelf1.adef", "data/anims/bcl/mf_tallcoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	decor_plastek_lab_cabinet1 =
	{
		build = { "data/anims/Plastek_Lab/plastek_lab_object_1x1cabinet1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_Lab/plastek_lab_object_1x1cabinet1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_med_med,
	},	

	decor_plastek_hall_bookshelf1 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_1x1bookshelf1.abld", "data/anims/bcl/mf_tallcoverpieces_1x1.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_1x1bookshelf1.adef", "data/anims/bcl/mf_tallcoverpieces_1x1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_1x1_tall_med,
	},		

	decor_plastek_hall_bookshelf2 =
	{
		build = { "data/anims/Plastek_hall/plastek_hall_object_2x1bookshelf2.abld", "data/anims/bcl/mf_tallcoverpieces_1x2.abld" },
		anims = { "data/anims/Plastek_hall/plastek_hall_object_2x1bookshelf2.adef", "data/anims/bcl/mf_tallcoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_tall_med,
	},	

	-- vanilla uses 1x1 cover icon, but this anim is neither 1x1 nor cover.
	holdingcell_1x1_celldoor1 =
	{                            
		build = { "data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.abld" },
		anims = { "data/anims/Unique_holdingcell/holdingcell_1x1_celldoor1.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.Wall,
	},			

	decor_cybernetics_object_2x1liquidpool1=
	{
		build = { "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.abld", "data/anims/hek/mf_noncoverpieces_1x2.abld" },
		anims = { "data/anims/Unique_cybernetics/cybernetics_2x1_liquidpool1.adef", "data/anims/hek/mf_noncoverpieces_1x2.adef" },
		anim = "idle",
		scale = 0.25,
		boundType = BoundType.bound_2x1_med_med, 
	},

}

return animdefs_tactical
