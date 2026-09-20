local Theme = {}

Theme.Colors = table.freeze({
	Ink = Color3.fromRGB(30, 39, 42),
	Panel = Color3.fromRGB(244, 241, 227),
	SoftPanel = Color3.fromRGB(224, 229, 219),
	Metal = Color3.fromRGB(106, 129, 126),
	Edge = Color3.fromRGB(30, 39, 42),
	Paper = Color3.fromRGB(244, 241, 227),
	PaperDark = Color3.fromRGB(30, 39, 42),
	Cream = Color3.fromRGB(30, 39, 42),
	White = Color3.fromRGB(30, 39, 42),
	Muted = Color3.fromRGB(80, 101, 99),
	Yellow = Color3.fromRGB(242, 197, 83),
	Green = Color3.fromRGB(98, 192, 113),
	Red = Color3.fromRGB(180, 60, 49),
	Blue = Color3.fromRGB(120, 185, 199),
	Purple = Color3.fromRGB(170, 83, 244),
	Orange = Color3.fromRGB(169, 77, 39),
})

Theme.Metrics = table.freeze({
	PanelRadius = 14,
	ButtonRadius = 11,
	Stroke = 1.25,
	AccentStroke = 1.75,
	TouchHeight = 60,
	ScreenMargin = 18,
	PromptWidth = 270,
	PromptHeight = 70,
})

Theme.Motion = table.freeze({
	PressIn = 0.07,
	PressOut = 0.14,
	Enter = 0.20,
	Exit = 0.16,
	Major = 0.36,
	PressedScale = 0.97,
})

Theme.Fonts = table.freeze({
	Display = Enum.Font.GothamBlack,
	Strong = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
})

Theme.FocusPriority = table.freeze({
	HUD = 10,
	Notice = 20,
	Workshop = 30,
	Phone = 40,
	Negotiation = 50,
	Confirm = 60,
	Cinematic = 70,
})

return table.freeze(Theme)


