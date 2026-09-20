--!strict

local TrackActivityConfig = {}

TrackActivityConfig.LAPS = 1
TrackActivityConfig.COOLDOWN_SECONDS = 10 * 60
TrackActivityConfig.PICKUP_CHECK_INTERVAL = 0.08
TrackActivityConfig.LATERAL_OFFSET_STUDS = 5
TrackActivityConfig.VISIBLE_PICKUPS = 3
TrackActivityConfig.MINIMUM_PICKUPS_TO_FINISH = 12
TrackActivityConfig.FIRST_PICKUP_DISTANCE_STUDS = 40
TrackActivityConfig.ROUTE_LOOKAHEAD_POINTS = 5
TrackActivityConfig.CAR_BOUND_EXPANSION_STUDS = 7
TrackActivityConfig.START_GATE_EXPANSION_STUDS = 7

TrackActivityConfig.BASE_REWARD = 125
TrackActivityConfig.BASE_CAR_PRICE = 120000
TrackActivityConfig.MAX_CAR_FACTOR = 10
TrackActivityConfig.MAX_INCOME_FACTOR = 3
TrackActivityConfig.REWARD_ROUNDING = 25

return table.freeze(TrackActivityConfig)
