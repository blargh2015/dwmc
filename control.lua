-- Dude Where's My Car - Main Control Script
-- Tracks the player's last vehicle and shows an arrow + horn alert

local function on_player_driving_changed_state(event)
  local player = game.players[event.player_index]
  log("DWMC: Driving state changed for player " .. player.name .. ", player.vehicle=" .. tostring(player.vehicle))
  
  if player.vehicle then
    -- Player is now IN a vehicle, clear alert and arrow
    log("DWMC: Player " .. player.name .. " entered vehicle: " .. player.vehicle.name)
    storage.currently_in_vehicle = storage.currently_in_vehicle or {}
    storage.currently_in_vehicle[player.index] = player.vehicle
    
    -- Clear any existing alert and arrow
    if storage.last_vehicle[player.index] and storage.last_vehicle[player.index].alert_id then
      player.remove_alert(storage.last_vehicle[player.index].alert_id)
    end
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
        alert_id = nil,
        alert_active = false,
        has_triggered_alert = false
      }
      log("DWMC: Vehicle saved, alert will show when > configured distance")
    else
      log("DWMC: Exited vehicle not found or was destroyed")
    end
    storage.currently_in_vehicle[player.index] = nil
  end
end

local function on_tick()
  if not storage.last_vehicle then storage.last_vehicle = {} end
  
  -- Only check every 30 ticks to reduce load
  if game.tick % 30 ~= 0 then return end
  
  for player_index, player in pairs(game.players) do
    if not player.connected then goto continue end
    
    local vehicle_data = storage.last_vehicle[player_index]
    
    -- Check if vehicle is still valid
    if vehicle_data and not vehicle_data.entity.valid then
      log("DWMC: Vehicle no longer valid for player " .. player.name)
      if vehicle_data.alert_id then
        player.remove_alert(vehicle_data.alert_id)
      end
      player.set_gui_arrow{type = "nowhere"}
      storage.last_vehicle[player_index] = nil
      goto continue
    end
    
    -- Check distance for alert display
    if vehicle_data and vehicle_data.entity and vehicle_data.entity.valid then
      if player.character then
        if player.surface.name == vehicle_data.surface_name then
          local distance = math.sqrt(
            (player.character.position.x - vehicle_data.entity.position.x) ^ 2 +
            (player.character.position.y - vehicle_data.entity.position.y) ^ 2
          )
          
          local alert_distance = player.mod_settings["dwmc-alert-distance"].value
          
          if distance > alert_distance then
            -- Player is far from car, show custom alert
            if not storage.last_vehicle[player_index].alert_active then
              log("DWMC: Creating alert for player " .. player.name .. " at distance " .. math.floor(distance))
              local alert_id = player.add_custom_alert(vehicle_data.entity, {type = "item", name = "car"}, "Your car!", true)
              storage.last_vehicle[player_index].alert_id = alert_id
              storage.last_vehicle[player_index].alert_active = true
              storage.last_vehicle[player_index].has_triggered_alert = true
              
              -- Play horn sound once
              if not storage.last_vehicle[player_index].horn_alerted then
                player.print("Your car is " .. math.floor(distance) .. " tiles away!")
                pcall(function()
                  player.surface.play_sound{
                    path = "dwmc-car-horn",
                    position = vehicle_data.entity.position,
                    volume_modifier = 1.0
                  }
                end)
                storage.last_vehicle[player_index].horn_alerted = true
              end
            end
          else
            -- Player is close to car
            if storage.last_vehicle[player_index].alert_active then
              log("DWMC: Removing alert for player " .. player.name)
              if storage.last_vehicle[player_index].alert_id then
                player.remove_alert(storage.last_vehicle[player_index].alert_id)
              end
              storage.last_vehicle[player_index].alert_active = false
            end
            
            -- Show GUI arrow if alert has been triggered before
            if storage.last_vehicle[player_index].has_triggered_alert then
              player.set_gui_arrow{type = "position", position = vehicle_data.entity.position}
            else
              player.set_gui_arrow{type = "nowhere"}
            end
          end
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

local function on_load()
  init_storage()
  log("DWMC: on_load called")
end

-- Register lifecycle events
script.on_init(on_init)
script.on_load(on_load)

-- Register game events at module level (not inside on_init/on_load)
script.on_event(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
script.on_event(defines.events.on_tick, on_tick)