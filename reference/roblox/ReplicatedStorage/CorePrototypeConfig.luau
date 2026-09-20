local Config = {}

Config.Stages = {
	{ title = "OPEN THE LOT", objective = "Open the lot, then set up a place to meet sellers" },
	{ title = "FIRST LEAD", objective = "Talk to the seller and buy the rusty sedan" },
	{ title = "RESTORE", objective = "Build and equip your repair bay, then restore the car" },
	{ title = "LIST & SELL", objective = "Build your sales area, list the car and meet the buyer" },
	{ title = "WORKSHOP", objective = "Build a functional workshop one piece at a time" },
	{ title = "FIRST HIRE", objective = "Hire a mechanic at the workshop" },
	{ title = "SECOND DEAL", objective = "Meet the smarter seller who has arrived at your lot" },
	{ title = "OPERATIONS", objective = "Set up buying and selling before claiming your car" },
	{ title = "YOUR CAR", objective = "Choose a car style and make it yours" },
	{ title = "FUTURE LEAD", objective = "An unusual outside opportunity is waiting on your phone" },
}

Config.StartingCash = 7000
Config.FirstCar = {
	name = "RUSTY SEDAN",
	rarity = "COMMON",
	state = "ROUGH",
	condition = 35,
	ask = 900,
	estimate = 2300,
}
Config.Repairs = {
	Body = { cost = 120, value = 300, condition = 17 },
	Wheels = { cost = 160, value = 400, condition = 20 },
	Engine = { cost = 220, value = 600, condition = 28 },
}
Config.FirstBuyer = {
	name = "MARCUS",
	greed = 0.61,
	offer = 2350,
	counter = 2400,
}
Config.SecondSeller = {
	name = "MAYA",
	greed = 0.78,
	car = "DESERT COUPE",
	rarity = "UNCOMMON",
	state = "FAIR",
	condition = 58,
	ask = 1400,
	counter = 1200,
	estimate = 2850,
}
Config.RareSeller = {
	name = "ELIAS",
	greed = 0.66,
	car = "1972 PHOENIX GT",
	rarity = "RARE",
	state = "SURVIVOR",
	condition = 62,
	ask = 4800,
	counter = 4650,
	estimate = 7200,
}
Config.DealTableCost = 100
Config.WorkshopCosts = {
	Foundation = 250,
	Approach = 150,
	ServiceSlab = 300,
	Lift = 300,
}
Config.WorkshopCost = 1000
Config.MechanicCost = 500
Config.OperationsCosts = {
	AppraisalPosition = 250,
	CarBuyer = 900,
	SalesPosition = 350,
	SalesRep = 1000,
}
-- The first automated route repays the player's staffing investment and
-- guarantees enough buying power for Elias's full rare-car ask.
Config.AutomationProfit = 2500

Config.Colors = {
	Ink = Color3.fromRGB(30, 39, 42),
	Panel = Color3.fromRGB(244, 241, 227),
	SoftPanel = Color3.fromRGB(224, 229, 219),
	Yellow = Color3.fromRGB(242, 197, 83),
	Green = Color3.fromRGB(98, 192, 113),
	Red = Color3.fromRGB(180, 60, 49),
	Orange = Color3.fromRGB(169, 77, 39),
	White = Color3.fromRGB(30, 39, 42),
	Muted = Color3.fromRGB(80, 101, 99),
	Blue = Color3.fromRGB(120, 185, 199),
}

return Config


