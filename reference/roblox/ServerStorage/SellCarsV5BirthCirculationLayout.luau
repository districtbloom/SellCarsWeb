-- CIRC02: reversible Birth-only poses. Original FJ_CF and later transfers stay intact.
local M={}
function M.Plan(root)
 local out={};local a=root.Retained_Starter_Ancestry
 local function add(p,cf)out[#out+1]={part=p,cf=cf}end
 local function move(g,delta)for _,p in g:GetDescendants()do if p:IsA('BasePart')then add(p,p:GetAttribute('FJ_CF')+delta)end end end
 move(a['04_Wash_Finish'].Transferable_Finish_Caddy,Vector3.new(-12,0,9))
 move(a['05_Phone_Listing'],Vector3.new(0,0,26))
 for _,p in root.GE01_Early_Property.P001_Roadside_Workyard_Approach:GetDescendants()do
  if p:IsA('BasePart')and(p.Name=='FootwayGuideStake'or p.Name=='CustomerFootApproach')then add(p,p:GetAttribute('FJ_CF')+Vector3.new(22.5,0,0))end
 end
 local pivot=CFrame.new(3073,0,82);local turn=pivot*CFrame.Angles(0,math.pi/2,0)*pivot:Inverse()
 for _,g in {a['06_Sales_Handover'].First_Sale_Display,root.Journey_Structural_Transitions.P019_Ready_Stock_Edge}do
  for _,p in g:GetDescendants()do if p:IsA('BasePart')then add(p,turn*p:GetAttribute('FJ_CF'))end end
 end
 return out
end
return M

