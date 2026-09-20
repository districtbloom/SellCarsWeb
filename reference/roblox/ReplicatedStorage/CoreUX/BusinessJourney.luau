-- Shared by server validation, world pad metadata, guidance, and client selection.
local J={}
J.Pads={
 {id='PlantSaleSign',path='LotEntrance.OpenAnchor',cost=0,stage=1,key='openingStep',step=0,title='Open your lot',benefit='Claim the ground for your dealership',guide='Step onto the first pad to open your dealership.',phase='START YOUR BUSINESS'},
 {id='DealTable',path='DealStation.DealTablePad',cost=100,stage=1,key='openingStep',step=1,title='Seller area',benefit='A permanent place to receive sellers and cars',guide='Set up a place to meet sellers. Every new car will arrive here.',phase='RECEIVE CARS'},
 {id='WorkshopFoundation',path='Workshop.FoundationPad',cost=100,stage=3,key='workshopStep',step=0,title='Repair bay',benefit='Establish the car’s permanent repair position',guide='You own the car. Set up a repair bay before moving it.',phase='RESTORE CARS'},
 {id='RepairTools',path='Workshop.ToolsPad',cost=150,stage=3,key='workshopStep',step=1,title='Repair tools',benefit='Jack, stands and hand tools',guide='Equip the repair bay with its basic tools.',phase='RESTORE CARS'},
 {id='YardPower',path='Workshop.PowerPad',cost=150,stage=3,key='workshopStep',step=2,title='Yard power',benefit='Connect protected power for your tools',guide='Connect power before the car arrives.',phase='RESTORE CARS'},
 {id='WorkshopApproach',path='Workshop.ApproachPad',cost=150,minStage=6,owned='shelterBuilt',optional=true,title='Workshop shelter',benefit='Cover the same repair bay',guide='Add shelter over your repair bay.',phase='RESTORE CARS'},
 {id='WorkshopServiceSlab',path='Workshop.ServiceSlabPad',cost=300,minStage=6,owned='serviceFloorBuilt',optional=true,title='Service floor',benefit='A sealed floor and drainage for repair work',guide='Finish the working floor beneath the car.',phase='RESTORE CARS'},
 {id='WorkshopLift',path='Workshop.LiftPad',cost=150,stage=3,key='workshopStep',step=3,title='Air service',benefit='Finish equipping the bay; your car moves here',guide='Connect power and air. Your car will move to the completed bay.',phase='RESTORE CARS'},
 {id='SalesPosition',path='Operations.SalesPositionPad',cost=200,stage=4,title='Sales space',benefit='A place to display cars and meet buyers',guide='The car is restored. Build a sales area and a table for making deals.',phase='SELL CARS'},
 {id='SalesDesk',path='Operations.SalesDeskPad',cost=150,stage=4,title='Deal table',benefit='Meet buyers beside the sales space',guide='Add a deal table. Your restored car will move here and go on sale.',phase='SELL CARS'},
 {id='FirstMechanic',path='Workshop.HirePad',cost=500,stage=6,title='Mechanic',benefit='Your mechanic repairs cars in the bay you built',guide='You completed the first flip. Hire a mechanic to take over repairs.',phase='DELEGATE REPAIRS'},
 {id='CarBuyer',path='Operations.CarBuyerPad',cost=1150,stage=8,key='operationsStep',step=0,title='Buyer & desk',benefit='Equip intake and hire staff to source cars',guide='Hire a buyer to source cars for your mechanic.',phase='DELEGATE BUYING'},
 {id='SalesRep',path='Operations.SalesRepPad',cost=1000,stage=8,key='operationsStep',step=3,title='Sales rep',benefit='Staff sell restored cars at your existing sales area',guide='Hire a sales rep. Buying, repair and selling can now run together.',phase='DELEGATE SELLING'},
 {id='PanelBench',path='Workshop.PanelBenchPad',cost=150,minStage=6,owned='panelBench',optional=true,title='Panel bench',benefit='A dedicated bench for body tools',guide='A dedicated bench for body tools',phase='IMPROVE YOUR WORKSHOP'},
 {id='TouchupKit',path='Workshop.TouchupKitPad',cost=150,minStage=8,owned='touchupKit',optional=true,title='Touch-up kit',benefit='Organize paint touch-up supplies',guide='Organize paint touch-up supplies',phase='IMPROVE YOUR WORKSHOP'},
 {id='WheelTools',path='Workshop.WheelToolsPad',cost=150,minStage=8,owned='wheelTools',optional=true,title='Wheel tools',benefit='Organize wheel and alignment tools',guide='Organize wheel and alignment tools',phase='IMPROVE YOUR WORKSHOP'},
 {id='FluidKit',path='Workshop.FluidKitPad',cost=150,minStage=9,owned='fluidKit',optional=true,title='Fluid service',benefit='Contain fluids and cooling supplies',guide='Contain fluids and cooling supplies',phase='IMPROVE YOUR WORKSHOP'},
 {id='FinishKit',path='Workshop.FinishKitPad',cost=150,minStage=10,owned='finishKit',optional=true,title='Finish trolley',benefit='Organize finishing tools and lighting',guide='Organize finishing tools and lighting',phase='IMPROVE YOUR WORKSHOP'},
 {id='PartsShelves',path='Workshop.PartsShelvesPad',cost=150,minStage=12,owned='partsShelves',optional=true,title='Parts shelves',benefit='Store job parts in labelled bins',guide='Store job parts in labelled bins',phase='IMPROVE YOUR WORKSHOP'},
 {id='FirstPersonalCar',path='PersonalGarage.ClaimPad',cost=0,stage=8,key='operationsStep',step=4,automation=true,optional=true,title='Personal car',benefit='A reward after the business completes its first automated cycle',guide='Your team completed a flip. Claim a car of your own.',phase='ENJOY YOUR PROGRESS'},
}
function J.Available(s,id)
 if not s or s.firstTransit or s.pendingDeal then return false end
 local p=J.Get(id);if not p then return false end
 if p.minStage then return s.stage>=p.minStage and not s[p.owned]end
 return s.stage==p.stage and (not p.key or (s[p.key]or 0)==p.step) and (not p.automation or s.automationDemoComplete) and (p.id~='SalesPosition' or not s.salesDisplayBuilt) and (p.id~='SalesDesk' or (s.salesDisplayBuilt and not s.salesBuilt)) and (p.id~='CarBuyer' or s.secondWorkComplete)
end
function J.Active(s)
 for _,p in J.Pads do if not p.optional and J.Available(s,p.id)then return p.id end end
end
function J.Get(id)for _,p in J.Pads do if p.id==id then return p end end end
function J.Find(world,path)local o=world;for n in path:gmatch('[^.]+')do o=o and o:FindFirstChild(n)end;return o end
return J

