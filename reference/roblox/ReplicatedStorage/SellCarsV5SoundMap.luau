-- SND01: authored acoustic zoning, not geometric acoustic simulation.
local V=Vector3.new
local M={Version='2026-09-09.SND01',Assets={water='9120591962',fan='6048037597',wind='9114057104',foliage='9114518577',music='9038532750',vent='103082732969874',ratchet='9118047781',metal='9125691302',box='9113578540',vacuum='9120361051',shutter='17208312548'}}
M.Route={
 {'Arrival / open roadside',V(3087,7,23),V(3105,8,52),'FRONT'},
 {'Client room / quiet welcome',V(3049,7,40),V(3039,6,52),'CLIENT'},
 {'Intake / no invented transactions',V(3007,7,75),V(2998,5,82),'FRONT'},
 {'Mechanical / ratchet audition',V(3004,8,201),V(2996,6,200),'MECHANICAL','MECHANICAL'},
 {'Wash / actual rinse activity',V(3040,9,139),V(3031,9,132),'WASH'},
 {'Body / light sheet-metal audition',V(3002,8,276),V(2993,6,271),'BODY','BODY'},
 {'Tune / actual fan movement',V(3028,8,324),V(3018,6,319),'TUNE'},
 {'Paint / filtered-air plant',V(3210,9,329),V(3217,13,331),'PAINT'},
 {'Detail / extraction audition',V(3207,7,252),V(3215,6,253),'DETAIL','DETAIL'},
 {'Photo / single capture audition',V(3158,9,179),V(3155,11,187),'PHOTO','PHOTO'},
 {'Owner / optional inherited stereo',V(3216,7,81),V(3225,5,85),'OWNER'},
 {'Parts / packing audition',V(3020,8,454),V(3022,6,461),'PARTS','PARTS'},
 {'Operations / contained utility air',V(3173,8,466),V(3166,7,465),'OPERATIONS'},
 {'Headquarters / quiet reception',V(3105,7,482),V(3116,8,493),'HQ'},
 {'Collector / deliberate quiet',V(3105,26,430),V(3124,26,440),'COLLECTOR'},
 {'Gardens / desert air and pauses',V(3105,8,264),V(3105,5,245),'GARDENS'},
}
function M.Zone(v)
 local x,z=v.X,v.Z
 if x<2960 or x>3250 or z<0 or z>530 then return 'OUTSIDE'end
 if z>=479 and x>3060 and x<3150 then return'HQ'end
 if z>=399 and z<=465 and x>3060 and x<3150 then return'COLLECTOR'end
 if z>=405 then return x<3060 and'PARTS'or x>3150 and'OPERATIONS'or'GARDENS'end
 if z<120 then if x>=3155 and z>=30 then return'OWNER'elseif x>=3028 and x<=3060 and z>=31 and z<=68 then return'CLIENT'else return'FRONT'end end
 if x>=3085 and x<=3125 then return'GARDENS'end
 if x<3085 then return z<168 and'WASH'or z<233 and'MECHANICAL'or z<298 and'BODY'or z<365 and'TUNE'or'GARDENS'end
 return z<170 and'OWNER'or z<234 and'PHOTO'or z<298 and'DETAIL'or z<365 and'PAINT'or'GARDENS'
end
function M.Bleed(sourceZone,listenerZone,step)
 if sourceZone==listenerZone then return 1 end
 if listenerZone=='COLLECTOR'or listenerZone=='HQ'then return .035 end
 if listenerZone=='CLIENT'then return step>=143 and .08 or .35 end
 if sourceZone=='OWNER'and listenerZone~='OWNER'then return .08 end
 if sourceZone=='OUTSIDE'or sourceZone=='GARDENS'then return listenerZone=='FRONT'and .65 or step>=157 and .13 or .38 end
 if listenerZone=='GARDENS'or listenerZone=='FRONT'then return step>=157 and .25 or .5 end
 return step>=157 and .12 or .35
end
-- Audition targets use exact existing machinery; missing targets are reported, never invented.
M.Targets={
 {key='BODY_AIR',model='Hot_Work_Safety_And_Extraction',part='DustCollectorCabinet',asset='vent',zone='BODY',mode='BED',gain=.12,radius=24},
 {key='PAINT_AIR',model='Filtered_Air_And_Extraction',part='ServicePlenum',asset='vent',zone='PAINT',mode='BED',gain=.10,radius=33},
 {key='OPERATIONS_AIR',model='Utilities_And_Maintenance_Annex',part='IntakeLouvre',asset='vent',zone='OPERATIONS',mode='BED',gain=.09,radius=26},
 {key='MECHANICAL',model='Engine_Rebuild_Stand',part='RotisserieHead',asset='ratchet',zone='MECHANICAL',mode='CUE',gain=.24,radius=24},
 {key='BODY',model='English_Wheel_And_Planishing',part='PolishedUpperWheel',asset='metal',zone='BODY',mode='CUE',gain=.14,radius=23},
 {key='DETAIL',model='Filtered_Wet_Dry_Vacuum',part='VacuumMotorHead',asset='vacuum',zone='DETAIL',mode='CUE',gain=.13,radius=24},
 {key='PHOTO',model='Editorial_Turntable_Studio_1',part='StudioCameraBody',asset='shutter',zone='PHOTO',mode='CUE',gain=.15,radius=24},
 {key='PARTS',model='Kitting_Packing_And_Dispatch',part='OpenKitTray',asset='box',zone='PARTS',mode='CUE',gain=.20,radius=23},
}
return M

