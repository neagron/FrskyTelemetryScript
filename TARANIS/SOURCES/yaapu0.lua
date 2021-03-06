--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Taranis X9D+ and QX7+ radios
--
-- Copyright (C) 2018. Alessandro Apostoli
--   https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
-- Borrowed some code from the LI-xx BATTCHECK v3.30 script
--  http://frskytaranis.forumactif.org/t2800-lua-download-un-testeur-de-batterie-sur-la-radio

--[[
	MAV_TYPE_GENERIC=0,               /* Generic micro air vehicle. | */
	MAV_TYPE_FIXED_WING=1,            /* Fixed wing aircraft. | */
	MAV_TYPE_QUADROTOR=2,             /* Quadrotor | */
	MAV_TYPE_COAXIAL=3,               /* Coaxial helicopter | */
	MAV_TYPE_HELICOPTER=4,            /* Normal helicopter with tail rotor. | */
	MAV_TYPE_ANTENNA_TRACKER=5,       /* Ground installation | */
	MAV_TYPE_GCS=6,                   /* Operator control unit / ground control station | */
	MAV_TYPE_AIRSHIP=7,               /* Airship, controlled | */
	MAV_TYPE_FREE_BALLOON=8,          /* Free balloon, uncontrolled | */
	MAV_TYPE_ROCKET=9,                /* Rocket | */
	MAV_TYPE_GROUND_ROVER=10,         /* Ground rover | */
	MAV_TYPE_SURFACE_BOAT=11,         /* Surface vessel, boat, ship | */
	MAV_TYPE_SUBMARINE=12,            /* Submarine | */
  MAV_TYPE_HEXAROTOR=13,            /* Hexarotor | */
	MAV_TYPE_OCTOROTOR=14,            /* Octorotor | */
	MAV_TYPE_TRICOPTER=15,            /* Tricopter | */
	MAV_TYPE_FLAPPING_WING=16,        /* Flapping wing | */
	MAV_TYPE_KITE=17,                 /* Kite | */
	MAV_TYPE_ONBOARD_CONTROLLER=18,   /* Onboard companion controller | */
	MAV_TYPE_VTOL_DUOROTOR=19,        /* Two-rotor VTOL using control surfaces in vertical operation in addition. Tailsitter. | */
	MAV_TYPE_VTOL_QUADROTOR=20,       /* Quad-rotor VTOL using a V-shaped quad config in vertical operation. Tailsitter. | */
	MAV_TYPE_VTOL_TILTROTOR=21,       /* Tiltrotor VTOL | */
	MAV_TYPE_VTOL_RESERVED2=22,       /* VTOL reserved 2 | */
	MAV_TYPE_VTOL_RESERVED3=23,       /* VTOL reserved 3 | */
	MAV_TYPE_VTOL_RESERVED4=24,       /* VTOL reserved 4 | */
	MAV_TYPE_VTOL_RESERVED5=25,       /* VTOL reserved 5 | */
	MAV_TYPE_GIMBAL=26,               /* Onboard gimbal | */
	MAV_TYPE_ADSB=27,                 /* Onboard ADSB peripheral | */
	MAV_TYPE_PARAFOIL=28,             /* Steerable, nonrigid airfoil | */
	MAV_TYPE_DODECAROTOR=29,          /* Dodecarotor | */
]]--

------------------------------------------------------------------------------------
-- X9D+ OpenTX 2.2.2 memory increase +4Kb https://github.com/opentx/opentx/pull/5579
------------------------------------------------------------------------------------

---------------------
-- radio model
---------------------
#define X9
--#define X7
-- to compile lua in luac files
--#define COMPILE
-- force loading of .lua files even after compilation
-- usefull if you rename .luac in .lua
--#define LOAD_LUA

#ifdef COMPILE
#define LOAD_LUA
#endif
---------------------
-- script version 
---------------------
#ifdef X9
  #define VERSION "Yaapu X9 telemetry script 1.7.1"
#else
  #define VERSION "Yaapu X7 1.7.1"
#endif

---------------------
-- features
---------------------
#define UNIT_SCALE
--#define FRAMETYPE
#define EFFICIENCY
---------------------
-- dev features
---------------------
--#define LOGTELEMETRY
--#define MEMDEBUG
#define COLLECTGARBAGE
--#define DEBUG
--#define TESTMODE
--#define BATT2TEST
--#define FLVSS2TEST
#ifdef TESTMODE
#define CELLCOUNT 4
#endif
--#define DEMO
--#define DEV
--#define DEBUGEVT
#define CS_LINES

-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE
-- calc and show actual incoming telemetry rate
--#define TELERATE

-------------------------------------
-- UNITS Scales from Ardupilot OSD code /ardupilot/libraries/AP_OSD/AP_OSD_Screen.cpp
-------------------------------------
--[[
    static const float scale_metric[UNIT_TYPE_LAST] = {
        1.0,       //ALTITUDE m
        3.6,       //SPEED km/hr
        1.0,       //VSPEED m/s
        1.0,       //DISTANCE m
        1.0/1000,  //DISTANCE_LONG km
        1.0,       //TEMPERATURE C
    };
    static const float scale_imperial[UNIT_TYPE_LAST] = {
        3.28084,     //ALTITUDE ft
        2.23694,     //SPEED mph
        3.28084,     //VSPEED ft/s
        3.28084,     //DISTANCE ft
        1.0/1609.34, //DISTANCE_LONG miles
        1.8,         //TEMPERATURE F
    };
    static const float scale_SI[UNIT_TYPE_LAST] = {
        1.0,       //ALTITUDE m
        1.0,       //SPEED m/s
        1.0,       //VSPEED m/s
        1.0,       //DISTANCE m
        1.0/1000,  //DISTANCE_LONG km
        1.0,       //TEMPERATURE C
    };
    static const float scale_aviation[UNIT_TYPE_LAST] = {
        3.28084,   //ALTITUDE Ft
        1.94384,   //SPEED Knots
        196.85,    //VSPEED ft/min
        3.28084,   //DISTANCE ft
        0.000539957,  //DISTANCE_LONG Nm
        1.0,       //TEMPERATURE C
    };
--]]
--
#define VFAS_ID 0x021F
#define VFAS_SUBID 0
#define VFAS_INSTANCE 0
#define VFAS_PRECISION 2
#define VFAS_NAME "VFAS"

#define CURR_ID 0x020F
#define CURR_SUBID 0
#define CURR_INSTANCE 0
#define CURR_PRECISION 1
#define CURR_NAME "CURR"

#define VSpd_ID 0x011F
#define VSpd_SUBID 0
#define VSpd_INSTANCE 0
#define VSpd_PRECISION 1
#define VSpd_NAME "VSpd"

#define GSpd_ID 0x083F
#define GSpd_SUBID 0
#define GSpd_INSTANCE 0
#define GSpd_PRECISION 0
#define GSpd_NAME "GSpd"

#define Alt_ID 0x010F
#define Alt_SUBID 0
#define Alt_INSTANCE 0
#define Alt_PRECISION 1
#define Alt_NAME "Alt"

#define GAlt_ID 0x082F
#define GAlt_SUBID 0
#define GAlt_INSTANCE 0
#define GAlt_PRECISION 0
#define GAlt_NAME "GAlt"

#define Hdg_ID 0x084F
#define Hdg_SUBID 0
#define Hdg_INSTANCE 0
#define Hdg_PRECISION 0
#define Hdg_NAME "Hdg"

#define Fuel_ID 0x060F
#define Fuel_SUBID 0
#define Fuel_INSTANCE 0
#define Fuel_PRECISION 0
#define Fuel_NAME "Fuel"

#define IMUTmp_ID 0x041F
#define IMUTmp_SUBID 0
#define IMUTmp_INSTANCE 0
#define IMUTmp_PRECISION 0
#define IMUTmp_NAME "IMUt"

#define ARM_ID 0x060F
#define ARM_SUBID 0
#define ARM_INSTANCE 1
#define ARM_PRECISION 0
#define ARM_NAME "ARM"

#ifdef X9
#ifdef FRAMETYPE
local frameNames = {}
-- copter
frameNames[0]   = "GEN"
frameNames[1]   = "WING"
frameNames[2]   = "QUAD"
frameNames[3]   = "COAX"
frameNames[4]   = "HELI"
frameNames[10]  = "ROV"
frameNames[11]  = "BOAT"
frameNames[13]  = "HEX"
frameNames[14]  = "OCTO"
frameNames[15]  = "TRI"
frameNames[16]  = "FLAP"
frameNames[19]  = "VTOL2"
frameNames[20]  = "VTOL4"
frameNames[21]  = "VTOLT"
frameNames[22]  = "VTOL"
frameNames[23]  = "VTOL"
frameNames[24]  = "VTOL"
frameNames[25]  = "VTOL"
frameNames[28]  = "FOIL"
frameNames[29]  = "DODE"
#endif --FRAMETYPE
#endif -- X9

local frameTypes = {}
-- copter
frameTypes[0]   = "c"
frameTypes[2]   = "c"
frameTypes[3]   = "c"
frameTypes[4]   = "c"
frameTypes[13]  = "c"
frameTypes[14]  = "c"
frameTypes[15]  = "c"
frameTypes[29]  = "c"
-- plane
frameTypes[1]   = "p"
frameTypes[16]  = "p"
frameTypes[19]  = "p"
frameTypes[20]  = "p"
frameTypes[21]  = "p"
frameTypes[22]  = "p"
frameTypes[23]  = "p"
frameTypes[24]  = "p"
frameTypes[25]  = "p"
frameTypes[28]  = "p"
-- rover
frameTypes[10]  = "r"
-- boat
frameTypes[11]  = "b"

#ifdef TESTMODE
-- undefined
frameTypes[5] = ""
frameTypes[6] = ""
frameTypes[7] = ""
frameTypes[8] = ""
frameTypes[9] = ""
frameTypes[12] = ""
frameTypes[17] = ""
frameTypes[18] = ""
frameTypes[26] = ""
frameTypes[27] = ""
frameTypes[30] = ""
#endif --TESTMODE
--
local frame = {}
--
local soundFileBasePath = "/SOUNDS/yaapu0"
local gpsStatuses = {}
--
#ifdef X9
gpsStatuses[0]="NoGPS"
gpsStatuses[1]="NoLock"
gpsStatuses[2]="2D"
gpsStatuses[3]="3D"
gpsStatuses[4]="DGPS"
gpsStatuses[5]="RTK"
gpsStatuses[6]="RTK"
#endif --X9

#ifdef X7
gpsStatuses[0]="GPS"
gpsStatuses[1]="Lock"
gpsStatuses[2]="2D"
gpsStatuses[3]="3D"
gpsStatuses[4]="DG"
gpsStatuses[5]="RT"
gpsStatuses[6]="RT"
#endif --X7
-- EMR,ALR,CRT,ERR,WRN,NOT,INF,DBG
#define mavSeverity(idx) string.sub("EMRALRCRTERRWRNNOTINFDBG",idx*3+1,idx*3+3)
--
#define CELLFULL 4.36
--------------------------------
-- FLVSS 1
local cell1min = 0
local cell1sum = 0
-- FLVSS 2
local cell2min = 0
local cell2sum = 0
-- FC 1
local cell1sumFC = 0
-- used to calculate cellcount
local cell1maxFC = 0
-- FC 2
local cell2sumFC = 0
-- A2
local cellsumA2 = 0
-- used to calculate cellcount
local cellmaxA2 = 0
--------------------------------
-- STATUS
local flightMode = 0
local simpleMode = 0
local landComplete = 0
local statusArmed = 0
local battFailsafe = 0
local ekfFailsafe = 0
local imuTemp = 0
-- GPS
local numSats = 0
local gpsStatus = 0
local gpsHdopC = 100
local gpsAlt = 0
-- BATT
local cellcount = 0
local battsource = "na"
-- BATT 1
local batt1volt = 0
local batt1current = 0
local batt1mah = 0
local batt1sources = {
  a2 = false,
  vs = false,
  fc = false
}
-- BATT 2
local batt2volt = 0
local batt2current = 0
local batt2mah = 0
local batt2sources = {
  a2 = false,
  vs = false,
  fc = false
}
-- TELEMETRY
local noTelemetryData = 1
-- HOME
local homeDist = 0
local homeAlt = 0
local homeAngle = -1
-- MESSAGES
local msgBuffer = ""
local lastMsgValue = 0
local lastMsgTime = 0
-- VELANDYAW
local vSpeed = 0
local hSpeed = 0
local yaw = 0
-- SYNTH VSPEED SUPPORT
local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0
-- ROLLPITCH
local roll = 0
local pitch = 0
local range = 0 
-- PARAMS
local frameType = -1
local batt1Capacity = 0
local batt2Capacity = 0
-- FLIGHT TIME
--[[ migrated to model.timer(2)
local seconds = 0
--]]
local lastTimerStart = 0
local timerRunning = 0
local flightTime = 0
-- EVENTS
local lastStatusArmed = 0
local lastGpsStatus = 0
local lastFlightMode = 0
local lastSimpleMode = 0
-- battery levels
local batLevel = 99
local battLevel1 = false
local battLevel2 = false
--
local lastBattLevel = 13
--
-- 00 05 10 15 20 25 30 40 50 60 70 80 90
#define batLevels(idx) tonumber(string.sub("00051015202530405060708090",idx*2+1,idx*2+2))
-- dual battery
local showDualBattery = false
--
#define MIN_BATT1_FC 1
#define MIN_BATT2_FC 2
#define MIN_CELL1_VS 3
#define MIN_CELL2_VS 4
#define MIN_BATT1_VS 5
#define MIN_BATT2_VS 6
#define MIN_BATT_A2 7

#define MAX_CURR 8
#define MAX_CURR1 9
#define MAX_CURR2 10
#define MAX_POWER 11
#define MINMAX_ALT 12
#define MAX_GPSALT 13
#define MAX_VSPEED 14
#define MAX_HSPEED 15
#define MAX_DIST 16
#define MAX_RANGE 17

#ifdef MEMDEBUG
local maxmem = 0
#endif
--
local minmaxValues = {}
-- min
minmaxValues[1] = 0
minmaxValues[2] = 0
minmaxValues[3] = 0
minmaxValues[4] = 0
minmaxValues[5] = 0
minmaxValues[6] = 0
minmaxValues[7] = 0
-- max
minmaxValues[8] = 0
minmaxValues[9] = 0
minmaxValues[10] = 0
minmaxValues[11] = 0
minmaxValues[12] = 0
minmaxValues[13] = 0
minmaxValues[14] = 0
minmaxValues[15] = 0
minmaxValues[16] = 0
minmaxValues[17] = 0

local showMinMaxValues = false
-- messages
local lastMessage
local lastMessageSeverity = 0
local lastMessageCount = 1
local messageCount = 0
local messages = {}
--
#ifdef LOGTELEMETRY
local logfile
local logfilename
#endif --LOGTELEMETRY
--
#ifdef PLAYLOG
local logfile
#endif -- PLAYLOG
--
#ifdef TESTMODE
-- TEST MODE
local thrOut = 0
#endif --TESTMODE

#ifdef X9
  
#define HUD_X 68
#define HUD_WIDTH 76
#define HUD_X_MID 35

#define LEFTPANE_X 68
#define RIGHTPANE_X 68

#define TOPBAR_Y 0
#define TOPBAR_HEIGHT 7
#define TOPBAR_WIDTH 212

#define BOTTOMBAR_Y 56
#define BOTTOMBAR_HEIGHT 9
#define BOTTOMBAR_WIDTH 212

#define BOX1_X 0
#define BOX1_Y 38
#define BOX1_WIDTH 66  
#define BOX1_HEIGHT 8

#define BOX2_X 61
#define BOX2_Y 46
#define BOX2_WIDTH 17  
#define BOX2_HEIGHT 12

#define BATTVOLT_X 2
#define BATTVOLT_Y 43
#define BATTVOLT_YV 43
#define BATTVOLT_FLAGS MIDSIZE+PREC1
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCELL_X 27
#define BATTCELL_Y 11
#define BATTCELL_YV 12
#define BATTCELL_YS 21
#define BATTCELL_FLAGS DBLSIZE+PREC2

#define BATTCURR_X 37
#define BATTCURR_Y 43
#define BATTCURR_YA 43
#define BATTCURR_FLAGS MIDSIZE+PREC1
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 4
#define BATTPERC_Y 15
#define BATTPERC_YPERC 20
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 5
#define BATTGAUGE_Y 28
#define BATTGAUGE_WIDTH 59
#define BATTGAUGE_HEIGHT 5
#define BATTGAUGE_STEPS 10

#define BATTMAH_X 10
#define BATTMAH_Y 35
#define BATTMAH_FLAGS SMLSIZE+PREC1

#define FLIGHTMODE_X 1
#define FLIGHTMODE_Y 0
#define FLIGHTMODE_FLAGS SMLSIZE+INVERS

#define HOMEANGLE_X 60
#define HOMEANGLE_Y 27
#define HOMEANGLE_XLABEL 3
#define HOMEANGLE_YLABEL 27
#define HOMEANGLE_FLAGS SMLSIZE

#define HSPEED_X 60
#define HSPEED_Y 49
#define HSPEED_XLABEL 12
#define HSPEED_YLABEL 48
#define HSPEED_XDIM 61
#define HSPEED_YDIM 49
#define HSPEED_FLAGS SMLSIZE
#define HSPEED_ARROW_WIDTH 10

#define GPS_X 0
#define GPS_Y 6
#define GPS_BORDER 0

#define ALTASL_X 65
#define ALTASL_Y 26
#define ALTASL_XLABEL 4
#define ALTASL_YLABEL 25
#define ALTASL_FLAGS RIGHT

#define BATTPOWER_X 65
#define BATTPOWER_Y 45
#define BATTPOWER_XLABEL 2
#define BATTPOWER_YLABEL 45
#define BATTPOWER_FLAGS SMLSIZE+RIGHT

#define HOMEDIST_X 65
#define HOMEDIST_Y 36
#define HOMEDIST_XLABEL 2
#define HOMEDIST_YLABEL 36
#define HOMEDIST_FLAGS RIGHT
#define HOMEDIST_ARROW_WIDTH 8

#define HOMEDIR_X 82
#define HOMEDIR_Y 48
#define HOMEDIR_R 7

#define FLIGHTTIME_X 179
#define FLIGHTTIME_Y 0
#define FLIGHTTIME_FLAGS SMLSIZE+INVERS

#define RSSI_X 69
#define RSSI_Y 0
#define RSSI_FLAGS SMLSIZE+INVERS 

#define TXVOLTAGE_X 116
#define TXVOLTAGE_Y 0
#define TXVOLTAGE_FLAGS SMLSIZE+INVERS

#endif --X9

#ifdef X7
  
#define HUD_X 0
#define HUD_WIDTH 64
#define HUD_X_MID 35

#define LEFTPANE_X 68
#define RIGHTPANE_X 68

#define TOPBAR_Y 0
#define TOPBAR_HEIGHT 7
#define TOPBAR_WIDTH 128

#define BOTTOMBAR_Y 57
#define BOTTOMBAR_HEIGHT 8
#define BOTTOMBAR_WIDTH 128

#define BOX1_X 65
#define BOX1_Y 28
#define BOX1_WIDTH 23 
#define BOX1_HEIGHT 15

#define BOX2_X 65
#define BOX2_Y 7
#define BOX2_WIDTH 38  
#define BOX2_HEIGHT 7

#define BATTVOLT_X 1
#define BATTVOLT_Y 29
#define BATTVOLT_YV 29
#define BATTVOLT_FLAGS INVERS+PREC1+SMLSIZE
#define BATTVOLT_FLAGSV INVERS+SMLSIZE

#define BATTCELL_X 24
#define BATTCELL_Y 27
#define BATTCELL_YV 28
#define BATTCELL_YS 36
#define BATTCELL_FLAGS DBLSIZE+PREC2

#define BATTCURR_X 1
#define BATTCURR_Y 36
#define BATTCURR_YA 36
#define BATTCURR_FLAGS INVERS+SMLSIZE+PREC1
#define BATTCURR_FLAGSA INVERS+SMLSIZE

#define BATTPERC_X 5
#define BATTPERC_Y 44
#define BATTPERC_YPERC 48
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTGAUGE_X 0
#define BATTGAUGE_Y 0
#define BATTGAUGE_WIDTH 0
#define BATTGAUGE_HEIGHT 0
#define BATTGAUGE_STEPS 0


#define BATTMAH_X 64
#define BATTMAH_Y 43
#define BATTMAH_FLAGS SMLSIZE+PREC1


#define FLIGHTMODE_X 1
#define FLIGHTMODE_Y 0
#define FLIGHTMODE_FLAGS SMLSIZE+INVERS

#define HOMEANGLE_X 0
#define HOMEANGLE_Y 0
#define HOMEANGLE_XLABEL 0
#define HOMEANGLE_YLABEL 0
#define HOMEANGLE_FLAGS SMLSIZE

#define HSPEED_X 107
#define HSPEED_Y 8
#define HSPEED_XLABEL 66
#define HSPEED_YLABEL 10
#define HSPEED_XDIM 102
#define HSPEED_YDIM 9
#define HSPEED_FLAGS SMLSIZE
#define HSPEED_ARROW_WIDTH 6

#define GPS_X 65
#define GPS_Y 6
#define GPS_BORDER 0

#define ALTASL_X 103
#define ALTASL_Y 8
#define ALTASL_XLABEL 67
#define ALTASL_YLABEL 9

#define HOMEDIST_X 103
#define HOMEDIST_Y 19
#define HOMEDIST_XLABEL 66
#define HOMEDIST_YLABEL 19
#define HOMEDIST_FLAGS RIGHT
#define HOMEDIST_ARROW_WIDTH 7

#define HOMEDIR_X 54
#define HOMEDIR_Y 48
#define HOMEDIR_R 7

#define FLIGHTTIME_X 96
#define FLIGHTTIME_Y 0
#define FLIGHTTIME_FLAGS SMLSIZE+INVERS

#define RSSI_X 70
#define RSSI_Y 0
#define RSSI_FLAGS SMLSIZE+INVERS 

#define TXVOLTAGE_X 104
#define TXVOLTAGE_Y 21
#define TXVOLTAGE_FLAGS SMLSIZE

#endif --X7

--------------------------------------------------------------------------------
-- ALARMS
--------------------------------------------------------------------------------
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{ 
  1 = notified, 
  2 = alarm start, 
  3 = armed, 
  4 = type(0=min,1=max,2=timer,3=batt), 
  5 = grace duration
  6 = ready
  7 = last alarm
}  
--]]
#define ALARM_NOTIFIED 1
#define ALARM_START 2
#define ALARM_ARMED 3
#define ALARM_TYPE 4
#define ALARM_GRACE 5
#define ALARM_READY 6
#define ALARM_LAST_ALARM 7
--
#define ALARMS_MIN_ALT 1
#define ALARMS_MAX_ALT 2
#define ALARMS_MAX_DIST 3
#define ALARMS_FS_EKF 4
#define ALARMS_FS_BATT 5
#define ALARMS_TIMER 6
#define ALARMS_BATT_L1 7
#define ALARMS_BATT_L2 8
--
#define ALARM_TYPE_MIN 0
#define ALARM_TYPE_MAX 1 
#define ALARM_TYPE_TIMER 2
#define ALARM_TYPE_BATT 3
--
#define ALARM_TYPE_BATT_GRACE 4
--
local alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, ALARM_TYPE_MIN, 0, false, 0}, --MIN_ALT
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_ALT
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --MAX_DIST
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_EKF
    { false, 0 , true, ALARM_TYPE_MAX, 0, false, 0 }, --FS_BAT
    { false, 0 , true, ALARM_TYPE_TIMER, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0 }, --BATT L1
    { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0 } --BATT L2
}

--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------
-- X-Lite Support
#define XLITE_UP 36
#define XLITE_UP_RPT 68
#define XLITE_DOWN 35
#define XLITE_DOWN_RPT 67
#define XLITE_RTN 33
#define XLITE_ENTER 34
#define XLITE_MENU_LONG 128
#define XLITE_MENU 32

#define TYPEVALUE 0
#define TYPECOMBO 1
#define MENU_Y 7
#define MENU_PAGESIZE 7
#define MENU_WRAPOFFSET 12
#ifdef X9
#define MENU_ITEM_X 150
#else
#define MENU_ITEM_X 99
#endif

#define L1 1
#define V1 2
#define V2 3
#define B1 4
#define B2 5
#define S1 6
#define S2 7
#define S3 8
#define VS 9
#define T1 10
#define A1 11
#define A2 12
#define D1 13
#define T2 14
#define CC 15
#define RM 16
#define SVS 17
#define HSPD 18
#define VSPD 19
  
#define CONF_LANGUAGE menuItems[L1][6][menuItems[L1][4]]
#define CONF_BATT_LEVEL1 menuItems[V1][4]
#define CONF_BATT_LEVEL2 menuItems[V2][4]
#define CONF_BATT_CAP1 menuItems[B1][4]*0.1
#define CONF_BATT_CAP2 menuItems[B2][4]*0.1
#define CONF_DISABLE_SOUNDS menuItems[S1][6][menuItems[S1][4]]
#define CONF_DISABLE_MSGBEEP menuItems[S2][6][menuItems[S2][4]]
#define CONF_DISABLE_MSGBLINK menuItems[S3][6][menuItems[S3][4]]
#define CONF_BATT_SOURCE menuItems[VS][6][menuItems[VS][4]]
#define CONF_TIMER_ALERT menuItems[T1][4]*0.1*60
#define CONF_MINALT_ALERT menuItems[A1][4]*0.1
#define CONF_MAXALT_ALERT menuItems[A2][4]
#define CONF_MAXDIST_ALERT menuItems[D1][4]
#define CONF_REPEAT menuItems[T2][4]
#define CONF_CELL_COUNT menuItems[CC][4]
#define CONF_RANGE_MAX menuItems[RM][4]
#define CONF_ENABLE_SYNTHVSPEED menuItems[SVS][6][menuItems[SVS][4]]
#define CONF_HSPEED_MULT menuItems[HSPD][6][menuItems[HSPD][4]]
#define CONF_VSPEED_MULT menuItems[VSPD][6][menuItems[VSPD][4]]


local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0
}

#ifdef X9
local menuItems = {
  {"voice language:", TYPECOMBO, "L1", 1, { "english", "italian", "french", "german" } , {"en","it","fr","de"} },
  {"batt alert level 1:", TYPEVALUE, "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", TYPEVALUE, "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] capacity override:", TYPEVALUE, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] capacity override:", TYPEVALUE, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", TYPECOMBO, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable msg blink:", TYPECOMBO, "S3", 1, { "no", "yes" }, { false, true } },
  {"default voltage source:", TYPECOMBO, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } },
  {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", TYPEVALUE, "T2", 10, 5,600,"sec",0,5 },
  {"cell count override:", TYPEVALUE, "CC", 0, 0,12," cells",0,1 },
  {"rangefinder max:", TYPEVALUE, "RM", 0, 0,10000," cm",0,10 },
  {"enable synthetic vspeed:", TYPECOMBO, "SVS", 1, { "no", "yes" }, { false, true } },
  {"air/groundspeed unit:", TYPECOMBO, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vert speed unit:", TYPECOMBO, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
}
#endif --X9

#ifdef X7
local menuItems = {
  {"voice language:", TYPECOMBO, "L1", 1, { "eng", "ita", "fre", "ger" } , {"en","it","fr","de"} },
  {"batt alert level 1:", TYPEVALUE, "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", TYPEVALUE, "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] mAh override:", TYPEVALUE, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] mAh override:", TYPEVALUE, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", TYPECOMBO, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", TYPECOMBO, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable msg blink:", TYPECOMBO, "S3", 1, { "no", "yes" }, { false, true } },
  {"def voltage source:", TYPECOMBO, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } },
  {"timer alert every:", TYPEVALUE, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", TYPEVALUE, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", TYPEVALUE, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", TYPEVALUE, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", TYPEVALUE, "T2", 10, 5,600,"sec",0,5 },
  {"cell count override:", TYPEVALUE, "CC", 0, 0,12,"s",0,1 },
  {"rangefinder max:", TYPEVALUE, "RM", 0, 0,10000," cm",0,10 },
  {"enable synth.vspeed:", TYPECOMBO, "SVS", 1, { "no", "yes" }, { false, true } },
  {"air/groundspd unit:", TYPECOMBO, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vert speed unit:", TYPECOMBO, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
}
#endif --X7

local modelInfo = model.getInfo()
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084

#define UNIT_ALT_SCALE unitScale
#define UNIT_DIST_SCALE unitScale
#define UNIT_DIST_LONG_SCALE (settings.imperial==0 and 1/1000 or 1/1609.34)
#define UNIT_HSPEED_SCALE menuItems[HSPD][6][menuItems[HSPD][4]]
#define UNIT_VSPEED_SCALE menuItems[VSPD][6][menuItems[VSPD][4]]

#ifdef X7
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "f"
#define UNIT_ALT_LABEL unitLabel
#define UNIT_DIST_LABEL unitLabel
#else
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
#define UNIT_ALT_LABEL unitLabel
#define UNIT_DIST_LABEL unitLabel
#endif

local function getConfigFilename()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(modelInfo.name, "[%c%p%s%z]", "")..".cfg")
end

local function applyConfigValues()
  if CONF_BATT_SOURCE ~= nil then
    battsource = CONF_BATT_SOURCE
  end
#ifdef COLLECTGARBAGE
  collectgarbage()
#endif
end

local function loadConfig()
  local cfg = io.open(getConfigFilename(),"r")
  if cfg == nil then
    return
  end
  local str = io.read(cfg,200)
  if string.len(str) > 0 then
    for i=1,#menuItems
    do
		local value = string.match(str, menuItems[i][3]..":(%d+)")
		if value ~= nil then
		  menuItems[i][4] = tonumber(value)
		end
    end
  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function saveConfig()
  local cfg = assert(io.open(getConfigFilename(),"w"))
  if cfg == nil then
    return
  end
  for i=1,#menuItems
  do
    io.write(cfg,menuItems[i][3],":",menuItems[i][4])
    if i < #menuItems then
      io.write(cfg,",")
    end
  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function drawConfigMenuBars()
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
#ifdef X9
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawRectangle(0, TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawText(0,0,VERSION,SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawRectangle(0, BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawText(0,BOTTOMBAR_Y+1,getConfigFilename(),SMLSIZE+INVERS)
#endif --X9
#ifdef X7
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawRectangle(0, TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawText(0,0,VERSION,SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y-1, BOTTOMBAR_WIDTH, 9, SOLID)
  lcd.drawRectangle(0, BOTTOMBAR_Y-1, BOTTOMBAR_WIDTH, 9, SOLID)
  lcd.drawText(0,BOTTOMBAR_Y,string.sub(getConfigFilename(),8),SMLSIZE+INVERS)
#endif --X7
  lcd.drawText(BOTTOMBAR_WIDTH,BOTTOMBAR_Y+1,itemIdx,SMLSIZE+INVERS+RIGHT)
end

local function incMenuItem(idx)
  if menuItems[idx][2] == TYPEVALUE then
    menuItems[idx][4] = menuItems[idx][4] + menuItems[idx][9]
    if menuItems[idx][4] > menuItems[idx][6] then
      menuItems[idx][4] = menuItems[idx][6]
    end
  else
    menuItems[idx][4] = menuItems[idx][4] + 1
    if menuItems[idx][4] > #menuItems[idx][5] then
      menuItems[idx][4] = 1
    end
  end
end

local function decMenuItem(idx)
  if menuItems[idx][2] == TYPEVALUE then
    menuItems[idx][4] = menuItems[idx][4] - menuItems[idx][9]
    if menuItems[idx][4] < menuItems[idx][5] then
      menuItems[idx][4] = menuItems[idx][5]
    end
  else
    menuItems[idx][4] = menuItems[idx][4] - 1
    if menuItems[idx][4] < 1 then
      menuItems[idx][4] = #menuItems[idx][5]
    end
  end
end

local function drawItem(idx,flags)
  if menuItems[idx][2] == TYPEVALUE then
    if menuItems[idx][4] == 0 then
      lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*7, "---",0+SMLSIZE+flags+menuItems[idx][8])
    else
      lcd.drawNumber(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][4],0+SMLSIZE+flags+menuItems[idx][8])
      lcd.drawText(lcd.getLastRightPos(),MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][7],SMLSIZE+flags)
    end
  else
    lcd.drawText(MENU_ITEM_X,MENU_Y + (idx-menu.offset-1)*7, menuItems[idx][5][menuItems[idx][4]],SMLSIZE+flags)
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if event == EVT_ENTER_BREAK or event == XLITE_ENTER then
	menu.editSelected = not menu.editSelected
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == EVT_PLUS_REPT or event == XLITE_UP or event == XLITE_UP_RPT) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_MINUS_REPT or event == XLITE_DOWN or event == XLITE_DOWN_RPT) then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == XLITE_UP) then
    menu.selectedItem = (menu.selectedItem - 1)
    if menu.offset >=  menu.selectedItem then
      menu.offset = menu.offset - 1
    end
  elseif not menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == XLITE_DOWN) then
    menu.selectedItem = (menu.selectedItem + 1)
    if menu.selectedItem - MENU_PAGESIZE > menu.offset then
      menu.offset = menu.offset + 1
    end
  end
  --wrap
  if menu.selectedItem > #menuItems then
    menu.selectedItem = 1 
    menu.offset = 0
  elseif menu.selectedItem  < 1 then
    menu.selectedItem = #menuItems
    -- 
    menu.offset = MENU_WRAPOFFSET
  end
  --
  for m=1+menu.offset,math.min(#menuItems,MENU_PAGESIZE+menu.offset) do
    lcd.drawText(2,MENU_Y + (m-menu.offset-1)*7, menuItems[m][1],0+SMLSIZE)
    if m == menu.selectedItem then
      if menu.editSelected then
        drawItem(m,INVERS+BLINK)
      else
        drawItem(m,INVERS)
      end
    else
      drawItem(m,0)
    end
  end
end
-----------------------
-- SOUNDS
-----------------------
local function playSound(soundFile)
  if CONF_DISABLE_SOUNDS then
    return
  end
  playFile(soundFileBasePath .."/"..CONF_LANGUAGE.."/".. soundFile..".wav")
end
----------------------------------------------
-- NOTE: sound file has same name as flightmode all lowercase with .wav extension
----------------------------------------------
local function playSoundByFrameTypeAndFlightMode(frameType,flightMode)
  if CONF_DISABLE_SOUNDS then
    return
  end
  if frame.flightModes then
    if frame.flightModes[flightMode] ~= nil then
      playFile(soundFileBasePath.."/"..CONF_LANGUAGE.."/".. string.lower(frame.flightModes[flightMode])..".wav")
    end
  end
end

local function drawHArrow(x,y,width,left,right)
  lcd.drawLine(x, y, x + width,y, SOLID, 0)
  if left == true then
    lcd.drawLine(x + 1,y  - 1,x + 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + 1,x + 2,y  + 2, SOLID, 0)
  end
  if right == true then
    lcd.drawLine(x + width - 1,y  - 1,x + width - 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + width - 1,y  + 1,x + width - 2,y  + 2, SOLID, 0)
  end
end

local function drawVArrow(x,y,h,top,bottom)
  lcd.drawLine(x,y,x,y + h, SOLID, 0)
  if top == true then
    lcd.drawLine(x - 1,y + 1,x - 2,y  + 2, SOLID, 0)
    lcd.drawLine(x + 1,y + 1,x + 2,y  + 2, SOLID, 0)
  end
  if bottom == true then
    lcd.drawLine(x - 1,y  + h - 1,x - 2,y + h - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + h - 1,x + 2,y + h - 2, SOLID, 0)
  end
end
--
local function drawHomeIcon(x,y)
  lcd.drawRectangle(x,y,5,5,SOLID)
  lcd.drawLine(x+2,y+3,x+2,y+4,SOLID,FORCE)
  lcd.drawPoint(x+2,y-1,FORCE)
  lcd.drawLine(x,y+1,x+5,y+1,SOLID,FORCE)
  lcd.drawLine(x-1,y+1,x+2,y-2,SOLID, FORCE)
  lcd.drawLine(x+5,y+1,x+3,y-1,SOLID, FORCE)
end

#ifdef CS_LINES
#define CS_INSIDE 0
#define CS_LEFT 1
#define CS_RIGHT 2
#define CS_BOTTOM 4
#define CS_TOP 8

local function computeOutCode(x,y,xmin,ymin,xmax,ymax)
    local code = CS_INSIDE; --initialised as being inside of hud
    --
    if x < xmin then --to the left of hud
        code = bit32.bor(code,CS_LEFT);
    elseif x > xmax then --to the right of hud
        code = bit32.bor(code,CS_RIGHT);
    end
    if y < ymin then --below the hud
        code = bit32.bor(code,CS_BOTTOM);
    elseif y > ymax then --above the hud
        code = bit32.bor(code,CS_TOP);
    end
    --
    return code;
end

-- Cohen–Sutherland clipping algorithm
-- https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
local function drawLineWithClipping(ox,oy,angle,len,style,xmin,xmax,ymin,ymax)
  --
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  --
  local x0 = ox - xx
  local x1 = ox + xx
  local y0 = oy - yy
  local y1 = oy + yy    
  -- compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
  local outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax);
  local outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax);
  local accept = false;

  while (true) do
    if ( bit32.bor(outcode0,outcode1) == CS_INSIDE) then
      -- bitwise OR is 0: both points inside window; trivially accept and exit loop
      accept = true;
      break;
    elseif (bit32.band(outcode0,outcode1) ~= CS_INSIDE) then
      -- bitwise AND is not 0: both points share an outside zone (LEFT, RIGHT, TOP, BOTTOM)
      -- both must be outside window; exit loop (accept is false)
      break;
    else
      -- failed both tests, so calculate the line segment to clip
      -- from an outside point to an intersection with clip edge
      local x = 0
      local y = 0
      -- At least one endpoint is outside the clip rectangle; pick it.
      local outcodeOut = outcode0 ~= CS_INSIDE and outcode0 or outcode1
      -- No need to worry about divide-by-zero because, in each case, the
      -- outcode bit being tested guarantees the denominator is non-zero
      if bit32.band(outcodeOut,CS_TOP) ~= CS_INSIDE then --point is above the clip window
        x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
        y = ymax
      elseif bit32.band(outcodeOut,CS_BOTTOM) ~= CS_INSIDE then --point is below the clip window
        x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
        y = ymin
      elseif bit32.band(outcodeOut,CS_RIGHT) ~= CS_INSIDE then --point is to the right of clip window
        y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
        x = xmax
      elseif bit32.band(outcodeOut,CS_LEFT) ~= CS_INSIDE then --point is to the left of clip window
        y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
        x = xmin
      end
      -- Now we move outside point to intersection point to clip
      -- and get ready for next pass.
      if outcodeOut == outcode0 then
        x0 = x
        y0 = y
        outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax)
      else
        x1 = x
        y1 = y
        outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax)
      end
    end
  end
  if accept then
    lcd.drawLine(x0,y0,x1,y1, style,0)
  end
end
#else --CS_LINES
-- draws a line centered at ox,oy with given angle and length WITH CROPPING
local function drawCroppedLine(ox,oy,angle,len,style,minX,maxX,minY,maxY)
  --
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  --
  local x1 = ox - xx
  local x2 = ox + xx
  local y1 = oy - yy
  local y2 = oy + yy
  --
  -- crop right
  if (x1 >= maxX and x2 >= maxX) then
    return
  end

  if (x1 >= maxX) then
    y1 = y1 - math.tan(math.rad(angle)) * (maxX - x1)
    x1 = maxX - 1
  end

  if (x2 >= maxX) then
    y2 = y2 + math.tan(math.rad(angle)) * (maxX - x2)
    x2 = maxX - 1
  end
  -- crop left
  if (x1 <= minX and x2 <= minX) then
    return
  end

  if (x1 <= minX) then
    y1 = y1 - math.tan(math.rad(angle)) * (x1 - minX)
    x1 = minX + 1
  end

  if (x2 <= minX) then
    y2 = y2 + math.tan(math.rad(angle)) * (x2 - minX)
    x2 = minX + 1
  end
  --
  -- crop right
  if (y1 >= maxY and y2 >= maxY) then
    return
  end

  if (y1 >= maxY) then
    x1 = x1 - (y1 - maxY)/math.tan(math.rad(angle))
    y1 = maxY - 1
  end

  if (y2 >= maxY) then
    x2 = x2 -  (y2 - maxY)/math.tan(math.rad(angle))
    y2 = maxY - 1
  end
  -- crop left
  if (y1 <= minY and y2 <= minY) then
    return
  end

  if (y1 <= minY) then
    x1 = x1 + (minY - y1)/math.tan(math.rad(angle))
    y1 = minY + 1
  end

  if (y2 <= minY) then
    x2 = x2 + (minY - y2)/math.tan(math.rad(angle))
    y2 = minY + 1
  end

  lcd.drawLine(x1,y1,x2,y2, style,0)
end
#endif --CS_LINES

#ifdef DEV
local function draw8(x0,y0,x,y)
  lcd.drawPoint(x0 + x, y0 + y);
  lcd.drawPoint(x0 + y, y0 + x);
  lcd.drawPoint(x0 - y, y0 + x);
  lcd.drawPoint(x0 - x, y0 + y);
  lcd.drawPoint(x0 - x, y0 - y);
  lcd.drawPoint(x0 - y, y0 - x);
  lcd.drawPoint(x0 + y, y0 - x);
  lcd.drawPoint(x0 + x, y0 - y);
end

local function drawCircle10(x0,y0)
  draw8(x0,y0,5,1)
  draw8(x0,y0,5,2)
  draw8(x0,y0,4,3)
  draw8(x0,y0,4,4)
  lcd.drawPoint(x0 + 5,y0)
  lcd.drawPoint(x0 - 5,y0)
  lcd.drawPoint(x0,y0 + 5)
  lcd.drawPoint(x0,y0 - 5)
end

local function drawCircle(x0,y0,radius,delta)
  local x = radius-1
  local y = 0
  local dx = delta
  local dy = delta
  local err = dx - bit32.lshift(radius,1)
  while (x >= y) do
    lcd.drawPoint(x0 + x, y0 + y);
    lcd.drawPoint(x0 + y, y0 + x);
    lcd.drawPoint(x0 - y, y0 + x);
    lcd.drawPoint(x0 - x, y0 + y);
    lcd.drawPoint(x0 - x, y0 - y);
    lcd.drawPoint(x0 - y, y0 - x);
    lcd.drawPoint(x0 + y, y0 - x);
    lcd.drawPoint(x0 + x, y0 - y);
    if err <= 0 then
      y=y+1
      err = err + dy
      dy = dy + 2
    end
    if err > 0 then

      x=x-1
      dx = dx + 2
      err = err + dx - bit32.lshift(radius,1)
    end
  end
end

local function drawHomePad(x0,y0)
  drawCircle(x0 + 5,y0,5,2)
  lcd.drawText(x0 + 5 - 2,y0 - 3,"H")
end
#endif --DEV

local function drawNumberWithTwoDims(x,y,yTop,yBottom,number,topDim,bottomDim,flags,topFlags,bottomFlags)
  -- +0.5 because PREC2 does a math.floor() and not a math.round()
  lcd.drawNumber(x, y, number + 0.5, flags)
  local lx = lcd.getLastRightPos()
  lcd.drawText(lx, yTop, topDim, topFlags)
  lcd.drawText(lx, yBottom, bottomDim, bottomFlags)
end

local function drawNumberWithDim(x,y,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(lcd.getLastRightPos(), yDim, dim, dimFlags)
end

#ifdef LOGTELEMETRY
local function getLogFilename(date)
  local modelName = string.lower(string.gsub(modelInfo.name, "[%c%p%s%z]", ""))
  return string.format("%s-%04d%02d%02d_%02d%02d%02d.plog",modelName,date.year,date.mon,date.day,date.hour,date.min,date.sec)
end

local function logTelemetryToFile(lc1,lc2,lc3,lc4)
  -- flight time
  local fmins = math.floor(flightTime / 60)
  local fsecs = flightTime % 60
  -- local date tiime from radio
  io.write(logfile,string.format("%d;%02d:%02d;%#01x;%#01x;%#02x;%#04x",getTime(),fmins,fsecs, lc1, lc2, lc3, lc4),"\r\n")
end
#endif --LOGTELEMETRY


#ifdef X9
local function formatMessage(severity,msg)
  if lastMessageCount > 1 then
    if #msg > 36 then
      msg = string.sub(msg,1,36)
    end
    return string.format("%02d:%s %s (x%d)", messageCount, mavSeverity(severity), msg, lastMessageCount)
  else
    if #msg > 40 then
      msg = string.sub(msg,1,40)
    end
    return string.format("%02d:%s %s", messageCount, mavSeverity(severity), msg)
  end
end
#endif --X9
#ifdef X7
local function formatMessage(severity,msg)
  if lastMessageCount > 1 then
    if #msg > 16 then
      msg = string.sub(msg,1,16)
    end
    return string.format("%d:%s %s (x%d)", messageCount, mavSeverity(severity), msg, lastMessageCount)
  else
    if #msg > 23 then
      msg = string.sub(msg,1,23)
    end
    return string.format("%d:%s %s", messageCount, mavSeverity(severity), msg)
  end
end
#endif --X7

#define MAX_MESSAGES 9

local function pushMessage(severity, msg)
  if  CONF_DISABLE_MSGBEEP == false and CONF_DISABLE_SOUNDS == false then
    if ( severity < 5) then
      playSound("../err")
    else
      playSound("../inf")
    end
  end
  -- check if wrapping is needed
  if #messages == MAX_MESSAGES and msg ~= lastMessage then
    for i=1,MAX_MESSAGES-1 do
      messages[i]=messages[i+1]
    end
    -- trunc at 9
    messages[MAX_MESSAGES] = nil
  end
  -- is it a duplicate?
  if msg == lastMessage then
    lastMessageCount = lastMessageCount + 1
    messages[#messages] = formatMessage(severity,msg)
  else  
    lastMessageCount = 1
    messageCount = messageCount + 1
    messages[#messages+1] = formatMessage(severity,msg)
  end
  lastMessage = msg
  lastMessageSeverity = severity
#ifdef COLLECTGARBAGE  
  collectgarbage()
  maxmem = 0
#endif
end
--
local function startTimer()
  lastTimerStart = getTime()/100
  model.setTimer(2,{mode=1})
end

local function stopTimer()
  model.setTimer(2,{mode=0})
  lastTimerStart = 0
end

#ifdef TESTMODE
-----------------------------------------------------
-- TEST MODE
-----------------------------------------------------
local function symTimer()
#ifdef DEMO
  seconds = 60 * 9 + 30
#endif --DEMO
  thrOut = getValue("thr")
  if (thrOut > -500 ) then
    landComplete = 1
  else
    landComplete = 0
  end
end

local function symGPS()
  thrOut = getValue("thr")
  if thrOut > 500 then
    numSats = 17
    gpsStatus = 4
    gpsHdopC = 6
    ekfFailsafe = 0
    battFailsafe = 0
    noTelemetryData = 0
    statusArmed = 1
  elseif thrOut < 500 and thrOut > 0  then
    numSats = 13
    gpsStatus = 5
    gpsHdopC = 6
    ekfFailsafe = 1
    battFailsafe = 0
    noTelemetryData = 0
    statusArmed = 1
  elseif thrOut > -500  then
    numSats = 6
    gpsStatus = 3
    gpsHdopC = 120
    ekfFailsafe = 0
    battFailsafe = 1
    noTelemetryData = 0
    statusArmed = 0
  else
    numSats = 0
    gpsStatus = 0
    gpsHdopC = 100
    ekfFailsafe = 0
    battFailsafe = 0
    noTelemetryData = 1
    statusArmed = 0
  end
end

local function symFrameType()
  local ch11 = getValue("ch11")
  if ch11 < -300 then
    frameType = 2
    simpleMode = 0
  elseif ch11 < 300 then
    frameType = 1
    simpleMode = 1
  else
    frameType = 10
    simpleMode = 2
  end
end

local function symBatt()
  thrOut = getValue("thr")
  if (thrOut > -500 ) then
#ifdef DEMO
    if battFailsafe == 1 then
      minmaxValues[MIN_BATT1_FC] = CELLCOUNT * 3.40
      minmaxValues[MIN_BATT2_FC] = CELLCOUNT * 3.43
      minmaxValues[MAX_CURR] = 341 + 335
      minmaxValues[MAX_CURR1] = 341
      minmaxValues[MAX_CURR2] = 335
      minmaxValues[MAX_POWER] = (CELLCOUNT * 3.43)*(34.1 + 33.5)
      -- battery voltage
      batt1current = 235
      batt1volt = CELLCOUNT * 3.43 * 10
      batt1Capacity = 5200
      batt1mah = 4400
#ifdef BATT2TEST
      batt2current = 238
      batt2volt = CELLCOUNT  * 3.44 * 10
      batt2Capacity = 5200
      batt2mah = 4500
#endif --BATT2TEST
    else
      minmaxValues[MIN_BATT1_FC] = CELLCOUNT * 3.75
      minmaxValues[MIN_BATT2_FC] = CELLCOUNT * 3.77
      minmaxValues[MAX_CURR] = 341+335
      minmaxValues[MAX_CURR1] = 341
      minmaxValues[MAX_CURR2] = 335
      minmaxValues[MAX_POWER] = (CELLCOUNT * 3.89)*(34.1+33.5)
      -- battery voltage
      batt1current = 235
      batt1volt = CELLCOUNT * 3.87 * 10
      batt1Capacity = 5200
      batt1mah = 2800
#ifdef BATT2TEST
      batt2current = 238
      batt2volt = CELLCOUNT * 3.89 * 10
      batt2Capacity = 5200
      batt2mah = 2700
#endif --BATT2TEST
    end
#else --DEMO
    -- battery voltage
    batt1current = 100 +  ((thrOut)*0.01 * 30)
    batt1volt = CELLCOUNT * (32 + 10*math.abs(thrOut)*0.001)
    batt1Capacity = 5200
    batt1mah = 5200 - math.abs(1000*(thrOut/200))
#ifdef BATT2TEST
    batt2current = 100 +  ((thrOut)*0.01 * 30)
    batt2volt = CELLCOUNT * (32 + 10*math.abs(thrOut)*0.001)
    batt2Capacity = 5200
    batt2mah = 5200 - math.abs(1000*(thrOut/200))
#endif --BATT2TEST
#endif --DEMO
  -- flightmode
#ifdef DEMO
    flightMode = 1
    minmaxValues[MAX_GPSALT] = 270*0.1
    minmaxValues[MAX_DIST] = 130
    gpsAlt = 200
    homeDist = 95
#else --DEMO
    flightMode = math.floor(20 * math.abs(thrOut)*0.001)
    gpsAlt = math.floor(10 * math.abs(thrOut)*0.1)
    homeDist = math.floor(15 * math.abs(thrOut)*0.1)
#endif --DEMO
  else
    batt1mah = 0
  end
end

-- simulates attitude by using channel 1 for roll, channel 2 for pitch and channel 4 for yaw
local function symAttitude()
#ifdef DEMO
  roll = 14
  pitch = -0.8
  yaw = 33
#else --DEMO
  local rollCh = 0
  local pitchCh = 0
  local yawCh = 0
  -- roll [-1024,1024] ==> [-180,180]
  rollCh = getValue("ch1") * 0.175
  -- pitch [1024,-1024] ==> [-90,90]
  pitchCh = getValue("ch2") * 0.0878
  -- yaw [-1024,1024] ==> [0,360]
  yawCh = getValue("ch10")
  if ( yawCh >= 0) then
    yawCh = yawCh * 0.175
  else
    yawCh = 360 + (yawCh * 0.175)
  end
  roll = rollCh/3
  pitch = pitchCh/2
  yaw = yawCh
#endif --DEMO
end

local function symHome()
  local yawCh = 0
  local S2Ch = 0
  -- home angle in deg [0-360]
  S2Ch = getValue("ch12")
  yawCh = getValue("ch4")
#ifdef DEMO
  minmaxValues[MINMAX_ALT] = 45
  minmaxValues[MAX_VSPEED] = 4
  minmaxValues[MAX_HSPEED] = 77
  homeAlt = 24
  vSpeed = 22
  hSpeed = 34
#else --DEMO
  homeAlt = yawCh * 0.01
  range = 10 * yawCh * 0.1
  vSpeed = yawCh * 0.1 * -1
  hSpeed = vSpeed
#endif --DEMO  
  if ( yawCh >= 0) then
    yawCh = yawCh * 0.175
  else
    yawCh = 360 + (yawCh * 0.175)
  end
  yaw = yawCh
  if ( S2Ch >= 0) then
    S2Ch = S2Ch * 0.175
  else
    S2Ch = 360 + (S2Ch * 0.175)
  end
  if (thrOut > 0 ) then
    homeAngle = S2Ch
  else
    homeAngle = -1
  end
end

local function symMode()
  symGPS()
  symAttitude()
  symTimer()
  symHome()
  symBatt()
  symFrameType()
end
#endif --TESTMODE

-----------------------------------------------------------------
-- TELEMETRY
-----------------------------------------------------------------
#ifdef TELERATE
local telecounter = 0
local telerate = 0
local telestart = 0
#endif --TELERATE
#ifdef LOGTELEMETRY
local lastAttiLogTime = 0
#endif --LOGTELEMETRY
--
local function processTelemetry()
  local SENSOR_ID,FRAME_ID,DATA_ID,VALUE
#ifdef PLAYLOG
#endif
  SENSOR_ID,FRAME_ID,DATA_ID,VALUE = sportTelemetryPop()
  if ( FRAME_ID == 0x10) then
#ifdef LOGTELEMETRY
    -- log all pitch and roll at ma
    if lastAttiLogTime == 0 then
      logTelemetryToFile(SENSOR_ID,FRAME_ID,DATA_ID,VALUE)
      lastAttiLogTime = getTime()
    elseif DATA_ID == 0x5006 and getTime() - lastAttiLogTime > 50 then -- @2Hz
      logTelemetryToFile(SENSOR_ID,FRAME_ID,DATA_ID,VALUE)
      lastAttiLogTime = getTime()
    else
      logTelemetryToFile(SENSOR_ID,FRAME_ID,DATA_ID,VALUE)
    end
#endif --LOGTELEMETRY
#ifdef TELERATE
    ------------------------
    -- CALC ACTUAL TELE RATE
    ------------------------
    local now = getTime()/100
    if telecounter == 0 then
      telestart = now
    else
      telerate = telecounter / (now - telestart)
    end
    --
    telecounter=telecounter+1
#endif --TELERATE
    noTelemetryData = 0
    if ( DATA_ID == 0x5006) then -- ROLLPITCH
      -- roll [0,1800] ==> [-180,180]
      roll = (math.min(bit32.extract(VALUE,0,11),1800) - 900) * 0.2
      -- pitch [0,900] ==> [-90,90]
      pitch = (math.min(bit32.extract(VALUE,11,10),900) - 450) * 0.2
      -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
      range = bit32.extract(VALUE,22,10) * (10^bit32.extract(VALUE,21,1)) -- cm
    elseif ( DATA_ID == 0x5005) then -- VELANDYAW
      vSpeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1)) * (bit32.extract(VALUE,8,1) == 1 and -1 or 1)
      hSpeed = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      yaw = bit32.extract(VALUE,17,11) * 0.2
    elseif ( DATA_ID == 0x5001) then -- AP STATUS
      flightMode = bit32.extract(VALUE,0,5)
      simpleMode = bit32.extract(VALUE,5,2)
      landComplete = bit32.extract(VALUE,7,1)
      statusArmed = bit32.extract(VALUE,8,1)
      battFailsafe = bit32.extract(VALUE,9,1)
      ekfFailsafe = bit32.extract(VALUE,10,2)
      -- IMU temperature: 0 means temp =< 19°, 63 means temp => 82°
      imuTemp = bit32.extract(VALUE,26,6) + 19 -- C°
    elseif ( DATA_ID == 0x5002) then -- GPS STATUS
      numSats = bit32.extract(VALUE,0,4)
      -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
      -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
      gpsStatus = bit32.extract(VALUE,4,2) + bit32.extract(VALUE,14,2)
      gpsHdopC = bit32.extract(VALUE,7,7) * (10^bit32.extract(VALUE,6,1)) -- dm
      gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1) -- dm
    elseif ( DATA_ID == 0x5003) then -- BATT
      batt1volt = bit32.extract(VALUE,0,9)
      batt1current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt1mah = bit32.extract(VALUE,17,15)
#ifdef BATT2TEST
      batt2volt = bit32.extract(VALUE,0,9)
      batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt2mah = bit32.extract(VALUE,17,15)
#endif --BATT2TEST
    elseif ( DATA_ID == 0x5008) then -- BATT2
      batt2volt = bit32.extract(VALUE,0,9)
      batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt2mah = bit32.extract(VALUE,17,15)
    elseif ( DATA_ID == 0x5004) then -- HOME
      homeDist = bit32.extract(VALUE,2,10) * (10^bit32.extract(VALUE,0,2))
      homeAlt = bit32.extract(VALUE,14,10) * (10^bit32.extract(VALUE,12,2)) * 0.1 * (bit32.extract(VALUE,24,1) == 1 and -1 or 1) --m
      homeAngle = bit32.extract(VALUE, 25,  7) * 3
    elseif ( DATA_ID == 0x5000) then -- MESSAGES
      if (VALUE ~= lastMsgValue) then
        lastMsgValue = VALUE
        local c1 = bit32.extract(VALUE,0,7)
        local c2 = bit32.extract(VALUE,8,7)
        local c3 = bit32.extract(VALUE,16,7)
        local c4 = bit32.extract(VALUE,24,7)
        --
        local msgEnd = false
        if (c4 ~= 0) then
          msgBuffer = msgBuffer .. string.char(c4)
        else
          msgEnd = true;
        end
        if (c3 ~= 0 and not msgEnd) then
          msgBuffer = msgBuffer .. string.char(c3)
        else
          msgEnd = true;
        end
        if (c2 ~= 0 and not msgEnd) then
          msgBuffer = msgBuffer .. string.char(c2)
        else
          msgEnd = true;
        end
        if (c1 ~= 0 and not msgEnd) then
          msgBuffer = msgBuffer .. string.char(c1)
        else
          msgEnd = true;
        end
        --[[
        _msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x4)<<21;
        _msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x2)<<14;
        _msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x1)<<7;
        --]]
        if (msgEnd) then
          local severity = (bit32.extract(VALUE,7,1) * 1) + (bit32.extract(VALUE,15,1) * 2) + (bit32.extract(VALUE,23,1) * 4)
          pushMessage( severity, msgBuffer)
          msgBuffer = ""
        end
    end
    elseif ( DATA_ID == 0x5007) then -- PARAMS
      paramId = bit32.extract(VALUE,24,4)
      paramValue = bit32.extract(VALUE,0,24)
      if paramId == 1 then
        frameType = paramValue
      elseif paramId == 4 then
        batt1Capacity = paramValue
#ifdef BATT2TEST
        batt2Capacity = paramValue
#endif --BATT2TEST
      elseif paramId == 5 then
        batt2Capacity = paramValue
      end
    end
  end
end

#ifdef TESTMODE
local function telemetryEnabled()
  return true
end
#else --TESTMODE
local function telemetryEnabled()
  if getRSSI() == 0 then
    noTelemetryData = 1
  end
  return noTelemetryData == 0
end
#endif --TESTMODE

local function getMaxValue(value,idx)
  minmaxValues[idx] = math.max(value,minmaxValues[idx])
  return showMinMaxValues == true and minmaxValues[idx] or value
end

local function calcMinValue(value,min)
  return min == 0 and value or math.min(value,min)
end

-- returns the actual minimun only if both are > 0
local function getNonZeroMin(v1,v2)
  return v1 == 0 and v2 or ( v2 == 0 and v1 or math.min(v1,v2))
end

local function calcCellCount()
  -- cellcount override from menu
  if CONF_CELL_COUNT ~= nil and CONF_CELL_COUNT > 0 then
    return CONF_CELL_COUNT
  end
  -- cellcount is cached only for FLVSS
  if batt1sources.vs == true and cellcount > 1 then
    return cellcount
  end
  -- round in excess and return
  -- Note: cellcount is not cached because max voltage can rise during initialization)
  return math.floor( (( math.max(cell1maxFC,cellmaxA2)*0.1 ) / CELLFULL) + 1)
end

local function calcBattery()
  ------------
  -- FLVSS 1
  ------------
  local cellResult = getValue("Cels")
  if type(cellResult) == "table" then
    cell1min = CELLFULL
    cell1sum = 0
    -- cellcount is global and shared
    cellcount = #cellResult
    for i, v in pairs(cellResult) do
      cell1sum = cell1sum + v
      if cell1min > v then
        cell1min = v
      end
    end
    -- if connected after scritp started
    if batt1sources.vs == false then
      battsource = "na"
    end
    if battsource == "na" then
      battsource = "vs"
    end
    batt1sources.vs = true
  else
    batt1sources.vs = false
    cell1min = 0
    cell1sum = 0
  end
  ------------
  -- FLVSS 2
  ------------
#ifdef FLVSS2TEST
  cellResult = getValue("Cels")
#else --FLVSS2TEST
  cellResult = getValue("Cel2")
#endif --FLVSS2TEST
  if type(cellResult) == "table" then
    cell2min = CELLFULL
    cell2sum = 0
    -- cellcount is global and shared
    cellcount = #cellResult
    for i, v in pairs(cellResult) do
      cell2sum = cell2sum + v
      if cell2min > v then
        cell2min = v
      end
    end
    -- if connected after scritp started
    if batt2sources.vs == false then
      battsource = "na"
    end
    if battsource == "na" then
      battsource = "vs"
    end
    batt2sources.vs = true
  else
    batt2sources.vs = false
    cell2min = 0
    cell2sum = 0
  end
  --------------------------------
  -- flight controller battery 1
  --------------------------------
  if batt1volt > 0 then
    cell1sumFC = batt1volt*0.1
    cell1maxFC = math.max(batt1volt,cell1maxFC)
    if battsource == "na" then
      battsource = "fc"
    end
    batt1sources.fc = true
  else
    batt1sources.fc = false
    cell1sumFC = 0
  end
  --------------------------------
  -- flight controller battery 2
  --------------------------------
  if batt2volt > 0 then
    cell2sumFC = batt2volt*0.1
    if battsource == "na" then
      battsource = "fc"
    end
    batt2sources.fc = true
  else
    batt2sources.fc = false
    cell2sumFC = 0
  end
  ----------------------------------
  -- A2 analog voltage only 1 supported
  ----------------------------------
  local battA2 = getValue("A2")
  --
  if battA2 > 0 then
    cellsumA2 = battA2
    cellmaxA2 = math.max(battA2*10,cellmaxA2)
    -- don't force a2, only way to display it
    -- is by user selection from menu
    --[[
    if battsource == "na" then
      battsource = "a2"
    end
    --]]
    batt1sources.a2 = true
  else
    batt1sources.a2 = false
    cellsumA2 = 0
  end
  -- batt fc
  minmaxValues[MIN_BATT1_FC] = calcMinValue(cell1sumFC,minmaxValues[MIN_BATT1_FC])
  minmaxValues[MIN_BATT2_FC] = calcMinValue(cell2sumFC,minmaxValues[MIN_BATT2_FC])
  -- cell flvss
  minmaxValues[MIN_CELL1_VS] = calcMinValue(cell1min,minmaxValues[MIN_CELL1_VS])
  minmaxValues[MIN_CELL2_VS] = calcMinValue(cell2min,minmaxValues[MIN_CELL2_VS])
  -- batt flvss
  minmaxValues[MIN_BATT1_VS] = calcMinValue(cell1sum,minmaxValues[MIN_BATT1_VS])
  minmaxValues[MIN_BATT2_VS] = calcMinValue(cell2sum,minmaxValues[MIN_BATT2_VS])
  -- batt A2
  minmaxValues[MIN_BATT_A2] = calcMinValue(cellsumA2,minmaxValues[MIN_BATT_A2])
end

local function checkLandingStatus()
  if ( timerRunning == 0 and landComplete == 1 and lastTimerStart == 0) then
    startTimer()
  end
  if (timerRunning == 1 and landComplete == 0 and lastTimerStart ~= 0) then
    stopTimer()
    -- play landing complete only if motorts are armed
    if statusArmed == 1 then
      playSound("landing")
    end
  end
  timerRunning = landComplete
end

local function calcFlightTime() 
  -- update local variable with timer 3 value
  flightTime = model.getTimer(2).value
end

local function getBatt1Capacity()
  return CONF_BATT_CAP1 > 0 and CONF_BATT_CAP1*100 or batt1Capacity  
end

local function getBatt2Capacity()
  return CONF_BATT_CAP2 > 0 and CONF_BATT_CAP2*100 or batt2Capacity  
end

-- gets the voltage based on source and min value, battId = [1|2]
local function getMinVoltageBySource(source,cell,cellFC,cellA2,battId,count)
  -- offset 0 for cell voltage, 2 for pack voltage
  local offset = 0
  --
  if cell > CELLFULL*2 or cellFC > CELLFULL*2 or cellA2 > CELLFULL*2 then
    offset = 2
  end
  --
  if source == "vs" then
    return showMinMaxValues == true and minmaxValues[2+offset+battId] or cell
  elseif source == "fc" then
      -- FC only tracks batt1 and batt2 no cell voltage tracking
      local minmax = (offset == 2 and minmaxValues[battId] or minmaxValues[battId]/count)
      return showMinMaxValues == true and minmax or cellFC
  elseif source == "a2" then
      -- A2 does not depend on battery id
      local minmax = (offset == 2 and minmaxValues[MIN_BATT_A2] or minmaxValues[MIN_BATT_A2]/count)
      return showMinMaxValues == true and minmax or cellA2
  end
  --
  return 0
end

local function setSensorValues()
  if (not telemetryEnabled()) then
    return
  end
  local battmah = batt1mah
  local battcapacity = getBatt1Capacity()
  if batt2mah > 0 then
    battcapacity =  getBatt1Capacity() + getBatt2Capacity()
    battmah = batt1mah + batt2mah
  end
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    end  
  end
  setTelemetryValue(Fuel_ID, Fuel_SUBID, Fuel_INSTANCE, perc, 13 , Fuel_PRECISION , Fuel_NAME)
  setTelemetryValue(VFAS_ID, VFAS_SUBID, VFAS_INSTANCE, getNonZeroMin(batt1volt,batt2volt)*10, 1 , VFAS_PRECISION , VFAS_NAME)
  setTelemetryValue(CURR_ID, CURR_SUBID, CURR_INSTANCE, batt1current+batt2current, 2 , CURR_PRECISION , CURR_NAME)
  setTelemetryValue(VSpd_ID, VSpd_SUBID, VSpd_INSTANCE, vSpeed, 5 , VSpd_PRECISION , VSpd_NAME)
  setTelemetryValue(GSpd_ID, GSpd_SUBID, GSpd_INSTANCE, hSpeed*0.1, 4 , GSpd_PRECISION , GSpd_NAME)
  setTelemetryValue(Alt_ID, Alt_SUBID, Alt_INSTANCE, homeAlt*10, 9 , Alt_PRECISION , Alt_NAME)
  setTelemetryValue(GAlt_ID, GAlt_SUBID, GAlt_INSTANCE, math.floor(gpsAlt*0.1), 9 , GAlt_PRECISION , GAlt_NAME)
  setTelemetryValue(Hdg_ID, Hdg_SUBID, Hdg_INSTANCE, math.floor(yaw), 20 , Hdg_PRECISION , Hdg_NAME)
  setTelemetryValue(IMUTmp_ID, IMUTmp_SUBID, IMUTmp_INSTANCE, imuTemp, 11 , IMUTmp_PRECISION , IMUTmp_NAME)
  setTelemetryValue(ARM_ID, ARM_SUBID, ARM_INSTANCE, statusArmed*100, 0 , ARM_PRECISION , ARM_NAME)
end
--------------------
-- Single long function much more memory efficient than many little functions
---------------------
#ifdef X9
local function drawX9BatteryPane(x,battVolt,cellVolt,current,battmah,battcapacity)
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    end
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if showMinMaxValues == false then
    if battLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif battLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  drawNumberWithTwoDims(x+BATTCELL_X, BATTCELL_Y, BATTCELL_YV, BATTCELL_YS,cellVolt,"V",battsource,BATTCELL_FLAGS+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(x+BATTVOLT_X,BATTVOLT_Y,BATTVOLT_YV, battVolt,"V",BATTVOLT_FLAGS,BATTVOLT_FLAGSV)
  -- battery current
  drawNumberWithDim(x+BATTCURR_X,BATTCURR_Y,BATTCURR_YA,current,"A",BATTCURR_FLAGS,BATTCURR_FLAGSA)
  -- battery percentage
  lcd.drawNumber(x+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
  -- display capacity bar %
  lcd.drawFilledRectangle(x+BATTGAUGE_X, BATTGAUGE_Y, 2 + math.floor(perc * 0.01 * (BATTGAUGE_WIDTH - 3)), BATTGAUGE_HEIGHT, SOLID)
  lcd.drawRectangle(x+BATTGAUGE_X, BATTGAUGE_Y, 2 + math.floor(perc * 0.01 * (BATTGAUGE_WIDTH - 3)), BATTGAUGE_HEIGHT, SOLID)
  local step = BATTGAUGE_WIDTH/BATTGAUGE_STEPS
  for s=1,BATTGAUGE_STEPS - 1 do
    lcd.drawLine(x+BATTGAUGE_X + s*step - 1,BATTGAUGE_Y, x+BATTGAUGE_X + s*step - 1, BATTGAUGE_Y + BATTGAUGE_HEIGHT - 1,SOLID,0)
  end
  -- battery mah
  lcd.drawNumber(x+BATTMAH_X, BATTMAH_Y, battmah/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "/", SMLSIZE)
  lcd.drawNumber(lcd.getLastRightPos(), BATTMAH_Y, battcapacity/100, BATTMAH_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "Ah", SMLSIZE)
  if showMinMaxValues == true then
    drawVArrow(x+BATTVOLT_X+29,BATTVOLT_Y + 6, 5,false,true)
    drawVArrow(x+BATTCURR_X+27,BATTCURR_Y + 6,5,true,false)
    drawVArrow(x+BATTCELL_X+37, BATTCELL_Y + 3,6,false,true)
  end
end
#endif

#ifdef X7
local function drawX7RightPane(x,battVolt,cellVolt,current,battmah,battcapacity)
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    end
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if showMinMaxValues == false then
    if battLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif battLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  drawNumberWithTwoDims(x+BATTCELL_X, BATTCELL_Y, BATTCELL_YV, BATTCELL_YS,cellVolt,"V",battsource,BATTCELL_FLAGS+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(x+BATTVOLT_X,BATTVOLT_Y,BATTVOLT_YV, battVolt,"V",BATTVOLT_FLAGS,BATTVOLT_FLAGSV)
  -- battery current
  drawNumberWithDim(x+BATTCURR_X,BATTCURR_Y,BATTCURR_YA,current,"A",BATTCURR_FLAGS,BATTCURR_FLAGSA)
  -- battery percentage
  lcd.drawNumber(x+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
  -- battery mah
  lcd.drawText(x+BATTMAH_X, BATTMAH_Y, "Ah", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y, battmah/10, SMLSIZE+PREC2+RIGHT)
  lcd.drawText(x+BATTMAH_X, BATTMAH_Y+8, "Ah", SMLSIZE+RIGHT+INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y+8, battcapacity/10, SMLSIZE+PREC2+RIGHT+INVERS)
  -- tx voltage
  --local vTx = string.format("Tx%.1fv",getValue(getFieldInfo("tx-voltage").id))
  --lcd.drawText(TXVOLTAGE_X, TXVOLTAGE_Y, vTx, TXVOLTAGE_FLAGS)
  --
  -- GPS status
  local strStatus = gpsStatuses[gpsStatus]
  flags = BLINK+PREC1
  local mult = 1
  lcd.drawLine(GPS_X + 38,GPS_Y+1,GPS_X+38,GPS_Y+19,SOLID,FORCE)
  lcd.drawLine(GPS_X + 38,GPS_Y + 20,GPS_X+63,GPS_Y + 20,SOLID,FORCE)
  if gpsStatus  > 2 then
    if homeAngle ~= -1 then
      flags = PREC1
    end
    if gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(GPS_X + 40,GPS_Y+13, strStatus, SMLSIZE)
    local strNumSats = string.format("%d",math.min(15,numSats))
    --if numSats >= 15 then
    --  strNumSats = strNumSats.."+"
    --end
    lcd.drawText(GPS_X + 63, GPS_Y + 13, strNumSats, SMLSIZE+RIGHT)
    lcd.drawText(GPS_X + 40, GPS_Y + 2 , "H", SMLSIZE)
    lcd.drawNumber(GPS_X + 63, GPS_Y+1, gpsHdopC*mult ,MIDSIZE+flags+RIGHT)
    
  else
    lcd.drawText(GPS_X + 46, GPS_Y+3, "No", SMLSIZE+INVERS+BLINK)
    lcd.drawText(GPS_X + 43, GPS_Y+12, strStatus, SMLSIZE+INVERS+BLINK)
  end
  -- alt asl/rng
  if showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
    flags = 0
  if CONF_RANGE_MAX > 0 then
    -- rng finder
    local rng = range
    -- rng is cm
    if rng > CONF_RANGE_MAX then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,MAX_RANGE)
    --
    if showMinMaxValues == true then
      drawVArrow(ALTASL_XLABEL + 1, ALTASL_YLABEL,5,true,false)
    else
      lcd.drawText(ALTASL_XLABEL - 1, ALTASL_YLABEL, "Rn", SMLSIZE)
    end
#ifdef UNIT_SCALE
    lcd.drawText(ALTASL_X, ALTASL_Y+1 , UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos(), ALTASL_Y , string.format("%.1f",rng*0.01*UNIT_ALT_SCALE), flags + RIGHT)
#else
    lcd.drawText(ALTASL_X, ALTASL_Y+1 , "m", SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos(), ALTASL_Y, string.format("%.2f",rng*0.01), flags + RIGHT)
#endif --UNIT_SCALE
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = gpsAlt/10
    flags = BLINK
    if gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,MAX_GPSALT)
    end
    if showMinMaxValues == true then
      drawVArrow(ALTASL_XLABEL + 1, ALTASL_YLABEL + 1,5,true,false)
    else
      drawVArrow(ALTASL_XLABEL + 1,ALTASL_YLABEL,6,true,true)
    end
#ifdef UNIT_SCALE    
    lcd.drawText(ALTASL_X, ALTASL_Y+1 ,UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos(), ALTASL_Y , string.format("%d",alt*UNIT_ALT_SCALE), flags+RIGHT)
#else --UNIT_SCALE   
    lcd.drawText(ALTASL_X, ALTASL_Y+1 ,"m", SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos(), ALTASL_Y , string.format("%d",alt), flags+RIGHT)
#endif --UNIT_SCALE
  end
  -- home dist
  local flags = 0
  if homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(homeDist,MAX_DIST)
  if showMinMaxValues == true then
    flags = 0
  end
#ifdef UNIT_SCALE
  lcd.drawText(HOMEDIST_X, HOMEDIST_Y+1, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawText(lcd.getLastLeftPos(), HOMEDIST_Y, string.format("%d",dist*UNIT_DIST_SCALE),HOMEDIST_FLAGS+flags)
#else --UNIT_SCALE
  lcd.drawText(HOMEDIST_X, HOMEDIST_Y+1, "m",SMLSIZE+RIGHT)
  lcd.drawText(lcd.getLastLeftPos(), HOMEDIST_Y, string.format("%d",dist),HOMEDIST_FLAGS+flags)
#endif --UNIT_SCALE
  if showMinMaxValues == true then
    drawVArrow(HOMEDIST_XLABEL + 2, HOMEDIST_YLABEL,5,true,false)
    drawVArrow(x+BATTCELL_X+36, BATTCELL_Y+2,6,false,true)
  else
    drawHArrow(HOMEDIST_XLABEL,HOMEDIST_YLABEL + 3,HOMEDIST_ARROW_WIDTH,true,true)
  end
end
#endif

#ifdef X7
---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawX7LeftPane(battVolt,cellVolt,current,battmah,battcapacity)
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
  else
    perc = 0
  end
  if perc > 99 then
    perc = 99
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if showMinMaxValues == false then
    if cellVolt < CONF_BATT_LEVEL2 then
      flags = BLINK
      dimFlags = BLINK
    elseif cellVolt < CONF_BATT_LEVEL1 then
      dimFlags = BLINK+INVERS
    end  
  end
  drawNumberWithTwoDims(0, BATTCELL_Y, BATTCELL_YV, BATTCELL_YS,cellVolt,"V",battsource,BATTCELL_FLAGS+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(41+BATTVOLT_X,BATTVOLT_Y,BATTVOLT_YV, battVolt,"V",BATTVOLT_FLAGS,BATTVOLT_FLAGSV)
  -- battery current
  drawNumberWithDim(41+BATTCURR_X,BATTCURR_Y,BATTCURR_YA,current,"A",BATTCURR_FLAGS,BATTCURR_FLAGSA)
  -- battery percentage
  lcd.drawNumber(38+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos(), BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
  -- box
  lcd.drawRectangle(0,BATTMAH_Y + 7,6,7,SOLID)
  lcd.drawFilledRectangle(0,BATTMAH_Y + 7,6,7,SOLID)
  -- battery mah
  lcd.drawText(-30+BATTMAH_X, BATTMAH_Y, "Ah", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y, battmah/10, SMLSIZE+PREC2+RIGHT)
  lcd.drawText(-30+BATTMAH_X, BATTMAH_Y+8, "Ah", SMLSIZE+RIGHT+INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTMAH_Y+8, battcapacity/10, SMLSIZE+PREC2+RIGHT+INVERS)
  if showMinMaxValues == true then
    drawVArrow(36, BATTCELL_Y+2,6,false,true)
  end
end
#endif --X7

local function drawNoTelemetryData()
  -- no telemetry data
#ifdef X9
  if (not telemetryEnabled()) then
    lcd.drawFilledRectangle((212-130)/2,18, 130, 30, SOLID)
    lcd.drawRectangle((212-130)/2,18, 130, 30, ERASE)
    lcd.drawText(60, 29, "no telemetry data", INVERS)
    return
  end
#else
  if (not telemetryEnabled()) then
    lcd.drawFilledRectangle(12,18, 105, 30, SOLID)
    lcd.drawRectangle(12,18, 105, 30, ERASE)
    lcd.drawText(30, 29, "no telemetry", INVERS)
    return
  end
#endif --X9
end

local function drawTopBar()
  -- black bar
  lcd.drawFilledRectangle(0,TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  lcd.drawRectangle(0, TOPBAR_Y, TOPBAR_WIDTH, 7, SOLID)
  -- flight mode
  if frame.flightModes then
    local strMode = frame.flightModes[flightMode]
    if strMode ~= nil then
      lcd.drawText(FLIGHTMODE_X, FLIGHTMODE_Y, strMode, FLIGHTMODE_FLAGS)
      if ( simpleMode > 0 ) then
        local strSimpleMode = simpleMode == 1 and "(S)" or "(SS)"
        lcd.drawText(lcd.getLastRightPos(), FLIGHTMODE_Y, strSimpleMode, FLIGHTMODE_FLAGS)
      end
    end  
  end
  -- flight time
  lcd.drawText(FLIGHTTIME_X, FLIGHTTIME_Y, "T:", FLIGHTTIME_FLAGS)
  lcd.drawTimer(lcd.getLastRightPos(), FLIGHTTIME_Y, flightTime, FLIGHTTIME_FLAGS)
  -- RSSI
  lcd.drawText(RSSI_X, RSSI_Y, "RS:", RSSI_FLAGS)
#ifdef DEMO
  lcd.drawText(lcd.getLastRightPos(), RSSI_Y, 87, RSSI_FLAGS)  
#else --DEMO
  lcd.drawText(lcd.getLastRightPos(), RSSI_Y, getRSSI(), RSSI_FLAGS)  
#endif --DEMO
#ifdef X9
  -- tx voltage
  local vTx = string.format("Tx%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(TXVOLTAGE_X, TXVOLTAGE_Y, vTx, TXVOLTAGE_FLAGS)
#endif --X9
end

local function drawBottomBar()
  -- black bar
  lcd.drawFilledRectangle(0,BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  lcd.drawRectangle(0, BOTTOMBAR_Y, BOTTOMBAR_WIDTH, 8, SOLID)
  -- message text
  local now = getTime()
  local msg = messages[#messages]
#ifdef X9
  if (now - lastMsgTime ) > 150 or CONF_DISABLE_MSGBLINK then
    lcd.drawText(0, BOTTOMBAR_Y+1, msg,SMLSIZE+INVERS)
  else
    lcd.drawText(0, BOTTOMBAR_Y+1, msg,SMLSIZE+INVERS+BLINK)
  end
#endif --X9
#ifdef X7
  if (now - lastMsgTime ) > 150 or CONF_DISABLE_MSGBLINK then
    lcd.drawText(0, BOTTOMBAR_Y + 1,  msg,SMLSIZE+INVERS)
  else
    lcd.drawText(0, BOTTOMBAR_Y + 1,  msg,SMLSIZE+INVERS+BLINK)
  end
#endif --X7
end

local function drawAllMessages()
  for i=1,#messages do
    lcd.drawText(1, 1 + 7*(i-1), messages[i],SMLSIZE)
  end
end

#ifdef X9
local function drawX9LeftPane(battcurrent,cellsumFC)
  -- gps status
  local strStatus = gpsStatuses[gpsStatus]
  local strNumSats = ""
  local flags = BLINK
  local mult = 1
  if gpsStatus  > 2 then
    if homeAngle ~= -1 then
      flags = PREC1
    end
    if gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(GPS_X,GPS_Y + 2, strStatus, SMLSIZE)
    lcd.drawText(GPS_X,GPS_Y + 8, "fix", SMLSIZE)
    if numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",numSats)
    end
    lcd.drawText(GPS_X + 40, GPS_Y + 2, strNumSats, MIDSIZE+RIGHT)
    lcd.drawText(GPS_X + 42, GPS_Y + 2 , "H", SMLSIZE)
    lcd.drawNumber(GPS_X + 66, GPS_Y + 2, gpsHdopC*mult , MIDSIZE+flags+RIGHT)
    lcd.drawLine(GPS_X + 40,GPS_Y+1,GPS_X+40,GPS_Y + 14,SOLID,FORCE)
  else
    lcd.drawText(GPS_X + 10, GPS_Y + 2, strStatus, MIDSIZE+INVERS+BLINK)
  end  
  lcd.drawLine(GPS_X ,GPS_Y + 15,GPS_X+66,GPS_Y + 15,SOLID,FORCE)
  if showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
  drawVArrow(ALTASL_XLABEL,ALTASL_YLABEL - 1,7,true,true)
  if CONF_RANGE_MAX > 0 then
    -- rng finder
    flags = 0
    local rng = range
    -- rng is centimeters, RANGE_MAX is feet
    if rng > CONF_RANGE_MAX then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,MAX_RANGE)
    lcd.drawText(ALTASL_XLABEL + 4, ALTASL_YLABEL, "Rng", SMLSIZE)
#ifdef UNIT_SCALE
    lcd.drawText(ALTASL_X, ALTASL_Y , UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos()-1, ALTASL_Y-1 , string.format("%.2f",rng*0.01*UNIT_ALT_SCALE), ALTASL_FLAGS+flags)
#else --UNIT_SCALE
    lcd.drawText(ALTASL_X, ALTASL_Y , "m", SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos()-1, ALTASL_Y-1 , string.format("%.2f",rng*0.01), ALTASL_FLAGS+flags)
#endif --UNIT_SCALE
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = gpsAlt/10 -- meters
    flags = BLINK
    if gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,MAX_GPSALT)
    end
    lcd.drawText(ALTASL_XLABEL + 4, ALTASL_YLABEL, "Asl", SMLSIZE)
#ifdef UNIT_SCALE    
    lcd.drawText(ALTASL_X, ALTASL_Y, UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos()-1, ALTASL_Y-1 , string.format("%d",alt*UNIT_ALT_SCALE), ALTASL_FLAGS+flags)
#else --UNIT_SCALE
    lcd.drawText(ALTASL_X, ALTASL_Y , "m", SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos()-1, ALTASL_Y-1 , string.format("%d",alt), ALTASL_FLAGS+flags)
#endif --UNIT_SCALE
  end
  -- home distance
  drawHomeIcon(HOMEDIST_XLABEL + 1,HOMEDIST_YLABEL,7)
  drawHArrow(HOMEDIST_XLABEL + 10,HOMEDIST_YLABEL + 2,HOMEDIST_ARROW_WIDTH,true,true)
  flags = 0
  if homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(homeDist,MAX_DIST)
  if showMinMaxValues == true then
    flags = 0
  end
#ifdef UNIT_SCALE
  lcd.drawText(HOMEDIST_X, HOMEDIST_Y-1, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, HOMEDIST_Y-1, dist*UNIT_DIST_SCALE, HOMEDIST_FLAGS+flags)
#else --UNIT_SCALE
  lcd.drawText(HOMEDIST_X, HOMEDIST_Y-1, "m",SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, HOMEDIST_Y-1, dist, HOMEDIST_FLAGS+flags)
#endif --UNIT_SCALE
#ifdef EFFICIENCY
  -- efficiency
  local eff = hSpeed*0.1 > 2 and 1000*battcurrent*0.1/(hSpeed*0.1*UNIT_HSPEED_SCALE) or 0
  lcd.drawText(BATTPOWER_XLABEL, BATTPOWER_YLABEL, "Eff", SMLSIZE)
  lcd.drawText(BATTPOWER_X,BATTPOWER_Y,string.format("%d mAh",eff),BATTPOWER_FLAGS)
#else --EFFICIENCY
  -- power
  local power = cellsumFC*battcurrent*0.1
  power = getMaxValue(power,MAX_POWER)
  lcd.drawText(BATTPOWER_XLABEL, BATTPOWER_YLABEL, "PWR", SMLSIZE)
  lcd.drawText(BATTPOWER_X,BATTPOWER_Y,string.format("%d w",power),BATTPOWER_FLAGS)
#endif --EFFICIENCY
#ifdef FRAMETYPE
  local fn = frameNames[frameType]
  if fn ~= nil then
    lcd.drawText(0,39,fn,SMLSIZE+INVERS)
  end
#ifdef DEBUG
  lcd.drawNumber(lcd.getLastRightPos() + 1,39,frameType,SMLSIZE+INVERS)
#endif --DEBUG
#endif --FRAMETYPE
  if showMinMaxValues == true then
#ifndef EFFICIENCY
    drawVArrow(BATTPOWER_XLABEL + 23, BATTPOWER_Y, 5,true,false)
#endif --EFFICIENCY
    drawVArrow(HOMEDIST_XLABEL + 23, HOMEDIST_Y - 2,6,true,false)
    drawVArrow(ALTASL_XLABEL + 21, ALTASL_Y - 2,6,true,false)
  end
end
#endif --X9

local function drawFailsafe()
  local xoffset = 0
  local yoffset = 0
#ifdef X7
  if showDualBattery == true and (ekfFailsafe > 0 or battFailsafe >0) then
    xoffset = 36
    yoffset = -10
    lcd.drawFilledRectangle(xoffset - 8, 18 + yoffset, 80, 15, ERASE)
    lcd.drawRectangle(xoffset - 8, 18 + yoffset, 80, 15, SOLID)
  end
#endif --X7
  if ekfFailsafe > 0 then
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 31, 22 + yoffset, " EKF FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
  if battFailsafe > 0 then
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 33, 22 + yoffset, " BATT FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
end

#ifdef X9
#define YAW_STEPWIDTH 17
#else
#define YAW_STEPWIDTH 13.2
#endif --X9

local yawRibbonPoints = {}
--
yawRibbonPoints[0]={"N",0}
yawRibbonPoints[1]={"NE",-3}
yawRibbonPoints[2]={"E",0}
yawRibbonPoints[3]={"SE",-3}
yawRibbonPoints[4]={"S",0}
yawRibbonPoints[5]={"SW",-3}
yawRibbonPoints[6]={"W",0}
yawRibbonPoints[7]={"NW",-3}

-- optimized yaw ribbon drawing
local function drawCompassRibbon()
  -- ribbon centered +/- 90 on yaw
  local centerYaw = (yaw+270)%360
  -- this is the first point left to be drawn on the compass ribbon
  local nextPoint = math.floor(centerYaw/45) * 45 --roundTo(centerYaw,45)
  -- distance in degrees between leftmost ribbon point and first 45° multiple normalized to YAW_WIDTH/8
#ifdef X9
  local yawMinX = (LCD_W - HUD_WIDTH)/2 + 2
  local yawMaxX = (LCD_W + HUD_WIDTH)/2 - 3
#else
  local yawMinX = 2
  local yawMaxX = HUD_WIDTH - 3
#endif --X9
  -- x coord of first ribbon letter
  local nextPointX = yawMinX + (nextPoint - centerYaw)/45 * YAW_STEPWIDTH
  local yawY = TOPBAR_Y + TOPBAR_HEIGHT
  --
  local i = (nextPoint / 45) % 8
  for idx=1,6
  do
      if nextPointX >= yawMinX and nextPointX < yawMaxX then
        lcd.drawText(nextPointX+yawRibbonPoints[i][2],yawY,yawRibbonPoints[i][1],SMLSIZE)
      end
      i = (i + 1) % 8
      nextPointX = nextPointX + YAW_STEPWIDTH
  end
  -- home icon
  local leftYaw = (yaw + 180)%360
  local rightYaw = yaw%360
  local centerHome = (homeAngle+270)%360
  --
  local homeIconX = yawMinX
  local homeIconY = yawY + 10
#ifdef X9
  if rightYaw >= leftYaw then
    if centerHome > leftYaw and centerHome < rightYaw then
      drawHomeIcon(math.min(yawMinX + ((centerHome - leftYaw)/180)*HUD_WIDTH,yawMaxX - 2),homeIconY)
    end
  else
    if centerHome < rightYaw then
      drawHomeIcon(yawMinX + (((360-leftYaw) + centerHome)/180)*HUD_WIDTH,homeIconY)
    elseif centerHome >= leftYaw then
      drawHomeIcon(math.min(yawMinX + ((centerHome-leftYaw)/180)*HUD_WIDTH,yawMaxX-2),homeIconY)
    end
  end
#else
  if rightYaw >= leftYaw then
    if centerHome > leftYaw and centerHome < rightYaw then
      drawHomeIcon(math.min(yawMinX + ((centerHome - leftYaw)/180)*HUD_WIDTH,yawMaxX - 2),homeIconY)
    end
  else
    if centerHome < rightYaw then
      drawHomeIcon(math.min(yawMinX + (((360-leftYaw) + centerHome)/180)*HUD_WIDTH,yawMaxX-2),homeIconY)
    elseif centerHome >= leftYaw then
      drawHomeIcon(math.min(yawMinX + ((centerHome-leftYaw)/180)*HUD_WIDTH,yawMaxX-2),homeIconY)
    end
  end
#endif
  -- when abs(home angle) > 90 draw home icon close to left/right border
  local angle = homeAngle - yaw
  local cos = math.cos(math.rad(angle - 90))    
  local sin = math.sin(math.rad(angle - 90))    
  if sin > 0 then
    drawHomeIcon(( cos > 0 and yawMaxX or yawMinX ) - 2, yawY + 10)
  end
  --
  lcd.drawLine(yawMinX - 2, yawY + 7, yawMaxX + 2, yawY + 7, SOLID, 0)
  local xx = yaw < 10 and 1 or ( yaw < 100 and -2 or -5 )
#ifdef X9
  lcd.drawNumber(LCD_W/2 + xx - 4, yawY, yaw, MIDSIZE+INVERS)
#else
  lcd.drawNumber(HUD_WIDTH/2 + xx - 4, yawY, yaw, MIDSIZE+INVERS)
#endif
end

#ifdef UNIT_SCALE
#define LEFTWIDTH   20
#else --UNIT_SCALE
#define LEFTWIDTH   17
#endif --UNIT_SCALE
#define RIGHTWIDTH  17
-- vertical distance between roll horiz segments
#define R2 6
--
local function drawHud()
  local r = -roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( roll == 0) then
    dx=0
    dy=pitch
    cx=0
    cy=R2
    ccx=0
    ccy=2*R2
    cccx=0
    cccy=3*R2
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -pitch
    dy = math.sin(math.rad(90 - r)) * pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * R2
    cy = math.sin(math.rad(90 - r)) * R2
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * R2
    ccy = math.sin(math.rad(90 - r)) * 2 * R2
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * R2
    cccy = math.sin(math.rad(90 - r)) * 3 * R2
  end
  local rollX = math.floor(HUD_X + HUD_WIDTH/2)
  -- parallel lines above and below horizon of increasing length 5,7,16,16,7,5
#ifdef CS_LINES
  drawLineWithClipping(rollX + dx - cccx,dy + HUD_X_MID + cccy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawLineWithClipping(rollX + dx - ccx,dy + HUD_X_MID + ccy,r,7,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawLineWithClipping(rollX + dx - cx,dy + HUD_X_MID + cy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawLineWithClipping(rollX + dx + cx,dy + HUD_X_MID - cy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawLineWithClipping(rollX + dx + ccx,dy + HUD_X_MID - ccy,r,7,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawLineWithClipping(rollX + dx + cccx,dy + HUD_X_MID - cccy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
#else
  drawCroppedLine(rollX + dx - cccx,dy + HUD_X_MID + cccy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawCroppedLine(rollX + dx - ccx,dy + HUD_X_MID + ccy,r,7,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawCroppedLine(rollX + dx - cx,dy + HUD_X_MID + cy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawCroppedLine(rollX + dx + cx,dy + HUD_X_MID - cy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawCroppedLine(rollX + dx + ccx,dy + HUD_X_MID - ccy,r,7,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
  drawCroppedLine(rollX + dx + cccx,dy + HUD_X_MID - cccy,r,16,DOTTED,HUD_X,HUD_X + HUD_WIDTH,yPos,BOTTOMBAR_Y - 1)
#endif  
  -----------------------
  -- dark color for "ground"
  -----------------------
#ifdef X9
  local minY = 16
  local maxY = 54
  local minX = HUD_X + 1
  local maxX = HUD_X + HUD_WIDTH - 2
  --
  local ox = 106 + dx
#endif --X9
#ifdef X7
  local minY = 16
  local maxY = 55
  local minX = HUD_X + 1
  local maxX = HUD_X + HUD_WIDTH - 2
  --
  local ox = (HUD_X + HUD_WIDTH)/2 + dx
#endif --X7
  --
  local oy = HUD_X_MID + dy
  local yy = 0
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-roll))
  -- for each pixel of the hud base/top draw vertical black 
  -- lines from hud border to horizon line
  -- horizon line moves with pitch/roll
  for xx= minX,maxX
  do
    if roll > 90 or roll < -90 then
      yy = (oy - ox*angle) + math.floor(xx*angle)
      if yy <= minY then
      elseif yy > minY + 1 and yy < maxY then
        lcd.drawLine(0 + xx, 0 + minY, 0 + xx, 0 + yy,SOLID,0)
      elseif yy >= maxY then
        lcd.drawLine(0 + xx, 0 + minY, 0 + xx, 0 + maxY,SOLID,0)
      end
    else
      yy = (oy - ox*angle) + math.floor(xx*angle)
      if yy <= minY then
        lcd.drawLine(0 + xx, 0 + minY, 0 + xx, 0 + maxY,SOLID,0)
      elseif yy >= maxY then
      else
        lcd.drawLine(0 + xx, 0 + yy, 0 + xx, 0 + maxY,SOLID,0)
      end
    end
  end
  ------------------------------------
  -- synthetic vSpeed based on 
  -- home altitude when EKF is disabled
  -- updated at 1Hz (i.e every 1000ms)
  -------------------------------------
  if CONF_ENABLE_SYNTHVSPEED == true then
    if (synthVSpeedTime == 0) then
      -- first time do nothing
      synthVSpeedTime = getTime()
      prevHomeAlt = homeAlt -- dm
    elseif (getTime() - synthVSpeedTime > 100) then
      -- calc vspeed
      vspd = 1000*(homeAlt-prevHomeAlt)/(getTime()-synthVSpeedTime) -- m/s
      -- update counters
      synthVSpeedTime = getTime()
      prevHomeAlt = homeAlt -- m
    end
  else
    vspd = vSpeed
  end
  -------------------------------------
  -- vario indicator on left
  -------------------------------------
  lcd.drawFilledRectangle(HUD_X, yPos, 7, 50, ERASE, 0)
  lcd.drawLine(HUD_X + 5, yPos, HUD_X + 5, yPos + 40, SOLID, FORCE)
  local varioMax = math.log(10)
  local varioSpeed = math.log(1+math.min(math.abs(0.1*vspd),10))
  local varioY = 0
  if vspd > 0 then
    varioY = HUD_X_MID - 4 - varioSpeed/varioMax*15
  else
    varioY = HUD_X_MID + 6
  end
  lcd.drawFilledRectangle(HUD_X, varioY, 5, varioSpeed/varioMax*15, FORCE, 0)
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- lets erase to hide the artificial horizon lines
  -- black borders
  lcd.drawRectangle(HUD_X, HUD_X_MID - 5, LEFTWIDTH, 11, FORCE, 0)
  lcd.drawRectangle(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1, HUD_X_MID - 5, RIGHTWIDTH+1, 11, FORCE, 0)
  -- erase area
  lcd.drawFilledRectangle(HUD_X, HUD_X_MID - 4, LEFTWIDTH, 9, ERASE, 0)
  lcd.drawFilledRectangle(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1, HUD_X_MID - 4, RIGHTWIDTH+2, 9, ERASE, 0)
  -- erase tips
  lcd.drawLine(HUD_X + LEFTWIDTH,HUD_X_MID - 3,HUD_X + LEFTWIDTH,HUD_X_MID + 3, SOLID, ERASE)
  lcd.drawLine(HUD_X + LEFTWIDTH+1,HUD_X_MID - 2,HUD_X + LEFTWIDTH+1,HUD_X_MID + 2, SOLID, ERASE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 2,HUD_X_MID - 3,HUD_X + HUD_WIDTH - RIGHTWIDTH - 2,HUD_X_MID + 3, SOLID, ERASE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID - 2,HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID + 2, SOLID, ERASE)
  -- left tip
  lcd.drawLine(HUD_X + LEFTWIDTH+2,HUD_X_MID - 2,HUD_X + LEFTWIDTH+2,HUD_X_MID + 2, SOLID, FORCE)
  lcd.drawLine(HUD_X + LEFTWIDTH-1,HUD_X_MID - 5,HUD_X + LEFTWIDTH+1,HUD_X_MID - 3, SOLID, FORCE)
  lcd.drawLine(HUD_X + LEFTWIDTH-1,HUD_X_MID + 5,HUD_X + LEFTWIDTH+1,HUD_X_MID + 3, SOLID, FORCE)
  -- right tip
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 4,HUD_X_MID - 2,HUD_X + HUD_WIDTH - RIGHTWIDTH - 4,HUD_X_MID + 2, SOLID, FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID - 3,HUD_X + HUD_WIDTH - RIGHTWIDTH - 1,HUD_X_MID - 5, SOLID, FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID + 3,HUD_X + HUD_WIDTH - RIGHTWIDTH - 1,HUD_X_MID + 5, SOLID, FORCE)
    -- altitude
#ifdef UNIT_SCALE
  local alt = getMaxValue(homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE -- homeAlt is meters*3.28 = feet
#else
  local alt = getMaxValue(homeAlt,MINMAX_ALT) -- homeAlt is meters
#endif
  --
  if math.abs(alt) < 10 then
      lcd.drawNumber(HUD_X + HUD_WIDTH,HUD_X_MID - 3,alt * 10,SMLSIZE+PREC1+RIGHT)
  else
      lcd.drawNumber(HUD_X + HUD_WIDTH,HUD_X_MID - 3,alt,SMLSIZE+RIGHT)
  end
  -- vertical speed
#ifdef UNIT_SCALE
  if math.abs(vspd*3.28*60) > 99 then
    lcd.drawNumber(HUD_X+1,HUD_X_MID - 3,vspd*0.1*UNIT_VSPEED_SCALE,SMLSIZE)
  else
    lcd.drawNumber(HUD_X+1,HUD_X_MID - 3,vspd*UNIT_VSPEED_SCALE,SMLSIZE+PREC1)
  end
#else --UNIT_SCALE
  if math.abs(vspd) > 99 then
    lcd.drawNumber(HUD_X+1,HUD_X_MID - 3,vspd*0.1,SMLSIZE)
  else
    lcd.drawNumber(HUD_X+1,HUD_X_MID - 3,vspd,SMLSIZE+PREC1)
  end
#endif --UNIT_SCALE
  -- center arrow
  local arrowX = math.floor(HUD_X + HUD_WIDTH/2)
  lcd.drawLine(arrowX - 4,HUD_X_MID + 4,arrowX ,HUD_X_MID ,SOLID,0)
  lcd.drawLine(arrowX + 1,HUD_X_MID + 1,arrowX + 4, HUD_X_MID + 4,SOLID,0)
#ifdef X9
#ifdef UNIT_SCALE
  lcd.drawLine(HUD_X + 25,HUD_X_MID,HUD_X + 30,HUD_X_MID ,SOLID,0)
#else -- UNIT_SCALE
  lcd.drawLine(HUD_X + 22,HUD_X_MID,HUD_X + 30,HUD_X_MID ,SOLID,0)
#endif --UNIT_SCALE
  lcd.drawLine(HUD_X + HUD_WIDTH - 24,HUD_X_MID,HUD_X + HUD_WIDTH - 31,HUD_X_MID ,SOLID,0)
#else
#ifdef UNIT_SCALE
  lcd.drawLine(HUD_X + 25,HUD_X_MID,HUD_X + 28,HUD_X_MID ,SOLID,0)
#else --UNIT_SCALE
  lcd.drawLine(HUD_X + 22,HUD_X_MID,HUD_X + 28,HUD_X_MID ,SOLID,0)
#endif --UNIT_SCALE
  lcd.drawLine(HUD_X + HUD_WIDTH - 23,HUD_X_MID,HUD_X + HUD_WIDTH - 28,HUD_X_MID ,SOLID,0)
#endif
  -- hspeed
#ifdef UNIT_SCALE
  local speed = getMaxValue(hSpeed,MAX_HSPEED) * UNIT_HSPEED_SCALE
#else --UNIT_SCALE
  local speed = getMaxValue(hSpeed,MAX_HSPEED) * CONF_HSPEED_MULT
#endif --UNIT_SCALE
--
#ifdef X9
  lcd.drawFilledRectangle((LCD_W)/2 - 10, LCD_H - 17, 20, 10, ERASE, 0)
  if math.abs(speed) > 99 then -- 
    lcd.drawNumber((LCD_W)/2 + 9, LCD_H - 15, speed*0.1, HSPEED_FLAGS+RIGHT)
  else
    lcd.drawNumber((LCD_W)/2 + 9, LCD_H - 15, speed, HSPEED_FLAGS+RIGHT+PREC1)
  end
  -- hspeed box
  lcd.drawRectangle((LCD_W)/2 - 10, LCD_H - 17, 20, 10, SOLID, FORCE)
  if showMinMaxValues == true then
    drawVArrow((LCD_W)/2 + 12,LCD_H - 16,6,true,false)
  end
#endif --X9
#ifdef X7
  lcd.drawFilledRectangle((HUD_WIDTH)/2 - 10, LCD_H - 16, 20, 10, ERASE, 0)
  if math.abs(speed) > 99 then -- 
    lcd.drawNumber((HUD_WIDTH)/2 + 9, LCD_H - 14, speed*0.1, HSPEED_FLAGS+RIGHT)
  else
    lcd.drawNumber((HUD_WIDTH)/2 + 9, LCD_H - 14, speed, HSPEED_FLAGS+RIGHT+PREC1)
  end
  -- hspeed box
  lcd.drawRectangle((HUD_WIDTH)/2 - 10, LCD_H - 16, 20, 10, SOLID, FORCE)
  if showMinMaxValues == true then
    drawVArrow((HUD_WIDTH)/2 + 12,LCD_H - 15,6,true,false)
  end
#endif --X7
  -- min/max arrows
  if showMinMaxValues == true then
    drawVArrow(HUD_X + HUD_WIDTH - 24, HUD_X_MID - 4,6,true,false)
  end
  -- arming status, show only if timer is not running, hide otherwise
  if ekfFailsafe == 0 and battFailsafe == 0 and timerRunning == 0 then
    if (statusArmed == 1) then
      lcd.drawText(HUD_X + HUD_WIDTH/2 - 15, 22, " ARMED ", SMLSIZE+INVERS)
    else
      lcd.drawText(HUD_X + HUD_WIDTH/2 - 21, 22, " DISARMED ", SMLSIZE+INVERS+BLINK)
    end
  end
end

local function drawGrid()
  lcd.drawLine(HUD_X - 1, 7 ,HUD_X - 1, 57, SOLID, 0)
  lcd.drawLine(HUD_X + HUD_WIDTH, 7, HUD_X + HUD_WIDTH, 57, SOLID, 0)
end

local function drawHomeDirection()
  local angle = math.floor(homeAngle - yaw)
  local x1 = HOMEDIR_X + HOMEDIR_R * math.cos(math.rad(angle - 90))
  local y1 = HOMEDIR_Y + HOMEDIR_R * math.sin(math.rad(angle - 90))
  local x2 = HOMEDIR_X + HOMEDIR_R * math.cos(math.rad(angle - 90 + 150))
  local y2 = HOMEDIR_Y + HOMEDIR_R * math.sin(math.rad(angle - 90 + 150))
  local x3 = HOMEDIR_X + HOMEDIR_R * math.cos(math.rad(angle - 90 - 150))
  local y3 = HOMEDIR_Y + HOMEDIR_R * math.sin(math.rad(angle - 90 - 150))
  local x4 = HOMEDIR_X + HOMEDIR_R * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = HOMEDIR_Y + HOMEDIR_R * 0.5 *math.sin(math.rad(angle - 270))
  --
  lcd.drawLine(x1,y1,x2,y2,SOLID,1)
  lcd.drawLine(x1,y1,x3,y3,SOLID,1)
  lcd.drawLine(x2,y2,x4,y4,SOLID,1)
  lcd.drawLine(x3,y3,x4,y4,SOLID,1)
end

#ifdef X7  
local function drawCustomBoxes()
  lcd.drawRectangle(BOX1_X,BOX1_Y,BOX1_WIDTH,BOX1_HEIGHT,SOLID)
  lcd.drawFilledRectangle(BOX1_X,BOX1_Y,BOX1_WIDTH,BOX1_HEIGHT,SOLID)
end
#endif --X7

---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms except battery alerts
  if timerRunning == 0 then
    if alarms[idx][ALARM_TYPE] == ALARM_TYPE_MIN then
      alarms[idx] = { false, 0, false, ALARM_TYPE_MIN, 0, false, 0} 
    elseif alarms[idx][ALARM_TYPE] == ALARM_TYPE_MAX then
      alarms[idx] = { false, 0, true, ALARM_TYPE_MAX, 0, false, 0}
    elseif  alarms[idx][ALARM_TYPE] == ALARM_TYPE_TIMER then
      alarms[idx] = { false, 0, true, ALARM_TYPE_TIMER, 0, false, 0}
    elseif  alarms[idx][ALARM_TYPE] == ALARM_TYPE_BATT then
      alarms[idx] = { false, 0 , false, ALARM_TYPE_BATT, ALARM_TYPE_BATT_GRACE, false, 0}
    end
    -- reset done
    return
  end
  -- if needed arm the alarm only after value has reached level  
  if alarms[idx][ALARM_ARMED] == false and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][ALARM_ARMED] = true
  end
  --
  if alarms[idx][ALARM_TYPE] == ALARM_TYPE_TIMER then
    if flightTime > 0 and math.floor(flightTime) %  delay == 0 then
      if alarms[idx][ALARM_NOTIFIED] == false then 
        alarms[idx][ALARM_NOTIFIED] = true
        playSound(sound)
         -- flightime is a multiple of 1 minute
        if (flightTime % 60 == 0 ) then
          -- minutes
          playNumber(flightTime / 60,25) --25=minutes,26=seconds
        else
          -- minutes
          if (flightTime > 60) then playNumber(flightTime / 60,25) end
          -- seconds
          playNumber(flightTime % 60,26)
        end
      end
    else
        alarms[idx][ALARM_NOTIFIED] = false
    end
  else
    if alarms[idx][ALARM_ARMED] == true then
      if level > 0 and sign*value > sign*level then
        -- value is outside level 
        if alarms[idx][ALARM_START] == 0 then
          -- first time outside level after last reset
          alarms[idx][ALARM_START] = flightTime
          -- status: START
        end
      else
        -- value back to normal ==> reset
        alarms[idx][ALARM_START] = 0
        alarms[idx][ALARM_NOTIFIED] = false
        alarms[idx][ALARM_READY] = false
        -- status: RESET
      end
      if alarms[idx][ALARM_START] > 0 and (flightTime ~= alarms[idx][ALARM_START]) and (flightTime - alarms[idx][ALARM_START]) >= alarms[idx][ALARM_GRACE] then
        -- enough time has passed after START
        alarms[idx][ALARM_READY] = true
        -- status: READY
      end
      --
      if alarms[idx][ALARM_READY] == true and alarms[idx][ALARM_NOTIFIED] == false then 
        playSound(sound)
        alarms[idx][ALARM_NOTIFIED] = true
        alarms[idx][ALARM_LAST_ALARM] = flightTime
        -- status: BEEP
      end
      -- all but battery alarms
      if alarms[idx][ALARM_TYPE] ~= ALARM_TYPE_BATT then
        if alarms[idx][ALARM_READY] == true and flightTime ~= alarms[idx][ALARM_LAST_ALARM] and (flightTime - alarms[idx][ALARM_LAST_ALARM]) %  delay == 0 then
          alarms[idx][ALARM_NOTIFIED] = false
          -- status: REPEAT
        end
      end
    end
  end
end

local function loadFlightModes()
  if frame.flightModes then
    return
  end
  if frameType ~= -1 then
#ifdef LOAD_LUA
    if frameTypes[frameType] == "c" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/copter.lua")
    elseif frameTypes[frameType] == "p" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/plane.lua")
    elseif frameTypes[frameType] == "r" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/rover.lua")
    end
#else
    if frameTypes[frameType] == "c" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/copter.luac")
    elseif frameTypes[frameType] == "p" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/plane.luac")
    elseif frameTypes[frameType] == "r" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/rover.luac")
    end
#endif
    if frame.flightModes then
      for i,v in pairs(frameTypes) do
        frameTypes[i] = nil
      end
      frameTypes = nil
    end
#ifdef COLLECTGARBAGE  
    collectgarbage()
    maxmem=0
#endif
  end
end

local function checkEvents()
  loadFlightModes()
  checkAlarm(CONF_MINALT_ALERT,homeAlt,ALARMS_MIN_ALT,-1,"minalt",CONF_REPEAT)
  checkAlarm(CONF_MAXALT_ALERT,homeAlt,ALARMS_MAX_ALT,1,"maxalt",CONF_REPEAT)  
  checkAlarm(CONF_MAXDIST_ALERT,homeDist,ALARMS_MAX_DIST,1,"maxdist",CONF_REPEAT)
  checkAlarm(1,2*ekfFailsafe,ALARMS_FS_EKF,1,"ekf",CONF_REPEAT)  
  checkAlarm(1,2*battFailsafe,ALARMS_FS_BATT,1,"lowbat",CONF_REPEAT)  
  checkAlarm(math.floor(CONF_TIMER_ALERT),flightTime,ALARMS_TIMER,1,"timealert",math.floor(CONF_TIMER_ALERT))
  --
  local capacity = getBatt1Capacity()
  local mah = batt1mah
  -- only if dual battery has been detected
  if batt2sources.fc or batt2sources.vs then
      capacity = capacity + getBatt2Capacity()
      mah = mah  + batt2mah
  end
  if (capacity > 0) then
    batLevel = (1 - (mah/capacity))*100
  else
    batLevel = 99
  end

  for l=0,12 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    local level = batLevels(l)
    if batLevel <= level + 1 and l < lastBattLevel then
      lastBattLevel = l
      playSound("bat"..level)
      break
    end
  end
  --
  if statusArmed ~= lastStatusArmed then
    if statusArmed == 1 then playSound("armed") else playSound("disarmed") end
    lastStatusArmed = statusArmed
  end
  --
  if gpsStatus > 2 and lastGpsStatus <= 2 then
    lastGpsStatus = gpsStatus
    playSound("gpsfix")
  elseif gpsStatus <= 2 and lastGpsStatus > 2 then
    lastGpsStatus = gpsStatus
    playSound("gpsnofix")
  end
  --
  if frame.flightModes ~= nil and flightMode ~= lastFlightMode then
    lastFlightMode = flightMode
    playSoundByFrameTypeAndFlightMode(frameType,flightMode)
  end
  --
  if simpleMode ~= lastSimpleMode then
    if simpleMode == 0 then
      playSound( lastSimpleMode == 1 and "simpleoff" or "ssimpleoff" )
    else
      playSound( simpleMode == 1 and "simpleon" or "ssimpleon" )
    end
    lastSimpleMode = simpleMode
  end
end

local function checkCellVoltage(celm)
  -- check alarms
  checkAlarm(CONF_BATT_LEVEL1,celm,ALARMS_BATT_L1,-1,"batalert1",menuItems[T2][4])
  checkAlarm(CONF_BATT_LEVEL2,celm,ALARMS_BATT_L2,-1,"batalert2",menuItems[T2][4])
  -- cell bgcolor is sticky but gets triggered with alarms
  if battLevel1 == false then battLevel1 = alarms[ALARMS_BATT_L1][ALARM_NOTIFIED] end
  if battLevel2 == false then battLevel2 = alarms[ALARMS_BATT_L2][ALARM_NOTIFIED] end
end

local function cycleBatteryInfo()
  if showDualBattery == false and (batt2sources.fc or batt2sources.vs) then
    showDualBattery = true
    return
  end
  if battsource == "vs" then
    battsource = "fc"
  elseif battsource == "fc" then
    battsource = "a2"
  elseif battsource == "a2" then
    battsource = "vs"
  end
end
--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
local showMessages = false
local showConfigMenu = false
local bgclock = 0
#ifdef BGRATE
local counter = 0
local bgrate = 0
local bgstart = 0
#endif --BGRATE
#ifdef FGRATE
local fgcounter = 0
local fgrate = 0
local fgstart = 0
#endif --FGRATE
#ifdef HUDRATE
local hudcounter = 0
local hudrate = 0
local hudstart = 0
#endif --HUDRATE
#ifdef BGTELERATE
local bgtelecounter = 0
local bgtelerate = 0
local bgtelestart = 0
#endif --BGTELERATE

-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local function background()
#ifdef BGRATE
  ------------------------
  -- CALC BG LOOP RATE
  ------------------------
  -- skip first iteration
  local now = getTime()/100
  if counter == 0 then
    bgstart = now
  else
    bgrate = counter / (now - bgstart)
  end
  --
  counter=counter+1
#endif --BGRATE
  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,3
  do
    processTelemetry()
#ifdef BGTELERATE
    ------------------------
    -- CALC BG TELE PROCESSING RATE
    ------------------------
    -- skip first iteration
    local now = getTime()/100
    if bgtelecounter == 0 then
      bgtelestart = now
    else
      bgtelerate = bgtelecounter / (now - bgtelestart)
    end
    --
    bgtelecounter=bgtelecounter+1
#endif --BGTELERATE
end
  --[[
  -- NORMAL: this runs at 10Hz (every 100ms)
  if telemetryEnabled() and (bgclock % 2 == 0) then
    setTelemetryValue(VSpd_ID, VSpd_SUBID, VSpd_INSTANCE, vSpeed, 5 , VSpd_PRECISION , VSpd_NAME)
  end
  --]]
  -- SLOW: this runs at 4Hz (every 250ms)
  if (bgclock % 4 == 0) then
    setSensorValues()
  end
  -- SLOWER: this runs at 2Hz (every 500ms)
  if (bgclock % 8 == 0) then
    calcBattery()
    calcFlightTime()
    -- prepare celm based on battsource
    local count = calcCellCount()
    local cellVoltage = 0
    --
    if battsource == "vs" then
      cellVoltage = getNonZeroMin(cell1min,cell2min)*100 --FLVSS
    elseif battsource == "fc" then
      cellVoltage = getNonZeroMin(cell1sumFC/count,cell2sumFC/count)*100 --FC
    elseif battsource == "a2" then
      cellVoltage = (cellsumA2/count)*100 --A2
    end
    --
    checkEvents()
    checkLandingStatus()
    -- no need for alarms if reported voltage is 0
    if cellVoltage > 0 then
      checkCellVoltage(cellVoltage)
    end
    -- aggregate value
    minmaxValues[MAX_CURR] = math.max(batt1current+batt2current,minmaxValues[MAX_CURR])
    -- indipendent values
    minmaxValues[MAX_CURR1] = math.max(batt1current,minmaxValues[MAX_CURR1])
    minmaxValues[MAX_CURR2] = math.max(batt2current,minmaxValues[MAX_CURR2])
    bgclock=0
  end
  bgclock = bgclock+1
end

local function run(event)
  lcd.clear()
#ifdef DEBUGEVT
  if (event ~= 0) then
    pushMessage(7,string.format("Event: %d",event))
  end
#endif
#ifdef FGRATE
  ------------------------
  -- CALC FG LOOP RATE
  ------------------------
  -- skip first iteration
  local now = getTime()/100
  if fgcounter == 0 then
    fgstart = now
  else
    fgrate = fgcounter / (now - fgstart)
  end
  --
  fgcounter=fgcounter+1
#endif --FGRATE
  ---------------------
  -- SHOW MESSAGES
  ---------------------
  if showConfigMenu == false and (event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == XLITE_UP) then
    showMessages = true
#ifdef COLLECTGARBAGE  
    collectgarbage()
#endif
  end
  ---------------------
  -- SHOW CONFIG MENU
  ---------------------
  if showMessages == false and (event == EVT_MENU_LONG or event == XLITE_MENU_LONG) then
    showConfigMenu = true
#ifdef COLLECTGARBAGE  
    collectgarbage()
#endif
  end
  if showMessages then
    ---------------------
    -- MESSAGES
    ---------------------
    if event == EVT_EXIT_BREAK or event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT  or event == XLITE_DOWN or event == XLITE_RTN then
      showMessages = false
    end
    drawAllMessages()
  elseif showConfigMenu then
    ---------------------
    -- CONFIG MENU
    ---------------------
    drawConfigMenu(event)
    --
    if event == EVT_EXIT_BREAK or event == XLITE_RTN then
      menu.editSelected = false
      showConfigMenu = false
      saveConfig()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    if event == EVT_ENTER_BREAK or event == XLITE_ENTER then
      cycleBatteryInfo()
    end
    if event == EVT_MENU_BREAK or event == XLITE_MENU then
      showMinMaxValues = not showMinMaxValues
    end
    if showDualBattery == true and event == EVT_EXIT_BREAK or event == XLITE_RTN then
      showDualBattery = false
    end
#ifdef TESTMODE
      symMode()
#endif --TESTMODE
#ifdef HUDRATE
    ------------------------
    -- CALC HUD REFRESH RATE
    ------------------------
    -- skip first iteration
    local hudnow = getTime()/100
    if hudcounter == 0 then
      hudstart = hudnow
    else
      hudrate = hudcounter / (hudnow - hudstart)
    end
    --
    hudcounter=hudcounter+1
#endif --HUDRATE
#ifdef X9
    drawHud()
#endif --X9
#ifdef X7
    -- on X7 the HUD is replaced with 2nd battery details
    if showDualBattery == false then
      drawHud()
    end
#endif --X7
    drawCompassRibbon()
    drawGrid()
#ifdef X7    
    drawCustomBoxes()
    --drawGPSStatus()
#endif --X7
    --
    -- Note: these can be calculated. not necessary to track them as min/max 
    -- cell1minFC = cell1sumFC/calcCellCount()
    -- cell2minFC = cell2sumFC/calcCellCount()
    -- cell1minA2 = cell1sumA2/calcCellCount()
    local count = calcCellCount()
    local cel1m = getMinVoltageBySource(battsource,cell1min,cell1sumFC/count,cellsumA2/count,1,count)*100
    local cel2m = getMinVoltageBySource(battsource,cell2min,cell2sumFC/count,cellsumA2/count,2,count)*100
    local batt1 = getMinVoltageBySource(battsource,cell1sum,cell1sumFC,cellsumA2,1,count)*10
    local batt2 = getMinVoltageBySource(battsource,cell2sum,cell2sumFC,cellsumA2,2,count)*10
    local curr  = getMaxValue(batt1current+batt2current,MAX_CURR)
    local curr1 = getMaxValue(batt1current,MAX_CURR1)
    local curr2 = getMaxValue(batt2current,MAX_CURR2)
    local mah1 = batt1mah
    local mah2 = batt2mah
    local cap1 = getBatt1Capacity()
    local cap2 = getBatt2Capacity()
    -- with dual battery default is to show aggregate view
    if batt2sources.fc or batt2sources.vs then
      if showDualBattery == false then
        -- dual battery: aggregate view
#ifdef X9
        lcd.drawText(HUD_X+HUD_WIDTH+1,TOPBAR_HEIGHT,"B1+B2",SMLSIZE+INVERS)
        drawX9BatteryPane(HUD_X+HUD_WIDTH+1,getNonZeroMin(batt1,batt2),getNonZeroMin(cel1m,cel2m),curr,mah1+mah2,cap1+cap2)
#endif --X9
#ifdef X7
        lcd.drawText(HUD_X+8,BOTTOMBAR_Y - 8,"2B",SMLSIZE+INVERS)
        drawX7RightPane(HUD_X+HUD_WIDTH+1,getNonZeroMin(batt1,batt2),getNonZeroMin(cel1m,cel2m),curr,mah1+mah2,cap1+cap2)
#endif --X7
      else
        -- dual battery: do I have also dual current monitor?
        if curr1 > 0 and curr2 == 0 then
          -- special case: assume 1 power brick is monitoring batt1+batt2 in parallel
          curr1 = curr1/2
          curr2 = curr1
          --
          mah1 = mah1/2
          mah2 = mah1
          --
          cap1 = cap1/2
          cap2 = cap1
        end
        -- dual battery:battery 1 right pane
#ifdef X9
        lcd.drawText(HUD_X+HUD_WIDTH+1,TOPBAR_HEIGHT,"B1",SMLSIZE+INVERS)
        drawX9BatteryPane(HUD_X+HUD_WIDTH+1,batt1,cel1m,curr1,mah1,cap1)
#endif --X9
#ifdef X7
        drawX7RightPane(HUD_X+HUD_WIDTH+1,batt1,cel1m,curr1,mah1,cap1)
#endif --X7
        -- dual battery:battery 2 left pane
#ifdef X9
        lcd.drawText(0,TOPBAR_HEIGHT,"B2",SMLSIZE+INVERS)
        drawX9BatteryPane(0,batt2,cel2m,curr2,mah2,cap2)
#endif --X9
#ifdef X7
        drawX7LeftPane(batt2,cel2m,curr2,mah2,cap2)
#endif --X7
      end
    else
#ifdef X9      
      -- battery 1 right pane in single battery mode
        drawX9BatteryPane(HUD_X+HUD_WIDTH+1,batt1,cel1m,curr1,mah1,cap1)
    end
    -- left pane info when not in dual battery mode
    if showDualBattery == false then
      -- power is always based on FC current+voltage
      drawX9LeftPane(curr1+curr2,getNonZeroMin(cell1sumFC,cell2sumFC))
    end
#endif --X9
#ifdef X7
      --- battery 1 right pane in single battery mode
      drawX7RightPane(HUD_X+HUD_WIDTH+1,batt1,cel1m,curr1,mah1,cap1)
    end
    if showDualBattery == false then
      drawHomeDirection()
    end
#endif --X7
#ifdef X9
    drawHomeDirection()
#endif --X9
    drawTopBar()
    drawBottomBar()
    drawFailsafe()
#ifdef DEBUG    
    lcd.drawNumber(0,40,cell1maxFC,SMLSIZE+PREC1)
    lcd.drawNumber(25,40,calcCellCount(),SMLSIZE)
#endif --DEBUG
#ifdef BGRATE    
    lcd.drawNumber(0,39,bgrate*10,PREC1+SMLSIZE+INVERS)
    lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --BGRATE
#ifdef FGRATE    
    lcd.drawNumber(0,39,fgrate*10,PREC1+SMLSIZE+INVERS)
    lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --FGRATE
#ifdef HUDRATE    
    lcd.drawNumber(0,39,hudrate*10,PREC1+SMLSIZE+INVERS)
    lcd.drawText(lcd.getLastRightPos(),39,"Hz",SMLSIZE+INVERS)
#endif --HUDRATE
#ifdef TELERATE    
    lcd.drawNumber(0,39,telerate,SMLSIZE+INVERS)
#endif --TELERATE
#ifdef BGTELERATE    
    lcd.drawNumber(20,39,bgtelerate,SMLSIZE+INVERS)
#endif --BGTELERATE
    drawNoTelemetryData()
  end
#ifdef MEMDEBUG
  -- debug info, allocated memory
  maxmem = math.max(maxmem,collectgarbage("count")*1024)
#ifdef X9
  lcd.drawNumber(LCD_W,LCD_H-7,maxmem,SMLSIZE+INVERS+RIGHT)
#else
  lcd.drawNumber(LCD_W,LCD_H-6,maxmem,SMLSIZE+INVERS+RIGHT)
#endif
#endif  
end

local function init()
-- initialize flight timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
#ifdef COMPILE
  loadScript("/SCRIPTS/TELEMETRY/yaapu/copter.lua")
  loadScript("/SCRIPTS/TELEMETRY/yaapu/plane.lua")
  loadScript("/SCRIPTS/TELEMETRY/yaapu/rover.lua")
#endif
  loadConfig()
#ifdef X9
  pushMessage(6,VERSION)
#endif --X9
#ifdef X7
  pushMessage(6,VERSION)
#endif --X7
#ifdef TESTMODE
#ifdef DEMO
  pushMessage(6,"APM:Copter V3.5.4 (284349c3) QUAD")
  pushMessage(6,"Calibrating barometer")
  pushMessage(6,"Initialising APM")
  pushMessage(6,"Barometer calibration complete")
  pushMessage(6,"EKF2 IMU0 initial yaw alignment complete")
  pushMessage(6,"EKF2 IMU1 initial yaw alignment complete")
  pushMessage(6,"GPS 1: detected as u-blox at 115200 baud")
  pushMessage(6,"EKF2 IMU0 tilt alignment complete")
  pushMessage(6,"EKF2 IMU1 tilt alignment complete")
  pushMessage(6,"u-blox 1 HW: 00080000 SW: 2.01 (75331)")
  pushMessage(4,"Bad AHRS")
  pushMessage(4,"Bad AHRS")
#endif --DEMO
#endif --TESTMODE
  playSound("yaapu")
#ifdef LOGTELEMETRY
  logfilename = getLogFilename(getDateTime())
  logfile = io.open(logfilename,"a")
  pushMessage(6,logfilename)
#endif --LOGTELEMETRY
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}
