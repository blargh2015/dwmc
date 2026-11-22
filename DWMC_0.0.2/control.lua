-- Dude Where's My Car - Main Control Script
-- Tracks the player's last vehicle and shows an arrow + horn alert

local car_alert_icon = {type = "item", name = "car"}
local car_alert_message = "Your car!"

local function remove_car_alert(player)
  player.remove_alert{
    type = defines.alert_type.custom,
    icon = car_alert_icon,
    message = car_alert_message
  }
end

local function clear_car_marker(player, vehicle_data)
  if vehicle_data.pin and vehicle_data.pin.valid then
    vehicle_data.pin.destroy()
  end
  vehicle_data.pin = nil

  -- Clean up custom alerts left by earlier 0.0.2 test builds.
  if vehicle_data.alert_active then
    remove_car_alert(player)
    vehicle_data.alert_active = false
  end
end

local function on_player_driving_changed_state(event)
  local player = game.players[event.player_index]
  if not player then return end
  log("DWMC: Driving state changed for player " .. player.name .. ", player.vehicle=" .. tostring(player.vehicle))
  
  if player.vehicle then
    -- Player is now IN a vehicle, clear alert and arrow
    log("DWMC: Player " .. player.name .. " entered vehicle: " .. player.vehicle.name)
    storage.currently_in_vehicle = storage.currently_in_vehicle or {}
    storage.currently_in_vehicle[player.index] = player.vehicle
    
    -- Clear our previous vehicle marker.
    if storage.last_vehicle[player.index] then
      clear_car_marker(player, storage.last_vehicle[player.index])
    end
    -- Clear the GUI arrow left by previous test builds.
    player.set_gui_arrow{type = "nowhere"}
    storage.last_vehicle[player.index] = nil
  else
    -- Player just EXITED a vehicle
    log("DWMC: Player " .. player.name .. " exited vehicle")
    storage.currently_in_vehicle = storage.currently_in_vehicle or {}
    local exited_vehicle = storage.currently_in_vehicle[player.index]
    log("DWMC: Previously tracked vehicle: " .. tostring(exited_vehicle))
    
    if exited_vehicle then
      log("DWMC: Vehicle valid: " .. tostring(exited_vehicle.valid))
    end
    
    -- Only set alert if vehicle still exists (not destroyed)
    if exited_vehicle and exited_vehicle.valid then
      log("DWMC: Saving exited vehicle as last_vehicle: " .. exited_vehicle.name)
      storage.last_vehicle[player.index] = {
        entity = exited_vehicle,
        surface_name = exited_vehicle.surface.name,
        alert_active = false,
        pin = nil
      }
      player.set_gui_arrow{type = "nowhere"}
      log("DWMC: Vehicle saved, alert will show when > configured distance")
    else
      log("DWMC: Exited vehicle not found or was destroyed")
    end
    storage.currently_in_vehicle[player.index] = nil
  end
end

local function on_tick()
  if not storage.last_vehicle then storage.last_vehicle = {} end
  
  for player_index, player in pairs(game.players) do
    if not player.connected then goto continue end
    
    local vehicle_data = storage.last_vehicle[player_index]
    
    -- Check if vehicle is still valid
    if vehicle_data and not vehicle_data.entity.valid then
      log("DWMC: Vehicle no longer valid for player " .. player.name)
      clear_car_marker(player, vehicle_data)
      player.set_gui_arrow{type = "nowhere"}
      storage.last_vehicle[player_index] = nil
      goto continue
    end
    
    -- Check distance for alert display
    if vehicle_data and vehicle_data.entity and vehicle_data.entity.valid then
      if player.character then
        if player.surface.name == vehicle_data.surface_name then
          -- Existing saves may have the tutorial-style arrow from an earlier build.
          if not vehicle_data.gui_arrow_cleared then
            player.set_gui_arrow{type = "nowhere"}
            vehicle_data.gui_arrow_cleared = true
          end
          local distance = math.sqrt(
            (player.character.position.x - vehicle_data.entity.position.x) ^ 2 +
            (player.character.position.y - vehicle_data.entity.position.y) ^ 2
          )
          
          local alert_distance = player.mod_settings["dwmc-alert-distance"].value

          -- Remove old-style alerts if the save came from a previous test build.
          if vehicle_data.alert_active then
            remove_car_alert(player)
            vehicle_data.alert_active = false
          end
          
          if distance > alert_distance then
            -- An entity pin tracks moving vehicles and uses the vanilla
            -- on-screen marker / off-screen edge-arrow behavior.
            if not vehicle_data.pin or not vehicle_data.pin.valid then
              vehicle_data.pin = player.add_pin{
                entity = vehicle_data.entity,
                label = "Your car",
                always_visible = true
              }
            end

            if not vehicle_data.horn_alerted then
              player.print("Your car is " .. math.floor(distance) .. " tiles away!")
              pcall(function()
                player.surface.play_sound{
                  path = "dwmc-car-horn",
                  position = vehicle_data.entity.position,
                  volume_modifier = 1.0
                }
              end)
              vehicle_data.horn_alerted = true
            end
          else
            -- Inside the threshold, show neither pin nor edge arrow.
            clear_car_marker(player, vehicle_data)
          end
        else
          -- A vehicle on another surface should not have an active marker.
          clear_car_marker(player, vehicle_data)
        end
      end
    end
    
    ::continue::
  end
end

local function init_storage()
  storage.last_vehicle = storage.last_vehicle or {}
  storage.currently_in_vehicle = storage.currently_in_vehicle or {}
  log("DWMC: Storage initialized")
end

local function on_init()
  init_storage()
  log("DWMC: on_init called")
end

-- Register lifecycle events
script.on_init(on_init)
script.on_configuration_changed(init_storage)

-- Register game events at module level (not inside on_init/on_load)
script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
script.on_nth_tick(30, on_tick)
