-- init.lua
temperature = require("ds18b20")
---------------------------------------
---LED MODULE

IO_BLINK = 4
TMR_BLINK = 5
gpio.mode(IO_BLINK, gpio.OUTPUT)

blink = nil
tmr.register(TMR_BLINK, 100, tmr.ALARM_AUTO, function()
    gpio.write(IO_BLINK, blink.i % 2)
    tmr.interval(TMR_BLINK, blink[blink.i + 1])
    blink.i = (blink.i + 1) % #blink
end)

function blinking(param)
    if type(param) == 'table' then
        blink = param
        blink.i = 0
        tmr.interval(TMR_BLINK, 1)
        running, _ = tmr.state(TMR_BLINK)
        if running ~= true then
            tmr.start(TMR_BLINK)
        end
    else
        tmr.stop(TMR_BLINK)
        gpio.write(IO_BLINK, param or gpio.LOW)
    end
end

-- blinking({300, 300}) -- 循环闪烁：亮300ms，灭300ms
-- blinking({100, 100 , 100, 500}) -- 循环闪烁：亮100ms，灭100ms，亮100ms，灭500ms

-- blinking() -- 常亮
-- blinking(gpio.LOW) -- 常亮
-- blinking(gpio.HIGH) -- 常灭

------------------------------------
-- ESP-01 GPIO Mapping
-- sensor MODULE

gpio2 = 4
temperature.setup(gpio2)
addrs = temperature.addrs()
if (addrs ~= nil) then
  print("Total DS18B20 sensors: "..table.getn(addrs))
end


-----------------------------------------



print('Setting up WIFI...')
wifi.setmode(wifi.STATION)
wifi.sta.config('CMPP_HUAWEI_4G', 'CMPP8888@')
wifi.sta.connect()

local  mqtt = mqtt.Client("4929385", 900, "82265", "zMaR1lCBXzzKis5W6=Gq3Gpwnl4=")
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
  local i = 0 ;
  local value = 0;
  tmr.alarm(3, 1000, tmr.ALARM_AUTO, function()
        if(i>2)then
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
          tmr.stop(3)
        else
          i = i +1
          value = temperature.read()
        end
    end)
end

local onConnect  = function (client)
	-- body
	print("connected ")
  blinking({300, 3000})
  sendData()
end

local onFailed = function (client, reason)
  -- body
  print("failed reason: "..reason)
  blinking({300, 300})
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
        mqtt:connect("183.230.40.39", 6002, 0, onConnect, onFailed)
        print('start mqtt connect')
        tmr.stop(1)
        startDaemon()
    end
end)
