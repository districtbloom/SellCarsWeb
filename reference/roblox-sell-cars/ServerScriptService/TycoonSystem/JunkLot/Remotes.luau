--!strict

-- One place that guarantees the junk lot remotes exist, so module load order does not
-- decide who creates what.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("TycoonRemotes")
if folder == nil then
	local created = Instance.new("Folder")
	created.Name = "TycoonRemotes"
	created.Parent = ReplicatedStorage
	folder = created
end

local function ensure(name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing ~= nil and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local Remotes = {
	-- client to server
	RepairPart = ensure("RepairPart"),
	ListCar = ensure("ListCar"), -- legacy no-op; listing is completed only by the P1 server check
	ListingDriveInput = ensure("ListingDriveInput"),
	ParkAssist = ensure("ParkAssist"),
	ReturnHome = ensure("ReturnHome"),
	StaffInspectRequest = ensure("StaffInspectRequest"),
	OfferAction = ensure("OfferAction"),
	BuyAction = ensure("BuyAction"),
	RequestCarState = ensure("RequestCarState"),
	-- server to client
	OfferUpdate = ensure("OfferUpdate"),
	BuyUpdate = ensure("BuyUpdate"),
	ProfitCard = ensure("ProfitCard"),
	CarState = ensure("CarState"),
	QueueUpdate = ensure("QueueUpdate"),
	RepairVFX = ensure("RepairVFX"),
	InsufficientFunds = ensure("InsufficientFunds"),
	PadPurchased = ensure("PadPurchased"),
	CarIndexState = ensure("CarIndexState"),
	RequestCarIndex = ensure("RequestCarIndex"),
	-- Money that lands or leaves shows up over the car it belongs to.
	CashPopup = ensure("CashPopup"),
	ListingNotice = ensure("ListingNotice"),
	SellerArrivalNotice = ensure("SellerArrivalNotice"),
	EconomyRateUpdate = ensure("EconomyRateUpdate"),
	StaffInspectionState = ensure("StaffInspectionState"),
}

return Remotes

