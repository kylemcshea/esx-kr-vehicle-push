ESX               = nil

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end
end)

-- This uses a qtarget dependency.
Citizen.CreateThread(function()
	exports.qtarget:Vehicle({
		options = {
			{
				event = "esx_vehicle_push:pushVehicle",
				icon = "fas fa-truck-loading",
				label = "Push Vehicle",
			},
		},
		distance = 1.8
	})	
end)

VehiclePush = {} 
VehiclePush.DamageNeeded = 100.0 -- 100.0 being broken and 1000.0 being fixed a lower value than 100.0 will break it
VehiclePush.MaxWidth = 5.0 -- Will complete soon
VehiclePush.MaxHeight = 5.0
VehiclePush.MaxLength = 5.0

local First = vector3(0.0, 0.0, 0.0)
local Second = vector3(5.0, 5.0, 5.0)

local Vehicle = {Coords = nil, Vehicle = nil, Dimension = nil, IsInFront = false, Distance = nil}

RegisterNetEvent('esx_vehicle_push:pushVehicle', function()
    -- Clears Vehicle data
    Vehicle.IsInFront = false
    Vehicle = {Coords = nil, Vehicle = nil, Dimension = nil, IsInFront = false, Distance = nil}

    -- Grabs vehicle data so it can send to the while loop for pushing vehicles 
    local ped = PlayerPedId()
    local closestVehicle, Distance = ESX.Game.GetClosestVehicle()
    local vehicleCoords = GetEntityCoords(closestVehicle)
    local dimension = GetModelDimensions(GetEntityModel(closestVehicle), First, Second)

    -- Use your notification system here. We use okok, you can use mythic or swt or whatever else to replace here.
    exports['okokNotify']:Alert("Vehicle Actions", "Use your LShift + E Muscle to push.", 5000, 'info')

    if Distance < 6.0  and not IsPedInAnyVehicle(ped, false) then
        Vehicle.Coords = vehicleCoords
        Vehicle.Dimensions = dimension
        Vehicle.Vehicle = closestVehicle
        Vehicle.Distance = Distance
        if GetDistanceBetweenCoords(GetEntityCoords(closestVehicle) + GetEntityForwardVector(closestVehicle), GetEntityCoords(ped), true) > GetDistanceBetweenCoords(GetEntityCoords(closestVehicle) + GetEntityForwardVector(closestVehicle) * -1, GetEntityCoords(ped), true) then
            Vehicle.IsInFront = false
			TriggerEvent('esx_vehicle_push:activelyPushingV', true)
        else
            Vehicle.IsInFront = true
			TriggerEvent('esx_vehicle_push:activelyPushingV', true)
        end
    end
end)

RegisterNetEvent('esx_vehicle_push:activelyPushingV', function(isPushingV)
	if isPushingV == nil then -- Stop the exploiters.
    -- Trigger a server event to remove them / ban them from the server.
		--TriggerServerEvent('dsrp_main:bahamaMamas', 'esx_vehicle_push:activelyPushingV')
		return
	end

	Citizen.CreateThread(function()
		local ped = PlayerPedId()
		while isPushingV do 
			Citizen.Wait(10)
			if Vehicle.Vehicle ~= nil then
				if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Vehicle.Coords) < 5 then
					-- LSHIFT = 21, E = 38
					if IsControlPressed(0, 21) and IsVehicleSeatFree(Vehicle.Vehicle, -1) and not IsEntityAttachedToEntity(ped, Vehicle.Vehicle) and IsControlJustPressed(0, 38)  and GetVehicleEngineHealth(Vehicle.Vehicle) <= VehiclePush.DamageNeeded then
						NetworkRequestControlOfEntity(Vehicle.Vehicle)
						local coords = GetEntityCoords(ped)
						if Vehicle.IsInFront then    
							AttachEntityToEntity(PlayerPedId(), Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y * -1 + 0.1 , Vehicle.Dimensions.z + 1.0, 0.0, 0.0, 180.0, 0.0, false, false, true, false, true)
						else
							AttachEntityToEntity(PlayerPedId(), Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y - 0.3, Vehicle.Dimensions.z  + 1.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, true)
						end
	
						ESX.Streaming.RequestAnimDict('missfinale_c2ig_11')
						TaskPlayAnim(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
						Citizen.Wait(200)
	
						local currentVehicle = Vehicle.Vehicle
						while true do
							Citizen.Wait(5)
							if IsDisabledControlPressed(0, 34) then -- A
								TaskVehicleTempAction(PlayerPedId(), currentVehicle, 11, 1000)
							end
	
							if IsDisabledControlPressed(0, 9) then -- D
								TaskVehicleTempAction(PlayerPedId(), currentVehicle, 10, 1000)
							end
	
							if Vehicle.IsInFront then
								SetVehicleForwardSpeed(currentVehicle, -1.0)
							else
								SetVehicleForwardSpeed(currentVehicle, 1.0)
							end
	
							if HasEntityCollidedWithAnything(currentVehicle) then
								SetVehicleOnGroundProperly(currentVehicle)
							end
	
							if not IsDisabledControlPressed(0, 38) then -- E
								DetachEntity(ped, false, false)
								StopAnimTask(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0)
								FreezeEntityPosition(ped, false)
								break
							end
						end
					end
				else
					isPushingV = false
					Vehicle.IsInFront = false
					Vehicle = {Coords = nil, Vehicle = nil, Dimension = nil, IsInFront = false, Distance = nil}
				end
			else
				isPushingV = false
				Citizen.Wait(3000)
			end
		end
	end)
end)


