IO_BTN_CFG = 3

print('hsp')
local change = true
gpio.mode(IO_BTN_CFG, gpio.OPENDRAIN)
gpio.write(IO_BTN_CFG, gpio.LOW)

tmr.alarm(1,5000,tmr.ALARM_AUTO,function ()
        -- body
       print('in')
       if(change)then
       	gpio.write(IO_BTN_CFG, gpio.LOW)
       	change = false
       	print('high')
       else
       	gpio.write(IO_BTN_CFG, gpio.HIGH)
       	change = true
       	print('low')
       end
      end)