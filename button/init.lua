buttonpin = 5
gpio.mode(buttonpin, gpio.OUTPUT)
gpio.write(buttonpin,gpio.HIGH)
-- gpio.mode(buttonpin, gpio.INPUT)
local i = 0
local state = 0
tmr.alarm(0,1000,1,function()
	local j = gpio.read(buttonpin)
	print(j)
	if(j == 0)then
		state = state + 1
	end
	i = i + 1
	if(i>3)then
		if(state > 3)then
			onWifiAP()
		else
			onStart()
		end
		tmr.stop(0)
	end
end)

function onStart( ... )
	-- body
	print('onStart')
end

function onWifiAP( ... )
	-- body
	print('onWifiAP')
end