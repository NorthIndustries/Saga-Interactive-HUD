
defaultPOS = 1 --export: Your Default Target Location or Home Base. '::pos{0,2,24.1067,88.1581,-0.0886}'. make sure the POS has '' around it.
--if defaultPOS == 1 then
--    defaultPOS =   vec3(_construct.getWorldPosition())       --'::pos{0,2,24.4452,87.9785,-0.0010}'
--end
spaceCapableOverride = false --export: (Space Capable Ship Override) true/false -- (average ships do not need this) is your ship space capable with a gyro? Space capability is auto detected from rear facing engines. if you use a gyro to get to space, the auto detection may not work, so set this to true if the ship says your not space capable when using AP, when you really are.
hoverHeight = 10 --export: (Hover Height) 0-50 default hover height to goto when unlocking parking mode (G key)
throttleBurnProtection = true --export: (Auto Throttle Burn Protection) true/false -- takes over the throttle/braking when you are going to exceed your ships burn speed in atmo. (only when already in atmo, it does not prevent you from coming in to atmo too fast if manually transitioning from space to atmo)
maxPitch = 35 --export: (Max Pitch) set between 5-80, 35 is default.
maxRoll = 45 --export: (Max Roll) set between 5-80, 45 is default.
wingStallAngle = 35 --export: (Wing Stall Angle) 25-60. what angle do a majority of your wings stall? 25-60. Ailerons 30, Wings 55, Stabilizers 70. Set slightly below the stall angle of your main lift source. or split the difference if a mix. if you notice your ship "skids" in atmo, your wings are stalling, reduce this number.
shieldManage = true --export: (Auto Shield Management) true/false , let the ship handle shield control on off/resistance management/venting.
maxSpaceSpeed = 0 --export: (Max Space Speed) in km/h (max speed you want to go in space, not ships capable max speed) 0 for ships max capable speed, or if your selected speed exceeds ships capability, ships max speed will be used.
radarOn = false --export: (Radar Widget) true/false -- if radar attached, start with radar widget open (open close widget with /radar command)	
autoAGGAdjust = true --export: when AGG is active, have the AP automatically control it or not. either way it will try to land in the bubble and catch you.
pitchSpeedFactor = 0.8 --export: This factor will increase/decrease the player input along the pitch axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
yawSpeedFactor =  1 --export: This factor will increase/decrease the player input along the yaw axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01
rollSpeedFactor = 1.5 --export: This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

brakeSpeedFactor = 3 --export: When braking, this factor will increase the brake force by brakeSpeedFactor * velocity<br>Valid values: Superior or equal to 0.01
brakeFlatFactor = 1 --export: When braking, this factor will increase the brake force by a flat brakeFlatFactor * velocity direction><br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

autoRoll = false --export: [Only in atmosphere]<br>When the pilot stops rolling,  flight model will try to get back to horizontal (no roll)
autoRollFactor = 2 --export: [Only in atmosphere]<br>When autoRoll is engaged, this factor will increase to strength of the roll back to 0<br>Valid values: Superior or equal to 0.01

turnAssist = true --export: [Only in atmosphere]<br>When the pilot is rolling, the flight model will try to add yaw and pitch to make the construct turn better<br>The flight model will start by adding more yaw the more horizontal the construct is and more pitch the more vertical it is
turnAssistFactor = 2 --export: [Only in atmosphere]<br>This factor will increase/decrease the turnAssist effect<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01

torqueFactor = 2 --export: Force factor applied to reach rotationSpeed<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01