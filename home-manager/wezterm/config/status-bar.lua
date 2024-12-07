local wezterm = require "wezterm"
local battery_status = require "battery-status"
local config_parser = require "parse-config"
local system_status = require "system-status.system-status"
local util = require "util.util"
local wifi_status = require "wifi-status"

local config = config_parser.get_config()
local system_status_config = config["status_bar"]["system_status"]
local wifi_status_config = config["status_bar"]["wifi_status"]

local status_bar = {}

function status_bar.update_status_bar(cwd)
    -- update the data files as needed
    wifi_status.update_json(config)

    local cells = {}

    ----------------------------------------------------
    -- battery
    ----------------------------------------------------
    if config["status_bar"]["toggles"]["show_battery"] then
        if #wezterm.battery_info() > 0 then
            for _, b in ipairs(wezterm.battery_info()) do
                icon, battery_percent = battery_status.get_battery_status(b)
                bat = icon .. " " .. battery_percent
                table.insert(cells, util.pad_string(1, 1, bat))
            end
        end
    end

    ----------------------------------------------------
    -- wifi status
    ----------------------------------------------------
    if wifi_status_config["enabled"] then
        wifi_data = wifi_status.get_wifi_status(config)
        if wifi_data ~= nil then
            for _, interface_data in ipairs(wifi_data) do
                table.insert(cells, interface_data)
            end
        end
    end

    ----------------------------------------------------
    -- system status
    ----------------------------------------------------
    if system_status_config["enabled"] then
        if system_status_config["toggles"]["show_load_averages"] then
            load_averages = system_status.get_load_averages(config)
            if load_averages ~= nil then
                table.insert(cells, load_averages)
            end
        end
        if system_status_config["toggles"]["show_uptime"] then
            system_uptime = system_status.get_system_uptime(config)
            if system_uptime ~= nil then
                table.insert(cells, system_uptime)
            end
        end

        if system_status_config["toggles"]["show_cpu_usage"] then
            cpu_usage = system_status.get_cpu_usage(config)
            if cpu_usage ~= nil then
                table.insert(cells, cpu_usage)
            end
        end

        if system_status_config["toggles"]["show_memory_usage"] then
            memory_usage = system_status.get_memory_usage(config)
            if memory_usage ~= nil then
                table.insert(cells, memory_usage)
            end
        end

        if system_status_config["toggles"]["show_disk_usage"] then
            disk_usage = system_status.get_disk_usage(config)
            if disk_usage ~= nil then
                for _, disk_usage_data in ipairs(disk_usage) do
                    table.insert(cells, disk_usage_data)
                end
            end
        end

        if system_status_config["toggles"]["show_network_throughput"] then
            network_throughput = system_status.get_network_throughput(config)
            if network_throughput ~= nil then
                table.insert(cells, network_throughput)
            end
        end
    end

    ----------------------------------------------------
    -- clock
    ----------------------------------------------------
    if config["status_bar"]["toggles"]["show_clock"] then
        local date = wezterm.strftime "%a %b %-d %H:%M"
        table.insert(cells, util.pad_string(2, 2, date))
    end

    return cells
end

return status_bar