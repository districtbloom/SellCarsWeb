-- Actual Institution asset ancestry. Ordinals here refer to the original draft;
-- the compiler preserves stable IDs when roof229 moves ahead of exhibits.
local R={Version='2026-09-08.FJ240.PI01'}
R.Departments={
 Wash={start=41,shell=72,second=124,staff=42,staff2=125,pro=175,final=203,x=3023,z=144},
 Mechanical={start=35,shell=78,second=126,staff=40,staff2=127,pro=157,final=207,x=3023,z=199},
 Body_Restoration={start=46,shell=84,second=129,staff=89,staff2=130,pro=161,final=208,x=3023,z=263},
 Tune_Performance={start=51,shell=90,second=131,staff=95,staff2=132,pro=165,final=211,x=3023,z=331},
 Paint_Exterior={start=49,shell=96,second=134,staff=101,staff2=135,pro=170,final=214,x=3187,z=331},
 Detail_QC={start=43,shell=102,second=136,staff=105,staff2=137,pro=177,final=214,x=3187,z=263},
 Photo_Listing={start=60,shell=106,second=138,staff=108,staff2=139,pro=180,final=214,x=3187,z=199},
}
R.Equipment={
 -- model name = first useful assembly, final renovation, optional intermediate renovation
 Compressor_And_Air={53,207},Contained_Fluids={80,207,160},Cooling_Pressure_Test_Trolley={37,207,160},Diagnostic_Trolley={81,205,159},Engine_Rebuild_Stand={158,207},Hose_Air_Reel={53,207},Lift_1={79,157},Lift_2={126,157},Tool_Bench_And_Vice={82,207},Safety_Station={69,191},
 Cell_Control_1={101,170},Cell_Control_2={135,170},Contained_Chemical_Cabinet={50,100},Film_Cutting_And_Glass={173,214},Filtered_Air_And_Extraction={97,170,98},Filtered_Finish_Cell_1={97,170},Filtered_Finish_Cell_2={134,170},Mix_Bank_And_Rare_Finishes={99,212,171},Paint_Shaker_And_Match={172,212},Parked_IR_Curing_Lamp={174,214},Spray_Gun_Service={100,214},Wrap_And_Tint_Roll_Rack={173,214},
 Covered_Receiving_And_Pallet_Jack={112,202,150},Kitting_Packing_And_Dispatch={113,202,149},Outbound_Job_Kits={117,202},Rare_Parts_Control={152,199},Restoration_Consumables={39,149},Returns_Quarantine={114,152},Service_Parts_Stock={38,149},Tyre_And_Panel_Store={38,149},
 Dispatch_ServiceWriter_And_Radio={55,154},Lockers_Changing_And_Break={56,238,156},Low_Observation_And_Shift_Briefing={115,153},Office_Rooms_And_Circulation={115,156},Supervisor_And_CCTV={115,154},Training_And_Standards={116,234,155},Utilities_And_Maintenance_Annex={71,192},
 Bunded_Chemistry_And_Dosing={75,204,176},Dryer_Head_1={76,175},Dryer_Head_2={124,175},Eye_Rinse_And_Spill_Response={69,175},Prewash_Lance_Control_And_Safety={73,175},Reclaim_Filtration_And_Pump_Skid={74,203,176},Tracked_Wash_Cell_1={72,175},Tracked_Wash_Cell_2={124,175},Wash_Process_Finishes={77,175},Wet_Floors_And_Trench_Drains={41,175},
 English_Wheel_And_Planishing={162,208},Frame_Straightening_Cell_1={85,161,86},Frame_Straightening_Cell_2={129,161},Hot_Work_Safety_And_Extraction={88,161},MIG_Welding_And_Gas_Trolley={47,163},Panel_Craft_Bench_And_Tools={87,208},Resistance_Spot_Welder={163,208},Restoration_Floor_And_Control_Edge={84,161},Restoration_Panels_And_Templates={48,208,161},
 Acoustic_Dyno_Control_Nook={93,210,165},Calibration_Floor_And_Utility_Edge={90,165},ECU_And_Sensor_Calibration_Bench={93,210,166},Recessed_Rolling_Road_Cell_1={91,165,92},Recessed_Rolling_Road_Cell_2={131,165},Running_Gear_And_Special_Build_Hardware={52,211,169},Tyre_Changing_Station={94,169},Wheel_Balancing_Station={94,169},
 Clean_Towels_Pads_And_Finish_Tools={44,177},Correction_Light_Cell_1={104,177},Correction_Light_Cell_2={136,177},Detail_Clean_Floor_And_Service_Edge={102,177},Filtered_Wet_Dry_Vacuum={103,177},Finish_Chemistry_And_Dilution_Control={105,178},Finish_Measurement_And_Release_Desk={45,215,179},Steam_And_Spot_Extraction_Cart={103,177},
 Camera_Grip_And_Calibration_Store={109,182},Capture_Preparation_Trolley={109,180},Editorial_And_Listing_Workstation={108,218,181},Editorial_Floor_And_Service_Edge={106,180},Editorial_Turntable_Studio_1={107,180},Editorial_Turntable_Studio_2={138,180},Provenance_Capture_And_Build_Record={217,218},
 Owner_Craft_Bench={121,225,185},Owner_Floor_And_Circulation={22,227},Personal_Build_History_And_Rest={186,227},Personal_Configuration_Studio={63,223,184},Secure_Performance_Parts={185,224},
 Curator_Archive_Station={190,230},Gallery_Viewing_And_Light={188,232},
 Consultation_Lounge_And_Materials={153,237},Crown_Hospitality_And_Craft={236,236},Crown_Project_Room={236,236},Founding_Craft_Specimens={237,237},HQ_Analytics_And_Management={154,237},Reception_And_Records={153,237},
}
local function has(p,s)return string.find(p,s,1,true)~=nil end
-- PI01: earn complete advanced subassemblies rather than recolouring them.
-- Baseline coordinates disambiguate duplicate part names in the source models.
function R.UpgradeFirst(o,path)
 local n=o.Name;local cf=o:GetAttribute('FJ_CF')or o.CFrame;local z=cf.Position.Z
 if has(path,'Shared_Customer_Room/WestTimberSolarScreen/')then return 221
 elseif has(path,'ECU_And_Sensor_Calibration_Bench/')then
  if table.find({'OscilloscopeHousing','ScopeScreen','ScopeDial','HarnessConnector','BenchHarnessLead'},n)then return 166 end
 elseif has(path,'Acoustic_Dyno_Control_Nook/')then
  if n=='TelemetryRack'or n=='RackVent'then return 210 end
  if table.find({'TelemetryMonitor','ReadableDarkDisplay','MonitorPedestal','MeasuredGraphBar'},n)and math.abs(z-310)>1 then return 210 end
  if table.find({'AcousticSideBase','AcousticSideGlazing','SideGlazingFrame','ControlFrontPier','FrontVisionPanel','OpenControlDoorHeader','AbsorberFabricPanel'},n)then return 165 end
 elseif has(path,'Finish_Measurement_And_Release_Desk/')then
  if table.find({'ReleaseTablet','ReleaseTabletStand','ReleaseScreen','QCRecordLine'},n)then return 215 end
  if table.find({'InspectionInstrumentCase','CaseFoam','GlossMeter','PaintThicknessGauge','GaugeDisplay'},n)then return 179 end
 elseif has(path,'Reclaim_Filtration_And_Pump_Skid/')then
  if z>146 and table.find({'CartridgeFilter','FilterClamp','FilterMount','FilterInlet','FilterOutlet'},n)then return 203 end
 end
end
function R.Department(path)
 for name,d in R.Departments do if has(path,name)then return name,d end end
 local aliases={['/01_Wash/']='Wash',['/02_Body/']='Body_Restoration',['/03_Tune/']='Tune_Performance',['/04_Detail/']='Detail_QC',['/05_Photo/']='Photo_Listing'}
 for a,n in aliases do if has(path,a)then return n,R.Departments[n]end end
end
function R.Bind(o,path)
 local dept,d=R.Department(path);local pos=o:IsA('BasePart')and o.Position or Vector3.zero
 local b={first=0,finish=0,mid=0,kind='asset',department=dept}
 local function set(a,z,m)b.first=a;b.finish=z or a;b.mid=m or 0;return b end
 -- Invisible contract/evidence geometry stays at its saved visibility, never invented as content.
 if path:match('^0[023467]_')or has(path,'/99_')or has(path,'/90_Restoration')or has(path,'/97_Evidence')or has(path,'/98_Access_Paths')or has(path,'/00_Shared_Kit/')then return set(999)end
 if path:match('^01_Ground_And_Road/')then return set(0)end
 if has(path,'/05_Architecture_Massing/')then error('Unexpected prefixed path')end
 if path:match('^05_Architecture_Massing/')then
  if d then b.kind='productionShell';return set(d.start,d.final,d.pro)end
  if has(path,'Elevated_Collector_Hall')then b.kind='collector';return set(187,233)end
  if has(path,'Parts_And_Logistics')then return set(112,202)end
  if has(path,'Headquarters')then b.kind='hq';return set(153,235)end
  return set(141,197)
 end
 if path:match('^08_Institution_Production_A/')then return set(d and d.shell or 0,d and d.final or 0)end
 if path:match('^09_Institution_Production_B/')then
  local i=tonumber(path:match('Owner_Position_(%d)'));if i then return set(({22,62,120,183,183,226})[i],227)end
  i=tonumber(path:match('Legacy_Snapshot_(%d)'));if i then return set(({187,229,189,187,229,189})[i],232)end
  if has(path,'Owner_Garage')then b.kind='owner';return set(62,227)end
  if has(path,'Collector_Hall')then b.kind='collector';return set(187,233)end
  if has(path,'Headquarters')then b.kind='hq';return set(153,235)end
  if has(path,'Estate_Identity')then if has(path,'Boundary')then return set(65,196)end;return set(59,195)end
  if has(path,'Parts')then return set(112,202)end
  if has(path,'Staff')or has(path,'Operations')then return set(115,238)end
  return set(118,219)
 end
 if has(path,'/06_Atmosphere/')then
  if has(path,'Occupation_Production')then return set(d and(has(path,dept..'_2')and d.staff2 or d.staff)or 123)end
  if has(path,'Occupation_Rear')then if has(path,'PartsRunner')then return set(117)elseif has(path,'Curator')or has(path,'GalleryVisitor')then return set(190)elseif has(path,'Analyst')then return set(154)end;return set(55)end
  if has(path,'Occupation_Frontage')then if has(path,'Seller')then return set(29)elseif has(path,'SalesAdvisor')or has(path,'Buyer')then return set(33)elseif has(path,'DeliveryHost')then return set(119)end;return set(148)end
  if has(path,'Activity_Wash')then return set(999)end
  if has(path,'Lighting_Hierarchy')then return set(195)end
  if has(path,'Landscape_And_Comfort')then return set(194,240)end
  if has(path,'Movement_Surfaces')then
   if has(path,'Limestone_Craft_Court')then return set(193,240)end
   if has(path,'Production_Street')or has(path,'Operating_Road')then return set(67,193)end
   if has(path,'Gravel_Reservations')then return set(123,194)end
   return set(66,193)
  end
 end
 if has(path,'Diagnostic_Trolley/')and has(o.Name,'DiagnosticTrace')then return set(205)end
 if has(path,'Bunded_Chemistry_And_Dosing/')and(table.find({'MeteringPump','MeteringTube','ChemistryManifold','DoseDial','DosingPanelBack','DosedSupplyLine'},o.Name))then return set(204)end
 if has(path,'Mix_Bank_And_Rare_Finishes/')then
  if o.Name=='CurvedFinishSample'then return set(212)end
  if o.Name=='PrecisionScale'or o.Name=='ScalePan'then return set(171,212)end
 end
 if has(path,'Curator_Archive_Station/')and(o.Name:find('Screen')or o.Name=='ArchiveKeyboard'or o.Name=='ScreenMount')then return set(230)end
 if has(path,'Owner_Floor_And_Circulation/')then b.kind='owner';return set(22,227)end
 local earned=R.UpgradeFirst(o,path)
 if earned then
  for segment in path:gmatch('[^/]+')do local e=R.Equipment[segment];if e then return set(earned,e[2],e[3]and math.max(earned,e[3])or 0)end end
  return set(earned)
 end
 for segment in path:gmatch('[^/]+')do local e=R.Equipment[segment];if e then return set(e[1],e[2],e[3])end end
 local n=tonumber(path:match('Personal_Fleet_Setting_(%d)'));if n then return set(({22,62,120,183,183,226})[n],227)end
 n=tonumber(path:match('Legacy_Exhibit_(%d)'));if n then return set(({187,229,189,187,229,189})[n],232)end
 if has(path,'Craft_Specimen_')then return set(231)end
 if has(path,'Craft_Gallery_Shell')then b.kind='collector';return set(187,233)end
 if has(path,'HQ_Circulation')or has(path,'HQ_Framed')or has(path,'HQ_Material')then b.kind='hq';return set(153,235)end
 if has(path,'Personal_Workshop_Shell')then b.kind='owner';return set(62,227)end
 if has(path,'Retained_Shell_And_Low_Annex')then b.kind='wing';return set(has(path,'Parts_Logistics')and 38 or 54,has(path,'Parts_Logistics')and 202 or 238,192)end
 if has(path,'/01_Service_Floors/')then return set(d and d.start or 49,d and d.pro or 170)end
 if has(path,'/07_Elevation_01/')then
  if has(path,'Mechanical_Roof')then return set(157,207)elseif has(path,'Tune_Equipment')then return set(165,211)elseif has(path,'Owner_')then return set(185,228)elseif has(path,'Operations_')then return set(57,238)elseif has(path,'Parts_')then return set(150,202)end
  return set(194,240)
 end
 if has(path,'/08_Courtyard02/')then return set(228)end
 if has(path,'/09_Campus03/')then
  if has(path,'Desert_Promenade')then return set(240)elseif has(path,'Parts_Work_Yard')then b.kind='court';return set(150,202)else b.kind='court';return set(192,238)end
 end
 if has(path,'/11_Frontage04/')then
  if has(path,'Actual_Sales_Vehicles')then
   local name=path:match('Actual_Sales_Vehicles/([^/]+)');local ord={SalesCar_3=6,SalesCar_1=31,ElevatedSalesCar_1=32,SalesCar_2=128,ElevatedSalesCar_2=133,SalesCar_4=140};return set(assert(ord[name],'Unknown sales car '..tostring(name)),143)
  end
  if has(path,'Receiving_Cantilever')then b.kind='receiving';return set(28,197,141)end
  if has(path,'Shared_Customer_Room')then b.kind='customer';return set(118,221,144)end
  if has(path,'Sales_Colonnade')then b.kind='sales';return set(143,219)end
  if has(path,'Street_Gateway')then return set(147,196)end
  if has(path,'Unified_Frontage_Ground')then return set(25,143)end
  if has(path,'Shared_Hospitality')then return set(145,221)end
  if has(path,'Receiving_Fitout')then return set(142,198)end
  if has(path,'Handover_Console')then return set(146,219)end
  if has(path,'Stowed_Reveal')then return set(119,220)end
  if has(path,'Listing_')then local i=tonumber(path:match('Listing_(%d+)'));return set(i and({31,32,128,6,133,140})[i]or 143,143)end
  if has(path,'Frontage_Landscape')then return set(148,222)end
  if has(path,'Warm_Lighting')then return set(195,222)end
  return set(25,143)
 end
 if has(path,'/12_WorkshopCraft01/')then return set(157,207)end
 if has(path,'/13_DistrictFinish02/')then
  if d then return set(191,d.final)end
  if has(path,'Rear_Collector')then b.kind='collector';return set(190,233)end
  if has(path,'Rear_Headquarters')then b.kind='hq';return set(153,235)end
  if has(path,'Parts_Logistics')then return set(192,202)end
  return set(192,238)
 end
 if has(path,'/14_AtmosphereCraft03/')then
  if has(path,'Mechanical')then return set(207)elseif has(path,'Paint')then return set(214)elseif has(path,'Photo')then return set(218)elseif has(path,'Owner')then return set(228)end
  return set(240)
 end
 if has(path,'/04_Estate_Identity/')then
  if has(path,'Rough_To_Remarkable')then return set(239)elseif has(path,'Roadside')then return set(147,196)elseif has(path,'Original_Yard')then return set(34,196)end
  return set(196)
 end
 error('UNBOUND '..path)
end
return R