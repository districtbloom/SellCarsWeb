--!nocheck
-- Source-built first-loop environmental proxy. No purchase, condition or economy code.
local G={Version='2026-09-08.FJ03.first-loop.1'}
local C={dust=Color3.fromRGB(132,116,91),concrete=Color3.fromRGB(157,151,136),steel=Color3.fromRGB(49,57,59),red=Color3.fromRGB(130,48,37),wood=Color3.fromRGB(135,102,65),cream=Color3.fromRGB(216,206,167),rubber=Color3.fromRGB(30,33,32),blue=Color3.fromRGB(54,95,106),silver=Color3.fromRGB(149,156,154)}
local function model(parent,name)
 local m=Instance.new('Model');m.Name=name;m.Parent=parent;return m
end
local function part(parent,name,size,pos,color,mat,cf)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf or CFrame.new(pos);p.Color=color or C.steel;p.Material=mat or Enum.Material.Metal
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
local function box(parent,name,x,y,z,sx,sy,sz,color,mat)
 return part(parent,name,Vector3.new(sx,sy,sz),Vector3.new(x,y,z),color,mat)
end
local function beam(parent,name,a,b,width,color)
 local d=b-a;return part(parent,name,Vector3.new(width,width,d.Magnitude),(a+b)/2,color,nil,CFrame.lookAt((a+b)/2,b))
end
local function cylinder(parent,name,x,y,z,h,d,color)
 local p=part(parent,name,Vector3.new(h,d,d),Vector3.new(x,y,z),color,nil,CFrame.new(x,y,z)*CFrame.Angles(0,0,math.pi/2));p.Shape=Enum.PartType.Cylinder;return p
end
local function label(p,text,face)
 local gui=Instance.new('SurfaceGui');gui.Name='Work_Record';gui.Face=face or Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=42;gui.Parent=p
 local l=Instance.new('TextLabel');l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Text=text;l.TextColor3=C.cream;l.Font=Enum.Font.GothamMedium;l.TextScaled=true;l.TextWrapped=true;l.Parent=gui
end
local function tableKit(parent,name,x,z,w,d)
 local m=model(parent,name)
 for i=1,4 do box(m,'Timber_Board_'..i,x,4.65,z-d/2+(i-.5)*d/4,w,.23,d/4-.04,C.wood,Enum.Material.Wood)end
 for _,dx in {-w/2+.4,w/2-.4}do
  beam(m,'Fold_Leg',Vector3.new(x+dx,1.9,z-d/2+.2),Vector3.new(x+dx,4.5,z+d/2-.2),.18,C.steel)
  beam(m,'Fold_Leg',Vector3.new(x+dx,1.9,z+d/2-.2),Vector3.new(x+dx,4.5,z-d/2+.2),.18,C.steel)
 end
 box(m,'Cross_Brace',x,2.55,z,w-.6,.2,.2,C.steel);return m
end
local function chair(parent,x,z)
 local m=model(parent,'Folding_Chair');box(m,'Seat',x,3.2,z,1.9,.2,1.9,C.wood,Enum.Material.Wood)
 box(m,'Back',x,4.2,z+.85,1.9,1.5,.16,C.wood,Enum.Material.Wood)
 for _,dx in {-.75,.75}do for _,dz in {-.75,.75}do box(m,'Leg',x+dx,2.55,z+dz,.15,1.5,.15,C.steel)end end
end
local function stand(parent,name,x,z,text)
 local m=model(parent,name);box(m,'Foot',x,1.9,z,3,.2,2,C.steel)
 box(m,'Post',x,3.45,z,.22,3,.22,C.steel)
 label(box(m,'Board',x,5,z,4,2,.2,C.steel),text);return m
end
local function rectangle(parent,name,x,z,w,d,color,y)
 local m=model(parent,name)
 for _,dz in {-d/2,d/2}do box(m,'Edge',x,y or 1.89,z+dz,w,.03,.13,color,Enum.Material.SmoothPlastic)end
 for _,dx in {-w/2,w/2}do box(m,'Edge',x+dx,y or 1.89,z,.13,.03,d,color,Enum.Material.SmoothPlastic)end
 return m
end
local function light(parent,x,z)
 local m=model(parent,'Portable_Worklight');box(m,'Tripod_Foot',x,1.93,z,2.6,.16,1.8,C.steel)
 box(m,'Mast',x,4.3,z,.18,4.7,.18,C.silver)
 local head=box(m,'Lamp_Housing',x,6.65,z,2.6,.75,.6,C.steel)
 box(m,'Lens',x,6.65,z-.32,2.25,.5,.06,C.cream,Enum.Material.SmoothPlastic)
 local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,222,172);l.Range=17;l.Brightness=.65;l.Shadows=false;l.Parent=head
end
function G.Build(parent,ids)
 local root=model(parent,'SellCars_Dealership_Journey_Preview');root:SetAttribute('SourceOwner','FirstLoopGeometry');root:SetAttribute('BuildVersion',G.Version)
 local base=model(root,'00_Supported_Parcel')
 local p=box(base,'Continuous_Physical_Ground',3105,1.46,265,260,.6,560,C.dust,Enum.Material.Sandstone);p.CanCollide=true
 p=box(base,'Road_Edge',3105,1.48,0,300,.6,26,Color3.fromRGB(71,74,73),Enum.Material.Asphalt);p.CanCollide=true
 -- The unpurchased background stays rough land; these are not finished mature roads.
 for _,x in {2977,3233}do for z=40,530,70 do box(base,'Survey_Stake',x,3,z,.25,2.5,.25,C.wood,Enum.Material.Wood)end end
 local bundles={}
 for n=1,6 do local m=model(root,string.format('%02d_',n)..({'Shared_Yard','Receiving','Repair','Wash_Finish','Phone_Listing','Sales_Handover'})[n]);m:SetAttribute('PurchaseId',ids[n]);m:SetAttribute('UnlockStep',n);bundles[n]=m end
 local b=bundles[1]
 p=box(b,'Compacted_Workyard',3039,1.79,106,102,.07,92,Color3.fromRGB(119,111,93),Enum.Material.Pebble);p.CanCollide=true
 p=box(b,'Original_Shared_Slab',3041,1.88,132,42,.22,26,C.concrete,Enum.Material.Concrete);p.CanCollide=true;p:SetAttribute('FutureFunction','Wash_Bay_1')
 for _,dx in {-12,3,14}do box(b,'Slab_Joint',3041+dx,2.001,132,.055,.013,25,Color3.fromRGB(95,94,88),Enum.Material.SmoothPlastic)end
 box(b,'Concrete_Repair_Patch',3027,2.008,138,8,.015,7,Color3.fromRGB(140,139,127),Enum.Material.Concrete)
 rectangle(b,'One_Shared_Work_Position',3041,132,34,14,C.cream,2.017)
 for z=102,117,5 do p=box(b,'Owner_Walk_Slab',3047,1.89,z,5,.18,4.5,C.concrete,Enum.Material.Concrete);p.CanCollide=true end
 stand(b,'First_Identity',2996,64,'DESERT CUSTOMS\nONE CAR AT A TIME')
 stand(b,'Manual_Job_Point',3020,113,'TODAY\nBUY · MAKE GOOD · SELL')
 for _,x in {2990,3088}do for _,z in {61,150}do box(b,'Boundary_Post',x,3.1,z,.45,2.6,.45,C.wood,Enum.Material.Wood)end end
 for _,x in {2990,3088}do beam(b,'Low_Scrap_Boundary',Vector3.new(x,2.7,110),Vector3.new(x,2.7,149),.13,C.steel)end
 b=bundles[2]
 rectangle(b,'One_Ordinary_Intake',3008,88,14,23,C.cream)
 tableKit(b,'Offer_And_Records_Table',3021,85,6,3);chair(b,3021,81)
 box(b,'Condition_Ledger',3020.3,4.84,85,1.6,.09,1.1,C.cream,Enum.Material.SmoothPlastic)
 box(b,'Key_Tray',3022,4.86,85,.8,.16,.65,C.blue)
 cylinder(b,'Key_Ring',3022,4.98,85,.04,.2,C.silver)
 rectangle(b,'Seller_Standing_Space',3019,90,4,4,Color3.fromRGB(163,181,173))
 stand(b,'Receiving_Marker',2998,102,'SELLER ARRIVAL\nCONDITION · OFFER · KEYS')
 b=bundles[3]
 local chest=model(b,'Repair_Tool_Chest')
 box(chest,'Cabinet',3016,3.35,135,5.6,2.65,2.6,C.red)
 box(chest,'Rubber_Worktop',3016,4.79,135,5.8,.18,2.85,C.rubber)
 for y=2.4,4.3,.47 do box(chest,'Drawer',3016,y,133.64,5.2,.37,.08,C.red);box(chest,'Drawer_Pull',3016,y,133.55,3.8,.055,.10,C.silver)end
 for _,x in {3013.9,3018.1}do for _,z in {134.05,135.95}do local wheel=box(chest,'Caster',x,2.02,z,.34,.55,.55,C.rubber);wheel.Shape=Enum.PartType.Cylinder end end
 tableKit(b,'Starter_Workbench',3014,125,8,3.8)
 local vice=model(b,'Hand_Vice');box(vice,'Base',3016.7,4.93,125,1,.25,1,C.blue);box(vice,'Fixed_Jaw',3016.7,5.3,124.7,1,.6,.3,C.blue);box(vice,'Sliding_Jaw',3016.7,5.3,125.35,1,.5,.3,C.blue)
 beam(vice,'Screw',Vector3.new(3016.7,5.2,124.5),Vector3.new(3016.7,5.2,126),.14,C.silver)
 for i=1,4 do box(b,'Hand_Tool_Handle',3011+i*.75,4.85,124.9,.22,.12,1.1,C.red);box(b,'Hand_Tool_Head',3011+i*.75,4.88,124.2,.38,.13,.38,C.silver)end
 local jack=model(b,'Manual_Jack');box(jack,'Chassis',3027,2.2,143,3.7,.55,1.6,C.red)
 beam(jack,'Lifting_Arm',Vector3.new(3025.6,2.3,143),Vector3.new(3028.4,2.9,143),.4,C.red)
 cylinder(jack,'Saddle',3028.4,3,143,.2,.8,C.rubber)
 beam(jack,'Handle',Vector3.new(3025.5,2.2,143),Vector3.new(3023.9,5,143),.18,C.steel)
 for _,x in {3025.8,3028.2}do box(jack,'Wheel',x,2,142.25,.45,.45,.32,C.rubber);box(jack,'Wheel',x,2,143.75,.45,.45,.32,C.rubber)end
 local stands=model(b,'Jack_Stands')
 for _,x in {3032,3035}do
  for _,z in {142.2,143.8}do beam(stands,'Leg',Vector3.new(x-.6,1.98,z),Vector3.new(x,3.3,143),.18,C.red);beam(stands,'Leg',Vector3.new(x+.6,1.98,z),Vector3.new(x,3.3,143),.18,C.red)end
  box(stands,'Saddle',x,3.4,143,1,.2,.45,C.steel)
 end
 local safety=model(b,'Starter_Safety_And_Power');cylinder(safety,'Fire_Extinguisher',3010,2.8,136,1.7,.7,C.red)
 box(safety,'Fire_Handle',3010,3.75,136,.8,.18,.3,C.steel);box(safety,'Spill_Kit',3010,2.5,138,1.6,1.1,1.6,Color3.fromRGB(155,128,56))
 box(safety,'Protected_Power_Box',3011,3.2,129,1.4,2.4,.5,C.steel);beam(safety,'Protected_Power_Run',Vector3.new(3011,1.99,129),Vector3.new(3011,1.99,125),.09,C.rubber)
 light(b,3019,122)
 b=bundles[4]
 local wash=model(b,'Retained_Wet_Kit');cylinder(wash,'Wash_Bucket',3063,2.5,123,1.4,1.25,C.blue)
 cylinder(wash,'Bucket_Interior',3063,3.22,123,.04,1.08,C.rubber)
 for i=0,15 do local a=i*math.pi/8;local a2=(i+1)*math.pi/8;beam(wash,'Hose_Coil',Vector3.new(3064+math.cos(a)*1.35,2.07,126+math.sin(a)*1.35),Vector3.new(3064+math.cos(a2)*1.35,2.07,126+math.sin(a2)*1.35),.13,C.rubber)end
 local cart=model(b,'Transferable_Finish_Caddy')
 for _,y in {2.4,4.05}do box(cart,'Shelf',3064,y,138,3.4,.18,2.2,C.blue)end
 for _,dx in {-1.5,1.5}do for _,dz in {-.9,.9}do box(cart,'Leg',3064+dx,3.2,138+dz,.15,2.5,.15,C.steel)end end
 for i=1,3 do cylinder(cart,'Contained_Finish_Bottle',3062.9+i*.65,4.6,138,.8,.35,i==2 and C.cream or C.blue)end
 box(cart,'Clean_Cloths',3063.2,4.22,137.5,.8,.22,.8,C.cream,Enum.Material.Fabric)
 box(cart,'Dirty_Cloth_Bin',3064,2.75,138,2,.5,1.4,C.steel)
 light(b,3063,143)
 b=bundles[5]
 local tripod=model(b,'Transferable_Phone_Kit')
 for i=0,2 do local a=i*math.pi*2/3;beam(tripod,'Tripod_Leg',Vector3.new(3067+math.cos(a)*1.2,1.91,129+math.sin(a)*1.2),Vector3.new(3067,4.9,129),.1,C.steel)end
 box(tripod,'Mast',3067,5.2,129,.13,1.2,.13,C.silver)
 box(tripod,'Phone_Clamp',3067,5.75,129,.28,.2,1.1,C.steel)
 box(tripod,'Phone',3067,6.2,129,.12,.9,.6,C.rubber)
 tableKit(b,'Portable_Listing_Table',3068,121,4,2.5)
 label(box(b,'Listing_Slate',3068,5.28,121,2.8,.9,.12,C.steel),'PHOTO / LISTING')
 box(b,'Listing_Folio',3067,4.86,121,1,.1,1.4,C.cream,Enum.Material.SmoothPlastic)
 b=bundles[6]
 rectangle(b,'First_Sale_Display',3073,82,23,14,C.cream)
 tableKit(b,'Transferable_Deal_Table',3083,98,6,3);chair(b,3081,101);chair(b,3085,101)
 box(b,'Sale_Folio',3082,4.86,98,1.5,.1,1,C.cream,Enum.Material.SmoothPlastic)
 box(b,'Handover_Key_Tray',3084,4.9,98,1,.2,.7,C.blue)
 stand(b,'Sale_Record_Stand',3058,82,'FOR SALE\nONE GOOD CAR')
 stand(b,'Deal_Point_Marker',3085,106,'BUY · RESTORE · SELL\nSTART SMALL')
 for _,m in ipairs(bundles)do m:SetAttribute('PartCount',#m:GetDescendants())end
 return root,bundles
end
return G

