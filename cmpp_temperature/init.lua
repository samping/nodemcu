-- init.lua
temperature = require("ds18b20")
-- ESP-01 GPIO Mapping
gpio2 = 4
temperature.setup(gpio2)
addrs = temperature.addrs()
if (addrs ~= nil) then
  print("Total DS18B20 sensors: "..table.getn(addrs))
end

print('Setting up WIFI...')
wifi.setmode(wifi.STATION)
wifi.sta.config('CMPP_HUAWEI_4G', 'CMPP8888@')
wifi.sta.connect()

local  mqtt = mqtt.Client("4929385", 120, "82265", "zMaR1lCBXzzKis5W6=Gq3Gpwnl4=")
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client don't send keepalive packet
mqtt:lwt("/lwt", "offline", 0, 0)

-- mqtt:on("connect", function(client) print ("connected 2") end)
mqtt:on("offline", function(client) print ("offline") end)

-- on publish message receive event
mqtt:on("message", function(client, topic, data) 
  print(topic .. ":" ) 
  if data ~= nil then
    print(data)
  end
end)


mqtt:subscribe("$creq",0, function(conn) print("subscribe success") end)

function sendData()
  -- body
  local value = temperature.read()
  value = temperature.read()
  local payload = '{"temperature":'.. value .. '}'
  local size  = string.len(payload)
  print(size)
  local prefix = string.char(0x03,0x00,size)
  local load = prefix .. payload
   -- Just read temperature
  print(payload)
  print(load)
   mqtt:publish('$dp', load, 0, 0, function(client)
   print("sent")
    end)
end

local onConnect  = function (client)
	-- body
	print("connected ")
  sendData()
end

function startDaemon()
  -- body
  tmr.alarm(2,1000*60*10,tmr.ALARM_AUTO,function ()
          -- body
          sendData()
        end)
end

tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()
    if wifi.sta.getip() == nil then
        print('Waiting for IP ...')
    else
        print('IP is ' .. wifi.sta.getip())
        mqtt:connect("183.230.40.39", 6002, 0, onConnect, 
                                     function(client, reason) print("failed reason: "..reason) end)
        print('start mqtt connect')
        tmr.stop(1)
        startDaemon()
    end
end)
