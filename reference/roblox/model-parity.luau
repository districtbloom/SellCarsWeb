local M=require(game.ReplicatedStorage.HubSlice.HubModel)
local s=M.fresh() local out={}
local function snap(name)
 local c=s.car
 table.insert(out,{name=name,cash=s.cash,sales=s.sales,pads=M.copy(s.pads),worker={level=s.worker.level,jobs=s.worker.jobs},completed=s.completed,car=c and {id=c.id,index=c.index,status=c.status,purchase=c.purchase,workSpent=c.workSpent,condition=c.condition}or nil,history=M.copy(s.history),ledger=M.copy(s.ledger)})
end
local function untilState(fn)for i=1,30000 do if fn()then return end M.tick(s,.1,1)end error('Scenario timed out: '..(s.car and s.car.status or 'no car'))end
local function pad(id)assert(M.buyPad(s,id),id)end
local function buy(price)untilState(function()return s.car.status=='seller'end)assert(M.openDeal(s));assert(M.counter(s,price));assert(M.buy(s))end
local function manual()
 untilState(function()return s.car.status=='repair'end)
 while s.car.status=='repair'do local j=M.job(s);if j and not j.started then assert(M.startJob(s))end M.tick(s,.1,1)end
end
local function sell(price)untilState(function()return s.car.status=='buyer'end);assert(M.openDeal(s));assert(M.counter(s,price));assert(M.sell(s));untilState(function()return not s.car end)end
pad('lot');pad('intake');buy(850);pad('repairbay');pad('tools');pad('power');pad('air');manual();pad('sales');pad('salesdesk');sell(2450);snap('first-sale')
pad('finish');assert(M.arrive(s,2));buy(1200);assert(M.plan(s,'Good'));manual();untilState(function()return s.car.status=='photo'end)
assert(M.customize(s,{paint='blue',wheels='sport',stripe=true}));assert(M.list(s));assert(M.openDeal(s));snap('lowball');assert(M.decline(s));sell(3450);snap('second-sale')
pad('mechanic');assert(M.arrive(s,3));buy(1000);assert(M.plan(s,'Quick'));untilState(function()return s.car.status=='photo'end);assert(M.upgrade(s));assert(M.list(s));sell(2200);snap('automated-sale')
pad('restoration');pad('display');untilState(function()return s.lead~=nil end);assert(M.visit(s));untilState(function()return s.car and s.car.status=='discovery'end);M.discover(s);buy(4350)
untilState(function()return s.personal.status=='parked'and s.car.status=='choose'end);assert(M.plan(s,'Quick'));untilState(function()return s.car.status=='photo'end);assert(M.list(s));sell(7650);snap('rare-sale')
return game.HttpService:JSONEncode(out)
