-- FullJourney runtime data adapted to the existing Sell Cars clients and assets.
local RS=game:GetService("ReplicatedStorage")
local Operations=require(script.Parent.FullJourneyOperations)
local Catalog=require(script.Parent.FullJourneyCatalog)
local CarVisuals=require(game.ServerScriptService.TycoonSystem.JunkLot.CarVisuals)
local Config=require(RS.DealerCarConfig)
local Remotes=require(game.ServerScriptService.TycoonSystem.JunkLot.Remotes)
local Bridge={}
local Service
local initialized=false
local function ensure(name)
	local folder=RS:FindFirstChild("TycoonRemotes")
	local remote=folder:FindFirstChild(name)
	if not remote then remote=Instance.new("RemoteEvent");remote.Name=name;remote.Parent=folder end
	return remote
end
local function send(record,name,payload)
	if record.owner and record.owner.Parent then ensure(name):FireClient(record.owner,payload) end
end
local function valueOf(s)
	if not s then return 0,0,0 end
	local investment=s.deposit or 0
	local repaired=0
	for _,id in {"Body","Wheels","Engine"} do if s.parts and s.parts[id] then repaired+=1 end end
	local projected=s.deal and (s.deal.fixedValue or 1000)
		or (math.max(investment,s.ask or 0)+math.floor(150+(s.record.data.step or 0)*14+9*35+math.pow(s.record.data.step or 0,1.35)*3))
	local base=s.deal and 25 or math.max(investment,s.ask or 0,100)
	local fraction=s.deal and math.max(0,repaired-1)/2 or repaired/3
	return math.floor(base+(projected-base)*fraction),projected,base
end
local function slot(s,which)
	local model=s and s.car
	local occupied=model and model.Parent and model:GetAttribute("DealerSlot")==which
	if not occupied then return {state="None",slot=which,slotIndex=1,workingIndex=which=="working" and 1 or nil,tradeId="",parts={},onLot=false} end
	local current,restored,base=valueOf(s)
	local partGains={Body=math.floor((restored-base)/3),Wheels=math.floor((restored-base)/(s.deal and 2 or 3)),Engine=math.floor((restored-base)/(s.deal and 2 or 3))}
	return {tradeId=s.tradeId,slot=which,slotIndex=1,workingIndex=which=="working" and 1 or nil,displayIndex=which=="display" and 1 or nil,
		state=s.tradeState or "None",templateId=s.templateId,displayName=Config.displayName(s.templateId),parts=table.clone(s.parts or {}),
		value=current,currentValue=current,valueAfterRepairs=restored,restoredValue=restored,baseValue=base,acquisitionValue=base,
		partsValue=current-base,repairValue=current-base,repairProgress=(current-base)/math.max(1,restored-base),repairGains=partGains,
		calculatedValue=current,serviceMultiplier=1,serviceStages={},listingMarkup=0,listedPrice=s.saleOffer or restored,currentOffer=s.saleOffer or 0,
		purchaseCost=s.deposit or 0,serviceCost=0,serviceCostPaid=0,totalInvestment=s.deposit or 0,finalProfit=s.profit or 0,cost=s.deposit or 0,ask=s.ask or 0,
		serviced=(s.services or 0)>=3,atBay=false,serviceRollDone=true,serviceQueuedAt=0,pipelineState=s.tradeState=="Ready" and "complete" or "working",
		pipelineStage=s.currentPart,pipelinePlan={},completedServices={},skippedServices={},dirty=false,dirtLevel=0,oilLeak=false,
		offered=s.saleOffer or 0,haggleUsed=s.haggleUsed==true,rarityOneInN=1,rarityTier="Common",arrivalTier="Basic",arrivalProbability=1,arrivalPercent=100,
		tutorialDealIndex=s.tutorialDealIndex or 0,tutorialBeat=s.deal and s.deal.beat,diagnosis=s.deal and s.deal.diagnosis,
		manualRepairCurrent=s.parts and ((s.parts.Engine and 1 or 0)+(s.parts.Wheels and 1 or 0)) or 0,manualRepairTotal=s.deal and 2 or 3,
		onLot=model:GetAttribute("Arriving")~=true,repairAutomated=not s.deal and s.record.data.step>=40,
		listingTransport=model:GetAttribute("ListingTransport")}
end
local function buyPayload(s,note)
	local value,restored=valueOf(s)
	return {visible=true,slot="working",slotIndex=1,workingIndex=1,tradeId=s.tradeId,channel="world",ask=s.ask,
		carName=Config.displayName(s.templateId),sellerName="Seller",affordable=s.hooks.getCash()>=s.ask,
		note=note,haggleUsed=s.haggleUsed==true,value=value,currentValue=value,valueAfterRepairs=restored,
		rarityOneInN=1,rarityTier="Common",tutorialDealIndex=s.tutorialDealIndex,tutorialBeat=s.deal and s.deal.beat,diagnosis=s.deal and s.deal.diagnosis}
end
function Bridge.close(record)
	local id=record.legacyTradeId
	if id then
		send(record,"BuyUpdate",{visible=false,slot="working",workingIndex=1,slotIndex=1,tradeId=id})
		send(record,"OfferUpdate",{visible=false,slot="display",slotIndex=1,tradeId=id})
	end
	record.legacyBuyOpen=false;record.legacyOfferOpen=false;record.legacyTradeId=nil
end
function Bridge.openBuy(record,player)
	if not Operations.canAct(record,player,"Buy") then return false end
	local s=Operations.getRuntime(record)
	record.legacyTradeId=s.tradeId;record.legacyBuyOpen=true
	send(record,"BuyUpdate",buyPayload(s))
	return true
end
function Bridge.showOffer(record,note)
	local s=Operations.getRuntime(record)
	if not s or s.expectedAction~="Sell" or s.acknowledged then return end
	local value,restored,base=valueOf(s)
	record.legacyTradeId=s.tradeId;record.legacyOfferOpen=true
	send(record,"OfferUpdate",{visible=true,slot="display",slotIndex=1,tradeId=s.tradeId,
		carName=Config.displayName(s.templateId),buyerName="Buyer",amount=s.saleOffer,currentOffer=s.saleOffer,
		value=restored,listedPrice=restored,calculatedValue=value,baseValue=base,partsValue=value-base,
		purchaseCost=s.deposit or 0,cost=s.deposit or 0,finalProfit=s.saleOffer-(s.deposit or 0),
		haggleUsed=s.saleHaggleUsed==true,note=note,tutorialDealIndex=s.tutorialDealIndex,tutorialBeat=s.deal and s.deal.beat,
		rarityOneInN=1,rarityTier="Common",breakdown={base=base,parts=value-base,signPct=0,servicePct=0,wealthPct=0,rarityPct=0,askMorePct=0}})
end
function Bridge.publish(record)
	if not record.owner or not record.data then return end
	local player=record.owner
	local nextEntry=Catalog.Next(record.data.step)
	record.folder:SetAttribute("NextPadTitle",nextEntry and nextEntry.title or "Dealership complete")
	record.folder:SetAttribute("NextPadCost",nextEntry and nextEntry.cost or nil)
	record.folder:SetAttribute("NextPadCategory",nextEntry and nextEntry.benefit or "")
	player:SetAttribute("PurchasedPads",record.data.step)
	player:SetAttribute("Luck",player:GetAttribute("Luck") or 1)
	player:SetAttribute("LuckLabel",player:GetAttribute("LuckLabel") or "NORMAL")
	local s=Operations.getRuntime(record)
	if s and s.car and s.car.Parent then
		s.car:SetAttribute("State",s.tradeState or "None")
		s.car:SetAttribute("TutorialDealIndex",s.tutorialDealIndex or 0)
		s.car:SetAttribute("IncomingSellerQueue",false)
		for _,rig in {s.seller,s.buyer} do if rig then rig:SetAttribute("TutorialDealIndex",s.tutorialDealIndex or 0) end end
		local current,_,base=valueOf(s)
		local stamp=(s.tradeState or "")..":"..current
		if s.billboardStamp~=stamp then
			s.billboardStamp=stamp
			if s.tradeState=="Sold" then CarVisuals.setSoldBillboard(s.car,Config.displayName(s.templateId),s.saleOffer or current)
			else CarVisuals.setValueBillboard(s.car,Config.displayName(s.templateId),current,current-base,s.accepted==true) end
		end
	end
	local working,display=slot(s,"working"),slot(s,"display")
	local data={version=5,workings={working},working=working,workingCapacity=1,hasFreeWorking=working.state=="None",
		displays={display},display=display,displayCapacity=1,hasFreeDisplay=display.state=="None",processings={},processingCapacity=1,hasFreeProcessing=true,
		hasListing=record.data.step>=5,phoneTrade=true,listingAutomated=record.data.step>=6,transportAutomated=record.data.step>=6,
		buyerAutomated=record.data.step>=33,displaySaleAutomated=record.data.step>=33,automated=record.data.step>=6,
		bayChapter=record.data.step>=35,hasLift=record.data.step>=79,bayMechanic=record.data.step>=40,displayOccupied=display.state~="None"}
	for key,value in working do if data[key]==nil then data[key]=value end end
	send(record,"CarState",data)
	-- The original QueueUpdate client requests CarState in response. Only emit a
	-- changed queue, otherwise a state request would create a feedback loop.
	local queueCount=s and s.expectedAction=="Buy" and 1 or 0
	if record.legacyQueueCount~=queueCount then
		record.legacyQueueCount=queueCount
		send(record,"QueueUpdate",{count=queueCount,capacity=1})
	end
	if s and s.expectedAction=="Sell" and not s.acknowledged and (s.deal or record.data.step<33) then
		if not record.legacyOfferOpen or record.legacyTradeId~=s.tradeId then Bridge.showOffer(record) end
	elseif record.legacyOfferOpen then
		send(record,"OfferUpdate",{visible=false,slot="display",slotIndex=1,tradeId=record.legacyTradeId});record.legacyOfferOpen=false
	end
	if record.legacyBuyOpen and (not s or s.expectedAction~="Buy" or s.acknowledged) then
		send(record,"BuyUpdate",{visible=false,slot="working",slotIndex=1,workingIndex=1,tradeId=record.legacyTradeId});record.legacyBuyOpen=false
	end
end
local function runtime(player,tradeId)
	local record=Service and Service.getForPlayer(player)
	local s=record and Operations.getRuntime(record)
	if not s or record.owner~=player or type(tradeId)~="string" or tradeId~=s.tradeId then return nil,nil end
	return record,s
end
function Bridge.buyAction(player,action,tradeId,index)
	local record,s=runtime(player,tradeId)
	if not record or index~=1 or not record.legacyBuyOpen or not Operations.canAct(record,player,"Buy") then return false end
	if action=="haggle" then
		if s.haggleUsed then return false end
		s.haggleUsed=true
		if not s.deal then s.ask=math.max(0,math.floor(s.ask*.9)) end
		send(record,"BuyUpdate",buyPayload(s,s.deal and "Rusty is yours for $25. Let's get him running." or "All right, that's my best price."))
		return true
	elseif action=="refuse" then
		local ok=Operations.reject(record,player,"Buy")
		if ok then Bridge.close(record) end
		return ok
	elseif action=="buy" then
		if s.hooks.getCash()<s.ask then
			send(record,"InsufficientFunds",{reason="funds",needed=s.ask-s.hooks.getCash(),title="Buy car"});return false
		end
		local ok=Operations.act(record,player,"Buy")
		if ok then send(record,"BuyUpdate",{visible=false,slot="working",workingIndex=1,slotIndex=1,tradeId=s.tradeId});record.legacyBuyOpen=false end
		return ok
	end
	return false
end
function Bridge.offerAction(player,action,tradeId)
	local record,s=runtime(player,tradeId)
	if not record or not Operations.canAct(record,player,"Sell",true) then return false end
	if action=="askmore" then
		if s.saleHaggleUsed then return false end
		s.saleHaggleUsed=true
		if not s.deal then s.saleOffer=math.floor(s.saleOffer*1.05) end
		Bridge.showOffer(record,s.deal and "One thousand. That's a fair price for Rusty." or "I'll add a little more. We have a deal?")
		return true
	elseif action=="refuse" then
		local ok=Operations.reject(record,player,"Sell",true)
		if ok then Bridge.close(record) end
		return ok
	elseif action=="accept" then
		local ok=Operations.act(record,player,"Sell",true)
		if ok then send(record,"OfferUpdate",{visible=false,slot="display",slotIndex=1,tradeId=s.tradeId});record.legacyOfferOpen=false end
		return ok
	end
	return false
end
function Bridge.onEvent(record,name,payload)
	local s=Operations.getRuntime(record)
	if (name=="CarBought" or name=="CarSold") and s and s.car then
		send(record,"CashPopup",{amount=(payload.paid or 0)*(name=="CarBought" and -1 or 1),position=s.car:GetPivot().Position})
	end
	if name=="CarSold" then
		send(record,"ProfitCard",{tradeId=payload.tradeId,carName=payload.carName,cost=payload.cost,paid=payload.paid,cashPayout=payload.paid,
			profit=payload.profit,serviceCost=0,totalInvestment=payload.cost,slotIndex=1,tutorialDealIndex=payload.tutorialDealIndex})
	elseif name=="PartFixed" and s and s.car then
		send(record,"RepairVFX",{model=s.car,position=s.car:GetPivot().Position,partId=payload.partId,tradeId=s.tradeId,workingIndex=1})
	end
	Bridge.publish(record)
end
function Bridge.init(service)
	if initialized then return end
	initialized=true;Service=service
	for _,name in {"BuyPad","TycoonAssigned","StateUpdate","RequestState","ProgressionState","RequestProgressionState"} do ensure(name) end
	Remotes.BuyAction.OnServerEvent:Connect(Bridge.buyAction)
	Remotes.OfferAction.OnServerEvent:Connect(Bridge.offerAction)
	local requested={}
	Remotes.RequestCarState.OnServerEvent:Connect(function(player)
		if requested[player] and os.clock()-requested[player]<.25 then return end
		requested[player]=os.clock()
		local record=Service.getForPlayer(player);if record then Bridge.publish(record) end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player) requested[player]=nil end)
	ensure("BuyPad").OnServerEvent:Connect(function(player)
		local record=Service.getForPlayer(player);local entry=record and record.data and Catalog.Next(record.data.step)
		if entry then Service.purchase(player,{purchaseId=entry.id}) end
	end)
end
return Bridge
