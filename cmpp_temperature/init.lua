temperature = require("ds18b20")
led         = require("led")
ssid = 'CMPP_HUAWEI_4G'
passwd = 'CMPP8888@'
local msg   = ''
local tem   = ''
local time  = ''
local set   = ''

------------------
--读温度配置
------------------
local MixTem = 25
if file.open("device.config", "r") then
  MixTem = tonumber(file.readline())
  print('MixTem : ' .. MixTem)
  file.close()
end




--------------------
--OLED
-------------------
sda = 5 -- SDA Pin
scl = 4 -- SCL Pin

function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3C
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
     --disp:setRot180()           -- Rotate Display if needed
end

function print_OLED(str1,str2,time)
   set = 'set : ' .. MixTem
   disp:firstPage()
   repeat
     disp:drawFrame(2,2,126,62)
     disp:drawStr(5, 10, str1)
     disp:drawStr(5, 20, str2)
     disp:drawStr(5, 30, time)
     disp:drawStr(5, 40, set)
   until disp:nextPage() == false
   
end


------------
--继电器
-------------
IO_HOT = 3
gpio.mode(IO_HOT, gpio.OPENDRAIN)
gpio.write(IO_HOT, gpio.HIGH)


----------------
-- init.lua
---------------




------------------------------------
-- ESP-01 GPIO Mapping
-- sensor MODULE

gpio1 = 1
IO_BTN_CFG = 10



function onBtnEvent()
    print('up~')
end


temperature.setup(gpio1)
addrs = temperature.addrs()
if (addrs ~= nil) then
  print("Total DS18B20 sensors: "..table.getn(addrs))
end



-----------------------------------------
--wifi mqtt 
-----------------------------------------
print('Setting up WIFI...')
wifi.setmode(wifi.STATION)
wifi.sta.config(ssid, passwd)
-- wifi.sta.config('vivo X7', '88888888')
wifi.sta.connect()
wifi.sta.autoconnect(1)
init_OLED(sda,scl)

local  mqtt = mqtt.Client("4929385", 120, "82265", "zMaR1lCBXzzKis5W6=Gq3Gpwnl4=")
-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client don't send keepalive packet
mqtt:lwt("/lwt", "offline", 0, 0)

-- mqtt:on("connect", function(client) print ("connected 2") end)
mqtt:on("offline", function(client) 
    print ("offline") 
    msg = 'offline'
    led.blinking({300, 300})
    mqtt:connect("183.230.40.39", 6002, 0, onConnect, onFailed)
    print('start mqtt connect')
  end)

-- on publish message receive event
mqtt:on("message", function(client, topic, data) 
  print(topic .. ":" ) 
  if data ~= nil then
    MixTem = tonumber(data)
    print('MixTem: ' .. MixTem)
    if file.open("device.config", "w") then
      file.writeline(data)
      file.close()
    end
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
          tem   = '' .. value .. ' C'
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
  msg = 'connected'
  led.blinking({300, 3000})
  sendData()
end

local onFailed = function (client, reason)
  -- body
  print("failed reason: "..reason)
  msg = 'failed reason ' .. reason
  led.blinking({300, 300})
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

        sntp.sync("202.120.2.101", 
            function()
                print("sync succeeded")
            end,
            function(index)
                print("failed : "..index)
            end
        )
        mqtt:connect("183.230.40.39", 6002, 0, onConnect, onFailed)
        print('start mqtt connect')
        tmr.stop(1)
        startDaemon()
    end
end)

tmr.alarm(4,5000,tmr.ALARM_AUTO,function ()
        -- body
       -- print('msg :' .. msg)
       tm = rtctime.epoch2cal(rtctime.get())
       time =  (tm["hour"] +8) .. ':' .. tm["min"] .. ':' .. tm["sec"] .. '  ' .. tm["year"] .. '/' .. tm["mon"] .. '/' .. tm["day"]
       local value = temperature.read()
       if(value ~= nil)then
        tem   = '' .. value .. ' C'
          if(value<MixTem)then
          -- print('add hot')
          gpio.write(IO_HOT, gpio.LOW)
         else
          -- print('stop hot')
          gpio.write(IO_HOT, gpio.HIGH)
         end
       end
       print_OLED(msg,tem,time)
      end)
-- gpio.mode(IO_BTN_CFG, gpio.INT,gpio.PULLUP)
-- gpio.trig(IO_BTN_CFG, 'low', onBtnEvent)

