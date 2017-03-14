-- init.lua
print('Setting up WIFI...')
wifi.setmode(wifi.STATION)
wifi.sta.config('CMPP_HUAWEI_4G', 'CMPP8888@')
wifi.sta.connect()

local  mqtt = mqtt.Client("4756548", 120, "81886", "TZGHtj2ywiOWy8nMAJVt=pg6Auw=")
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client don't send keepalive packet
mqtt:lwt("/lwt", "offline", 0, 0)

mqtt:on("connect", function(client) print ("connected 2") end)
mqtt:on("offline", function(client) print ("offline") end)

-- on publish message receive event
mqtt:on("message", function(client, topic, data) 
  print(topic .. ":" ) 
  if data ~= nil then
    print(data)
  end
end)


mqtt:subscribe("$creq",0, function(conn) print("subscribe success") end)

local onConnect  = function (client)
	-- body
	 print("connected 1")
	 local payload = string.char(0x03, 0x00, 0x0B,0x7B,0x22,0x74,0x65,0x73,0x74,0x22,0x3A,0x31,0x32,0x7D)
	 mqtt:publish('$dp', payload, 0, 0, function(client)
	 	print("sent")
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
    end
end)
